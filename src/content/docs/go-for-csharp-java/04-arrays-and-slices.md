---
title: "4. Arrays and slices"
description: "Understand copied arrays, shared slice storage, append and explicit cloning."
sidebar:
  order: 4
---

## Learning objectives

Draw the storage shared by two slices, separate length from capacity, and choose when a shallow clone is sufficient.

## The collection is not always the storage

An [array](https://go.dev/ref/spec#Array_types) contains a fixed number of elements, and its length belongs to its type. Assigning an array copies those elements. A [slice](https://go.dev/ref/spec#Slice_types) instead describes a segment of an underlying array. Its length is the number of accessible elements; its capacity describes how far that segment can extend before [`append`](https://pkg.go.dev/builtin#append) needs another allocation. Copying the slice value copies this description. It does not automatically copy the elements it describes.

Our fixture returns a fresh slice of two Record values. The expression selecting its first element as a slice creates another view of the same backing array. Updating that view's first record therefore updates the record read through the original slice. In contrast, study.Clone delegates to [slices.Clone](https://pkg.go.dev/slices#Clone), which allocates a separate element sequence. The detached first record keeps fifteen minutes when the shared original becomes thirty. This is an ownership question, not a mysterious change in assignment rules.

## Append can change who shares what

append returns a slice, so retain its result. When existing capacity suffices it may reuse the backing array; otherwise it allocates storage and copies existing elements. Do not write correctness logic that depends on an undocumented capacity growth ratio. Two seemingly similar examples can alias differently because their capacities differ. If your requirement is independent storage, clone explicitly instead of hoping that a later append will happen to allocate.

The nil slice has length and capacity zero and can be ranged over or appended to. A nonnil empty slice also has length zero, but the distinction can matter to serialization or API contracts. An index must be within length, even when spare capacity exists. Use slicing to extend a view only when that operation is intentional. Passing a slice to a function copies its descriptor; changes to shared elements remain visible, but reassigning the local descriptor does not update the caller's variable.

## Copy depth follows element shape

The current Record contains a string and a numeric Minutes value. A shallow element copy is enough to isolate subsequent assignment to those fields; strings themselves are immutable. If Record later contained a mutable map or another slice, cloning the outer slice would copy those descriptors while leaving their referenced storage shared. Do not advertise Clone as a universal deep-copy facility. Its guarantee should stay tied to the current data model and standard library contract.

C# arrays and Java arrays are reference-bearing objects, so a direct variable assignment there shares the array object. Go array assignment copies, while slice assignment shares underlying storage through copied descriptors. That difference makes translating the word array unreliable. Ask which type a declaration actually names. A slice is not a growable object with methods equivalent to every collection operation you know; built-ins and ordinary functions provide its basic operations.

## Diagnose an alias before fixing it

Trace the three names in the worked command. original and alias reach the same first record; detached reaches another record. The mutation goes through alias, but the output reads original and detached. This deliberately makes the relationship observable. The authored test checks both sides, so a change that accidentally removes aliasing or accidentally shares the clone would fail. A full slice expression can restrict capacity and constrain append reuse, but it does not isolate writes to existing elements. Clone is the appropriate operation when those writes must be independent.

## Worked example

Complete source: [`cmd/l04/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l04/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	original := study.Fixture()
	alias := original[:1]
	detached := study.Clone(alias)
	alias[0].Minutes = 30
	fmt.Printf("original=%d clone=%d\n", original[0].Minutes, detached[0].Minutes)
}
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l04
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
original=30 clone=15
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. Why is the result original thirty and clone fifteen?

<details>
<summary>Solution 1</summary>

The alias addresses the first element of the same backing array as original, so assigning thirty through alias changes what original reads. Clone copied that element before the assignment. Its separate backing array still contains fifteen. Reversing the order of cloning and assignment would copy thirty instead.

</details>

2. Would cloning isolate a map field added to Record?

<details>
<summary>Solution 2</summary>

No. A shallow slice clone copies each map value, which still refers to the same map storage. Either keep the current immutable field model or define and test a deeper copying rule for the new field. Restricting slice capacity also would not isolate existing map entries or existing slice elements.

</details>

## Official sources

- [Array types](https://go.dev/ref/spec#Array_types)
- [Slice types](https://go.dev/ref/spec#Slice_types)
- [slices.Clone](https://pkg.go.dev/slices#Clone)

[Next lesson](../05-maps-and-structs/) · [Journal](../journal/)
