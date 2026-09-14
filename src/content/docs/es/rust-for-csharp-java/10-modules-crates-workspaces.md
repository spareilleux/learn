---
title: 10. Módulos, crates y workspaces
description: Namespaces, assemblies y soluciones en Rust — visibilidad, archivos, dependencias, features y workspaces de varios crates.
sidebar:
  order: 10
---

Ejemplo completo: [`examples/l10_modules.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l10_modules.rs) — `cargo run --example l10_modules`.
Workspace: [`l10-workspace/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l10-workspace) — `cargo run -p app` desde esa carpeta.

## Vocabulario

| Rust | C# | Java |
|---|---|---|
| **module** (`mod`) | [namespace](https://learn.microsoft.com/dotnet/csharp/fundamentals/program-structure/namespaces) | [package](https://docs.oracle.com/javase/tutorial/java/package/packages.html) |
| **crate** — una unidad de compilación, biblioteca o ejecutable | [assembly](https://learn.microsoft.com/dotnet/standard/assembly/) (`.dll` / `.exe`) | [JAR](https://docs.oracle.com/javase/tutorial/deployment/jar/) |
| **package** — un [`Cargo.toml`](https://doc.rust-lang.org/cargo/reference/manifest.html) que compila uno o varios crates | [proyecto (`.csproj`)](https://learn.microsoft.com/dotnet/core/project-sdk/overview) | módulo [Maven](https://maven.apache.org/)/[Gradle](https://gradle.org/) |
| **workspace** — varios packages compilados juntos | [solución (`.sln`)](https://learn.microsoft.com/visualstudio/ide/solutions-and-projects-in-visual-studio) | [build multimódulo (POM padre)](https://maven.apache.org/guides/mini/guide-multiple-modules.html) |
| [crates.io](https://crates.io) | [NuGet](https://www.nuget.org/) | [Maven Central](https://central.sonatype.com/) |

Destacan dos diferencias. Un namespace de C# es solo un prefijo de nombres y cualquier archivo puede añadirle elementos; un módulo de Rust es un verdadero **ámbito** con su propia privacidad, y el árbol de módulos se declara explícitamente. Y en C# se compila cada archivo `.cs` de la carpeta del proyecto; en Rust, un archivo solo se compila si algún módulo lo declara.

## Módulos y privacidad

```rust
mod billing {
    pub fn invoice_total(amounts: &[f64]) -> f64 {
        let subtotal: f64 = amounts.iter().sum();
        subtotal + tax(subtotal)
    }

    fn tax(amount: f64) -> f64 {
        amount * rates::SALES_TAX
    }

    pub mod rates {
        pub const SALES_TAX: f64 = 0.15;
    }
}

println!("{}", billing::tax(100.0));
```

```text
error[E0603]: function `tax` is private
  --> e10_private_fn.rs:12:29
   |
12 |     println!("{}", billing::tax(100.0));
   |                             ^^^ private function
   |
note: the function `tax` is defined here
  --> e10_private_fn.rs:6:5
   |
 6 |     fn tax(amount: f64) -> f64 {
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^
```

Todo es **privado por defecto**. Un elemento privado es visible en el módulo que lo define **y en los hijos de ese módulo** — así que `rates` podría llamar a `tax` mediante `super::tax`, pero `main`, fuera de `billing`, no puede.

| Rust | Visible desde | C# | Java |
|---|---|---|---|
| *(nada)* | este módulo y sus hijos | `private` | `private` |
| `pub(super)` | también el módulo padre | — | — |
| `pub(crate)` | todo el crate | [`internal`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/internal) | [package-private](https://docs.oracle.com/javase/tutorial/java/javaOO/accesscontrol.html) (aproximadamente) |
| `pub` | en todas partes donde el módulo padre es visible | `public` | `public` |

No existe `protected`: Rust no tiene herencia entre structs.

### Los campos de un struct son privados por separado

`pub struct` hace público el **tipo**, no sus campos. Así es como Rust garantiza invariantes — el equivalente de una clase con campos privados y un constructor:

```rust
mod shapes {
    pub struct Rect {
        width: f64,
        height: f64,
    }

    impl Rect {
        pub fn new(width: f64, height: f64) -> Self {
            Rect { width: width.max(0.0), height: height.max(0.0) }
        }

        pub fn area(&self) -> f64 {
            self.width * self.height
        }
    }
}

let r = shapes::Rect { width: 2.0, height: 3.0 };
```

```text
error[E0451]: fields `width` and `height` of struct `Rect` are private
  --> e10_private_literal.rs:19:28
   |
19 |     let r = shapes::Rect { width: 2.0, height: 3.0 };
   |                            ^^^^^       ^^^^^^ private field
   |                            |
   |                            private field
```

Leer `r.width` desde fuera falla de la misma manera (`E0616: field width of struct Rect is private`). El código externo tiene que pasar por `Rect::new`, que recorta los tamaños negativos a cero. Las variantes de un `pub enum`, en cambio, son siempre públicas.

## Rutas y `use`

```rust
use billing::discounts::with_discount;       // trae una función al ámbito
use billing::rates::SALES_TAX as TAX;        // renombra, como `using X = …`
use shapes::Rect;

mod billing {
    // …
    pub mod discounts {
        pub fn with_discount(amounts: &[f64], percent: f64) -> f64 {
            super::invoice_total(amounts) * (1.0 - percent / 100.0)   // módulo padre
        }
    }
}

println!("{}", crate::billing::rates::SALES_TAX * 100.0);   // ruta absoluta desde la raíz del crate
```

```text
total: 172.50
with 10% off: 155.25
tax rate: 0.15
clamped area: 0
unit square: 1
15
```

| Inicio de la ruta | Significa | Como |
|---|---|---|
| `crate::` | la raíz del crate actual | [`global::`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/namespace-alias-qualifier) en C# |
| `super::` | el módulo padre | `..` en una ruta de archivo |
| `self::` | el módulo actual | `.` |
| un nombre de crate (`std::`, `geometry::`) | un crate externo | el namespace raíz de un assembly |

`use` solo crea un atajo; sin él tienes que escribir la ruta completa. El compilador sugiere la importación que falta:

```text
error[E0422]: cannot find struct, variant or union type `Rect` in this scope
 --> e10_no_use.rs:8:13
  |
8 |     let r = Rect { width: 2.0 };
  |             ^^^^ not found in this scope
  |
help: consider importing this struct
  |
1 + use crate::shapes::Rect;
  |
```

[`pub use`](https://doc.rust-lang.org/reference/items/use-declarations.html#use-visibility) **reexporta** un nombre para que quien llama vea una ruta más sencilla que tu organización interna — la biblioteca de la sección siguiente lo usa.

## Módulos en archivos

`mod shapes;` con un punto y coma en lugar de un cuerpo entre llaves indica al compilador que cargue el módulo desde un archivo:

| Declaración | En el archivo | El cuerpo del módulo está en |
|---|---|---|
| `mod shapes;` | `src/lib.rs` o `src/main.rs` | `src/shapes.rs` (o el más antiguo `src/shapes/mod.rs`) |
| `pub mod http;` | `src/network.rs` | `src/network/http.rs` |

El archivo contiene solo el cuerpo — sin envoltorio `mod shapes { }`. Un archivo `.rs` al que no llega ninguna declaración `mod` simplemente se ignora, aunque esté en `src/`.

## Crates y packages

Un package puede contener un **crate de biblioteca** (`src/lib.rs`) y cualquier número de **crates binarios** (`src/main.rs`, `src/bin/*.rs`). El propio código del curso es una biblioteca con doctests más `examples/`, que Cargo compila como binarios adicionales.

Las dependencias van en `Cargo.toml`, o se añaden con [`cargo add`](https://doc.rust-lang.org/cargo/commands/cargo-add.html):

```toml
[dependencies]
serde = "1.0"                                   # desde crates.io
geometry = { path = "../geometry" }             # un crate local
```

| Cargo | .NET | Maven/Gradle |
|---|---|---|
| `serde = "1.0"` significa `>=1.0.0, <2.0.0` (caret, actualizaciones compatibles con [SemVer](https://semver.org/)) | [`Version="1.0"`](https://learn.microsoft.com/nuget/concepts/package-versioning#version-ranges) significa `>=1.0` | `1.0` es un [requisito flexible](https://maven.apache.org/pom.html#Dependency_Version_Requirement_Specification) que la resolución de conflictos puede anular; los rangos se escriben `[1.0,2.0)` |
| [`Cargo.lock`](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html) fija las versiones exactas | [`packages.lock.json`](https://learn.microsoft.com/nuget/consume-packages/package-references-in-project-files#locking-dependencies) | archivos de bloqueo / [dependency locking](https://docs.gradle.org/current/userguide/dependency_locking.html) |
| [`cargo tree`](https://doc.rust-lang.org/cargo/commands/cargo-tree.html) | [`dotnet list package --include-transitive`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-list) | [`mvn dependency:tree`](https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html) |

### Features: opciones en tiempo de compilación

Un crate puede declarar **features** que activan código opcional. Las features son interruptores aditivos que se comprueban con [`#[cfg]`](https://doc.rust-lang.org/reference/conditional-compilation.html), más cercanos a los símbolos [`#if`](https://learn.microsoft.com/dotnet/csharp/language-reference/preprocessor-directives#conditional-compilation) de C# que a una configuración en tiempo de ejecución:

```toml
# geometry/Cargo.toml
[features]
default = []
display = []
```

```rust
// geometry/src/shapes.rs — solo se compila cuando un dependiente activa `display`
#[cfg(feature = "display")]
impl std::fmt::Display for Rect {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{}x{} rectangle", self.width, self.height)
    }
}
```

Si `app` olvida activarla, `Rect` simplemente no tiene implementación de `Display`:

```text
error[E0277]: `Rect` doesn't implement `std::fmt::Display`
 --> app\src\main.rs:9:20
  |
9 |     println!("{}", Rect::new(4.0, 2.5)); // Display exists because app enables the feature
  |               --   ^^^^^^^^^^^^^^^^^^^ `Rect` cannot be formatted with the default formatter
  |               |
  |               required by this formatting parameter
  |
  = help: the trait `std::fmt::Display` is not implemented for `Rect`
```

## Workspaces

Un workspace es una solución: varios packages que comparten un mismo `Cargo.lock` y una misma carpeta `target/`, compilados y probados con un solo comando. El [`l10-workspace`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l10-workspace) del curso:

```text
l10-workspace/
├── Cargo.toml          workspace root (no package of its own)
├── Cargo.lock          shared by all members
├── geometry/           library crate
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs      mod shapes; pub mod units; pub use shapes::{…};
│       ├── shapes.rs
│       └── units.rs
└── app/                binary crate that depends on geometry
    ├── Cargo.toml
    └── src/main.rs
```

```toml
# l10-workspace/Cargo.toml
[workspace]
resolver = "3"
members = ["geometry", "app"]

# Compartido por cada miembro que lo adopte con `x.workspace = true`
[workspace.package]
version = "0.1.0"
edition = "2024"
publish = false

[workspace.dependencies]
geometry = { path = "geometry" }
```

```toml
# l10-workspace/app/Cargo.toml
[package]
name = "app"
version.workspace = true
edition.workspace = true
publish.workspace = true

[dependencies]
geometry = { workspace = true, features = ["display"] }
```

`[workspace.dependencies]` cumple el papel del [*Central Package Management*](https://learn.microsoft.com/nuget/consume-packages/central-package-management) de .NET (`Directory.Packages.props`) o de una sección [`<dependencyManagement>`](https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Dependency_Management) de Maven: las versiones se declaran una sola vez y los miembros solo dicen `workspace = true`.

```rust
// geometry/src/lib.rs
mod shapes;          // módulo privado, cargado desde src/shapes.rs
pub mod units;       // módulo público, cargado desde src/units.rs

pub use shapes::{Circle, Rect, Shape};
```

```rust
// app/src/main.rs
use geometry::units::cm_to_inches;
use geometry::{Circle, Rect, Shape};

fn main() {
    let shapes: Vec<Box<dyn Shape>> = vec![Box::new(Circle { radius: 1.0 }), Box::new(Rect::new(2.0, 3.0))];
    let total: f64 = shapes.iter().map(|s| s.area()).sum();
    println!("total area: {total:.2}");

    println!("{}", Rect::new(4.0, 2.5));
    println!("10 cm = {:.2} in", cm_to_inches(10.0));
}
```

```text
total area: 9.14
4x2.5 rectangle
10 cm = 3.94 in
```

La visibilidad funciona ahora entre crates. `shapes` es un módulo privado y `non_negative` es `pub(crate)`, así que `app` no puede usar ninguno de los dos:

```text
error[E0603]: function `non_negative` is private
  --> app\src\main.rs:10:30
   |
10 |     let _ = geometry::units::non_negative(-1.0);
   |                              ^^^^^^^^^^^^ private function
   |
note: the function `non_negative` is defined here
  --> geometry\src\units.rs:6:1
   |
 6 | pub(crate) fn non_negative(value: f64) -> f64 {
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

error[E0603]: module `shapes` is private
  --> app\src\main.rs:11:23
   |
11 |     let _ = geometry::shapes::Circle { radius: 1.0 };
   |                       ^^^^^^ private module
```

Comandos de uso diario, ejecutados desde la raíz del workspace:

| Comando | Hace |
|---|---|
| `cargo build` | compila todos los miembros |
| `cargo run -p app` | ejecuta un solo package, como [`dotnet run --project app`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run) |
| `cargo test --workspace` | prueba todos los miembros |
| `cargo tree` | muestra el grafo de dependencias |

```text
app v0.1.0 (…\l10-workspace\app)
└── geometry v0.1.0 (…\l10-workspace\geometry)
```

:::tip[Los tests unitarios viven junto al código]
`geometry/src/lib.rs` termina con un bloque `#[cfg(test)] mod tests { use super::*; … }`. Como `tests` es un módulo hijo, puede incluso llamar a funciones privadas. Los tests tienen su propia lección, la 14.
:::

## Puntos clave

- Un módulo es un ámbito de privacidad; un crate es una unidad de compilación; un package es un `Cargo.toml`; un workspace agrupa packages.
- Todo es privado por defecto; `pub(crate)` es `internal`, `pub` es `public`, y los campos de un struct necesitan su propio `pub`.
- `use` crea atajos, `pub use` reexporta, y las rutas empiezan por `crate`, `super`, `self` o un nombre de crate.
- `mod name;` carga `name.rs`; los archivos que ningún módulo declara no se compilan.
- Las versiones de Cargo son rangos compatibles con SemVer fijados por `Cargo.lock`; las features son interruptores en tiempo de compilación.
- Los workspaces comparten un archivo de bloqueo y la salida de compilación, y pueden centralizar las versiones en `[workspace.dependencies]`.

## Ejercicios

1. Escribe un módulo `temperature` con un `pub struct Celsius(f64)` que **no pueda** contener un valor por debajo del cero absoluto (−273.15). Fuera del módulo, `temperature::Celsius(-500.0)` no debe compilar.

<details>
<summary>Solución</summary>

```rust
mod temperature {
    #[derive(Debug, PartialEq)]
    pub struct Celsius(f64);

    impl Celsius {
        pub const ABSOLUTE_ZERO: f64 = -273.15;

        pub fn new(value: f64) -> Option<Celsius> {
            (value >= Self::ABSOLUTE_ZERO).then_some(Celsius(value))
        }

        pub fn value(&self) -> f64 {
            self.0
        }
    }
}

use temperature::Celsius;
assert_eq!(Celsius::new(-500.0), None);
assert_eq!(Celsius::new(21.5).map(|c| c.value()), Some(21.5));
```

El campo `f64` no tiene `pub`, así que el constructor de tupla es privado:

```text
error[E0603]: tuple struct constructor `Celsius` is private
 --> e10_tuple.rs:7:26
  |
3 |     pub struct Celsius(f64);
  |                        --- a constructor is private if any of the fields is private
...
7 |     let t = temperature::Celsius(-500.0);
  |                          ^^^^^^^ private tuple struct constructor
```

</details>

2. El `src/main.rs` de un crate binario contiene `mod network { pub mod http { pub fn get(host: &str) -> String { … } } }`. Mueve cada módulo a su propio archivo. ¿Qué archivos creas y qué conserva `main.rs`?

<details>
<summary>Solución</summary>

```text
src/
├── main.rs            mod network;   +  fn main() { … network::http::get("example.com") … }
├── network.rs         pub mod http;
└── network/
    └── http.rs        pub fn get(host: &str) -> String { format!("GET http://{host}/") }
```

`main.rs` declara `network`, `network.rs` declara `http`, y `http.rs` contiene el cuerpo. Al ejecutarlo se imprime `GET http://example.com/`.

</details>

3. Añade un tercer miembro, `report`, a `l10-workspace`: una biblioteca con `pub fn describe(shapes: &[Box<dyn Shape>]) -> String` que devuelva, por ejemplo, `"2 shapes, total area 9.14"`, y un test unitario. ¿Qué cambia y en qué `Cargo.toml`?

<details>
<summary>Solución</summary>

En el `Cargo.toml` raíz: `members = ["geometry", "app", "report"]`. Después:

```toml
# report/Cargo.toml
[package]
name = "report"
version.workspace = true
edition.workspace = true
publish.workspace = true

[dependencies]
geometry.workspace = true
```

```rust
// report/src/lib.rs
use geometry::Shape;

pub fn describe(shapes: &[Box<dyn Shape>]) -> String {
    let total: f64 = shapes.iter().map(|s| s.area()).sum();
    format!("{} shapes, total area {total:.2}", shapes.len())
}

#[cfg(test)]
mod tests {
    use super::*;
    use geometry::{Circle, Rect};

    #[test]
    fn describes_shapes() {
        let shapes: Vec<Box<dyn Shape>> = vec![Box::new(Rect::new(2.0, 3.0)), Box::new(Circle { radius: 1.0 })];
        assert_eq!(describe(&shapes), "2 shapes, total area 9.14");
    }
}
```

`cargo test -p report` ejecuta el test. `report` no necesita la feature `display`, así que no la pide.

</details>

## Fuentes

- [The Book, ch. 7 — Managing Growing Projects with Packages, Crates, and Modules](https://doc.rust-lang.org/book/ch07-00-managing-growing-projects-with-packages-crates-and-modules.html)
- [The Rust Reference — Visibility and privacy](https://doc.rust-lang.org/reference/visibility-and-privacy.html)
- [The Cargo Book — Specifying dependencies](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html)
- [The Cargo Book — Features](https://doc.rust-lang.org/cargo/reference/features.html)
- [The Cargo Book — Workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html)
