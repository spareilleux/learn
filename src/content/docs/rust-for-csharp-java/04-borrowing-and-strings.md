---
title: 4. Borrowing and strings
description: Shared and mutable references, the borrow rules, slices, and String vs &str.
sidebar:
  order: 4
---

Full example: [`examples/l04_borrowing.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l04_borrowing.rs) — `cargo run --example l04_borrowing`.

## Borrowing instead of moving

[Lesson 3](../03-ownership-and-moves/) ended with a function that "stole" its argument. Most of the time you only want to *look at* a value: pass a **reference** with `&`.

From [`examples/l04_borrowing.rs`, lines 1-3](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L1-L3), [16-19](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L16-L19):

```rust
fn word_count(text: &str) -> usize {
    text.split_whitespace().count()
}

let title = String::from("the rust programming language");
println!("{} words", word_count(&title));   // 4 words
println!("{title}");                        // title is still usable
```

A reference **borrows** the value: the owner keeps ownership, and the borrow must end before the owner goes away.

## Two kinds of references

| | Syntax | How many at once | Can modify |
|---|---|---|---|
| Shared reference | `&T` | any number | no |
| Mutable reference | `&mut T` | exactly one, and no shared ones | yes |

From [`examples/l04_borrowing.rs`, lines 5-8](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L5-L8), [22-24](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L22-L24):

```rust
fn shout(text: &mut String) {
    text.make_ascii_uppercase();
    text.push('!');
}

let mut message = String::from("hello");
shout(&mut message);
println!("{message}");   // HELLO!
```

The caller writes `&mut` at the call site — like C#'s [`ref` keyword](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/ref), the mutation is visible where it happens. Java has no equivalent: any method holding a reference can mutate the object.

## The rule: shared XOR mutable

At any point, you can have **either** many readers **or** one writer — never both. The compiler checks this; it is called the **borrow checker**.

From [`src/lib.rs`, lines 134-137](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L134-L137):

```rust
let mut names = vec![String::from("Ada")];
let first = &names[0];
names.push(String::from("Grace"));
println!("{first}");
```

```text
error[E0502]: cannot borrow `names` as mutable because it is also borrowed as immutable
 --> e_borrow_mut.rs:4:5
  |
3 |     let first = &names[0];
  |                  ----- immutable borrow occurs here
4 |     names.push(String::from("Grace"));
  |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ mutable borrow occurs here
5 |     println!("{first}");
  |                ----- immutable borrow later used here
```

This is not pedantry. [`push`](https://doc.rust-lang.org/std/vec/struct.Vec.html#method.push) may reallocate the vector's buffer, which would leave `first` pointing into freed memory. In C#/Java the GC keeps the old object alive, so this particular bug does not crash — but the *same rule* catches a bug you know well.

## You have met this bug before

```java
// Java
for (Integer n : numbers) {
    numbers.add(n * 2);   // ConcurrentModificationException at runtime
}
```

```csharp
// C#
foreach (var n in numbers) {
    numbers.Add(n * 2);   // InvalidOperationException: Collection was modified
}
```

In Rust, it does not get past the compiler ([`src/lib.rs`, lines 143-146](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L143-L146)):

```rust
let mut numbers = vec![1, 2, 3];
for n in &numbers {
    numbers.push(n * 2);
}
```

```text
error[E0502]: cannot borrow `numbers` as mutable because it is also borrowed as immutable
 --> e_iter_mutate.rs:4:9
  |
3 |     for n in &numbers {
  |              --------
  |              |
  |              immutable borrow occurs here
  |              immutable borrow later used here
4 |         numbers.push(n * 2);
  |         ^^^^^^^^^^^^^^^^^^^ mutable borrow occurs here
```

The fix is the same as in C#/Java — finish reading, then write ([lines 46-49](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L46-L49)):

```rust
let mut numbers = vec![1, 2, 3];
let doubled: Vec<i32> = numbers.iter().map(|n| n * 2).collect();
numbers.extend(doubled);
println!("{numbers:?}");   // [1, 2, 3, 2, 4, 6]
```

## No dangling references

A reference can never outlive what it points to ([`src/lib.rs`, lines 152-155](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L152-L155)):

```rust
fn longest_line() -> &str {
    let text = String::from("line one\nline two");
    text.lines().next().unwrap()
}
```

```text
error[E0106]: missing lifetime specifier
 --> e_dangling.rs:1:22
  |
1 | fn longest_line() -> &str {
  |                      ^ expected named lifetime parameter
  |
  = help: this function's return type contains a borrowed value, but there is no value for it to be borrowed from
…
help: instead, you are more likely to want to return an owned value
  |
1 - fn longest_line() -> &str {
1 + fn longest_line() -> String {
```

`text` is dropped when the function returns, so a reference into it would dangle. Return an owned [`String`](https://doc.rust-lang.org/std/string/struct.String.html) instead. (Lifetimes — the `'a` syntax the error mentions — get their own lesson, 9.)

## Slices

A **slice** borrows a contiguous part of a collection without copying it ([lines 31-34](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L31-L34)):

```rust
let mut scores = vec![90, 72, 85];
scores.push(60);
let top_two = &scores[..2];      // &[i32]
println!("top two: {top_two:?}");  // top two: [90, 72]
```

Think [`Span<T>`](https://learn.microsoft.com/dotnet/api/system.span-1) / [`ReadOnlySpan<T>`](https://learn.microsoft.com/dotnet/api/system.readonlyspan-1) in C#, or [`List.subList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html#subList(int,int)) in Java — but checked at compile time so it can never outlive the vector.

## `String` vs `&str`

This is the most common stumbling block, and slices explain it:

| | `String` | `&str` |
|---|---|---|
| What it is | an owned, growable UTF-8 buffer | a borrowed slice of UTF-8 text |
| Where the bytes live | heap, owned by this value | anywhere: a `String`, the binary (literals), … |
| Can grow | yes (`push_str`, `push`) | no |
| C# analogy | [`StringBuilder`](https://learn.microsoft.com/dotnet/api/system.text.stringbuilder) that you own | `ReadOnlySpan<char>` / a [`string`](https://learn.microsoft.com/dotnet/api/system.string) you don't own |
| Typical use | struct fields, return values | function parameters |

- String literals like `"hello"` are [`&str`](https://doc.rust-lang.org/std/primitive.str.html) (`&'static str`: they live in the binary).
- `&String` converts to `&str` automatically, so **parameters should usually be `&str`** — they then accept both ([lines 10-12](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L10-L12), [27-28](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L27-L28)):

```rust
fn first_word(text: &str) -> &str {
    text.split_whitespace().next().unwrap_or("")
}

println!("{}", word_count("a literal works too"));   // 4
println!("first word: {}", first_word(&title));      // first word: the
```

## Strings are UTF-8, not arrays of chars

In C# and Java, `s[0]` / [`s.charAt(0)`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html#charAt(int)) returns a UTF-16 unit. Rust refuses to index a string by position ([`src/lib.rs`, lines 161-162](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L161-L162)):

```rust
let word = String::from("cafe");
let c = word[0];
```

```text
error[E0277]: the type `str` cannot be indexed by `{integer}`
 --> e_index_str.rs:3:18
  |
3 |     let c = word[0];
  |                  ^ string indices are ranges of `usize`
  |
  = help: the trait `SliceIndex<str>` is not implemented for `{integer}`
  = note: you can use `.chars().nth()` or `.bytes().nth()`
```

Because characters take 1 to 4 bytes in UTF-8, "the n-th character" is an O(n) walk, and Rust makes that explicit ([lines 37-43](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L37-L43)):

```rust
let word = "café";
println!("{} bytes, {} chars, first 3 bytes: {}", word.len(), word.chars().count(), &word[..3]);
// 5 bytes, 4 chars, first 3 bytes: caf
```

Slicing by byte range works, but it panics if you cut through a character:

```text
thread 'main' panicked at e_slice_boundary.rs:3:25:
byte index 4 is not a char boundary; it is inside 'é' (bytes 3..5) of `café`
```

## Building strings

From [`examples/l04_borrowing.rs`, lines 52-56](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L52-L56):

```rust
let mut log = String::new();
for (i, s) in ["alpha", "beta"].iter().enumerate() {
    log.push_str(&format!("{i}:{s} "));
}
println!("{}", log.trim_end());   // 0:alpha 1:beta
```

[`format!`](https://doc.rust-lang.org/std/macro.format.html) works like [`string.Format`](https://learn.microsoft.com/dotnet/api/system.string.format) / [`String.format`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html#format(java.lang.String,java.lang.Object...)) (and like C# [interpolation](https://learn.microsoft.com/dotnet/csharp/language-reference/tokens/interpolated) with `{name}` inside the literal).

## Key takeaways

- `&T` borrows for reading, `&mut T` borrows for writing; the owner keeps ownership.
- Many shared borrows **or** one mutable borrow — the rule that also catches "collection modified during iteration" at compile time.
- References can never dangle; return owned values when the data is created inside a function.
- Take `&str` in parameters, store `String` in structs; strings are UTF-8, so iterate with [`.chars()`](https://doc.rust-lang.org/std/primitive.str.html#method.chars) instead of indexing.

## Exercises

1. Fix the signature so this compiles without cloning, and explain why your version is more flexible:

```rust
fn is_shouting(text: String) -> bool {
    text.chars().any(|c| c.is_alphabetic()) && text == text.to_uppercase()
}

let msg = String::from("HELLO");
if is_shouting(msg) { println!("{msg} is shouting"); }
```

<details>
<summary>Solution</summary>

From [`src/lib.rs`, lines 168-174](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L168-L174):

```rust
fn is_shouting(text: &str) -> bool {
    text.chars().any(|c| c.is_alphabetic()) && text == text.to_uppercase()
}

let msg = String::from("HELLO");
if is_shouting(&msg) { println!("{msg} is shouting"); }
```

Borrowing leaves `msg` owned by the caller, and `&str` also accepts literals (`is_shouting("hi")`) and slices.

</details>

2. This compiles in C# and runs fine. Why does Rust reject the equivalent, and how do you fix it?

```csharp
var names = new List<string> { "Ada" };
var first = names[0];
names.Add("Grace");
Console.WriteLine(first);
```

<details>
<summary>Solution</summary>

In C#, `first` holds a reference to the string object, which the GC keeps alive even if the list reallocates. In Rust, `&names[0]` points *into* the vector's buffer, which `push` may reallocate, so the borrow checker forbids the mutation while the borrow is alive (`E0502`). Fixes: use `first` before pushing, or take an owned copy with `let first = names[0].clone();`.

</details>

3. Write `fn initials(full_name: &str) -> String` that returns `"A.L."` for `"Ada Lovelace"`, correctly handling names that start with non-ASCII letters like `"Émile Zola"`.

<details>
<summary>Solution</summary>

From [`src/lib.rs`, lines 189-197](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L189-L197):

```rust
fn initials(full_name: &str) -> String {
    full_name
        .split_whitespace()
        .filter_map(|word| word.chars().next())
        .map(|c| format!("{c}."))
        .collect()
}

assert_eq!(initials("Ada Lovelace"), "A.L.");
assert_eq!(initials("Émile Zola"), "É.Z.");
```

`chars().next()` takes the first *character*, not the first byte, so `É` (2 bytes in UTF-8) is handled correctly.

</details>

## Sources

- [The Book, ch. 4.2 — References and Borrowing](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html)
- [The Book, ch. 4.3 — The Slice Type](https://doc.rust-lang.org/book/ch04-03-slices.html)
- [The Book, ch. 8.2 — Storing UTF-8 Encoded Text with Strings](https://doc.rust-lang.org/book/ch08-02-strings.html)
