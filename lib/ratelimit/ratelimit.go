package ratelimit

// Every ratelimit user polls to receive a new bloom filter every minute.
// When a user tries to do something effectful, the bloom filter is
// checked, and if the user comes up positive, then the service checks
// the database to see if they are truly banned by checking their request
// count during the 5 minute time slice. The local service downloads the
// number of requests they've made, and uses that as a reference for how
// to enforce their restrictions. A CDC-powered service maintains the
// bloom filters by performing evictions and updates over time.
// This is a write-only service, owing to how we use Lambda, so it's not
// needed to do any garbage collection of the rate limited instances, since
// the Lambda function will simply shut itself down over time.

// The problem with this approach is the boundary burst, but it serves well
// to simply convert users to our RPC, which has a different (in memory)
// architecture.

import (
	"database/sql"
	"encoding/hex"
	"fmt"
	"log"
	"log/slog"
	"time"

	_ "github.com/lib/pq"

	bloom "github.com/bits-and-blooms/bloom/v3"
)

const (
	// TimesliceBlock to enforce the restrictions within.
	TimesliceBlock = 5 * time.Minute

	// BloomRefreshTimer to refresh the bloom filter after this timer expires.
	BloomRefreshTimer = 30 * time.Second

	// MaxCount to enforce within the timeslice.
	MaxCount = 10

	// BloomBits to use when making the bloom filter, optimised for ip addresses.
	BloomBits = 1024

	// BloomHashing function passes to use for hashing the ip addresess.
	BloomHashing = 3
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
	seen := make(map[string]struct {
		slice time.Time
		count int
	})
	newBloom := make(chan *bloom.BloomFilter)
	go func() {
		evictionTimer := time.NewTimer(BloomRefreshTimer)
		for range evictionTimer.C {
			newBloom <- getBloomFilter(db)
			evictionTimer.Reset(BloomRefreshTimer)
		}
	}()
	go func() {
		var (
			bloom *bloom.BloomFilter
			err   error
		)
	L:
		for {
			select {
			case b := <-newBloom:
				bloom = b
			case r := <-requests:
				curSlice := time.Now().Truncate(TimesliceBlock)
				var curCount int
				if curSlice.Equal(seen[r.id].slice) {
					curCount = seen[r.id].count
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
				}
				if bloom != nil {
					res := bloom.Test([]byte(r.id))
					slog.Debug("tested an id in the bloom filter",
						"time slice", curSlice,
						"res", res,
						"id", r.id,
					)
					if !res {
						r.resp <- false
						continue L
					}
				}
				// curCount here is increased already by the function that was used to do the lookup:
				curCount, err = getCount(db, r.id)
				if err != nil {
					slog.Error("failed to get ratelimit count",
						"err", err,
					)
					r.respErr <- err
					continue L
				}
				s := seen[r.id]
				s.slice = curSlice
				s.count = curCount
				if curCount > MaxCount {
					slog.Debug("rate limited a user after lookup",
						"cur slice", curSlice,
						"id", r.id,
					)
					r.resp <- true
					continue L
				}
				r.resp <- false
			}
		}
	}()
	return Server{requests}
}

func getBloomFilter(db *sql.DB) *bloom.BloomFilter {
	r := db.QueryRow(`
SELECT bloom FROM ninelives_ratelimit_bloom_1 WHERE bucket = 'accounts' LIMIT 1`,
	)
	var bs string
	switch err := r.Scan(&bs); err {
	case sql.ErrNoRows:
		return bloom.New(BloomBits, BloomHashing)
	case nil:
		// Do nothing
	default:
		log.Fatalf("get bloom filter: %v", err)
	}
	b, err := hex.DecodeString(bs)
	if err != nil {
		log.Fatalf("decode bloom filter: %v", err)
	}
	o := new(bloom.BloomFilter)
	if err := o.UnmarshalBinary(b); err != nil {
		log.Fatalf("unmarshal bloom filter: %v", err)
	}
	return o
}

func getCount(db *sql.DB, id string) (c int, err error) {
	r := db.QueryRow(`SELECT ninelives_get_ratelimit_1($1)`, id)
	if err := r.Scan(&c); err != nil {
		return 0, fmt.Errorf("error scanning and bumping: %v", err)
	}
	return
}
