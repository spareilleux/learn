package jobs

import (
	"context"
	"errors"
	"example.com/learn/go-advanced/domain"
	"sync"
	"testing"
	"time"
)

func TestConcurrentAdmissionAndDrain(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	const submissions = 16
	service := New(submissions + 1)
	defer service.Drain(ctx)
	job := domain.Job{Name: "sum", Values: []int{2, 3}}
	first, err := service.Submit(ctx, job)
	if err != nil {
		t.Fatal(err)
	}
	type admission struct {
		reply <-chan Result
		err   error
	}
	start := make(chan struct{})
	admissions := make(chan admission, submissions)
	drains := make(chan error, 2)
	var ready sync.WaitGroup
	ready.Add(submissions + 2)
	for range submissions {
		go func() {
			ready.Done()
			<-start
			reply, err := service.Submit(ctx, job)
			admissions <- admission{reply, err}
		}()
	}
	for range 2 {
		go func() {
			ready.Done()
			<-start
			drains <- service.Drain(ctx)
		}()
	}
	ready.Wait()
	close(start)
	for range 2 {
		select {
		case err := <-drains:
			if err != nil {
				t.Fatal(err)
			}
		case <-ctx.Done():
			t.Fatal(ctx.Err())
		}
	}
	// Drain must complete even while the first accepted reply remains unread.
	replies := []<-chan Result{first}
	for range submissions {
		select {
		case result := <-admissions:
			if result.err == nil {
				replies = append(replies, result.reply)
			} else if !errors.Is(result.err, ErrClosed) {
				t.Fatalf("unexpected admission error: %v", result.err)
			}
		case <-ctx.Done():
			t.Fatal(ctx.Err())
		}
	}
	for _, reply := range replies {
		select {
		case result := <-reply:
			if result.Err != nil || result.Total != 5 {
				t.Fatal(result)
			}
		case <-ctx.Done():
			t.Fatal(ctx.Err())
		}
	}
	if _, err := service.Submit(ctx, job); !errors.Is(err, ErrClosed) {
		t.Fatalf("admission after drain: %v", err)
	}
}
