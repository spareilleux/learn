---
title: 3. Ownership and moves
description: What replaces the garbage collector — owners, moves, Copy, clone and Drop.
sidebar:
  order: 3
---

Full example: [`examples/l03_ownership.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l03_ownership.rs) — `cargo run --example l03_ownership`.

## The problem a GC solves

In C# and Java, objects live on the heap and many variables can point to the same object. Nobody "owns" it: the **garbage collector** frees it at some point after the last reference disappears.

That is convenient, but it costs a runtime, pauses, and memory headroom — and it only manages memory: files, sockets and locks still need [`using`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/using) / [`IDisposable`](https://learn.microsoft.com/dotnet/api/system.idisposable) or [try-with-resources](https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html).

Rust has no GC. Instead, the compiler enforces **ownership** rules and inserts the cleanup code itself, at compile time.

## The three rules

1. Each value has exactly **one owner** (a variable, a field, a collection element…).
2. When the owner goes out of scope, the value is **dropped** (freed).
3. Ownership can be **moved** to another owner; the previous owner can no longer be used.

## Moves

From [`examples/l03_ownership.rs`, lines 21-23](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L21-L23):

```rust
let a = String::from("hello");
let b = a;             // ownership of the heap buffer moves to b
println!("b = {b}");   // b = hello
```

In C#, `var b = a;` copies a *reference*: `a` and `b` now point to the same string, and both remain usable. In Rust, `a` is **gone** ([`src/lib.rs`, lines 61-63](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L61-L63)):

```rust
let a = String::from("hello");
let b = a;
println!("{a} {b}");
```

```text
error[E0382]: borrow of moved value: `a`
 --> e_move.rs:4:16
  |
2 |     let a = String::from("hello");
  |         - move occurs because `a` has type `String`, which does not implement the `Copy` trait
3 |     let b = a;
  |             - value moved here
4 |     println!("{a} {b}");
  |                ^ value borrowed here after move
  |
help: consider cloning the value if the performance cost is acceptable
  |
3 |     let b = a.clone();
  |              ++++++++
```

Why? If both `a` and `b` owned the buffer, both would free it at the end of the scope — a double free. Moving makes "who frees this" unambiguous.

## `clone` — an explicit deep copy

From [`examples/l03_ownership.rs`, lines 26-27](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L26-L27):

```rust
let c = b.clone();
println!("b = {b}, c = {c}");   // b = hello, c = hello
```

[`clone()`](https://doc.rust-lang.org/std/clone/trait.Clone.html) duplicates the heap data. It is always visible in the code, so expensive copies never happen by accident.

## `Copy` types

Small values that live entirely on the stack are **copied** instead of moved ([lines 30-32](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L30-L32)):

```rust
let x = 5;
let y = x;
println!("x = {x}, y = {y}");   // x = 5, y = 5
```

Integers, floats, `bool`, `char`, and tuples/arrays of those are `Copy`. This is close to C# value types ([`struct`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/struct)) — but in Rust *your own* structs are moved by default and only become `Copy` if you opt in with [`#[derive(Clone, Copy)]`](https://doc.rust-lang.org/book/appendix-03-derivable-traits.html).

| | C# | Java | Rust |
|---|---|---|---|
| `b = a` with a heap object | both reference the same object | both reference the same object | **move**: `a` unusable |
| `b = a` with an `int` | copy | copy | copy (`Copy` type) |
| explicit deep copy | [`ICloneable`](https://learn.microsoft.com/dotnet/api/system.icloneable), copy constructor | [`clone()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Object.html#clone()), copy constructor | `.clone()` |

## Functions take ownership too

Passing a [`String`](https://doc.rust-lang.org/std/string/struct.String.html) by value moves it into the function ([`src/lib.rs`, lines 69-75](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L69-L75)):

```rust
fn take(s: String) -> usize {
    s.len()
} // s is dropped here

let name = String::from("Ferris");
let len = take(name);
println!("{name} has {len} letters");
```

```text
error[E0382]: borrow of moved value: `name`
 --> e_move_fn.rs:8:16
  |
6 |     let name = String::from("Ferris");
  |         ---- move occurs because `name` has type `String`, which does not implement the `Copy` trait
7 |     let len = take(name);
  |                    ---- value moved here
8 |     println!("{name} has {len} letters");
  |                ^^^^ value borrowed here after move
  |
note: consider changing this parameter type in function `take` to borrow instead if owning the value isn't necessary
```

The compiler already points at the real fix: *borrow* instead of taking ownership. That is the topic of [lesson 4](../04-borrowing-and-strings/).

Returning a value moves ownership back out to the caller ([lines 15-17](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L15-L17), [38](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L38)):

```rust
fn make_greeting(name: &str) -> String {
    format!("Hello, {name}!")
}

let greeting = make_greeting("Ferris");   // greeting owns the new String
```

## `Drop` — deterministic cleanup

When an owner goes out of scope, Rust calls `drop`, in **reverse** order of declaration. You can hook into it by implementing the `Drop` trait ([lines 1-9](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L1-L9), [19](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L19), [42-55](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L42-L55)):

```rust
struct TempFile {
    name: String,
}

impl Drop for TempFile {
    fn drop(&mut self) {
        println!("dropping {}", self.name);
    }
}

fn main() {
    let _first = TempFile { name: "first.tmp".into() };
    {
        let _inner = TempFile { name: "inner.tmp".into() };
        println!("leaving inner scope");
    }
    let _second = TempFile { name: "second.tmp".into() };
    println!("end of main");
}
```

```text
leaving inner scope
dropping inner.tmp
end of main
dropping second.tmp
dropping first.tmp
```

| | C# | Java | Rust |
|---|---|---|---|
| Memory | GC, non-deterministic | GC, non-deterministic | freed at end of owner's scope |
| Files, sockets, locks | `using` + `IDisposable` | try-with-resources + [`AutoCloseable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/AutoCloseable.html) | the same `Drop`, automatically |
| Forgetting to clean up | leak until [finalizer](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/finalizers) (maybe) | leak until finalizer (maybe) | cleanup runs automatically; a leak needs an explicit [`std::mem::forget`](https://doc.rust-lang.org/std/mem/fn.forget.html) or a reference cycle (lesson 11) |

This pattern — acquire in a constructor, release in `Drop` — is how [`File`](https://doc.rust-lang.org/std/fs/struct.File.html), [`MutexGuard`](https://doc.rust-lang.org/std/sync/struct.MutexGuard.html) and network connections work in Rust. There is no `using` keyword because every scope already behaves like one.

## Key takeaways

- One owner per value; the value is freed when the owner goes out of scope.
- Assigning or passing a non-`Copy` value **moves** it; the old variable is unusable.
- `.clone()` is the explicit, visible deep copy.
- `Drop` gives deterministic cleanup for memory *and* resources, like an automatic `using`.

## Exercises

1. Which lines compile? Explain each.

```rust
let a = 10;
let b = a;
println!("{a}");        // (1)

let s = String::from("x");
let t = s;
println!("{s}");        // (2)

let u = String::from("y");
let v = u.clone();
println!("{u} {v}");    // (3)
```

<details>
<summary>Solution</summary>

1. Compiles: `i32` is `Copy`, so `b` gets a copy and `a` stays usable.
2. Does not compile (`E0382`): `String` is not `Copy`, so `s` was moved into `t`.
3. Compiles: `clone()` creates an independent `String`, so both remain valid.

</details>

2. Rewrite this Java method so the Rust version does not need `clone()`:

```java
static int countVowels(String text) { /* … */ }
// called as: countVowels(name); System.out.println(name);
```

<details>
<summary>Solution</summary>

Take a borrowed string slice instead of an owned `String`, so the caller keeps ownership (explained in lesson 4) ([`src/lib.rs`, lines 99-104](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L99-L104)):

```rust
fn count_vowels(text: &str) -> usize {
    text.chars().filter(|c| "aeiouAEIOU".contains(*c)).count()
}

let name = String::from("Ferris");
let n = count_vowels(&name);
println!("{name}: {n} vowels");
```

</details>

3. In what order are `a`, `b` and `c` dropped?

```rust
let a = TempFile { name: "a".into() };
let b = TempFile { name: "b".into() };
let c = TempFile { name: "c".into() };
drop(b);
println!("done");
```

<details>
<summary>Solution</summary>

`b` first (explicitly, via [`std::mem::drop`](https://doc.rust-lang.org/std/mem/fn.drop.html), before `done` is printed), then at the end of the scope `c`, then `a` — reverse declaration order for the values still owned.

</details>

## Sources

- [The Book, ch. 4.1 — What Is Ownership?](https://doc.rust-lang.org/book/ch04-01-what-is-ownership.html)
- [`Drop` — standard library](https://doc.rust-lang.org/std/ops/trait.Drop.html)
- [`Copy` — standard library](https://doc.rust-lang.org/std/marker/trait.Copy.html)
