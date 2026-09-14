---
title: V for C#/Java developers — Mission
description: Learn the V language from what you already know in C# and Java — every example, compiler error and panic run in CI on Windows, Linux and macOS.
sidebar:
  label: Mission
  order: 0
---

:::note[Version studied]
[V](https://vlang.io/) **0.5.2**, the [release of July 2026](https://github.com/vlang/v/releases/tag/0.5.2). Every example of this course is in [`code/v-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/v-for-csharp-java), next to its expected output. [`.github/workflows/v-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/v-examples.yml) installs V 0.5.2 from the GitHub release on Linux, Windows and macOS, runs every example, compiles every snippet a lesson shows as rejected, and compares the outputs and compiler messages with the ones pasted in the lessons.
:::

## Why I'm learning this

V promises a small language, close to Go, that compiles to C in about a second, with immutable variables by default, no `null`, no exceptions, and a garbage collector you can turn off.
I write C# and read plenty of Java. I want to know which of these promises hold in version 0.5.2, what V costs in exchange, and where its documentation and its compiler disagree.

## Who this course is for

You are comfortable with C# or Java: classes, interfaces, generics, exceptions, collections, [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/) or [streams](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html).
You have never written V, and you don't need to know C. Each lesson starts from the concept you already know and shows where V agrees, where it differs, and what the compiler says when you get it wrong.

## V in one table

| | C# | Java | V |
|---|---|---|---|
| Compiles to | IL, run by the CLR | bytecode, run by the JVM | C, compiled to a native executable |
| Build tool | [`dotnet`](https://learn.microsoft.com/dotnet/core/tools/) | [Maven](https://maven.apache.org/), [Gradle](https://gradle.org/) | `v` itself |
| Project file | `.csproj` | `pom.xml`, `build.gradle` | `v.mod` (optional) |
| Local variable | `var x = 1;` (mutable) | `var x = 1;` (mutable) | `x := 1` (immutable), `mut x := 1` |
| Class | `class`, `record`, `struct` | `class`, `record` | `struct` with methods, no inheritance |
| Absent value | `null`, `int?` | `null`, `Optional<T>` | `?T` and `none` |
| Failure | exceptions | checked and unchecked exceptions | `!T`, `error()` and `or { }` |
| Memory | generational GC | GC (G1 by default) | Boehm GC by default, `-autofree`, `-gc none` |
| Namespaces | `namespace` | `package` | one module per folder |
| Visibility | `public`, `internal`, `private` | `public`, package-private, `private` | `pub` or private to the module |

Sources: [.NET garbage collection](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals), [G1 garbage collector](https://docs.oracle.com/en/java/javase/25/gctuning/garbage-first-g1-garbage-collector1.html), [V documentation](https://docs.vlang.io/introduction.html).

## The documentation and the version

[docs.vlang.io](https://docs.vlang.io/introduction.html) is built from `doc/docs.md` on V's `master` branch, which has moved on since 0.5.2: its page [The default compiler](https://docs.vlang.io/the-default-compiler.html), for example, isn't in the documentation of 0.5.2. This course links to docs.vlang.io for the concepts and checks every behavior with 0.5.2 itself; the documentation of the version studied is [`doc/docs.md` at the 0.5.2 tag](https://github.com/vlang/v/blob/0.5.2/doc/docs.md), and the standard library is described at [modules.vlang.io](https://modules.vlang.io/).

## The data

Lessons 3 and 4 read [`code/v-for-csharp-java/data/pages.csv`](https://github.com/spareilleux/learn/blob/main/code/v-for-csharp-java/data/pages.csv): the 319 pages of this site at commit `cbcbb42`, with their locale, course, title and number of lines. It is a copy of the file the [LadybugDB course](../ladybugdb/) extracts from this repository.

## By the end of this course, I will be able to

- install V on Windows, Linux and macOS, and organize a program in modules;
- model data with structs, methods, interfaces and sum types instead of classes;
- handle absence and failure with `?`, `!` and `or { }` instead of `null` and exceptions;
- say where an array, a map or a struct is copied, shared or freed;
- write concurrent code with `spawn` and channels;
- test, format and document a module, and call a C library.

## Outline

| # | Lesson | You already know |
|---|---|---|
| 1 | [Installation, `v run`, modules and projects](01-install-and-projects/) | `dotnet new`, `dotnet run`, `javac`, `java` |
| 2 | [Types, immutable variables, structs and methods](02-types-structs-methods/) | `var`, `readonly`/`final`, classes, records |
| 3 | [Errors: `?`, `!` and `or { }`](03-errors-option-result/) | `null`, `Optional`, exceptions |
| 4 | [Arrays, maps, slices and memory](04-arrays-maps-memory/) | `List<T>`, `Dictionary`, `ArrayList`, `HashMap`, the GC |
| 5 | Interfaces and generics (coming next) | interfaces, generics |
| 6 | Sum types, enums and `match` | sealed hierarchies, `switch` expressions |
| 7 | Concurrency: `spawn`, channels and `shared` | `Task`, `Thread`, `lock`/`synchronized` |
| 8 | Tests, `v fmt`, `v vet`, docs and packages | xUnit/JUnit, analyzers, NuGet/Maven Central |
| 9 | Calling C | P/Invoke, JNI, the FFM API |
| 10 | JSON and a web server with `veb` | `System.Text.Json`, ASP.NET Core, Jackson, Spring |
| 11 | The ORM and SQLite | Entity Framework, JPA |
| 12 | Cross-compilation and deployment | `dotnet publish`, `jlink` |
| — | [Journal](journal/) | |

## Resources

- [V documentation](https://docs.vlang.io/introduction.html), and [`doc/docs.md` at the 0.5.2 tag](https://github.com/vlang/v/blob/0.5.2/doc/docs.md)
- [V standard library](https://modules.vlang.io/)
- [V source code](https://github.com/vlang/v), and the [0.5.2 release](https://github.com/vlang/v/releases/tag/0.5.2) this course uses
- [V's language tests](https://github.com/vlang/v/tree/0.5.2/vlib/v/tests): the documentation says the compiler and its tests are the reference when they disagree with it
