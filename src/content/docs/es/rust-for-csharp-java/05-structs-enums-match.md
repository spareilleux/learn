---
title: 5. Structs, enums y pattern matching
description: Sustituir clases, records y jerarquías selladas por struct, enum, impl y un match exhaustivo.
sidebar:
  order: 5
---

Ejemplo completo: [`examples/l05_structs_enums.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l05_structs_enums.rs) — `cargo run --example l05_structs_enums`.

## Los datos y el comportamiento se declaran por separado

Una clase de C# o Java agrupa campos, constructores y métodos en un solo bloque. Rust los separa: un `struct` declara los datos, y uno o varios bloques `impl` añaden las funciones.

De [`examples/l05_structs_enums.rs`, líneas 4-33](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L4-L33):

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
| `fn new(…) -> Self` (una convención) | constructor | constructor |
| `fn balance(&self)` | método de instancia | método de instancia |
| `fn deposit(&mut self, …)` | método que modifica `this` | método que modifica `this` |
| `fn close(self)` | — (sin equivalente) | — |
| `fn new(…)` sin `self` | método `static` | método `static` |
| [`#[derive(Debug, Clone, PartialEq)]`](https://doc.rust-lang.org/reference/attributes/derive.html) | lo que genera un `record`: `ToString`, copia, igualdad por valor | lo que genera un `record` |

- **No hay constructores**: `Account::new` es una función asociada normal que devuelve `Self`. Varios «constructores» no son más que varias funciones (`new`, `with_capacity`, `from_str`…).
- El receptor indica qué hace el método con el valor: leerlo (`&self`), modificarlo (`&mut self`) o **consumirlo** (`self`) — después de `account.close()`, `account` se ha movido y no se puede usar, que es como Rust modela «este objeto ha terminado».
- **No hay herencia** entre structs. El comportamiento compartido va en los traits ([lección 7](../07-traits-and-generics/)).

De [`examples/l05_structs_enums.rs`, líneas 96-104](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L96-L104):

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

Hay que inicializar todos los campos — no existen `null` por defecto:

```text
error[E0063]: missing field `balance_cents` in initializer of `Account`
 --> e05_missing_field.rs:7:19
  |
7 |     let account = Account { owner: String::from("Ada") };
  |                   ^^^^^^^ missing `balance_cents`
```

La **sintaxis de actualización de structs** (struct update syntax) copia los campos restantes de otro valor, como una [expresión `with`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/with-expression) de C# ([líneas 107-111](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L107-L111)):

```rust
let other = Account { owner: "Grace".into(), ..copy };
println!("{} has {} cents", other.owner, other.balance_cents);   // Grace has 1250 cents
```

## Tuple structs y newtypes

Un struct puede tener campos sin nombre. Con un único campo, crea un tipo distinto alrededor de uno existente — un **[newtype](https://doc.rust-lang.org/rust-by-example/generics/new_types.html)** ([líneas 36-37](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L36-L37), [116-118](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L116-L118)):

```rust
#[derive(Debug, Clone, Copy, PartialEq, PartialOrd)]
struct Meters(f64);

let short = Meters(3.5);
let long = Meters(10.0);
println!("{short:?} < {long:?}: {}", short < long);   // Meters(3.5) < Meters(10.0): true
```

Una función que recibe `Meters` no aceptará un `f64` sin más ni un `Feet(f64)`. No cuesta nada en tiempo de ejecución: en memoria, `Meters` es exactamente un `f64`.

## Los enums llevan datos

Los [enums de C#](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/enum) son enteros con nombre; los [enums de Java](https://dev.java/learn/classes-objects/enums/) son un conjunto fijo de objetos que comparten todos los mismos campos. Un `enum` de Rust es una **unión etiquetada** (tagged union): cada variante puede contener datos *diferentes*.

De [`examples/l05_structs_enums.rs`, líneas 41-45](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L41-L45):

```rust
enum Shape {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
    Triangle(f64, f64, f64),
}
```

El equivalente más cercano es una jerarquía cerrada:

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

## `match` es exhaustivo

De [`examples/l05_structs_enums.rs`, líneas 47-59](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L47-L59):

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

Olvida una variante y el programa no compila:

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

| Cuando falta un caso | Resultado |
|---|---|
| [expresión `switch`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression) de C# | advertencia [CS8509](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/pattern-matching-warnings#pattern-completeness-and-redundancy), y luego [`SwitchExpressionException`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.switchexpressionexception) en tiempo de ejecución |
| [`switch`](https://openjdk.org/jeps/441) de Java 21 sobre una [interfaz sellada](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html) | error de compilación |
| `match` de Rust | error de compilación [`E0004`](https://doc.rust-lang.org/error_codes/E0004.html) |

Esto es lo que hace que los enums sean tan útiles para refactorizar: añade una variante y el compilador enumera cada lugar que debe tratarla.

## Patrones

Los patrones desestructuran valores y se pueden refinar ([líneas 139-144](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L139-L144)):

```rust
match command {
    Command::Move { dx, dy: 0 } => println!("horizontal move by {dx}"),   // literal dentro de un patrón
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

Rangos, [guardas](https://doc.rust-lang.org/reference/expressions/match-expr.html#match-guards) (`if`) y el comodín `_` ([líneas 77-85](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L77-L85)):

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

Los brazos se prueban **en orden**, así que pon primero los más específicos — la misma regla que en los patrones de `switch` de C# y Java.

## `if let` y `let … else`

Cuando solo importa un patrón, [`if let`](https://doc.rust-lang.org/book/ch06-03-if-let.html) evita un `match` completo:

```rust
if let Some(Shape::Circle { radius }) = shapes.first() {
    println!("first shape is a circle of radius {radius}");
}
```

[`let … else`](https://doc.rust-lang.org/rust-by-example/flow_control/let_else.html) enlaza un patrón o sale del bloque actual — perfecto para las cláusulas de guarda ([líneas 87-93](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l05_structs_enums.rs#L87-L93)):

```rust
fn parse_port(text: &str) -> u16 {
    let Ok(port) = text.parse::<u16>() else {
        return 8080;
    };
    port
}
// parse_port("3000") == 3000, parse_port("oops") == 8080
```

`Some` y `Ok` son a su vez variantes de enums — el tema de la [próxima lección](../06-option-result/).

## Puntos clave

- `struct` contiene los datos, `impl` añade funciones asociadas y métodos; `new` es una convención, no un constructor.
- `&self`, `&mut self` y `self` indican si un método lee, modifica o consume el valor.
- Las variantes de un `enum` llevan datos distintos: un enum de Rust es una jerarquía sellada de records en una sola declaración.
- `match` debe ser exhaustivo; `if let` y `let … else` cubren los casos de un solo patrón.

## Ejercicios

1. Traduce esta jerarquía de C# a un enum de Rust y escribe `fn describe(payment: &Payment) -> String`, que devuelva `"card ending 4242"`, `"transfer from FR76…"` o `"cash"`.

```csharp
abstract record Payment;
record Card(string Last4) : Payment;
record Transfer(string Iban) : Payment;
record Cash : Payment;
```

<details>
<summary>Solución</summary>

De [`src/lib.rs`, líneas 223-230](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L223-L230):

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

2. Añades `Crypto { wallet: String }` a `Payment`. ¿Qué le pasa a `describe` y por qué es mejor que el comportamiento de C#?

<details>
<summary>Solución</summary>

`describe` deja de compilar con `E0004: non-exhaustive patterns: &Payment::Crypto { .. } not covered`. Cada `match` que debe tratar el nuevo caso se señala en tiempo de compilación, en lugar de una advertencia seguida de una `SwitchExpressionException` en producción. (Si existe un brazo `_ =>`, la nueva variante cae en él en silencio — un motivo para evitar los comodines en los enums que te pertenecen.)

</details>

3. Escribe un `Rectangle { width: f64, height: f64 }` con `fn square(size: f64) -> Self`, `fn area(&self) -> f64` y `fn scale(&mut self, factor: f64)`. Después crea una copia el doble de ancha usando la sintaxis de actualización de structs.

<details>
<summary>Solución</summary>

De [`src/lib.rs`, líneas 249-259](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L249-L259):

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

## Fuentes

- [The Book, ch. 5 — Using Structs to Structure Related Data](https://doc.rust-lang.org/book/ch05-00-structs.html)
- [The Book, ch. 6 — Enums and Pattern Matching](https://doc.rust-lang.org/book/ch06-00-enums.html)
- [The Book, ch. 19 — Patterns and Matching](https://doc.rust-lang.org/book/ch19-00-patterns.html)
