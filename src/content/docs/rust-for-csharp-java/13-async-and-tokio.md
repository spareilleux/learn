---
title: 13. async and tokio
description: async/await without a built-in runtime — lazy futures, tokio tasks, join!, select!, cancellation and the Send rule across .await.
sidebar:
  order: 13
---

Full example: [`examples/l13_async.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l13_async.rs) — `cargo run --example l13_async`.

## Same keywords, different machinery

The syntax will look familiar:

```rust
async fn fetch_price(item: &str, delay_ms: u64) -> u32 {
    sleep(Duration::from_millis(delay_ms)).await;   // simulated I/O
    item.len() as u32 * 10
}
```

Note that `.await` is a **postfix** keyword: `fetch(url).await?.json().await?` chains left to right, where C# needs `await (await fetch(url)).Json()`.

Three things differ fundamentally from C#:

| | C# [`Task`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task) / Java [`CompletableFuture`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/CompletableFuture.html) | Rust [`Future`](https://doc.rust-lang.org/std/future/trait.Future.html) |
|---|---|---|
| Starts running | immediately, when created ("hot") | only when awaited or spawned ("lazy") |
| Runtime | built in (thread pool, [`SynchronizationContext`](https://learn.microsoft.com/dotnet/api/system.threading.synchronizationcontext)) | none in the standard library — you pick a crate, usually **tokio** |
| Cost | usually a heap-allocated object per task | a state machine the compiler generates; no allocation unless spawned or boxed |

## Futures are lazy

An `async fn` returns a **future**: a value describing work that has not started.

```rust
let future = async {
    println!("  future body runs");
    1
};
println!("future created");
let one = future.await;
println!("awaited: {one}");
```

```text
future created
  future body runs
awaited: 1
```

In C#, forgetting `await` still runs the task (fire-and-forget). In Rust, a future that is never awaited **never runs**. The compiler warns you:

```rust
async fn log_call(name: &str) {
    println!("called {name}");
}

#[tokio::main]
async fn main() {
    log_call("save");         // missing .await
    println!("done");
}
```

```text
warning: unused implementer of `Future` that must be used
 --> examples\w13_not_awaited.rs:7:5
  |
7 |     log_call("save");
  |     ^^^^^^^^^^^^^^^^
  |
  = note: futures do nothing unless you `.await` or poll them
  = note: `#[warn(unused_must_use)]` (part of `#[warn(unused)]`) on by default
```

The program prints `done` and nothing else. When you do use the result, a forgotten `.await` is a type error: the future is not the value.

```text
error[E0308]: mismatched types
 --> examples\e13_missing_await.rs:6:22
  |
6 |     let price: u32 = fetch_price();
  |                ---   ^^^^^^^^^^^^^ expected `u32`, found future
  |                |
  |                expected due to this
  |
note: calling an async function returns a future
 --> examples\e13_missing_await.rs:6:22
  |
6 |     let price: u32 = fetch_price();
  |                      ^^^^^^^^^^^^^
help: consider `await`ing on the `Future`
  |
6 |     let price: u32 = fetch_price().await;
  |                                   ++++++
```

## A runtime: tokio

Something has to poll futures, wake them up when I/O is ready and schedule them on threads. The standard library does not include that piece, so `main` cannot simply be `async`:

```text
error[E0752]: `main` function is not allowed to be `async`
 --> examples\e13_async_main.rs:1:1
  |
1 | async fn main() {
  | ^^^^^^^^^^^^^^^ `main` function is not allowed to be `async`
```

[tokio](https://tokio.rs) is the de facto standard runtime ([axum](https://docs.rs/axum), [reqwest](https://docs.rs/reqwest), [tonic](https://docs.rs/tonic) and most of the async ecosystem build on it):

```toml
[dependencies]
tokio = { version = "1", features = ["rt-multi-thread", "macros", "time", "sync"] }
```

```rust
#[tokio::main]              // builds a multi-threaded runtime and runs main on it
async fn main() {
    // …
}
```

`.await` is also only allowed inside `async` code ([`E0728`](https://doc.rust-lang.org/error_codes/E0728.html)). The bridge from synchronous code is the runtime's [`block_on`](https://docs.rs/tokio/latest/tokio/runtime/struct.Runtime.html#method.block_on), which [`#[tokio::main]`](https://docs.rs/tokio/latest/tokio/attr.main.html) calls for you.

## Concurrency: `join!`, `spawn`, `JoinSet`

Awaiting one future after another is **sequential**:

```rust
let a = fetch_price("book", 100).await;
let b = fetch_price("pen", 100).await;
let c = fetch_price("lamp", 100).await;

let (a, b, c) = tokio::join!(fetch_price("book", 100), fetch_price("pen", 100), fetch_price("lamp", 100));
```

```text
sequential: 110 in ~300 ms
join!:      110 in ~100 ms
```

This is where laziness shows: in C#, `var t1 = FetchAsync(); var t2 = FetchAsync(); await t1; await t2;` is already concurrent because both tasks started when created. In Rust, the equivalent code runs one after the other; you ask for concurrency explicitly.

| C# | Java | tokio |
|---|---|---|
| [`await Task.WhenAll(a, b)`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.whenall) | `CompletableFuture.allOf(a, b)` | [`tokio::join!(a, b)`](https://docs.rs/tokio/latest/tokio/macro.join.html) |
| [`Task.Run(…)`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.run) | `CompletableFuture.supplyAsync(…)` | [`tokio::spawn(async { … })`](https://docs.rs/tokio/latest/tokio/task/fn.spawn.html) |
| [`Task.WhenAny`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.whenany) in a loop | [`ExecutorCompletionService`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/ExecutorCompletionService.html) | [`JoinSet::join_next()`](https://docs.rs/tokio/latest/tokio/task/struct.JoinSet.html#method.join_next) |
| `await Task.WhenAny(a, b)` | `CompletableFuture.anyOf(a, b)` | [`tokio::select!`](https://docs.rs/tokio/latest/tokio/macro.select.html) |
| [`Task.Delay`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.delay) | `CompletableFuture.delayedExecutor` | [`tokio::time::sleep`](https://docs.rs/tokio/latest/tokio/time/fn.sleep.html) |
| [`Channel<T>`](https://learn.microsoft.com/dotnet/api/system.threading.channels.channel-1) | [`BlockingQueue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/BlockingQueue.html) | [`tokio::sync::mpsc`](https://docs.rs/tokio/latest/tokio/sync/mpsc/index.html) |
| [`SemaphoreSlim.WaitAsync`](https://learn.microsoft.com/dotnet/api/system.threading.semaphoreslim.waitasync) | [`Semaphore`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Semaphore.html) | [`tokio::sync::Semaphore`](https://docs.rs/tokio/latest/tokio/sync/struct.Semaphore.html) |

`join!` runs its futures concurrently **inside the current task**. `tokio::spawn` hands a future to the runtime as an independent **task** that may run on another thread, and returns a [`JoinHandle`](https://docs.rs/tokio/latest/tokio/task/struct.JoinHandle.html):

```rust
let handle = tokio::spawn(async { fetch_price("keyboard", 50).await });
println!("spawned task returned {}", handle.await.unwrap());   // 80
```

`JoinSet` collects results in completion order:

```rust
let mut set = JoinSet::new();
for (item, delay) in [("slow", 150), ("fast", 50), ("medium", 100)] {
    set.spawn(async move { (item, fetch_price(item, delay).await) });
}
while let Some(result) = set.join_next().await {
    let (item, price) = result.unwrap();
    println!("  finished {item}: {price}");
}
```

```text
  finished fast: 40
  finished medium: 60
  finished slow: 40
```

## Cancellation is dropping

C# passes a [`CancellationToken`](https://learn.microsoft.com/dotnet/api/system.threading.cancellationtoken) through every call. In Rust, a future that is **dropped** simply stops at its current `.await` and never resumes. [`timeout`](https://docs.rs/tokio/latest/tokio/time/fn.timeout.html) and `select!` rely on that:

```rust
match timeout(Duration::from_millis(50), fetch_price("late", 200)).await {
    Ok(price) => println!("got {price}"),
    Err(_) => println!("timed out after 50 ms"),
}

tokio::select! {
    price = fetch_price("tortoise", 200) => println!("tortoise won: {price}"),
    price = fetch_price("hare", 20) => println!("hare won: {price}"),
}
```

```text
timed out after 50 ms
hare won: 40
```

The tortoise's future is dropped as soon as the hare wins. Destructors run, so resources are released. The catch is *cancellation safety*: if a future is dropped halfway through, say, reading a message, that partial work is lost. The tokio docs have a *cancel safety* section for the methods where this matters.

A spawned task keeps running after its `JoinHandle` is dropped; stop it with [`handle.abort()`](https://docs.rs/tokio/latest/tokio/task/struct.JoinHandle.html#method.abort).

## `Send` across `.await`

The multi-threaded runtime can move a task to another thread at any `.await`. So `tokio::spawn` requires the future to be `Send` — and a future holds every local variable that lives across an `.await`. Lesson 12's `Rc` problem comes back:

```rust
let handle = tokio::spawn(async {
    let counter = Rc::new(0);
    sleep(Duration::from_millis(10)).await;
    println!("{counter}");
});
```

```text
error: future cannot be sent between threads safely
   --> examples\e13_not_send.rs:6:18
    |
  6 |       let handle = tokio::spawn(async {
    |  __________________^
  7 | |         let counter = Rc::new(0);
  8 | |         sleep(Duration::from_millis(10)).await;
  9 | |         println!("{counter}");
 10 | |     });
    | |______^ future created by async block is not `Send`
    |
    = help: within `{async block@examples\e13_not_send.rs:6:31: 6:36}`, the trait `Send` is not implemented for `Rc<i32>`
note: future is not `Send` as this value is used across an await
   --> examples\e13_not_send.rs:8:42
    |
  7 |         let counter = Rc::new(0);
    |             ------- has type `Rc<i32>` which is not `Send`
  8 |         sleep(Duration::from_millis(10)).await;
    |                                          ^^^^^ await occurs here, with `counter` maybe used later
```

This error has no `E` code: it comes from the `F: Future + Send + 'static` bound on `tokio::spawn`. The fix is to use `Arc`, or to make sure the value is dropped before the `.await`.

The same applies to a [`std::sync::MutexGuard`](https://doc.rust-lang.org/std/sync/struct.MutexGuard.html) (exercise 3). When a lock must be held **across** an `.await`, use [`tokio::sync::Mutex`](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html), whose `lock()` is itself async:

```rust
let cache = Arc::new(tokio::sync::Mutex::new(Vec::new()));
// in each task:
let mut guard = cache.lock().await;
let price = fetch_price(item, 10).await;     // the guard is held across this await
guard.push(price);
```

For short critical sections with no `.await` inside, the standard `Mutex` is faster and fine.

## Don't block the runtime

An async worker thread runs many tasks, switching at each `.await`. Code that blocks without awaiting — [`std::thread::sleep`](https://doc.rust-lang.org/std/thread/fn.sleep.html), synchronous file or network I/O, a long computation — freezes every task on that thread. The C# equivalent is calling [`.Result`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task-1.result) or doing CPU work on a UI or ASP.NET thread.

```rust
let primes = tokio::task::spawn_blocking(|| (1..100_000u64).filter(|&n| is_prime(n)).count())
    .await
    .unwrap();
// primes below 100000: 9592
```

[`spawn_blocking`](https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html) runs a closure on a separate pool reserved for blocking work. For data-parallel computation, rayon from lesson 12 is still the better tool.

:::note[Java took the other road]
Java 21's [*virtual threads*](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html) let you write plain blocking code while the JVM multiplexes cheap threads underneath — no `async` keyword at all. Rust and C# chose explicit `async`/`await` instead: more syntax, but no hidden runtime and, in Rust's case, futures that cost no allocation.
:::

## Key takeaways

- Rust futures are lazy: nothing runs until you `.await` or spawn them; a forgotten `.await` is a warning or a type error.
- The runtime is a library: `#[tokio::main]`, `tokio::spawn`, `tokio::time`, `tokio::sync`.
- Concurrency is explicit: `join!` and `JoinSet` for "all", `select!` and `timeout` for "first".
- Cancelling means dropping the future; think about what a half-finished future leaves behind.
- Spawned futures must be `Send`: no `Rc` or `std::sync::MutexGuard` across an `.await`.
- Never block an async thread; use `spawn_blocking` or rayon for CPU work.

## Exercises

1. Write `async fn fetch_all(items: &[(&str, u64)]) -> Vec<u32>` that fetches every price concurrently (each item with its own delay) and returns the prices **in input order**. With delays of 150, 10 and 80 ms, how long should it take?

<details>
<summary>Solution</summary>

```rust
async fn fetch_price(item: String, delay_ms: u64) -> u32 {
    sleep(Duration::from_millis(delay_ms)).await;
    item.len() as u32 * 10
}

async fn fetch_all(items: &[(&str, u64)]) -> Vec<u32> {
    let handles: Vec<_> = items
        .iter()
        .map(|&(item, delay)| tokio::spawn(fetch_price(item.to_string(), delay)))
        .collect();
    let mut prices = Vec::with_capacity(handles.len());
    for handle in handles {
        prices.push(handle.await.unwrap());
    }
    prices
}

let prices = fetch_all(&[("slow", 150), ("fast", 10), ("medium", 80)]).await;
assert_eq!(prices, [40, 40, 60]);   // ~150 ms, not 240 ms
```

All tasks start when spawned, so the total is the longest delay, about 150 ms. Awaiting the handles in order keeps the input order; a `JoinSet` would give completion order instead. `fetch_price` takes a `String` because a spawned task must be `'static` and cannot borrow `items`.

</details>

2. Write `async fn fetch_with_retry(delays: &[u64], per_try: Duration) -> Result<u32, String>`: attempt `i` calls a fetch taking `delays[i]` ms, gives up on that attempt after `per_try`, and moves on to the next. Return the first success, or an error after the last attempt.

<details>
<summary>Solution</summary>

```rust
async fn fetch_price(delay_ms: u64) -> u32 {
    sleep(Duration::from_millis(delay_ms)).await;
    42
}

async fn fetch_with_retry(delays: &[u64], per_try: Duration) -> Result<u32, String> {
    for (attempt, &delay) in delays.iter().enumerate() {
        match timeout(per_try, fetch_price(delay)).await {
            Ok(price) => return Ok(price),
            Err(_) => println!("attempt {} timed out", attempt + 1),
        }
    }
    Err(format!("gave up after {} attempts", delays.len()))
}

let per_try = Duration::from_millis(50);
assert_eq!(fetch_with_retry(&[5_000, 5_000, 10], per_try).await, Ok(42));
assert_eq!(fetch_with_retry(&[5_000, 5_000], per_try).await, Err("gave up after 2 attempts".to_string()));
```

Each timed-out attempt is dropped, so the 5-second sleeps never finish and cost nothing afterwards. There is no token to thread through `fetch_price`.

</details>

3. This does not compile. Read the error, then fix it in two different ways.

```rust
let hits = Arc::new(std::sync::Mutex::new(0));
let h = Arc::clone(&hits);
tokio::spawn(async move {
    let mut guard = h.lock().unwrap();
    sleep(Duration::from_millis(10)).await;
    *guard += 1;
})
.await
.unwrap();
```

```text
error: future cannot be sent between threads safely
   --> examples\e13_guard_await.rs:8:5
    |
  8 | /     tokio::spawn(async move {
  9 | |         let mut guard = h.lock().unwrap();
 10 | |         sleep(Duration::from_millis(10)).await;
 11 | |         *guard += 1;
 12 | |     })
    | |______^ future created by async block is not `Send`
    |
    = help: within `{async block@examples\e13_guard_await.rs:8:18: 8:28}`, the trait `Send` is not implemented for `std::sync::MutexGuard<'_, i32>`
note: future is not `Send` as this value is used across an await
   --> examples\e13_guard_await.rs:10:42
    |
  9 |         let mut guard = h.lock().unwrap();
    |             --------- has type `std::sync::MutexGuard<'_, i32>` which is not `Send`
 10 |         sleep(Duration::from_millis(10)).await;
    |                                          ^^^^^ await occurs here, with `mut guard` maybe used later
```

<details>
<summary>Solution</summary>

**Fix 1** — don't hold the guard across the `.await`. Lock only for the update:

```rust
tokio::spawn(async move {
    sleep(Duration::from_millis(10)).await;
    *h.lock().unwrap() += 1;          // the guard is dropped at the end of the statement
})
```

**Fix 2** — use an async mutex, whose guard is `Send` and may be held while waiting:

```rust
let hits = Arc::new(tokio::sync::Mutex::new(0));
let h = Arc::clone(&hits);
tokio::spawn(async move {
    let mut guard = h.lock().await;
    sleep(Duration::from_millis(10)).await;
    *guard += 1;
})
```

Prefer fix 1 when the critical section needs no `.await`: it is cheaper, and holding a lock while waiting on I/O slows every other task down. Use fix 2 when the protected operation itself is asynchronous.

</details>

## Sources

- [The Book, ch. 17 — Fundamentals of Asynchronous Programming](https://doc.rust-lang.org/book/ch17-00-async-await.html)
- [Asynchronous Programming in Rust](https://rust-lang.github.io/async-book/)
- [Tokio tutorial](https://tokio.rs/tokio/tutorial) — spawning, shared state, channels, `select!`
- [`tokio::task::JoinSet`](https://docs.rs/tokio/latest/tokio/task/struct.JoinSet.html) and [`tokio::select!`](https://docs.rs/tokio/latest/tokio/macro.select.html) (cancellation safety)
- [`tokio::task::spawn_blocking`](https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html)
