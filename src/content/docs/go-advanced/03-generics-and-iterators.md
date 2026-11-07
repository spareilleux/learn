---
title: "3. Generics and iterators"
description: "Implement a lazy generic transformation that stops when its consumer stops."
sidebar:
  order: 3
---

## Learning objective

Implement a lazy generic transformation that stops when its consumer stops.

## Mechanics and mental models

The [iter](https://pkg.go.dev/iter) package names iterator function shapes. Seq takes a yield callback; returning false from yield means that the consumer has stopped. Map transforms one value at a time and immediately returns when yield returns false. Nothing is materialized until the consumer asks for values. slices.Collect deliberately materializes the result in the command. Separating these decisions lets the caller choose between streaming, early exit and collecting all results.

Unlike a Java Stream pipeline, this iterator is an ordinary function value with a documented calling convention. Unlike a C# iterator block, its public type is a callback based sequence rather than an IEnumerator object. Both analogies help explain laziness but neither substitutes for obeying yield. Calling yield again after it returned false breaks the contract. Starting a goroutine inside every iterator is unnecessary and would introduce cancellation and lifetime problems absent from a synchronous callback.

Map has two type parameters because the output need not have the input type. any expresses that no operations on a value are required beyond passing it to the supplied function. A comparable constraint would add an equality capability that this transformation does not use. Constraints containing underlying type terms describe sets of admissible types; they are not ordinary runtime sum values. Keep behavioral interfaces and constraints conceptually distinct even when their syntax overlaps.

This course targets Go 1.27. Its release notes add generic methods; older statements that methods can never introduce type parameters are obsolete for this baseline. Interface methods still cannot introduce their own type parameters. The example uses a generic package function because transformation does not require receiver state, not because generic methods are forbidden. The early stop test counts transformations and breaks after the first result. That verifies a useful lifetime property, while a collected list alone would miss an iterator that kept doing unnecessary work.

## Worked runnable example

The executable belongs to the independent module `example.com/learn/go-advanced`. Its command is a small caller of reusable packages rather than the only location of the behavior. Read the package file first, then follow its calls from the command. The complete checked-in files appear below so imports, error paths and cleanup remain visible. No hidden notebook state or external service is required. Commands use the same working directory and syntax on Windows, Linux/WSL and macOS once Go is on PATH.

### Reusable source

[collection/sequence.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/collection/sequence.go)

```go
package collection

import "iter"

func Map[A, B any](input iter.Seq[A], f func(A) B) iter.Seq[B] {
	return func(yield func(B) bool) {
		for value := range input {
			if !yield(f(value)) {
				return
			}
		}
	}
}

func Reverse(s string) string {
	r := []rune(s)
	for i, j := 0, len(r)-1; i < j; i, j = i+1, j-1 {
		r[i], r[j] = r[j], r[i]
	}
	return string(r)
}
```

[cmd/l03/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l03/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/collection"
	"fmt"
	"slices"
)

func main() {
	values := collection.Map(slices.Values([]int{1, 2, 3}), func(v int) int { return v * 2 })
	fmt.Println(slices.Collect(values))
}
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l03
```

### Expected output contract

```text
[2 4 6]
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. Why must Map return immediately when yield returns false?

<details>
<summary>Complete solution</summary>

The consumer has ended iteration. Returning propagates that decision upstream and prevents extra callbacks, work and resource retention. TestMapStops expects exactly one transformation after an immediate break.

</details>

2. Would comparable improve the Map signature?

<details>
<summary>Complete solution</summary>

No equality operation is needed, so it would reject useful inputs without proving anything the body needs. Keep any; use a stronger constraint only when implementing an operation that requires it.

</details>

## Primary sources

- [Go 1.27 release notes](https://go.dev/doc/go1.27)
- [iter](https://pkg.go.dev/iter)
- [slices](https://pkg.go.dev/slices)

[Next lesson](../04-error-contracts-and-typed-nil/) · [Learning journal](../journal/)
