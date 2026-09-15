---
title: "Lesson 8: Rx.NET"
description: Reactive Extensions for .NET 7.0 measured by a program — IObservable and IObserver, cold and hot sources, operators tested in virtual time on notes that form chords, schedulers, the backpressure Rx doesn't have, asynchronous steps and their order, errors and retries — with the counting bug of Guitar Alchemist's reactive demo, and the Reactor operator for each Rx one.
sidebar:
  label: 8. Rx.NET
  order: 8
---

Channels and Dataflow move items that someone *produces*; Rx is for items that *happen*. A key pressed, a MIDI note played, a sensor reading, a message pushed by a server: the source doesn't wait to be asked, and the interesting questions are about time. Which notes were played together? What was the last value before the user stopped moving the slider? [Reactive Extensions for .NET](https://github.com/dotnet/reactive) (Rx.NET) answers them with LINQ operators over [`IObservable<T>`](https://learn.microsoft.com/dotnet/api/system.iobservable-1), and with a scheduler abstraction that lets a test run minutes of events in no time.

Rx is also the ancestor of Reactor. The [Spring Boot, Spring Cloud and Reactor course](../../spring-cloud-reactor/02-reactor-mono-and-flux/) introduces `Flux` by comparing it with `IObservable`, and the table at the end of this lesson goes the other way. The difference that matters most is backpressure: Reactor has it, Rx doesn't, and this lesson measures what that means.

GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Rx links point to tag [`rxnet-v7.0.0`](https://github.com/dotnet/reactive/tree/rxnet-v7.0.0) of `dotnet/reactive`.

## Running the lesson's program

```bash
bash code/csharp-advanced/check.sh                                   # every lesson, compared with expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- l8  # this lesson only, after check.sh
```

The code is [`Advanced/Lesson8.cs`](https://github.com/spareilleux/learn/blob/b4d713f86711b770a75d7504f334c5871c95f820/code/csharp-advanced/Advanced/Lesson8.cs), and its output is compared with [`expected/l8.txt`](https://github.com/spareilleux/learn/blob/b4d713f86711b770a75d7504f334c5871c95f820/code/csharp-advanced/expected/l8.txt). The program references the [`System.Reactive`](https://www.nuget.org/packages/System.Reactive) and [`Microsoft.Reactive.Testing`](https://www.nuget.org/packages/Microsoft.Reactive.Testing) packages, version 7.0.0, released in July 2026.

```text
== Where the types come from
IObservable<T>: System.Private.CoreLib; Observable: System.Reactive 7.0.0.0
```

The two interfaces, `IObservable<T>` and [`IObserver<T>`](https://learn.microsoft.com/dotnet/api/system.iobserver-1), have been part of the base library since .NET Framework 4. Everything else, the operators, the subjects and the schedulers, comes from the package. An observer has three methods, `OnNext`, `OnError` and `OnCompleted`, and the contract is the one Reactor calls signals: any number of `OnNext` calls, then at most one `OnError` or `OnCompleted`, never at the same time.

## Cold and hot

An `IObservable` built with [`Observable.Create`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Creation.cs#L27) runs its function once for each subscriber. That is a *cold* observable, like a `Mono` or `Flux` built from a supplier:

```text
== Cold: each subscriber runs the source
source ran 2 times; first got Dm7 G7 Cmaj7 A7, second got Dm7 G7 Cmaj7 A7
```

A [`Subject<T>`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Subjects/Subject.cs) is both an observer and an observable: whatever you push into it goes to the observers subscribed *at that moment*. That's a *hot* source, like a mouse or a MIDI device:

```text
== Hot: a Subject pushes to whoever is subscribed now
subscribed before G7: G7 Cmaj7; subscribed before Cmaj7: Cmaj7; Dm7 went to nobody
ReplaySubject(2), subscribed after four chords: Cmaj7 A7
Publish() and Connect(): source ran 1 time; both got Dm7 G7 Cmaj7 A7 / Dm7 G7 Cmaj7 A7
```

- Nobody heard `Dm7`, pushed before anyone subscribed; the late subscriber missed `G7` too.
- A `ReplaySubject` keeps the last values for the subscribers that come later: with a buffer of two, a new subscriber gets `Cmaj7` and `A7` at once.
- `Publish()` turns a cold observable into a hot one that shares a single subscription to its source: the subscribers wait, `Connect()` starts the source once, and both get every chord.

Which one you have decides whether subscribing twice runs twice the work, or whether a slow subscriber misses events. Exercise 1 shares a source with `RefCount` instead of `Connect`.

## Operators in virtual time

Rx operators that involve time take an [`IScheduler`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Concurrency/IScheduler.cs), and the `TestScheduler` of `Microsoft.Reactive.Testing` is a scheduler whose clock only moves when the test says so. The program feeds it notes played on a keyboard: C, E and G within 25 ms, D, F and A half a second later, then B alone. Notes that follow each other within 50 ms form a chord:

```csharp
static void VirtualTime()
{
    Title("Virtual time: notes played within 50 ms of each other form a chord");
    var scheduler = new TestScheduler();
    var notes = scheduler.CreateHotObservable(
        ReactiveTest.OnNext(Ms(0), "C"), ReactiveTest.OnNext(Ms(12), "E"), ReactiveTest.OnNext(Ms(25), "G"),
        ReactiveTest.OnNext(Ms(510), "D"), ReactiveTest.OnNext(Ms(540), "F"), ReactiveTest.OnNext(Ms(570), "A"),
        ReactiveTest.OnNext(Ms(1010), "B"),
        ReactiveTest.OnCompleted<string>(Ms(1200)));

    var chords = notes
        .Buffer(notes.Throttle(TimeSpan.FromMilliseconds(50), scheduler))
        .Where(chord => chord.Count > 0);
    var observer = scheduler.CreateObserver<IList<string>>();
    chords.Subscribe(observer);
    scheduler.Start();
    foreach (var message in observer.Messages)
    {
        var value = message.Value;
        Line($"t = {TimeSpan.FromTicks(message.Time).TotalMilliseconds,4} ms  {value.Kind}{(value.Kind == NotificationKind.OnNext ? " " + string.Join(" ", value.Value) : "")}");
    }

    Title("The same notes: Sample(100 ms) and Buffer(100 ms)");
    foreach (var (name, pipeline) in new (string, Func<IObservable<string>, IScheduler, IObservable<string>>)[]
    {
        ("Sample(100 ms)", (source, s) => source.Sample(TimeSpan.FromMilliseconds(100), s)),
        ("Buffer(100 ms)", (source, s) => source.Buffer(TimeSpan.FromMilliseconds(100), s).Select(buffer => $"[{string.Join(" ", buffer)}]")),
    })
    {
        var testScheduler = new TestScheduler();
        var source = testScheduler.CreateHotObservable(
            ReactiveTest.OnNext(Ms(0), "C"), ReactiveTest.OnNext(Ms(12), "E"), ReactiveTest.OnNext(Ms(25), "G"),
            ReactiveTest.OnNext(Ms(510), "D"), ReactiveTest.OnNext(Ms(540), "F"), ReactiveTest.OnNext(Ms(570), "A"),
            ReactiveTest.OnNext(Ms(1010), "B"),
            ReactiveTest.OnCompleted<string>(Ms(1200)));
        var results = testScheduler.CreateObserver<string>();
        pipeline(source, testScheduler).Subscribe(results);
        testScheduler.Start();
        var shown = results.Messages
            .Where(m => m.Value.Kind == NotificationKind.OnNext && m.Value.Value != "[]")
            .Select(m => $"{TimeSpan.FromTicks(m.Time).TotalMilliseconds}:{m.Value.Value}");
        Line($"{name}: {string.Join("  ", shown)}");
    }
}
```

```text
== Virtual time: notes played within 50 ms of each other form a chord
t =   75 ms  OnNext C E G
t =  620 ms  OnNext D F A
t = 1060 ms  OnNext B
t = 1200 ms  OnCompleted
```

The pipeline reads: buffer the notes, and close the buffer each time the stream has been quiet for 50 ms. [`Throttle`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Time.cs#L1455-L1476) emits a note only when no other note follows it within 50 ms, so it fires at 75 ms (25 + 50), 620 ms (570 + 50) and 1,060 ms. `Buffer` closes a group each time. The whole test runs 1.2 seconds of events in a few microseconds, and gives the same answer on every machine.

A warning for anyone who knows RxJS or Reactor: Rx.NET's `Throttle` is what those libraries call *debounce*. It waits for silence. The operator that lets one value through per period is `Sample`, and `Buffer` with a `TimeSpan` cuts fixed windows regardless of the notes:

```text
== The same notes: Sample(100 ms) and Buffer(100 ms)
Sample(100 ms): 100:G  600:A  1100:B
Buffer(100 ms): 100:[C E G]  600:[D F A]  1100:[B]
```

`Sample` kept only the last note of each 100-ms window that saw one, and the fixed windows happen to match the chords only because the notes were played well apart.

## Schedulers: where the observer runs

Rx doesn't start threads by itself. An observer runs on whatever thread calls `OnNext`, unless an operator moves it:

```text
== Schedulers: Rx runs the observer on the thread that calls OnNext, unless told otherwise
Subject.OnNext: observer ran on the caller's thread True, before OnNext returned True
ObserveOn(rx-loop): observer on rx-loop
SubscribeOn(rx-loop): the source ran on rx-loop
Observable.Timer(1 ms): observer on a pool thread True
```

- **No scheduler**: `Subject.OnNext` calls the observer directly, on the caller's thread, and returns only when the observer has returned.
- [`ObserveOn`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Concurrency.cs#L14-L26) moves the notifications that pass through it to a scheduler, here an `EventLoopScheduler`, which owns one thread named `rx-loop`. It's Reactor's `publishOn`.
- [`SubscribeOn`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Concurrency.cs#L85) moves the *subscription*, so a synchronous source like this `Observable.Create` runs on `rx-loop`. It's Reactor's `subscribeOn`.
- Time-based operators such as `Observable.Timer` schedule on the thread pool by default, so the code after them no longer runs on the caller's thread: the same surprise as Reactor's `delayElements`, described in the [Reactor course](../../spring-cloud-reactor/03-reactor-under-the-hood/).

The program also `await`s observables: Rx makes `IObservable<T>` [awaitable](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Awaiter.cs#L12-L20), and `await` returns the last value once the sequence completes, throws its error, or throws if the sequence was empty.

## No backpressure

A Reactor subscriber tells its publisher how many items it can take. An Rx observer has no way to say anything: `OnNext` returns `void`. Two cases follow from that. Without a scheduler, the producer calls the observer directly:

```text
== No backpressure: without a scheduler, OnNext waits for the observer
1,000 OnNext: the observer ran inside each call True, processed 1000
```

The observer ran inside each `OnNext` call, so a slow observer does slow the producer down, by holding its thread. That is backpressure only by accident, and it stops as soon as an operator puts a queue between them. `ObserveOn` is such an operator:

```csharp
static async Task NoBackpressure()
{
    Title("No backpressure: without a scheduler, OnNext waits for the observer");
    var subject = new Subject<int>();
    var processed = 0;
    var insideEachCall = true;
    var pushed = 0;
    subject.Subscribe(_ =>
    {
        insideEachCall &= processed == pushed;
        processed++;
    });
    for (; pushed < 1000; pushed++)
    {
        subject.OnNext(pushed);
    }

    Line($"1,000 OnNext: the observer ran inside each call {insideEachCall}, processed {processed}");

    Title("No backpressure: behind ObserveOn, OnNext returns at once and the queue grows");
    using var loop = new EventLoopScheduler(start => new Thread(start) { Name = "rx-slow", IsBackground = true });
    var gate = new ManualResetEventSlim();
    var done = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
    var slowProcessed = 0;
    var queued = new Subject<byte[]>();
    using var subscription = queued.ObserveOn(loop).Subscribe(_ =>
    {
        gate.Wait();
        slowProcessed++;
    }, () => done.SetResult());

    var before = GC.GetTotalMemory(forceFullCollection: true);
    for (var i = 0; i < 10_000; i++)
    {
        queued.OnNext(new byte[1024]);
    }

    queued.OnCompleted();
    var after = GC.GetTotalMemory(forceFullCollection: true);
    Line($"10,000 OnNext of 1 KB returned while the observer held the first: processed {slowProcessed}, more than 10 MB still reachable {after - before > 10_000_000}");
    Machine($"memory reachable after pushing: {(after - before) / 1_000_000.0:F1} MB more");
    gate.Set();
    await done.Task;
    Line($"after releasing the observer: processed {slowProcessed}");
}
```

```text
== No backpressure: behind ObserveOn, OnNext returns at once and the queue grows
10,000 OnNext of 1 KB returned while the observer held the first: processed 0, more than 10 MB still reachable True
after releasing the observer: processed 10000
```

The producer pushed 10,000 arrays of 1 KB while the observer was stuck on the first one. Every `OnNext` returned immediately, and more than 10 MB piled up in the queue that `ObserveOn` keeps for the event loop: 10.7 MB on the author's machine, in the program's `# ` line. Nothing limits that queue. Rx's answer is to reduce the stream before it reaches a slow observer, with `Sample`, `Throttle`, `Buffer` or `Window`, or to leave Rx for a bounded channel, which lesson 9 does.

## Asynchronous steps and their order

To call an asynchronous method for each item, Rx offers two shapes, and they behave very differently. The program runs two batches, where batch 0 waits up to 200 ms for batch 1 to start:

```csharp
static async Task AsyncSteps()
{
    Title("An asynchronous step: SelectMany runs batches concurrently, Concat one at a time");
    foreach (var name in new[] { "SelectMany", "Select + Concat" })
    {
        var secondStarted = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var overlapped = false;

        async Task<string> Process(int batch)
        {
            if (batch == 0)
            {
                // Batch 0 waits up to 200 ms for batch 1 to start
                overlapped = await Task.WhenAny(secondStarted.Task, Task.Delay(200)) == secondStarted.Task;
            }
            else
            {
                secondStarted.TrySetResult();
            }

            return $"batch {batch}";
        }

        var batches = Observable.Range(0, 2);
        var pipeline = name == "SelectMany"
            ? batches.SelectMany(Process)
            : batches.Select(batch => Observable.FromAsync(() => Process(batch))).Concat();
        var results = await pipeline.ToList();
        Line($"{name,-16} batch 1 started while batch 0 ran: {overlapped,-5}  results: {string.Join(", ", results)}");
    }
}
```

```text
== An asynchronous step: SelectMany runs batches concurrently, Concat one at a time
SelectMany       batch 1 started while batch 0 ran: True   results: batch 1, batch 0
Select + Concat  batch 1 started while batch 0 ran: False  results: batch 0, batch 1
```

- `SelectMany` with a function that returns a `Task` subscribes to every task as soon as its item arrives: batch 1 started while batch 0 was running, finished first, and came out first. It's Reactor's `flatMap`, in completion order.
- `Select` into `Observable.FromAsync`, then `Concat`, starts each task only when the previous one has finished: batch 0 waited its 200 ms alone, and the results kept their order. It's Reactor's `concatMap`.
- `Merge(n)`, in exercise 3, sits in between: at most `n` tasks at a time, in completion order.

## Case study: GA's reactive demo

The Rx part of GA's [`PerformanceOptimizationDemo`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Performance/PerformanceOptimizationDemo/Program.cs#L171-L222) pushes 1,000 musical events into a `Subject`, groups them every 100 ms, processes each batch asynchronously and counts what comes out:

```csharp
var subscription = subject
    .Buffer(TimeSpan.FromMilliseconds(100)) // Batch events every 100ms
    .Where(batch => batch.Count > 0)
    .SelectMany(batch => ProcessBatchAsync(batch))
    .Subscribe(
        _ =>
        {
            Interlocked.Increment(ref processedCount);
            if (processedCount % 100 == 0)
            {
                logger.LogInformation("Processed {Count} musical events", processedCount);
            }
        },
        error => logger.LogError(error, "Error in reactive pipeline"),
        () => logger.LogInformation("Reactive pipeline completed"));
```

`ProcessBatchAsync` returns a `Task<IEnumerable<ProcessedEvent>>`: one task per batch, whose result is the whole batch. `SelectMany` flattens the task, not the collection inside it, so each `OnNext` receives a batch, and `processedCount` counts batches while the log calls them events. The program runs the same pipeline with batches of 100 events instead of 100 ms, so that the count doesn't depend on timing:

```text
== GA's reactive demo: 1,000 events, batches of 100, counted after SelectMany
element type after SelectMany: IEnumerable<ProcessedEvent>; processedCount 10
with a second SelectMany that flattens each batch: processedCount 1000
```

1,000 events make 10 batches, and the demo would report 10. With 100-ms windows over events spaced by `Task.Delay(1)`, the count depends on the machine's timer resolution, and the "every 100 events" log line may never appear. The fix is one more `SelectMany` that flattens each batch.

The demo also ends with `await Task.Delay(500); // Allow final batches to process`, then disposes the subscription. Half a second is a guess. If a batch is still running when the subscription is disposed, its results are simply dropped:

```text
== Disposing the subscription drops the batch still in flight
after Dispose, then the last batch finishing: received 2, OnCompleted False
```

Awaiting the pipeline itself, as the program does with `await pipeline.Do(count).DefaultIfEmpty()`, waits exactly as long as needed, and rethrows the pipeline's error instead of logging it from inside `Subscribe`. `DefaultIfEmpty` is there because awaiting an observable that completes without any value throws.

## Errors and retries

`OnError` ends a sequence for good, and a `Subject` remembers it:

```text
== Errors: OnError ends the sequence
observer saw: Dm7, OnError(the MIDI device was unplugged); a later subscriber sees: OnError(the MIDI device was unplugged)
```

After `OnError`, the subject ignored `G7` and `OnCompleted`, and a subscriber that came later received the error at once. A hot source that fails is finished; to recover, you need a cold source that you can subscribe to again:

```text
== Retry subscribes again; Catch switches to another sequence
Retry(3): D dorian after 3 subscriptions
Retry(2) on a source that keeps failing: InvalidOperationException: scale service unavailable, 2 subscriptions
Catch: C ionian (cached)
```

[`Retry(n)`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Linq/Observable.Single.cs#L636-L645) counts subscriptions, not retries: `Retry(3)` succeeded on the third subscription, and `Retry(2)` gave up after two, rethrowing the last error. Its summary says it "repeats the source observable sequence the specified number of times", and the count includes the first subscription. Reactor's `retry(n)` counts *re*-subscriptions: the [Reactor course's `retry(2)`](../../spring-cloud-reactor/03-reactor-under-the-hood/#errors-and-retries) calls the same flaky scale service three times before `D dorian`. `Catch` switches to a fallback sequence, like Reactor's `onErrorResume`. Rx has no ready-made backoff like Reactor's `Retry.backoff`: `RetryWhen` lets you build one, or Polly wraps the call.

## If you know Spring and Reactor

| Rx.NET | Reactor |
|---|---|
| `IObservable<T>`, `IObserver<T>` | `Publisher<T>` (`Flux`, `Mono`), `Subscriber<T>` |
| `Observable.Create`, `Defer` | `Flux.create`, `Flux.defer` |
| `Subject<T>` | `Sinks.many().multicast()` |
| `ReplaySubject<T>(n)` | `Sinks.many().replay().limit(n)`, or `replay(n)` on a `Flux` |
| `Publish()` + `Connect()`, `Publish().RefCount(n)` | `publish()` + `connect()`, `publish().refCount(n)`; `share()` |
| `Select`, `Where`, `SelectMany` | `map`, `filter`, `flatMap` |
| `Select(x => Observable.FromAsync(...)).Concat()` | `concatMap` |
| `Merge(n)` | `flatMap(f, n)` |
| `Throttle(t)` (waits for silence) | `sampleTimeout(x -> Mono.delay(t))` |
| `Sample(t)` | `sample(Duration)` |
| `Buffer(TimeSpan)`, `Buffer(count)` | `buffer(Duration)`, `buffer(n)`, `bufferTimeout(n, Duration)` |
| `ObserveOn(scheduler)` | `publishOn(scheduler)` |
| `SubscribeOn(scheduler)` | `subscribeOn(scheduler)` |
| `EventLoopScheduler` | `Schedulers.single()` |
| `TestScheduler` | `VirtualTimeScheduler`, `StepVerifier.withVirtualTime` |
| no backpressure: `OnNext` returns `void` | `request(n)`, `onBackpressureBuffer`, `limitRate` |
| `Retry(n)`: n subscriptions | `retry(n)`: n re-subscriptions after the first |
| `Catch` | `onErrorResume` |
| `await observable` | `block()`, or `blockLast()` |

The names come from the [`Flux`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) and [`Sinks`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Sinks.html) Javadoc. The Reactor course's [lesson 2](../../spring-cloud-reactor/02-reactor-mono-and-flux/) and [lesson 3](../../spring-cloud-reactor/03-reactor-under-the-hood/) show them running.

## Exercises

1. Share one cold source between two subscribers, so that it runs once and starts only when both have subscribed, without calling `Connect` yourself.
2. Play the chord detector a note every 40 ms, from 0 to 280 ms, and complete the sequence at 1 s. What does it emit, and when? What does that say about `Throttle` for a stream that never pauses?
3. Process eight items with an asynchronous function, never more than two at a time. Which operator, and in which order do the results come?

<details>
<summary>Solutions</summary>

1. `Publish().RefCount(2)` connects when the second subscriber arrives, and disconnects when the subscriber count drops back to zero:

    ```text
    1. Publish().RefCount(2): source ran 1 time; first Dm7 G7 Cmaj7 A7, second Dm7 G7 Cmaj7 A7
    ```

2. One chord of eight notes, at 330 ms: 50 ms after the last note. `Throttle` restarts its timer on every note, so as long as notes keep coming less than 50 ms apart, it emits nothing at all. Rx's own remarks on `Throttle` say it: "for streams that never have gaps larger than or equal to dueTime between elements, the resulting stream won't produce any elements". A detector for a continuous stream also needs a limit on the group's size or duration, for example a buffer closed by the `Throttle` or by a timer, whichever comes first (*to verify*: the lesson's program doesn't run that variant).

    ```text
    2. a note every 40 ms from 0 to 280 ms: 330:[C D E F G A B C]
    ```

3. `Select` each item into `Observable.FromAsync(...)`, then `Merge(2)`. The results come in completion order; the program checks the concurrency instead of the order:

    ```text
    3. Select + Merge(2): 8 results, at most 2 running at once, all of 0..7 True
    ```

</details>

## Key takeaways

- `IObservable<T>` pushes; the observer can't slow the source down. Rx is for events that happen, not for work you pull.
- Cold observables run their source for each subscriber; subjects and `Publish` are hot and share one.
- Test time-based pipelines with `TestScheduler`: they run in microseconds and give the same answer everywhere.
- `Throttle` in Rx.NET waits for silence, like *debounce* elsewhere; `Sample` takes the latest value per period.
- Rx runs the observer on the thread that calls `OnNext`; `ObserveOn` and `SubscribeOn` move notifications and subscriptions, like `publishOn` and `subscribeOn`.
- Behind `ObserveOn` the queue is unbounded: reduce the stream first, or hand it to a bounded channel.
- `SelectMany` with tasks is concurrent and unordered, and flattens the task, not a collection inside it; `Concat` keeps order, `Merge(n)` limits concurrency.
- Await the pipeline instead of guessing how long it takes, and remember that `OnError` is final.

## Sources

- [dotnet/reactive](https://github.com/dotnet/reactive) and its [Rx.NET 7.0.0 release](https://github.com/dotnet/reactive/releases/tag/rxnet-v7.0.0); Ian Griffiths and Lee Campbell, [Introduction to Rx.NET, 2nd edition](https://introtorx.com/), free online.
- Microsoft Learn: [`IObservable<T>`](https://learn.microsoft.com/dotnet/api/system.iobservable-1), [`IObserver<T>`](https://learn.microsoft.com/dotnet/api/system.iobserver-1), [the observer design pattern](https://learn.microsoft.com/dotnet/standard/events/observer-design-pattern).
- Rx.NET at `rxnet-v7.0.0`: [`Subject.cs`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Subjects/Subject.cs), [`IScheduler.cs`](https://github.com/dotnet/reactive/blob/rxnet-v7.0.0/Rx.NET/Source/src/System.Reactive/Concurrency/IScheduler.cs).
- Reactor: [`Flux`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) and [`Sinks`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Sinks.html) Javadoc.
- Guitar Alchemist at `a826864`: [`PerformanceOptimizationDemo/Program.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Performance/PerformanceOptimizationDemo/Program.cs#L171-L222).
