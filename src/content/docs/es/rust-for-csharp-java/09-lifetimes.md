---
title: 9. Tiempos de vida
description: Cómo demuestra el compilador que una referencia nunca sobrevive a su valor — anotaciones, elisión, structs que toman prestado y 'static.
sidebar:
  order: 9
---

Ejemplo completo: [`examples/l09_lifetimes.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l09_lifetimes.rs) — `cargo run --example l09_lifetimes`.

## El problema que oculta un recolector de basura

En C# o en Java, una referencia mantiene vivo su objeto: mientras puedas alcanzarlo, el [recolector de basura](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals) no lo liberará. Una [«referencia colgante»](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html#dangling-references) sencillamente no puede existir.

Rust no tiene recolector de basura. Un valor se libera cuando su propietario sale de ámbito ([lección 3](../03-ownership-and-moves/)), así que el compilador debe demostrar que ninguna referencia sigue en uso en ese momento ([`src/lib.rs`, líneas 474-479](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L474-L479)):

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

El intervalo durante el cual una referencia es válida es su **tiempo de vida (lifetime)**. Dentro de una sola función, el compilador deduce los tiempos de vida por sí mismo — llevas contando con ello desde la lección 4. Solo los escribes cuando una referencia cruza una **frontera de función o de struct** y el compilador no puede adivinar la relación.

:::note[Los tiempos de vida no cambian cuánto vive nada]
Una anotación de tiempo de vida es una *descripción* que el compilador comprueba, no una instrucción. Escribir `'a` nunca mantiene un valor vivo más tiempo, a diferencia de guardar una referencia en C#.
:::

## Anotar una función

¿De qué entrada toma prestado el resultado?

De [`src/lib.rs`, líneas 485-487](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L485-L487):

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

El compilador comprueba cada función **solo por su firma**, nunca por su cuerpo — igual que quien llama a un método en C# solo ve su declaración. Así que la firma tiene que decirlo ([líneas 2-4](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L2-L4)):

```rust
fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}
```

Lee `<'a>` como un [parámetro genérico](https://doc.rust-lang.org/reference/items/generics.html) (se declara en el mismo lugar que `<T>`): *«para algún tiempo de vida `'a` durante el cual `a` y `b` son válidos, el resultado también es válido durante `'a`»*. En la práctica, `'a` pasa a ser el **más corto** de los dos, de modo que quien llama no puede conservar el resultado más tiempo que cualquiera de las entradas ([`src/lib.rs`, líneas 496-502](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L496-L502)):

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

En tiempo de ejecución, `title` es la cadena más larga, así que esto funcionaría por casualidad — pero la firma no promete nada sobre cuál se devuelve, y el compilador te obliga a atenerte a la firma.

Anota solo lo que el resultado toma prestado de verdad. Aquí el resultado viene únicamente de `a`, así que `len_from` no necesita tiempo de vida y puede ser cualquier cosa efímera ([líneas 12-14](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L12-L14)):

```rust
fn prefix_of<'a>(a: &'a str, len_from: &str) -> &'a str {
    &a[..len_from.len().min(a.len())]
}
```

## Elisión: cuándo puedes omitirlos

La mayoría de las funciones nunca mencionan un tiempo de vida, porque tres **reglas de elisión** los completan:

1. Cada parámetro referencia recibe su propio tiempo de vida.
2. Si hay exactamente **un** tiempo de vida de entrada, se usa para todas las referencias de salida.
3. Si uno de los parámetros es `&self` o `&mut self`, se usa **su** tiempo de vida para las salidas.

De [`examples/l09_lifetimes.rs`, líneas 7-9](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L7-L9):

```rust
fn first_word(text: &str) -> &str {     // regla 2: el resultado toma prestado `text`
    text.split_whitespace().next().unwrap_or("")
}
```

`longest` necesitaba una anotación porque tiene dos entradas y ningún `self`: no se aplica ninguna regla.

La elisión nunca hace compilar un programa incorrecto. Cuando las reglas producen un tiempo de vida que no encaja, sigues obteniendo un error — y devolver una referencia a una variable local es siempre un error, anotes lo que anotes ([`src/lib.rs`, líneas 530-533](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L530-L533)):

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

La solución es la de la lección 4: devolver el [`String`](https://doc.rust-lang.org/std/string/struct.String.html) con propietario.

## Structs que toman prestado

Un struct que contiene una referencia debe declarar el tiempo de vida, igual que un parámetro de tipo genérico ([`src/lib.rs`, líneas 508-510](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L508-L510)):

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

De [`examples/l09_lifetimes.rs`, líneas 17-25](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L17-L25), [82-85](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L82-L85):

```rust
struct Excerpt<'a> {
    text: &'a str,
}

impl Excerpt<'_> {                 // '_ : «algún tiempo de vida, no necesito su nombre»
    fn word_count(&self) -> usize {
        self.text.split_whitespace().count()
    }
}

let novel = String::from("Call me Ishmael. Some years ago, never mind how long precisely...");
let excerpt = Excerpt { text: novel.split('.').next().unwrap_or("") };
// excerpt: "Call me Ishmael" (3 words)
```

`Excerpt<'a>` se lee *«un extracto que no puede sobrevivir al texto al que apunta»*. El compilador lo hace cumplir:

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

El equivalente más cercano en C# es un [`ref struct`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct) como [`Span<T>`](https://learn.microsoft.com/dotnet/api/system.span-1): puede apuntar a la memoria de otro, así que el compilador restringe adónde puede ir. En Rust, cualquier struct puede ser así.

### El tiempo de vida en la firma de un método importa

Un tokenizador que devuelve slices de su entrada ([líneas 28-59](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L28-L59)):

```rust
struct Parser<'a> {
    input: &'a str,
    pos: usize,
}

impl<'a> Parser<'a> {
    fn next_token(&mut self) -> Option<&'a str> {
        // … devuelve &self.input[start..end]
    }
}

fn tokenize(line: &str) -> Vec<&str> {
    let mut parser = Parser::new(line);
    let mut tokens = Vec::new();
    while let Some(token) = parser.next_token() {
        tokens.push(token);
    }
    tokens                          // el parser se libera, los tokens sobreviven
}
// tokens: ["let", "x", "=", "42"]
```

El tipo de retorno dice `&'a str`: un token toma prestado el **texto de entrada**, no el parser. Si se hubiera escrito `Option<&str>`, la regla de elisión 3 ataría cada token a `&mut self` — y no podrías conservar dos tokens a la vez (ejercicio 3).

## `'static`

`'static` es el tiempo de vida de los datos válidos durante toda la ejecución del programa. Los literales de cadena se almacenan en el binario, así que lo tienen ([líneas 62-64](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L62-L64)):

```rust
fn default_greeting() -> &'static str {
    "hello"
}
```

Te encontrarás `'static` sobre todo como **restricción** (bound), por ejemplo en `std::thread::spawn`: un hilo nuevo puede sobrevivir a la función que lo inició, así que no puede tomar prestadas las variables locales de esa función.

De [`src/lib.rs`, líneas 539-542](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L539-L542):

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

Mover el propio `String` a la closure lo arregla. [`T: 'static`](https://doc.rust-lang.org/reference/trait-bounds.html#lifetime-bounds) **no** significa «vive para siempre»: significa «no contiene datos prestados que puedan caducar» — un `String` con propietario cumple la condición. Los hilos son el tema de la [lección 12](../12-threads-and-concurrency/).

## Cuando los tiempos de vida estorban: sé dueño de los datos

Viniendo de C#, el reflejo es guardar referencias en todas partes. En Rust, un struct lleno de campos `&'a` contagia su tiempo de vida a todo lo que lo contiene. Una regla práctica mientras aprendes:

| Situación | Usa |
|---|---|
| Parámetros de función que solo lees | [`&str`](https://doc.rust-lang.org/std/primitive.str.html), [`&[T]`](https://doc.rust-lang.org/std/primitive.slice.html), `&T` |
| Vistas efímeras sobre datos que posee otro (parsers, iteradores, extractos) | un struct con `'a` |
| Datos que un struct conserva mucho tiempo | `String`, `Vec<T>`, `T` con propietario |
| Datos compartidos por varios propietarios | [`Rc`](https://doc.rust-lang.org/std/rc/struct.Rc.html)/[`Arc`](https://doc.rust-lang.org/std/sync/struct.Arc.html) — [lección 11](../11-smart-pointers/) |

Clonar unas cuantas cadenas para evitar un parámetro de tiempo de vida es un compromiso perfectamente razonable.

## Puntos clave

- Un tiempo de vida es el intervalo durante el cual una referencia es válida; el compilador comprueba que ninguna referencia sobreviva a su valor.
- Las anotaciones describen relaciones entre referencias en una **firma**; nunca alargan la vida de un valor.
- Tres reglas de elisión cubren la mayoría de las funciones; anotas cuando hay varias entradas y ningún `self`.
- Un struct que contiene una referencia lleva un parámetro de tiempo de vida y no puede sobrevivir a lo que toma prestado.
- Los datos `'static` no contienen préstamos que caduquen; los exigen API como `thread::spawn`.
- En caso de duda, sé dueño de los datos.

## Ejercicios

1. Escribe `fn longest_line(text: &str) -> &str`, que devuelve la línea más larga de un texto. ¿Necesita una anotación de tiempo de vida? Después escribe `fn pick(first: &str, second: &str, use_first: bool) -> &str` — ¿qué necesita?

<details>
<summary>Solución</summary>

De [`src/lib.rs`, líneas 548-556](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L548-L556):

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

`longest_line` tiene una sola referencia de entrada, así que se aplica la regla de elisión 2. `pick` tiene dos y puede devolver cualquiera de ellas, así que ambas deben compartir `'a` — exactamente como `longest`.

</details>

2. Define `struct Highlight<'a> { line: &'a str, column: usize }` y escribe `find_highlights(text, word)`, que devuelve cada línea de `text` que contiene `word`. Quien llama debe poder buscar con una consulta `String` temporal que se libera antes de usar los resultados.

<details>
<summary>Solución</summary>

De [`src/lib.rs`, líneas 562-577](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L562-L577):

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
    let query = String::from("Rust");   // se libera al final de este bloque
    find_highlights(&text, &query)
};
assert_eq!(hits, [Highlight { line: "I like Rust", column: 7 }, Highlight { line: "Rust again", column: 0 }]);
```

Los resultados solo toman prestado `text`, así que `word` recibe su propio tiempo de vida (elidido). Escribir `word: &'a str` haría compilar la función, pero rechazaría esta llamada con [`E0597`](https://doc.rust-lang.org/error_codes/E0597.html): el compilador supondría entonces que los resultados podrían apuntar a `query`.

</details>

3. Esta versión del tokenizador compila, pero `main` no. Explica el error y corrígelo cambiando una sola línea.

De [`src/lib.rs`, líneas 607-618](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L607-L618):

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
<summary>Solución</summary>

Con `Option<&str>`, la regla de elisión 3 da al resultado el tiempo de vida de `&mut self`. Mientras `first` siga vivo, `parser` permanece prestado de forma mutable, así que la segunda llamada se rechaza. El token apunta en realidad a la entrada, así que dilo ([línea 38](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L38)):

```rust
fn next_token(&mut self) -> Option<&'a str> {
```

Ahora los tokens toman prestado `line`, y el parser vuelve a quedar libre en cuanto termina cada llamada.

</details>

## Fuentes

- [The Book, ch. 10.3 — Validating References with Lifetimes](https://doc.rust-lang.org/book/ch10-03-lifetime-syntax.html)
- [The Rust Reference — Lifetime elision](https://doc.rust-lang.org/reference/lifetime-elision.html)
- [Rust by Example — `'static`](https://doc.rust-lang.org/rust-by-example/scope/lifetime/static_lifetime.html)
- [`std::thread::spawn`](https://doc.rust-lang.org/std/thread/fn.spawn.html)
