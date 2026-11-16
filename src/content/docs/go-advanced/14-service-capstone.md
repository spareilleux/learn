---
title: "14. An integrated HTTP job service"
description: "Trace a complete request through validation, owned admission, bounded work, response and drain."
sidebar:
  order: 14
---

## Learning objective

Trace a complete request through validation, owned admission, bounded work, response and drain.

## Mechanics and mental models

The capstone composes [net/http](https://pkg.go.dev/net/http), domain values and a bounded worker into one observable service. A POST to /jobs carries a name and integer values. The adapter limits bytes, decodes exactly one document, validates the name and submits a copied job. One worker computes a total and deposits one result into a buffered reply. The handler either writes a JSON response or reports cancellation. These are the actual guarantees: in-memory processing, finite request budgets and explicit shutdown, with no claim of durable delivery.

The service owns its queue and worker lifetime. Submit and Drain share a mutex around the admission decision, so closing the queue cannot race a send. A nonblocking enqueue returns ErrFull instead of allocating another goroutine to wait indefinitely. Once draining begins, later submissions return ErrClosed. The worker consumes already accepted tasks, then closes done. Repeating Drain is safe; a context deadline bounds waiting without reopening admission. The module therefore has a concrete state transition that tests can observe without sleeps.

Cancellation does not mean a completed sum was undone. The worker checks the task context before computing; the small finite computation may finish if cancellation arrives afterward. Its buffered reply prevents an abandoned HTTP waiter from blocking worker completion. Because the input is copied during admission, caller mutation cannot change accepted work. These ownership and completion rules connect earlier lessons more directly than adding a framework or a database would. Persisting jobs would require identities, durable states and recovery semantics beyond this unit.

The command demonstrates a successful request, drains the service, then observes a rejected late request. The [httptest](https://pkg.go.dev/net/http/httptest) integration test additionally sends a real loopback HTTP request with a finite client timeout. Recorder cases exercise malformed input, oversized body, unknown fields, method and path errors. Separate ownership and cancellation tests localize failures. C# hosted services and Java executor-backed endpoints share the lifecycle concerns, but Go makes the goroutine and channel protocol visible. Review every blocked send, every owner of close, and every resource budget before declaring a service complete. A green suite establishes tested contracts, not operational readiness or learner acceptance.

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

[cmd/l14/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l14/main.go)

```go
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
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l14
```

### Expected output contract

```text
200
{"total":9}
503
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. A client times out after submitting. Is repeating the request automatically safe?

<details>
<summary>Complete solution</summary>

No. The request may already have completed and this service has no durable deduplication identity. Reconcile its outcome before repeating operations with external effects. Cancellation controls waiting and cooperative work; it does not provide transactional rollback.

</details>

2. State a complete shutdown acceptance test.

<details>
<summary>Complete solution</summary>

Submit valid owned data, receive its expected total, drain within a bounded context, drain again successfully, then verify a later submission returns ErrClosed and HTTP maps it to 503. Use channels or request completion to order observations, never a scheduling sleep.

</details>

## Primary sources

- [net/http](https://pkg.go.dev/net/http)
- [httptest](https://pkg.go.dev/net/http/httptest)
- [context](https://pkg.go.dev/context)

[Next lesson](../journal/) · [Learning journal](../journal/)
