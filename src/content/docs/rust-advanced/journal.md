---
title: Journal
description: Dated progress, experiments and open questions for the Advanced Rust course.
sidebar:
  order: 99
---

## Progress

- [x] Mission and twelve-lesson outline
- [x] Course crate with formatting, Clippy, unit tests, compile-fail doctests and captured output
- [x] Lesson 1: memory layout and representation
- [ ] Lesson 2: allocation, ownership costs and `Drop`
- [ ] Lessons 3–12

## Experiments

| Question | Hypothesis written before measurement | Result | Verdict | Evidence |
|---|---|---|---|---|
| Does ordering the most-aligned field first shrink this `repr(C)` packet? | `u8, u32, bool` needs more padding than `u32, u8, bool` on the course's 64-bit targets | 12 bytes became 8 on the author's Windows x86-64 machine; offsets changed from `0,4,8` to `0,4,5` | Confirmed locally; CI targets pending | [Entry](#2026-09-27--the-first-measured-slice), [`code/rust-advanced`](https://github.com/spareilleux/learn/tree/main/code/rust-advanced) |
| Can `Option` reuse an invalid value of `NonZeroUsize`? | `Option<NonZeroUsize>` should remain one word, while `Option<usize>` needs another word | 8 bytes against 16 on the same target | Confirmed locally; guaranteed case documented by the standard library | [Entry](#2026-09-27--the-first-measured-slice), [lesson](../01-memory-layout-and-representation/) |

## 2026-09-27 — The first measured slice

The course began as a tracer-bullet rather than twelve empty lessons: one mission, one complete lesson and one crate that checks every number quoted by the lesson. Rust 1.94.0 produced:

```text
target_pointer_width=64
Packet size=12 align=4 offsets=0,4,8
CompactPacket size=8 align=4 offsets=0,4,5
Option<usize> size=16
Option<NonZeroUsize> size=8
```

`bash check.sh` passed formatting, Clippy with warnings denied, one unit test, one compile-fail doctest and the captured-output comparison. A separate nightly doctest run also verified the exact E0690 code. This is local Windows evidence. The workflow has three runners, but their result does not exist until CI runs.

The lesson keeps `repr(Rust)` out of the offset comparison because its field order is not an ABI promise. Both measured packets use `repr(C)`, making the representation choice part of the question rather than an accidental compiler detail.

## To verify

- Confirm `check.sh` on the hosted Linux, Windows and macOS runners before calling the slice cross-platform.
- Decide whether lesson 2 should measure the system allocator directly or use allocation counts through a deliberately scoped test allocator.
- Select a real IX or hari type only after the standalone method is stable; do not turn a course experiment into an unsolicited optimisation.

## Open questions

- Which layout claims are useful to application developers without encouraging premature ABI commitments?
- Can Miri examples remain deterministic enough for lesson 3 while clearly separating undefined behaviour detection from proof of soundness?
