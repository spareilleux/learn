---
title: Rust pour développeurs C#/Java — Mission
description: Apprendre Rust de zéro en s'appuyant sur ce que l'on connaît déjà de C# et de Java.
sidebar:
  label: Mission
  order: 0
---

:::note[Version étudiée]
Rust **1.94.0**, édition **2024**. Chaque exemple de code de ce cours est compilé et exécuté en CI depuis [`code/rust-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java) ; chaque extrait « ceci ne compile pas » est un doctest `compile_fail`.
:::

## Pourquoi j'apprends ça

J'écris du C# (et je lis beaucoup de Java), et une part croissante de mon écosystème — [IX](https://github.com/GuitarAlchemist/ix), [hari](https://github.com/GuitarAlchemist/hari) — est écrite en Rust.
Je veux lire et modifier ce code avec assurance au lieu de deviner, et comprendre *pourquoi* le compilateur rejette ce qui serait parfaitement valable en C#.

## À qui s'adresse ce cours

Vous êtes à l'aise avec C# ou Java : classes, interfaces, génériques, exceptions, collections, LINQ ou Streams, `async`/`await` ou `CompletableFuture`.
Vous n'avez jamais écrit de Rust. Chaque leçon part du concept que vous connaissez déjà et montre où Rust est d'accord, où il diffère, et pourquoi.

## À la fin de ce cours, je saurai

- mettre en place un projet Rust avec Cargo et m'y retrouver dans l'outillage ;
- expliquer la possession (ownership), l'emprunt et les durées de vie (lifetimes) en partant de ce qu'un ramasse-miettes fait normalement pour moi ;
- modéliser des données avec `struct`, `enum` et `match` au lieu de hiérarchies de classes ;
- gérer les erreurs avec `Option`, `Result` et `?` au lieu de `null` et des exceptions ;
- utiliser les traits, les génériques et les itérateurs comme j'utilise les interfaces, les génériques et LINQ/Streams ;
- écrire du code concurrent et asynchrone sûr ;
- tester, documenter et analyser (lint) une crate.

## Plan

| # | Leçon | Vous connaissez déjà |
|---|---|---|
| 1 | [Chaîne d'outils et Cargo](01-toolchain-and-cargo/) | CLI `dotnet`, NuGet, Maven/Gradle |
| 2 | [Types, mutabilité et expressions](02-types-mutability-expressions/) | `var`, `final`/`readonly`, `int`/`long`, ternaires |
| 3 | [Possession et déplacements](03-ownership-and-moves/) | le ramasse-miettes, `IDisposable`, try-with-resources |
| 4 | [Emprunts et chaînes](04-borrowing-and-strings/) | références, `string`/`String`, `StringBuilder` |
| 5 | [Structs, enums et pattern matching](05-structs-enums-match/) | classes, records, hiérarchies scellées, `switch` |
| 6 | [`Option`, `Result` et `?`](06-option-result/) | `null`, exceptions |
| 7 | [Traits et génériques](07-traits-and-generics/) | interfaces, génériques |
| 8 | [Collections et itérateurs](08-collections-and-iterators/) | LINQ, Streams |
| 9 | Durées de vie (lifetimes) *(à venir)* | — |
| 10 | Modules, crates et workspaces | namespaces/packages, projets, solutions |
| 11 | `Box`, `Rc`, `Arc`, `RefCell` | références, objets partagés |
| 12 | Threads, `Send`/`Sync`, `Mutex`, rayon | `Thread`, `lock`/`synchronized`, `Parallel.For` |
| 13 | `async` et tokio | `async`/`await`, `CompletableFuture` |
| 14 | Tests, docs, clippy, fmt | xUnit/JUnit, docs XML/Javadoc, analyseurs |
| 15 | Macros, `unsafe` et FFI (aperçu) | générateurs de source, P/Invoke, JNI |

Un cours de suite, **Rust en pratique : IX et cie**, applique chacune de ces idées à du vrai code dans IX, hari et mes autres dépôts Rust.

[Journal](journal/) — ce que j'ai essayé, ce qui m'a surpris, ce qu'il me reste à vérifier.

## Ressources

- [The Rust Programming Language](https://doc.rust-lang.org/book/) (« le Book ») — l'introduction officielle et gratuite.
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/) — de courts exemples exécutables.
- [The Cargo Book](https://doc.rust-lang.org/cargo/) — outil de build et gestionnaire de paquets.
- [Documentation de la bibliothèque standard Rust](https://doc.rust-lang.org/std/).
- [Rust Error Codes Index](https://doc.rust-lang.org/error_codes/) — chaque `E0xxx` expliqué, également disponible hors ligne avec `rustc --explain E0382`.
