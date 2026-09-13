---
title: Journal
description: Dated progress notes for the Rust course — attempts, surprises and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Lesson 1 — Toolchain and Cargo
- [x] Lesson 2 — Types, mutability and expressions
- [x] Lesson 3 — Ownership and moves
- [x] Lesson 4 — Borrowing and strings
- [x] Lesson 5 — Structs, enums and pattern matching
- [x] Lesson 6 — `Option`, `Result` and `?`
- [x] Lesson 7 — Traits and generics
- [x] Lesson 8 — Collections and iterators
- [x] Lesson 9 — Lifetimes
- [x] Lesson 10 — Modules, crates and workspaces
- [x] Lesson 11 — `Box`, `Rc`, `Arc`, `RefCell`
- [x] Lesson 12 — Threads, `Send`/`Sync`, `Mutex`, rayon
- [x] Lesson 13 — `async` and tokio
- [x] Lesson 14 — Tests, docs, clippy, fmt
- [x] Lesson 15 — Macros, `unsafe` and FFI

## 2026-09-13 — Lessons 1 to 4

- Toolchain on my machine: `rustc 1.94.0`, `cargo 1.94.0`, edition 2024 by default for `cargo new`.
- Every snippet was compiled before being written into a lesson; the compiler errors are copied from real `rustc` output (only the long "other types implement this trait" notes were trimmed).
- The course code lives in [`code/rust-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java): runnable `examples/` and `compile_fail` doctests in `src/lib.rs`, checked by the *Rust course examples* GitHub workflow.

**Surprises coming from C#:**

- Integer overflow **panics** in debug builds but **wraps** in release builds — verified with `255u8 + 1` compiled both ways. C# wraps in both unless `checked`.
- Clippy flagged `let scores = vec![90, 72, 85, 60];` as `useless_vec` because the vector was only ever read as a slice — an array would do.
- The borrow checker error for "push while iterating" is the compile-time version of `InvalidOperationException: Collection was modified`.

**Answered: does `compile_fail,E0382` check the error code?** Not on stable. A doctest marked `compile_fail,E0999` around a use-after-move (really `E0382`) still passed with `cargo test --doc` on 1.94.0 — stable only checks that compilation fails. The CI workflow now also runs `cargo +nightly test --doc`, which does compare the codes.

## 2026-09-13 — Lessons 5 to 8

Every exercise solution is now a doctest too: 41 doctests in total (compile-fail snippets plus solutions), all green on 1.94.0.

**Mistakes the tests caught before publishing:**

- I first wrote `prices.sort_by(|a, b| a.total_cmp(b))` on `vec![19.99, 5.0, 12.5]`. It does not compile: the literals are still an undecided `{float}` when the closure is type-checked (`E0599: no method named total_cmp found for reference &{float}`). Annotating `Vec<f64>` fixes it — lesson 8 now explains this.
- In lesson 7 I claimed `cheapest` could take a `Vec<Box<dyn Priced>>` with a `T: Priced + ?Sized` bound. Wrong: `&[T]` requires `T: Sized`. The working version implements `Priced` for `Box<dyn Priced>`, and that is what the exercise now shows (and tests).
- Clippy rejected `(1..=5).fold(1, |acc, n| acc * n)` in favour of `.product()` (`unnecessary_fold`), so the `fold` example computes a min/max pair instead — something no single adapter does.

**Surprises coming from C#:**

- When `main` returns `Err`, Rust prints the error with its `Debug` format (`Error: Missing("port")`), not `Display`, and exits with code 1.
- `Vec<f64>::sort()` does not compile at all (`f64` is not `Ord`), where C# and Java sort doubles silently.
- The `E0004` message for a new enum variant names the exact missing pattern (`&Payment::Crypto { .. } not covered`) — better than any C# analyzer warning I know.

## 2026-09-13 — Lessons 9 to 12

76 doctests now (stable and nightly), plus a real two-crate workspace for lesson 10 (`code/rust-for-csharp-java/l10-workspace`) that CI tests, lints and runs. The course crate gained its first dependency: `rayon`, as a dev-dependency.

**Things I got wrong first:**

- In the lesson 9 example I used `drop(parser)` to show that the tokens outlive the parser. Clippy refused it (`drop_non_drop`): dropping a type with no `Drop` impl does nothing useful. A `tokenize` function whose local parser dies at the end makes the same point better.
- Clippy also taught me `u64::is_multiple_of` (`manual_is_multiple_of`) instead of `n % d != 0`.
- I assumed a rayon `map` that mutates a captured counter would fail with a `Send`/`Sync` error. It fails earlier: rayon's closures are `Fn`, so it is `E0594: cannot assign to a captured variable in a Fn closure`.

**Surprises:**

- The `RefCell` panic message on 1.94 is just `RefCell already borrowed`; older material quotes `already borrowed: BorrowMutError`.
- Writing `&str` instead of `&'a str` as a method's return type compiles fine — the error only appears at the call site, when you try to hold two tokens (`E0499`). Elision picked `&mut self`'s lifetime.
- A recursive enum without `Box` gives `E0391` (a cycle in the compiler's "needs drop" query) in addition to `E0072`.
- rayon on this machine (Core Ultra 9 285K, 24 cores): counting primes below 5,000,000 went from ~775 ms to ~41 ms, about 18×.

## 2026-09-13 — Lessons 13 to 15, and three operating systems

The core course is complete. The code now has tokio as a dev-dependency, two more small crates (`l14-testing`, and `l15-ffi` with a .NET 10 client), and CI runs everything on **Windows, Ubuntu and macOS**. The C# program calls the Rust library successfully on all three.

**Things I got wrong first:**

- The lesson 15 FFI test asserted `pricing_sum([19.99, 5.0, 12.5]) == 37.49`. The real `f64` sum is `37.489999999999995`; C# had printed `37.49` only because of its `F2` format.
- An XML comment in the `.csproj` contained `--release`: MSBuild refuses to load a project whose comment contains `--`.
- I wrote that `[LibraryImport]` marshals `bool` as a 4-byte `BOOL` by default. It has no default at all: the build fails with `SYSLIB1051` until you add `[MarshalAs]`. That was `[DllImport]`'s behaviour.
- `cargo fmt --check --manifest-path …` worked on my machine (Cargo 1.94) but failed on the CI runners (Cargo 1.98.1) with `Failed to find targets`. CI now runs `cargo fmt --check` from each crate's folder.
- `missing_docs = "warn"` in `[lints]` also applies to integration tests: each file in `tests/` is its own crate and needs a `//!` line.
- A lesson 13 doctest asserted that three concurrent sleeps finish within 290 ms. That is true on my machine but a timing assertion is a flaky test on shared CI runners, so the test now checks only the results.

**Surprises:**

- In async Rust, a forgotten `.await` means the code **never runs** — the opposite of C#, where the task starts anyway.
- The "future cannot be sent between threads safely" error has no `E` code: it comes from the `Send` bound on `tokio::spawn`, not from the language.
- Edition 2024 requires `unsafe extern "C"` and `#[unsafe(no_mangle)]`; much older FFI material no longer compiles as written.
- `cargo fmt` had never been run on this course: 30 formatting differences in twelve lessons of examples.
- Hello world in release mode: about 130 KB on Windows, 430–460 KB on Linux and macOS (CI runners, Cargo 1.98.1).

## Open questions

- How does `rust-analyzer` in RustRover compare with VS Code for these exercises?
