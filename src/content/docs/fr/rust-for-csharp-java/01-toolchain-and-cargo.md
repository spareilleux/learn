---
title: 1. Chaîne d'outils et Cargo
description: rustup, cargo et crates.io, mis en correspondance avec la CLI dotnet, NuGet et Maven.
sidebar:
  order: 1
---

## Les trois outils

| Rust | Rôle | C# | Java |
|---|---|---|---|
| `rustup` | installe et met à jour les chaînes d'outils | installeur du SDK .NET / `global.json` | SDKMAN!, installeurs du JDK |
| `cargo` | compiler, exécuter, tester, ajouter des dépendances | CLI `dotnet` | Maven / Gradle |
| crates.io | registre public de paquets | NuGet | Maven Central |
| `rustc` | le compilateur (Cargo l'appelle pour vous) | Roslyn (`csc`) | `javac` |

Installez depuis [rustup.rs](https://rustup.rs). Sous Windows, la chaîne d'outils par défaut cible MSVC : il vous faut donc aussi les **Visual Studio C++ Build Tools** (l'éditeur de liens).

```powershell
rustc --version   # rustc 1.94.0 (4a4ef493e 2026-03-02)
cargo --version   # cargo 1.94.0 (85eff7c80 2026-01-15)
rustup update     # passer à la dernière version stable
```

:::note[Aucun runtime à installer]
Rust compile en exécutable natif. Il n'y a ni CLR ni JVM à distribuer : le build release de « Hello, world! » est un unique `.exe` d'environ 130 Ko sous Windows.
:::

## Créer un projet

```powershell
cargo new hello
cd hello
cargo run
```

```text
    Creating binary (application) `hello` package
   Compiling hello v0.1.0 (…\hello)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 1.01s
     Running `target\debug\hello.exe`
Hello, world!
```

`cargo new` lance aussi `git init` et écrit un `.gitignore`. L'arborescence :

```text
hello/
├── Cargo.toml      ← like .csproj or pom.xml
├── src/
│   └── main.rs     ← entry point (a library would have src/lib.rs)
└── .gitignore
```

```toml
# Cargo.toml
[package]
name = "hello"
version = "0.1.0"
edition = "2024"

[dependencies]
```

```rust
// src/main.rs
fn main() {
    println!("Hello, world!");
}
```

- `println!` se termine par `!` parce que c'est une **macro**, pas une fonction (elle vérifie la chaîne de format à la compilation).
- L'**édition** (`2024`) joue le rôle de `<LangVersion>` ou de `--release` : elle active des changements du langage sans casser les crates plus anciennes, qui continuent de compiler avec leur propre édition.

## Commandes du quotidien

| Tâche | Cargo | dotnet | Maven |
|---|---|---|---|
| Nouvelle application | `cargo new app` | `dotnet new console` | `mvn archetype:generate` |
| Nouvelle bibliothèque | `cargo new --lib lib` | `dotnet new classlib` | — |
| Vérification rapide des types | `cargo check` | — | — |
| Compiler (debug) | `cargo build` | `dotnet build` | `mvn compile` |
| Compiler (release) | `cargo build --release` | `dotnet build -c Release` | `mvn package` |
| Exécuter | `cargo run` | `dotnet run` | `mvn exec:java` |
| Tester | `cargo test` | `dotnet test` | `mvn test` |
| Ajouter une dépendance | `cargo add rand` | `dotnet add package` | modifier `pom.xml` |
| Formater | `cargo fmt` | `dotnet format` | plugin Spotless |
| Analyser (lint) | `cargo clippy` | analyseurs Roslyn | Error Prone, SpotBugs |
| Documentation d'API | `cargo doc --open` | docs XML + DocFX | `javadoc` |

:::tip[Utilisez `cargo check` en permanence]
`cargo check` exécute toute la vérification des types et le borrow checker, mais saute la génération de code. C'est bien plus rapide qu'un build, et c'est ce que fait votre éditeur (rust-analyzer) à chaque frappe.
:::

## Dépendances

```powershell
cargo add rand
```

```toml
[dependencies]
rand = "0.10.2"
```

- `"0.10.2"` signifie **compatible avec 0.10.2** (caret SemVer), et non « exactement 0.10.2 ».
- Les versions exactes résolues sont écrites dans `Cargo.lock` — comme `packages.lock.json` ou un fichier de verrouillage Gradle. Versionnez-le pour les applications.
- Les builds debug et release atterrissent dans `target/debug` et `target/release` (comme `bin/Debug` et `bin/Release`).

## À retenir

- `rustup` gère les compilateurs, `cargo` fait tout le reste, crates.io héberge les paquets.
- `Cargo.toml` + `Cargo.lock` ≈ `.csproj` + fichier de verrouillage / `pom.xml`.
- `cargo check` pour un retour rapide, `cargo build --release` pour des binaires optimisés.

## Exercices

1. Créez un projet nommé `dice`, ajoutez la crate `rand`, et trouvez dans `Cargo.lock` quelle version a réellement été résolue.

<details>
<summary>Solution</summary>

```powershell
cargo new dice
cd dice
cargo add rand
cargo build
Select-String -Path Cargo.lock -Pattern 'name = "rand"' -Context 0,1
```

`Cargo.toml` contient l'exigence que vous avez demandée ; `Cargo.lock` contient la version exacte (et chaque dépendance transitive) qui a été choisie.

</details>

2. Quelle est la différence entre `cargo check` et `cargo build`, et quand utiliser chacun ?

<details>
<summary>Solution</summary>

`cargo check` vérifie les types et les emprunts sans produire de binaire, il est donc rapide — utilisez-le pendant l'édition. `cargo build` génère aussi le code machine — utilisez-le quand vous devez exécuter le programme, et `cargo build --release` pour une version optimisée.

</details>

## Sources

- [The Book, ch. 1 — Getting Started](https://doc.rust-lang.org/book/ch01-00-getting-started.html)
- [The Cargo Book — Specifying dependencies](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html)
- [The Rust Edition Guide](https://doc.rust-lang.org/edition-guide/)
