---
title: 1. Memory layout and representation
sidebar:
  order: 1
description: Measure size, alignment, padding, field offsets and a niche optimisation; learn what repr(Rust), repr(C) and repr(transparent) do and do not promise.
---

Source: [`examples/l01_layout.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-advanced/examples/l01_layout.rs). Run it with:

```bash
cd code/rust-advanced
bash check.sh
```

## The question before the measurement

Two packets contain exactly the same fields. Does placing the field with the strictest alignment first reduce their size?

**Hypothesis written before running the program:** on the 64-bit targets used by this course, the order `u8, u32, bool` needs internal and trailing padding, while `u32, u8, bool` needs less. The second packet should be smaller without storing less information.

Rust's [`size_of`](https://doc.rust-lang.org/std/mem/fn.size_of.html), [`align_of`](https://doc.rust-lang.org/std/mem/fn.align_of.html) and [`offset_of`](https://doc.rust-lang.org/std/mem/macro.offset_of.html) let the program ask the target instead of guessing.

## Size, alignment and padding

A type's **alignment** is the set of addresses at which a value of that type may start. If `u32` has alignment 4, its address must be a multiple of four. A struct may therefore contain:

- **internal padding** before a field;
- **trailing padding** after its last field, so consecutive values in an array are aligned;
- useful bytes that belong to fields.

The [Rust Reference's type-layout chapter](https://doc.rust-lang.org/reference/type-layout.html) is the contract. These numbers are target properties, not universal constants.

## A representation is a promise

The default `repr(Rust)` representation guarantees that fields are properly aligned, do not overlap and that the type's alignment is at least the maximum field alignment. It does **not** promise declaration order or stable offsets. Do not publish offsets from a default Rust struct as an ABI.

For this experiment, both structs use [`repr(C)`](https://doc.rust-lang.org/reference/type-layout.html#the-c-representation), which gives the target C ABI's field order and padding rules:

```rust
#[repr(C)]
pub struct Packet {
    pub tag: u8,
    pub count: u32,
    pub ready: bool,
}

#[repr(C)]
pub struct CompactPacket {
    pub count: u32,
    pub tag: u8,
    pub ready: bool,
}
```

The captured output on the author's 64-bit Windows machine is:

```text
target_pointer_width=64
Packet size=12 align=4 offsets=0,4,8
CompactPacket size=8 align=4 offsets=0,4,5
Option<usize> size=16
Option<NonZeroUsize> size=8
```

The hypothesis is confirmed locally:

- `Packet`: byte 0 is `tag`; bytes 1–3 are padding; bytes 4–7 are `count`; byte 8 is `ready`; bytes 9–11 are trailing padding;
- `CompactPacket`: bytes 0–3 are `count`; bytes 4 and 5 hold the two one-byte fields; bytes 6–7 are trailing padding.

Reordering saved four bytes here. That does **not** mean “always sort fields by size”: readability, ABI compatibility, cache access patterns and zero-sized fields can matter more. Measure the actual type on the targets you support.

## A value the type says cannot exist

[`NonZeroUsize`](https://doc.rust-lang.org/std/num/type.NonZeroUsize.html) excludes zero. `Option<NonZeroUsize>` can therefore encode `None` as zero and every non-zero bit pattern as `Some`. This unused representation is a **niche**.

`usize` has no invalid bit pattern, so `Option<usize>` needs an extra discriminant. On this target the program measured 16 bytes against 8. The standard library explicitly guarantees the null-pointer optimisation for the listed non-zero integer types; do not infer the same guarantee for every enum that happens to be small today.

## `repr(transparent)` is narrower than “same size”

A [`repr(transparent)`](https://doc.rust-lang.org/reference/type-layout.html#the-transparent-representation) wrapper has the layout and ABI of its single non-zero-sized field. That is useful for strongly typed IDs crossing an FFI boundary:

```rust
#[repr(transparent)]
struct UserId(u64);
```

A second non-zero-sized field breaks the contract. The course keeps the rejection as a doctest:

```rust
#[repr(transparent)]
struct InvalidTransparent(u32, u32);
```

Stable `cargo test --doc` verifies that the snippet fails. `cargo +nightly test --doc` additionally verifies the exact compiler error code E0690 instead of trusting copied output.

## Mapping from C# and Java

| Question | Rust | C# | Java |
|---|---|---|---|
| Inline value layout | `struct`, representation attribute | value type plus [`StructLayout`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.structlayoutattribute) | ordinary objects have VM-managed layout; the [Foreign Function & Memory API](https://docs.oracle.com/en/java/javase/25/core/foreign-function-and-memory-api.html) models explicit native layouts |
| Stable C ABI | `repr(C)` | `LayoutKind.Sequential`/`Explicit` | `MemoryLayout` |
| One-field ABI wrapper | `repr(transparent)` | no exact general equivalent | no exact general equivalent |
| Ask the running target | `size_of`, `align_of`, `offset_of` | `Unsafe.SizeOf`, `Marshal.OffsetOf` with different object/value semantics | layout APIs for foreign memory, not arbitrary object internals |

A Rust `struct` is not automatically the equivalent of a C# class or a Java object: it has no object header merely because it is a struct, and where it lives depends on its owner.

## Exercises

### 1. Predict before running

Add a `u16` field to both packets. Write the expected offsets and total sizes before compiling, then use `offset_of!` to test the prediction.

<details>
<summary>Solution</summary>

With `repr(C)`, calculate each field from the current offset rounded up to that field's alignment, then round the final size up to the struct alignment. The best order depends on where the `u16` is placed; let the failed prediction remain in your notes if you were wrong.

</details>

### 2. Encode absence without another word

Define a `Handle` newtype around `NonZeroUsize`. Compare `size_of::<Handle>()` and `size_of::<Option<Handle>>()`.

<details>
<summary>Solution</summary>

```rust
use std::num::NonZeroUsize;

#[repr(transparent)]
struct Handle(NonZeroUsize);

assert_eq!(std::mem::size_of::<Handle>(), std::mem::size_of::<Option<Handle>>());
```

The transparent wrapper preserves the inner type's valid-range contract, so the option can retain its niche.

</details>

### 3. Choose the representation deliberately

For each case, choose `repr(Rust)`, `repr(C)` or `repr(transparent)`: an internal parser state, a packet sent to a C library, and a strongly typed `u64` ID passed through that library.

<details>
<summary>Solution</summary>

- internal parser state: default `repr(Rust)` unless another requirement is measured;
- C packet: `repr(C)`, with field types that also have a defined boundary representation;
- one-field ID: `repr(transparent)` around `u64`.

The attribute is necessary but not sufficient: ownership, validity, endianness and lifetime are separate boundary contracts.

</details>

## What this proves — and what it does not

The program proves the printed layout on the target that ran it, and CI will test the three hosted 64-bit targets. It does not prove a stable ABI for `repr(Rust)`, that a smaller struct makes a whole program faster, or that the same result holds on a 32-bit or unusual target.

Next: allocation, ownership costs and deterministic `Drop` traces.
