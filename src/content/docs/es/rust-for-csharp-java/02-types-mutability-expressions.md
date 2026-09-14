---
title: 2. Tipos, mutabilidad y expresiones
description: let y mut, tipos numéricos, ninguna conversión implícita, y todo es una expresión.
sidebar:
  order: 2
---

Ejemplo completo: [`examples/l02_types.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l02_types.rs) — ejecútalo con `cargo run --example l02_types`.

## Inmutable por defecto

De [`examples/l02_types.rs`, líneas 3-5](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L3-L5):

```rust
let answer = 42;            // inferido como i32, no puede cambiar
let mut counter: u32 = 0;   // explícitamente mutable
counter += 1;
```

En términos de C#, cada `let` es como una variable local que nunca puedes reasignar; en Java, como [`final var`](https://openjdk.org/jeps/286). La mutabilidad se **elige** con `mut` ([`src/lib.rs`, líneas 10-11](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L10-L11)):

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

:::tip[Lee el error completo]
Los errores de Rust suelen contener la solución (`help: consider making this binding mutable`). Acostúmbrate a leerlos hasta el final — y [`rustc --explain E0384`](https://doc.rust-lang.org/rustc/command-line-arguments.html#--explain-provide-a-detailed-explanation-of-an-error-message) da una explicación completa.
:::

## Sombreado (shadowing)

Puedes declarar una variable nueva con el mismo nombre, incluso con otro tipo. Resulta práctico para «analizar y reemplazar» ([líneas 9-11](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L9-L11)):

```rust
let input = "  7 ";
let input: i32 = input.trim().parse().expect("not a number");
println!("input + 1 = {}", input + 1); // input + 1 = 8
```

Esto no es una mutación: el primer `input` (un [`&str`](https://doc.rust-lang.org/std/primitive.str.html)) sigue existiendo, simplemente queda oculto. C# y Java prohíben volver a declarar una variable local en el mismo ámbito.

## Tipos escalares

| Rust | C# | Java | Notas |
|---|---|---|---|
| `i8` / `u8` | `sbyte` / `byte` | `byte` (con signo) / — | Java no tiene enteros sin signo |
| `i16` / `u16` | `short` / `ushort` | `short` / — | |
| `i32` / `u32` | `int` / `uint` | `int` / — | `i32` es el entero por defecto |
| `i64` / `u64` | `long` / `ulong` | `long` / — | |
| `i128` / `u128` | [`Int128`](https://learn.microsoft.com/dotnet/api/system.int128) / `UInt128` | — | |
| `isize` / `usize` | [`nint` / `nuint`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/integral-numeric-types#native-sized-integers) | — | del tamaño de un puntero; se usan para índices y longitudes |
| `f32` / `f64` | `float` / `double` | `float` / `double` | `f64` es el flotante por defecto |
| `bool` | `bool` | `boolean` | |
| `char` | [`Rune`](https://learn.microsoft.com/dotnet/api/system.text.rune) | punto de código `int` | **4 bytes**, un valor escalar Unicode — *no* una unidad UTF-16 como el `char` de C#/Java |

De [`examples/l02_types.rs`, líneas 28-33](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L28-L33):

```rust
let note = '♪';
println!("{note} is {} bytes in UTF-8, size_of::<char>() = {}", note.len_utf8(), std::mem::size_of::<char>());
// ♪ is 3 bytes in UTF-8, size_of::<char>() = 4
```

## Ninguna conversión implícita

C# y Java amplían en silencio un `int` a `long`. Rust nunca convierte números por ti ([`src/lib.rs`, líneas 18-20](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L18-L20)):

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

Convierte explícitamente con [`as`](https://doc.rust-lang.org/reference/expressions/operator-expr.html#type-cast-expressions) (o con [`i64::from(small)`](https://doc.rust-lang.org/std/convert/trait.From.html), que solo existe para las conversiones sin pérdida) ([línea 16](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L16)):

```rust
let total = small as i64 + big; // 30
```

## El desbordamiento es un error, no una característica

| | C# | Java | Rust, compilación debug | Rust, compilación release |
|---|---|---|---|---|
| `255u8 + 1` | da la vuelta (salvo con [`checked`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/checked-and-unchecked)) | da la vuelta | **[entra en pánico](https://doc.rust-lang.org/book/ch09-01-unrecoverable-errors-with-panic.html)** | da la vuelta |

En una compilación debug, Rust detiene el programa:

```text
thread 'main' panicked at e_overflow.rs:3:16:
attempt to add with overflow
```

Cuando dar la vuelta o fallar es el comportamiento que buscas, dilo explícitamente ([líneas 20-25](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L20-L25)):

```rust
let max = u8::MAX;
println!("checked: {:?}, wrapping: {}", max.checked_add(1), max.wrapping_add(1));
// checked: None, wrapping: 0
```

## Tuplas y arrays

De [`examples/l02_types.rs`, líneas 36-43](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L36-L43):

```rust
let point: (f64, f64) = (1.5, -2.0);
let (x, y) = point;              // desestructuración, como la deconstrucción de tuplas en C#
let primes = [2, 3, 5, 7, 11];   // array de tamaño fijo: [i32; 5]
println!("x = {x}, y = {y}, first prime = {}, count = {}", primes[0], primes.len());
// x = 1.5, y = -2, first prime = 2, count = 5
```

Una lista que puede crecer es un [`Vec<T>`](https://doc.rust-lang.org/std/vec/struct.Vec.html) (como [`List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1) / [`ArrayList<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/ArrayList.html)) — la lección 8 trata las colecciones.

## Todo es una expresión

`if` devuelve un valor, así que no hay operador ternario ([línea 46](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L46)):

```rust
let parity = if answer % 2 == 0 { "even" } else { "odd" };
```

Un bloque `{ … }` se evalúa a su última expresión — **sin** punto y coma ([líneas 50-54](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L50-L54)):

```rust
let area = {
    let width = 3;
    let height = 4;
    width * height   // sin `;` → este es el valor del bloque
};
```

Las funciones funcionan igual; `return` solo hace falta para salir antes de tiempo ([líneas 78-80](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l02_types.rs#L78-L80)):

```rust
fn square(x: i32) -> i32 {
    x * x
}
```

:::caution[El punto y coma importa]
Escribir `x * x;` convierte la expresión en una sentencia: la función devuelve entonces [`()`](https://doc.rust-lang.org/std/primitive.unit.html) (el tipo unidad, el `void` de Rust) y el compilador se queja de que los tipos no coinciden.
:::

## Bucles

```rust
// loop + break con un valor
let mut n = 1;
let first_power_over_100 = loop {
    n *= 2;
    if n > 100 {
        break n;
    }
};                                   // 128

// for sobre rangos: 0..3 excluye el final, 1..=10 lo incluye
for i in 0..3 {
    print!("{i} ");                  // 0 1 2
}
let sum: i32 = (1..=10).sum();       // 55
```

No existe el `for (int i = 0; i < n; i++)` al estilo de C: usa un rango. También existe `while condition { … }`.

## Puntos clave

- `let` es inmutable; añade `mut` solo cuando lo necesites.
- Los tipos numéricos son explícitos, las conversiones son explícitas y el desbordamiento provoca un pánico en debug.
- `char` es un valor escalar Unicode (4 bytes), no UTF-16.
- `if`, los bloques, `loop` y las funciones son expresiones; la última expresión sin `;` es el valor.

## Ejercicios

1. Escribe una función `clamp_percent(value: i32) -> u8` que devuelva `0` para los valores negativos, `100` para los valores mayores que 100 y el propio valor en los demás casos — usando `if` como expresión.

<details>
<summary>Solución</summary>

De [`src/lib.rs`, líneas 26-34](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L26-L34):

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

El `as u8` es seguro aquí porque se sabe que el valor está dentro de `0..=100`. Rust también ofrece `value.clamp(0, 100) as u8`.

</details>

2. ¿Por qué esta función no compila y cuál es la corrección de un solo carácter?

De [`src/lib.rs`, líneas 44-46](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L44-L46):

```rust
fn double(x: i32) -> i32 {
    x * 2;
}
```

<details>
<summary>Solución</summary>

El punto y coma final convierte `x * 2` en una sentencia, así que el cuerpo se evalúa a `()` en lugar de `i32` (error `E0308: mismatched types`). Quita el `;`.

</details>

3. En C#, `byte b = 255; b++;` da `0`. ¿Qué ocurre en Rust con `let mut b: u8 = 255; b += 1;`?

<details>
<summary>Solución</summary>

En una compilación debug, el programa entra en pánico con `attempt to add with overflow`. En una compilación release, da la vuelta a `0`. Si lo que quieres es dar la vuelta, escribe `b = b.wrapping_add(1);`; si quieres detectarlo, usa [`b.checked_add(1)`](https://doc.rust-lang.org/std/primitive.u8.html#method.checked_add), que devuelve un [`Option<u8>`](https://doc.rust-lang.org/std/option/enum.Option.html).

</details>

## Fuentes

- [The Book, ch. 3 — Common Programming Concepts](https://doc.rust-lang.org/book/ch03-00-common-programming-concepts.html)
- [The Rust Reference — Integer overflow](https://doc.rust-lang.org/reference/expressions/operator-expr.html#overflow)
- [`char` — biblioteca estándar](https://doc.rust-lang.org/std/primitive.char.html)
