package main

import (
	"context"
	"example.com/learn/go-advanced/httpapi"
	"example.com/learn/go-advanced/jobs"
	"fmt"
	"net/http/httptest"
	"strings"
)

func main() {
	service := jobs.New(1)
	defer service.Drain(context.Background())
	request := httptest.NewRequest("POST", "/jobs", strings.NewReader(`{"name":"sum","values":[2,3]}`))
	response := httptest.NewRecorder()
	httpapi.API{Service: service}.ServeHTTP(response, request)
	fmt.Println(response.Code)
	fmt.Print(response.Body.String())
}
