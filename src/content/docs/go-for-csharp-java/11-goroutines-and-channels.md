---
title: "11. Goroutines and channels"
description: "Stream records with an owned sender, explicit closure and cancellable sends."
sidebar:
  order: 11
---

## Learning objectives

Trace an unbuffered handoff, assign responsibility for closing a channel and give a blocked sender a cancellation path.

## Concurrency needs a lifetime

A [go statement](https://go.dev/ref/spec#Go_statements) starts a goroutine executing a function. It is not a returned future that automatically joins itself. The caller must decide how work completes, how failure is communicated and how cancellation stops abandoned work. Our Stream starts one producer and returns a receive-only channel. The command consumes until that producer closes the channel, which establishes a clear completion path without sleeping or guessing how quickly another goroutine runs.

A [channel](https://go.dev/ref/spec#Channel_types) transfers values between goroutines. The unbuffered channel in Stream makes each successful send meet a receiver. It does not store an arbitrary backlog. A buffered channel instead permits a bounded number of queued values. Capacity changes scheduling and backpressure, but it does not replace a termination policy. Choose a buffer to express a real bound, not to hide a producer that nobody will ever consume.

## Own the close operation

The producer creates the channel and defers close before sending records. Only that producer knows when it has no more values. The consumer ranges over the channel and stops when it is closed and drained. Receivers should not close a channel merely because they want to stop receiving: the sender could still be writing. Closing twice or sending after close is a programming error, so ownership should be apparent in the function structure.

Stream returns a receive-only channel type. That prevents callers from sending or closing through that handle. It documents direction and lets the compiler enforce part of the ownership rule. The values sent are Record copies. Their current fields are safe to read independently after the handoff, but sending a struct containing pointers or maps would not automatically deep-copy that storage.

## Cancellation must reach blocked operations

The [select statement](https://go.dev/ref/spec#Select_statements) in Stream waits for either a receiver or context cancellation. A plain channel send could remain blocked forever if the caller stops consuming. Selecting the cancellation channel provides an exit in that case. The command owns cancel and defers it, so abandoning the operation through a normal return can release the producer. A context does not forcibly terminate arbitrary code; the operation must observe it.

If several select cases are ready, cancellation is not guaranteed to win every individual selection. Do not promise that cancellation prevents every final value from racing with observation. Our Count checks cancellation before starting and again after the stream finishes; its result contract is separate from a claim that no value could ever be sent near cancellation. Tests use explicit cancellation and channel completion instead of sleeps to establish ordering.

## Relate this to tasks and threads

[C# Task](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task) and [Java virtual threads](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html) offer familiar ways to think about independent work, but goroutines and channels have their own completion semantics. The [Go memory model](https://go.dev/ref/mem) defines synchronization relationships for channel operations. Simply starting a goroutine does not make arbitrary shared writes safe. The example avoids a shared accumulator: only the consumer adds minutes. Its expected forty is independent of how the scheduler interleaves the handoffs.

## Worked example

Complete source: [`cmd/l11/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l11/main.go).

```go
package main

import (
	"context"
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	var total study.Minutes
	for record := range study.Stream(ctx, study.Fixture()) {
		total += record.Minutes
	}
	fmt.Printf("stream-total=%d\n", total)
}
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l11
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
stream-total=40
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. Can the consumer safely close the channel after receiving one record?

<details>
<summary>Solution 1</summary>

No. The producer may still send the second record, so consumer closure would violate the ownership rule. If the consumer wants to abandon the stream, it should cancel the context it owns and return. The producer observes cancellation through select and closes its own channel on exit.

</details>

2. Why does a buffer of two not solve every producer leak?

<details>
<summary>Solution 2</summary>

It only lets this fixture’s two sends finish without an immediate receiver. A larger or unbounded source can still fill the buffer and block. The durable solution is a bounded lifetime: the cancellation case lets a blocked producer exit, while close and consumption describe normal completion. Capacity and cancellation solve different problems.

</details>

## Official sources

- [Go statements](https://go.dev/ref/spec#Go_statements)
- [Channel types](https://go.dev/ref/spec#Channel_types)
- [Select statements](https://go.dev/ref/spec#Select_statements)
- [Go memory model](https://go.dev/ref/mem)

[Next lesson](../12-http-and-context/) · [Journal](../journal/)
