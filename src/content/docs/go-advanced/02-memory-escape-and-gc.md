---
title: "2. Memory, escape analysis and GC"
description: "Separate aliasing guarantees from compiler allocation choices, and prepare an honest measurement."
sidebar:
  order: 2
---

## Learning objective

Separate aliasing guarantees from compiler allocation choices, and prepare an honest measurement.

## Mechanics and mental models

The [GC guide](https://go.dev/doc/gc-guide) explains a tracing collector that follows reachable objects. A pointer does not imply a heap allocation, and a local declaration does not imply a stack allocation. Escape analysis decides whether storage can stay within the current lifetime; inlining and compiler versions can change that decision. Returning a pointer to a local value is safe because Go preserves its lifetime. Treat an escape report as an explanation of one compilation, not a permanent property of a line of source.

A slice is a descriptor over an array. Copying the descriptor shares storage; reslicing changes the visible window without releasing a large referenced array. Our Clone function allocates independent storage for the visible bytes. Mutating source afterward changes only source. NewJob applies the same ownership decision to integers. This is a semantic guarantee we can test without knowing whether a compiler places any particular object on the stack or heap. Copying a nested slice would require a separate decision for each referenced layer.

Coming from C# arrays or Java array references, distinguish a Go array value from a slice referencing an array. A Go array assignment copies elements. A slice assignment copies only its descriptor. Neither garbage collection nor synchronization makes shared mutable elements independent. Avoid retaining a tiny window of a huge buffer across a long lived request cache; clone the portion whose ownership you actually need. The additional copy can reduce retained memory while increasing allocation traffic, so the useful metric depends on the workload.

Run escape diagnostics with go build -gcflags=-m=2 ./domain and compare the exact compiler version, flags and source revision. That command is a proposed experiment here; no diagnostic transcript has been captured. Likewise, benchmark allocation counts before introducing a pool. A pool is allowed to discard entries and does not confer exclusive ownership after a value is returned. GC tuning changes a CPU and memory tradeoff; it cannot repair an accidentally retained object graph. Prefer a clear lifetime boundary before tuning a collector setting.

## Worked runnable example

The executable belongs to the independent module `example.com/learn/go-advanced`. Its command is a small caller of reusable packages rather than the only location of the behavior. Read the package file first, then follow its calls from the command. The complete checked-in files appear below so imports, error paths and cleanup remain visible. No hidden notebook state or external service is required. Commands use the same working directory and syntax on Windows, Linux/WSL and macOS once Go is on PATH.

### Reusable source

[domain/job.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/domain/job.go)

```go
package domain

import (
	"errors"
	"fmt"
	"strings"
)

var ErrInvalid = errors.New("invalid job")

type Job struct {
	Name   string
	Values []int
}

func NewJob(name string, values []int) (Job, error) {
	if strings.TrimSpace(name) == "" {
		return Job{}, fmt.Errorf("name: %w", ErrInvalid)
	}
	return Job{Name: name, Values: append([]int(nil), values...)}, nil
}

func (j Job) Total() int {
	var total int
	for _, v := range j.Values {
		total += v
	}
	return total
}

func Clone(data []byte) []byte { return append([]byte(nil), data...) }

type ValidationError struct{ Field string }

func (e *ValidationError) Error() string {
	if e == nil {
		return "nil validation"
	}
	return "invalid " + e.Field
}
func Validate(name string) error {
	if name == "" {
		return &ValidationError{Field: "name"}
	}
	return nil
}
func TypedNil() error { var e *ValidationError; return e }
```

[cmd/l02/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l02/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/domain"
	"fmt"
)

func main() {
	source := []byte{1, 2}
	copy := domain.Clone(source)
	source[0] = 9
	fmt.Println(source, copy)
}
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l02
```

### Expected output contract

```text
[9 2] [1 2]
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. Does returning a local pointer make it dangling?

<details>
<summary>Complete solution</summary>

No. Go keeps the referenced storage alive. Allocation location is decided by the implementation; memory safety follows from the language lifetime, not a guess about stack frames.

</details>

2. A cache keeps 20 bytes from a 20 MB buffer. What change and measurement would you propose?

<details>
<summary>Complete solution</summary>

Clone the visible bytes before retaining them. Compare retained heap and allocation traffic with identical workloads and GC conditions. Do not declare a speed improvement from the ownership test or from the size ratio alone.

</details>

## Primary sources

- [GC guide](https://go.dev/doc/gc-guide)
- [Compiler options](https://pkg.go.dev/cmd/compile)

[Next lesson](../03-generics-and-iterators/) · [Learning journal](../journal/)
