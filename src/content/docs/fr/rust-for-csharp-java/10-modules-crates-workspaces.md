---
title: 10. Modules, crates et workspaces
description: Namespaces, assemblies et solutions en Rust — visibilité, fichiers, dépendances, features et workspaces multi-crates.
sidebar:
  order: 10
---

Exemple complet : [`examples/l10_modules.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l10_modules.rs) — `cargo run --example l10_modules`.
Workspace : [`l10-workspace/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l10-workspace) — `cargo run -p app` depuis ce dossier.

## Vocabulaire

| Rust | C# | Java |
|---|---|---|
| **module** (`mod`) | [namespace](https://learn.microsoft.com/dotnet/csharp/fundamentals/program-structure/namespaces) | [package](https://docs.oracle.com/javase/tutorial/java/package/packages.html) |
| **crate** — une unité de compilation, bibliothèque ou exécutable | [assembly](https://learn.microsoft.com/dotnet/standard/assembly/) (`.dll` / `.exe`) | [JAR](https://docs.oracle.com/javase/tutorial/deployment/jar/) |
| **package** — un [`Cargo.toml`](https://doc.rust-lang.org/cargo/reference/manifest.html) qui construit une ou plusieurs crates | [projet (`.csproj`)](https://learn.microsoft.com/dotnet/core/project-sdk/overview) | module [Maven](https://maven.apache.org/)/[Gradle](https://gradle.org/) |
| **workspace** — plusieurs packages construits ensemble | [solution (`.sln`)](https://learn.microsoft.com/visualstudio/ide/solutions-and-projects-in-visual-studio) | [build multi-modules (POM parent)](https://maven.apache.org/guides/mini/guide-multiple-modules.html) |
| [crates.io](https://crates.io) | [NuGet](https://www.nuget.org/) | [Maven Central](https://central.sonatype.com/) |

Deux différences ressortent. Un namespace C# n'est qu'un préfixe de nommage et n'importe quel fichier peut y ajouter des éléments ; un module Rust est une véritable **portée** avec sa propre confidentialité, et l'arbre des modules est déclaré explicitement. Et en C#, chaque fichier `.cs` du dossier du projet est compilé ; en Rust, un fichier n'est compilé que si un module le déclare.

## Modules et confidentialité

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

Tout est **privé par défaut**. Un élément privé est visible dans le module qui le définit **et dans les enfants de ce module** — `rates` pourrait donc appeler `tax` via `super::tax`, mais `main`, en dehors de `billing`, ne le peut pas.

| Rust | Visible depuis | C# | Java |
|---|---|---|---|
| *(rien)* | ce module et ses enfants | `private` | `private` |
| `pub(super)` | le module parent aussi | — | — |
| `pub(crate)` | toute la crate | [`internal`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/internal) | [package-private](https://docs.oracle.com/javase/tutorial/java/javaOO/accesscontrol.html) (à peu près) |
| `pub` | partout où le module parent est visible | `public` | `public` |

Il n'y a pas de `protected` : Rust n'a pas d'héritage entre structs.

### Les champs d'une struct sont privés séparément

`pub struct` rend le **type** public, pas ses champs. C'est ainsi que Rust garantit les invariants — l'équivalent d'une classe avec des champs privés et un constructeur :

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

Lire `r.width` depuis l'extérieur échoue de la même manière (`E0616: field width of struct Rect is private`). Le code extérieur doit passer par `Rect::new`, qui ramène les tailles négatives à zéro. Les variantes d'un `pub enum`, en revanche, sont toujours publiques.

## Chemins et `use`

```rust
use billing::discounts::with_discount;       // amène une fonction dans la portée
use billing::rates::SALES_TAX as TAX;        // renomme, comme `using X = …`
use shapes::Rect;

mod billing {
    // …
    pub mod discounts {
        pub fn with_discount(amounts: &[f64], percent: f64) -> f64 {
            super::invoice_total(amounts) * (1.0 - percent / 100.0)   // module parent
        }
    }
}

println!("{}", crate::billing::rates::SALES_TAX * 100.0);   // chemin absolu depuis la racine de la crate
```

```text
total: 172.50
with 10% off: 155.25
tax rate: 0.15
clamped area: 0
unit square: 1
15
```

| Début du chemin | Signifie | Comme |
|---|---|---|
| `crate::` | la racine de la crate courante | [`global::`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/namespace-alias-qualifier) en C# |
| `super::` | le module parent | `..` dans un chemin de fichier |
| `self::` | le module courant | `.` |
| un nom de crate (`std::`, `geometry::`) | une crate externe | l'espace de noms racine d'une assembly |

`use` ne fait que créer un raccourci ; sans lui, vous devez écrire le chemin complet. Le compilateur suggère l'import manquant :

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

[`pub use`](https://doc.rust-lang.org/reference/items/use-declarations.html#use-visibility) **réexporte** un nom, afin que les appelants voient un chemin plus simple que votre organisation interne — la bibliothèque de la section suivante s'en sert.

## Des modules dans des fichiers

`mod shapes;` avec un point-virgule au lieu d'un corps `{ … }` indique au compilateur de charger le module depuis un fichier :

| Déclaration | Dans le fichier | Le corps du module se trouve dans |
|---|---|---|
| `mod shapes;` | `src/lib.rs` ou `src/main.rs` | `src/shapes.rs` (ou l'ancien `src/shapes/mod.rs`) |
| `pub mod http;` | `src/network.rs` | `src/network/http.rs` |

Le fichier ne contient que le corps — pas d'enveloppe `mod shapes { }`. Un fichier `.rs` qu'aucune déclaration `mod` n'atteint est tout simplement ignoré, même s'il se trouve dans `src/`.

## Crates et packages

Un package peut contenir une **crate bibliothèque** (`src/lib.rs`) et un nombre quelconque de **crates binaires** (`src/main.rs`, `src/bin/*.rs`). Le code du cours lui-même est une bibliothèque avec des doctests, plus des `examples/`, que Cargo construit comme binaires supplémentaires.

Les dépendances se déclarent dans `Cargo.toml`, ou s'ajoutent avec [`cargo add`](https://doc.rust-lang.org/cargo/commands/cargo-add.html) :

```toml
[dependencies]
serde = "1.0"                                   # depuis crates.io
geometry = { path = "../geometry" }             # une crate locale
```

| Cargo | .NET | Maven/Gradle |
|---|---|---|
| `serde = "1.0"` signifie `>=1.0.0, <2.0.0` (caret, mises à jour compatibles [SemVer](https://semver.org/)) | [`Version="1.0"`](https://learn.microsoft.com/nuget/concepts/package-versioning#version-ranges) signifie `>=1.0` | `1.0` est une [exigence souple](https://maven.apache.org/pom.html#Dependency_Version_Requirement_Specification) que la résolution de conflits peut outrepasser ; les intervalles s'écrivent `[1.0,2.0)` |
| [`Cargo.lock`](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html) fige les versions exactes | [`packages.lock.json`](https://learn.microsoft.com/nuget/consume-packages/package-references-in-project-files#locking-dependencies) | fichiers de verrouillage / [dependency locking](https://docs.gradle.org/current/userguide/dependency_locking.html) |
| [`cargo tree`](https://doc.rust-lang.org/cargo/commands/cargo-tree.html) | [`dotnet list package --include-transitive`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-list) | [`mvn dependency:tree`](https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html) |

### Features : des options à la compilation

Une crate peut déclarer des **features** qui activent du code optionnel. Les features sont des interrupteurs additifs testés avec [`#[cfg]`](https://doc.rust-lang.org/reference/conditional-compilation.html), plus proches des symboles [`#if`](https://learn.microsoft.com/dotnet/csharp/language-reference/preprocessor-directives#conditional-compilation) de C# que d'une configuration à l'exécution :

```toml
# geometry/Cargo.toml
[features]
default = []
display = []
```

```rust
// geometry/src/shapes.rs — compilé seulement quand un dépendant active `display`
#[cfg(feature = "display")]
impl std::fmt::Display for Rect {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{}x{} rectangle", self.width, self.height)
    }
}
```

Si `app` oublie de l'activer, `Rect` n'a tout simplement pas d'implémentation de `Display` :

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

Un workspace est une solution : plusieurs packages qui partagent un même `Cargo.lock` et un même dossier `target/`, construits et testés en une seule commande. Le [`l10-workspace`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l10-workspace) du cours :

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

# Partagé par chaque membre qui s'y inscrit avec `x.workspace = true`
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

`[workspace.dependencies]` joue le rôle du [*Central Package Management*](https://learn.microsoft.com/nuget/consume-packages/central-package-management) de .NET (`Directory.Packages.props`) ou d'une section Maven [`<dependencyManagement>`](https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Dependency_Management) : les versions sont déclarées une fois, les membres se contentent de `workspace = true`.

```rust
// geometry/src/lib.rs
mod shapes;          // module privé, chargé depuis src/shapes.rs
pub mod units;       // module public, chargé depuis src/units.rs

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

La visibilité fonctionne désormais d'une crate à l'autre. `shapes` est un module privé et `non_negative` est `pub(crate)`, donc `app` ne peut utiliser ni l'un ni l'autre :

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

Commandes courantes, lancées depuis la racine du workspace :

| Commande | Effet |
|---|---|
| `cargo build` | construit tous les membres |
| `cargo run -p app` | exécute un seul package, comme [`dotnet run --project app`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run) |
| `cargo test --workspace` | teste tous les membres |
| `cargo tree` | affiche le graphe des dépendances |

```text
app v0.1.0 (…\l10-workspace\app)
└── geometry v0.1.0 (…\l10-workspace\geometry)
```

:::tip[Les tests unitaires vivent à côté du code]
`geometry/src/lib.rs` se termine par un bloc `#[cfg(test)] mod tests { use super::*; … }`. Comme `tests` est un module enfant, il peut même appeler des fonctions privées. Les tests auront leur propre leçon, la 14.
:::

## À retenir

- Un module est une portée de confidentialité ; une crate est une unité de compilation ; un package est un `Cargo.toml` ; un workspace regroupe des packages.
- Tout est privé par défaut ; `pub(crate)` correspond à `internal`, `pub` à `public`, et les champs d'une struct ont besoin de leur propre `pub`.
- `use` crée des raccourcis, `pub use` réexporte, les chemins partent de `crate`, `super`, `self` ou d'un nom de crate.
- `mod name;` charge `name.rs` ; les fichiers qu'aucun module ne déclare ne sont pas compilés.
- Les versions Cargo sont des intervalles compatibles SemVer, figés par `Cargo.lock` ; les features sont des interrupteurs à la compilation.
- Les workspaces partagent un fichier de verrouillage et la sortie de build, et peuvent centraliser les versions dans `[workspace.dependencies]`.

## Exercices

1. Écrivez un module `temperature` avec une `pub struct Celsius(f64)` qui ne **peut pas** contenir une valeur inférieure au zéro absolu (−273.15). En dehors du module, `temperature::Celsius(-500.0)` ne doit pas compiler.

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

Le champ `f64` n'a pas de `pub`, donc le constructeur de tuple est privé :

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

2. Le `src/main.rs` d'une crate binaire contient `mod network { pub mod http { pub fn get(host: &str) -> String { … } } }`. Déplacez chaque module dans son propre fichier. Quels fichiers créez-vous, et que conserve `main.rs` ?

<details>
<summary>Solution</summary>

```text
src/
├── main.rs            mod network;   +  fn main() { … network::http::get("example.com") … }
├── network.rs         pub mod http;
└── network/
    └── http.rs        pub fn get(host: &str) -> String { format!("GET http://{host}/") }
```

`main.rs` déclare `network`, `network.rs` déclare `http`, et `http.rs` contient le corps. L'exécution affiche `GET http://example.com/`.

</details>

3. Ajoutez un troisième membre, `report`, à `l10-workspace` : une bibliothèque avec `pub fn describe(shapes: &[Box<dyn Shape>]) -> String` qui renvoie par exemple `"2 shapes, total area 9.14"`, et un test unitaire. Qu'est-ce qui change, et dans quel `Cargo.toml` ?

<details>
<summary>Solution</summary>

Dans le `Cargo.toml` racine : `members = ["geometry", "app", "report"]`. Puis :

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

`cargo test -p report` exécute le test. `report` n'a pas besoin de la feature `display`, il ne la demande donc pas.

</details>

## Sources

- [The Book, ch. 7 — Managing Growing Projects with Packages, Crates, and Modules](https://doc.rust-lang.org/book/ch07-00-managing-growing-projects-with-packages-crates-and-modules.html)
- [The Rust Reference — Visibility and privacy](https://doc.rust-lang.org/reference/visibility-and-privacy.html)
- [The Cargo Book — Specifying dependencies](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html)
- [The Cargo Book — Features](https://doc.rust-lang.org/cargo/reference/features.html)
- [The Cargo Book — Workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html)
