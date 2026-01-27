package ratelimit

import (
	"database/sql"
	"fmt"
	"log"
	"log/slog"
	"time"

	_ "github.com/lib/pq"
)

const (
	// TimesliceBlock to enforce the restrictions within.
	TimesliceBlock = 5 * time.Minute

	// MaxCount to enforce within the timeslice.
	MaxCount = 4
)

// req for the internal lookup of bloom filter cache hits.
type (
	req struct {
		id      string
		resp    chan bool
		respErr chan error
	}

	Server struct {
		req chan req
	}
)

func (s Server) IsRateLimited(id [20]byte) bool {
	var (
		r   = make(chan bool)
		err = make(chan error)
	)
	s.req <- req{string(id[:]), r, err}
	select {
	case x := <-r:
		return x
	case e := <-err:
		log.Fatalf("failed to get rate limit: %v", e)
	}
	return false
}

func Run(db *sql.DB, dryrun bool) Server {
	// Before we do anything here, we check if the feature is enabled
	// to do this. If it's not, then we allow everything:
	requests := make(chan req)
	if dryrun {
		slog.Info("Rate limiting brought in, but it's not enabled")
		go func() {
			for r := range requests {
				r.resp <- false
			}
		}()
		return Server{requests}
	}
	// We're going
	var (
		lastSlice time.Time
		seen      = make(map[string]int)
	)
	go func() {
	L:
		for r := range requests {
			curSlice := time.Now().Truncate(TimesliceBlock)
			var curCount int
			if !lastSlice.Equal(curSlice) {
				lastSlice = curSlice
				seen = make(map[string]int, len(seen))
				r.resp <- false
				continue L
			}
			curCount = seen[r.id]
			// If we already have an idea of who this person is, we can evict them
			// here if we want:
			if curCount+1 > MaxCount {
				slog.Debug("rate limited a user based on memory",
					"cur slice", curSlice,
					"id", r.id,
				)
				r.resp <- true
				continue L
			}
			seen[r.id] += 1
			r.resp <- false
		}
	}()
	return Server{requests}
}

func getCount(db *sql.DB, id string) (c int, err error) {
	r := db.QueryRow(`SELECT ninelives_get_ratelimit_1($1)`, id)
	if err := r.Scan(&c); err != nil {
		return 0, fmt.Errorf("error scanning and bumping: %v", err)
	}
	return
}
