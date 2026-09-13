---
title: 7. Traits et génériques
description: Les interfaces deviennent des traits — dispatch statique et dynamique, contraintes, traits standard et méthodes d'extension.
sidebar:
  order: 7
---

Exemple complet : [`examples/l07_traits_generics.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l07_traits_generics.rs) — `cargo run --example l07_traits_generics`.

## Un trait est une interface

```rust
trait Shape {
    fn area(&self) -> f64;

    fn name(&self) -> String {        // méthode par défaut
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
    // conserve le name() par défaut
}
```

| Rust | C# | Java |
|---|---|---|
| `trait Shape { … }` | `interface IShape { … }` | `interface Shape { … }` |
| méthode par défaut dans le trait | [méthode d'interface par défaut](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interface-implementation/default-interface-methods-versions) (C# 8) | [méthode `default`](https://docs.oracle.com/javase/tutorial/java/IandI/defaultmethods.html) (Java 8) |
| `impl Shape for Circle { … }` — un bloc séparé | `class Circle : IShape` | `class Circle implements Shape` |
| pas d'héritage entre structs | héritage de classes | héritage de classes |

L'implémentation vit dans son propre bloc `impl`, et non dans la déclaration du type. Ce détail compte : il permet d'implémenter un trait pour un type **après coup**, même un type que vous n'avez pas écrit (voir *méthodes d'extension* plus bas).

Omettre une méthode requise est une erreur de compilation :

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

## Génériques avec contraintes de trait

Une fonction générique doit indiquer quels traits son paramètre de type implémente — l'équivalent de [`where T : IShape`](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters) ou de [`<T extends Shape>`](https://docs.oracle.com/javase/tutorial/java/generics/bounded.html) :

```rust
fn total_area<T: Shape>(shapes: &[T]) -> f64 {
    shapes.iter().map(|s| s.area()).sum()
}

let circles = [Circle { radius: 1.0 }, Circle { radius: 2.0 }];
println!("total circle area = {:.2}", total_area(&circles));   // 15.71
```

Sans la contrainte (bound), Rust ne suppose rien sur `T` :

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

Deux autres écritures de la même idée :

```rust
// `impl Trait` en position d'argument : raccourci pour un paramètre générique
fn describe(shape: &impl Shape) -> String {
    format!("{} has area {:.2}", shape.name(), shape.area())
}

// clause `where` : plus lisible avec plusieurs contraintes
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

## Dispatch statique contre dispatch dynamique

`total_area::<Circle>` et `total_area::<Square>` sont compilées comme **deux fonctions distinctes**, chacune appelant `area` directement et pouvant être inlinée. C'est ce qu'on appelle la [**monomorphisation**](https://doc.rust-lang.org/book/ch10-01-syntax.html#performance-of-code-using-generics) (monomorphization).

Quand vous avez besoin d'une collection de types *différents*, utilisez un [**objet trait**](https://doc.rust-lang.org/reference/types/trait-object.html) (trait object), `dyn Shape`, derrière un pointeur comme [`Box`](https://doc.rust-lang.org/std/boxed/struct.Box.html) ou `&` :

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

| | Génériques `T: Shape` | Objet trait `dyn Shape` |
|---|---|---|
| Résolution | à la compilation | à l'exécution, via une vtable |
| Types mélangés dans un même `Vec` | non | oui |
| Coût | nul à l'exécution, binaire plus gros | un appel indirect, comme un appel d'interface |
| Analogie C# | génériques sur des `struct` (spécialisés par le JIT) | appel via `IShape` |
| Analogie Java | — (les génériques sont [effacés](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html) en casts) | appel via `Shape` |

Par défaut, utilisez les génériques ; recourez à `dyn Trait` quand vous avez vraiment besoin de valeurs hétérogènes ou voulez masquer le type concret. Tous les traits ne peuvent pas être utilisés avec `dyn` : un trait qui a des méthodes génériques, par exemple, n'est pas *dyn-compatible* (anciennement appelé « object-safe »).

## Les traits standard que vous implémentez

Une grande partie de ce que C# place dans [`System.Object`](https://learn.microsoft.com/dotnet/api/system.object) ou dans les opérateurs est un trait en Rust :

| Trait Rust | C# | Java | Habituellement |
|---|---|---|---|
| `Debug` | affichage dans le débogueur | — | [`#[derive(Debug)]`](https://doc.rust-lang.org/reference/attributes/derive.html) |
| [`Display`](https://doc.rust-lang.org/std/fmt/trait.Display.html) | `ToString()` | `toString()` | implémenté à la main |
| `Clone` | [`ICloneable`](https://learn.microsoft.com/dotnet/api/system.icloneable) | `clone()` | dérivé |
| `PartialEq` / `Eq` | `Equals` / `==` | `equals` | dérivé |
| `Hash` | `GetHashCode` | `hashCode` | dérivé |
| [`PartialOrd`](https://doc.rust-lang.org/std/cmp/trait.PartialOrd.html) / `Ord` | [`IComparable<T>`](https://learn.microsoft.com/dotnet/api/system.icomparable-1) | [`Comparable<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Comparable.html) | dérivé |
| `Default` | constructeur sans paramètre | constructeur sans argument | dérivé |
| [`From`](https://doc.rust-lang.org/std/convert/trait.From.html) / `Into` | opérateurs de conversion | fabrique statique | implémenté à la main |
| `Add`, `Mul`, … | [`operator +`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/operator-overloading) | — | implémenté à la main |

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
let also: Celsius = Fahrenheit(212.0).into();   // Into est fourni gratuitement avec From
println!("{body} / {also} / default {}", Celsius::default());
// 37.0°C / 100.0°C / default 0.0°C
```

## Les méthodes d'extension, à la manière de Rust

En C#, une [méthode d'extension](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/extension-methods) ajoute `Shout()` à `string`. En Rust, vous définissez un trait et l'implémentez pour le type existant :

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

Comme un `using` C# pour les méthodes d'extension, le trait doit être dans la portée (`use`) là où vous l'appelez.

### La règle de l'orphelin

Vous pouvez implémenter **votre** trait pour n'importe quel type, ou **n'importe quel** trait pour votre type — mais pas le trait de quelqu'un d'autre pour le type de quelqu'un d'autre :

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

Cela garantit que deux crates ne peuvent jamais fournir des implémentations contradictoires. La solution de contournement habituelle est le **newtype** de la leçon 5 : envelopper le type étranger dans votre propre struct.

## À retenir

- Les traits sont des interfaces avec des méthodes par défaut, implémentées dans des blocs `impl` séparés.
- Le code générique doit déclarer ce dont il a besoin avec des contraintes (`T: Shape`, [`impl Shape`](https://doc.rust-lang.org/reference/types/impl-trait.html), `where`).
- Les génériques sont résolus à la compilation ; `dyn Trait` offre du polymorphisme à l'exécution quand vous avez besoin de types mélangés.
- `Display`, `Clone`, `PartialEq`, `Default`, `From` remplacent `ToString`, `ICloneable`, `Equals`, les constructeurs et les conversions.
- Implémenter un trait pour un type existant remplace les méthodes d'extension, dans les limites de la règle de l'orphelin.

## Exercices

1. Définissez un trait `Priced` avec `fn price(&self) -> f64` et une méthode par défaut `fn price_with_tax(&self, rate: f64) -> f64`. Implémentez-le pour `Book { title: String, price: f64 }` et écrivez `fn cheapest<T: Priced>(items: &[T]) -> Option<&T>`.

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

On utilise `total_cmp` parce que `f64` n'a pas d'ordre total (`NaN`), donc `min_by_key` ne peut pas être utilisé directement sur des flottants.

</details>

2. Ajoutez `struct Coffee { size_ml: u32 }` au prix de `0.01` par ml. Écrivez `fn total(items: &[Box<dyn Priced>]) -> f64` sur un vecteur qui mélange livres et cafés. Pourquoi `cheapest` de l'exercice 1 ne peut-elle pas prendre ce même vecteur comme `&[T]` avec `T = Book` ?

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

Un `&[T]` générique exige que chaque élément soit du *même* type concret `T`. Un `Vec<Box<dyn Priced>>` contient des types différents derrière un même objet trait, ce qui est exactement la raison d'être du dispatch dynamique. Pour réutiliser `cheapest` sur le panier, `T` devrait être `Box<dyn Priced>` — ce qui fonctionne dès que l'on transmet le trait à la box :

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

3. `impl fmt::Display for Vec<i32>` est rejeté (`E0117`). Affichez une liste de scores sous la forme `"3 scores: 12, 7, 30"` en utilisant plutôt un newtype.

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

`Scores` est un type local, donc implémenter pour lui le trait étranger `Display` est autorisé. Tout type qui implémente `Display` obtient aussi `to_string()`.

</details>

## Sources

- [The Book, ch. 10.2 — Traits: Defining Shared Behavior](https://doc.rust-lang.org/book/ch10-02-traits.html)
- [The Book, ch. 18.2 — Using Trait Objects That Allow for Values of Different Types](https://doc.rust-lang.org/book/ch18-02-trait-objects.html)
- [The Rust Reference — Orphan rules](https://doc.rust-lang.org/reference/items/implementations.html#orphan-rules)
- [The Rust Reference — Dyn compatibility](https://doc.rust-lang.org/reference/items/traits.html#dyn-compatibility)
