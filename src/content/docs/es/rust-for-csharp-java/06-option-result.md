---
title: 6. Option, Result y ?
description: Ni null ni excepciones — la ausencia y el fallo como valores corrientes.
sidebar:
  order: 6
---

Ejemplo completo: [`examples/l06_option_result.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l06_option_result.rs) — `cargo run --example l06_option_result`.

## Dos cosas que Rust no tiene

Rust **no tiene `null`** ni **excepciones**. Ambos se sustituyen por dos enums de la biblioteca estándar — construidos exactamente como los de la [lección 5](../05-structs-enums-match/):

```rust
enum Option<T> {
    Some(T),
    None,
}

enum Result<T, E> {
    Ok(T),
    Err(E),
}
```

| Situación | C# | Java | Rust |
|---|---|---|---|
| Un valor puede faltar | `null`, [`int?`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/nullable-value-types), [tipos de referencia que aceptan valores null](https://learn.microsoft.com/dotnet/csharp/fundamentals/null-safety/nullable-reference-types) (advertencias) | `null`, [`Optional<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html) | `Option<T>` |
| Una operación puede fallar | [excepciones](https://learn.microsoft.com/dotnet/csharp/fundamentals/exceptions/) (no comprobadas) | [excepciones comprobadas y no comprobadas](https://docs.oracle.com/javase/tutorial/essential/exceptions/runtime.html) | `Result<T, E>` |
| Un error de programación, irrecuperable | [`Environment.FailFast`](https://learn.microsoft.com/dotnet/api/system.environment.failfast), excepción no controlada | [`Error`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Error.html), excepción no controlada | [`panic!`](https://doc.rust-lang.org/std/macro.panic.html) |

Como la ausencia y el fallo forman parte del **tipo**, no puedes olvidarlos.

## `Option<T>`

```rust
fn find_user(users: &HashMap<u32, User>, id: u32) -> Option<&User> {
    users.get(&id)
}

match find_user(&users, 3) {
    Some(user) => println!("found {}", user.name),
    None => println!("no user 3"),
}
```

Un `Option<i32>` no es un `i32`, así que no puedes usarlo por accidente:

```rust
let maybe: Option<i32> = Some(1);
let total = maybe + 1;
```

```text
error[E0369]: cannot add `{integer}` to `Option<i32>`
   --> e06_option_add.rs:3:23
    |
  3 |     let total = maybe + 1;
    |                 ----- ^ - {integer}
    |                 |
    |                 Option<i32>
```

En C#, la [`NullReferenceException`](https://learn.microsoft.com/dotnet/api/system.nullreferenceexception) equivalente ocurriría en tiempo de ejecución.

### Combinadores

En lugar de `if (x != null)` anidados, encadena métodos — se leen como [`?.`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/member-access-operators#null-conditional-operators--and-) y [`??`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/null-coalescing-operator):

```rust
let name_len = find_user(&users, 2).map(|u| u.name.len()).unwrap_or(0);
```

| Rust | C# | `Optional` de Java |
|---|---|---|
| `opt.map(f)` | `x?.F()` | `opt.map(f)` |
| `opt.unwrap_or(v)` | `x ?? v` | `opt.orElse(v)` |
| `opt.unwrap_or_else(f)` | `x ?? F()` | `opt.orElseGet(f)` |
| `opt.and_then(f)` | `x?.F()` donde `F` devuelve un valor que admite null | `opt.flatMap(f)` |
| `opt.ok_or(err)` | `x ?? throw …` | `opt.orElseThrow(…)` |
| `opt.is_some()` / `is_none()` | `x != null` | `opt.isPresent()` |

## `Result<T, E>`

Una función que puede fallar lo dice en su firma — algo parecido a una excepción comprobada de Java, pero como valor de retorno:

```rust
fn sum_csv(line: &str) -> Result<i32, ParseIntError> {
    let mut total = 0;
    for field in line.split(',') {
        total += field.trim().parse::<i32>()?;
    }
    Ok(total)
}

println!("{:?}", sum_csv("1, 2, 3"));     // Ok(6)
println!("{:?}", sum_csv("1, two, 3"));   // Err(ParseIntError { kind: InvalidDigit })
```

Ignorar un `Result` genera una advertencia, porque puede ocultar un error:

```text
warning: unused `Result` that must be used
 --> e06_unused_result.rs:6:5
  |
6 |     save();
  |     ^^^^^^
  |
  = note: this `Result` may be an `Err` variant, which should be handled
```

## El operador `?`

`?` significa: *si es `Ok`/`Some`, extrae el valor; si no, devuelve inmediatamente el `Err`/`None` desde la función actual.* Es el equivalente explícito y visible de dejar que una excepción se propague.

```rust
fn manager_name(users: &HashMap<u32, User>, id: u32) -> Option<&str> {
    let user = find_user(users, id)?;                  // no existe el usuario → None
    let manager = find_user(users, user.manager_id?)?; // sin manager → None
    Some(&manager.name)
}
```

```text
manager of 2: Some("Grace")
manager of 1: None
manager of 9: None
```

`?` solo funciona dentro de una función que a su vez devuelve `Result` u `Option`:

```text
error[E0277]: the `?` operator can only be used in a function that returns `Result` or `Option` (or another type that implements `FromResidual`)
 --> e06_question_in_main.rs:2:35
  |
1 | fn main() {
  | --------- this function should return `Result` or `Option` to accept `?`
2 |     let port: u16 = "3000".parse()?;
  |                                   ^ cannot use the `?` operator in a function that returns `()`
  |
help: consider adding return type
  |
1 ~ fn main() -> Result<(), Box<dyn std::error::Error>> {
2 |     let port: u16 = "3000".parse()?;
3 |     println!("{port}");
4 +     Ok(())
  |
```

## Tus propios tipos de error

Un error puede ser de cualquier tipo; un `enum` enumera las formas en que una operación puede fallar:

```rust
#[derive(Debug)]
enum ConfigError {
    Missing(&'static str),
    BadNumber { key: &'static str, source: ParseIntError },
}

impl fmt::Display for ConfigError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            ConfigError::Missing(key) => write!(f, "missing key `{key}`"),
            ConfigError::BadNumber { key, source } => write!(f, "`{key}` is not a number: {source}"),
        }
    }
}

impl Error for ConfigError {}

fn read_port(config: &HashMap<&str, &str>) -> Result<u16, ConfigError> {
    let raw = config.get("port").ok_or(ConfigError::Missing("port"))?;
    raw.parse::<u16>().map_err(|source| ConfigError::BadNumber { key: "port", source })
}
```

```text
Err("missing key `port`")
Err("`port` is not a number: invalid digit found in string")
Ok(3000)
```

- [`ok_or`](https://doc.rust-lang.org/std/option/enum.Option.html#method.ok_or) convierte un `Option` en un `Result`; [`map_err`](https://doc.rust-lang.org/std/result/enum.Result.html#method.map_err) convierte un tipo de error en otro — como capturar una excepción y envolverla.
- [`Display`](https://doc.rust-lang.org/std/fmt/trait.Display.html) es el mensaje para los usuarios; [`Debug`](https://doc.rust-lang.org/std/fmt/trait.Debug.html), los detalles para los desarrolladores.
- En proyectos reales, el crate [`thiserror`](https://crates.io/crates/thiserror) genera este código repetitivo para las bibliotecas, y [`anyhow`](https://crates.io/crates/anyhow) ofrece un tipo de error comodín para las aplicaciones.

### `main` puede devolver un `Result`

```rust
fn main() -> Result<(), Box<dyn Error>> {
    let port = read_port(&config)?;   // ConfigError se convierte en Box<dyn Error>
    println!("listening on {port}");
    Ok(())
}
```

[`Box<dyn Error>`](https://doc.rust-lang.org/std/error/trait.Error.html) acepta cualquier tipo de error, así que `?` funciona con errores distintos en la misma función. Si `main` devuelve `Err`, Rust lo imprime con su formato **`Debug`** y termina con el código 1:

```text
Error: Missing("port")
```

## Cuándo entrar en pánico

[`unwrap()`](https://doc.rust-lang.org/std/result/enum.Result.html#method.unwrap) y [`expect("…")`](https://doc.rust-lang.org/std/result/enum.Result.html#method.expect) extraen el valor o **entran en pánico**:

```rust
let port: u16 = "http".parse().expect("PORT must be a number");
```

```text
thread 'main' panicked at e06_unwrap_panic.rs:2:36:
PORT must be a number: ParseIntError { kind: InvalidDigit }
```

| Usa | Para |
|---|---|
| `Result` + `?` | todo lo que puede fallar en el funcionamiento normal: E/S, análisis de la entrada del usuario, red |
| `expect("why this cannot fail")` | invariantes que has comprobado, pruebas, prototipos rápidos |
| `unwrap()` | pruebas y ejemplos; en código de producción, prefiere `expect` con un motivo |

Un pánico no es un mecanismo de `try/catch`: trátalo como un informe de error de programación.

## Puntos clave

- `Option<T>` sustituye a `null`; `Result<T, E>` sustituye a las excepciones; ambos son enums corrientes.
- El compilador se niega a usar un `Option<T>` como un `T`, y avisa cuando se ignora un `Result`.
- `?` propaga `None`/`Err` a quien llama — explícito, pero tan breve como una excepción.
- Modela los errores con enums, conviértelos con `map_err`/[`From`](https://doc.rust-lang.org/std/convert/trait.From.html) y reserva `panic!` para los errores de programación.

## Ejercicios

1. Traduce a Rust este método de C# y su llamada, usando `Option` y `unwrap_or`:

```csharp
int? FindAge(Dictionary<string, int> ages, string name) =>
    ages.TryGetValue(name, out var age) ? age : null;

var age = FindAge(ages, "Ada") ?? -1;
```

<details>
<summary>Solución</summary>

```rust
use std::collections::HashMap;

fn find_age(ages: &HashMap<&str, u32>, name: &str) -> Option<u32> {
    ages.get(name).copied()
}

let ages = HashMap::from([("Ada", 36)]);
let age = find_age(&ages, "Ada").map(i64::from).unwrap_or(-1);
assert_eq!(age, 36);
assert_eq!(find_age(&ages, "Bob"), None);
```

`get` devuelve `Option<&u32>`; `.copied()` lo convierte en `Option<u32>`. Devolver `-1` como valor centinela exige un tipo con signo — en Rust, lo habitual sería conservar el `Option`.

</details>

2. Escribe `fn parse_point(text: &str) -> Result<(i32, i32), String>` de modo que `"3,4"` dé `Ok((3, 4))`, `"3"` dé `Err("expected x,y")` y `"3,z"` dé un error que mencione el fallo de análisis. Usa `?`.

<details>
<summary>Solución</summary>

```rust
fn parse_point(text: &str) -> Result<(i32, i32), String> {
    let (x, y) = text.split_once(',').ok_or("expected x,y")?;
    let x = x.trim().parse::<i32>().map_err(|e| format!("bad x: {e}"))?;
    let y = y.trim().parse::<i32>().map_err(|e| format!("bad y: {e}"))?;
    Ok((x, y))
}

assert_eq!(parse_point("3,4"), Ok((3, 4)));
assert_eq!(parse_point("3"), Err(String::from("expected x,y")));
assert_eq!(parse_point("3,z"), Err(String::from("bad y: invalid digit found in string")));
```

`?` también convierte el `&str` que devuelve `ok_or` en un `String`, porque `String` implementa `From<&str>`.

</details>

3. `let port: u16 = "3000".parse()?;` no compila en `fn main()`. Da dos soluciones.

<details>
<summary>Solución</summary>

- Cambiar la firma a `fn main() -> Result<(), Box<dyn std::error::Error>>` y terminar con `Ok(())`, para que `?` tenga adónde devolver el error.
- O tratar el error localmente, por ejemplo con `let port: u16 = "3000".parse().expect("PORT must be a number");` o con un `match`.

</details>

## Fuentes

- [The Book, ch. 9 — Error Handling](https://doc.rust-lang.org/book/ch09-00-error-handling.html)
- [`Option` — biblioteca estándar](https://doc.rust-lang.org/std/option/enum.Option.html)
- [`Result` — biblioteca estándar](https://doc.rust-lang.org/std/result/enum.Result.html)
- [El operador `?` — Rust Reference](https://doc.rust-lang.org/reference/expressions/operator-expr.html#the-try-propagation-expression)
