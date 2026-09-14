---
title: 5. Structs, enums et pattern matching
description: Remplacer classes, records et hiérarchies scellées par struct, enum, impl et un match exhaustif.
sidebar:
  order: 5
---

Exemple complet : [`examples/l05_structs_enums.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l05_structs_enums.rs) — `cargo run --example l05_structs_enums`.

## Les données et le comportement sont déclarés séparément

Une classe C# ou Java regroupe champs, constructeurs et méthodes dans un seul bloc. Rust les sépare : une `struct` déclare les données, un ou plusieurs blocs `impl` ajoutent les fonctions.

Extrait de [`examples/l05_structs_enums.rs`, lignes 4-33](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L4-L33) :

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
| `struct` + `impl` | `class` / [`record`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record) | `class` / [`record`](https://docs.oracle.com/en/java/javase/25/language/records.html) |
| `fn new(…) -> Self` (une convention) | constructeur | constructeur |
| `fn balance(&self)` | méthode d'instance | méthode d'instance |
| `fn deposit(&mut self, …)` | méthode qui modifie `this` | méthode qui modifie `this` |
| `fn close(self)` | — (pas d'équivalent) | — |
| `fn new(…)` sans `self` | méthode `static` | méthode `static` |
| [`#[derive(Debug, Clone, PartialEq)]`](https://doc.rust-lang.org/reference/attributes/derive.html) | ce que génère un `record` : `ToString`, copie, égalité de valeur | ce que génère un `record` |

- Il n'y a **pas de constructeurs** : `Account::new` est une fonction associée ordinaire qui renvoie `Self`. Plusieurs « constructeurs » ne sont que plusieurs fonctions (`new`, `with_capacity`, `from_str`…).
- Le receveur indique ce que la méthode fait de la valeur : la lire (`&self`), la modifier (`&mut self`) ou la **consommer** (`self`) — après `account.close()`, `account` est déplacé et ne peut plus être utilisé, et c'est ainsi que Rust modélise « cet objet est terminé ».
- Il n'y a **pas d'héritage** entre structs. Le comportement partagé va dans les traits ([leçon 7](../07-traits-and-generics/)).

Extrait de [`examples/l05_structs_enums.rs`, lignes 96-104](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L96-L104) :

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

Chaque champ doit être initialisé — il n'y a pas de `null` par défaut :

```text
error[E0063]: missing field `balance_cents` in initializer of `Account`
 --> e05_missing_field.rs:7:19
  |
7 |     let account = Account { owner: String::from("Ada") };
  |                   ^^^^^^^ missing `balance_cents`
```

La **syntaxe de mise à jour de struct** (struct update syntax) copie les champs restants depuis une autre valeur, comme une [expression `with`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/with-expression) en C# ([lignes 107-111](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L107-L111)) :

```rust
let other = Account { owner: "Grace".into(), ..copy };
println!("{} has {} cents", other.owner, other.balance_cents);   // Grace has 1250 cents
```

## Tuple structs et newtypes

Une struct peut avoir des champs sans nom. Avec un seul champ, elle crée un type distinct autour d'un type existant — un **[newtype](https://doc.rust-lang.org/rust-by-example/generics/new_types.html)** ([lignes 36-37](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L36-L37), [116-118](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L116-L118)) :

```rust
#[derive(Debug, Clone, Copy, PartialEq, PartialOrd)]
struct Meters(f64);

let short = Meters(3.5);
let long = Meters(10.0);
println!("{short:?} < {long:?}: {}", short < long);   // Meters(3.5) < Meters(10.0): true
```

Une fonction qui prend un `Meters` n'acceptera ni un `f64` brut ni un `Feet(f64)`. Cela ne coûte rien à l'exécution : en mémoire, `Meters` est exactement un `f64`.

## Les enums portent des données

Les [enums C#](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/enum) sont des entiers nommés ; les [enums Java](https://dev.java/learn/classes-objects/enums/) sont un ensemble fixe d'objets qui partagent tous les mêmes champs. Une `enum` Rust est une **union étiquetée** (tagged union) : chaque variante peut contenir des données *différentes*.

Extrait de [`examples/l05_structs_enums.rs`, lignes 41-45](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L41-L45) :

```rust
enum Shape {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
    Triangle(f64, f64, f64),
}
```

L'équivalent le plus proche est une hiérarchie fermée :

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

## `match` est exhaustif

Extrait de [`examples/l05_structs_enums.rs`, lignes 47-59](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L47-L59) :

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

Oubliez une variante et le programme ne compile pas :

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

| Quand un cas manque | Résultat |
|---|---|
| [expression `switch`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression) en C# | avertissement [CS8509](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/pattern-matching-warnings#pattern-completeness-and-redundancy), puis [`SwitchExpressionException`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.switchexpressionexception) à l'exécution |
| [`switch`](https://openjdk.org/jeps/441) Java 21 sur une [interface scellée](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html) | erreur de compilation |
| `match` en Rust | erreur de compilation [`E0004`](https://doc.rust-lang.org/error_codes/E0004.html) |

C'est ce qui rend les enums si utiles pour le refactoring : ajoutez une variante, et le compilateur liste chaque endroit qui doit la gérer.

## Motifs

Le **filtrage par motif** (pattern matching) déstructure les valeurs, et les motifs peuvent être affinés ([lignes 139-144](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L139-L144)) :

```rust
match command {
    Command::Move { dx, dy: 0 } => println!("horizontal move by {dx}"),   // littéral à l'intérieur d'un motif
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

Intervalles, [gardes](https://doc.rust-lang.org/reference/expressions/match-expr.html#match-guards) (`if`) et le motif fourre-tout `_` ([lignes 77-85](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L77-L85)) :

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

Les branches sont essayées **dans l'ordre**, donc placez les plus spécifiques en premier — la même règle que pour les motifs des `switch` C# et Java.

## `if let` et `let … else`

Quand un seul motif compte, [`if let`](https://doc.rust-lang.org/book/ch06-03-if-let.html) évite un `match` complet :

```rust
if let Some(Shape::Circle { radius }) = shapes.first() {
    println!("first shape is a circle of radius {radius}");
}
```

[`let … else`](https://doc.rust-lang.org/rust-by-example/flow_control/let_else.html) lie un motif ou quitte le bloc courant — parfait pour les clauses de garde ([lignes 87-93](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L87-L93)) :

```rust
fn parse_port(text: &str) -> u16 {
    let Ok(port) = text.parse::<u16>() else {
        return 8080;
    };
    port
}
// parse_port("3000") == 3000, parse_port("oops") == 8080
```

`Some` et `Ok` sont eux-mêmes des variantes d'enum — le sujet de la [leçon suivante](../06-option-result/).

## À retenir

- `struct` contient les données, `impl` ajoute les fonctions associées et les méthodes ; `new` est une convention, pas un constructeur.
- `&self`, `&mut self` et `self` indiquent si une méthode lit, modifie ou consomme la valeur.
- Les variantes d'une `enum` portent des données différentes : une enum Rust est une hiérarchie scellée de records en une seule déclaration.
- `match` doit être exhaustif ; `if let` et `let … else` gèrent les cas à motif unique.

## Exercices

1. Traduisez cette hiérarchie C# en enum Rust, et écrivez `fn describe(payment: &Payment) -> String` qui renvoie `"card ending 4242"`, `"transfer from FR76…"` ou `"cash"`.

```csharp
abstract record Payment;
record Card(string Last4) : Payment;
record Transfer(string Iban) : Payment;
record Cash : Payment;
```

<details>
<summary>Solution</summary>

Extrait de [`src/lib.rs`, lignes 223-230](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L223-L230) :

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

2. Vous ajoutez `Crypto { wallet: String }` à `Payment`. Qu'arrive-t-il à `describe`, et pourquoi est-ce mieux que le comportement de C# ?

<details>
<summary>Solution</summary>

`describe` ne compile plus, avec `E0004: non-exhaustive patterns: &Payment::Crypto { .. } not covered`. Chaque `match` qui doit gérer le nouveau cas est signalé à la compilation, au lieu d'un avertissement suivi d'une `SwitchExpressionException` en production. (Si une branche `_ =>` existe, la nouvelle variante y tombe silencieusement — une raison d'éviter les motifs fourre-tout sur les enums que vous possédez.)

</details>

3. Écrivez un `Rectangle { width: f64, height: f64 }` avec `fn square(size: f64) -> Self`, `fn area(&self) -> f64` et `fn scale(&mut self, factor: f64)`. Créez ensuite une copie deux fois plus large avec la syntaxe de mise à jour de struct.

<details>
<summary>Solution</summary>

Extrait de [`src/lib.rs`, lignes 249-259](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L249-L259) :

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
