---
title: Rust pour développeurs C#/Java — Mission
description: Apprendre Rust de zéro en s'appuyant sur ce que l'on connaît déjà de C# et de Java, puis construire une application de bureau avec Tauri.
sidebar:
  label: Mission
  order: 0
---

:::note[Version étudiée]
Rust **1.94.0**, édition **2024**. Chaque exemple de code de ce cours est compilé et exécuté en CI depuis [`code/rust-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java) ; chaque extrait « ceci ne compile pas » est un doctest `compile_fail`.

La partie 2 fixe **Tauri 2.11.5**. Son application, [`code/rust-for-csharp-java/l16-tauri`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri), est compilée, analysée par clippy et testée par la CI sous Windows, Ubuntu et macOS ; sa fenêtre n'a été lancée que sous Windows.
:::

## Pourquoi j'apprends ça

J'écris du C# (et je lis beaucoup de Java), et une part croissante de mon écosystème — [IX](https://github.com/GuitarAlchemist/ix), [hari](https://github.com/GuitarAlchemist/hari) — est écrite en Rust.
Je veux lire et modifier ce code avec assurance au lieu de deviner, et comprendre *pourquoi* le compilateur rejette ce qui serait parfaitement valable en C#.
Ensuite, je veux savoir si Rust est une option sérieuse pour les applications de bureau que j'écrirais sinon avec [WPF](https://learn.microsoft.com/dotnet/desktop/wpf/overview/), [.NET MAUI](https://learn.microsoft.com/dotnet/maui/what-is-maui), [JavaFX](https://openjfx.io/) ou [Electron](https://www.electronjs.org/).

## À qui s'adresse ce cours

Vous êtes à l'aise avec C# ou Java : classes, interfaces, génériques, exceptions, collections, [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/) ou [Streams](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html), `async`/`await` ou `CompletableFuture`.
Vous n'avez jamais écrit de Rust. Chaque leçon part du concept que vous connaissez déjà et montre où Rust est d'accord, où il diffère, et pourquoi.

## À la fin de ce cours, je saurai

- mettre en place un projet Rust avec Cargo et m'y retrouver dans l'outillage ;
- expliquer la possession (ownership), l'emprunt et les durées de vie (lifetimes) en partant de ce qu'un ramasse-miettes fait normalement pour moi ;
- modéliser des données avec `struct`, `enum` et `match` au lieu de hiérarchies de classes ;
- gérer les erreurs avec `Option`, `Result` et `?` au lieu de `null` et des exceptions ;
- utiliser les traits, les génériques et les itérateurs comme j'utilise les interfaces, les génériques et LINQ/Streams ;
- écrire du code concurrent et asynchrone sûr ;
- tester, documenter et analyser (lint) une crate ;
- choisir entre les toolkits d'interface de bureau de Rust, et construire une application Tauri dont l'interface web appelle des commandes Rust, partage un état et reçoit des événements et des flux ;
- sécuriser, tester et empaqueter cette application pour Windows, Linux et macOS.

## Plan

### Partie 1 — Le langage

| # | Leçon | Vous connaissez déjà |
|---|---|---|
| 1 | [Chaîne d'outils et Cargo](01-toolchain-and-cargo/) | [CLI `dotnet`](https://learn.microsoft.com/dotnet/core/tools/), [NuGet](https://www.nuget.org/), [Maven](https://maven.apache.org/)/[Gradle](https://gradle.org/) |
| 2 | [Types, mutabilité et expressions](02-types-mutability-expressions/) | `var`, `final`/`readonly`, `int`/`long`, ternaires |
| 3 | [Possession et déplacements](03-ownership-and-moves/) | le ramasse-miettes, [`IDisposable`](https://learn.microsoft.com/dotnet/api/system.idisposable), [try-with-resources](https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html) |
| 4 | [Emprunts et chaînes](04-borrowing-and-strings/) | références, `string`/`String`, [`StringBuilder`](https://learn.microsoft.com/dotnet/api/system.text.stringbuilder) |
| 5 | [Structs, enums et pattern matching](05-structs-enums-match/) | classes, [records](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record), [hiérarchies scellées](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html), `switch` |
| 6 | [`Option`, `Result` et `?`](06-option-result/) | `null`, exceptions |
| 7 | [Traits et génériques](07-traits-and-generics/) | interfaces, génériques |
| 8 | [Collections et itérateurs](08-collections-and-iterators/) | LINQ, Streams |
| 9 | [Durées de vie (lifetimes)](09-lifetimes/) | — |
| 10 | [Modules, crates et workspaces](10-modules-crates-workspaces/) | namespaces/packages, projets, solutions |
| 11 | [`Box`, `Rc`, `Arc`, `RefCell`](11-smart-pointers/) | références, objets partagés |
| 12 | [Threads, `Send`/`Sync`, `Mutex`, rayon](12-threads-and-concurrency/) | `Thread`, `lock`/`synchronized`, `Parallel.For` |
| 13 | [`async` et tokio](13-async-and-tokio/) | `async`/`await`, `CompletableFuture` |
| 14 | [Tests, docs, clippy, fmt](14-tests-docs-tooling/) | [xUnit](https://xunit.net/)/[JUnit](https://junit.org/), docs XML/[Javadoc](https://docs.oracle.com/en/java/javase/25/javadoc/), analyseurs |
| 15 | [Macros, `unsafe` et FFI](15-macros-unsafe-ffi/) (aperçu) | [générateurs de source](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/source-generators-overview), [P/Invoke](https://learn.microsoft.com/dotnet/standard/native-interop/pinvoke), [JNI](https://docs.oracle.com/en/java/javase/25/docs/specs/jni/index.html) |

### Partie 2 — Applications de bureau avec Tauri

Les six leçons construisent une seule application, un explorateur d'accords, dans [`l16-tauri`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri).

| # | Leçon | Vous connaissez déjà |
|---|---|---|
| 16 | [Interfaces de bureau en Rust, puis Tauri](16-desktop-ui-and-tauri/) | WPF, MAUI, JavaFX, Electron |
| 17 | [Commandes Tauri](17-tauri-commands/) | commandes WPF, contrôleurs, `ipcMain.handle` d'Electron |
| 18 | [État, événements et canaux](18-tauri-state-events-channels/) | singletons de l'injection de dépendances, messengers, [`IProgress<T>`](https://learn.microsoft.com/dotnet/api/system.iprogress-1) |
| 19 | [Le frontend : Vite, TypeScript et types générés depuis Rust](19-tauri-frontend-and-types/) | un client TypeScript généré à partir d'une description d'API |
| 20 | [Sécurité : capabilities, CSP et plugins](20-tauri-security-and-plugins/) | l'isolation de contexte d'Electron, les permissions d'application |
| 21 | [Tests, packaging et distribution](21-tauri-tests-and-packaging/) | [MSIX](https://learn.microsoft.com/windows/msix/overview), [`jpackage`](https://docs.oracle.com/en/java/javase/25/docs/specs/man/jpackage.html), installeurs |

Un cours de suite, **Rust en pratique : IX et cie**, applique chacune de ces idées à du vrai code dans IX, hari et mes autres dépôts Rust.

[Journal](journal/) — ce que j'ai essayé, ce qui m'a surpris, ce qu'il me reste à vérifier.

## Ressources

- [The Rust Programming Language](https://doc.rust-lang.org/book/) (« le Book ») — l'introduction officielle et gratuite.
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/) — de courts exemples exécutables.
- [The Cargo Book](https://doc.rust-lang.org/cargo/) — outil de build et gestionnaire de paquets.
- [Documentation de la bibliothèque standard Rust](https://doc.rust-lang.org/std/).
- [Rust Error Codes Index](https://doc.rust-lang.org/error_codes/) — chaque `E0xxx` expliqué, également disponible hors ligne avec `rustc --explain E0382`.
