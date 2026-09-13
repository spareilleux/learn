---
title: 5. Structs, enums and pattern matching
description: Replacing classes, records and sealed hierarchies with struct, enum, impl and exhaustive match.
sidebar:
  order: 5
---

Full example: [`examples/l05_structs_enums.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l05_structs_enums.rs) — `cargo run --example l05_structs_enums`.

## Data and behaviour are declared separately

A C# or Java class bundles fields, constructors and methods in one block. Rust splits them: a `struct` declares the data, one or more `impl` blocks add the functions.

```rust
#[derive(Debug, Clone, PartialEq)]
struct Account {
    owner: String,
    balance_cents: i64,
}

impl Account {
    fn new(owner: &str) -> Self {
        Self { owner: owner.to_string(), balance_cents: 0 }
    }

    fn balance(&self) -> f64 {
        self.balance_cents as f64 / 100.0
    }

    fn deposit(&mut self, cents: i64) {
        self.balance_cents += cents;
    }

    fn close(self) -> i64 {
        self.balance_cents
    }
}
```

| Rust | C# | Java |
|---|---|---|
| `struct` + `impl` | `class` / `record` | `class` / `record` |
| `fn new(…) -> Self` (a convention) | constructor | constructor |
| `fn balance(&self)` | instance method | instance method |
| `fn deposit(&mut self, …)` | method that mutates `this` | method that mutates `this` |
| `fn close(self)` | — (no equivalent) | — |
| `fn new(…)` without `self` | `static` method | `static` method |
| `#[derive(Debug, Clone, PartialEq)]` | what a `record` generates: `ToString`, copy, value equality | what a `record` generates |

- There are **no constructors**: `Account::new` is an ordinary associated function that returns `Self`. Several "constructors" are just several functions (`new`, `with_capacity`, `from_str`…).
- The receiver says what the method does to the value: read (`&self`), modify (`&mut self`) or **consume** (`self`) — after `account.close()`, `account` is moved and cannot be used, which is how Rust models "this object is finished".
- There is **no inheritance** between structs. Shared behaviour goes into traits ([lesson 7](../07-traits-and-generics/)).

```rust
let mut account = Account::new("Ada");
account.deposit(1_250);
let copy = account.clone();
println!("{account:?}");
println!("balance = {:.2}, equal to copy: {}", account.balance(), account == copy);
```

```text
Account { owner: "Ada", balance_cents: 1250 }
balance = 12.50, equal to copy: true
```

Every field must be initialised — there are no default `null`s:

```text
error[E0063]: missing field `balance_cents` in initializer of `Account`
 --> e05_missing_field.rs:7:19
  |
7 |     let account = Account { owner: String::from("Ada") };
  |                   ^^^^^^^ missing `balance_cents`
```

**Struct update syntax** copies the remaining fields from another value, like a C# `with` expression:

```rust
let other = Account { owner: "Grace".into(), ..copy };
println!("{} has {} cents", other.owner, other.balance_cents);   // Grace has 1250 cents
```

## Tuple structs and newtypes

A struct can have unnamed fields. With a single field, it creates a distinct type around an existing one — a **newtype**:

```rust
#[derive(Debug, Clone, Copy, PartialEq, PartialOrd)]
struct Meters(f64);

let short = Meters(3.5);
let long = Meters(10.0);
println!("{short:?} < {long:?}: {}", short < long);   // Meters(3.5) < Meters(10.0): true
```

A function taking `Meters` will not accept a raw `f64` or a `Feet(f64)`. It costs nothing at runtime: `Meters` is exactly an `f64` in memory.

## Enums carry data

C# enums are named integers; Java enums are a fixed set of objects that all share the same fields. A Rust `enum` is a **tagged union**: each variant can hold *different* data.

```rust
enum Shape {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
    Triangle(f64, f64, f64),
}
```

The closest equivalent is a closed hierarchy:

```csharp
// C#
abstract record Shape;
record Circle(double Radius) : Shape;
record Rectangle(double Width, double Height) : Shape;
record Triangle(double A, double B, double C) : Shape;
```

```java
// Java 21
sealed interface Shape permits Circle, Rectangle, Triangle {}
record Circle(double radius) implements Shape {}
record Rectangle(double width, double height) implements Shape {}
record Triangle(double a, double b, double c) implements Shape {}
```

## `match` is exhaustive

```rust
impl Shape {
    fn area(&self) -> f64 {
        match self {
            Shape::Circle { radius } => std::f64::consts::PI * radius * radius,
            Shape::Rectangle { width, height } => width * height,
            Shape::Triangle(a, b, c) => {
                let s = (a + b + c) / 2.0;
                (s * (s - a) * (s - b) * (s - c)).sqrt()
            }
        }
    }
}
```

Forget a variant and the program does not compile:

```text
error[E0004]: non-exhaustive patterns: `&Shape::Triangle(_, _, _)` not covered
  --> e05_nonexhaustive.rs:8:11
   |
 8 |     match shape {
   |           ^^^^^ pattern `&Shape::Triangle(_, _, _)` not covered
   |
note: `Shape` defined here
  --> e05_nonexhaustive.rs:1:6
   |
 1 | enum Shape {
   |      ^^^^^
...
 4 |     Triangle(f64, f64, f64),
   |     -------- not covered
```

| When a case is missing | Result |
|---|---|
| C# `switch` expression | warning CS8509, then `SwitchExpressionException` at runtime |
| Java 21 `switch` over a sealed interface | compile error |
| Rust `match` | compile error `E0004` |

This is what makes enums so useful for refactoring: add a variant, and the compiler lists every place that must handle it.

## Patterns

Patterns destructure values and can be refined:

```rust
match command {
    Command::Move { dx, dy: 0 } => println!("horizontal move by {dx}"),   // literal inside a pattern
    Command::Move { dx, dy } => println!("move by ({dx}, {dy})"),
    Command::Say(text) => println!("say {text:?}"),
    Command::Quit => println!("quit"),
}
```

```text
horizontal move by 3
move by (1, -2)
say "hi"
quit
```

Ranges, guards (`if`) and the catch-all `_`:

```rust
fn describe(temperature: i32) -> &'static str {
    match temperature {
        i32::MIN..=0 => "freezing",
        1..=15 => "cold",
        t if t > 30 => "hot",
        _ => "mild",
    }
}
```

Arms are tried **in order**, so put the specific ones first — the same rule as C# and Java `switch` patterns.

## `if let` and `let … else`

When only one pattern matters, `if let` avoids a full `match`:

```rust
if let Some(Shape::Circle { radius }) = shapes.first() {
    println!("first shape is a circle of radius {radius}");
}
```

`let … else` binds a pattern or leaves the current block — perfect for guard clauses:

```rust
fn parse_port(text: &str) -> u16 {
    let Ok(port) = text.parse::<u16>() else {
        return 8080;
    };
    port
}
// parse_port("3000") == 3000, parse_port("oops") == 8080
```

`Some` and `Ok` are themselves enum variants — the subject of the [next lesson](../06-option-result/).

## Key takeaways

- `struct` holds data, `impl` adds associated functions and methods; `new` is a convention, not a constructor.
- `&self`, `&mut self` and `self` state whether a method reads, modifies or consumes the value.
- `enum` variants carry different data: a Rust enum is a sealed hierarchy of records in one declaration.
- `match` must be exhaustive; `if let` and `let … else` handle the single-pattern cases.

## Exercises

1. Translate this C# hierarchy into a Rust enum, and write `fn describe(payment: &Payment) -> String` returning `"card ending 4242"`, `"transfer from FR76…"` or `"cash"`.

```csharp
abstract record Payment;
record Card(string Last4) : Payment;
record Transfer(string Iban) : Payment;
record Cash : Payment;
```

<details>
<summary>Solution</summary>

```rust
enum Payment {
    Card { last4: String },
    Transfer { iban: String },
    Cash,
}

fn describe(payment: &Payment) -> String {
    match payment {
        Payment::Card { last4 } => format!("card ending {last4}"),
        Payment::Transfer { iban } => format!("transfer from {iban}"),
        Payment::Cash => String::from("cash"),
    }
}
```

</details>

2. You add `Crypto { wallet: String }` to `Payment`. What happens to `describe`, and why is it better than the C# behaviour?

<details>
<summary>Solution</summary>

`describe` stops compiling with `E0004: non-exhaustive patterns: &Payment::Crypto { .. } not covered`. Every `match` that must handle the new case is reported at build time, instead of a warning plus a `SwitchExpressionException` in production. (If a `_ =>` arm exists, the new variant silently falls into it — a reason to avoid catch-alls on enums you own.)

</details>

3. Write a `Rectangle { width: f64, height: f64 }` with `fn square(size: f64) -> Self`, `fn area(&self) -> f64` and `fn scale(&mut self, factor: f64)`. Then create a copy that is twice as wide using struct update syntax.

<details>
<summary>Solution</summary>

```rust
#[derive(Debug, Clone, Copy, PartialEq)]
struct Rectangle {
    width: f64,
    height: f64,
}

impl Rectangle {
    fn square(size: f64) -> Self {
        Self { width: size, height: size }
    }

    fn area(&self) -> f64 {
        self.width * self.height
    }

    fn scale(&mut self, factor: f64) {
        self.width *= factor;
        self.height *= factor;
    }
}

let mut r = Rectangle::square(2.0);
r.scale(1.5);                                            // 3 x 3
let wide = Rectangle { width: r.width * 2.0, ..r };      // 6 x 3
assert_eq!(wide.area(), 18.0);
```

</details>

## Sources

- [The Book, ch. 5 — Using Structs to Structure Related Data](https://doc.rust-lang.org/book/ch05-00-structs.html)
- [The Book, ch. 6 — Enums and Pattern Matching](https://doc.rust-lang.org/book/ch06-00-enums.html)
- [The Book, ch. 19 — Patterns and Matching](https://doc.rust-lang.org/book/ch19-00-patterns.html)
