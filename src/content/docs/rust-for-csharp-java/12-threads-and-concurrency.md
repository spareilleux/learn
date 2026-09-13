---
title: 12. Threads, Send/Sync, Mutex and rayon
description: Fearless concurrency — threads, scoped threads, shared state, channels, atomics and data parallelism, with data races rejected at compile time.
sidebar:
  order: 12
---

Full example: [`examples/l12_threads.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l12_threads.rs) — `cargo run --example l12_threads`.

## What the compiler checks for you

In C# and Java, the compiler happily lets two threads write to the same `List<T>`. The bug shows up later, maybe once in a thousand runs, as corrupted data or an exception far from its cause.

Rust's ownership and borrowing rules — *one writer or many readers* — are exactly the rules that prevent **data races**. Applied to threads, they make a data race a compile error. The Rust community calls this *fearless concurrency*.

What Rust does **not** prevent: deadlocks, race conditions at a higher level (check-then-act), and starvation. Those are still your job.

## `thread::spawn`

```rust
use std::thread;

let names = [String::from("ada"), String::from("grace")];
let handle = thread::spawn(move || names.iter().map(|n| n.len()).sum::<usize>());
println!("total name length: {}", handle.join().unwrap());   // 8
```

| Rust | C# | Java |
|---|---|---|
| `thread::spawn(closure)` | `new Thread(...).Start()` / `Task.Run` | `new Thread(...).start()` |
| `handle.join()` returns the closure's result | `thread.Join()` (no result) / `await task` | `thread.join()` (no result) / `future.get()` |
| `join()` returns `Err` if the thread panicked | exception rethrown by `Task` | `ExecutionException` |

The new thread may outlive the function that started it, so it cannot borrow that function's locals ([lesson 9](../09-lifetimes/), `'static`). Forgetting `move` gives a very direct error:

```rust
let names = vec!["ada", "grace"];
let handle = thread::spawn(|| {
    println!("{names:?}");
});
```

```text
error[E0373]: closure may outlive the current function, but it borrows `names`, which is owned by the current function
 --> e12_no_move.rs:5:32
  |
5 |     let handle = thread::spawn(|| {
  |                                ^^ may outlive borrowed value `names`
6 |         println!("{names:?}");
  |                    ----- `names` is borrowed here
  |
note: function requires argument type to outlive `'static`
…
help: to force the closure to take ownership of `names` (and any other referenced variables), use the `move` keyword
  |
5 |     let handle = thread::spawn(move || {
  |                                ++++
```

## Scoped threads: borrowing is allowed

`thread::scope` guarantees that every thread spawned inside it is joined before `scope` returns, so those threads **can** borrow local data:

```rust
let data: Vec<u64> = (1..=1_000).collect();
let chunk_sums: Vec<u64> = thread::scope(|s| {
    let handles: Vec<_> = data
        .chunks(250)
        .map(|chunk| s.spawn(move || chunk.iter().sum::<u64>()))   // moves the &[u64] slice, not the data
        .collect();
    handles.into_iter().map(|h| h.join().unwrap()).collect()
});
// chunk sums: [31375, 93875, 156375, 218875], total 500500
```

Borrowing still follows the usual rules. Two threads mutating the same counter is a data race, and it does not compile:

```rust
let mut count = 0;
thread::scope(|s| {
    s.spawn(|| count += 1);
    s.spawn(|| count += 1);
});
```

```text
error[E0499]: cannot borrow `count` as mutable more than once at a time
   --> e12_race.rs:7:17
    |
  5 |     thread::scope(|s| {
    |                    - has type `&'1 Scope<'1, '_>`
  6 |         s.spawn(|| count += 1);
    |         ----------------------
    |         |       |  |
    |         |       |  first borrow occurs due to use of `count` in closure
    |         |       first mutable borrow occurs here
    |         argument requires that `count` is borrowed for `'1`
  7 |         s.spawn(|| count += 1);
    |                 ^^ ----- second borrow occurs due to use of `count` in closure
    |                 |
    |                 second mutable borrow occurs here
```

The C# equivalent — `count++` from two tasks — compiles and silently loses increments.

## `Send` and `Sync`

Two marker traits, implemented automatically by the compiler, decide what may cross a thread boundary:

- **`Send`**: a value of this type can be **moved** to another thread.
- **`Sync`**: a value can be **shared** by reference between threads (`T` is `Sync` when `&T` is `Send`).

Almost every type is both. The exceptions are the single-thread tools from [lesson 11](../11-smart-pointers/):

| Type | `Send` | `Sync` | Why |
|---|---|---|---|
| `i32`, `String`, `Vec<T>`… | yes | yes | plain owned data |
| `Rc<T>` | no | no | non-atomic reference count |
| `Arc<T>` (with `T: Send + Sync`) | yes | yes | atomic count |
| `Cell<T>`, `RefCell<T>` | yes | **no** | unsynchronised interior mutability |
| `Mutex<T>` (with `T: Send`) | yes | yes | access is synchronised |

`thread::spawn` requires its closure to be `Send`, so everything it captures must be too. Sharing a `RefCell` through an `Arc` fails — and the compiler suggests the thread-safe alternative:

```rust
let total = Arc::new(RefCell::new(0));
let t = Arc::clone(&total);
thread::spawn(move || *t.borrow_mut() += 1).join().unwrap();
```

```text
error[E0277]: `RefCell<i32>` cannot be shared between threads safely
   --> e12_refcell_sync.rs:8:19
    |
  8 |     thread::spawn(move || *t.borrow_mut() += 1).join().unwrap();
    |     ------------- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `RefCell<i32>` cannot be shared between threads safely
    |     |
    |     required by a bound introduced by this call
    |
    = help: the trait `Sync` is not implemented for `RefCell<i32>`
    = note: if you want to do aliasing and mutation between multiple threads, use `std::sync::RwLock` instead
    = note: required for `Arc<RefCell<i32>>` to implement `Send`
```

C# and Java have no such distinction: thread safety is a comment in the documentation. In Rust it is part of the type.

## Shared state: `Arc<Mutex<T>>`

A C# `lock (obj) { … }` protects code; nothing stops another method from touching the list without locking. A Rust `Mutex<T>` **owns** the data, and the only way to reach it is `lock()`:

```rust
let count = std::sync::Mutex::new(0);
*count += 1;
```

```text
error[E0614]: type `std::sync::Mutex<{integer}>` cannot be dereferenced
 --> e12_mutex_no_lock.rs:5:5
  |
5 |     *count += 1;
  |     ^^^^^^ can't be dereferenced
```

Combined with `Arc` for shared ownership:

```rust
use std::sync::{Arc, Mutex};

let results = Arc::new(Mutex::new(Vec::new()));
let workers: Vec<_> = (1..=4)
    .map(|id| {
        let results = Arc::clone(&results);
        thread::spawn(move || {
            let square = id * id;
            results.lock().unwrap().push((id, square));   // unlocked at the end of the statement
        })
    })
    .collect();
for worker in workers {
    worker.join().unwrap();
}
// squares: [(1, 1), (2, 4), (3, 9), (4, 16)]   (after sorting)
```

- `lock()` returns a **guard** (`MutexGuard`) that derefs to the data. The lock is released when the guard is dropped — no `finally`, no forgotten `unlock()` as with Java's `ReentrantLock`.
- `lock()` returns a `Result`: if a thread **panicked** while holding the lock, the mutex is *poisoned* and later `lock()` calls return `Err`. `.unwrap()` propagates that panic, which is usually what you want.
- Keep the guard's scope short. Holding it across a slow call blocks everyone else — and two threads taking two locks in opposite order still deadlock.

`RwLock<T>` allows many readers or one writer, like `ReaderWriterLockSlim` or `ReentrantReadWriteLock`:

```rust
let settings = RwLock::new(HashMap::from([("mode", "fast")]));
{
    let a = settings.read().unwrap();
    let b = settings.read().unwrap();      // two readers at once are fine
}
settings.write().unwrap().insert("mode", "safe");
```

## Atomics

For a counter or a flag, a lock is overkill:

```rust
use std::sync::atomic::{AtomicUsize, Ordering};

let hits = AtomicUsize::new(0);
thread::scope(|s| {
    for _ in 0..8 {
        s.spawn(|| {
            for _ in 0..1_000 {
                hits.fetch_add(1, Ordering::Relaxed);
            }
        });
    }
});
// hits: 8000
```

`fetch_add` is `Interlocked.Increment` / `AtomicInteger.getAndAdd`. The `Ordering` argument describes the memory-ordering guarantee you need; for an independent counter `Relaxed` is enough (the *Rust Atomics and Locks* book, linked below, explains the others). Note that the scoped threads borrow `hits` without an `Arc`: an atomic is `Sync`.

## Channels: share by communicating

Instead of sharing data, threads can send values to each other. Sending **moves** the value, so the sender cannot touch it afterwards:

```rust
use std::sync::mpsc;

let (sender, receiver) = mpsc::channel();
for id in 0..3 {
    let sender = sender.clone();            // one sender per thread
    thread::spawn(move || {
        sender.send(format!("worker {id} done")).unwrap();
    });
}
drop(sender);                               // otherwise the loop below never ends
let messages: Vec<String> = receiver.iter().collect();
// ["worker 0 done", "worker 1 done", "worker 2 done"]   (after sorting)
```

`mpsc` means *multiple producer, single consumer*. The C# equivalent is `System.Threading.Channels.Channel<T>` or `BlockingCollection<T>`; in Java, a `BlockingQueue`. The receiver's iterator ends when every `Sender` has been dropped — forgetting `drop(sender)` is the classic hang.

## Data parallelism with rayon

For "do this to every element, on all cores", don't manage threads yourself. The [rayon](https://docs.rs/rayon) crate turns an iterator chain into a parallel one — the equivalent of PLINQ's `AsParallel()` or Java's `parallelStream()`:

```toml
[dependencies]
rayon = "1"
```

```rust
use rayon::prelude::*;

fn is_prime(n: u64) -> bool {
    n >= 2 && (2..).take_while(|d| d * d <= n).all(|d| !n.is_multiple_of(d))
}

let sequential = (1..200_000u64).filter(|&n| is_prime(n)).count();
let parallel = (1..200_000u64).into_par_iter().filter(|&n| is_prime(n)).count();
// primes below 200000: 17984 sequential, 17984 parallel

let mut words = vec!["pear", "fig", "apple", "kiwi"];
words.par_sort_unstable();
let lengths: Vec<usize> = words.par_iter().map(|w| w.len()).collect();   // order is preserved
// ["apple", "fig", "kiwi", "pear"] [5, 3, 4, 4]
```

| Sequential | rayon |
|---|---|
| `.iter()` | `.par_iter()` |
| `.into_iter()` | `.into_par_iter()` |
| `.iter_mut()` | `.par_iter_mut()` |
| `.sort()` | `.par_sort()` |

rayon runs the work on a pool with one thread per core and splits it with *work stealing*, like the .NET thread pool and Java's `ForkJoinPool`. Its closures must be `Fn` (no mutation of captured variables) and `Send + Sync`, so the data race from earlier cannot sneak back in:

```rust
let mut seen = 0;
let doubled: Vec<i32> = (1..100).into_par_iter().map(|n| { seen += 1; n * 2 }).collect();
```

```text
error[E0594]: cannot assign to `seen`, as it is a captured variable in a `Fn` closure
 --> src\main.rs:5:64
  |
4 |     let mut seen = 0;
  |         -------- `seen` declared here, outside the closure
5 |     let doubled: Vec<i32> = (1..100).into_par_iter().map(|n| { seen += 1; n * 2 }).collect();
  |                                                          ---   ^^^^^^^^^ cannot assign
  |                                                          |
  |                                                          in this closure
```

Use `.count()`, or an `AtomicUsize`, instead.

On my machine (Intel Core Ultra 9 285K, 24 cores, release build), counting the primes below 5,000,000 took **about 775 ms** sequentially and **about 41 ms** with `into_par_iter()` — see exercise 3.

:::note[Threads or async?]
Threads (and rayon) are for **CPU-bound** work: every core computes. For **I/O-bound** work — thousands of network requests mostly waiting — you want `async`, the subject of lesson 13.
:::

## Key takeaways

- The borrowing rules forbid data races, so a data race is a compile error; deadlocks are still possible.
- `thread::spawn` needs `move` and `'static` data; `thread::scope` lets threads borrow locals.
- `Send` (can be moved to a thread) and `Sync` (can be shared between threads) are checked by the compiler; `Rc` and `RefCell` are not thread-safe.
- `Mutex<T>` owns its data: you cannot forget to lock, and the guard unlocks on drop. Share it with `Arc`.
- Atomics for counters, channels to pass ownership between threads, rayon for data parallelism.

## Exercises

1. Write `fn parallel_sum(data: &[u64], threads: usize) -> u64` that splits `data` into at most `threads` chunks and sums them on scoped threads. It must work for an empty slice and for more threads than elements.

<details>
<summary>Solution</summary>

```rust
fn parallel_sum(data: &[u64], threads: usize) -> u64 {
    let chunk_size = data.len().div_ceil(threads.max(1)).max(1);
    std::thread::scope(|s| {
        let handles: Vec<_> = data
            .chunks(chunk_size)
            .map(|chunk| s.spawn(move || chunk.iter().sum::<u64>()))
            .collect();
        handles.into_iter().map(|h| h.join().unwrap()).sum()
    })
}

let data: Vec<u64> = (1..=10_001).collect();
assert_eq!(parallel_sum(&data, 4), 50_015_001);
assert_eq!(parallel_sum(&data, 64), 50_015_001);
assert_eq!(parallel_sum(&[], 4), 0);
```

`chunks` panics on a size of 0, hence the two `max(1)`. The handles are collected into a `Vec` **before** joining: joining inside the same `map` would wait for each thread before starting the next, and the code would run sequentially.

</details>

2. Write `fn count_words(texts: &[&str]) -> HashMap<String, usize>` (case-insensitive) that processes each text on its own thread. Use a channel rather than an `Arc<Mutex<HashMap>>`. Why is that a better design here?

<details>
<summary>Solution</summary>

```rust
use std::collections::HashMap;
use std::sync::mpsc;

fn count_words(texts: &[&str]) -> HashMap<String, usize> {
    let (sender, receiver) = mpsc::channel();
    std::thread::scope(|s| {
        for &text in texts {
            let sender = sender.clone();
            s.spawn(move || {
                let mut local = HashMap::new();
                for word in text.split_whitespace() {
                    *local.entry(word.to_lowercase()).or_insert(0) += 1;
                }
                sender.send(local).unwrap();
            });
        }
    });
    drop(sender);

    let mut total = HashMap::new();
    for local in receiver {
        for (word, n) in local {
            *total.entry(word).or_insert(0) += n;
        }
    }
    total
}

let counts = count_words(&["the cat", "The dog", "a cat and THE end"]);
assert_eq!(counts["the"], 3);
assert_eq!(counts["cat"], 2);
assert_eq!(counts.len(), 6);
```

Each thread works on its own map with no locking, and sends it once when done. With a shared `Mutex<HashMap>`, every single word would take the lock, so the threads would mostly wait for each other. The unbounded channel buffers the maps, so the threads can finish before `main` reads them.

</details>

3. Count the primes below 5,000,000 with `is_prime` from this lesson, sequentially and with rayon, and time both with `std::time::Instant` in a **release** build (`cargo run --release`). Check that both counts are equal. How close to "number of cores ×" is the speed-up?

<details>
<summary>Solution</summary>

```rust
use rayon::prelude::*;
use std::time::Instant;

let limit = 5_000_000u64;

let start = Instant::now();
let sequential = (1..limit).filter(|&n| is_prime(n)).count();
let seq_time = start.elapsed();

let start = Instant::now();
let parallel = (1..limit).into_par_iter().filter(|&n| is_prime(n)).count();
let par_time = start.elapsed();

assert_eq!(parallel, sequential);
println!("{sequential} primes in {seq_time:.2?} sequential, {parallel} in {par_time:.2?} parallel on {} threads", rayon::current_num_threads());
```

On my machine:

```text
348513 primes in 770.75ms sequential, 348513 in 41.76ms parallel on 24 threads
```

About 18× on 24 cores. The speed-up is below 24× because this CPU mixes performance and efficiency cores and because splitting and joining has a cost. Also, checking large numbers takes longer than small ones, so the chunks are uneven. The task is ideal otherwise: every number is independent. Always measure in release mode; debug-build timings are not representative.

</details>

## Sources

- [The Book, ch. 16 — Fearless Concurrency](https://doc.rust-lang.org/book/ch16-00-concurrency.html)
- [`std::thread::scope`](https://doc.rust-lang.org/std/thread/fn.scope.html)
- [`std::marker::Send`](https://doc.rust-lang.org/std/marker/trait.Send.html) and [`Sync`](https://doc.rust-lang.org/std/marker/trait.Sync.html)
- [`std::sync::Mutex`](https://doc.rust-lang.org/std/sync/struct.Mutex.html) — including poisoning
- [rayon documentation](https://docs.rs/rayon)
- [Mara Bos, *Rust Atomics and Locks*](https://mara.nl/atomics/) — free online
