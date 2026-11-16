---
title: "3. Control flow and functions"
description: "Write explicit transformations with loops, multiple returns and small functions."
sidebar:
  order: 3
---

## Learning objectives

Trace a selection loop, distinguish declaration from assignment, and choose a clear function boundary.

## Make the transformation visible

Go's [control-flow statements](https://go.dev/ref/spec#Statements) let us express our study-log rule directly: keep records whose duration reaches a minimum, then add their minutes. Start with a plain loop before inventing a fluent pipeline. The command delegates selection and summation to two small functions. Their names express different questions, and the selected slice is an ordinary intermediate value that can be inspected or tested independently.

There is one loop keyword, for. It supports a condition, initialization and update, an unconditional loop, or range over a supported value. A range over our slice supplies an index and an element value. We discard the unused index with the blank identifier. That element is a copy of a Record. Reading its Minutes is straightforward; assigning to the copied record would not rewrite the original slice element. Lesson four examines where shared backing storage changes that picture.

## Follow the branches and return values

Select allocates an initially empty result and appends each record satisfying an inclusive comparison. With the fixture's fifteen and twenty-five minutes, a minimum of twenty selects only the second record. The input order is preserved because the loop appends in encounter order. Total initializes its accumulator to the zero value of Minutes and adds each selected value. Empty input therefore produces zero without a special branch. These small decisions are the public behavior that tests should observe.

Go conditions do not need parentheses, but their bodies use braces. An if statement can introduce a short-lived variable before its condition; later examples use that pattern for errors. Keep the variable's scope narrow enough that a reader can tell which operation produced it. A short declaration must introduce at least one new nonblank variable in the current scope. Using it inside another block can create a different variable instead of updating the one you intended.

[Functions](https://go.dev/ref/spec#Function_declarations) can return several values. We will use a value and an error instead of hiding ordinary failure behind an exception. Parameters are passed by value; copying a pointer or slice descriptor still carries access to shared data, so passing by value does not promise deep isolation. A function value can also be stored or passed to another function. Lesson ten uses that ability to parameterize a collection transformation without introducing a class hierarchy.

## Translating familiar idioms

C# developers may reach for [Enumerable.Where](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.where); Java developers may think of [Stream.filter](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/Stream.html#filter(java.util.function.Predicate)). Our explicit loop is eager and returns a materialized slice. It does not create a deferred query object, and repeated iteration does not rerun a predicate. This distinction matters when the data can change or a predicate has effects. Here the comparison is pure and its result is reusable.

An expressionless switch can express ordered conditions, while ordinary cases do not fall through automatically. Use it when it clarifies a genuine choice rather than replacing every if statement. Avoid translating an entire enterprise service framework just to organize two functions. The current seam is sufficient: Select owns filtering and Total owns summation. Neither prints, parses arguments nor opens files. That makes their behavior reusable in the later HTTP and CLI boundaries.

## Read the worked result carefully

The example's selected count is one, but its total is twenty-five. A count and a sum are different measurements. Change the threshold to fifteen on paper and trace both records before running anything. The result would contain both records and sum to forty. At twenty-five the comparison still includes the second record. This boundary is exactly where an accidental strict comparison would produce a plausible but wrong report.

## Worked example

Complete source: [`cmd/l03/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l03/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	records := study.Select(study.Fixture(), 20)
	fmt.Printf("selected=%d total=%d\n", len(records), study.Total(records))
}
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l03
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
selected=1 total=25
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. What happens at minimum twenty-five, and at minimum twenty-six?

<details>
<summary>Solution 1</summary>

The inclusive comparison keeps the twenty-five-minute record at the first threshold, so the count is one and the total is twenty-five. At twenty-six neither record qualifies; the result has length zero and Total returns its zero accumulator. No special empty-input branch is required.

</details>

2. Where should argument parsing and output formatting go?

<details>
<summary>Solution 2</summary>

Keep them outside Select and Total. The CLI package translates flags into a Minutes threshold, calls Select, then formats the returned records and Total. The complete Select function below shows the reusable core. It receives typed data and returns typed data, which also makes a boundary test independent of a terminal.

</details>

## Official sources

- [For statements](https://go.dev/ref/spec#For_statements)
- [Function declarations](https://go.dev/ref/spec#Function_declarations)
- [If statements](https://go.dev/ref/spec#If_statements)

[Next lesson](../04-arrays-and-slices/) · [Journal](../journal/)
