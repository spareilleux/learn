---
title: "7. Cancellation, deadlines and shutdown"
description: "Separate requesting cancellation, observing completion and draining accepted work."
sidebar:
  order: 7
---

## Learning objective

Separate requesting cancellation, observing completion and draining accepted work.

## Mechanics and mental models

A [context](https://pkg.go.dev/context) carries cancellation, a deadline and request scoped values. Pass it explicitly as the first parameter where work may block. A cancellation function requests that cooperative work stop; it does not join goroutines. The example therefore uses two separate signals: started proves the worker reached its wait, and done returns the terminal error. No sleep guesses whether the worker has begun. WithCancelCause preserves the reason without changing the ordinary cancellation identity returned by Err.

Always release resources associated with a derived context by calling its cancellation function, including when work finishes early. Deadline propagation prevents a child from extending a parent's lifetime. A timeout around a function cannot interrupt an arbitrary CPU loop or a library that ignores context. Put observation points where cancellation is meaningful, and document operations that finish atomically once admitted. Our small integer sum may complete after cancellation races with dispatch; callers must not infer rollback from a cancelled HTTP request.

The job service separates admission from drain. Submit holds a mutex while checking the closed flag and performing a nonblocking queue send. Drain holds the same mutex while stopping admission and closing that queue. This prevents a send racing a channel close. Its done channel closes when the worker has consumed accepted tasks. Each reply has one buffered slot, so the worker can finish even if the original requester no longer waits. A reply channel carries exactly one result and is not a stream to range indefinitely.

C# cancellation tokens also require cooperation; a cancelled Java future is not a universal interruption guarantee either. Build a shutdown sequence around observable states instead of borrowing an implication from an API name. For an HTTP process, stop admission, let handlers finish within a finite shutdown context, drain accepted work and enforce an overall deadline. [http.Server.Shutdown](https://pkg.go.dev/net/http#Server.Shutdown) manages HTTP connections; it does not know about an independent application worker. A timed out drain stops waiting, but does not reopen admission or secretly undo accepted work.

## Worked runnable example

The executable belongs to the independent module `example.com/learn/go-advanced`. Its command is a small caller of reusable packages rather than the only location of the behavior. Read the package file first, then follow its calls from the command. The complete checked-in files appear below so imports, error paths and cleanup remain visible. No hidden notebook state or external service is required. Commands use the same working directory and syntax on Windows, Linux/WSL and macOS once Go is on PATH.

### Reusable source

[jobs/service.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/jobs/service.go)

```go
package jobs

import (
	"context"
	"errors"
	"example.com/learn/go-advanced/domain"
	"sync"
)

var ErrFull = errors.New("queue full")
var ErrClosed = errors.New("service closed")

type Result struct {
	Total int
	Err   error
}
type work struct {
	ctx   context.Context
	job   domain.Job
	reply chan Result
}
type Service struct {
	mu     sync.Mutex
	closed bool
	queue  chan work
	done   chan struct{}
}

func New(capacity int) *Service {
	if capacity < 0 {
		capacity = 0
	}
	s := &Service{queue: make(chan work, capacity), done: make(chan struct{})}
	go func() {
		defer close(s.done)
		for task := range s.queue {
			if err := task.ctx.Err(); err != nil {
				task.reply <- Result{Err: err}
				continue
			}
			task.reply <- Result{Total: task.job.Total()}
		}
	}()
	return s
}

func (s *Service) Submit(ctx context.Context, job domain.Job) (<-chan Result, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	owned, err := domain.NewJob(job.Name, job.Values)
	if err != nil {
		return nil, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.closed {
		return nil, ErrClosed
	}
	reply := make(chan Result, 1)
	select {
	case s.queue <- work{ctx, owned, reply}:
		return reply, nil
	default:
		return nil, ErrFull
	}
}

func (s *Service) Drain(ctx context.Context) error {
	s.mu.Lock()
	if !s.closed {
		s.closed = true
		close(s.queue)
	}
	s.mu.Unlock()
	select {
	case <-s.done:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}
```

[cmd/l07/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l07/main.go)

```go
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
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l07
```

### Expected output contract

```text
requested
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. Why does a buffered reply prevent a shutdown leak here?

<details>
<summary>Complete solution</summary>

Each accepted task produces exactly one result. One available slot lets that send complete even when its requester has cancelled. An unbuffered reply would need a cancellation select or a guaranteed receiver.

</details>

2. If Drain returns a deadline error, may Submit accept again?

<details>
<summary>Complete solution</summary>

No. Admission closes once and remains closed. The deadline bounds the caller’s wait; it does not reverse the service state transition. Call Drain again to observe completion, without resubmitting work whose outcome is unknown.

</details>

## Primary sources

- [context](https://pkg.go.dev/context)
- [http.Server.Shutdown](https://pkg.go.dev/net/http#Server.Shutdown)

[Next lesson](../08-production-http/) · [Learning journal](../journal/)
