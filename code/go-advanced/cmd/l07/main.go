package main

import (
	"context"
	"errors"
	"example.com/learn/go-advanced/pipeline"
	"fmt"
)

func main() {
	ctx, cancel := context.WithCancelCause(context.Background())
	defer cancel(nil)
	started := make(chan struct{})
	done := make(chan error, 1)
	go func() { done <- pipeline.Wait(ctx, started) }()
	<-started
	cancel(errors.New("requested"))
	fmt.Println(<-done)
}
