---
title: "10. Generics and collections"
description: "Build a typed eager mapping function and understand constraints without relying on outdated limits."
sidebar:
  order: 10
---

## Learning objectives

Read type parameters, infer input and output types from a callback, and separate generic functions from interface requirements.

## Reuse an algorithm without hiding its types

[Type parameters](https://go.dev/ref/spec#Type_parameter_declarations) let an algorithm describe a family of concrete operations. Our Map function accepts a slice of T and a conversion from T to U, then returns a slice of U. The compiler checks that the callback accepts the input element type and that every returned value matches the output element type. No interface conversion to any is necessary for each element, and the caller receives a statically typed result.

In the command, T is Record and U is string. [Type inference](https://go.dev/ref/spec#Type_inference) uses the fixture slice and callback signature, so the call need not spell out both arguments. Map allocates the final length, assigns one converted result per index and preserves order. It is eager: all callbacks run before it returns. It is not a lazy query pipeline and does not automatically parallelize the work.

## Constraints determine permitted operations

Both parameters use any because Map neither compares nor adds values of those types. It passes T to the callback and stores U. A function using equality would require an appropriate comparable constraint; a numeric algorithm would need a constraint supporting its operators. A broader constraint is not automatically more flexible if it prevents the implementation from doing its required operation. State only the operations the algorithm genuinely needs.

Named types and their underlying types matter when designing reusable constraints. Do not casually erase Minutes back to int just to satisfy a helper. The current map keeps the conversion explicit at the callback and allows different output types without sacrificing the domain type elsewhere. Type safety does not prove that a callback's business rule is correct; tests still check order, values and empty input.

## A generic helper is not every collection operation

The result has independently allocated slice storage, but converted values may still contain references. Mapping a Record into another Record does not promise a deep clone. The callback also has no error return in this particular contract. If conversion can fail, a separate function returning a result and error would need a defined policy for partial results. Do not silently drop failures to preserve the convenient Map signature.

[C# Enumerable.Select](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.select) and [Java Stream.map](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/Stream.html#map(java.util.function.Function)) provide useful comparisons for element transformation. Their surrounding execution models differ from this eager slice helper. Avoid importing expectations about deferred execution, iterator invalidation or parallel streams into a function whose complete implementation is a short loop.

## Teach the current language

Go 1.27 supports concrete methods with their own type parameters. Older material saying that generic methods are universally forbidden is outdated. Interface methods still cannot declare their own type parameters, and generic methods do not implement such interface requirements. This course uses a generic function because an operation over arbitrary slices has a natural package-level home, not because the current language prohibits every alternative.

Reach for generics when the same typed algorithm is needed across types. Our earlier Select remains domain-specific and clearer for filtering study durations. There is no need to turn every helper into a universal collection framework. The important capability here is a small typed transformation whose allocation, ordering and evaluation behavior are visible.

## Worked example

Complete source: [`cmd/l10/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l10/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	labels := study.Map(study.Fixture(), func(record study.Record) string { return record.Label() })
	fmt.Printf("labels=%v\n", labels)
}
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l10
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
labels=[types go]
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. What are T and U in the worked call, and when does the callback execute?

<details>
<summary>Solution 1</summary>

T is study.Record and U is string. The callback runs once for each of the two records during Map, before main prints the result. The output order remains types then go because each result is assigned to the same index as its input. No deferred enumeration remains to execute later.

</details>

2. Would any allow Map to add two T values?

<details>
<summary>Solution 2</summary>

No. The constraint does not guarantee an addition operation. This implementation needs no such operation: it only passes values to the callback and stores results. A numeric algorithm would require a suitable constraint. Keep the current generic function small rather than weakening types with assertions or inventing an arithmetic policy for arbitrary values.

</details>

## Official sources

- [Type parameters](https://go.dev/ref/spec#Type_parameter_declarations)
- [Type inference](https://go.dev/ref/spec#Type_inference)
- [Go 1.27 generic methods](https://go.dev/doc/go1.27#language)

[Next lesson](../11-goroutines-and-channels/) · [Journal](../journal/)
