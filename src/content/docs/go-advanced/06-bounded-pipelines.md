---
title: "6. Bounded pipelines"
description: "Bound concurrent work and make every potentially blocked operation cancellable."
sidebar:
  order: 6
---

## Learning objective

Bound concurrent work and make every potentially blocked operation cancellable.

## Mechanics and mental models

A [pipeline](https://go.dev/blog/pipelines) needs an ownership and termination story for each stage. Squares has one producer, a fixed number of workers, and one collector. The producer alone closes jobs. A separate goroutine waits for every worker and closes results. The collector ranges results until that closure. Workers never close a shared channel they do not exclusively own. Those closure decisions matter more than an attractive diagram of arrows.

The worker count is normalized to at least one and at most the number of inputs. Empty input therefore creates no worker. Unbuffered channels enforce handoff between stages instead of storing an unbounded queue. The function still allocates an output slice proportional to input length: bounded concurrency is not constant total memory. For an unbounded stream, the public API would need streaming output or an explicit input limit. Here the input is a finite slice and the output preserves its index order.

Every producer send and worker send selects against [context](https://pkg.go.dev/context) cancellation. A consumer that abandons a result stream without cancellation can strand an upstream sender; this function avoids that public hazard by collecting internally until workers finish. Cancellation is cooperative. If both communication and cancellation are ready, a select may choose either, so a few additional bounded steps can occur. The final context check ensures the function reports a cancelled operation instead of presenting partially filled results as complete.

C# parallel query and Java parallel streams hide scheduling behind operators. That can be convenient, but a direct port that launches one goroutine per input does not preserve a concurrency budget. State the budget separately from the input count. Also distinguish result order from completion order: index tagging permits arbitrary worker scheduling while deterministic collection reconstructs the original order. Test several worker counts, empty input and already cancelled input. The calculation uses machine-sized integers and can overflow for large values; it teaches lifecycle, not checked arithmetic for financial quantities.

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

[cmd/l06/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l06/main.go)

```go
package main

import (
	"context"
	"example.com/learn/go-advanced/pipeline"
	"fmt"
)

func main() {
	values, err := pipeline.Squares(context.Background(), []int{1, 2, 3}, 2)
	if err != nil {
		panic(err)
	}
	fmt.Println(values)
}
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l06
```

### Expected output contract

```text
[1 4 9]
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. Who is allowed to close results, and when?

<details>
<summary>Complete solution</summary>

The coordinator closes it only after WaitGroup confirms all workers have stopped sending. A worker closing it could make another worker send on a closed channel. The producer owns only jobs.

</details>

2. Does a fixed worker count guarantee constant memory?

<details>
<summary>Complete solution</summary>

No. Input and output slices still grow with the number of values. To process an unlimited source, expose streaming consumption with cancellation or impose a documented input bound instead of collecting everything.

</details>

## Primary sources

- [Pipelines and cancellation](https://go.dev/blog/pipelines)
- [context](https://pkg.go.dev/context)

[Next lesson](../07-cancellation-deadlines-and-shutdown/) · [Learning journal](../journal/)
