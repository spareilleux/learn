---
title: Rust avanzado — Misión
description: Rust bajo el capó — representación, asignación, contratos unsafe, generación de código, runtimes async, concurrencia, profiling y servicios en producción — con cada afirmación publicada comprobada por un programa o una prueba compile-fail.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Las pruebas están en [`code/rust-advanced`](https://github.com/spareilleux/learn/tree/main/code/rust-advanced). `check.sh` ejecuta el formato, Clippy con los warnings denegados, pruebas unitarias, doctests compile-fail y los programas de las lecciones, y compara sus salidas con archivos versionados. El workflow de CI repite el gate en Linux, Windows y macOS. Los resultados aún no observados en esos tres runners permanecen en **Por verificar** en el diario.
:::

## Por qué estoy aprendiendo esto

El curso [Rust para desarrolladores C#/Java](../rust-for-csharp-java/) enseña a escribir Rust correcto. Este empieza donde termina aquel: qué representación puede elegir el compilador, cuánto cuesta una abstracción, qué invariante hace sound un bloque `unsafe`, cómo un `Future` se convierte en trabajo ejecutable y cómo medir antes de cambiar código.

El objetivo no es coleccionar optimizaciones ingeniosas. Es sustituir el folclore por pruebas inspeccionables: tamaños y offsets impresos por un programa, contratos rechazados conservados como pruebas compile-fail, código generado examinado deliberadamente y afirmaciones de rendimiento ligadas a un benchmark reproducible.

## A quién va dirigido

Ya utilizas ownership, préstamos, lifetimes, traits, iteradores, `Result`, threads y Rust async básico. Si son conceptos nuevos, completa primero [Rust para desarrolladores C#/Java](../rust-for-csharp-java/). Las comparaciones con C# y Java explican las decisiones del runtime, pero los ejercicios presuponen Rust práctico.

## Al terminar este curso, sabré

- distinguir la representación predeterminada de Rust de `repr(C)` y `repr(transparent)`, y medir tamaño, alineación, padding y optimización por nichos;
- razonar sobre asignación, orden de `Drop`, procedencia y el contrato de seguridad de un núcleo `unsafe` pequeño;
- predecir los compromisos de monomorfización y dispatch dinámico, e inspeccionarlos en vez de adivinarlos;
- explicar `Pin`, `Future`, el despertar y la planificación de un executor;
- diseñar pipelines Tokio acotados con cancelación, backpressure y estados terminales explícitos;
- usar atomics y memory orderings sin tratar `SeqCst` como sustituto de una prueba;
- perfilar CPU, asignaciones y tamaño del binario antes de optimizar;
- reconocer las fronteras adecuadas para macros procedurales, FFI, Axum, Tower y Hyper.

## Plan

### Parte 1 — Representación y generación de código

| # | Lección | Prueba |
|---|---|---|
| 1 | [Disposición de memoria y representación](01-memory-layout-and-representation/) | `size_of`, `align_of`, `offset_of` y contrato `repr(transparent)` compile-fail |
| 2 | Asignación, costes de ownership y `Drop` | observaciones del asignador y trazas deterministas de destrucción — planificada |
| 3 | Contratos unsafe, punteros, procedencia y `Pin` | wrapper seguro y comprobaciones Miri — planificada |
| 4 | Traits, monomorfización y dispatch dinámico | código generado y comparación del tamaño binario — planificada |
| 5 | Profiling y optimización medida | Criterion, flamegraphs y pruebas de asignación — planificada |

### Parte 2 — Concurrencia y runtimes async

| # | Lección | Prueba |
|---|---|---|
| 6 | Atomics y modelo de memoria | litmus tests con límites declarados — planificada |
| 7 | `Future`, wakers y executors | executor mínimo antes de Tokio — planificada |
| 8 | Planificación Tokio, channels y backpressure | pipeline acotado, cancelación y pruebas de estados terminales — planificada |

### Parte 3 — Fronteras avanzadas

| # | Lección | Prueba |
|---|---|---|
| 9 | Macros procedurales | expansión y diagnósticos de compilación — planificada |
| 10 | Diseño FFI y ABI | frontera Rust/C ejercitada desde otro lenguaje — planificada |
| 11 | Axum, Tower y Hyper | petición a través de layers, cancelación y cierre ordenado — planificada |
| 12 | Observabilidad, compilación cruzada y tamaño binario | trazas, métricas y artifacts de release reproducibles — planificada |
| — | [Diario](journal/) | progreso medido, experimentos y preguntas abiertas |

## Requisitos previos

- Rust 1.94.0 con la edición 2024 y Cargo;
- los conceptos cubiertos por [Rust para desarrolladores C#/Java](../rust-for-csharp-java/);
- Git y un shell. En Windows, el gate del curso se ejecuta desde Git Bash.

## Fuentes primarias

- [The Rust Reference — type layout](https://doc.rust-lang.org/reference/type-layout.html)
- [The Rustonomicon](https://doc.rust-lang.org/nomicon/)
- [The Async Book](https://rust-lang.github.io/async-book/)
- [The Rust Performance Book](https://nnethercote.github.io/perf-book/)
- [Documentación de Tokio](https://tokio.rs/tokio/tutorial)
