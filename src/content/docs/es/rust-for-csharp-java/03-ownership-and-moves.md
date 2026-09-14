---
title: 3. Ownership y movimientos
description: Lo que sustituye al recolector de basura — propietarios, movimientos, Copy, clone y Drop.
sidebar:
  order: 3
---

Ejemplo completo: [`examples/l03_ownership.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l03_ownership.rs) — `cargo run --example l03_ownership`.

## El problema que resuelve un GC

En C# y Java, los objetos viven en el montón (heap) y varias variables pueden apuntar al mismo objeto. Nadie lo «posee»: el **recolector de basura** (garbage collector) lo libera en algún momento después de que desaparezca la última referencia.

Es cómodo, pero cuesta un runtime, pausas y memoria de margen — y solo gestiona la memoria: los archivos, los sockets y los locks siguen necesitando [`using`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/using) / [`IDisposable`](https://learn.microsoft.com/dotnet/api/system.idisposable) o [try-with-resources](https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html).

Rust no tiene GC. En su lugar, el compilador impone reglas de **propiedad (ownership)** e inserta él mismo el código de limpieza, en tiempo de compilación.

## Las tres reglas

1. Cada valor tiene exactamente **un propietario** (una variable, un campo, un elemento de una colección…).
2. Cuando el propietario sale de su ámbito, el valor se **libera** (drop).
3. La propiedad se puede **mover** a otro propietario; el propietario anterior ya no se puede usar.

## Movimientos (moves)

De [`examples/l03_ownership.rs`, líneas 21-23](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L21-L23):

```rust
let a = String::from("hello");
let b = a;             // la propiedad del buffer del montón pasa a b
println!("b = {b}");   // b = hello
```

En C#, `var b = a;` copia una *referencia*: `a` y `b` apuntan ahora a la misma cadena, y ambas siguen siendo utilizables. En Rust, `a` **ya no existe** ([`src/lib.rs`, líneas 61-63](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L61-L63)):

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

¿Por qué? Si `a` y `b` poseyeran ambos el buffer, ambos lo liberarían al final del ámbito — una doble liberación. El movimiento hace que «quién libera esto» no sea ambiguo.

## `clone` — una copia profunda explícita

De [`examples/l03_ownership.rs`, líneas 26-27](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L26-L27):

```rust
let c = b.clone();
println!("b = {b}, c = {c}");   // b = hello, c = hello
```

[`clone()`](https://doc.rust-lang.org/std/clone/trait.Clone.html) duplica los datos del montón. Siempre es visible en el código, así que las copias costosas nunca ocurren por accidente.

## Los tipos `Copy`

Los valores pequeños que viven por completo en la pila se **copian** en lugar de moverse ([líneas 30-32](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L30-L32)):

```rust
let x = 5;
let y = x;
println!("x = {x}, y = {y}");   // x = 5, y = 5
```

Los enteros, los flotantes, `bool`, `char`, y las tuplas y arrays formados por ellos son `Copy`. Se parece a los tipos de valor de C# ([`struct`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/struct)) — pero en Rust *tus propios* structs se mueven por defecto y solo pasan a ser `Copy` si lo pides con [`#[derive(Clone, Copy)]`](https://doc.rust-lang.org/book/appendix-03-derivable-traits.html).

| | C# | Java | Rust |
|---|---|---|---|
| `b = a` con un objeto del montón | ambos referencian el mismo objeto | ambos referencian el mismo objeto | **movimiento**: `a` inutilizable |
| `b = a` con un `int` | copia | copia | copia (tipo `Copy`) |
| copia profunda explícita | [`ICloneable`](https://learn.microsoft.com/dotnet/api/system.icloneable), constructor de copia | [`clone()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Object.html#clone()), constructor de copia | `.clone()` |

## Las funciones también toman la propiedad

Pasar un [`String`](https://doc.rust-lang.org/std/string/struct.String.html) por valor lo mueve a la función ([`src/lib.rs`, líneas 69-75](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L69-L75)):

```rust
fn take(s: String) -> usize {
    s.len()
} // s se libera aquí

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

El compilador ya señala la verdadera solución: *tomar prestado* en lugar de tomar la propiedad. Ese es el tema de la [lección 4](../04-borrowing-and-strings/).

Devolver un valor devuelve la propiedad a quien llama ([líneas 15-17](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L15-L17), [38](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L38)):

```rust
fn make_greeting(name: &str) -> String {
    format!("Hello, {name}!")
}

let greeting = make_greeting("Ferris");   // greeting posee el nuevo String
```

## `Drop` — limpieza determinista

Cuando un propietario sale de su ámbito, Rust llama a `drop`, en orden **inverso** al de declaración. Puedes engancharte a ello implementando el trait `Drop` ([líneas 1-9](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L1-L9), [19](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L19), [42-55](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l03_ownership.rs#L42-L55)):

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
| Memoria | GC, no determinista | GC, no determinista | se libera al final del ámbito del propietario |
| Archivos, sockets, locks | `using` + `IDisposable` | try-with-resources + [`AutoCloseable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/AutoCloseable.html) | el mismo `Drop`, automáticamente |
| Olvidar la limpieza | fuga hasta el [finalizador](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/finalizers) (quizá) | fuga hasta el finalizador (quizá) | la limpieza se ejecuta automáticamente; una fuga requiere un [`std::mem::forget`](https://doc.rust-lang.org/std/mem/fn.forget.html) explícito o un ciclo de referencias (lección 11) |

Este patrón — adquirir en un constructor, liberar en `Drop` — es como funcionan [`File`](https://doc.rust-lang.org/std/fs/struct.File.html), [`MutexGuard`](https://doc.rust-lang.org/std/sync/struct.MutexGuard.html) y las conexiones de red en Rust. No hay palabra clave `using` porque cada ámbito ya se comporta como uno.

## Puntos clave

- Un propietario por valor; el valor se libera cuando el propietario sale de su ámbito.
- Asignar o pasar un valor que no es `Copy` lo **mueve**; la variable anterior queda inutilizable.
- `.clone()` es la copia profunda explícita y visible.
- `Drop` ofrece una limpieza determinista para la memoria *y* los recursos, como un `using` automático.

## Ejercicios

1. ¿Qué líneas compilan? Explica cada una.

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
<summary>Solución</summary>

1. Compila: `i32` es `Copy`, así que `b` recibe una copia y `a` sigue siendo utilizable.
2. No compila (`E0382`): `String` no es `Copy`, así que `s` se movió a `t`.
3. Compila: `clone()` crea un `String` independiente, así que ambos siguen siendo válidos.

</details>

2. Reescribe este método de Java para que la versión en Rust no necesite `clone()`:

```java
static int countVowels(String text) { /* … */ }
// se llama así: countVowels(name); System.out.println(name);
```

<details>
<summary>Solución</summary>

Recibe un slice de cadena prestado en lugar de un `String` en propiedad, para que quien llama conserve la propiedad (se explica en la lección 4) ([`src/lib.rs`, líneas 99-104](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L99-L104)):

```rust
fn count_vowels(text: &str) -> usize {
    text.chars().filter(|c| "aeiouAEIOU".contains(*c)).count()
}

let name = String::from("Ferris");
let n = count_vowels(&name);
println!("{name}: {n} vowels");
```

</details>

3. ¿En qué orden se liberan `a`, `b` y `c`?

```rust
let a = TempFile { name: "a".into() };
let b = TempFile { name: "b".into() };
let c = TempFile { name: "c".into() };
drop(b);
println!("done");
```

<details>
<summary>Solución</summary>

Primero `b` (explícitamente, mediante [`std::mem::drop`](https://doc.rust-lang.org/std/mem/fn.drop.html), antes de que se imprima `done`), luego, al final del ámbito, `c` y después `a` — orden inverso al de declaración para los valores que aún tienen propietario.

</details>

## Fuentes

- [The Book, ch. 4.1 — What Is Ownership?](https://doc.rust-lang.org/book/ch04-01-what-is-ownership.html)
- [`Drop` — biblioteca estándar](https://doc.rust-lang.org/std/ops/trait.Drop.html)
- [`Copy` — biblioteca estándar](https://doc.rust-lang.org/std/marker/trait.Copy.html)
