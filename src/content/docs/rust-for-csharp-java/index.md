---
title: Rust for C#/Java developers — Mission
description: Learn Rust from scratch, building on what you already know from C# and Java, then build a desktop application with Tauri.
sidebar:
  label: Mission
  order: 0
---

:::note[Version studied]
Rust **1.94.0**, edition **2024**. Every code sample in this course is compiled and run in CI from [`code/rust-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java); every "this does not compile" snippet is a `compile_fail` doctest.

Part 2 pins **Tauri 2.11.5**. Its application, [`code/rust-for-csharp-java/l16-tauri`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri), is built, linted and tested by CI on Windows, Ubuntu and macOS; its window has only been run on Windows.
:::

## Why I'm learning this

I write C# (and read plenty of Java), and a growing part of my ecosystem — [IX](https://github.com/GuitarAlchemist/ix), [hari](https://github.com/GuitarAlchemist/hari) — is written in Rust.
I want to read and change that code with confidence instead of guessing, and understand *why* the compiler rejects what would be perfectly fine in C#.
Then I want to know whether Rust is a serious option for the desktop applications I would otherwise write with [WPF](https://learn.microsoft.com/dotnet/desktop/wpf/overview/), [.NET MAUI](https://learn.microsoft.com/dotnet/maui/what-is-maui), [JavaFX](https://openjfx.io/) or [Electron](https://www.electronjs.org/).

## Who this course is for

You are comfortable with C# or Java: classes, interfaces, generics, exceptions, collections, [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/) or [Streams](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html), `async`/`await` or `CompletableFuture`.
You have never written Rust. Each lesson starts from the concept you already know and shows where Rust agrees, where it differs, and why.

## By the end of this course, I will be able to

- set up a Rust project with Cargo and navigate the tooling;
- explain ownership, borrowing and lifetimes in terms of what a garbage collector normally does for me;
- model data with `struct`, `enum` and `match` instead of class hierarchies;
- handle errors with `Option`, `Result` and `?` instead of `null` and exceptions;
- use traits, generics and iterators the way I use interfaces, generics and LINQ/Streams;
- write safe concurrent and async code;
- test, document and lint a crate;
- choose between Rust's desktop UI toolkits, and build a Tauri application whose web UI calls Rust commands, shares state and receives events and streams;
- secure, test and package that application for Windows, Linux and macOS.

## Outline

### Part 1 — The language

| # | Lesson | You already know |
|---|---|---|
| 1 | [Toolchain and Cargo](01-toolchain-and-cargo/) | [`dotnet` CLI](https://learn.microsoft.com/dotnet/core/tools/), [NuGet](https://www.nuget.org/), [Maven](https://maven.apache.org/)/[Gradle](https://gradle.org/) |
| 2 | [Types, mutability and expressions](02-types-mutability-expressions/) | `var`, `final`/`readonly`, `int`/`long`, ternaries |
| 3 | [Ownership and moves](03-ownership-and-moves/) | the garbage collector, [`IDisposable`](https://learn.microsoft.com/dotnet/api/system.idisposable), [try-with-resources](https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html) |
| 4 | [Borrowing and strings](04-borrowing-and-strings/) | references, `string`/`String`, [`StringBuilder`](https://learn.microsoft.com/dotnet/api/system.text.stringbuilder) |
| 5 | [Structs, enums and pattern matching](05-structs-enums-match/) | classes, [records](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record), [sealed hierarchies](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html), `switch` |
| 6 | [`Option`, `Result` and `?`](06-option-result/) | `null`, exceptions |
| 7 | [Traits and generics](07-traits-and-generics/) | interfaces, generics |
| 8 | [Collections and iterators](08-collections-and-iterators/) | LINQ, Streams |
| 9 | [Lifetimes](09-lifetimes/) | — |
| 10 | [Modules, crates and workspaces](10-modules-crates-workspaces/) | namespaces/packages, projects, solutions |
| 11 | [`Box`, `Rc`, `Arc`, `RefCell`](11-smart-pointers/) | references, shared objects |
| 12 | [Threads, `Send`/`Sync`, `Mutex`, rayon](12-threads-and-concurrency/) | `Thread`, `lock`/`synchronized`, `Parallel.For` |
| 13 | [`async` and tokio](13-async-and-tokio/) | `async`/`await`, `CompletableFuture` |
| 14 | [Tests, docs, clippy, fmt](14-tests-docs-tooling/) | [xUnit](https://xunit.net/)/[JUnit](https://junit.org/), XML docs/[Javadoc](https://docs.oracle.com/en/java/javase/25/javadoc/), analyzers |
| 15 | [Macros, `unsafe` and FFI](15-macros-unsafe-ffi/) (overview) | [source generators](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/source-generators-overview), [P/Invoke](https://learn.microsoft.com/dotnet/standard/native-interop/pinvoke), [JNI](https://docs.oracle.com/en/java/javase/25/docs/specs/jni/index.html) |

### Part 2 — Desktop applications with Tauri

The six lessons build one application, a chord explorer, in [`l16-tauri`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri).

| # | Lesson | You already know |
|---|---|---|
| 16 | [Desktop UI in Rust, then Tauri](16-desktop-ui-and-tauri/) | WPF, MAUI, JavaFX, Electron |
| 17 | [Tauri commands](17-tauri-commands/) | WPF commands, controllers, Electron's `ipcMain.handle` |
| 18 | [State, events and channels](18-tauri-state-events-channels/) | DI singletons, messengers, [`IProgress<T>`](https://learn.microsoft.com/dotnet/api/system.iprogress-1) |
| 19 | [The frontend: Vite, TypeScript and types generated from Rust](19-tauri-frontend-and-types/) | a TypeScript client generated from an API description |
| 20 | [Security: capabilities, CSP and plugins](20-tauri-security-and-plugins/) | Electron's context isolation, app permissions |
| 21 | [Tests, packaging and distribution](21-tauri-tests-and-packaging/) | [MSIX](https://learn.microsoft.com/windows/msix/overview), [`jpackage`](https://docs.oracle.com/en/java/javase/25/docs/specs/man/jpackage.html), installers |

A follow-up course, **Rust in practice: IX and co**, applies each of these ideas to real code in IX, hari and my other Rust repositories.

[Journal](journal/) — what I tried, what surprised me, what I still need to verify.

## Resources

- [The Rust Programming Language](https://doc.rust-lang.org/book/) ("the Book") — the official, free introduction.
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/) — short runnable examples.
- [The Cargo Book](https://doc.rust-lang.org/cargo/) — build tool and package manager.
- [Rust standard library docs](https://doc.rust-lang.org/std/).
- [Rust Error Codes Index](https://doc.rust-lang.org/error_codes/) — every `E0xxx` explained, also available offline with `rustc --explain E0382`.
