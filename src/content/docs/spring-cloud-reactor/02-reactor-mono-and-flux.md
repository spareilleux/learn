---
title: "2. Reactor: Mono and Flux"
description: Mono and Flux compared with Task, IAsyncEnumerable and Rx.NET — assembly versus subscription, the operators that LINQ already taught you, signals and demand, and StepVerifier with virtual time.
sidebar:
  order: 2
---

Full example: [`code/spring-cloud-reactor/l02-reactor`](https://github.com/spareilleux/learn/tree/main/code/spring-cloud-reactor/l02-reactor), plain Java with [`reactor-core`](https://projectreactor.io/docs/core/release/reference/) and [`reactor-test`](https://projectreactor.io/docs/core/release/reference/testing.html), no Spring. `ExamplesTest` runs each example and compares its output with [`expected`](https://github.com/spareilleux/learn/tree/main/code/spring-cloud-reactor/l02-reactor/expected); the .NET side is [`csharp/l02-task-vs-flux.cs`](https://github.com/spareilleux/learn/blob/main/code/spring-cloud-reactor/csharp/l02-task-vs-flux.cs).

## Two types, four interfaces

WebFlux, Spring Cloud Gateway, R2DBC and the reactive clients of the later lessons all speak [Project Reactor](https://projectreactor.io/docs/core/release/reference/). Its two types are the whole vocabulary:

- **`Mono<T>`** emits at most one value, then completes, or fails. It is where C# would return a `Task<T>`.
- **`Flux<T>`** emits any number of values, then completes, or fails. It is where C# would return an `IAsyncEnumerable<T>` or an `IObservable<T>`.

Both implement `Publisher<T>`, one of the four interfaces of the [Reactive Streams specification](https://github.com/reactive-streams/reactive-streams-jvm/blob/a625d3aba756e9842ad1291a5b73f5db280b6168/README.md): a `Publisher` accepts a `Subscriber`, gives it a `Subscription`, and sends it values only as fast as the subscriber requests them through that subscription. The JDK carries the same four interfaces as [`java.util.concurrent.Flow`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Flow.html). .NET has no standard equivalent; the closest relative is [Rx.NET](https://github.com/dotnet/reactive), whose `IObservable<T>` pushes without any request mechanism.

| C# | Reactor | Notes |
|---|---|---|
| `Task<T>` | `Mono<T>` | a `Mono` doesn't start until subscribed; a `Task` has usually started already |
| `Task` | `Mono<Void>` | completes without a value |
| `IAsyncEnumerable<T>` | `Flux<T>` | both are lazy; the subscriber pulls in both, in batches with Reactor |
| `IObservable<T>` (Rx.NET) | `Flux<T>` | Rx pushes; Reactor pushes only what was requested |
| `await` | a following operator, or `block()` at the edge | there is no `await` in Java: the pipeline is the continuation |
| LINQ operators | `map`, `filter`, `flatMap`, … | more than 400 public methods on `Flux`, overloads included, with marble diagrams in the [Javadoc](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) |
| `null` | `Mono.empty()` | Reactor forbids `null` values |
| `FakeTimeProvider`, Rx's `TestScheduler` | `StepVerifier.withVirtualTime` | tests that span minutes run in milliseconds |

[Lesson 9 of the Java course](../../java-for-csharp/09-concurrency-and-virtual-threads/) mapped `Task` onto `CompletableFuture`. The difference with `Mono` comes first.

## Assembly and subscription

Building a pipeline and running it are two separate moments. Reactor's documentation calls the first **assembly** and the second **subscription**:

```java
static Scale lookUp(String root, String mode) {
    System.out.println("  looking up " + root + " " + mode);
    return Scale.of(root, mode);
}

public static void main(String[] args) {
    // Assembly: this line builds a description of the work. Nothing runs yet.
    Mono<Scale> dorian = Mono.fromCallable(() -> lookUp("D", "dorian"));
    System.out.println("assembled a Mono");

    // Subscription starts the work, once per subscriber: a Mono is cold.
    System.out.println("first subscriber:");
    dorian.subscribe(scale -> System.out.println("  got " + scale.notes()));
    System.out.println("second subscriber:");
    dorian.subscribe(scale -> System.out.println("  got " + scale.notes()));

    // A CompletableFuture is hot, like a Task: it starts when created and runs once.
    System.out.println("CompletableFuture:");
    CompletableFuture<Scale> future = CompletableFuture.supplyAsync(() -> lookUp("E", "phrygian"));
    future.join();
    System.out.println("  joined twice, same result: " + (future.join() == future.join()));

    // Mono.just takes a value, so its argument is computed during assembly, subscriber or not.
    System.out.println("Mono.just:");
    Mono<Scale> eager = Mono.just(lookUp("F", "lydian"));
    System.out.println("  assembled, no subscriber yet");

    // Mono.defer postpones building the Mono itself until someone subscribes.
    System.out.println("Mono.defer:");
    Mono<Scale> deferred = Mono.defer(() -> Mono.just(lookUp("G", "mixolydian")));
    System.out.println("  assembled, no subscriber yet");
    deferred.subscribe();
    eager.subscribe();
}
```

```text
assembled a Mono
first subscriber:
  looking up D dorian
  got [D, E, F, G, A, B, C]
second subscriber:
  looking up D dorian
  got [D, E, F, G, A, B, C]
CompletableFuture:
  looking up E phrygian
  joined twice, same result: true
Mono.just:
  looking up F lydian
  assembled, no subscriber yet
Mono.defer:
  assembled, no subscriber yet
  looking up G mixolydian
```

Three rules come out of this output:

- **Nothing happens without a subscriber.** A method that returns a `Mono` has only described the work. Forgetting to subscribe is the reactive version of calling an `async` method without awaiting it, except that the work doesn't even start. In WebFlux, the framework subscribes to what a controller returns, so application code rarely calls `subscribe` itself.
- **Each subscriber runs the pipeline again.** The lookup ran twice for two subscribers. A `Mono` is a recipe, not a result; a `Task` or a `CompletableFuture` is a result, computed once. When several subscribers must share one execution, `cache()` or `share()` make a pipeline hot.
- **`Mono.just` is eager.** Its argument is an ordinary Java expression, evaluated before `just` is even called: `F lydian` was looked up with no subscriber at all. `Mono.fromCallable`, `Mono.fromSupplier` and `Mono.defer` delay the work until subscription. The only side effect of `eager.subscribe()`, the last line, is to deliver a value computed long before.

The C# side prints the same three situations for `Task`, `IAsyncEnumerable` and Rx.NET:

```text
Task:
  looking up E phrygian
  awaited twice, same result: True
IAsyncEnumerable:
  created, not enumerated
  looking up D dorian
  got D dorian
  looking up D dorian
  got D dorian
  LINQ: Cm Dm Am
Observable.Return:
  looking up F lydian
  created, no subscriber yet
Observable.Defer:
  created, no subscriber yet
  looking up G mixolydian
```

An `IAsyncEnumerable` behaves like a `Flux`: the iterator runs again for each `await foreach`. `Observable.Return` and `Observable.Defer` have exactly the trap and the fix of `Mono.just` and `Mono.defer`, because Rx.NET and Reactor come from the same design. The `LINQ` line uses the operators that .NET 10 ships for `IAsyncEnumerable` in the framework itself ([`System.Linq.AsyncEnumerable`](https://learn.microsoft.com/dotnet/api/system.linq.asyncenumerable)).

## Operators

Most operators are LINQ under another name, which makes a pipeline easy to read and easy to misread:

```java
Flux<Mode> modes = Flux.fromArray(Mode.values());

// map and filter are Select and Where.
List<String> minorModes = modes
        .filter(mode -> Scale.of("C", mode.label()).triads().getFirst().quality() == Chord.Quality.MINOR)
        .map(Mode::label)
        .collectList()
        .block();
System.out.println("modes with a minor tonic chord: " + minorModes);

// flatMapIterable is SelectMany over a collection; distinct and count are what LINQ calls them.
Mono<Long> distinctChords = modes
        .flatMapIterable(mode -> Scale.of("C", mode.label()).triads())
        .map(Chord::symbol)
        .distinct()
        .count();
System.out.println("distinct triads in the seven modes on C: " + distinctChords.block());

// zip pairs two sequences element by element, like Enumerable.Zip.
Flux<String> degrees = Flux.just("I", "ii", "iii", "IV", "V", "vi", "vii°");
Flux<Chord> chords = Flux.fromIterable(Scale.of("G", "major").triads());
System.out.println(Flux.zip(degrees, chords, (degree, chord) -> degree + "=" + chord)
        .take(4)
        .collectList()
        .block());

// reduce is Aggregate; a Flux of Monos is merged with flatMap, like await Task.WhenAll.
Mono<String> progression = Flux.just("C", "A", "D", "G")
        .flatMap(root -> Mono.fromCallable(() -> Scale.of(root, "major").triads().getFirst().symbol()))
        .reduce((left, right) -> left + " " + right);
System.out.println("progression: " + progression.block());
```

```text
modes with a minor tonic chord: [dorian, phrygian, aeolian]
distinct triads in the seven modes on C: 25
[I=G, ii=Am, iii=Bm, IV=C]
progression: C A D G
```

| LINQ | Reactor |
|---|---|
| `Select` | `map` |
| `Where` | `filter` |
| `SelectMany` over collections | `flatMapIterable` |
| `SelectMany` over asynchronous results | `flatMap` (concurrent), `concatMap` (one at a time), `flatMapSequential` |
| `Aggregate` | `reduce` |
| `ToListAsync`, `ToDictionaryAsync` | `collectList`, `collectMap` |
| `Zip` | `zip`, `zipWith` |
| `Take`, `Skip` | `take`, `skip` |
| `Distinct`, `Count` | `distinct`, `count` |
| `Concat` | `concatWith`, `Flux.concat` |
| `DefaultIfEmpty` | `defaultIfEmpty`, `switchIfEmpty` |
| `Task.WhenAll` | `Mono.zip`, `Flux.merge`, `flatMap` |

`collectList` and `count` turn a `Flux` into a `Mono`, like the LINQ methods that end with `Async` and return a `Task`. `block()` then waits for that `Mono`, like `.GetAwaiter().GetResult()`. It is fine in `main` and in tests; lesson 3 shows where Reactor refuses it.

### `flatMap` doesn't keep the order

`flatMap` subscribes to the inner publishers concurrently and forwards their values as they arrive. The synchronous `Mono.fromCallable` above completed immediately, so the order looked preserved. With inner publishers that take time, it isn't. This test uses a tonic chord service whose answer takes 300 ms for C and 100 ms for the others:

```java
// A chord service that answers slowly for some roots; the durations are virtual.
static Mono<String> slowTonic(String root, long millis) {
    return Mono.delay(Duration.ofMillis(millis)).map(tick -> Scale.of(root, "major").triads().getFirst().symbol());
}

@Test
void flatMapEmitsInCompletionOrder() {
    // Without virtual time, this test would wait 300 ms of real time.
    StepVerifier.withVirtualTime(() -> Flux.just("C", "F", "G")
                    .flatMap(root -> slowTonic(root, root.equals("C") ? 300 : 100)))
            .thenAwait(Duration.ofMillis(300))
            .expectNext("F", "G", "C")
            .verifyComplete();
}

@Test
void concatMapKeepsTheSourceOrder() {
    StepVerifier.withVirtualTime(() -> Flux.just("C", "F", "G")
                    .concatMap(root -> slowTonic(root, root.equals("C") ? 300 : 100)))
            .expectSubscription()
            .expectNoEvent(Duration.ofMillis(300))
            .expectNext("C")
            .thenAwait(Duration.ofMillis(200))
            .expectNext("F", "G")
            .verifyComplete();
}
```

`flatMap` emitted F, G, then C, in completion order: it is `Task.WhenAny` in a loop, not `Task.WhenAll`, whose results keep the order of the tasks. `concatMap` waits for each inner publisher before subscribing to the next, so it keeps the order and takes 500 ms. `flatMapSequential` is the third choice: concurrent subscriptions, results reordered to match the source.

## Signals

A `Subscriber` receives four kinds of signal: `onSubscribe` once, `onNext` for each value, then `onComplete` or `onError`, never both. `log()` prints every signal that crosses its position in the pipeline:

```java
// log() prints every signal that crosses this point of the pipeline.
Flux.just("C", "E", "G")
        .map(String::toLowerCase)
        .log("triad")
        .take(2)
        .subscribe(note -> System.out.println("subscriber got " + note));
```

```text
[ INFO] (main) | onSubscribe([Fuseable] FluxMapFuseable.MapFuseableSubscriber)
[ INFO] (main) | request(2)
[ INFO] (main) | onNext(c)
subscriber got c
[ INFO] (main) | onNext(e)
subscriber got e
[ INFO] (main) | cancel()
```

Without SLF4J on the class path, Reactor logs to the console, and the category name `triad` doesn't appear. The output shows what `IAsyncEnumerable` never makes visible:

- **Demand travels up.** The subscriber asked for everything, but `take(2)` passed only `request(2)` upstream. Every operator can change the demand; lesson 3 is about what happens when a source produces faster than that.
- **Cancellation travels up too.** Once `take` has its two values, it sends `cancel()` to the source, the equivalent of leaving an `await foreach` loop, which disposes the enumerator. No `CancellationToken` is passed anywhere.
- **Everything ran on `main`.** Reactor doesn't switch threads unless an operator or a scheduler does, which lesson 3 also covers.

Errors and empty results are signals as well:

```java
// Errors are signals too: the sequence stops at the first one.
Flux.just("C", "H", "D")
        .map(root -> Scale.of(root, "major").root())
        .subscribe(
                root -> System.out.println("onNext " + root),
                error -> System.out.println("onError " + error.getMessage()),
                () -> System.out.println("onComplete"));

// null is not a value in Reactor: a mapper that returns null fails the sequence.
Mono.just("C")
        .map(root -> (String) null)
        .subscribe(
                value -> System.out.println("onNext " + value),
                // The message names the lambda's generated class, whose address changes from run to run.
                error -> System.out.println("onError " + error.getClass().getSimpleName() + ": "
                        + error.getMessage().replaceAll("/0x[0-9a-f]+", "/0x...")));

// Empty is how Reactor says "no value": defaultIfEmpty and switchIfEmpty handle it.
Mono<String> favourite = Mono.justOrEmpty(System.getenv("NO_SUCH_VARIABLE_FOR_THE_LESSON"));
System.out.println("empty Mono blocks to: " + favourite.block());
System.out.println("defaultIfEmpty: " + favourite.defaultIfEmpty("ionian").block());
```

```text
onNext C
onError unknown note: H
onError NullPointerException: The mapper [dev.learn.reactor.l02.Operators$$Lambda/0x...] returned a null value.
empty Mono blocks to: null
defaultIfEmpty: ionian
```

- **An error ends the sequence.** `D` was never processed and `onComplete` never printed. The exception thrown inside `map` became an `onError` signal instead of propagating up the call stack; lesson 3 shows how to recover from it.
- **`null` is refused.** The [Reactive Streams specification](https://github.com/reactive-streams/reactive-streams-jvm/blob/a625d3aba756e9842ad1291a5b73f5db280b6168/README.md#2.13) forbids `null` elements, so a mapper that returns `null` fails. `Mono.justOrEmpty` turns a possibly null value into an empty `Mono`, the way `?.` and `??` handle `null` in C#.
- **`block()` on an empty `Mono` returns `null`.** It is the one place where Reactor gives `null` back, at the edge between reactive and ordinary code.
- **A `subscribe` without an error handler** doesn't throw either. In a one-off probe with the same `map` and only a value consumer, Reactor logged `[ERROR] (main) Operator called default onErrorDropped - reactor.core.Exceptions$ErrorCallbackNotImplemented: java.lang.IllegalStateException: boom` with its stack trace, and `main` carried on. Always pass an error consumer, or let a framework subscribe for you.

## Testing with `StepVerifier`

`block()` in a test works for a single value but says nothing about the order, the number of values or the way a sequence ends. [`StepVerifier`](https://projectreactor.io/docs/core/release/reference/testing.html), in `reactor-test`, subscribes and checks each signal in turn:

```java
static Flux<String> triads(String root, String mode) {
    return Flux.defer(() -> Flux.fromIterable(Scale.of(root, mode).triads())).map(Chord::symbol);
}

@Test
void expectEachSignalInOrder() {
    StepVerifier.create(triads("A", "minor"))
            .expectNext("Am", "Bdim", "C")
            .expectNextCount(3)
            .expectNext("G")
            .verifyComplete();
}

@Test
void errorsAreSignalsToExpect() {
    StepVerifier.create(triads("H", "minor"))
            .expectErrorMessage("unknown note: H")
            .verify();
}
```

Nothing is checked until `verify()`, `verifyComplete()` or another `verify…` method runs: without it, the test builds a scenario and passes without subscribing. When an expectation fails, the message names the step:

```java
StepVerifier.create(triads("D", "dorian"))
        .expectNext("Dm", "Em", "F#")
        .verifyComplete();
```

```text
expectation "expectNext(F#)" failed (expected value: F#; actual value: F)
```

**Virtual time** replaces Reactor's clock for the duration of a test. `withVirtualTime` takes a supplier, not a `Flux`, so that operators like `Mono.delay` are created after the virtual clock is installed; `thenAwait` advances it, and `expectNoEvent` checks that nothing happened during a period. The `flatMap` tests above cover 500 ms of virtual time in a few milliseconds. .NET tests get the same with [`FakeTimeProvider`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.time.testing.faketimeprovider) for code that takes a `TimeProvider`, or Rx.NET's `TestScheduler`.

## Key takeaways

- `Mono` is zero or one value, `Flux` is zero to many; both are Reactive Streams publishers, closer to Rx.NET's `IObservable` than to `Task`.
- Assembly builds a description; subscription runs it, once per subscriber. Nothing happens without a subscriber, and `Mono.just(expensive())` runs `expensive()` anyway: use `fromCallable` or `defer`.
- Operators are LINQ with other names. `flatMap` is concurrent and emits in completion order; `concatMap` and `flatMapSequential` keep the source order.
- Signals are `onSubscribe`, `onNext`, `onComplete` and `onError`. Demand (`request`) and cancellation travel upstream; values, errors and completion travel downstream. `log()` shows all of them.
- Errors end a sequence, `null` is forbidden, and emptiness is a signal of its own.
- Test with `StepVerifier` and always finish with a `verify` method; use virtual time for anything with a delay.

## Exercises

1. This method compiles and returns a `Flux`. Explain why the call `eagerTriads("H", "major")` throws, when a caller of a reactive API expects an `onError` signal instead, then fix it.

```java
static Flux<String> eagerTriads(String root, String mode) {
    return Flux.fromIterable(Scale.of(root, mode).triads()).map(Chord::symbol);
}
```

<details>
<summary>Solution</summary>

```java
static Flux<String> lazyTriads(String root, String mode) {
    return Flux.defer(() -> Flux.fromIterable(Scale.of(root, mode).triads())).map(Chord::symbol);
}

@Test
void exercise1WhereTheErrorHappens() {
    var thrown = assertThrows(IllegalArgumentException.class, () -> eagerTriads("H", "major"));
    assertEquals("unknown note: H", thrown.getMessage());

    Flux<String> assembled = lazyTriads("H", "major");
    StepVerifier.create(assembled).expectErrorMessage("unknown note: H").verify();
}
```

`Scale.of(root, mode)` is an argument of `fromIterable`, so Java evaluates it during assembly, in the caller's stack frame: the same trap as `Mono.just`. `Flux.defer` moves it into the subscription, where the exception becomes an `onError` signal. The C# counterpart is an `async` method that validates its arguments: the exception is stored in the returned `Task`, not thrown by the call, unless the validation sits in a non-`async` wrapper.

</details>

2. Port this C# query to Reactor, returning a `Mono<List<String>>`: of the keys C, G, D, A, E and B, in that order, keep the first three whose major scale contains F#.

```csharp
var keys = await new[] { "C", "G", "D", "A", "E", "B" }.ToAsyncEnumerable()
    .Where(root => MajorScale(root).Contains("F#"))
    .Take(3)
    .ToListAsync();
```

<details>
<summary>Solution</summary>

```java
static Mono<List<String>> keysWithFSharp() {
    Note fSharp = Note.parse("F#");
    return Flux.just("C", "G", "D", "A", "E", "B")
            .filter(root -> Scale.of(root, "major").notes().contains(fSharp))
            .take(3)
            .collectList();
}
```

The test expects `[G, D, A]`. `take(3)` cancels the source after the third match, so E and B are never tested, as LINQ's `Take` stops the enumeration. The `Note` record compares by value, so `contains` works with a freshly parsed note.

</details>

3. Write a metronome: a `Flux<String>` that plays a four-chord progression, one chord every 500 ms, twice, then completes. Test it without waiting four seconds.

<details>
<summary>Solution</summary>

```java
static Flux<String> metronome(List<String> progression) {
    return Flux.interval(Duration.ofMillis(500))
            .map(beat -> progression.get((int) (beat % progression.size())))
            .take(progression.size() * 2L);
}

@Test
void exercise3MetronomeInVirtualTime() {
    Duration took = StepVerifier.withVirtualTime(() -> metronome(List.of("C", "Am", "F", "G")))
            .expectSubscription()
            .expectNoEvent(Duration.ofMillis(500))
            .expectNext("C")
            .thenAwait(Duration.ofMillis(1500))
            .expectNext("Am", "F", "G")
            .thenAwait(Duration.ofSeconds(2))
            .expectNext("C", "Am", "F", "G")
            .verifyComplete();
    assertTrue(took.compareTo(Duration.ofSeconds(1)) < 0, "four virtual seconds took " + took);
}
```

`Flux.interval` emits 0, 1, 2… on a timer and never completes; `take` ends it. `expectSubscription()` comes before `expectNoEvent`, because the subscription itself is an event. `verify` methods return the real time they took, which the test uses to prove that no real waiting happened.

</details>

## Sources

- [Reactor 3 reference guide](https://projectreactor.io/docs/core/release/reference/): [introduction to reactive programming](https://projectreactor.io/docs/core/release/reference/reactiveProgramming.html), [core features](https://projectreactor.io/docs/core/release/reference/coreFeatures.html), [testing](https://projectreactor.io/docs/core/release/reference/testing.html), [which operator do I need?](https://projectreactor.io/docs/core/release/reference/apdx-operatorChoice.html)
- [`Flux`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) and [`Mono`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Mono.html) Javadoc
- [Reactive Streams specification](https://github.com/reactive-streams/reactive-streams-jvm/blob/a625d3aba756e9842ad1291a5b73f5db280b6168/README.md), [`java.util.concurrent.Flow`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Flow.html)
- .NET: [asynchronous streams](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/generate-consume-asynchronous-stream), [`System.Linq.AsyncEnumerable`](https://learn.microsoft.com/dotnet/api/system.linq.asyncenumerable), [Reactive Extensions for .NET](https://github.com/dotnet/reactive), [`FakeTimeProvider`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.time.testing.faketimeprovider)
