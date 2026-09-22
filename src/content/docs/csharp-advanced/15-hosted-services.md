---
title: 15. Hosted services and background work
description: Own startup, shutdown, faults, bounded queues and dependency-injection scopes with IHostedService and BackgroundService.
sidebar:
  order: 15
---

An [`IHostedService`](https://learn.microsoft.com/dotnet/core/extensions/scoped-service) participates in the host lifetime. [`BackgroundService`](https://learn.microsoft.com/dotnet/core/extensions/workers) supplies the long-running `ExecuteAsync` loop, but the host still owns startup, cancellation and shutdown.

## Prerequisites

Complete [dependency injection and options](13-dependency-injection-options/) and [channels](06-channels/) first. You should already understand service lifetimes, cancellation tokens and asynchronous streams.

## The host owns lifetime

The experiment starts one host, waits on explicit completion gates, processes two items, then asks the host to stop. There is no `Thread.Sleep` and every wait has a five-second bound.

In .NET 10, [all of `BackgroundService.ExecuteAsync` runs on a background thread](https://learn.microsoft.com/dotnet/core/compatibility/extensions/10.0/backgroundservice-executeasync-task). Work that must happen synchronously before other hosted services start belongs in a constructor, [`StartAsync`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.hosting.ihostedservice.startasync), or [`IHostedLifecycleService`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.hosting.ihostedlifecycleservice)—not before the first `await` in `ExecuteAsync`.

## A bounded queue is an application contract

The worker consumes a bounded [`Channel<T>`](https://learn.microsoft.com/dotnet/core/extensions/channels). `BoundedChannelFullMode.Wait` applies backpressure when the queue is full. A real submission API should await `WriteAsync`; this small proof uses `TryWrite` because its capacity and two writes are fixed.

[`AddHostedService`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.dependencyinjection.servicecollectionhostedserviceextensions.addhostedservice) registers the worker as a singleton. A scoped dependency must therefore be resolved inside a fresh [`IServiceScope`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.dependencyinjection.iservicescope) for every item. Injecting it into the worker constructor would turn a per-operation object into a captive dependency.

```text
== The host starts one singleton worker and the queue owns the work
startup observed: True
queued results: C major@scope-1 | G major@scope-2
fresh scope per item: True
shutdown cancellation observed: True
```

## Faults are policy

The default .NET 10 host policy stops the application when a `BackgroundService` throws. The proof sets `BackgroundServiceExceptionBehavior.StopHost` explicitly, releases a fault gate and observes `ApplicationStopping`:

```text
== A BackgroundService fault stops its host
fault requested host stop: True
```

Stopping the host is not recovery. Production code still needs an explicit retry, dead-letter or operator policy around work that may be safely repeated.

## Run the proof

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l15
```

The checked transcript is [`expected/l15.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l15.txt).

## Exercises

1. Replace `TryWrite` with an asynchronous submission API and prove a third item waits while the two-slot queue is full.
2. Add one failure result to each work item without terminating the singleton worker.
3. Introduce a second consumer and state which ordering guarantee is lost.

<details>
<summary>Solutions</summary>

1. Return `ValueTask` from submission, await `Writer.WriteAsync`, and use gates to hold the first two items. Release one gate and assert the third write completes—never infer blocking from a delay.
2. Catch the operation exception around one item, complete its `TaskCompletionSource` with a typed failure, and continue the read loop. Do not catch host cancellation as a work failure.
3. Set `SingleReader = false` and run two workers. FIFO still governs reads, but completion order now depends on processing; add sequence numbers if downstream code needs reordering.

</details>
