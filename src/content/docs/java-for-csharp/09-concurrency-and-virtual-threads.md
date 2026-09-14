---
title: 9. Concurrency and virtual threads
description: Virtual threads instead of async/await, executors, CompletableFuture as Task, cancellation by interruption, locks and atomics, ScopedValue instead of AsyncLocal, and parallel streams.
sidebar:
  order: 9
---

Full examples: [`lessons/l09`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/src/main/java/lessons/l09).

## Two answers to the same problem

A server that waits on a database, an HTTP call or a file spends most of its time blocked. Blocking an operating system thread is expensive: each one reserves a stack and the scheduler can juggle only so many. C# answered in 2012 with `async`/`await`: a method that awaits gives its thread back, and the compiler rewrites it into a state machine. Java answered in 2023 with [virtual threads](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html) ([JEP 444](https://openjdk.org/jeps/444), Java 21): the code keeps blocking, but the thread that blocks is a cheap JVM object, and the JVM unmounts it from its carrier thread while it waits.

So Java has no `async` keyword, no `Task<T>` return type to thread through every signature, and no "async all the way down". A method that reads a socket is an ordinary method.

| C# | Java 25 |
|---|---|
| `Task.Run(...)` | `executor.submit(...)` or `CompletableFuture.supplyAsync(...)` |
| `await` | a blocking call on a virtual thread, or `thenApply`/`thenCompose` |
| `Task<T>` | `Future<T>`, [`CompletableFuture<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/CompletableFuture.html) |
| `await Task.WhenAll(...)` | `executor.invokeAll(...)`, `CompletableFuture.allOf(...)`, or closing the executor |
| `CancellationToken` | thread interruption |
| `lock (obj)`, [`System.Threading.Lock`](https://learn.microsoft.com/dotnet/api/system.threading.lock) | `synchronized (obj)`, [`ReentrantLock`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/locks/ReentrantLock.html) |
| `Interlocked.Increment` | `AtomicInteger`, [`LongAdder`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/atomic/LongAdder.html) |
| `ConcurrentDictionary` | [`ConcurrentHashMap`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/ConcurrentHashMap.html) |
| [`AsyncLocal<T>`](https://learn.microsoft.com/dotnet/api/system.threading.asynclocal-1) | [`ScopedValue<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ScopedValue.html) (Java 25) |
| [PLINQ](https://learn.microsoft.com/dotnet/standard/parallel-programming/introduction-to-plinq) `AsParallel()` | `parallel()` streams |

## Platform threads and virtual threads

`Thread.ofPlatform()` builds what .NET calls a thread: one operating system thread. `Thread.ofVirtual()` builds a virtual thread, which the JVM schedules onto a small pool of carrier threads:

```java
// A platform thread wraps an operating system thread, like new Thread(...) in .NET.
Thread platform = Thread.ofPlatform().name("platform-1").start(() -> System.out.println("hello from a platform thread"));
platform.join();

// A virtual thread is scheduled by the JVM onto a few carrier threads.
Thread virtual = Thread.ofVirtual().name("virtual-1").start(() -> {
    Thread current = Thread.currentThread();
    System.out.println(current.getName() + " isVirtual=" + current.isVirtual() + " daemon=" + current.isDaemon());
});
virtual.join();
```

```text
hello from a platform thread
virtual-1 isVirtual=true daemon=true
```

Virtual threads are always daemon threads: they don't keep the JVM alive, so `main` must wait for them. Without the `join()`, the program could end before the second line prints.

You rarely create threads by hand. The idiom is an executor that starts one virtual thread per task, in a `try`-with-resources block. [`ExecutorService.close()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/ExecutorService.html) (Java 19) waits for every submitted task, which gives you `await Task.WhenAll` without collecting the tasks:

```java
// One virtual thread per task: blocking calls are cheap, so there is no async/await.
long start = System.nanoTime();
var results = new ArrayList<Future<Integer>>();
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (int i = 0; i < 10_000; i++) {
        int id = i;
        results.add(executor.submit(() -> {
            Thread.sleep(Duration.ofSeconds(1));
            return id;
        }));
    }
} // close() waits for every task, like await Task.WhenAll(...)
long sum = 0;
for (Future<Integer> result : results) {
    sum += result.get();
}
Duration elapsed = Duration.ofNanos(System.nanoTime() - start);
System.out.println("10,000 tasks slept 1 s each; sum of ids = " + sum);
System.out.println("finished in under 5 s: " + (elapsed.compareTo(Duration.ofSeconds(5)) < 0));
```

```text
10,000 tasks slept 1 s each; sum of ids = 49995000
finished in under 5 s: true
```

Ten thousand blocking sleeps take about one second in total: the whole program ran in 1.1 s on my machine. With 10,000 platform threads, the same code would reserve 10,000 stacks. The C# side gets the same numbers with `await Task.WhenAll(Enumerable.Range(0, 10_000).Select(SleepThenReturn))`, where `SleepThenReturn` awaits `Task.Delay`. C# rewrites the code; Java keeps it and makes the thread cheap.

Virtual threads help with *waiting*, not with computing. A CPU-bound loop still needs a core, and there are only as many cores as before. Parallel streams, at the end of this lesson, are the tool for that. Don't pool virtual threads either: they are meant to be created per task and thrown away.

Cheap blocking also doesn't make blocking safe everywhere. The event-loop threads of reactive libraries such as [Project Reactor](https://projectreactor.io/docs/core/release/reference/) and Netty must never block, virtual threads or not. [BlockHound](https://github.com/reactor/BlockHound) detects blocking calls on those threads, and [lesson 11](../11-testing/) sets it up in the tests.

`submit` catches an exception thrown by the task and keeps it in the `Future`. `get()` rethrows it wrapped in the checked `ExecutionException`:

```java
// An exception inside a task is kept in its Future and rethrown, wrapped, by get().
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    Future<Integer> failing = executor.submit(() -> Integer.parseInt("forty-two"));
    try {
        failing.get();
    } catch (ExecutionException e) {
        System.out.println("get() threw " + e.getClass().getSimpleName() + " caused by " + e.getCause());
    }
}
```

```text
get() threw ExecutionException caused by java.lang.NumberFormatException: For input string: "forty-two"
```

### Checked exceptions meet threads

Lesson 5's checked exceptions show up again. `Thread.sleep` throws `InterruptedException`, and `submit` accepts either a `Runnable`, which can't throw checked exceptions, or a `Callable`, which can. A block lambda that returns nothing can only be a `Runnable`:

```java
import java.util.concurrent.Executors;

class Sleeper {
    static void run() {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            executor.submit(() -> {
                Thread.sleep(100);
            });
        }
    }
}
```

```text
SleepInRunnable.java:7: error: unreported exception InterruptedException; must be caught or declared to be thrown
                Thread.sleep(100);
                            ^
1 error
```

Returning a value (`return id;` in the example above) makes the lambda a `Callable`, and the error goes away. C# has no such split: `Task.Run` accepts any lambda.

## `CompletableFuture`: Java's `Task`

A `Future` can only be waited on. [`CompletableFuture`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/CompletableFuture.html) (Java 8) adds continuations, so it covers what C# does with `Task`, `ContinueWith` and `await`:

```java
// supplyAsync is Task.Run; thenApply is the code after an await.
CompletableFuture<Integer> score = CompletableFuture
        .supplyAsync(() -> fetchUser(7), executor)
        .thenApply(Futures::fetchScore);
System.out.println("score: " + score.join());

// thenCombine waits for two independent futures, like await Task.WhenAll(a, b).
var name = CompletableFuture.supplyAsync(() -> "Ada", executor);
var year = CompletableFuture.supplyAsync(() -> 1815, executor);
System.out.println(name.thenCombine(year, (n, y) -> n + " was born in " + y).join());

// allOf completes when every future has; the results are read afterwards.
List<CompletableFuture<String>> users = List.of(1, 2, 3).stream()
        .map(id -> CompletableFuture.supplyAsync(() -> fetchUser(id), executor))
        .toList();
CompletableFuture.allOf(users.toArray(CompletableFuture[]::new)).join();
System.out.println(users.stream().map(CompletableFuture::join).toList());

// Failures: join() wraps in CompletionException, get() in ExecutionException.
CompletableFuture<Integer> failing = CompletableFuture.supplyAsync(() -> Integer.parseInt("x"), executor);
try {
    failing.join();
} catch (CompletionException e) {
    System.out.println("join: " + e.getCause().getClass().getSimpleName());
}
try {
    failing.get();
} catch (ExecutionException e) {
    System.out.println("get: " + e.getCause().getClass().getSimpleName());
}
System.out.println("recovered: " + failing.exceptionally(e -> -1).join());
```

```text
score: 60
Ada was born in 1815
[user-1, user-2, user-3]
join: NumberFormatException
get: NumberFormatException
recovered: -1
```

The futures here run on the lesson's virtual thread executor. Without the `executor` argument, `supplyAsync` runs on the common `ForkJoinPool`, a pool of platform threads sized from the number of cores, which is the wrong place for tasks that block.

Two differences from C# catch people out:

- **No unwrapping.** `await` rethrows the original exception; `CompletableFuture` always wraps it, like C#'s `.Result` wraps it in `AggregateException`. The C# side prints `Result: AggregateException of FormatException` then `await: FormatException`.
- **`get()` is checked, `join()` is not.** `get()` declares `InterruptedException` and `ExecutionException`, so the `.Result` habit doesn't compile in a method that doesn't handle them:

```java
import java.util.concurrent.CompletableFuture;

class Results {
    static String name() {
        return CompletableFuture.supplyAsync(() -> "Ada").get();
    }
}
```

```text
BlockingGet.java:5: error: unreported exception InterruptedException; must be caught or declared to be thrown
        return CompletableFuture.supplyAsync(() -> "Ada").get();
                                                             ^
1 error
```

With virtual threads, long `thenApply` chains are less necessary: code that runs on a virtual thread can call `join()` and continue on the next line, which reads like `await`. The keyword itself doesn't exist, and javac's message is just a syntax error:

```java
import java.util.concurrent.CompletableFuture;

class Client {
    static CompletableFuture<String> fetch() {
        return CompletableFuture.completedFuture("ok");
    }

    static String body() {
        return await fetch();
    }
}
```

```text
AwaitKeyword.java:9: error: ';' expected
        return await fetch();
                    ^
1 error
```

## Cancellation is interruption

Java has no `CancellationToken`. A thread is cancelled by **interrupting** it: blocking methods such as `Thread.sleep`, `BlockingQueue.take` or `Future.get` then throw `InterruptedException`, and a CPU-bound loop checks `Thread.currentThread().isInterrupted()`. `Future.cancel(true)` interrupts the thread running the task:

```java
// Cancellation: there is no CancellationToken; cancel(true) interrupts the thread running the task.
var started = new CountDownLatch(1);
var stopped = new CountDownLatch(1);
var worker = executor.submit(() -> {
    started.countDown();
    try {
        Thread.sleep(60_000);
        return "finished";
    } catch (InterruptedException e) {
        System.out.println("worker interrupted while sleeping");
        stopped.countDown();
        throw e;
    }
});
started.await();
worker.cancel(true);
stopped.await();
System.out.println("cancelled: " + worker.isCancelled() + ", state: " + worker.state());
```

```text
worker interrupted while sleeping
cancelled: true, state: CANCELLED
```

The two latches only make the output order deterministic. The C# equivalent passes `cts.Token` to `Task.Delay` and prints `cancelled: True, status: Canceled`. The difference is who asks: C# code must accept a token and pass it down, while any Java code that blocks is cancellable without changing its signature. The price is a rule to respect: a method that catches `InterruptedException` must either rethrow it or restore the flag with `Thread.currentThread().interrupt()`, or the cancellation is silently lost.

`CompletableFuture` breaks this rule on purpose. Its `cancel(true)` completes the future with a `CancellationException`, but the Javadoc says the argument "has no effect in this implementation because interrupts are not used to control processing". The task keeps running:

```java
// A timeout on the future itself, like Task.WaitAsync(TimeSpan).
var slow = CompletableFuture.supplyAsync(() -> sleepThenReturn(1_000), executor);
try {
    slow.get(50, TimeUnit.MILLISECONDS);
} catch (TimeoutException e) {
    System.out.println("timed out after 50 ms");
}
// cancel(true) completes the CompletableFuture but does not interrupt the task behind it.
System.out.println("slow cancelled: " + slow.cancel(true));
```

```text
timed out after 50 ms
slow cancelled: true
worker interrupted while sleeping
cancelled: true, state: CANCELLED
slow task ran to the end
```

The last line appears a second later, when the executor's `close()` waits for the slow task that was never stopped. My first version slept five seconds, and the example took five seconds to finish, which is how I found out.

## Shared state

Virtual threads change nothing about data races. This loop increments a `static int` from 1,000 tasks, 1,000 times each:

```java
executor.submit(() -> {
    for (int i = 0; i < 1_000; i++) {
        value++;
    }
});
```

Three runs on my machine printed 76,422, then 855,000, then 803,000, instead of 1,000,000. This snippet isn't part of the tested examples, because its output can't be predicted.

The same code with a local variable doesn't compile. A lambda captures values, not variables (lesson 6), so Java rejects the shared mutable local that C# accepts and races on:

```java
class Clicks {
    static int count() throws InterruptedException {
        int count = 0;
        Thread worker = Thread.ofVirtual().start(() -> count++);
        worker.join();
        return count;
    }
}
```

```text
CaptureCounter.java:4: error: local variables referenced from a lambda expression must be final or effectively final
        Thread worker = Thread.ofVirtual().start(() -> count++);
                                                       ^
1 error
```

The fixes are the ones you know from .NET:

```java
static class Counter {
    private int value;

    // synchronized is C#'s lock (this); every object has a monitor.
    synchronized void increment() {
        value++;
    }

    synchronized int value() {
        return value;
    }
}

static class Account {
    private final ReentrantLock lock = new ReentrantLock();
    private long balance;

    // An explicit lock, with try/finally where C# uses a lock statement.
    void deposit(long amount) {
        lock.lock();
        try {
            balance += amount;
        } finally {
            lock.unlock();
        }
    }
```

Running each counter from 1,000 tasks of 1,000 increments, and counting words with `ConcurrentHashMap.merge`:

```java
// merge is atomic per key, like ConcurrentDictionary.AddOrUpdate.
var words = List.of("to", "be", "or", "not", "to", "be");
var counts = new ConcurrentHashMap<String, Integer>();
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (int copy = 0; copy < 100; copy++) {
        for (String word : words) {
            executor.submit(() -> counts.merge(word, 1, Integer::sum));
        }
    }
}
Map<String, Integer> sorted = new TreeMap<>(counts);
System.out.println("word counts: " + sorted);
```

```text
synchronized: 1000000
AtomicInteger: 1000000
LongAdder: 1000000
ReentrantLock: 1000000
word counts: {be=200, not=100, or=100, to=200}
```

- **`synchronized`** is `lock`. A `synchronized` method locks `this` (or the class, for a static method), which C# style guides discourage and Java code does all the time. Since C# 13, .NET code can lock a dedicated [`System.Threading.Lock`](https://learn.microsoft.com/dotnet/api/system.threading.lock); in Java, a `ReentrantLock` field plays that role and adds `tryLock` with a timeout.
- **`AtomicInteger`** is `Interlocked`, wrapped in an object. `LongAdder` scales better when many threads increment the same counter often.
- **Before Java 24, `synchronized` pinned virtual threads**: a virtual thread that blocked inside a `synchronized` block kept its carrier thread, and libraries switched to `ReentrantLock` to avoid it. [JEP 491](https://openjdk.org/jeps/491) removed that limitation in Java 24, so advice to avoid `synchronized` with virtual threads is out of date on Java 25.

Like C#, which rejects `lock` on a value type ([CS0185](https://learn.microsoft.com/dotnet/csharp/misc/cs0185)), Java refuses to synchronize on a primitive:

```java
class Tally {
    private int count;

    void increment() {
        synchronized (count) {
            count++;
        }
    }
}
```

```text
SynchronizeOnInt.java:5: error: unexpected type
        synchronized (count) {
        ^
  required: reference
  found:    int
1 error
```

Change `int` to `Integer` and it compiles, which is worse: `count++` replaces the boxed object, so each thread may lock a different `Integer`. javac only warns, and only with `-Xlint`:

```text
SynchronizeOnInteger.java:5: warning: [identity] attempt to synchronize on an instance of a value-based class
        synchronized (count) {
        ^
1 warning
```

## `ThreadLocal`, `ScopedValue` and `AsyncLocal`

C# code that needs ambient context (the current user, a trace ID) uses `AsyncLocal<T>`, which flows along `await`s into tasks and new threads. Java's `ThreadLocal` doesn't flow anywhere, and a virtual thread per task is a new thread every time. [`ScopedValue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ScopedValue.html) ([JEP 506](https://openjdk.org/jeps/506), final in Java 25) is the modern replacement: a value bound for the duration of a call, immutable within it, and unbound again afterwards:

```java
static final ThreadLocal<String> CURRENT_USER = new ThreadLocal<>();

// A ScopedValue is bound for the duration of a call, then unbound again.
static final ScopedValue<String> REQUEST_USER = ScopedValue.newInstance();

static String greet() {
    return "hello " + (REQUEST_USER.isBound() ? REQUEST_USER.get() : "nobody");
}

public static void main(String[] args) throws Exception {
    CURRENT_USER.set("ada");
    try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
        // A ThreadLocal belongs to one thread: a task on another thread doesn't see it.
        System.out.println("caller thread: " + CURRENT_USER.get());
        System.out.println("executor task: " + executor.submit(CURRENT_USER::get).get());
    } finally {
        CURRENT_USER.remove();
    }

    ScopedValue.where(REQUEST_USER, "grace").run(() -> {
        System.out.println("inside the scope: " + greet());
        ScopedValue.where(REQUEST_USER, "alan").run(() -> System.out.println("nested scope: " + greet()));
        System.out.println("back in the outer scope: " + greet());
    });
    System.out.println("after the scope: " + greet());

    // Scoped values don't flow into an ordinary executor either: that needs structured concurrency (preview).
    ScopedValue.where(REQUEST_USER, "grace").run(() -> {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            System.out.println("executor task in the scope: " + executor.submit(ScopedValues::greet).get());
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    });
}
```

```text
caller thread: ada
executor task: null
inside the scope: hello grace
nested scope: hello alan
back in the outer scope: hello grace
after the scope: hello nobody
executor task in the scope: hello nobody
```

The C# side prints `AsyncLocal in Task.Run: grace` and `in a new thread: AsyncLocal grace, ThreadLocal null`. The last Java line is the gap: a scoped value reaches child threads only when they are forked by a `StructuredTaskScope`, and that API is still a preview.

## Structured concurrency is still a preview

[Structured concurrency](https://openjdk.org/jeps/505) treats a group of subtasks as one unit: if one fails, the others are cancelled, and the scope doesn't end before all of them do. It is the closest thing to a `Task.WhenAll` that cancels its siblings. In Java 25 it is in its fifth preview, and using it without `--enable-preview` fails:

```java
import java.util.concurrent.StructuredTaskScope;

class Fanout {
    static String both() throws InterruptedException {
        try (var scope = StructuredTaskScope.open()) {
            var user = scope.fork(() -> "ada");
            var order = scope.fork(() -> 42);
            scope.join();
            return user.get() + " " + order.get();
        }
    }
}
```

```text
StructuredScope.java:1: error: StructuredTaskScope is a preview API and is disabled by default.
import java.util.concurrent.StructuredTaskScope;
                           ^
  (use --enable-preview to enable preview APIs)
StructuredScope.java:5: error: StructuredTaskScope is a preview API and is disabled by default.
        try (var scope = StructuredTaskScope.open()) {
                         ^
  (use --enable-preview to enable preview APIs)
2 errors
```

As with primitive patterns in lesson 8, this course doesn't use preview features. The API has changed between previews: in Java 25 a scope is created with static `open()` factory methods and a `Joiner` that sets the completion policy, where earlier previews used constructors and subclasses such as `ShutdownOnFailure`.

## Parallel streams

Lesson 7 promised this section. `parallel()` on a stream is PLINQ's `AsParallel()`: the stream is split and processed on the common `ForkJoinPool`:

```java
// parallel() is AsParallel(); the result is the same as the sequential one.
long sequential = IntStream.rangeClosed(1, 2_000_000).filter(ParallelStreams::isPrime).count();
long parallel = IntStream.rangeClosed(1, 2_000_000).parallel().filter(ParallelStreams::isPrime).count();
System.out.println("primes up to 2,000,000: " + sequential + " sequential, " + parallel + " parallel");

// Unlike PLINQ without AsOrdered(), collecting keeps the encounter order.
List<Integer> squares = IntStream.rangeClosed(1, 10).parallel().map(x -> x * x).boxed().toList();
System.out.println("squares: " + squares);

// forEach runs in whatever order the threads reach the elements; forEachOrdered restores it.
var ordered = new StringBuilder();
IntStream.rangeClosed(1, 10).parallel().forEachOrdered(x -> ordered.append(x).append(' '));
System.out.println("forEachOrdered: " + ordered.toString().strip());

// reduce needs a true identity: 0 for addition. Sequentially, a wrong identity is added once.
int wrongIdentitySequential = IntStream.rangeClosed(1, 4).reduce(10, Integer::sum);
int rightIdentityParallel = IntStream.rangeClosed(1, 4).parallel().reduce(0, Integer::sum);
System.out.println("reduce(10) sequential: " + wrongIdentitySequential + ", reduce(0) parallel: " + rightIdentityParallel);

// Parallel streams run on the common ForkJoinPool, shared by the whole JVM.
Set<String> threads = ConcurrentHashMap.newKeySet();
IntStream.rangeClosed(1, 2_000_000).parallel().filter(n -> {
    threads.add(Thread.currentThread().getName());
    return isPrime(n);
}).count();
System.out.println("caller thread took part: " + threads.contains(Thread.currentThread().getName()));
System.out.println("common pool workers took part: " + threads.stream().anyMatch(t -> t.startsWith("ForkJoinPool.commonPool-worker-")));
```

```text
primes up to 2,000,000: 148933 sequential, 148933 parallel
squares: [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
forEachOrdered: 1 2 3 4 5 6 7 8 9 10
reduce(10) sequential: 20, reduce(0) parallel: 10
caller thread took part: true
common pool workers took part: true
```

- **Order is kept by default.** A parallel stream over an ordered source still collects in encounter order; PLINQ needs `AsOrdered()`. The C# side prints `AsOrdered: 1, 4, 9, …`. Only `forEach` gives up the order.
- **The identity of `reduce` must be a real identity.** `reduce(10, Integer::sum)` adds 10 once sequentially, but a parallel stream adds it once per chunk, so the result depends on how many chunks the machine creates. That is why the example runs the wrong identity sequentially only.
- **The caller works too.** The thread that starts the terminal operation takes part, alongside the common pool's workers. The pool is shared by the whole JVM, so one slow parallel stream slows down every other one.

Parallel streams help with large, CPU-bound, stateless work over sources that split well (arrays, ranges, `ArrayList`). They don't help with blocking I/O (use virtual threads), with small collections (splitting costs more than it saves), or with `LinkedList` and `Stream.iterate`, which don't split well. Measure before and after, with a warmed-up JVM: lesson 13 comes back to benchmarking.

## Key takeaways

- Virtual threads make blocking cheap, so Java code stays synchronous: no `async`, no `Task` in signatures. Use `Executors.newVirtualThreadPerTaskExecutor()` in `try`-with-resources; `close()` waits for all tasks.
- Virtual threads help with waiting, not with computing. Don't pool them.
- `CompletableFuture` is `Task`: `supplyAsync`, `thenApply`, `thenCombine`, `allOf`. Exceptions are always wrapped, and `get()` throws checked exceptions where `join()` doesn't.
- Cancellation is interruption. Rethrow `InterruptedException` or restore the interrupt flag. `CompletableFuture.cancel(true)` doesn't interrupt anything.
- `synchronized`, `ReentrantLock`, atomics and `ConcurrentHashMap` map onto `lock`, `Interlocked` and `ConcurrentDictionary`. Since Java 24, `synchronized` no longer pins virtual threads.
- `ScopedValue` (final in Java 25) replaces `ThreadLocal` for request context, but only structured concurrency, still a preview, passes it to child threads.
- Parallel streams keep encounter order, run on the shared common pool, and need a true identity in `reduce`.

## Exercises

1. Write `fetchAll(List<T> inputs, Function<T, R> fetch)`, the Java counterpart of `await Task.WhenAll(inputs.Select(FetchAsync))`: it runs every call concurrently and returns the results in input order. With a `fetch` that sleeps 200 ms, 100 inputs must complete in well under 5 seconds.

<details>
<summary>Solution</summary>

```java
static <T, R> List<R> fetchAll(List<T> inputs, Function<T, R> fetch) throws InterruptedException, ExecutionException {
    try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
        List<Callable<R>> calls = inputs.stream().<Callable<R>>map(input -> () -> fetch.apply(input)).toList();
        List<R> results = new ArrayList<>();
        for (Future<R> future : executor.invokeAll(calls)) {
            results.add(future.get());
        }
        return results;
    }
}
```

`invokeAll` waits for all the calls and returns their futures in the order of the list, so the results line up with the inputs. The type witness `<Callable<R>>` is needed: without it, the inner lambda has no target type, and javac reports "cannot infer type-variable(s) R … Object is not a functional interface". The test runs 100 calls of 200 ms and checks the order and the elapsed time. `fetch` is a `Function`, so it can't throw checked exceptions: a real HTTP call would wrap its `IOException`, as in lesson 5's exercise 1.

</details>

2. C# code often throttles concurrent calls with `SemaphoreSlim(3)` and `await semaphore.WaitAsync()`. Write `mapThrottled(inputs, maxConcurrency, work)`, which reuses `fetchAll` but lets at most `maxConcurrency` calls of `work` run at the same time.

<details>
<summary>Solution</summary>

```java
static <T, R> List<R> mapThrottled(List<T> inputs, int maxConcurrency, Function<T, R> work)
        throws InterruptedException, ExecutionException {
    var permits = new Semaphore(maxConcurrency);
    return fetchAll(inputs, input -> {
        try {
            permits.acquire();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
        try {
            return work.apply(input);
        } finally {
            permits.release();
        }
    });
}
```

[`Semaphore`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Semaphore.html) is `SemaphoreSlim` with a blocking `acquire()`, which is fine on a virtual thread. Every input still gets its own virtual thread, but only three at a time get past `acquire()`. The test records the highest number of calls running at once and checks that it never exceeds 3. The `finally` matters as much as C#'s `Release()` in a `finally`: an exception in `work` would otherwise keep a permit forever.

</details>

3. Two accounts, two kinds of task: one transfers from `a` to `b`, the other from `b` to `a`, each locking both accounts with `synchronized`. Written naively, 10,000 such tasks can deadlock. Write a `transfer(from, to, amount)` that cannot deadlock, and check that the total balance is conserved.

<details>
<summary>Solution</summary>

```java
static final class Account {
    final int id;
    long balance;

    Account(int id, long balance) {
        this.id = id;
        this.balance = balance;
    }
}

// Lock the account with the smaller id first, so two opposite transfers can't wait for each other.
static void transfer(Account from, Account to, long amount) {
    Account first = from.id < to.id ? from : to;
    Account second = first == from ? to : from;
    synchronized (first) {
        synchronized (second) {
            from.balance -= amount;
            to.balance += amount;
        }
    }
}
```

A deadlock needs a cycle: one task holds `a` and waits for `b` while another holds `b` and waits for `a`. Locking in a global order (here by id) breaks the cycle, in Java as with nested `lock` statements in C#. The test runs 10,000 transfers in alternating directions under `assertTimeoutPreemptively`, so a deadlock fails the test instead of hanging it, then checks that the two balances still add up to 2,000,000. A `ReentrantLock` with `tryLock(timeout)` is the other classic answer: back off and retry instead of waiting forever.

</details>

## Sources

- [Java Core Libraries — Virtual threads](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html)
- [JEP 444 — Virtual Threads](https://openjdk.org/jeps/444), [JEP 491 — Synchronize Virtual Threads without Pinning](https://openjdk.org/jeps/491), [JEP 505 — Structured Concurrency (Fifth Preview)](https://openjdk.org/jeps/505), [JEP 506 — Scoped Values](https://openjdk.org/jeps/506)
- [`java.util.concurrent` package summary](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/package-summary.html) and [`java.util.stream` — parallelism](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html)
- [JLS chapter 17 — Threads and Locks](https://docs.oracle.com/javase/specs/jls/se25/html/jls-17.html)
- C#: [asynchronous programming](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/), [cancellation in managed threads](https://learn.microsoft.com/dotnet/standard/threading/cancellation-in-managed-threads), [the `lock` statement](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/lock), [PLINQ](https://learn.microsoft.com/dotnet/standard/parallel-programming/introduction-to-plinq)
