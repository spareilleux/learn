package webapi

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"example.com/learn/go-for-csharp-java/internal/study"
)

func TestRecordsContract(t *testing.T) {
	response := httptest.NewRecorder()
	Handler().ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/records", nil))
	if response.Code != http.StatusOK || response.Header().Get("Content-Type") != "application/json" {
		t.Fatalf("code=%d headers=%v", response.Code, response.Header())
	}
	var records []study.Record
	if err := json.Unmarshal(response.Body.Bytes(), &records); err != nil {
		t.Fatal(err)
	}
	if len(records) != 2 || study.Total(records) != 40 {
		t.Fatal(records)
	}
}

func TestMethodAndCancellation(t *testing.T) {
	handler := Handler()
	wrongMethod := httptest.NewRecorder()
	handler.ServeHTTP(wrongMethod, httptest.NewRequest(http.MethodPost, "/records", nil))
	if wrongMethod.Code != http.StatusMethodNotAllowed {
		t.Fatal(wrongMethod.Code)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	cancelled := httptest.NewRecorder()
	handler.ServeHTTP(cancelled, httptest.NewRequestWithContext(ctx, http.MethodGet, "/records", nil))
	if cancelled.Body.Len() != 0 {
		t.Fatal("wrote after observing cancellation")
	}
}
