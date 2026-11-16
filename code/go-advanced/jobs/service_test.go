package jobs

import (
	"context"
	"errors"
	"example.com/learn/go-advanced/domain"
	"testing"
	"time"
)

func TestOwnershipAndDrain(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	service := New(1)
	defer service.Drain(ctx)
	values := []int{2, 3}
	reply, err := service.Submit(ctx, domain.Job{Name: "sum", Values: values})
	if err != nil {
		t.Fatal(err)
	}
	values[0] = 99
	select {
	case result := <-reply:
		if result.Err != nil || result.Total != 5 {
			t.Fatal(result)
		}
	case <-ctx.Done():
		t.Fatal(ctx.Err())
	}
	if err := service.Drain(ctx); err != nil {
		t.Fatal(err)
	}
	if err := service.Drain(ctx); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Submit(ctx, domain.Job{Name: "late"}); !errors.Is(err, ErrClosed) {
		t.Fatal(err)
	}
}
func TestCancelledAdmission(t *testing.T) {
	service := New(1)
	defer service.Drain(context.Background())
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := service.Submit(ctx, domain.Job{Name: "sum"}); !errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
}
