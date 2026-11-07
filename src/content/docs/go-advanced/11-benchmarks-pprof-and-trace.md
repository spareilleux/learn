---
title: "11. Benchmarks, pprof and trace"
description: "Choose a measurement that answers a performance question without inventing timings."
sidebar:
  order: 11
---

## Learning objective

Choose a measurement that answers a performance question without inventing timings.

## Mechanics and mental models

A [benchmark](https://pkg.go.dev/testing#hdr-Benchmarks) is an experiment around a specific operation and input distribution. BenchmarkSum builds a fixed slice before the timed loop, reports allocations and stores the result in a package variable. The sink makes the result observable. The loop measures summation instead of repeatedly constructing its input. This is a microbenchmark of one workload; it does not establish HTTP throughput, cancellation latency or end-to-end service capacity.

Use go test -run="^$" -bench=BenchmarkSum -benchmem ./metrics to request a measurement. Record compiler version, operating system, CPU, revision, flags and input size with the output. Compare repeated runs rather than one attractive number. No ns/op, bytes/op or allocations/op are quoted here because none have been measured for this authored unit. A change can reduce allocation traffic while retaining more memory, so pair the metric with the question instead of declaring every smaller counter universally better.

[Diagnostics](https://go.dev/doc/diagnostics) separates profiles from execution traces. A CPU profile samples where execution spends time; a heap profile helps investigate allocations or retained objects; a trace exposes scheduler, blocking and runtime events over time. Generate local artifacts with go test -run="^$" -bench=BenchmarkSum -cpuprofile=cpu.out ./metrics and inspect with go tool pprof -http=127.0.0.1:0 cpu.out. Keep profiling listeners on loopback. Profiles can contain sensitive paths and workload information, so handle artifacts according to the application's data policy.

C# and Java profiling habits transfer at the question level: establish a baseline, locate the cost, change one hypothesis, measure again. Go has different runtime signals and tool commands. Go 1.27 adds a goroutineleak profile to runtime/pprof; it is not complete detection of every logical leak or blocked worker. Join signals and drain tests remain necessary. Tracing, profiling and race instrumentation also add overhead, so do not compare an instrumented run with an uninstrumented baseline as if the difference came from the code change.

## Worked runnable example

The executable belongs to the independent module `example.com/learn/go-advanced`. Its command is a small caller of reusable packages rather than the only location of the behavior. Read the package file first, then follow its calls from the command. The complete checked-in files appear below so imports, error paths and cleanup remain visible. No hidden notebook state or external service is required. Commands use the same working directory and syntax on Windows, Linux/WSL and macOS once Go is on PATH.

### Reusable source

[metrics/sum_test.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/metrics/sum_test.go)

```go
package metrics

import "testing"

var sink int

func TestSum(t *testing.T) {
	if Sum([]int{2, 3, 4}) != 9 {
		t.Fatal("sum")
	}
}
func BenchmarkSum(b *testing.B) {
	values := make([]int, 1024)
	for i := range values {
		values[i] = i
	}
	b.ReportAllocs()
	for b.Loop() {
		sink = Sum(values)
	}
}
```

[cmd/l11/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l11/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/metrics"
	"fmt"
)

func main() { fmt.Println(metrics.Sum([]int{1, 2, 3})) }
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l11
```

### Expected output contract

```text
6
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. Why prepare input outside the timed loop?

<details>
<summary>Complete solution</summary>

The question is the cost of summation on an existing slice. Including construction would measure another operation. If construction is part of the real workload, write a separately named benchmark that includes it deliberately.

</details>

2. Does a clean goroutineleak profile replace shutdown tests?

<details>
<summary>Complete solution</summary>

No. The profile has a particular runtime detection scope, while tests assert application completion contracts. Keep explicit joins and cancellation tests, then use profiles to investigate behavior observed under a representative workload.

</details>

## Primary sources

- [testing benchmarks](https://pkg.go.dev/testing#hdr-Benchmarks)
- [Diagnostics](https://go.dev/doc/diagnostics)
- [runtime/pprof](https://pkg.go.dev/runtime/pprof)
- [runtime/trace](https://pkg.go.dev/runtime/trace)

[Next lesson](../12-reflection-and-encoding/) · [Learning journal](../journal/)
