package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"example.com/learn/go-advanced/domain"
	"example.com/learn/go-advanced/jobs"
	"io"
	"net/http"
	"time"
)

const MaxBody = 256

type API struct{ Service *jobs.Service }

func (a API) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/jobs" {
		http.NotFound(w, r)
		return
	}
	if r.Method != http.MethodPost {
		w.Header().Set("Allow", http.MethodPost)
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), time.Second)
	defer cancel()
	r.Body = http.MaxBytesReader(w, r.Body, MaxBody)
	defer r.Body.Close()
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	var input struct {
		Name   string `json:"name"`
		Values []int  `json:"values"`
	}
	if err := decoder.Decode(&input); err != nil {
		var large *http.MaxBytesError
		if errors.As(err, &large) {
			http.Error(w, "body", http.StatusRequestEntityTooLarge)
		} else {
			http.Error(w, "json", http.StatusBadRequest)
		}
		return
	}
	if err := decoder.Decode(new(any)); err != io.EOF {
		var large *http.MaxBytesError
		if errors.As(err, &large) {
			http.Error(w, "body", http.StatusRequestEntityTooLarge)
		} else {
			http.Error(w, "trailing", http.StatusBadRequest)
		}
		return
	}
	job, err := domain.NewJob(input.Name, input.Values)
	if err != nil {
		http.Error(w, "job", http.StatusBadRequest)
		return
	}
	reply, err := a.Service.Submit(ctx, job)
	if err != nil {
		status := http.StatusServiceUnavailable
		if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
			status = http.StatusRequestTimeout
		}
		http.Error(w, "unavailable", status)
		return
	}
	select {
	case result := <-reply:
		if result.Err != nil {
			http.Error(w, "cancelled", http.StatusRequestTimeout)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(struct {
			Total int `json:"total"`
		}{result.Total}); err != nil {
			return
		}
	case <-ctx.Done():
		http.Error(w, "deadline", http.StatusGatewayTimeout)
	}
}

func Server(address string, handler http.Handler) *http.Server {
	return &http.Server{Addr: address, Handler: handler, ReadHeaderTimeout: 2 * time.Second, ReadTimeout: 3 * time.Second, WriteTimeout: 3 * time.Second, IdleTimeout: 30 * time.Second, MaxHeaderBytes: 8192}
}
