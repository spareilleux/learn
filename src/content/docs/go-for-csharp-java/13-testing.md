---
title: "13. Testing"
description: "Verify observable contracts with table tests, examples, handler tests and a bounded fuzz target."
sidebar:
  order: 13
---

## Learning objectives

Choose a behavior worth testing, distinguish assertions from demonstration output, and understand deterministic cancellation tests.

## A passing printout is not the whole contract

The [testing package](https://pkg.go.dev/testing) discovers test functions in files ending in _test.go. A Test function receives a [`testing.T`](https://pkg.go.dev/testing#T) and records failures through that object. Our command prints the fixture's total and the empty total, but the actual tests assert more: aliasing, independent copies, invalid records, error identity, Unicode counts, ordering and cancellation. The purpose is to make plausible mistakes observable, not merely execute every line once.

TestSelectBoundaryAndOrder uses values at nineteen and twenty minutes. A threshold of twenty must include both boundary records, exclude nineteen and preserve encounter order. It also changes one selected result and verifies that the input element stays unchanged. Those are behavior claims. Rewriting the production loop without changing these claims should keep the test green. Replacing the test expectation with a value computed by Select itself would remove the independent check.

## Tables make scenarios visible

The loader and CLI tests use tables: each row names an input, expected outcome and relevant category. [Subtests](https://pkg.go.dev/testing#hdr-Subtests_and_Sub_benchmarks) identify which scenario failed. Keep rows meaningful. A malformed JSON document, an empty log and a valid zero duration are different contracts; duplicating several equivalent valid names does not provide the same value. Failure messages should show the observed data needed to diagnose the broken claim.

An [example test](https://pkg.go.dev/testing#hdr-Examples) documents a small public behavior and checks its expected output. ExampleTotal prints forty and zero and carries the special output directive understood by the runner. That directive is executable test metadata, not a claim that an author captured a manual terminal session. The manifest separately checks all fourteen command outputs. Each mechanism has a specific role: examples demonstrate stable formatting, while assertions inspect domain behavior and error categories.

## Use real boundaries where inexpensive

The CLI tests call Run with real readers and buffers, exercising flag parsing, JSON loading, selection and report formatting together. A temporary file test exercises file acquisition without a permanent fixture. The HTTP tests invoke the real handler using [`httptest`](https://pkg.go.dev/net/http/httptest). There is no mock of Select returning the number the test wanted, so these tests can detect integration errors between the boundary and core.

The cancellation test cancels before Count and verifies [`context.Canceled`](https://pkg.go.dev/context#Canceled). It does not sleep and hope a goroutine reached a particular instruction. Stream completion also gives the test an observable joining point. Run the race detector as a separate appropriate check; an ordinary unit-test pass does not prove absence of data races. The coordinator owns those authoritative course runs and records their actual environment in the journal.

## Explore inputs without inventing evidence

The authored [fuzz target](https://go.dev/doc/security/fuzz/) seeds Load with a sample, empty array and null. For any successfully accepted input, it asserts nonempty names and nonnegative durations. Errors are legitimate outcomes, so arbitrary malformed input is not itself a fuzz failure. A normal test invocation runs seed cases; a time-bounded fuzz command explores mutations. Do not report discovered case counts or coverage percentages until a real run supplies them.

C# and Java developers can retain the habit of testing observable behavior while using Go's built-in discovery rather than adding an assertion framework immediately. Name the failure mode, create an independent expectation and keep the setup smaller than the behavior under test. The complete tests are part of the checked-in module and remain readable beside the implementation.

## Worked example

Complete source: [`cmd/l13/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l13/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	records := study.Fixture()
	fmt.Printf("fixture-total=%d empty-total=%d\n", study.Total(records), study.Total(nil))
}
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l13
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
fixture-total=40 empty-total=0
```

## An assertion of boundary behavior

[`internal/study/study_test.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/internal/study/study_test.go)

```go
func TestSelectBoundaryAndOrder(t *testing.T) {
	records := []Record{{"first", 20}, {"skip", 19}, {"last", 20}}
	selected := Select(records, 20)
	if len(selected) != 2 || selected[0].Name != "first" || selected[1].Name != "last" {
		t.Fatal(selected)
	}
	selected[0].Name = "changed"
	if records[0].Name != "first" {
		t.Fatal("selection aliases the input elements")
	}
}
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. Which test catches changing the selection comparison from inclusive to strict?

<details>
<summary>Solution 1</summary>

TestSelectBoundaryAndOrder does: its records at exactly twenty minutes must be included by a threshold of twenty. A strict comparison would exclude them and fail both the expected length and order checks. The test does not ask the implementation to calculate its own expectation; the expected records are stated independently.

</details>

2. Does the fuzz target prove every accepted input is safe for unlimited summation?

<details>
<summary>Solution 2</summary>

No. Its property checks names and negative durations, not all arithmetic bounds or resource limits. Passing seed cases also is not a sustained fuzz campaign. Keep the claim tied to the assertions that exist and record real fuzz duration and results only after execution. A stronger domain contract would require corresponding rules and tests.

</details>

## Official sources

- [testing package](https://pkg.go.dev/testing)
- [Example tests](https://pkg.go.dev/testing#hdr-Examples)
- [Subtests](https://pkg.go.dev/testing#hdr-Subtests_and_Sub_benchmarks)
- [Fuzzing](https://go.dev/doc/security/fuzz/)

[Next lesson](../14-cli-capstone/) · [Journal](../journal/)
