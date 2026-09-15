---
title: V para desarrolladores C#/Java — Misión
description: Aprende el lenguaje V desde lo que ya sabes de C# y Java — cada ejemplo, error del compilador y panic se ejecuta en CI en Windows, Linux y macOS.
sidebar:
  label: Misión
  order: 0
---

:::note[Versión estudiada]
[V](https://vlang.io/) **0.5.2**, la [versión de julio de 2026](https://github.com/vlang/v/releases/tag/0.5.2). Cada ejemplo de este curso está en [`code/v-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/v-for-csharp-java), junto a su salida esperada. [`.github/workflows/v-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/v-examples.yml) instala V 0.5.2 desde la versión publicada en GitHub en Linux, Windows y macOS, ejecuta cada ejemplo, compila cada snippet que una lección muestra como rechazado, y compara las salidas y los mensajes del compilador con los que se pegan en las lecciones.
:::

## Por qué aprendo esto

V promete un lenguaje pequeño, cercano a Go, que compila a C en alrededor de un segundo, con variables inmutables por defecto, sin `null`, sin excepciones y con un recolector de basura (GC) que se puede desactivar.
Escribo C# y leo bastante Java. Quiero saber cuáles de esas promesas se cumplen en la versión 0.5.2, qué cuesta V a cambio, y dónde su documentación y su compilador no están de acuerdo.

## Para quién es este curso

Te manejas bien con C# o Java: clases, interfaces, genéricos, excepciones, colecciones, [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/) o [streams](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html).
Nunca has escrito V, y no necesitas saber C. Cada lección parte del concepto que ya conoces y muestra dónde V coincide, dónde difiere, y qué dice el compilador cuando te equivocas.

## V en una tabla

| | C# | Java | V |
|---|---|---|---|
| Compila a | IL, ejecutado por el CLR | bytecode, ejecutado por la JVM | C, compilado a un ejecutable nativo |
| Herramienta de compilación | [`dotnet`](https://learn.microsoft.com/dotnet/core/tools/) | [Maven](https://maven.apache.org/), [Gradle](https://gradle.org/) | el propio `v` |
| Archivo de proyecto | `.csproj` | `pom.xml`, `build.gradle` | `v.mod` (opcional) |
| Variable local | `var x = 1;` (mutable) | `var x = 1;` (mutable) | `x := 1` (inmutable), `mut x := 1` |
| Clase | `class`, `record`, `struct` | `class`, `record` | `struct` con métodos, sin herencia |
| Valor ausente | `null`, `int?` | `null`, `Optional<T>` | `?T` y `none` |
| Fallo | excepciones | excepciones comprobadas y no comprobadas | `!T`, `error()` y `or { }` |
| Memoria | GC generacional | GC (G1 por defecto) | GC de Boehm por defecto, `-autofree`, `-gc none` |
| Espacios de nombres | `namespace` | `package` | un módulo por carpeta |
| Visibilidad | `public`, `internal`, `private` | `public`, privado de paquete, `private` | `pub` o privado del módulo |

Fuentes: [recolección de basura de .NET](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals), [recolector de basura G1](https://docs.oracle.com/en/java/javase/25/gctuning/garbage-first-g1-garbage-collector1.html), [documentación de V](https://docs.vlang.io/introduction.html).

## La documentación y la versión

[docs.vlang.io](https://docs.vlang.io/introduction.html) se genera a partir de `doc/docs.md` en la rama `master` de V, que ha avanzado desde la 0.5.2: su página [The default compiler](https://docs.vlang.io/the-default-compiler.html), por ejemplo, no está en la documentación de la 0.5.2. Este curso enlaza a docs.vlang.io para los conceptos y comprueba cada comportamiento con la propia 0.5.2; la documentación de la versión estudiada es [`doc/docs.md` en la etiqueta 0.5.2](https://github.com/vlang/v/blob/0.5.2/doc/docs.md), y la biblioteca estándar se describe en [modules.vlang.io](https://modules.vlang.io/).

## Los datos

Las lecciones 3 y 4 leen [`code/v-for-csharp-java/data/pages.csv`](https://github.com/spareilleux/learn/blob/main/code/v-for-csharp-java/data/pages.csv): las 319 páginas de este sitio en el commit `cbcbb42`, con su idioma (locale), curso, título y número de líneas. Es una copia del archivo que el [curso de LadybugDB](../ladybugdb/) extrae de este repositorio.

Las lecciones 5 a 8 leen [`code/v-for-csharp-java/data/ga`](https://github.com/spareilleux/learn/tree/main/code/v-for-csharp-java/data/ga): los 111 proyectos .NET de [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) en el commit [`a26a7893`](https://github.com/GuitarAlchemist/ga/commit/a26a7893), sus 266 referencias de proyecto y 478 referencias de paquete, copiados también del curso de LadybugDB. La lección 7 recorre sus referencias en paralelo, la lección 8 prueba un módulo que las analiza.

## Al final de este curso, sabré

- instalar V en Windows, Linux y macOS, y organizar un programa en módulos;
- modelar datos con structs, métodos, interfaces y tipos suma en lugar de clases;
- gestionar la ausencia y el fallo con `?`, `!` y `or { }` en lugar de `null` y excepciones;
- decir dónde se copia, se comparte o se libera un array, un map o un struct;
- escribir código concurrente con `spawn` y canales (*channels*);
- probar, formatear y documentar un módulo, y llamar a una biblioteca C.

## Plan

| # | Lección | Ya conoces |
|---|---|---|
| 1 | [Instalación, `v run`, módulos y proyectos](01-install-and-projects/) | `dotnet new`, `dotnet run`, `javac`, `java` |
| 2 | [Tipos, variables inmutables, structs y métodos](02-types-structs-methods/) | `var`, `readonly`/`final`, clases, records |
| 3 | [Errores: `?`, `!` y `or { }`](03-errors-option-result/) | `null`, `Optional`, excepciones |
| 4 | [Arrays, maps, slices y memoria](04-arrays-maps-memory/) | `List<T>`, `Dictionary`, `ArrayList`, `HashMap`, el GC |
| 5 | [Interfaces y genéricos](05-interfaces-generics/) | interfaces, genéricos, restricciones |
| 6 | [Enums, tipos suma y `match`](06-sum-types-match/) | enums, jerarquías selladas, expresiones `switch` |
| 7 | [Concurrencia: `spawn`, canales y `shared`](07-concurrency/) | `Task`, `CompletableFuture`, hilos virtuales, `lock`/`synchronized` |
| 8 | [Pruebas, `v fmt`, `v vet` y `v doc`](08-tests-tools/) | xUnit/JUnit, `dotnet format`, analizadores, comentarios de documentación XML |
| 9 | Llamar a C (próximamente) | P/Invoke, JNI, la API FFM |
| 10 | JSON y un servidor web con `veb` | `System.Text.Json`, ASP.NET Core, Jackson, Spring |
| 11 | El ORM y SQLite | Entity Framework, JPA |
| 12 | Paquetes, compilación cruzada y despliegue | NuGet/Maven Central, `dotnet publish`, `jlink` |
| — | [Diario](journal/) | |

## Recursos

- [Documentación de V](https://docs.vlang.io/introduction.html), y [`doc/docs.md` en la etiqueta 0.5.2](https://github.com/vlang/v/blob/0.5.2/doc/docs.md)
- [Biblioteca estándar de V](https://modules.vlang.io/)
- [Código fuente de V](https://github.com/vlang/v), y la [versión 0.5.2](https://github.com/vlang/v/releases/tag/0.5.2) que usa este curso
- [Las pruebas del lenguaje de V](https://github.com/vlang/v/tree/0.5.2/vlib/v/tests): la documentación dice que el compilador y sus pruebas son la referencia cuando no coinciden con ella
