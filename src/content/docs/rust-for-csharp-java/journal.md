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
- [ ] Lesson 5 — Structs, enums and pattern matching
- [ ] Lesson 6 — `Option`, `Result` and `?`
- [ ] Lesson 7 — Traits and generics
- [ ] Lesson 8 — Collections and iterators
- [ ] Lesson 9 — Lifetimes
- [ ] Lesson 10 — Modules, crates and workspaces
- [ ] Lesson 11 — `Box`, `Rc`, `Arc`, `RefCell`
- [ ] Lesson 12 — Threads, `Send`/`Sync`, `Mutex`, rayon
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

## Open questions

- How does `rust-analyzer` in RustRover compare with VS Code for these exercises?
