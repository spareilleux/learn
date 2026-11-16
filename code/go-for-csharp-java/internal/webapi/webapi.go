package webapi

import (
	"encoding/json"
	"net/http"

	"example.com/learn/go-for-csharp-java/internal/study"
)

func Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /records", func(w http.ResponseWriter, r *http.Request) {
		if r.Context().Err() != nil {
			return
		}
		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(study.Fixture()); err != nil {
			return
		}
	})
	return mux
}
