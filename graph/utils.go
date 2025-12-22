package graph

import (
	"bytes"
	"encoding/json"
	"log/slog"
	"net/http"
)

func isDryrun(x *bool) bool {
	if x != nil && *x {
		return true
	} else {
		return false
	}
}

func activateSoftAlarm(url string, snowflake int, err error) {
	if url == "" {
		slog.Info("not alarming soft alarm")
	}
	var buf bytes.Buffer
	_ = json.NewEncoder(&buf).Encode(struct {
		Snowflake int    `json:"snowflake"`
		Error     string `json:"error"`
	}{snowflake, err.Error()})
	r, _ := http.Post(url, "application/json", &buf)
	r.Body.Close()
}
