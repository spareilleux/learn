---
title: 10. Shared state and the thread pool
description: Choose Lock, Interlocked, concurrent collections and Parallel.ForEachAsync by invariant, then diagnose starvation without turning every asynchronous wait into a worker thread.
sidebar:
  order: 10
---

Concurrency bugs do not require unlucky hardware. Two workers can read the same value, both compute the same successor and both write it. The executable lesson forces that schedule with a barrier: two increments leave `1`.

## Protect the invariant, not the line

[`System.Threading.Lock`](https://learn.microsoft.com/dotnet/api/system.threading.lock) is the modern .NET lock primitive. Use it when several reads and writes form one invariant. [`Interlocked`](https://learn.microsoft.com/dotnet/api/system.threading.interlocked) is better for one atomic counter or compare-and-swap loop. A concurrent collection makes its own operation safe; it does not make a sequence such as “check, call a remote service, then update” atomic.

The measured program runs 10,000 updates through both mechanisms:

```text
two increments without synchronization: 1
Lock count: 10000
Interlocked count: 10000
AddOrUpdate count: 1000
```

`ConcurrentDictionary.AddOrUpdate` may invoke a value factory more than once under contention. Keep factories pure and treat side effects as a separate, idempotent operation.

## Parallelism is a budget

[`Parallel.ForEachAsync`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.parallel.foreachasync) bounds concurrently active bodies with `MaxDegreeOfParallelism`. The lesson observes exactly two active bodies for a configured degree of two. This is a local budget, not end-to-end backpressure: the database pool, sockets and broker queues need their own limits.

Thread-pool starvation happens when worker threads block while queued work needs those workers to make progress. Prefer asynchronous waits for I/O, keep CPU work bounded, and diagnose with `dotnet-counters` before raising minimum threads. More threads can hide the symptom while increasing memory and context switching.

## Run the proof

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l10
```

The portable assertions are stored in [`expected/l10.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l10.txt); machine-dependent thread-pool minimums are printed with `#` and excluded from comparison.

## Exercises

1. Replace the `Lock` counter with a two-field invariant: total and checksum. Show why two `Interlocked.Increment` calls do not make the pair atomic.
2. Put an HTTP call inside `ConcurrentDictionary.GetOrAdd`. Count how many calls occur under contention, then remove the side effect.
3. Compare `Parallel.ForEachAsync` degrees 2, 8 and 64 against a dependency limited to four concurrent calls.

<details>
<summary>Solutions</summary>

1. Protect both fields with one `Lock`, or replace the pair atomically as one immutable value with compare-and-swap. Two independent atomic writes expose an intermediate state.
2. The factory may run repeatedly even though only one value wins. Cache a task only when its failure/cancellation semantics are intentional, or perform an idempotent operation outside the collection primitive.
3. Degree 2 underuses the dependency, 8 adds queuing, and 64 usually adds latency without throughput. The falsifier is measured throughput and tail latency, not CPU count alone.

</details>
