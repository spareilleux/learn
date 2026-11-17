---
title: Advanced Rust — Mission
description: Rust under the hood — representation, allocation, unsafe contracts, code generation, async runtimes, concurrency, profiling and production services — with every shipped claim checked by a program or compile-fail test.
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
The evidence lives in [`code/rust-advanced`](https://github.com/spareilleux/learn/tree/main/code/rust-advanced). `check.sh` runs formatting, Clippy with warnings denied, unit tests, compile-fail doctests and the lesson programs, then compares their output with committed files. The dedicated CI workflow repeats the gate on Linux, Windows and macOS. Results not yet observed on those three runners stay in the journal's **To verify** section.
:::

## Why I am learning this

The introductory [Rust for C#/Java developers](../rust-for-csharp-java/) course teaches how to write correct Rust. This course starts where it stops: what representation the compiler may choose, what an abstraction costs, which invariant makes an `unsafe` block sound, how a `Future` becomes runnable work, and how to measure before changing code.

The goal is not a list of clever optimisations. It is to replace folklore with inspectable evidence: sizes and offsets printed by a program, rejected contracts kept as compile-fail tests, generated code inspected deliberately, and performance claims tied to a reproducible benchmark.

## Who this course is for

You already use ownership, borrowing, lifetimes, traits, iterators, `Result`, threads and basic async Rust. If those are new, complete [Rust for C#/Java developers](../rust-for-csharp-java/) first. Comparisons with C# and Java explain the runtime choices, but the exercises assume working Rust.

## By the end of this course, I will be able to

- distinguish Rust's default representation from `repr(C)` and `repr(transparent)`, and measure size, alignment, padding and niche optimisation;
- reason about allocation, drop order, provenance and the safety contract around a small `unsafe` core;
- predict monomorphisation and dynamic-dispatch trade-offs, then inspect rather than guess;
- explain `Pin`, `Future`, waking and executor scheduling;
- design bounded Tokio pipelines with explicit cancellation, backpressure and terminal states;
- use atomics and memory orderings without treating `SeqCst` as a substitute for a proof;
- profile CPU time, allocations and binary size before optimising;
- recognise when procedural macros, FFI, Axum, Tower and Hyper are appropriate boundaries.

## Outline

### Part 1 — Representation and code generation

| # | Lesson | Evidence |
|---|---|---|
| 1 | [Memory layout and representation](01-memory-layout-and-representation/) | `size_of`, `align_of`, `offset_of`, a compile-fail `repr(transparent)` contract |
| 2 | Allocation, ownership costs and `Drop` | allocator observations and deterministic drop traces — planned |
| 3 | Unsafe contracts, pointers, provenance and `Pin` | safe wrapper plus Miri checks — planned |
| 4 | Traits, monomorphisation and dynamic dispatch | generated code and binary-size comparison — planned |
| 5 | Profiling and measured optimisation | Criterion, flamegraphs and allocation evidence — planned |

### Part 2 — Concurrency and async runtimes

| # | Lesson | Evidence |
|---|---|---|
| 6 | Atomics and the memory model | litmus tests with stated limits — planned |
| 7 | `Future`, wakers and executors | a minimal executor before Tokio — planned |
| 8 | Tokio scheduling, channels and backpressure | bounded pipeline, cancellation and terminal-state tests — planned |

### Part 3 — Advanced boundaries

| # | Lesson | Evidence |
|---|---|---|
| 9 | Procedural macros | expansion and compile-time diagnostics — planned |
| 10 | FFI and ABI design | Rust/C boundary exercised from another language — planned |
| 11 | Axum, Tower and Hyper | one request through layers, cancellation and graceful shutdown — planned |
| 12 | Observability, cross-compilation and binary size | traces, metrics and reproducible release artifacts — planned |
| — | [Journal](journal/) | measured progress, experiments and open questions |

## Prerequisites

- Rust 1.94.0 with the 2024 edition and Cargo;
- the concepts covered by [Rust for C#/Java developers](../rust-for-csharp-java/);
- Git and a shell. The course gate runs from Git Bash on Windows.

## Primary resources

- [The Rust Reference — type layout](https://doc.rust-lang.org/reference/type-layout.html)
- [The Rustonomicon](https://doc.rust-lang.org/nomicon/)
- [The Async Book](https://rust-lang.github.io/async-book/)
- [The Rust Performance Book](https://nnethercote.github.io/perf-book/)
- [Tokio documentation](https://tokio.rs/tokio/tutorial)
