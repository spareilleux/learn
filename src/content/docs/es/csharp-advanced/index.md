---
title: C# avanzado — Misión
description: Lo que ocurre bajo el capó de C# 14 y .NET 10 — la disposición en memoria, el recolector de basura, la máquina de estados de async y el rendimiento medido —, cada afirmación comprobada con un programa, el IL o un benchmark, sobre código real de Guitar Alchemist.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Cada salida de las lecciones procede de [`code/csharp-advanced`](https://github.com/spareilleux/learn/tree/main/code/csharp-advanced). [`check.sh`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/check.sh) compila el programa del curso contra [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) clonado en el commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), ejecuta cada lección, desensambla los ejemplos con [la herramienta de línea de comandos de ILSpy](https://github.com/icsharpcode/ILSpy/tree/master/ICSharpCode.ILSpyCmd), compila cada fragmento rechazado con [Roslyn](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/) y lo compara todo con los archivos esperados. [`.github/workflows/csharp-advanced-examples.yml`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/.github/workflows/csharp-advanced-examples.yml) hace lo mismo en Linux, Windows y macOS, y comprueba que cada benchmark se ejecuta. Las líneas que dependen de la máquina empiezan por `# ` y no se comparan; los tiempos de los benchmarks proceden de la máquina del autor, nunca de la CI. Salidas capturadas en septiembre de 2026 con el SDK de .NET 10.0.112 y el runtime de .NET 10.0.12.
:::

## Por qué aprendo esto

Llevo años escribiendo C#, y la mayor parte de lo que sé sobre su rendimiento es folclore: «los structs son más rápidos», «evita LINQ», «usa siempre `ConfigureAwait(false)`», «`FrozenDictionary` es el rápido». Parte de ello era cierto en .NET Framework 4.5 y es falso en .NET 10, donde el JIT elimina asignaciones que el IL pide. Este curso sustituye cada pieza de folclore por algo que puedo observar: el tamaño de un objeto, el IL que emitió el compilador, la máquina de estados que hay detrás de `await`, la generación de un array, una tabla de BenchmarkDotNet.

Las mediciones se hacen sobre código real, no sobre clases de juguete: [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA), una gran base de código .NET 10 sobre teoría musical. Sus objetos de valor, sus cachés y sus utilidades vectoriales son justo el tipo de código donde surgen estas preguntas, y las lecciones encontraron varios lugares donde GA paga por algo que no pretendía.

## A quién va dirigido este curso

Escribes C# a diario y conoces bien el lenguaje: genéricos, LINQ, `async`/`await`, records, coincidencia de patrones. Quieres saber qué hacen el compilador, el JIT y el recolector de basura con ese código, y medir antes de optimizar. Si estás empezando con C#, comienza por el curso [C# para principiantes](../csharp-beginner/), que termina donde empieza este.

## Al terminar este curso, sabré

- predecir el tamaño de un valor o de un objeto, detectar el boxing en el IL y saber cuándo lo elimina el JIT;
- usar `ref`, `in`, `ref readonly`, `Span<T>` y `stackalloc` sin copias defensivas ni referencias que escapan;
- explicar las generaciones, los montones de objetos grandes y de objetos fijados y los modos del GC, y leer `GC.GetGCMemoryInfo`;
- leer la máquina de estados que el compilador genera para un método `async`, elegir entre `Task` y `ValueTask`, y evitar interbloqueos y cancelaciones perdidas;
- escribir un benchmark de BenchmarkDotNet que mida lo que creo que mide, e interpretar la compilación por niveles y la PGO;
- elegir entre `Dictionary`, `FrozenDictionary`, `SearchValues` y la aritmética simple, y vectorizar un bucle con `Vector<T>` o `TensorPrimitives`;
- y, en las lecciones posteriores: matemáticas genéricas, generadores de código fuente, analizadores de Roslyn, interoperabilidad, Native AOT y diagnóstico en producción.

## Plan

| # | Lección | Bajo el capó | Medido en GA |
|---|---|---|---|
| 1 | [Memoria: valores, referencias y spans](01-memory-values-and-spans/) | disposición de los objetos, boxing en el IL, `ref`/`in`, `ref struct`, `Span<T>`, `stackalloc` | `PitchClass`, `PitchClassSetId.ItemsSpan` |
| 2 | [El recolector de basura](02-garbage-collector/) | generaciones, LOH y POH, GC de estación de trabajo y de servidor, DATAS, finalizadores, `GC.GetGCMemoryInfo` | asignaciones de `ItemsSpan` con `[MemoryDiagnoser]` |
| 3 | [async y await bajo el capó](03-async-under-the-hood/) | la máquina de estados generada, `ValueTask`, `SynchronizationContext`, `ConfigureAwait`, cancelación, `IAsyncEnumerable` | `Try.OfAsync`, `LazyWithExpiration` |
| 4 | [Rendimiento medido](04-measured-performance/) | BenchmarkDotNet, JIT por niveles y PGO, `SearchValues`, `FrozenDictionary`, `Vector<T>` | resta de `PitchClass`, `SimdOps.Dot` |
| 5 | Genéricos en profundidad | restricciones, miembros abstractos estáticos, matemáticas genéricas, `allows ref struct`, cómo comparte el JIT el código genérico | `IStaticValueObjectList<TSelf>` de GA |
| 6 | Primitivas de concurrencia | `System.Threading.Lock`, `Interlocked`, `Channel<T>`, `Parallel.ForEachAsync`, el grupo de subprocesos | |
| 7 | Delegados, clausuras y árboles de expresión | en qué se compila una lambda, `Expression<T>`, compilar expresiones en tiempo de ejecución | |
| 8 | Reflexión y generadores de código fuente | el coste de la reflexión, generadores incrementales, `[GeneratedRegex]` | |
| 9 | Analizadores y correcciones de código de Roslyn | modelos sintácticos y semánticos, escribir un analizador y sus pruebas | |
| 10 | Interoperabilidad y código no seguro | `[LibraryImport]`, punteros de función, `Unsafe`, `MemoryMarshal`, fijación | |
| 11 | Native AOT y recorte | lo que elimina AOT, advertencias de recorte, arranque y tamaño medidos | |
| 12 | Diagnóstico en producción | `dotnet-counters`, `dotnet-trace`, `dotnet-dump`, EventPipe, `System.Diagnostics.Metrics` | |
| — | [Diario](journal/) | | |

Las lecciones 5 a 12 están planificadas y aún no se han escrito.

## Requisitos previos

- El [SDK de .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) y [Git](https://git-scm.com/downloads). En Windows, ejecuta los scripts del curso desde Git Bash.
- `check.sh` restaura [`ilspycmd`](https://www.nuget.org/packages/ilspycmd) como herramienta local de .NET (versión 11.0.0.9375, fijada en [`.config/dotnet-tools.json`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/.config/dotnet-tools.json)) y descarga los tres proyectos de GA que usa el programa, unos 11 MB.
- Para los benchmarks, una máquina que puedas mantener tranquila durante unos minutos: cierra el navegador y enchufa el portátil.

## Cursos relacionados en este sitio

- [C# para principiantes](../csharp-beginner/): el lenguaje desde cero, escrito al mismo tiempo que este curso.
- [Teoría musical para Guitar Alchemist](../music-theory-ga/) lee los mismos proyectos de GA por lo que calculan; este curso los lee por cómo se ejecutan.
- [Rust para desarrolladores C#/Java](../rust-for-csharp-java/) hace explícito lo que .NET decide por ti: ownership en lugar de un recolector de basura, préstamos en lugar de las reglas de seguridad de `ref`.

## Recursos

- [Fundamentos de .NET: administración de memoria y recolección de elementos no utilizados](https://learn.microsoft.com/dotnet/standard/garbage-collection/), y las [opciones de configuración del GC](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector).
- [Referencia del lenguaje C#](https://learn.microsoft.com/dotnet/csharp/language-reference/), en particular los [ref structs](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct) y la [programación asincrónica](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/).
- Stephen Toub, [Performance Improvements in .NET 10](https://devblogs.microsoft.com/dotnet/performance-improvements-in-net-10/) y [How async/await really works in C#](https://devblogs.microsoft.com/dotnet/how-async-await-really-works/), en el blog de .NET.
- El repositorio [dotnet/runtime](https://github.com/dotnet/runtime): las lecciones enlazan las líneas del runtime en las que se apoyan, en la etiqueta `v10.0.12` (commit `4271d88`).
- [BenchmarkDotNet](https://benchmarkdotnet.org/) y sus [buenas prácticas](https://benchmarkdotnet.org/articles/guides/good-practices.html).
- Konrad Kokosa, *Pro .NET Memory Management* (Apress, 2018): anterior a .NET 10, sigue siendo el libro más profundo sobre el GC.
