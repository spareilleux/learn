---
title: Rust para desarrolladores C#/Java — Misión
description: Aprende Rust desde cero, apoyándote en lo que ya sabes de C# y Java, y luego construye una aplicación de escritorio con Tauri.
sidebar:
  label: Misión
  order: 0
---

:::note[Versión estudiada]
Rust **1.94.0**, edición **2024**. Cada ejemplo de código de este curso se compila y ejecuta en CI desde [`code/rust-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java); cada fragmento «esto no compila» es un doctest `compile_fail`.

La parte 2 fija **Tauri 2.11.5**. Su aplicación, [`code/rust-for-csharp-java/l16-tauri`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri), se compila, se analiza con clippy y se prueba en la CI en Windows, Ubuntu y macOS; su ventana solo se ha ejecutado en Windows.
:::

## Por qué aprendo esto

Escribo C# (y leo mucho Java), y una parte creciente de mi ecosistema — [IX](https://github.com/GuitarAlchemist/ix), [hari](https://github.com/GuitarAlchemist/hari) — está escrita en Rust.
Quiero leer y modificar ese código con seguridad en lugar de adivinar, y entender *por qué* el compilador rechaza lo que sería perfectamente válido en C#.
Después quiero saber si Rust es una opción seria para las aplicaciones de escritorio que, si no, escribiría con [WPF](https://learn.microsoft.com/dotnet/desktop/wpf/overview/), [.NET MAUI](https://learn.microsoft.com/dotnet/maui/what-is-maui), [JavaFX](https://openjfx.io/) o [Electron](https://www.electronjs.org/).

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
- probar, documentar y analizar (lint) un crate;
- elegir entre los toolkits de interfaz de escritorio de Rust, y construir una aplicación Tauri cuya interfaz web llama a comandos Rust, comparte estado y recibe eventos y flujos;
- asegurar, probar y empaquetar esa aplicación para Windows, Linux y macOS.

## Plan

### Parte 1 — El lenguaje

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

### Parte 2 — Aplicaciones de escritorio con Tauri

Las seis lecciones construyen una sola aplicación, un explorador de acordes, en [`l16-tauri`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l16-tauri).

| # | Lección | Ya conoces |
|---|---|---|
| 16 | [Interfaces de escritorio en Rust, y luego Tauri](16-desktop-ui-and-tauri/) | WPF, MAUI, JavaFX, Electron |
| 17 | [Comandos de Tauri](17-tauri-commands/) | los comandos de WPF, los controladores, `ipcMain.handle` de Electron |
| 18 | [Estado, eventos y canales](18-tauri-state-events-channels/) | singletons de inyección de dependencias, messengers, [`IProgress<T>`](https://learn.microsoft.com/dotnet/api/system.iprogress-1) |
| 19 | [El frontend: Vite, TypeScript y tipos generados desde Rust](19-tauri-frontend-and-types/) | un cliente TypeScript generado a partir de una descripción de API |
| 20 | [Seguridad: capabilities, CSP y plugins](20-tauri-security-and-plugins/) | el aislamiento de contexto de Electron, los permisos de las aplicaciones |
| 21 | [Tests, empaquetado y distribución](21-tauri-tests-and-packaging/) | [MSIX](https://learn.microsoft.com/windows/msix/overview), [`jpackage`](https://docs.oracle.com/en/java/javase/25/docs/specs/man/jpackage.html), instaladores |

Un curso de continuación, **Rust en la práctica: IX y compañía**, aplica cada una de estas ideas a código real de IX, hari y mis otros repositorios Rust.

[Diario](journal/) — lo que probé, lo que me sorprendió, lo que aún me queda por verificar.

## Recursos

- [The Rust Programming Language](https://doc.rust-lang.org/book/) («el Book») — la introducción oficial y gratuita.
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/) — ejemplos breves y ejecutables.
- [The Cargo Book](https://doc.rust-lang.org/cargo/) — herramienta de compilación y gestor de paquetes.
- [Documentación de la biblioteca estándar de Rust](https://doc.rust-lang.org/std/).
- [Rust Error Codes Index](https://doc.rust-lang.org/error_codes/) — cada `E0xxx` explicado, también disponible sin conexión con `rustc --explain E0382`.
