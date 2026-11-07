---
title: "6. Pointers and methods"
description: "Choose value and pointer receivers by their mutation and method-set contracts."
sidebar:
  order: 6
---

## Learning objectives

Trace a copied record, explain implicit address-taking at a method call, and distinguish receiver mutation from shared identity.

## A pointer is a value that identifies storage

A [pointer](https://go.dev/ref/spec#Pointer_types) holds the address of a variable or is nil. Taking an address and dereferencing it are explicit language operations. Go manages ordinary object lifetimes through garbage collection; returning a pointer to a local value is supported without manually allocating and freeing memory. This does not remove ownership questions. A pointer lets callers reach the same mutable object, so sharing it changes what one caller can observe after another writes.

The worked program first copies a Record into copy. Because the fields are a string and Minutes, the two records can subsequently be updated independently. Calling copy.Add changes the copy from fifteen to twenty. Calling record.Add changes the original local from fifteen to twenty-five. We print both values to distinguish copying the record from passing an address to a method. There is no hidden deep copy at the method call.

## Choose what the receiver promises

A [method](https://go.dev/ref/spec#Method_declarations) is a function associated with a receiver type. Label has a value receiver because it only reads a field. Add has a pointer receiver because it updates the pointed-to Record. The receiver itself is still passed by value: copying a pointer retains access to its target. A value receiver receives a copy of the record and cannot replace the caller's fields merely by assigning its own fields.

For an addressable local variable, Go can take its address implicitly when calling a pointer-receiver method. That convenience does not mean the value type has every method in every context. Method sets control interface satisfaction, which is the next lesson's subject. Also distinguish a nil pointer from a zero Record. The latter has accessible zero fields; dereferencing the former is invalid unless the method deliberately handles nil without dereferencing it.

## Compare familiar object models

[C# struct](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/struct) copying is a useful starting comparison, while Java references are a useful model for intentionally shared pointed-to storage. Neither analogy fully defines Go. There is no universal object base class, and declaring a method does not require a class hierarchy. A pointer receiver is not a marker that the compiler must put the value on the heap; escape analysis and implementation choices determine placement.

Avoid choosing pointer receivers solely because a record seems large, before measuring or considering consistency. Mutation is already a sufficient reason for Add. Mixing receiver styles should reflect a clear contract, especially when interfaces enter the design. A method cannot make a copied mutable nested field independent simply by receiving the outer struct by value. The slice lesson's shallow-copy rule still applies.

## Give callers an understandable boundary

The capstone reads immutable input records and produces selected values, so it does not need to mutate every record through a shared pointer. Add is a focused teaching example, not a reason to redesign the whole model around identity. When reviewing the code, identify exactly which variable is addressable and which storage each call changes. That concrete trace is more reliable than saying that Go passes objects by reference. Everything is passed by value; some of those values deliberately refer to shared storage.

## Worked example

Complete source: [`cmd/l06/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l06/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	record := study.Fixture()[0]
	copy := record
	copy.Add(5)
	record.Add(10)
	fmt.Printf("record=%d copy=%d\n", record.Minutes, copy.Minutes)
}
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l06
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
record=25 copy=20
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. If copy.Add runs again with five, does record change?

<details>
<summary>Solution 1</summary>

No. copy and record are distinct struct variables after assignment. The second pointer-receiver call addresses copy and raises its duration from twenty to twenty-five. record remains twenty-five from its own earlier update. Equal final numbers would not imply shared identity; they would be independent results of separate mutations.

</details>

2. Which receiver should a read-only Label use, and why does Add differ?

<details>
<summary>Solution 2</summary>

Label can use a value receiver because it reads a field and need not modify caller storage. Add needs a pointer receiver to update the target record. The checked-in declarations implement exactly that distinction. An interface accepting Label can work with values and pointers according to their method sets; mutation is a separate requirement.

</details>

## Official sources

- [Pointer types](https://go.dev/ref/spec#Pointer_types)
- [Method declarations](https://go.dev/ref/spec#Method_declarations)
- [Method sets](https://go.dev/ref/spec#Method_sets)

[Next lesson](../07-interfaces-and-composition/) · [Journal](../journal/)
