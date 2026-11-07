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
	service := jobs.New(2)
	defer service.Drain(context.Background())
	api := httpapi.API{Service: service}
	first := httptest.NewRecorder()
	api.ServeHTTP(first, httptest.NewRequest("POST", "/jobs", strings.NewReader(`{"name":"sum","values":[4,5]}`)))
	fmt.Println(first.Code)
	fmt.Print(first.Body.String())
	if err := service.Drain(context.Background()); err != nil {
		panic(err)
	}
	late := httptest.NewRecorder()
	api.ServeHTTP(late, httptest.NewRequest("POST", "/jobs", strings.NewReader(`{"name":"late"}`)))
	fmt.Println(late.Code)
}
