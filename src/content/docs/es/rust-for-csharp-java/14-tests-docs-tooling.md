---
title: 14. Tests, docs, clippy y fmt
description: Las herramientas de calidad que vienen con Cargo — tests unitarios, de integración y de documentación, rustdoc, lints de clippy y rustfmt, integrados en la CI.
sidebar:
  order: 14
---

Ejemplo completo: [`l14-testing/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l14-testing) — una pequeña biblioteca `pricing`; ejecuta `cargo test` desde esa carpeta.

## Todo viene incluido

En .NET eliges [xUnit](https://xunit.net), [NUnit](https://nunit.org) o [MSTest](https://learn.microsoft.com/dotnet/core/testing/unit-testing-mstest-intro), añades analizadores desde [NuGet](https://www.nuget.org) y configuras [`dotnet format`](https://learn.microsoft.com/dotnet/core/tools/dotnet-format). En Java añades [JUnit](https://junit.org), [Checkstyle](https://checkstyle.org) o [Error Prone](https://errorprone.info) y un plugin de formato a [Maven](https://maven.apache.org) o [Gradle](https://gradle.org). Rust trae una respuesta estándar para cada cosa, instalada con la cadena de herramientas:

| Tarea | Rust | C# | Java |
|---|---|---|---|
| Ejecutar tests | [`cargo test`](https://doc.rust-lang.org/cargo/commands/cargo-test.html) (framework de tests integrado) | [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test) + xUnit/NUnit/MSTest | `mvn test` + JUnit |
| Documentación de la API | [`cargo doc`](https://doc.rust-lang.org/cargo/commands/cargo-doc.html) ([rustdoc](https://doc.rust-lang.org/rustdoc/)) | [comentarios de documentación XML](https://learn.microsoft.com/dotnet/csharp/language-reference/xmldoc/recommended-tags) + [DocFX](https://dotnet.github.io/docfx/) | [Javadoc](https://docs.oracle.com/en/java/javase/25/javadoc/) |
| Lints | [`cargo clippy`](https://doc.rust-lang.org/clippy/usage.html) | [analizadores de Roslyn](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/overview) | Error Prone, [SpotBugs](https://spotbugs.github.io) |
| Formato | `cargo fmt` ([rustfmt](https://rust-lang.github.io/rustfmt/)) | `dotnet format` | [Spotless](https://github.com/diffplug/spotless), [google-java-format](https://github.com/google/google-java-format) |
| Configuración de lints | [`[lints]`](https://doc.rust-lang.org/cargo/reference/manifest.html#the-lints-section) en `Cargo.toml` | [`.editorconfig`](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/configuration-files), `<WarningsAsErrors>` | configuración del plugin |

Como hay una de cada, todos los proyectos Rust se ven iguales para un recién llegado: `cargo test`, `cargo clippy` y `cargo fmt` funcionan en todas partes.

## Tests unitarios

Los tests unitarios viven **en el mismo archivo** que el código, en un módulo hijo que solo se compila para los tests ([`l14-testing/src/lib.rs`, líneas 108-169](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/l14-testing/src/lib.rs#L108-L169)):

```rust
// Tests unitarios: un módulo hijo, así que puede acceder a los elementos privados
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn percent_discount_rounds_down() {
        let cart = cart_with(&[("book", 1, 999)]);
        assert_eq!(cart.total_with(Discount::Percent(10)), 899);
    }

    #[test]
    fn zero_quantity_is_rejected() {
        let mut cart = Cart::new();
        assert_eq!(cart.add("pen", 0, 150), Err(PricingError::ZeroQuantity));
        assert!(cart.lines.is_empty(), "a rejected line must not be stored");   // campo privado
    }

    #[test]
    #[should_panic(expected = "discount above 100%")]
    fn percent_above_100_panics() {
        Cart::new().total_with(Discount::Percent(101));
    }

    // Un test puede devolver Result y usar `?`
    #[test]
    fn free_item_error_message() -> Result<(), String> {
        let err = Cart::new().add("gift", 1, 0).err().ok_or("expected an error")?;
        assert_eq!(err.to_string(), "`gift` has no price");
        Ok(())
    }

    #[test]
    #[ignore = "slow: run with cargo test -- --ignored"]
    fn many_lines() { /* … */ }
}
```

| Rust | xUnit | JUnit 5 |
|---|---|---|
| `#[test]` | `[Fact]` | `@Test` |
| `assert_eq!(actual, expected)` | `Assert.Equal(expected, actual)` | `assertEquals(expected, actual)` |
| `assert!(cond, "message {x}")` | `Assert.True(cond, "message")` | `assertTrue(cond, "message")` |
| `#[should_panic(expected = "…")]` | `Assert.Throws<T>` | `assertThrows` |
| `#[ignore = "reason"]` | `[Fact(Skip = "reason")]` | `@Disabled("reason")` |
| una función auxiliar en `mod tests` | un helper privado o un fixture | `@BeforeEach` / helper |

La biblioteca estándar de Rust no tiene atributos para tests parametrizados ni para fixtures; un bucle sobre una tabla de casos, o una función auxiliar como `cart_with`, es la respuesta habitual (crates como [`rstest`](https://docs.rs/rstest) los añaden).

`cargo test` ejecuta tres tipos de tests e informa de cada uno:

```text
     Running unittests src\lib.rs (target\debug\deps\pricing-2041fb093a55ec20.exe)

running 7 tests
test tests::many_lines ... ignored, slow: run with cargo test -- --ignored
test tests::empty_cart_totals_zero ... ok
test tests::fixed_discount_never_goes_negative ... ok
test tests::free_item_error_message ... ok
test tests::percent_above_100_panics - should panic ... ok
test tests::percent_discount_rounds_down ... ok
test tests::zero_quantity_is_rejected ... ok

test result: ok. 6 passed; 0 failed; 1 ignored; 0 measured; 0 filtered out; finished in 0.00s

     Running tests\checkout.rs (target\debug\deps\checkout-8074f42be2f51ecc.exe)

running 1 test
test checkout_with_discount ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests pricing

running 2 tests
test src\lib.rs - Cart::total_with (line 90) - should panic ... ok
test src\lib.rs - Cart::add (line 59) ... ok

test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.05s
```

Un `assert_eq!` que falla muestra ambos lados:

```text
test tests::percent_discount_rounds_down ... FAILED

failures:

---- tests::percent_discount_rounds_down stdout ----

thread 'tests::percent_discount_rounds_down' (409064) panicked at src\lib.rs:128:9:
assertion `left == right` failed
  left: 899
 right: 900
```

Opciones útiles:

| Comando | Hace |
|---|---|
| `cargo test discount` | ejecuta solo los tests cuyo nombre contiene `discount` |
| `cargo test -- --ignored` | ejecuta solo los tests ignorados |
| `cargo test -- --nocapture` | muestra la salida de `println!` de los tests que pasan (capturada por defecto) |
| `cargo test -- --test-threads=1` | ejecuta los tests de uno en uno — por defecto se ejecutan **en paralelo** |

La ejecución en paralelo implica que los tests no deben compartir estado global mutable, como una ruta de archivo o una variable de entorno, sin coordinarse.

## Tests de integración

Los archivos de una carpeta `tests/` situada junto a `src/` son **tests de integración**. Cada archivo se compila como un crate aparte que depende de tu biblioteca, así que solo puede usar la API pública — como un proyecto `Pricing.Tests` independiente que referencia el assembly sin [`InternalsVisibleTo`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.internalsvisibletoattribute) ([`l14-testing/tests/checkout.rs`, líneas 3-13](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/l14-testing/tests/checkout.rs#L3-L13)):

```rust
// tests/checkout.rs
//! Escenarios de pago en caja, probados solo a través de la API pública.

use pricing::{Cart, Discount, PricingError};

#[test]
fn checkout_with_discount() -> Result<(), PricingError> {
    let mut cart = Cart::new();
    cart.add("book", 2, 2_000)?;
    cart.add("pen", 3, 150)?;
    assert_eq!(cart.total_cents(), 4_450);
    assert_eq!(cart.total_with(Discount::Percent(20)), 3_560);
    Ok(())
}
```

Ahí no hace falta `#[cfg(test)]`: toda la carpeta existe solo para los tests. Los tests de integración solo pueden hacer `use` de un crate de **biblioteca** — no hay forma de importar funciones de `src/main.rs`. Esa es una de las razones por las que los binarios guardan la mayor parte de su lógica en `src/lib.rs`, con un `src/main.rs` mínimo.

## Documentación y doc tests

`///` documenta el elemento siguiente, `//!` documenta el módulo o crate que lo contiene. El contenido es Markdown ([`l14-testing/src/lib.rs`, línea 67](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/l14-testing/src/lib.rs#L67)):

````rust
/// Añade `quantity` artículos a `unit_cents` cada uno.
///
/// # Errors
///
/// Devuelve [`PricingError::ZeroQuantity`] si `quantity` es 0 y
/// [`PricingError::FreeItem`] si `unit_cents` es 0.
///
/// # Examples
///
/// ```
/// use pricing::Cart;
///
/// let mut cart = Cart::new();
/// cart.add("pen", 2, 150)?;
/// assert_eq!(cart.total_cents(), 300);
/// # Ok::<(), pricing::PricingError>(())
/// ```
pub fn add(&mut self, name: &str, quantity: u32, unit_cents: u64) -> Result<(), PricingError> {
````

- `# Examples`, `# Errors`, `# Panics` y `# Safety` son los nombres de sección convencionales, como `<example>` o `<exception>` en C# o `@throws` en Javadoc.
- `` [`PricingError::ZeroQuantity`] `` es un **[enlace intra-doc](https://doc.rust-lang.org/rustdoc/write-documentation/linking-to-items-by-name.html)** (intra-doc link), que el compilador resuelve como `<see cref="…"/>`.
- Cada bloque de código es un **doc test**: `cargo test` lo compila y lo ejecuta, así que los ejemplos de la documentación no pueden quedarse obsoletos. Una línea que empieza por `# ` se compila pero se oculta en la página generada — aquí, el `Ok(())` que permite al ejemplo usar `?`.
- Los bloques de código aceptan [atributos](https://doc.rust-lang.org/rustdoc/write-documentation/documentation-tests.html#attributes): `should_panic`, `no_run` (solo compilar), `ignore` y `compile_fail` — el atributo que este curso usa para cada fragmento «esto no compila».

`cargo doc --open` genera la documentación HTML de tu crate y de todas sus dependencias. Con `RUSTDOCFLAGS="-D warnings"`, los enlaces rotos hacen fallar la compilación:

```text
error: unresolved link to `Cart::most_expensive`
   --> src\lib.rs:172:44
    |
172 | /// Name of the most expensive line, see [`Cart::most_expensive`].
    |                                            ^^^^^^^^^^^^^^^^^^^^ the struct `Cart` has no field or associated item named `most_expensive`
    |
    = note: `-D rustdoc::broken-intra-doc-links` implied by `-D warnings`
```

## Clippy

`cargo clippy` ejecuta varios cientos de lints además de las propias advertencias del compilador. Dada esta función:

```rust
pub fn describe(cart: &Cart) -> String {
    if cart.lines.len() == 0 {
        return String::from("empty");
    }
    let first = cart.lines.first().unwrap();
    return first.0.clone();
}
```

```text
warning: unneeded `return` statement
   --> src\lib.rs:178:5
    |
178 |     return first.0.clone();
    |     ^^^^^^^^^^^^^^^^^^^^^^
    |
    = help: for further information visit https://rust-lang.github.io/rust-clippy/rust-1.94.0/index.html#needless_return
    = note: `#[warn(clippy::needless_return)]` on by default
help: remove `return`
    |
178 -     return first.0.clone();
178 +     first.0.clone()
    |

warning: length comparison to zero
   --> src\lib.rs:174:8
    |
174 |     if cart.lines.len() == 0 {
    |        ^^^^^^^^^^^^^^^^^^^^^ help: using `is_empty` is clearer and more explicit: `cart.lines.is_empty()`

warning: used `unwrap()` on an `Option` value
   --> src\lib.rs:177:17
    |
177 |     let first = cart.lines.first().unwrap();
    |                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^
    |
    = note: if this value is `None`, it will panic
    = help: consider using `expect()` to provide a better panic message
```

Muchas sugerencias pueden aplicarse automáticamente con `cargo clippy --fix`. Los lints se organizan en [grupos](https://doc.rust-lang.org/clippy/lints.html): el conjunto por defecto (`correctness`, `suspicious`, `style`, `complexity`, `perf`), más los grupos opcionales `pedantic`, `nursery` y `restriction`. `unwrap_used`, arriba, pertenece a `restriction`, así que solo salta porque el package lo activa.

### Configurar los lints

Los niveles de lint de todo un package van en `Cargo.toml` — el equivalente de las severidades en `.editorconfig` ([`l14-testing/Cargo.toml`, líneas 8-12](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/l14-testing/Cargo.toml#L8-L12)):

```toml
# Niveles de lint para todo el package, en lugar de atributos #![deny] en cada archivo
[lints.rust]
missing_docs = "warn"

[lints.clippy]
unwrap_used = "warn"
```

En el código, [`#[allow(lint)]`](https://doc.rust-lang.org/reference/attributes/diagnostics.html#lint-check-attributes) silencia un lint para un elemento. Prefiere [`#[expect(lint, reason = "…")]`](https://doc.rust-lang.org/reference/attributes/diagnostics.html#the-expect-attribute): también silencia el lint, pero **avisa cuando el lint deja de saltar**, así que no se acumulan supresiones obsoletas (como un [`#pragma warning disable`](https://learn.microsoft.com/dotnet/csharp/language-reference/preprocessor-directives#pragma-warning) innecesario):

```text
warning: this lint expectation is unfulfilled
   --> src\lib.rs:173:10
    |
173 | #[expect(clippy::len_zero, reason = "comparing with 0 reads better here")]
    |          ^^^^^^^^^^^^^^^^
    |
    = note: comparing with 0 reads better here
    = note: `#[warn(unfulfilled_lint_expectations)]` on by default
```

Algunos lints también leen opciones de un archivo [`clippy.toml`](https://doc.rust-lang.org/clippy/configuration.html) (ejercicio 3).

:::caution[`missing_docs` también se aplica a los tests de integración]
Con `missing_docs = "warn"` en `[lints]`, `cargo clippy --all-targets -- -D warnings` falló en `tests/checkout.rs`: cada archivo de tests de integración es su propio crate, y un crate necesita un comentario de documentación `//!`. Añadí una línea de documentación de crate al archivo de tests.
:::

## rustfmt

`cargo fmt` formatea todo el package; `cargo fmt --check` solo informa de las diferencias y falla, que es lo que ejecuta la CI:

```text
Diff in \\?\C:\…\p14\src\lib.rs:178:
     return first.0.clone();
 }
 
-pub fn line_count(cart: &Cart) -> usize { cart.lines.len() }
+pub fn line_count(cart: &Cart) -> usize {
+    cart.lines.len()
+}
```

Hay un único estilo comunitario y casi nada que configurar (un `rustfmt.toml` puede cambiar algunas opciones como `max_width`). Los debates sobre formato desaparecen de la revisión de código.

:::note[Este curso lo adoptó tarde]
El código del curso pasó doce lecciones sin `cargo fmt`. Ejecutar `cargo fmt --check` para esta lección detectó 30 diferencias en los ejemplos; ahora están formateados y la CI comprueba el formato. Los comentarios de documentación, y por tanto los fragmentos `compile_fail`, no se reformatean.
:::

## Llevarlo a la CI

El propio workflow del curso, [`.github/workflows/rust-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/rust-examples.yml), es un pipeline de Rust típico (extracto) ([líneas 36-67](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/rust-examples.yml#L36-L67)):

```yaml
- name: Formatting
  run: cargo fmt --check
- name: Compile-fail doctests
  run: cargo test --doc
- name: Clippy
  run: cargo clippy --examples -- -D warnings
- name: Lesson 14 crate
  working-directory: code/rust-for-csharp-java/l14-testing
  env:
    RUSTDOCFLAGS: -D warnings
  run: |
    cargo clippy --all-targets -- -D warnings
    cargo test
    cargo test -- --ignored
    cargo doc --no-deps
```

`-D warnings` convierte cada advertencia en un error solo en la CI, así que las compilaciones locales siguen siendo cómodas y nada se integra con advertencias.

Más allá de las herramientas estándar, estos crates cubren los huecos que quedan: [`criterion`](https://docs.rs/criterion) para benchmarks ([BenchmarkDotNet](https://benchmarkdotnet.org), [JMH](https://github.com/openjdk/jmh)), [`proptest`](https://docs.rs/proptest) para tests basados en propiedades ([FsCheck](https://fscheck.github.io/FsCheck/), [jqwik](https://jqwik.net)), [`mockall`](https://docs.rs/mockall) para mocks ([Moq](https://github.com/devlooped/moq), [Mockito](https://site.mockito.org)) y [`cargo-llvm-cov`](https://github.com/taiki-e/cargo-llvm-cov) para la cobertura ([Coverlet](https://github.com/coverlet-coverage/coverlet), [JaCoCo](https://www.jacoco.org/jacoco/)).

## Puntos clave

- `cargo test`, `cargo doc`, `cargo clippy` y `cargo fmt` vienen con la cadena de herramientas; no hay nada que elegir.
- Los tests unitarios están junto al código en `#[cfg(test)] mod tests` y pueden probar elementos privados; los tests de integración de `tests/` solo ven la API pública.
- Cada ejemplo de código de la documentación `///` se compila y se ejecuta, así que la documentación sigue siendo correcta.
- Configura los lints en `[lints]`; usa `#[expect(…, reason = …)]` en lugar de `#[allow]`.
- En la CI: `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test`, `RUSTDOCFLAGS="-D warnings" cargo doc`.

## Ejercicios

1. Escribe `fn parse_percent(text: &str) -> Result<u8, String>`, que acepta `"15%"` (con espacios alrededor permitidos) y rechaza la ausencia de `%`, lo que no sea un número y los valores por encima de 100. Escribe tests unitarios para una entrada válida, para cada tipo de error y para `"300%"` (que no cabe en un `u8`), incluido un test que devuelva `Result`.

<details>
<summary>Solución</summary>

```rust
pub fn parse_percent(text: &str) -> Result<u8, String> {
    let digits = text
        .trim()
        .strip_suffix('%')
        .ok_or_else(|| format!("`{text}` does not end with %"))?;
    let value: u8 = digits
        .parse()
        .map_err(|e| format!("`{digits}` is not a number: {e}"))?;
    if value > 100 {
        return Err(format!("{value}% is above 100%"));
    }
    Ok(value)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_valid_percentages() {
        assert_eq!(parse_percent("0%"), Ok(0));
        assert_eq!(parse_percent(" 15% "), Ok(15));
        assert_eq!(parse_percent("100%"), Ok(100));
    }

    #[test]
    fn rejects_values_above_100() {
        assert_eq!(parse_percent("150%"), Err("150% is above 100%".to_string()));
    }

    #[test]
    fn rejects_missing_sign_and_garbage() {
        assert!(parse_percent("15").is_err());
        let err = parse_percent("abc%").unwrap_err();
        assert!(err.contains("not a number"), "unexpected message: {err}");
    }

    #[test]
    fn values_that_overflow_u8() -> Result<(), String> {
        let err = parse_percent("300%").err().ok_or("300% should fail")?;
        assert!(err.contains("not a number"), "unexpected message: {err}");
        Ok(())
    }
}
```

`"300%"` falla en `parse::<u8>()` antes de llegar a la comprobación `> 100`, así que su mensaje es el de «not a number» — un test es la forma más barata de descubrirlo.

</details>

2. Documenta `parse_percent` con las secciones `# Errors` y `# Examples`. El ejemplo debe usar `?` en lugar de `unwrap()`. ¿Qué le pasa a `cargo test` si el ejemplo afirma `parse_percent("15%")? == 16`?

<details>
<summary>Solución</summary>

````rust
/// Analiza un porcentaje como `"15%"`.
///
/// # Errors
///
/// Devuelve un error si el texto no termina en `%`, no es un número
/// o supera 100.
///
/// # Examples
///
/// ```
/// use ex14::parse_percent;
///
/// assert_eq!(parse_percent("15%")?, 15);
/// assert!(parse_percent("150%").is_err());
/// # Ok::<(), String>(())
/// ```
pub fn parse_percent(text: &str) -> Result<u8, String> {
````

La línea oculta `# Ok::<(), String>(())` hace que el `main` implícito del ejemplo devuelva `Result<(), String>`, que es lo que permite usar `?`. Si el ejemplo afirmara `16`, el doc test entraría en pánico y `cargo test` fallaría bajo `Doc-tests`, señalando la línea del comentario de documentación: una documentación errónea rompe la compilación.

</details>

3. Haz que `clippy::unwrap_used` sea un **error** para la biblioteca, sin dejar de permitir `unwrap()` en los tests unitarios. Compruébalo con una función que llame a `unwrap()`.

<details>
<summary>Solución</summary>

```toml
# Cargo.toml
[lints.clippy]
unwrap_used = "deny"
```

```toml
# clippy.toml, junto a Cargo.toml
allow-unwrap-in-tests = true
```

`cargo clippy --all-targets` ahora solo informa del código de la biblioteca:

```text
error: used `unwrap()` on a `Result` value
  --> src\lib.rs:35:5
   |
35 |     parse_percent(items[0]).unwrap()
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   |
   = note: if this value is an `Err`, it will panic
   = help: consider using `expect()` to provide a better panic message
```

Sin `clippy.toml`, también se informa del `unwrap_err()` de `rejects_missing_sign_and_garbage` (`used unwrap_err() on a Result value`).

</details>

## Fuentes

- [The Book, ch. 11 — Writing Automated Tests](https://doc.rust-lang.org/book/ch11-00-testing.html)
- [The rustdoc book — Documentation tests](https://doc.rust-lang.org/rustdoc/write-documentation/documentation-tests.html)
- [The Cargo Book — la sección `[lints]`](https://doc.rust-lang.org/cargo/reference/manifest.html#the-lints-section)
- [Documentación de Clippy](https://doc.rust-lang.org/clippy/) y la [lista de lints](https://rust-lang.github.io/rust-clippy/master/index.html)
- [The Rust Reference — `#[expect]`](https://doc.rust-lang.org/reference/attributes/diagnostics.html#the-expect-attribute)
- [rustfmt](https://github.com/rust-lang/rustfmt)
