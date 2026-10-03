---
title: C# for beginners — Mission
description: Learn to program in C# 14 on .NET 10 from zero — variables, conditions, loops, methods and collections, each notion explained with short programs that were run, and exercises with solutions.
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
Every program in the lessons, every exercise solution and every compiler error comes from [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner). [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/csharp-beginner/check.sh) runs them with the .NET 10 SDK and compares their output with the expected files; [`.github/workflows/csharp-beginner-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/csharp-beginner-examples.yml) does the same on Linux, Windows and macOS. The outputs were captured in September 2026 with the .NET SDK 10.0.112.
:::

## Why this course

The other language courses on this site assume you already write C# or Java. This one doesn't. It is for someone who has never programmed, or who has written a little Python, JavaScript or spreadsheet formulas, and wants to learn C# properly.

C# is a good first language: the compiler checks your program before it runs and explains what is wrong, the tools are free on Windows, Linux and macOS, and the same language builds command-line tools, web sites, games and desktop applications. The course uses the current versions: [C# 14](https://learn.microsoft.com/dotnet/csharp/whats-new/csharp-14) and [.NET 10](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-10/overview), released in November 2025.

## How the lessons work

Each lesson introduces a few notions, and for each one:

1. **the idea**, in plain words;
2. **a short program** that uses it, with the output it really printed;
3. **the mistakes** beginners make with it, with the exact message of the compiler;
4. **exercises**, with a solution hidden under *Solution*: try first, then open it.

The examples use small, real data where it helps: the notes of a guitar, the tuning that [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) uses, the names of its projects. You don't need to play music to follow them.

## By the end of this course, I will be able to

- install the .NET SDK, run a C# file and create a project, on Windows, Linux or macOS;
- read a compiler error and fix it;
- store values in variables of the right type, convert between types, and read input from the keyboard;
- make decisions with `if` and `switch`, and repeat work with loops;
- split a program into methods, and work with arrays and lists;
- model my own data with classes and records, and handle errors with exceptions;
- read and write files, test my code, and use a NuGet package.

## Outline

| # | Lesson | Notions |
|---|---|---|
| 1 | [Install .NET and run your first program](01-first-program/) | SDK, `dotnet run app.cs`, statements, projects, compiler errors |
| 2 | [Variables, types and input](02-variables-and-types/) | `int`, `double`, `decimal`, `string`, `bool`, `var`, conversions, interpolation, `Console.ReadLine` |
| 3 | [Conditions and loops](03-conditions-and-loops/) | `if`, `switch`, `for`, `foreach`, `while`, `break`, the debugger |
| 4 | [Methods, arrays and lists](04-methods-arrays-lists/) | parameters, return values, arrays, `List<T>`, first steps with `null` |
| 5 | [Classes and objects](05-classes-and-objects/) | fields, properties, constructors, methods, `static` |
| 6 | [Records, structs and enums](06-records-structs-enums/) | value and reference types, equality, `enum` |
| 7 | [Interfaces and inheritance](07-interfaces-and-inheritance/) | `interface`, `abstract`, `override`, polymorphism |
| 8 | [Exceptions and null safety](08-exceptions-and-null-safety/) | `try`/`catch`/`finally`, `throw`, nullable reference types |
| 9 | [Collections and LINQ](09-collections-and-linq/) | `Dictionary<TKey, TValue>`, `HashSet<T>`, `Where`, `Select`, `OrderBy` |
| 10 | [Files and text](10-files-and-text/) | `File`, `Path`, reading a CSV file of Guitar Alchemist's projects |
| 11 | Unit tests | xUnit, `dotnet test`, testing the methods of earlier lessons |
| 12 | A small project | a solution with a library, a console app and tests, a NuGet package, a first look at `async` |
| — | [Journal](journal/) | |

Lessons 11 and 12 are planned and not written yet.

## Highlights from the journal

The [journal](journal/) records what writing and testing this course turned up. These are the findings that change how you write or run a program; each row links to the lesson that teaches it and to the journal entry with the measurement.

| What the journal found | Why it matters | See |
|---|---|---|
| A misspelled `Writeline` (CS0117) is reported only once the missing `;` and quote of the same program are fixed: syntax errors hide the others | Fixing an error can make new ones appear; that is progress, not a step back | [Lesson 1](01-first-program/), [journal](journal/#2026-09-14--the-sdk-and-file-based-apps) |
| `double.TryParse("1.5")` depends on the culture: `true` and 15 in `es-ES`, where the dot separates thousands, `false` in `fr-FR` | The same program reads a different number on a Spanish or a French machine | [Lesson 2](02-variables-and-types/), [journal](journal/#2026-09-14--the-sdk-and-file-based-apps) |
| Warnings are printed only when the SDK compiles: a second `dotnet run` of an unchanged file prints none, even with `--no-cache`; `dotnet clean` brings them back | A warning that is gone on the next run has not been fixed | [Lesson 3](03-conditions-and-loops/), [journal](journal/#2026-09-14--the-sdk-and-file-based-apps) |
| The literal `0` converts to an enum without a cast, and CS8524 warns about a `switch` expression that has an arm for every name | An enum variable can hold a number that has no name: the lesson's program fails on 7 | [Lesson 6](06-records-structs-enums/), [journal](journal/#2026-10-01--records-structs-and-enums) |
| A draft said that `shape[i].Fret += 2` on a list of `readonly record struct` gives CS1612; a probe compiled before publishing gave CS8852 | Every output and error message in the course is pasted from a run, never written from memory | [Lesson 6](06-records-structs-enums/), [journal](journal/#2026-10-01--records-structs-and-enums) |
| In Guitar Alchemist, `ChordTemplate`'s `ToString() => Name` is not `sealed`, so its derived records print all their properties instead of the chord's name | The `override` of lesson 7 meets the records of lesson 6 in real code; one GA call site logs the dump. Not reported to GA yet | [Lesson 7](07-interfaces-and-inheritance/), [QA table](journal/#qa) |
| A nullable warning points where `null` gets in, not where the program crashes: CS8618 sits on the property's declaration, and the line that crashes has no warning | Fix each warning where it is, even far from the crash | [Lesson 8](08-exceptions-and-null-safety/), [journal](journal/#2026-10-02--exceptions-and-null-safety) |
| Guitar Alchemist silences fifteen nullable warnings in `NoWarn`, twice. Its code has none to hide, but a test file with seven nullable mistakes compiled without a warning | Silencing a warning also silences the mistakes still to come. Not reported to GA yet | [Lesson 8](08-exceptions-and-null-safety/), [QA table](journal/#qa) |
| A dictionary's `foreach` follows the order of addition only until the first `Remove`: a key added afterwards takes the removed key's place | A sorted result put in a `Dictionary` stays sorted by chance; sort when the order matters | [Lesson 9](09-collections-and-linq/), [journal](journal/#2026-10-02--collections-and-linq) |
| Three of the four YAML files that Guitar Alchemist's music knowledge services read don't load; each loader catches the exception and carries on with one default item | A `catch` that only prints hides the bug: GA counts 16 artists, and nothing fails. Reported as [GA issue #797](https://github.com/GuitarAlchemist/ga/issues/797) | [Lesson 9](09-collections-and-linq/), [QA table](journal/#qa) |
| A relative path starts from the current directory, not from the program's file: `l10_where.cs` finds `data/ga-projects.csv` when `dotnet run` starts in `code/csharp-beginner`, and misses it from the repository root | The same program finds its file or not depending on the folder it is started from; a path built from `EntryPointFileDirectoryPath` works from both | [Lesson 10](10-files-and-text/), [journal](journal/#2026-10-03--files-and-text) |
| The format string that Guitar Alchemist writes its naturalness CSV with follows the machine's culture: under `fr-FR`, `2.50` becomes `2,50`, and a row of 6 values splits into 8 | A file written on a French machine doesn't read back with `Split(',')`; write numbers with `CultureInfo.InvariantCulture`. Not reported to GA yet | [Lesson 10](10-files-and-text/), [QA table](journal/#qa) |

## Prerequisites

- A computer with Windows 10 or 11, a recent Linux distribution (or WSL), or macOS 14 or later.
- About 1 GB of disk for the .NET SDK.
- A terminal: lesson 1 explains how to open one.
- An editor: [Visual Studio Code](https://code.visualstudio.com/) with the C# Dev Kit extension, [Visual Studio](https://visualstudio.microsoft.com/) on Windows, or [JetBrains Rider](https://www.jetbrains.com/rider/). Lesson 1 compares them.

## After this course

An *Advanced C#* course, written at the same time as this one, starts where it ends: memory, the garbage collector, `async` under the hood and measured performance. The [Java for C# developers](../java-for-csharp/) and [Rust for C#/Java developers](../rust-for-csharp-java/) courses use C# as their starting point.

## Resources

- [C# documentation](https://learn.microsoft.com/dotnet/csharp/), and its [tour of C#](https://learn.microsoft.com/dotnet/csharp/tour-of-csharp/) and [fundamentals](https://learn.microsoft.com/dotnet/csharp/fundamentals/program-structure/).
- [C# language reference](https://learn.microsoft.com/dotnet/csharp/language-reference/): every keyword, operator and compiler error.
- [.NET CLI overview](https://learn.microsoft.com/dotnet/core/tools/): the `dotnet` command.
- [File-based apps](https://learn.microsoft.com/dotnet/core/sdk/file-based-apps): running a single `.cs` file.
