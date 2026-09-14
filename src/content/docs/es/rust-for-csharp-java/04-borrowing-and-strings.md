---
title: 4. Préstamos y cadenas
description: Referencias compartidas y mutables, las reglas de préstamo, slices, y String frente a &str.
sidebar:
  order: 4
---

Ejemplo completo: [`examples/l04_borrowing.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l04_borrowing.rs) — `cargo run --example l04_borrowing`.

## Tomar prestado en lugar de mover

La [lección 3](../03-ownership-and-moves/) terminó con una función que «robaba» su argumento. La mayoría de las veces solo quieres *consultar* un valor: pasa una **referencia** con `&`.

De [`examples/l04_borrowing.rs`, líneas 1-3](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L1-L3), [16-19](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L16-L19):

```rust
fn word_count(text: &str) -> usize {
    text.split_whitespace().count()
}

let title = String::from("the rust programming language");
println!("{} words", word_count(&title));   // 4 words
println!("{title}");                        // title sigue siendo utilizable
```

Una referencia **toma prestado** el valor: el propietario conserva la propiedad, y el préstamo debe terminar antes de que el propietario desaparezca.

## Dos tipos de referencias

| | Sintaxis | Cuántas a la vez | Puede modificar |
|---|---|---|---|
| Referencia compartida | `&T` | cualquier cantidad | no |
| Referencia mutable | `&mut T` | exactamente una, y ninguna compartida | sí |

De [`examples/l04_borrowing.rs`, líneas 5-8](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L5-L8), [22-24](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L22-L24):

```rust
fn shout(text: &mut String) {
    text.make_ascii_uppercase();
    text.push('!');
}

let mut message = String::from("hello");
shout(&mut message);
println!("{message}");   // HELLO!
```

Quien llama escribe `&mut` en el punto de la llamada — como con la [palabra clave `ref`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/ref) de C#, la mutación es visible donde ocurre. Java no tiene equivalente: cualquier método que tenga una referencia puede modificar el objeto.

## La regla: compartida XOR mutable

En cada momento puedes tener **o bien** muchos lectores **o bien** un único escritor — nunca ambos. El compilador lo comprueba; es lo que se llama el **borrow checker** (verificador de préstamos).

De [`src/lib.rs`, líneas 134-137](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L134-L137):

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

No es pedantería. [`push`](https://doc.rust-lang.org/std/vec/struct.Vec.html#method.push) puede reasignar el buffer del vector, lo que dejaría a `first` apuntando a memoria liberada. En C#/Java el GC mantiene vivo el objeto antiguo, así que este error concreto no provoca un fallo — pero la *misma regla* atrapa un error que conoces bien.

## Ya te has encontrado con este error

```java
// Java
for (Integer n : numbers) {
    numbers.add(n * 2);   // ConcurrentModificationException en tiempo de ejecución
}
```

```csharp
// C#
foreach (var n in numbers) {
    numbers.Add(n * 2);   // InvalidOperationException: Collection was modified
}
```

En Rust, no pasa del compilador ([`src/lib.rs`, líneas 143-146](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L143-L146)):

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

La solución es la misma que en C#/Java — terminar de leer y luego escribir ([líneas 46-49](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L46-L49)):

```rust
let mut numbers = vec![1, 2, 3];
let doubled: Vec<i32> = numbers.iter().map(|n| n * 2).collect();
numbers.extend(doubled);
println!("{numbers:?}");   // [1, 2, 3, 2, 4, 6]
```

## Sin referencias colgantes

Una referencia nunca puede vivir más que aquello a lo que apunta ([`src/lib.rs`, líneas 152-155](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L152-L155)):

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

`text` se libera cuando la función retorna, así que una referencia a su contenido quedaría colgando. Devuelve en su lugar un [`String`](https://doc.rust-lang.org/std/string/struct.String.html) en propiedad. (Los tiempos de vida (lifetimes) — la sintaxis `'a` que menciona el error — tienen su propia lección, la 9.)

## Slices

Un **slice** toma prestada una parte contigua de una colección sin copiarla ([líneas 31-34](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L31-L34)):

```rust
let mut scores = vec![90, 72, 85];
scores.push(60);
let top_two = &scores[..2];      // &[i32]
println!("top two: {top_two:?}");  // top two: [90, 72]
```

Piensa en [`Span<T>`](https://learn.microsoft.com/dotnet/api/system.span-1) / [`ReadOnlySpan<T>`](https://learn.microsoft.com/dotnet/api/system.readonlyspan-1) en C#, o en [`List.subList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html#subList(int,int)) en Java — pero comprobado en tiempo de compilación, de modo que nunca puede vivir más que el vector.

## `String` frente a `&str`

Este es el tropiezo más habitual, y los slices lo explican:

| | `String` | `&str` |
|---|---|---|
| Qué es | un buffer UTF-8 en propiedad que puede crecer | un slice prestado de texto UTF-8 |
| Dónde viven los bytes | en el montón, propiedad de este valor | en cualquier parte: un `String`, el binario (literales), … |
| Puede crecer | sí (`push_str`, `push`) | no |
| Analogía en C# | un [`StringBuilder`](https://learn.microsoft.com/dotnet/api/system.text.stringbuilder) que te pertenece | `ReadOnlySpan<char>` / un [`string`](https://learn.microsoft.com/dotnet/api/system.string) que no te pertenece |
| Uso típico | campos de structs, valores de retorno | parámetros de funciones |

- Los literales de cadena como `"hello"` son [`&str`](https://doc.rust-lang.org/std/primitive.str.html) (`&'static str`: viven en el binario).
- `&String` se convierte automáticamente en `&str`, así que **los parámetros normalmente deberían ser `&str`** — entonces aceptan ambos ([líneas 10-12](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L10-L12), [27-28](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L27-L28)):

```rust
fn first_word(text: &str) -> &str {
    text.split_whitespace().next().unwrap_or("")
}

println!("{}", word_count("a literal works too"));   // 4
println!("first word: {}", first_word(&title));      // first word: the
```

## Las cadenas son UTF-8, no arrays de caracteres

En C# y Java, `s[0]` / [`s.charAt(0)`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html#charAt(int)) devuelve una unidad UTF-16. Rust se niega a indexar una cadena por posición ([`src/lib.rs`, líneas 161-162](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L161-L162)):

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

Como los caracteres ocupan de 1 a 4 bytes en UTF-8, «el n-ésimo carácter» es un recorrido O(n), y Rust lo hace explícito ([líneas 37-43](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L37-L43)):

```rust
let word = "café";
println!("{} bytes, {} chars, first 3 bytes: {}", word.len(), word.chars().count(), &word[..3]);
// 5 bytes, 4 chars, first 3 bytes: caf
```

Cortar por un rango de bytes funciona, pero entra en pánico si cortas por la mitad de un carácter:

```text
thread 'main' panicked at e_slice_boundary.rs:3:25:
byte index 4 is not a char boundary; it is inside 'é' (bytes 3..5) of `café`
```

## Construir cadenas

De [`examples/l04_borrowing.rs`, líneas 52-56](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l04_borrowing.rs#L52-L56):

```rust
let mut log = String::new();
for (i, s) in ["alpha", "beta"].iter().enumerate() {
    log.push_str(&format!("{i}:{s} "));
}
println!("{}", log.trim_end());   // 0:alpha 1:beta
```

[`format!`](https://doc.rust-lang.org/std/macro.format.html) funciona como [`string.Format`](https://learn.microsoft.com/dotnet/api/system.string.format) / [`String.format`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html#format(java.lang.String,java.lang.Object...)) (y como la [interpolación](https://learn.microsoft.com/dotnet/csharp/language-reference/tokens/interpolated) de C#, con `{name}` dentro del literal).

## Puntos clave

- `&T` toma prestado para leer, `&mut T` toma prestado para escribir; el propietario conserva la propiedad.
- Muchos préstamos compartidos **o** un único préstamo mutable — la regla que también detecta «colección modificada durante la iteración» en tiempo de compilación.
- Las referencias nunca pueden quedar colgando; devuelve valores en propiedad cuando los datos se crean dentro de una función.
- Recibe `&str` en los parámetros y guarda `String` en los structs; las cadenas son UTF-8, así que itera con [`.chars()`](https://doc.rust-lang.org/std/primitive.str.html#method.chars) en lugar de indexar.

## Ejercicios

1. Corrige la firma para que esto compile sin clonar, y explica por qué tu versión es más flexible:

```rust
fn is_shouting(text: String) -> bool {
    text.chars().any(|c| c.is_alphabetic()) && text == text.to_uppercase()
}

let msg = String::from("HELLO");
if is_shouting(msg) { println!("{msg} is shouting"); }
```

<details>
<summary>Solución</summary>

De [`src/lib.rs`, líneas 168-174](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L168-L174):

```rust
fn is_shouting(text: &str) -> bool {
    text.chars().any(|c| c.is_alphabetic()) && text == text.to_uppercase()
}

let msg = String::from("HELLO");
if is_shouting(&msg) { println!("{msg} is shouting"); }
```

Tomar prestado deja `msg` en propiedad de quien llama, y `&str` también acepta literales (`is_shouting("hi")`) y slices.

</details>

2. Esto compila en C# y se ejecuta sin problemas. ¿Por qué Rust rechaza el equivalente y cómo lo corriges?

```csharp
var names = new List<string> { "Ada" };
var first = names[0];
names.Add("Grace");
Console.WriteLine(first);
```

<details>
<summary>Solución</summary>

En C#, `first` guarda una referencia al objeto cadena, que el GC mantiene vivo aunque la lista se reasigne. En Rust, `&names[0]` apunta *dentro* del buffer del vector, que `push` puede reasignar, así que el borrow checker prohíbe la mutación mientras el préstamo siga vivo (`E0502`). Soluciones: usar `first` antes del `push`, o tomar una copia en propiedad con `let first = names[0].clone();`.

</details>

3. Escribe `fn initials(full_name: &str) -> String` que devuelva `"A.L."` para `"Ada Lovelace"`, manejando correctamente los nombres que empiezan por letras no ASCII como `"Émile Zola"`.

<details>
<summary>Solución</summary>

De [`src/lib.rs`, líneas 189-197](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L189-L197):

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

`chars().next()` toma el primer *carácter*, no el primer byte, así que `É` (2 bytes en UTF-8) se maneja correctamente.

</details>

## Fuentes

- [The Book, ch. 4.2 — References and Borrowing](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html)
- [The Book, ch. 4.3 — The Slice Type](https://doc.rust-lang.org/book/ch04-03-slices.html)
- [The Book, ch. 8.2 — Storing UTF-8 Encoded Text with Strings](https://doc.rust-lang.org/book/ch08-02-strings.html)
