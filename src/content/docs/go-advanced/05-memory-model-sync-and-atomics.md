---
title: "5. Memory model, synchronization and atomics"
description: "Explain the synchronization edge that makes a concurrent result observable."
sidebar:
  order: 5
---

## Learning objective

Explain the synchronization edge that makes a concurrent result observable.

## Mechanics and mental models

The [Go memory model](https://go.dev/ref/mem) defines when one goroutine can rely on another goroutine's writes. Correct concurrent code needs a synchronization relationship, not a plausible scheduling story. A channel communication, a mutex protocol, a wait operation or an atomic operation can establish the appropriate relationship. Waiting for a wall clock duration cannot establish that a write has happened or become visible. A program free of data races enjoys the useful sequential consistency guarantee described by the model.

Counter stores its value in an atomic.Int64. Add and Load operate on that same atomic location. The command starts four goroutines, each adding twenty five times, then waits before printing. The total is stable because each increment is atomic and all goroutines finish before the final observation. An ordinary increment combines read, arithmetic and write; concurrent increments can overwrite each other. This course does not include a deliberately racy command with an invented final total.

The [sync](https://pkg.go.dev/sync) package offers several different coordination tools. WaitGroup tracks completion; it does not automatically protect a shared map modified by its workers. Mutex protects an invariant involving several values when every relevant access follows the same locking protocol. Atomic fields support carefully scoped operations on individual values. Replacing a mutex around a balance and a ledger with two independent atomics would not preserve their relationship. Never copy a synchronization value after it has been used.

C# lock and Java synchronized are familiar ways to protect invariants. Their existence does not imply Go atomics behave like an unsynchronized field with a volatile annotation. Use the Go memory model and package documentation for the actual guarantee. The pipeline illustrates another ownership strategy: workers send indexed results, and one collecting goroutine writes the output slice. This removes concurrent output mutation altogether. Choose the simplest argument you can state precisely, then verify that every access participates in it. Race detection exercises executed paths; it supplements that argument without proving every possible path safe.

## Worked runnable example

The executable belongs to the independent module `example.com/learn/go-advanced`. Its command is a small caller of reusable packages rather than the only location of the behavior. Read the package file first, then follow its calls from the command. The complete checked-in files appear below so imports, error paths and cleanup remain visible. No hidden notebook state or external service is required. Commands use the same working directory and syntax on Windows, Linux/WSL and macOS once Go is on PATH.

### Reusable source

[pipeline/pipeline.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/pipeline/pipeline.go)

```go
package pipeline

import (
	"context"
	"sync"
	"sync/atomic"
)

type Counter struct{ value atomic.Int64 }

func (c *Counter) Add()         { c.value.Add(1) }
func (c *Counter) Value() int64 { return c.value.Load() }

func Squares(ctx context.Context, input []int, workers int) ([]int, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	if workers < 1 {
		workers = 1
	}
	if workers > len(input) {
		workers = len(input)
	}
	type item struct{ index, value int }
	jobs := make(chan item)
	results := make(chan item)
	var group sync.WaitGroup
	group.Add(workers)
	for range workers {
		go func() {
			defer group.Done()
			for {
				select {
				case <-ctx.Done():
					return
				case job, ok := <-jobs:
					if !ok {
						return
					}
					job.value *= job.value
					select {
					case results <- job:
					case <-ctx.Done():
						return
					}
				}
			}
		}()
	}
	go func() {
		defer close(jobs)
		for i, v := range input {
			select {
			case jobs <- item{i, v}:
			case <-ctx.Done():
				return
			}
		}
	}()
	go func() { group.Wait(); close(results) }()
	output := make([]int, len(input))
	for result := range results {
		output[result.index] = result.value
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	return output, nil
}

func Wait(ctx context.Context, started chan<- struct{}) error {
	close(started)
	<-ctx.Done()
	return context.Cause(ctx)
}
```

[cmd/l05/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l05/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/pipeline"
	"fmt"
	"sync"
)

func main() {
	var c pipeline.Counter
	var group sync.WaitGroup
	for range 4 {
		group.Go(func() {
			for range 25 {
				c.Add()
			}
		})
	}
	group.Wait()
	fmt.Println(c.Value())
}
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l05
```

### Expected output contract

```text
100
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. Does WaitGroup alone make a shared increment safe?

<details>
<summary>Complete solution</summary>

No. It coordinates completion, not the read and write inside each increment. Use the atomic Counter or a mutex protecting every access, and still wait before interpreting a final total.

</details>

2. Can two atomics maintain a multi-field invariant automatically?

<details>
<summary>Complete solution</summary>

No. A reader may observe a combination from different updates. Put the related state behind one mutex or publish an immutable snapshot through one synchronization point; choose from the actual invariant.

</details>

## Primary sources

- [Go memory model](https://go.dev/ref/mem)
- [sync](https://pkg.go.dev/sync)
- [sync/atomic](https://pkg.go.dev/sync/atomic)

[Next lesson](../06-bounded-pipelines/) · [Learning journal](../journal/)
