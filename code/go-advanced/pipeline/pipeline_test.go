package pipeline

import (
	"context"
	"errors"
	"reflect"
	"sync"
	"testing"
)

func TestSquares(t *testing.T) {
	for _, workers := range []int{0, 1, 3, 99} {
		got, err := Squares(context.Background(), []int{3, 1, 2}, workers)
		if err != nil || !reflect.DeepEqual(got, []int{9, 1, 4}) {
			t.Fatalf("workers=%d values=%v err=%v", workers, got, err)
		}
	}
	got, err := Squares(context.Background(), nil, 4)
	if err != nil || len(got) != 0 {
		t.Fatal(got, err)
	}
}
func TestCancellation(t *testing.T) {
	ctx, cancel := context.WithCancelCause(context.Background())
	started := make(chan struct{})
	done := make(chan error, 1)
	go func() { done <- Wait(ctx, started) }()
	<-started
	cause := errors.New("stop")
	cancel(cause)
	if !errors.Is(<-done, cause) {
		t.Fatal("cause lost")
	}
	if _, err := Squares(ctx, []int{1, 2}, 2); !errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
}
func TestCounter(t *testing.T) {
	var c Counter
	var wg sync.WaitGroup
	for range 8 {
		wg.Go(func() {
			for range 100 {
				c.Add()
			}
		})
	}
	wg.Wait()
	if c.Value() != 800 {
		t.Fatal(c.Value())
	}
}
