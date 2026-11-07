package main

import (
	"context"
	"encoding/json"
	"errors"
	"example.com/learn/go-for-csharp-java/internal/study"
	"example.com/learn/go-for-csharp-java/internal/webapi"
	"fmt"
	"net/http"
	"net/http/httptest"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	request := httptest.NewRequestWithContext(ctx, http.MethodGet, "/records", nil)
	response := httptest.NewRecorder()
	webapi.Handler().ServeHTTP(response, request)
	var records []study.Record
	if err := json.Unmarshal(response.Body.Bytes(), &records); err != nil {
		panic(err)
	}
	cancel()
	_, err := study.Count(ctx, records)
	fmt.Printf("status=%d records=%d cancelled=%t\n", response.Code, len(records), errors.Is(err, context.Canceled))
}
