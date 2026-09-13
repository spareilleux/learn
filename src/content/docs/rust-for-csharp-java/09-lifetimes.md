---
title: 9. Lifetimes
description: How the compiler proves a reference never outlives its value — annotations, elision, structs that borrow and 'static.
sidebar:
  order: 9
---

Full example: [`examples/l09_lifetimes.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l09_lifetimes.rs) — `cargo run --example l09_lifetimes`.

## The problem a garbage collector hides

In C# or Java, a reference keeps its object alive: as long as you can reach it, the [garbage collector](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals) will not free it. A ["dangling reference"](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html#dangling-references) simply cannot happen.

Rust has no garbage collector. A value is freed when its owner goes out of scope ([lesson 3](../03-ownership-and-moves/)), so the compiler must prove that no reference is still in use at that point:

```rust
let r;
{
    let s = String::from("hello");
    r = &s;
}
println!("{r}");
```

```text
error[E0597]: `s` does not live long enough
 --> e09_dangling.rs:5:13
  |
4 |         let s = String::from("hello");
  |             - binding `s` declared here
5 |         r = &s;
  |             ^^ borrowed value does not live long enough
6 |     }
  |     - `s` dropped here while still borrowed
7 |     println!("{r}");
  |                - borrow later used here
```

The span during which a reference is valid is its **lifetime**. Inside a single function the compiler works lifetimes out on its own — you have been relying on that since lesson 4. You only write them when a reference crosses a **function or struct boundary** and the compiler cannot guess the relationship.

:::note[Lifetimes do not change how long anything lives]
A lifetime annotation is a *description* the compiler checks, not an instruction. Writing `'a` never keeps a value alive longer, unlike holding a reference in C#.
:::

## Annotating a function

Which input does the result borrow from?

```rust
fn longest(a: &str, b: &str) -> &str {
    if a.len() >= b.len() { a } else { b }
}
```

```text
error[E0106]: missing lifetime specifier
 --> e09_longest.rs:1:33
  |
1 | fn longest(a: &str, b: &str) -> &str {
  |               ----     ----     ^ expected named lifetime parameter
  |
  = help: this function's return type contains a borrowed value, but the signature does not say whether it is borrowed from `a` or `b`
help: consider introducing a named lifetime parameter
  |
1 | fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
  |           ++++     ++          ++          ++
```

The compiler checks each function on its **signature alone**, never on its body — the same way a C# caller only sees a method's declaration. So the signature has to say it:

```rust
fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}
```

Read `<'a>` like a [generic parameter](https://doc.rust-lang.org/reference/items/generics.html) (it is declared in the same place as `<T>`): *"for some lifetime `'a` during which both `a` and `b` are valid, the result is valid for `'a` too"*. In practice `'a` becomes the **shorter** of the two, so the caller cannot keep the result longer than either input:

```rust
let title = String::from("Rust for C# developers");
let winner;
{
    let subtitle = String::from("ownership");
    winner = longest(&title, &subtitle);
}
println!("{winner}");
```

```text
error[E0597]: `subtitle` does not live long enough
  --> e09_longest_scope.rs:10:34
   |
 9 |         let subtitle = String::from("ownership");
   |             -------- binding `subtitle` declared here
10 |         winner = longest(&title, &subtitle);
   |                                  ^^^^^^^^^ borrowed value does not live long enough
11 |     }
   |     - `subtitle` dropped here while still borrowed
12 |     println!("{winner}");
   |                ------ borrow later used here
```

At runtime `title` is the longest string, so this would happen to work — but the signature promises nothing about which one is returned, and the compiler holds you to the signature.

Only annotate what the result actually borrows. Here the result comes from `a` alone, so `len_from` needs no lifetime and can be anything short-lived:

```rust
fn prefix_of<'a>(a: &'a str, len_from: &str) -> &'a str {
    &a[..len_from.len().min(a.len())]
}
```

## Elision: when you can leave them out

Most functions never mention a lifetime because three **elision rules** fill them in:

1. Each reference parameter gets its own lifetime.
2. If there is exactly **one** input lifetime, it is used for every output reference.
3. If one of the parameters is `&self` or `&mut self`, **its** lifetime is used for the outputs.

```rust
fn first_word(text: &str) -> &str {     // rule 2: the result borrows `text`
    text.split_whitespace().next().unwrap_or("")
}
```

`longest` needed an annotation because it has two inputs and no `self`: no rule applies.

Elision never makes a wrong program compile. When the rules produce a lifetime that does not fit, you still get an error — and returning a reference to a local variable is always an error, whatever you annotate:

```rust
fn shout(word: &str) -> &str {
    let upper = word.to_uppercase();
    &upper
}
```

```text
error[E0515]: cannot return reference to local variable `upper`
 --> e09_local.rs:3:5
  |
3 |     &upper
  |     ^^^^^^ returns a reference to data owned by the current function
```

The fix is the one from lesson 4: return the owned [`String`](https://doc.rust-lang.org/std/string/struct.String.html).

## Structs that borrow

A struct that holds a reference must declare the lifetime, just like a generic type parameter:

```rust
struct Excerpt {
    text: &str,
}
```

```text
error[E0106]: missing lifetime specifier
 --> e09_struct.rs:2:11
  |
2 |     text: &str,
  |           ^ expected named lifetime parameter
  |
help: consider introducing a named lifetime parameter
  |
1 ~ struct Excerpt<'a> {
2 ~     text: &'a str,
  |
```

```rust
struct Excerpt<'a> {
    text: &'a str,
}

impl Excerpt<'_> {                 // '_ : "some lifetime, I don't need its name"
    fn word_count(&self) -> usize {
        self.text.split_whitespace().count()
    }
}

let novel = String::from("Call me Ishmael. Some years ago, never mind how long precisely...");
let excerpt = Excerpt { text: novel.split('.').next().unwrap_or("") };
// excerpt: "Call me Ishmael" (3 words)
```

`Excerpt<'a>` reads as *"an excerpt that cannot outlive the text it points into"*. The compiler enforces it:

```text
error[E0597]: `novel` does not live long enough
  --> e09_struct_outlive.rs:9:35
   |
 8 |         let novel = String::from("Call me Ishmael. Some years ago...");
   |             ----- binding `novel` declared here
 9 |         excerpt = Excerpt { text: novel.split('.').next().unwrap() };
   |                                   ^^^^^ borrowed value does not live long enough
10 |     }
   |     - `novel` dropped here while still borrowed
11 |     println!("{}", excerpt.text);
   |                    ------------ borrow later used here
```

The C# closest equivalent is a [`ref struct`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct) such as [`Span<T>`](https://learn.microsoft.com/dotnet/api/system.span-1): it may point into someone else's memory, so the compiler restricts where it can go. In Rust, any struct can be like that.

### The lifetime in a method signature matters

A tokenizer that returns slices of its input:

```rust
struct Parser<'a> {
    input: &'a str,
    pos: usize,
}

impl<'a> Parser<'a> {
    fn next_token(&mut self) -> Option<&'a str> {
        // … returns &self.input[start..end]
    }
}

fn tokenize(line: &str) -> Vec<&str> {
    let mut parser = Parser::new(line);
    let mut tokens = Vec::new();
    while let Some(token) = parser.next_token() {
        tokens.push(token);
    }
    tokens                          // the parser is dropped, the tokens survive
}
// tokens: ["let", "x", "=", "42"]
```

The return type says `&'a str`: a token borrows the **input text**, not the parser. Had it been written `Option<&str>`, elision rule 3 would tie each token to `&mut self` — and you could not hold two tokens at once (exercise 3).

## `'static`

`'static` is the lifetime of data that is valid for the whole run of the program. String literals are stored in the binary, so they have it:

```rust
fn default_greeting() -> &'static str {
    "hello"
}
```

You will mostly meet `'static` as a **bound**, for example on `std::thread::spawn`: a new thread may outlive the function that started it, so it cannot borrow that function's locals.

```rust
let name = String::from("worker");
let label: &str = &name;
let handle = std::thread::spawn(move || println!("{label}"));
handle.join().unwrap();
```

```text
error[E0597]: `name` does not live long enough
   --> e09_static.rs:4:23
    |
  3 |     let name = String::from("worker");
    |         ---- binding `name` declared here
  4 |     let label: &str = &name;
    |                       ^^^^^ borrowed value does not live long enough
  5 |     let h = thread::spawn(move || println!("{label}"));
    |             ------------------------------------------ argument requires that `name` is borrowed for `'static`
  6 |     h.join().unwrap();
  7 | }
    | - `name` dropped here while still borrowed
    |
note: requirement that the value outlives `'static` introduced here
```

Moving the `String` itself into the closure fixes it. [`T: 'static`](https://doc.rust-lang.org/reference/trait-bounds.html#lifetime-bounds) does **not** mean "lives forever": it means "contains no borrowed data that could expire" — an owned `String` qualifies. Threads are [lesson 12](../12-threads-and-concurrency/).

## When lifetimes get in the way: own the data

Coming from C#, the reflex is to store references everywhere. In Rust, a struct full of `&'a` fields spreads its lifetime to everything that holds it. A practical rule while you are learning:

| Situation | Use |
|---|---|
| Function parameters you only read | [`&str`](https://doc.rust-lang.org/std/primitive.str.html), [`&[T]`](https://doc.rust-lang.org/std/primitive.slice.html), `&T` |
| Short-lived views over data someone else owns (parsers, iterators, excerpts) | a struct with `'a` |
| Data a struct keeps for a long time | owned `String`, `Vec<T>`, `T` |
| Data shared by several owners | [`Rc`](https://doc.rust-lang.org/std/rc/struct.Rc.html)/[`Arc`](https://doc.rust-lang.org/std/sync/struct.Arc.html) — [lesson 11](../11-smart-pointers/) |

Cloning a few strings to avoid a lifetime parameter is a perfectly good trade-off.

## Key takeaways

- A lifetime is the span during which a reference is valid; the compiler checks that no reference outlives its value.
- Annotations describe relationships between references in a **signature**; they never extend how long a value lives.
- Three elision rules cover most functions; you annotate when there are several inputs and no `self`.
- A struct holding a reference carries a lifetime parameter and cannot outlive what it borrows.
- `'static` data contains no expiring borrows; it is required by APIs such as `thread::spawn`.
- When in doubt, own the data.

## Exercises

1. Write `fn longest_line(text: &str) -> &str` returning the longest line of a text. Does it need a lifetime annotation? Then write `fn pick(first: &str, second: &str, use_first: bool) -> &str` — what does it need?

<details>
<summary>Solution</summary>

```rust
fn longest_line(text: &str) -> &str {
    text.lines().max_by_key(|line| line.len()).unwrap_or("")
}

fn pick<'a>(first: &'a str, second: &'a str, use_first: bool) -> &'a str {
    if use_first { first } else { second }
}

let poem = String::from("short\na much longer line\nmid");
assert_eq!(longest_line(&poem), "a much longer line");
assert_eq!(pick("left", "right", false), "right");
```

`longest_line` has a single reference input, so elision rule 2 applies. `pick` has two and may return either, so both must share `'a` — exactly like `longest`.

</details>

2. Define `struct Highlight<'a> { line: &'a str, column: usize }` and write `find_highlights(text, word)` returning every line of `text` containing `word`. The caller must be able to search with a temporary `String` query that is dropped before the results are used.

<details>
<summary>Solution</summary>

```rust
#[derive(Debug, PartialEq)]
struct Highlight<'a> {
    line: &'a str,
    column: usize,
}

fn find_highlights<'a>(text: &'a str, word: &str) -> Vec<Highlight<'a>> {
    text.lines()
        .filter_map(|line| line.find(word).map(|column| Highlight { line, column }))
        .collect()
}

let text = String::from("I like Rust\nC# too\nRust again");
let hits = {
    let query = String::from("Rust");   // dropped at the end of this block
    find_highlights(&text, &query)
};
assert_eq!(hits, [Highlight { line: "I like Rust", column: 7 }, Highlight { line: "Rust again", column: 0 }]);
```

The results borrow `text` only, so `word` gets its own (elided) lifetime. Writing `word: &'a str` would compile the function but reject this call with [`E0597`](https://doc.rust-lang.org/error_codes/E0597.html): the compiler would then assume the highlights might point into `query`.

</details>

3. This version of the tokenizer compiles, but `main` does not. Explain the error and fix it by changing one line.

```rust
impl<'a> Parser<'a> {
    fn next_token(&mut self) -> Option<&str> {
        let start = self.pos;
        self.pos = self.input.len();
        Some(&self.input[start..])
    }
}

let line = String::from("let x = 42");
let mut parser = Parser { input: &line, pos: 0 };
let first = parser.next_token();
let second = parser.next_token();
println!("{first:?} {second:?}");
```

```text
error[E0499]: cannot borrow `parser` as mutable more than once at a time
  --> e09_elided_self.rs:18:18
   |
17 |     let first = parser.next_token();
   |                 ------ first mutable borrow occurs here
18 |     let second = parser.next_token();
   |                  ^^^^^^ second mutable borrow occurs here
19 |     println!("{first:?} {second:?}");
   |                ----- first borrow later used here
```

<details>
<summary>Solution</summary>

With `Option<&str>`, elision rule 3 gives the result the lifetime of `&mut self`. As long as `first` is alive, `parser` stays mutably borrowed, so the second call is rejected. The token really points into the input, so say so:

```rust
fn next_token(&mut self) -> Option<&'a str> {
```

Now the tokens borrow `line`, and the parser is free again as soon as each call returns.

</details>

## Sources

- [The Book, ch. 10.3 — Validating References with Lifetimes](https://doc.rust-lang.org/book/ch10-03-lifetime-syntax.html)
- [The Rust Reference — Lifetime elision](https://doc.rust-lang.org/reference/lifetime-elision.html)
- [Rust by Example — `'static`](https://doc.rust-lang.org/rust-by-example/scope/lifetime/static_lifetime.html)
- [`std::thread::spawn`](https://doc.rust-lang.org/std/thread/fn.spawn.html)
