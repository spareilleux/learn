---
title: 7. Traits y genéricos
description: Las interfaces se convierten en traits — despacho estático y dinámico, restricciones, traits estándar y métodos de extensión.
sidebar:
  order: 7
---

Ejemplo completo: [`examples/l07_traits_generics.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l07_traits_generics.rs) — `cargo run --example l07_traits_generics`.

## Un trait es una interfaz

```rust
trait Shape {
    fn area(&self) -> f64;

    fn name(&self) -> String {        // método por defecto
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
    // conserva el name() por defecto
}
```

| Rust | C# | Java |
|---|---|---|
| `trait Shape { … }` | `interface IShape { … }` | `interface Shape { … }` |
| método por defecto en el trait | [método de interfaz predeterminado](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interface-implementation/default-interface-methods-versions) (C# 8) | [método `default`](https://docs.oracle.com/javase/tutorial/java/IandI/defaultmethods.html) (Java 8) |
| `impl Shape for Circle { … }` — un bloque aparte | `class Circle : IShape` | `class Circle implements Shape` |
| sin herencia entre structs | herencia de clases | herencia de clases |

La implementación vive en su propio bloque `impl`, no en la declaración del tipo. Ese detalle importa: permite implementar un trait para un tipo **a posteriori**, incluso para un tipo que no escribiste tú (consulta *métodos de extensión* más abajo).

Omitir un método obligatorio es un error de compilación:

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

## Genéricos con restricciones de trait

Una función genérica debe decir qué traits implementa su parámetro de tipo — el equivalente de [`where T : IShape`](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters) o de [`<T extends Shape>`](https://docs.oracle.com/javase/tutorial/java/generics/bounded.html):

```rust
fn total_area<T: Shape>(shapes: &[T]) -> f64 {
    shapes.iter().map(|s| s.area()).sum()
}

let circles = [Circle { radius: 1.0 }, Circle { radius: 2.0 }];
println!("total circle area = {:.2}", total_area(&circles));   // 15.71
```

Sin la restricción (bound), Rust no supone nada sobre `T`:

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

Otras dos formas de escribir la misma idea:

```rust
// `impl Trait` en posición de argumento: atajo para un parámetro genérico
fn describe(shape: &impl Shape) -> String {
    format!("{} has area {:.2}", shape.name(), shape.area())
}

// cláusula `where`: más legible con varias restricciones
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

## Despacho estático frente a dinámico

`total_area::<Circle>` y `total_area::<Square>` se compilan como **dos funciones distintas**, cada una de las cuales llama directamente a `area` y puede insertarse en línea (inlining). Esto se llama [**monomorfización**](https://doc.rust-lang.org/book/ch10-01-syntax.html#performance-of-code-using-generics) (monomorphization).

Cuando necesitas una colección de tipos *distintos*, usa un [**objeto trait**](https://doc.rust-lang.org/reference/types/trait-object.html) (trait object), `dyn Shape`, detrás de un puntero como [`Box`](https://doc.rust-lang.org/std/boxed/struct.Box.html) o `&`:

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

| | Genéricos `T: Shape` | Objeto trait `dyn Shape` |
|---|---|---|
| Se resuelve | en tiempo de compilación | en tiempo de ejecución, mediante una vtable |
| Tipos mezclados en un mismo `Vec` | no | sí |
| Coste | ninguno en tiempo de ejecución, binario más grande | una llamada indirecta, como una llamada a través de una interfaz |
| Analogía en C# | genéricos sobre `struct` (especializados por el JIT) | llamada a través de `IShape` |
| Analogía en Java | — (los genéricos se [borran](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html) y quedan en casts) | llamada a través de `Shape` |

Usa genéricos por defecto; recurre a `dyn Trait` cuando de verdad necesites valores heterogéneos o quieras ocultar el tipo concreto. No todos los traits se pueden usar como `dyn`: un trait con métodos genéricos, por ejemplo, no es *dyn-compatible* (antes llamado «object-safe»).

## Traits estándar que implementas

Gran parte de lo que C# pone en [`System.Object`](https://learn.microsoft.com/dotnet/api/system.object) o en los operadores es un trait en Rust:

| Trait de Rust | C# | Java | Normalmente |
|---|---|---|---|
| `Debug` | visualización en el depurador | — | [`#[derive(Debug)]`](https://doc.rust-lang.org/reference/attributes/derive.html) |
| [`Display`](https://doc.rust-lang.org/std/fmt/trait.Display.html) | `ToString()` | `toString()` | implementado a mano |
| `Clone` | [`ICloneable`](https://learn.microsoft.com/dotnet/api/system.icloneable) | `clone()` | derivado |
| `PartialEq` / `Eq` | `Equals` / `==` | `equals` | derivado |
| `Hash` | `GetHashCode` | `hashCode` | derivado |
| [`PartialOrd`](https://doc.rust-lang.org/std/cmp/trait.PartialOrd.html) / `Ord` | [`IComparable<T>`](https://learn.microsoft.com/dotnet/api/system.icomparable-1) | [`Comparable<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Comparable.html) | derivado |
| `Default` | constructor sin parámetros | constructor sin argumentos | derivado |
| [`From`](https://doc.rust-lang.org/std/convert/trait.From.html) / `Into` | operadores de conversión | fábrica estática | implementado a mano |
| `Add`, `Mul`, … | [`operator +`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/operator-overloading) | — | implementado a mano |

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
let also: Celsius = Fahrenheit(212.0).into();   // Into viene gratis con From
println!("{body} / {also} / default {}", Celsius::default());
// 37.0°C / 100.0°C / default 0.0°C
```

## Métodos de extensión, al estilo de Rust

En C#, un [método de extensión](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/extension-methods) añade `Shout()` a `string`. En Rust, defines un trait y lo implementas para el tipo existente:

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

Como con el `using` de C# para los métodos de extensión, el trait debe estar en el ámbito (`use`) allí donde lo llamas.

### La regla del huérfano

Puedes implementar **tu** trait para cualquier tipo, o **cualquier** trait para tu tipo — pero no el trait de otro para el tipo de otro:

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

Esto garantiza que dos crates nunca puedan proporcionar implementaciones en conflicto. La solución habitual es el **newtype** de la lección 5: envolver el tipo ajeno en tu propio struct.

## Puntos clave

- Los traits son interfaces con métodos por defecto, implementadas en bloques `impl` aparte.
- El código genérico debe declarar lo que necesita mediante restricciones (`T: Shape`, [`impl Shape`](https://doc.rust-lang.org/reference/types/impl-trait.html), `where`).
- Los genéricos se resuelven en tiempo de compilación; `dyn Trait` ofrece polimorfismo en tiempo de ejecución cuando necesitas tipos mezclados.
- `Display`, `Clone`, `PartialEq`, `Default` y `From` sustituyen a `ToString`, `ICloneable`, `Equals`, los constructores y las conversiones.
- Implementar un trait para un tipo existente sustituye a los métodos de extensión, dentro de los límites de la regla del huérfano.

## Ejercicios

1. Define un trait `Priced` con `fn price(&self) -> f64` y un método por defecto `fn price_with_tax(&self, rate: f64) -> f64`. Impleméntalo para `Book { title: String, price: f64 }` y escribe `fn cheapest<T: Priced>(items: &[T]) -> Option<&T>`.

<details>
<summary>Solución</summary>

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

Se usa `total_cmp` porque `f64` no tiene un orden total (`NaN`), así que `min_by_key` no se puede usar directamente con flotantes.

</details>

2. Añade `struct Coffee { size_ml: u32 }` con un precio de `0.01` por ml. Escribe `fn total(items: &[Box<dyn Priced>]) -> f64` sobre un vector que mezcle libros y cafés. ¿Por qué `cheapest` del ejercicio 1 no puede recibir ese mismo vector como `&[T]` con `T = Book`?

<details>
<summary>Solución</summary>

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

Un `&[T]` genérico exige que todos los elementos sean del *mismo* tipo concreto `T`. Un `Vec<Box<dyn Priced>>` contiene tipos distintos detrás de un mismo objeto trait, que es justo para lo que sirve el despacho dinámico. Para reutilizar `cheapest` con la cesta, `T` tendría que ser `Box<dyn Priced>` — lo cual funciona en cuanto reenvías el trait a la caja:

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

3. `impl fmt::Display for Vec<i32>` se rechaza (`E0117`). Imprime una lista de puntuaciones con la forma `"3 scores: 12, 7, 30"` usando en su lugar un newtype.

<details>
<summary>Solución</summary>

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

`Scores` es un tipo local, así que está permitido implementar para él el trait ajeno `Display`. Todo tipo que implementa `Display` obtiene también `to_string()`.

</details>

## Fuentes

- [The Book, ch. 10.2 — Traits: Defining Shared Behavior](https://doc.rust-lang.org/book/ch10-02-traits.html)
- [The Book, ch. 18.2 — Using Trait Objects That Allow for Values of Different Types](https://doc.rust-lang.org/book/ch18-02-trait-objects.html)
- [The Rust Reference — Orphan rules](https://doc.rust-lang.org/reference/items/implementations.html#orphan-rules)
- [The Rust Reference — Dyn compatibility](https://doc.rust-lang.org/reference/items/traits.html#dyn-compatibility)
