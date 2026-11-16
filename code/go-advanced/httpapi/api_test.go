package httpapi

import (
	"context"
	"example.com/learn/go-advanced/jobs"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestLocalRequests(t *testing.T) {
	service := jobs.New(4)
	defer service.Drain(context.Background())
	api := API{Service: service}
	cases := []struct {
		method, path, body string
		status             int
	}{{"POST", "/jobs", `{"name":"sum","values":[2,3]}`, 200}, {"GET", "/jobs", "", 405}, {"POST", "/missing", "", 404}, {"POST", "/jobs", `{"name":""}`, 400}, {"POST", "/jobs", `{"name":"sum","extra":1}`, 400}, {"POST", "/jobs", `{"name":"sum"} {}`, 400}, {"POST", "/jobs", strings.Repeat(" ", MaxBody+1), 413}}
	for _, tc := range cases {
		t.Run(tc.method+tc.body, func(t *testing.T) {
			rec := httptest.NewRecorder()
			api.ServeHTTP(rec, httptest.NewRequest(tc.method, tc.path, strings.NewReader(tc.body)))
			if rec.Code != tc.status {
				t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
			}
			if tc.status == 200 && rec.Body.String() != `{"total":5}`+"\n" {
				t.Fatal(rec.Body.String())
			}
		})
	}
}
func TestHTTPIntegration(t *testing.T) {
	service := jobs.New(2)
	defer service.Drain(context.Background())
	server := httptest.NewServer(API{Service: service})
	defer server.Close()
	client := &http.Client{Timeout: 2 * time.Second}
	response, err := client.Post(server.URL+"/jobs", "application/json", strings.NewReader(`{"name":"sum","values":[4,5]}`))
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	body, err := io.ReadAll(response.Body)
	if err != nil || response.StatusCode != 200 || string(body) != `{"total":9}`+"\n" {
		t.Fatal(response.StatusCode, string(body), err)
	}
	if err := service.Drain(context.Background()); err != nil {
		t.Fatal(err)
	}
	rec := httptest.NewRecorder()
	API{service}.ServeHTTP(rec, httptest.NewRequest("POST", "/jobs", strings.NewReader(`{"name":"late"}`)))
	if rec.Code != 503 {
		t.Fatal(rec.Code)
	}
}
func TestCancelledRequestAndTimeouts(t *testing.T) {
	service := jobs.New(1)
	defer service.Drain(context.Background())
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	req := httptest.NewRequest("POST", "/jobs", strings.NewReader(`{"name":"sum"}`)).WithContext(ctx)
	rec := httptest.NewRecorder()
	API{service}.ServeHTTP(rec, req)
	if rec.Code != 408 {
		t.Fatal(rec.Code)
	}
	server := Server("127.0.0.1:0", API{service})
	if server.ReadHeaderTimeout <= 0 || server.ReadTimeout <= 0 || server.WriteTimeout <= 0 || server.IdleTimeout <= 0 {
		t.Fatal("unbounded server")
	}
}
