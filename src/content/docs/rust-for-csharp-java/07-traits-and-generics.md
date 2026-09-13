---
title: 7. Traits and generics
description: Interfaces become traits — static and dynamic dispatch, bounds, standard traits and extension methods.
sidebar:
  order: 7
---

Full example: [`examples/l07_traits_generics.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l07_traits_generics.rs) — `cargo run --example l07_traits_generics`.

## A trait is an interface

```rust
trait Shape {
    fn area(&self) -> f64;

    fn name(&self) -> String {        // default method
        String::from("shape")
    }
}

struct Circle { radius: f64 }
struct Square { side: f64 }

impl Shape for Circle {
    fn area(&self) -> f64 {
        std::f64::consts::PI * self.radius * self.radius
    }

    fn name(&self) -> String {
        format!("circle r={}", self.radius)
    }
}

impl Shape for Square {
    fn area(&self) -> f64 {
        self.side * self.side
    }
    // keeps the default name()
}
```

| Rust | C# | Java |
|---|---|---|
| `trait Shape { … }` | `interface IShape { … }` | `interface Shape { … }` |
| default method in the trait | [default interface method](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interface-implementation/default-interface-methods-versions) (C# 8) | [`default` method](https://docs.oracle.com/javase/tutorial/java/IandI/defaultmethods.html) (Java 8) |
| `impl Shape for Circle { … }` — a separate block | `class Circle : IShape` | `class Circle implements Shape` |
| no inheritance between structs | class inheritance | class inheritance |

The implementation lives in its own `impl` block, not in the type declaration. That detail matters: it lets you implement a trait for a type **after** the fact, even a type you did not write (see *extension methods* below).

Leaving out a required method is a compile error:

```text
error[E0046]: not all trait items implemented, missing: `area`
  --> e07_missing_method.rs:12:1
   |
 2 |     fn area(&self) -> f64;
   |     ---------------------- `area` from trait
...
12 | impl Shape for Square {
   | ^^^^^^^^^^^^^^^^^^^^^ missing `area` in implementation
```

## Generics with trait bounds

A generic function must say which traits its type parameter implements — the equivalent of [`where T : IShape`](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters) or [`<T extends Shape>`](https://docs.oracle.com/javase/tutorial/java/generics/bounded.html):

```rust
fn total_area<T: Shape>(shapes: &[T]) -> f64 {
    shapes.iter().map(|s| s.area()).sum()
}

let circles = [Circle { radius: 1.0 }, Circle { radius: 2.0 }];
println!("total circle area = {:.2}", total_area(&circles));   // 15.71
```

Without the bound, Rust does not assume anything about `T`:

```text
error[E0599]: no method named `area` found for reference `&T` in the current scope
 --> e07_missing_bound.rs:6:29
  |
6 |     shapes.iter().map(|s| s.area()).sum()
  |                             ^^^^ method not found in `&T`
  |
  = help: items from traits can only be used if the type parameter is bounded by the trait
help: the following trait defines an item `area`, perhaps you need to restrict type parameter `T` with it:
  |
5 | fn total_area<T: Shape>(shapes: &[T]) -> f64 {
  |                +++++++
```

Two other spellings of the same idea:

```rust
// `impl Trait` in argument position: shorthand for a generic parameter
fn describe(shape: &impl Shape) -> String {
    format!("{} has area {:.2}", shape.name(), shape.area())
}

// `where` clause: easier to read with several bounds
fn print_all<T>(items: &[T])
where
    T: fmt::Display + PartialOrd,
{
    // …
}
```

```text
3 9 4 (max 9)
pear apple fig (max pear)
```

## Static vs dynamic dispatch

`total_area::<Circle>` and `total_area::<Square>` are compiled as **two separate functions**, each calling `area` directly and eligible for inlining. This is called [**monomorphization**](https://doc.rust-lang.org/book/ch10-01-syntax.html#performance-of-code-using-generics).

When you need a collection of *different* types, use a [**trait object**](https://doc.rust-lang.org/reference/types/trait-object.html), `dyn Shape`, behind a pointer such as [`Box`](https://doc.rust-lang.org/std/boxed/struct.Box.html) or `&`:

```rust
fn largest(shapes: &[Box<dyn Shape>]) -> Option<&dyn Shape> {
    shapes
        .iter()
        .map(|s| s.as_ref())
        .max_by(|a, b| a.area().total_cmp(&b.area()))
}

let mixed: Vec<Box<dyn Shape>> = vec![Box::new(Circle { radius: 1.5 }), Box::new(Square { side: 2.0 })];
// largest: circle r=1.5 (7.07)
```

| | Generics `T: Shape` | Trait object `dyn Shape` |
|---|---|---|
| Resolved | at compile time | at runtime, through a vtable |
| Mixed types in one `Vec` | no | yes |
| Cost | none at runtime, larger binary | one indirect call, like an interface call |
| C# analogy | generics over `struct`s (specialised by the JIT) | calling through `IShape` |
| Java analogy | — (generics are [erased](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html) to casts) | calling through `Shape` |

Default to generics; reach for `dyn Trait` when you truly need heterogeneous values or want to hide the concrete type. Not every trait can be used as `dyn`: a trait with generic methods, for example, is not *dyn-compatible* (formerly called "object-safe").

## Standard traits you implement

Much of what C# puts in [`System.Object`](https://learn.microsoft.com/dotnet/api/system.object) or in operators is a trait in Rust:

| Rust trait | C# | Java | Usually |
|---|---|---|---|
| `Debug` | debugger display | — | [`#[derive(Debug)]`](https://doc.rust-lang.org/reference/attributes/derive.html) |
| [`Display`](https://doc.rust-lang.org/std/fmt/trait.Display.html) | `ToString()` | `toString()` | implemented by hand |
| `Clone` | [`ICloneable`](https://learn.microsoft.com/dotnet/api/system.icloneable) | `clone()` | derived |
| `PartialEq` / `Eq` | `Equals` / `==` | `equals` | derived |
| `Hash` | `GetHashCode` | `hashCode` | derived |
| [`PartialOrd`](https://doc.rust-lang.org/std/cmp/trait.PartialOrd.html) / `Ord` | [`IComparable<T>`](https://learn.microsoft.com/dotnet/api/system.icomparable-1) | [`Comparable<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Comparable.html) | derived |
| `Default` | parameterless constructor | no-arg constructor | derived |
| [`From`](https://doc.rust-lang.org/std/convert/trait.From.html) / `Into` | conversion operators | static factory | implemented by hand |
| `Add`, `Mul`, … | [`operator +`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/operator-overloading) | — | implemented by hand |

```rust
#[derive(Debug, Default, PartialEq)]
struct Celsius(f64);

struct Fahrenheit(f64);

impl fmt::Display for Celsius {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{:.1}°C", self.0)
    }
}

impl From<Fahrenheit> for Celsius {
    fn from(f: Fahrenheit) -> Self {
        Celsius((f.0 - 32.0) * 5.0 / 9.0)
    }
}

let body = Celsius::from(Fahrenheit(98.6));
let also: Celsius = Fahrenheit(212.0).into();   // Into comes for free with From
println!("{body} / {also} / default {}", Celsius::default());
// 37.0°C / 100.0°C / default 0.0°C
```

## Extension methods, Rust style

In C#, an [extension method](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/extension-methods) adds `Shout()` to `string`. In Rust, you define a trait and implement it for the existing type:

```rust
trait Shout {
    fn shout(&self) -> String;
}

impl Shout for str {
    fn shout(&self) -> String {
        format!("{}!", self.to_uppercase())
    }
}

println!("{}", "hello".shout());   // HELLO!
```

Like a C# `using` for extension methods, the trait must be in scope (`use`) where you call it.

### The orphan rule

You can implement **your** trait for any type, or **any** trait for your type — but not someone else's trait for someone else's type:

```rust
impl fmt::Display for Vec<i32> { /* … */ }
```

```text
error[E0117]: only traits defined in the current crate can be implemented for types defined outside of the crate
 --> e07_orphan.rs:3:1
  |
3 | impl fmt::Display for Vec<i32> {
  | ^^^^^^^^^^^^^^^^^^^^^^--------
  |                       |
  |                       `Vec` is not defined in the current crate
  |
  = note: impl doesn't have any local type before any uncovered type parameters
  = note: for more information see https://doc.rust-lang.org/reference/items/implementations.html#orphan-rules
  = note: define and implement a trait or new type instead
```

This guarantees two crates can never provide conflicting implementations. The standard workaround is the **newtype** from lesson 5: wrap the foreign type in your own struct.

## Key takeaways

- Traits are interfaces with default methods, implemented in separate `impl` blocks.
- Generic code must declare what it needs with bounds (`T: Shape`, [`impl Shape`](https://doc.rust-lang.org/reference/types/impl-trait.html), `where`).
- Generics are resolved at compile time; `dyn Trait` gives runtime polymorphism when you need mixed types.
- `Display`, `Clone`, `PartialEq`, `Default`, `From` replace `ToString`, `ICloneable`, `Equals`, constructors and conversions.
- Implementing a trait for an existing type replaces extension methods, within the orphan rule.

## Exercises

1. Define a trait `Priced` with `fn price(&self) -> f64` and a default `fn price_with_tax(&self, rate: f64) -> f64`. Implement it for `Book { title: String, price: f64 }` and write `fn cheapest<T: Priced>(items: &[T]) -> Option<&T>`.

<details>
<summary>Solution</summary>

```rust
trait Priced {
    fn price(&self) -> f64;

    fn price_with_tax(&self, rate: f64) -> f64 {
        self.price() * (1.0 + rate)
    }
}

struct Book {
    title: String,
    price: f64,
}

impl Priced for Book {
    fn price(&self) -> f64 {
        self.price
    }
}

fn cheapest<T: Priced>(items: &[T]) -> Option<&T> {
    items.iter().min_by(|a, b| a.price().total_cmp(&b.price()))
}

let books = [
    Book { title: "Rust".into(), price: 40.0 },
    Book { title: "C#".into(), price: 35.0 },
];
assert_eq!(cheapest(&books).map(|b| b.title.as_str()), Some("C#"));
assert_eq!(books[0].price_with_tax(0.25), 50.0);
```

`total_cmp` is used because `f64` has no total order (`NaN`), so `min_by_key` cannot be used directly on floats.

</details>

2. Add `struct Coffee { size_ml: u32 }` priced at `0.01` per ml. Write `fn total(items: &[Box<dyn Priced>]) -> f64` over a vector mixing books and coffees. Why can't `cheapest` from exercise 1 take that same vector as `&[T]` with `T = Book`?

<details>
<summary>Solution</summary>

```rust
struct Coffee {
    size_ml: u32,
}

impl Priced for Coffee {
    fn price(&self) -> f64 {
        self.size_ml as f64 * 0.01
    }
}

fn total(items: &[Box<dyn Priced>]) -> f64 {
    items.iter().map(|i| i.price()).sum()
}

let basket: Vec<Box<dyn Priced>> = vec![
    Box::new(Book { title: "Rust".into(), price: 40.0 }),
    Box::new(Coffee { size_ml: 250 }),
];
assert_eq!(total(&basket), 42.5);
```

A generic `&[T]` needs every element to be the *same* concrete type `T`. A `Vec<Box<dyn Priced>>` holds different types behind one trait object, which is exactly what dynamic dispatch is for. To reuse `cheapest` on the basket, `T` would have to be `Box<dyn Priced>` — which works once you forward the trait to the box:

```rust
impl Priced for Box<dyn Priced> {
    fn price(&self) -> f64 {
        (**self).price()
    }
}

let cheapest_item = cheapest(&basket).map(|i| i.price());
assert_eq!(cheapest_item, Some(2.5));
```

</details>

3. `impl fmt::Display for Vec<i32>` is rejected (`E0117`). Print a list of scores as `"3 scores: 12, 7, 30"` using a newtype instead.

<details>
<summary>Solution</summary>

```rust
use std::fmt;

struct Scores(Vec<i32>);

impl fmt::Display for Scores {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let list: Vec<String> = self.0.iter().map(|s| s.to_string()).collect();
        write!(f, "{} scores: {}", self.0.len(), list.join(", "))
    }
}

assert_eq!(Scores(vec![12, 7, 30]).to_string(), "3 scores: 12, 7, 30");
```

`Scores` is a local type, so implementing the foreign `Display` trait for it is allowed. Any type that implements `Display` also gets `to_string()`.

</details>

## Sources

- [The Book, ch. 10.2 — Traits: Defining Shared Behavior](https://doc.rust-lang.org/book/ch10-02-traits.html)
- [The Book, ch. 18.2 — Using Trait Objects That Allow for Values of Different Types](https://doc.rust-lang.org/book/ch18-02-trait-objects.html)
- [The Rust Reference — Orphan rules](https://doc.rust-lang.org/reference/items/implementations.html#orphan-rules)
- [The Rust Reference — Dyn compatibility](https://doc.rust-lang.org/reference/items/traits.html#dyn-compatibility)
