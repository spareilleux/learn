---
title: Rust para desarrolladores C#/Java — Misión
description: Aprende Rust desde cero, apoyándote en lo que ya sabes de C# y Java.
sidebar:
  label: Misión
  order: 0
---

:::note[Versión estudiada]
Rust **1.94.0**, edición **2024**. Cada ejemplo de código de este curso se compila y ejecuta en CI desde [`code/rust-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java); cada fragmento «esto no compila» es un doctest `compile_fail`.
:::

## Por qué aprendo esto

Escribo C# (y leo mucho Java), y una parte creciente de mi ecosistema — [IX](https://github.com/GuitarAlchemist/ix), [hari](https://github.com/GuitarAlchemist/hari) — está escrita en Rust.
Quiero leer y modificar ese código con seguridad en lugar de adivinar, y entender *por qué* el compilador rechaza lo que sería perfectamente válido en C#.

## Para quién es este curso

Te manejas con soltura en C# o Java: clases, interfaces, genéricos, excepciones, colecciones, [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/) o [Streams](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html), `async`/`await` o `CompletableFuture`.
Nunca has escrito Rust. Cada lección parte del concepto que ya conoces y muestra en qué coincide Rust, en qué difiere y por qué.

## Al final de este curso, sabré

- crear un proyecto Rust con Cargo y orientarme en sus herramientas;
- explicar el ownership (propiedad), el borrowing (préstamo) y los tiempos de vida (lifetimes) a partir de lo que un recolector de basura hace normalmente por mí;
- modelar datos con `struct`, `enum` y `match` en lugar de jerarquías de clases;
- gestionar errores con `Option`, `Result` y `?` en lugar de `null` y excepciones;
- usar traits, genéricos e iteradores como uso interfaces, genéricos y LINQ/Streams;
- escribir código concurrente y asíncrono seguro;
- probar, documentar y analizar (lint) un crate.

## Plan

| # | Lección | Ya conoces |
|---|---|---|
| 1 | [Cadena de herramientas y Cargo](01-toolchain-and-cargo/) | [CLI `dotnet`](https://learn.microsoft.com/dotnet/core/tools/), [NuGet](https://www.nuget.org/), [Maven](https://maven.apache.org/)/[Gradle](https://gradle.org/) |
| 2 | [Tipos, mutabilidad y expresiones](02-types-mutability-expressions/) | `var`, `final`/`readonly`, `int`/`long`, ternarios |
| 3 | [Ownership y movimientos](03-ownership-and-moves/) | el recolector de basura, [`IDisposable`](https://learn.microsoft.com/dotnet/api/system.idisposable), [try-with-resources](https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html) |
| 4 | [Préstamos y cadenas](04-borrowing-and-strings/) | referencias, `string`/`String`, [`StringBuilder`](https://learn.microsoft.com/dotnet/api/system.text.stringbuilder) |
| 5 | [Structs, enums y pattern matching](05-structs-enums-match/) | clases, [records](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record), [jerarquías selladas](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html), `switch` |
| 6 | [`Option`, `Result` y `?`](06-option-result/) | `null`, excepciones |
| 7 | [Traits y genéricos](07-traits-and-generics/) | interfaces, genéricos |
| 8 | [Colecciones e iteradores](08-collections-and-iterators/) | LINQ, Streams |
| 9 | [Tiempos de vida (lifetimes)](09-lifetimes/) | — |
| 10 | [Módulos, crates y workspaces](10-modules-crates-workspaces/) | namespaces/paquetes, proyectos, soluciones |
| 11 | [`Box`, `Rc`, `Arc`, `RefCell`](11-smart-pointers/) | referencias, objetos compartidos |
| 12 | [Hilos, `Send`/`Sync`, `Mutex`, rayon](12-threads-and-concurrency/) | `Thread`, `lock`/`synchronized`, `Parallel.For` |
| 13 | [`async` y tokio](13-async-and-tokio/) | `async`/`await`, `CompletableFuture` |
| 14 | [Tests, docs, clippy, fmt](14-tests-docs-tooling/) | [xUnit](https://xunit.net/)/[JUnit](https://junit.org/), documentación XML/[Javadoc](https://docs.oracle.com/en/java/javase/25/javadoc/), analizadores |
| 15 | [Macros, `unsafe` y FFI](15-macros-unsafe-ffi/) (panorama) | [generadores de código fuente](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/source-generators-overview), [P/Invoke](https://learn.microsoft.com/dotnet/standard/native-interop/pinvoke), [JNI](https://docs.oracle.com/en/java/javase/25/docs/specs/jni/index.html) |

Un curso de continuación, **Rust en la práctica: IX y compañía**, aplica cada una de estas ideas a código real de IX, hari y mis otros repositorios Rust.

[Diario](journal/) — lo que probé, lo que me sorprendió, lo que aún me queda por verificar.

## Recursos

- [The Rust Programming Language](https://doc.rust-lang.org/book/) («el Book») — la introducción oficial y gratuita.
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/) — ejemplos breves y ejecutables.
- [The Cargo Book](https://doc.rust-lang.org/cargo/) — herramienta de compilación y gestor de paquetes.
- [Documentación de la biblioteca estándar de Rust](https://doc.rust-lang.org/std/).
- [Rust Error Codes Index](https://doc.rust-lang.org/error_codes/) — cada `E0xxx` explicado, también disponible sin conexión con `rustc --explain E0382`.
