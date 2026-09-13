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
- [ ] Lesson 13 — `async` and tokio
- [ ] Lesson 14 — Tests, docs, clippy, fmt
- [ ] Lesson 15 — Macros, `unsafe` and FFI

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

## Open questions

- How does `rust-analyzer` in RustRover compare with VS Code for these exercises?
