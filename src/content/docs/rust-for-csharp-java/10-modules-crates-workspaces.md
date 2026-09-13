---
title: 10. Modules, crates and workspaces
description: Namespaces, assemblies and solutions in Rust — visibility, files, dependencies, features and multi-crate workspaces.
sidebar:
  order: 10
---

Full example: [`examples/l10_modules.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l10_modules.rs) — `cargo run --example l10_modules`.
Workspace: [`l10-workspace/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l10-workspace) — `cargo run -p app` from that folder.

## Vocabulary

| Rust | C# | Java |
|---|---|---|
| **module** (`mod`) | [namespace](https://learn.microsoft.com/dotnet/csharp/fundamentals/program-structure/namespaces) | [package](https://docs.oracle.com/javase/tutorial/java/package/packages.html) |
| **crate** — one compilation unit, a library or an executable | [assembly](https://learn.microsoft.com/dotnet/standard/assembly/) (`.dll` / `.exe`) | [JAR](https://docs.oracle.com/javase/tutorial/deployment/jar/) |
| **package** — a [`Cargo.toml`](https://doc.rust-lang.org/cargo/reference/manifest.html) building one or more crates | [project (`.csproj`)](https://learn.microsoft.com/dotnet/core/project-sdk/overview) | [Maven](https://maven.apache.org/)/[Gradle](https://gradle.org/) module |
| **workspace** — several packages built together | [solution (`.sln`)](https://learn.microsoft.com/visualstudio/ide/solutions-and-projects-in-visual-studio) | [multi-module build (parent POM)](https://maven.apache.org/guides/mini/guide-multiple-modules.html) |
| [crates.io](https://crates.io) | [NuGet](https://www.nuget.org/) | [Maven Central](https://central.sonatype.com/) |

Two differences stand out. A C# namespace is just a naming prefix and any file can add to it; a Rust module is a real **scope** with its own privacy, and the module tree is declared explicitly. And in C#, every `.cs` file in the project folder is compiled; in Rust, a file is compiled only if some module declares it.

## Modules and privacy

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

Everything is **private by default**. A private item is visible in the module that defines it **and in that module's children** — so `rates` could call `tax` through `super::tax`, but `main`, outside `billing`, cannot.

| Rust | Visible from | C# | Java |
|---|---|---|---|
| *(nothing)* | this module and its children | `private` | `private` |
| `pub(super)` | the parent module too | — | — |
| `pub(crate)` | the whole crate | [`internal`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/internal) | [package-private](https://docs.oracle.com/javase/tutorial/java/javaOO/accesscontrol.html) (roughly) |
| `pub` | everywhere the parent module is visible | `public` | `public` |

There is no `protected`: Rust has no inheritance between structs.

### Struct fields are private separately

`pub struct` makes the **type** public, not its fields. That is how Rust enforces invariants — the equivalent of a class with private fields and a constructor:

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

Reading `r.width` from outside fails the same way (`E0616: field width of struct Rect is private`). Outside code must go through `Rect::new`, which clamps negative sizes. The variants of a `pub enum`, on the other hand, are always public.

## Paths and `use`

```rust
use billing::discounts::with_discount;       // bring a function into scope
use billing::rates::SALES_TAX as TAX;        // rename, like `using X = …`
use shapes::Rect;

mod billing {
    // …
    pub mod discounts {
        pub fn with_discount(amounts: &[f64], percent: f64) -> f64 {
            super::invoice_total(amounts) * (1.0 - percent / 100.0)   // parent module
        }
    }
}

println!("{}", crate::billing::rates::SALES_TAX * 100.0);   // absolute path from the crate root
```

```text
total: 172.50
with 10% off: 155.25
tax rate: 0.15
clamped area: 0
unit square: 1
15
```

| Path start | Means | Like |
|---|---|---|
| `crate::` | the root of the current crate | [`global::`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/namespace-alias-qualifier) in C# |
| `super::` | the parent module | `..` in a file path |
| `self::` | the current module | `.` |
| a crate name (`std::`, `geometry::`) | an external crate | an assembly's root namespace |

`use` only creates a shortcut; without it you must write the full path. The compiler suggests the missing import:

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

[`pub use`](https://doc.rust-lang.org/reference/items/use-declarations.html#use-visibility) **re-exports** a name so that callers see a simpler path than your internal layout — the library in the next section uses it.

## Modules in files

`mod shapes;` with a semicolon instead of a `{ … }` body tells the compiler to load the module from a file:

| Declaration | In file | Module body is in |
|---|---|---|
| `mod shapes;` | `src/lib.rs` or `src/main.rs` | `src/shapes.rs` (or the older `src/shapes/mod.rs`) |
| `pub mod http;` | `src/network.rs` | `src/network/http.rs` |

The file contains the body only — no `mod shapes { }` wrapper. A `.rs` file that no `mod` declaration reaches is simply ignored, even though it sits in `src/`.

## Crates and packages

A package can contain one **library crate** (`src/lib.rs`) and any number of **binary crates** (`src/main.rs`, `src/bin/*.rs`). The course code itself is a library with doctests plus `examples/`, which Cargo builds as extra binaries.

Dependencies go in `Cargo.toml`, or are added with [`cargo add`](https://doc.rust-lang.org/cargo/commands/cargo-add.html):

```toml
[dependencies]
serde = "1.0"                                   # from crates.io
geometry = { path = "../geometry" }             # a local crate
```

| Cargo | .NET | Maven/Gradle |
|---|---|---|
| `serde = "1.0"` means `>=1.0.0, <2.0.0` (caret, [SemVer](https://semver.org/)-compatible updates) | [`Version="1.0"`](https://learn.microsoft.com/nuget/concepts/package-versioning#version-ranges) means `>=1.0` | `1.0` is a [soft requirement](https://maven.apache.org/pom.html#Dependency_Version_Requirement_Specification) that conflict resolution may override; ranges are written `[1.0,2.0)` |
| [`Cargo.lock`](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html) pins exact versions | [`packages.lock.json`](https://learn.microsoft.com/nuget/consume-packages/package-references-in-project-files#locking-dependencies) | lock files / [dependency locking](https://docs.gradle.org/current/userguide/dependency_locking.html) |
| [`cargo tree`](https://doc.rust-lang.org/cargo/commands/cargo-tree.html) | [`dotnet list package --include-transitive`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-list) | [`mvn dependency:tree`](https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html) |

### Features: compile-time options

A crate can declare **features** that turn optional code on. Features are additive switches checked with [`#[cfg]`](https://doc.rust-lang.org/reference/conditional-compilation.html), closer to C# [`#if`](https://learn.microsoft.com/dotnet/csharp/language-reference/preprocessor-directives#conditional-compilation) symbols than to runtime configuration:

```toml
# geometry/Cargo.toml
[features]
default = []
display = []
```

```rust
// geometry/src/shapes.rs — only compiled when a dependent enables `display`
#[cfg(feature = "display")]
impl std::fmt::Display for Rect {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{}x{} rectangle", self.width, self.height)
    }
}
```

If `app` forgets to enable it, `Rect` simply has no `Display` implementation:

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

A workspace is a solution: several packages that share one `Cargo.lock` and one `target/` folder, built and tested with one command. The course's [`l10-workspace`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l10-workspace):

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

# Shared by every member that opts in with `x.workspace = true`
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

`[workspace.dependencies]` plays the role of .NET [*Central Package Management*](https://learn.microsoft.com/nuget/consume-packages/central-package-management) (`Directory.Packages.props`) or a Maven [`<dependencyManagement>`](https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Dependency_Management) section: versions are declared once, members only say `workspace = true`.

```rust
// geometry/src/lib.rs
mod shapes;          // private module, loaded from src/shapes.rs
pub mod units;       // public module, loaded from src/units.rs

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

Visibility now works across crates. `shapes` is a private module and `non_negative` is `pub(crate)`, so `app` can use neither:

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

Everyday commands, run from the workspace root:

| Command | Does |
|---|---|
| `cargo build` | builds every member |
| `cargo run -p app` | runs one package, like [`dotnet run --project app`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run) |
| `cargo test --workspace` | tests every member |
| `cargo tree` | shows the dependency graph |

```text
app v0.1.0 (…\l10-workspace\app)
└── geometry v0.1.0 (…\l10-workspace\geometry)
```

:::tip[Unit tests live next to the code]
`geometry/src/lib.rs` ends with a `#[cfg(test)] mod tests { use super::*; … }` block. Because `tests` is a child module, it can even call private functions. Testing gets its own lesson, 14.
:::

## Key takeaways

- A module is a privacy scope; a crate is a compilation unit; a package is a `Cargo.toml`; a workspace groups packages.
- Everything is private by default; `pub(crate)` is `internal`, `pub` is `public`, and struct fields need their own `pub`.
- `use` creates shortcuts, `pub use` re-exports, paths start from `crate`, `super`, `self` or a crate name.
- `mod name;` loads `name.rs`; files that no module declares are not compiled.
- Cargo versions are SemVer-compatible ranges pinned by `Cargo.lock`; features are compile-time switches.
- Workspaces share a lock file and build output, and can centralise versions in `[workspace.dependencies]`.

## Exercises

1. Write a module `temperature` with a `pub struct Celsius(f64)` that **cannot** hold a value below absolute zero (−273.15). Outside the module, `temperature::Celsius(-500.0)` must not compile.

<details>
<summary>Solution</summary>

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

The field `f64` has no `pub`, so the tuple constructor is private:

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

2. A binary crate's `src/main.rs` contains `mod network { pub mod http { pub fn get(host: &str) -> String { … } } }`. Move each module into its own file. Which files do you create, and what does `main.rs` keep?

<details>
<summary>Solution</summary>

```text
src/
├── main.rs            mod network;   +  fn main() { … network::http::get("example.com") … }
├── network.rs         pub mod http;
└── network/
    └── http.rs        pub fn get(host: &str) -> String { format!("GET http://{host}/") }
```

`main.rs` declares `network`, `network.rs` declares `http`, and `http.rs` holds the body. Running it prints `GET http://example.com/`.

</details>

3. Add a third member, `report`, to `l10-workspace`: a library with `pub fn describe(shapes: &[Box<dyn Shape>]) -> String` returning e.g. `"2 shapes, total area 9.14"`, and a unit test. What changes in which `Cargo.toml`?

<details>
<summary>Solution</summary>

In the root `Cargo.toml`: `members = ["geometry", "app", "report"]`. Then:

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

`cargo test -p report` runs the test. `report` does not need the `display` feature, so it does not ask for it.

</details>

## Sources

- [The Book, ch. 7 — Managing Growing Projects with Packages, Crates, and Modules](https://doc.rust-lang.org/book/ch07-00-managing-growing-projects-with-packages-crates-and-modules.html)
- [The Rust Reference — Visibility and privacy](https://doc.rust-lang.org/reference/visibility-and-privacy.html)
- [The Cargo Book — Specifying dependencies](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html)
- [The Cargo Book — Features](https://doc.rust-lang.org/cargo/reference/features.html)
- [The Cargo Book — Workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html)
