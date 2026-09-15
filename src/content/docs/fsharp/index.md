---
title: F# for C#/Java developers — Mission
description: F# 10 on .NET 10 from the first script to expert level, for C# and Java developers with no functional programming background — every script, compiler message and exercise run in CI, with real code from TARS and Guitar Alchemist.
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
Every script, F# Interactive session, exercise solution and compiler message in the lessons comes from [`code/fsharp`](https://github.com/spareilleux/learn/tree/main/code/fsharp). [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/fsharp/check.sh) runs them with the .NET 10 SDK and compares their output with the expected files; the workflow `.github/workflows/fsharp-examples.yml` does the same on Linux, Windows and macOS (see the [journal](journal/) for its state). The outputs were captured in September 2026 with the .NET SDK 10.0.112, which contains F# 10.
:::

## Why this course

You write C# or Java. You have used lambdas, LINQ or streams, records, maybe `switch` expressions with patterns. F# takes those ideas, which C# and Java borrowed from functional languages over the last fifteen years, and makes them the default: values that don't change, functions that return values instead of changing state, types that describe every case of your data, and a compiler that checks that you handled all of them.

F# runs on .NET, calls every .NET library, and compiles to the same intermediate language as C#. You don't have to leave your ecosystem to learn it, and what you learn changes how you write C#.

This course uses the current versions: [F# 10](https://learn.microsoft.com/dotnet/fsharp/whats-new/fsharp-10), which ships with [.NET 10](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-10/overview), released in November 2025.

## Real code: TARS and Guitar Alchemist

The examples come from two public F# code bases, pinned on a commit so that the links keep pointing at the code the lessons describe:

- **[TARS](https://github.com/GuitarAlchemist/tars)**, an F# agent framework (reasoning, multi-agent workflows, probabilistic grammars), at commit [`87464ce`](https://github.com/GuitarAlchemist/tars/tree/87464ce583c42cd11c3d76836e05842377455b24). Its active code lives in `v2/`: the lessons only cite projects that its solution `v2/Tars.sln` builds and that its CI tests.
- **[Guitar Alchemist](https://github.com/GuitarAlchemist/ga)** (GA), a music theory application written mostly in C#, whose music DSL, parsers, configuration and language server are in F#, at commit [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381).

When an extract of GA compiles on its own, the course keeps a copy of the file in [`code/fsharp/external/ga`](https://github.com/spareilleux/learn/tree/main/code/fsharp/external/ga) (GA is under the MIT license) and runs it. TARS has no license file, so its code is linked and quoted, and reproduced in a few lines only where a behavior needs to be shown. What the lessons find in these repositories (a bug, dead code, a script that doesn't run) goes in the [journal](journal/).

## How the lessons work

Each lesson starts from what you would write in C# (and in Java when it differs), then:

1. **the F# way**, with a short script and the output it really printed;
2. **the compiler's view**: the errors and warnings you will meet, with their exact message;
3. **real code** from TARS or GA that uses the notion;
4. **exercises**, with a solution under *Solution*: try first, then open it.

## By the end of this course, I will be able to

- run F# scripts and F# Interactive, and organize an F# project whose files compile in order;
- model a domain with records, discriminated unions and options, so that invalid states don't compile;
- write functions that compose, with pipelines, partial application and exhaustive pattern matching;
- handle errors with `Result`, and write and read computation expressions, including my own;
- test F# code with xUnit, FsCheck and Expecto, and parse text with FParsec;
- measure and reduce allocations, and choose between `Async`, `Task` and `MailboxProcessor`;
- read and extend a real F# code base, and publish an F# library that C# code consumes comfortably.

## Outline

| # | Lesson | Notions | Real code |
|---|---|---|---|
| | **Beginner** | | |
| 1 | [Scripts, F# Interactive and projects](01-first-program/) | `dotnet fsi`, `.fsx` scripts, `printfn`, `#r "nuget:"`, indentation, the file order of a `.fsproj` | GA's `GA.Business.DSL.fsproj` and `Scripts/ModesConfig.fsx`, TARS's `Tars.Core.fsproj` |
| 2 | [Values, functions and type inference](02-values-and-functions/) | `let`, immutability, `mutable`, inference, currying, partial application, `\|>` and `>>`, expressions everywhere | GA's `HarmonicTransformationService`, TARS's `TextNormalizer` |
| 3 | [Tuples, records, unions and options](03-records-unions-options/) | tuples, records and `with`, discriminated unions, `Option`, single-case unions, `RequireQualifiedAccess` | GA's `ChordAst`, TARS's `Domain.fs` and `Primitives.fs` |
| 4 | [Pattern matching](04-pattern-matching/) | `match`, guards, or-patterns, list and record patterns, exhaustiveness warnings | GA's `ChordRenderer`, `ChordParser` and `BinObj.fsx`, TARS's `AgentWorkflow.fs` |
| 5 | Lists, arrays and sequences | `List`, `Array` and `Seq` modules, pipelines next to LINQ and streams, laziness | |
| 6 | Modules, namespaces and project organization | modules, namespaces, `private` and `internal`, signature files | |
| | **Intermediate** | | |
| 7 | Errors with `Result` | railway-oriented programming, `Result` next to exceptions | |
| 8 | Computation expressions | `seq`, `async`, `task`, a hand-written `result` builder | TARS's `asyncResult` |
| 9 | Objects in F# | classes, interfaces, object expressions, calling C# libraries | |
| 10 | Testing | xUnit, FsCheck property-based tests, Expecto | |
| 11 | Parsers | FParsec and hand-written combinators | GA's music DSL |
| 12 | Modeling a domain | units of measure, phantom types, making illegal states unrepresentable | TARS's `Budget` |
| | **Advanced and expert** | | |
| 13 | Custom computation expressions | builders, `let!` and `and!`, what the compiler generates | TARS's `AgentWorkflow` |
| 14 | Type providers, quotations and reflection | | |
| 15 | Performance | structs, `inline`, `Span`, `voption`, allocations measured with BenchmarkDotNet | |
| 16 | Concurrency | `MailboxProcessor`, `Async` next to `Task`, channels | |
| 17 | Metaprogramming | Myriad, FSharp.Compiler.Service | GA's F# Interactive session pool |
| 18 | Tooling | a language server in F#, Fantomas, analyzers | GA's `GaMusicTheoryLsp` |
| 19 | Architecture of a real F# application | a guided reading of TARS | TARS |
| 20 | Publishing an F# library for C# | API design, `[<CompiledName>]`, options and unions seen from C# | |
| — | [Journal](journal/) | | |

Lessons 5 to 20 are planned and not written yet.

## Prerequisites

- You program in C# or Java. No functional programming experience is needed.
- The [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0), on Windows, Linux (or WSL) or macOS. Lesson 1 checks the installation; the [C# for beginners](../csharp-beginner/01-first-program/#install-the-net-sdk) course details it for each OS.
- An editor with F# support: [Visual Studio Code](https://code.visualstudio.com/) with the [Ionide](https://ionide.io/) extension, [JetBrains Rider](https://www.jetbrains.com/rider/), or [Visual Studio](https://visualstudio.microsoft.com/) on Windows.

## Related courses

- [Advanced C#](../csharp-advanced/) covers what happens under .NET: memory, the garbage collector, `async` and measured performance. This course links to it rather than repeating it; lessons 15 and 16 build on it.
- [Rust for C#/Java developers](../rust-for-csharp-java/) meets the same ideas from another side: [enums and `match`](../rust-for-csharp-java/05-structs-enums-match/), [`Option` and `Result`](../rust-for-csharp-java/06-option-result/).

## Resources

- [F# documentation](https://learn.microsoft.com/dotnet/fsharp/), with its [tour of F#](https://learn.microsoft.com/dotnet/fsharp/tour) and [language reference](https://learn.microsoft.com/dotnet/fsharp/language-reference/).
- [What's new in F# 10](https://learn.microsoft.com/dotnet/fsharp/whats-new/fsharp-10).
- [FSharp.Core API reference](https://fsharp.github.io/fsharp-core-docs/): the `List`, `Option`, `Result` modules and the rest of the core library.
- [The F# language specification](https://fsharp.org/specs/language-spec/) and the design RFCs in [fsharp/fslang-design](https://github.com/fsharp/fslang-design).
- [dotnet/fsharp](https://github.com/dotnet/fsharp): the compiler, FSharp.Core and F# Interactive.
- [F# style guide](https://learn.microsoft.com/dotnet/fsharp/style-guide/) and [F# coding conventions](https://learn.microsoft.com/dotnet/fsharp/style-guide/conventions).
