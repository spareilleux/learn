---
title: 2. Types, mutability and expressions
description: let and mut, numeric types, no implicit conversions, and everything-is-an-expression.
sidebar:
  order: 2
---

Full example: [`examples/l02_types.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l02_types.rs) — run it with `cargo run --example l02_types`.

## Immutable by default

```rust
let answer = 42;            // inferred as i32, cannot change
let mut counter: u32 = 0;   // explicitly mutable
counter += 1;
```

In C# terms, every `let` is like a local you can never reassign; in Java, like [`final var`](https://openjdk.org/jeps/286). You opt **into** mutability with `mut`:

```rust
let count = 0;
count += 1;
```

```text
error[E0384]: cannot assign twice to immutable variable `count`
 --> e_immutable.rs:3:5
  |
2 |     let count = 0;
  |         ----- first assignment to `count`
3 |     count += 1;
  |     ^^^^^^^^^^ cannot assign twice to immutable variable
  |
help: consider making this binding mutable
  |
2 |     let mut count = 0;
  |         +++
```

:::tip[Read the whole error]
Rust errors usually contain the fix (`help: consider making this binding mutable`). Get into the habit of reading them to the end — and [`rustc --explain E0384`](https://doc.rust-lang.org/rustc/command-line-arguments.html#--explain-provide-a-detailed-explanation-of-an-error-message) gives a full explanation.
:::

## Shadowing

You can declare a new variable with the same name, even with a different type. Handy for "parse and replace":

```rust
let input = "  7 ";
let input: i32 = input.trim().parse().expect("not a number");
println!("input + 1 = {}", input + 1); // input + 1 = 8
```

This is not mutation: the first `input` (a [`&str`](https://doc.rust-lang.org/std/primitive.str.html)) still exists, it is just hidden. C# and Java forbid redeclaring a local in the same scope.

## Scalar types

| Rust | C# | Java | Notes |
|---|---|---|---|
| `i8` / `u8` | `sbyte` / `byte` | `byte` (signed) / — | Java has no unsigned integers |
| `i16` / `u16` | `short` / `ushort` | `short` / — | |
| `i32` / `u32` | `int` / `uint` | `int` / — | `i32` is the default integer |
| `i64` / `u64` | `long` / `ulong` | `long` / — | |
| `i128` / `u128` | [`Int128`](https://learn.microsoft.com/dotnet/api/system.int128) / `UInt128` | — | |
| `isize` / `usize` | [`nint` / `nuint`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/integral-numeric-types#native-sized-integers) | — | pointer-sized; used for indexes and lengths |
| `f32` / `f64` | `float` / `double` | `float` / `double` | `f64` is the default float |
| `bool` | `bool` | `boolean` | |
| `char` | [`Rune`](https://learn.microsoft.com/dotnet/api/system.text.rune) | `int` code point | **4 bytes**, a Unicode scalar value — *not* a UTF-16 unit like C#/Java `char` |

```rust
let note = '♪';
println!("{note} is {} bytes in UTF-8, size_of::<char>() = {}", note.len_utf8(), std::mem::size_of::<char>());
// ♪ is 3 bytes in UTF-8, size_of::<char>() = 4
```

## No implicit conversions

C# and Java silently widen an `int` to a `long`. Rust never converts numbers for you:

```rust
let small: i32 = 10;
let big: i64 = 20;
let total = small + big;
```

```text
error[E0308]: mismatched types
 --> e_mismatch.rs:4:25
  |
4 |     let total = small + big;
  |                         ^^^ expected `i32`, found `i64`
```

Convert explicitly with [`as`](https://doc.rust-lang.org/reference/expressions/operator-expr.html#type-cast-expressions) (or [`i64::from(small)`](https://doc.rust-lang.org/std/convert/trait.From.html), which only exists for lossless conversions):

```rust
let total = small as i64 + big; // 30
```

## Overflow is a bug, not a feature

| | C# | Java | Rust debug build | Rust release build |
|---|---|---|---|---|
| `255u8 + 1` | wraps (unless [`checked`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/checked-and-unchecked)) | wraps | **[panics](https://doc.rust-lang.org/book/ch09-01-unrecoverable-errors-with-panic.html)** | wraps |

In a debug build, Rust stops the program:

```text
thread 'main' panicked at e_overflow.rs:3:16:
attempt to add with overflow
```

When wrapping or failure is the intended behaviour, say so explicitly:

```rust
let max = u8::MAX;
println!("checked: {:?}, wrapping: {}", max.checked_add(1), max.wrapping_add(1));
// checked: None, wrapping: 0
```

## Tuples and arrays

```rust
let point: (f64, f64) = (1.5, -2.0);
let (x, y) = point;              // destructuring, like C# tuple deconstruction
let primes = [2, 3, 5, 7, 11];   // fixed-size array: [i32; 5]
println!("x = {x}, y = {y}, first prime = {}, count = {}", primes[0], primes.len());
// x = 1.5, y = -2, first prime = 2, count = 5
```

A growable list is [`Vec<T>`](https://doc.rust-lang.org/std/vec/struct.Vec.html) (like [`List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1) / [`ArrayList<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/ArrayList.html)) — lesson 8 covers collections.

## Everything is an expression

`if` returns a value, so there is no ternary operator:

```rust
let parity = if answer % 2 == 0 { "even" } else { "odd" };
```

A block `{ … }` evaluates to its last expression — **without** a semicolon:

```rust
let area = {
    let width = 3;
    let height = 4;
    width * height   // no `;` → this is the block's value
};
```

Functions work the same way; `return` is only needed for early exits:

```rust
fn square(x: i32) -> i32 {
    x * x
}
```

:::caution[The semicolon matters]
Writing `x * x;` turns the expression into a statement: the function then returns [`()`](https://doc.rust-lang.org/std/primitive.unit.html) (the unit type, Rust's `void`) and the compiler complains about a type mismatch.
:::

## Loops

```rust
// loop + break with a value
let mut n = 1;
let first_power_over_100 = loop {
    n *= 2;
    if n > 100 {
        break n;
    }
};                                   // 128

// for over ranges: 0..3 is end-exclusive, 1..=10 is inclusive
for i in 0..3 {
    print!("{i} ");                  // 0 1 2
}
let sum: i32 = (1..=10).sum();       // 55
```

There is no C-style `for (int i = 0; i < n; i++)`: use a range. `while condition { … }` also exists.

## Key takeaways

- `let` is immutable; add `mut` only when you need it.
- Numeric types are explicit, conversions are explicit, overflow panics in debug.
- `char` is a Unicode scalar value (4 bytes), not UTF-16.
- `if`, blocks, `loop` and functions are expressions; the last expression without `;` is the value.

## Exercises

1. Write a function `clamp_percent(value: i32) -> u8` that returns `0` for negative values, `100` for values above 100, and the value otherwise — using `if` as an expression.

<details>
<summary>Solution</summary>

```rust
fn clamp_percent(value: i32) -> u8 {
    if value < 0 {
        0
    } else if value > 100 {
        100
    } else {
        value as u8
    }
}
```

The `as u8` is safe here because the value is known to be within `0..=100`. Rust also provides `value.clamp(0, 100) as u8`.

</details>

2. Why does this function fail to compile, and what is the one-character fix?

```rust
fn double(x: i32) -> i32 {
    x * 2;
}
```

<details>
<summary>Solution</summary>

The trailing semicolon turns `x * 2` into a statement, so the body evaluates to `()` instead of `i32` (error `E0308: mismatched types`). Remove the `;`.

</details>

3. In C#, `byte b = 255; b++;` gives `0`. What happens in Rust with `let mut b: u8 = 255; b += 1;`?

<details>
<summary>Solution</summary>

In a debug build the program panics with `attempt to add with overflow`. In a release build it wraps to `0`. If wrapping is what you want, write `b = b.wrapping_add(1);`; if you want to detect it, use [`b.checked_add(1)`](https://doc.rust-lang.org/std/primitive.u8.html#method.checked_add), which returns an [`Option<u8>`](https://doc.rust-lang.org/std/option/enum.Option.html).

</details>

## Sources

- [The Book, ch. 3 — Common Programming Concepts](https://doc.rust-lang.org/book/ch03-00-common-programming-concepts.html)
- [The Rust Reference — Integer overflow](https://doc.rust-lang.org/reference/expressions/operator-expr.html#overflow)
- [`char` — standard library](https://doc.rust-lang.org/std/primitive.char.html)
