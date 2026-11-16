package pipeline

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"
)

type startupContext struct {
	context.Context
	observed chan struct{}
	release  <-chan struct{}
	once     sync.Once
}

func (c *startupContext) Done() <-chan struct{} {
	c.once.Do(func() { close(c.observed) })
	<-c.release
	return c.Context.Done()
}

func TestSquaresCancellationAfterStartup(t *testing.T) {
	base, cancel := context.WithCancel(context.Background())
	release := make(chan struct{})
	var releaseOnce sync.Once
	unblock := func() { releaseOnce.Do(func() { close(release) }) }
	t.Cleanup(func() { cancel(); unblock() })
	ctx := &startupContext{Context: base, observed: make(chan struct{}), release: release}
	done := make(chan error, 1)
	go func() {
		_, err := Squares(ctx, []int{1, 2, 3}, 2)
		done <- err
	}()
	watchdog := time.NewTimer(5 * time.Second)
	defer watchdog.Stop()
	select {
	case <-ctx.observed:
	case <-watchdog.C:
		t.Fatal("pipeline did not observe cancellation after its initial Err check")
	}
	cancel()
	unblock()
	select {
	case err := <-done:
		if !errors.Is(err, context.Canceled) {
			t.Fatalf("got %v; want context.Canceled", err)
		}
	case <-watchdog.C:
		t.Fatal("pipeline did not finish after cancellation")
	}
}
