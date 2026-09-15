---
title: F# para desarrolladores C#/Java — Misión
description: F# 10 sobre .NET 10, del primer script al nivel experto, para desarrolladores C# y Java sin experiencia en programación funcional — cada script, mensaje del compilador y ejercicio ejecutado en CI, con código real de TARS y Guitar Alchemist.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Cada script, sesión de F# Interactive, solución de ejercicio y mensaje del compilador de las lecciones proviene de [`code/fsharp`](https://github.com/spareilleux/learn/tree/main/code/fsharp). [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/fsharp/check.sh) los ejecuta con el SDK de .NET 10 y compara su salida con los archivos esperados; el workflow `.github/workflows/fsharp-examples.yml` hace lo mismo en Linux, Windows y macOS (consulta el [diario](journal/) para ver su estado). Las salidas se capturaron en septiembre de 2026 con el SDK de .NET 10.0.112, que contiene F# 10.
:::

## Por qué este curso

Escribes C# o Java. Has usado lambdas, LINQ o streams, records, quizá expresiones `switch` con patrones. F# toma esas ideas, que C# y Java tomaron prestadas de los lenguajes funcionales en los últimos quince años, y las convierte en lo normal: valores que no cambian, funciones que devuelven valores en lugar de modificar estado, tipos que describen cada caso de tus datos y un compilador que comprueba que los has tratado todos.

F# se ejecuta sobre .NET, llama a cualquier biblioteca .NET y compila al mismo lenguaje intermedio que C#. No tienes que salir de tu ecosistema para aprenderlo, y lo que aprendes cambia tu forma de escribir C#.

Este curso usa las versiones actuales: [F# 10](https://learn.microsoft.com/dotnet/fsharp/whats-new/fsharp-10), que se distribuye con [.NET 10](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-10/overview), publicado en noviembre de 2025.

## Código real: TARS y Guitar Alchemist

Los ejemplos vienen de dos bases de código F# públicas, fijadas en un commit para que los enlaces sigan apuntando al código que describen las lecciones:

- **[TARS](https://github.com/GuitarAlchemist/tars)**, un framework de agentes en F# (razonamiento, workflows multiagente, gramáticas probabilísticas), en el commit [`87464ce`](https://github.com/GuitarAlchemist/tars/tree/87464ce583c42cd11c3d76836e05842377455b24). Su código activo está en `v2/`: las lecciones solo citan proyectos que su solución `v2/Tars.sln` compila y que su CI prueba.
- **[Guitar Alchemist](https://github.com/GuitarAlchemist/ga)** (GA), una aplicación de teoría musical escrita sobre todo en C#, cuyo DSL musical, parsers, configuración y servidor de lenguaje están en F#, en el commit [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381).

Cuando un extracto de GA compila por sí solo, el curso guarda una copia del archivo en [`code/fsharp/external/ga`](https://github.com/spareilleux/learn/tree/main/code/fsharp/external/ga) (GA tiene licencia MIT) y lo ejecuta. TARS no tiene archivo de licencia, así que su código se enlaza y se cita, y solo se reproduce en unas pocas líneas cuando hay que mostrar un comportamiento. Lo que las lecciones encuentran en estos repositorios (un bug, código muerto, un script que no se ejecuta) va al [diario](journal/).

## Cómo funcionan las lecciones

Cada lección parte de lo que escribirías en C# (y en Java cuando es distinto) y luego muestra:

1. **la forma F#**, con un script corto y la salida que realmente imprimió;
2. **el punto de vista del compilador**: los errores y advertencias que encontrarás, con su mensaje exacto;
3. **código real** de TARS o GA que usa la noción;
4. **ejercicios**, con una solución en *Solución*: inténtalo primero y luego ábrela.

## Al final de este curso, sabré

- ejecutar scripts F# y F# Interactive, y organizar un proyecto F# cuyos archivos compilan en orden;
- modelar un dominio con records, uniones discriminadas y opciones, para que los estados inválidos no compilen;
- escribir funciones que se componen, con pipelines, aplicación parcial y coincidencia de patrones exhaustiva;
- manejar errores con `Result`, y escribir y leer expresiones de cómputo, incluidas las mías;
- probar código F# con xUnit, FsCheck y Expecto, y analizar texto con FParsec;
- medir y reducir asignaciones de memoria, y elegir entre `Async`, `Task` y `MailboxProcessor`;
- leer y ampliar una base de código F# real, y publicar una biblioteca F# que el código C# consuma cómodamente.

## Plan

| # | Lección | Nociones | Código real |
|---|---|---|---|
| | **Principiante** | | |
| 1 | [Scripts, F# Interactive y proyectos](01-first-program/) | `dotnet fsi`, scripts `.fsx`, `printfn`, `#r "nuget:"`, indentación, el orden de los archivos de un `.fsproj` | `GA.Business.DSL.fsproj` y `Scripts/ModesConfig.fsx` de GA, `Tars.Core.fsproj` de TARS |
| 2 | [Valores, funciones e inferencia de tipos](02-values-and-functions/) | `let`, inmutabilidad, `mutable`, inferencia, currificación, aplicación parcial, `\|>` y `>>`, expresiones en todas partes | `HarmonicTransformationService` de GA, `TextNormalizer` de TARS |
| 3 | [Tuplas, records, uniones y opciones](03-records-unions-options/) | tuplas, records y `with`, uniones discriminadas, `Option`, uniones de un solo caso, `RequireQualifiedAccess` | `ChordAst` de GA, `Domain.fs` y `Primitives.fs` de TARS |
| 4 | [Coincidencia de patrones](04-pattern-matching/) | `match`, guardas, patrones «o», patrones de listas y de records, advertencias de exhaustividad | `ChordRenderer`, `ChordParser` y `BinObj.fsx` de GA, `AgentWorkflow.fs` de TARS |
| 5 | Listas, arrays y secuencias | módulos `List`, `Array` y `Seq`, pipelines junto a LINQ y streams, evaluación perezosa | |
| 6 | Módulos, espacios de nombres y organización del proyecto | módulos, espacios de nombres, `private` e `internal`, archivos de firma | |
| | **Intermedio** | | |
| 7 | Errores con `Result` | programación orientada a raíles, `Result` junto a las excepciones | |
| 8 | Expresiones de cómputo | `seq`, `async`, `task`, un builder `result` escrito a mano | `asyncResult` de TARS |
| 9 | Objetos en F# | clases, interfaces, expresiones de objeto, llamadas a bibliotecas C# | |
| 10 | Pruebas | xUnit, pruebas basadas en propiedades con FsCheck, Expecto | |
| 11 | Parsers | FParsec y combinadores escritos a mano | el DSL musical de GA |
| 12 | Modelar un dominio | unidades de medida, tipos fantasma, hacer que los estados ilegales no sean representables | `Budget` de TARS |
| | **Avanzado y experto** | | |
| 13 | Expresiones de cómputo personalizadas | builders, `let!` y `and!`, lo que genera el compilador | `AgentWorkflow` de TARS |
| 14 | Proveedores de tipos, citas de código y reflexión | | |
| 15 | Rendimiento | structs, `inline`, `Span`, `voption`, asignaciones medidas con BenchmarkDotNet | |
| 16 | Concurrencia | `MailboxProcessor`, `Async` junto a `Task`, canales | |
| 17 | Metaprogramación | Myriad, FSharp.Compiler.Service | el pool de sesiones de F# Interactive de GA |
| 18 | Herramientas | un servidor de lenguaje en F#, Fantomas, analizadores | `GaMusicTheoryLsp` de GA |
| 19 | Arquitectura de una aplicación F# real | una lectura guiada de TARS | TARS |
| 20 | Publicar una biblioteca F# para C# | diseño de API, `[<CompiledName>]`, opciones y uniones vistas desde C# | |
| — | [Diario](journal/) | | |

Las lecciones 5 a 20 están planificadas y aún no están escritas.

## Requisitos previos

- Programas en C# o Java. No hace falta experiencia en programación funcional.
- El [SDK de .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0), en Windows, Linux (o WSL) o macOS. La lección 1 comprueba la instalación; el curso [C# para principiantes](../csharp-beginner/01-first-program/#instalar-el-sdk-de-net) la detalla para cada sistema.
- Un editor compatible con F#: [Visual Studio Code](https://code.visualstudio.com/) con la extensión [Ionide](https://ionide.io/), [JetBrains Rider](https://www.jetbrains.com/rider/), o [Visual Studio](https://visualstudio.microsoft.com/) en Windows.

## Cursos relacionados

- [C# avanzado](../csharp-advanced/) cubre lo que ocurre bajo .NET: la memoria, el recolector de basura, `async` y el rendimiento medido. Este curso enlaza con él en lugar de repetirlo; las lecciones 15 y 16 se apoyan en él.
- [Rust para desarrolladores C#/Java](../rust-for-csharp-java/) aborda las mismas ideas desde otro ángulo: [los enums y `match`](../rust-for-csharp-java/05-structs-enums-match/), [`Option` y `Result`](../rust-for-csharp-java/06-option-result/).

## Recursos

- [La documentación de F#](https://learn.microsoft.com/dotnet/fsharp/), con su [recorrido por F#](https://learn.microsoft.com/dotnet/fsharp/tour) y su [referencia del lenguaje](https://learn.microsoft.com/dotnet/fsharp/language-reference/).
- [Novedades de F# 10](https://learn.microsoft.com/dotnet/fsharp/whats-new/fsharp-10).
- [La referencia de la API de FSharp.Core](https://fsharp.github.io/fsharp-core-docs/): los módulos `List`, `Option`, `Result` y el resto de la biblioteca básica.
- [La especificación del lenguaje F#](https://fsharp.org/specs/language-spec/) y las RFC de diseño en [fsharp/fslang-design](https://github.com/fsharp/fslang-design).
- [dotnet/fsharp](https://github.com/dotnet/fsharp): el compilador, FSharp.Core y F# Interactive.
- [La guía de estilo de F#](https://learn.microsoft.com/dotnet/fsharp/style-guide/) y [las convenciones de código de F#](https://learn.microsoft.com/dotnet/fsharp/style-guide/conventions).
