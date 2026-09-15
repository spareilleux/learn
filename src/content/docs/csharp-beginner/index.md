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
| 5 | Classes and objects | fields, properties, constructors, methods, `static` |
| 6 | Records, structs and enums | value and reference types, equality, `enum` |
| 7 | Interfaces and inheritance | `interface`, `abstract`, `override`, polymorphism |
| 8 | Exceptions and null safety | `try`/`catch`/`finally`, `throw`, nullable reference types |
| 9 | Collections and LINQ | `Dictionary<TKey, TValue>`, `HashSet<T>`, `Where`, `Select`, `OrderBy` |
| 10 | Files and text | `File`, `Path`, reading a CSV file of Guitar Alchemist's projects |
| 11 | Unit tests | xUnit, `dotnet test`, testing the methods of earlier lessons |
| 12 | A small project | a solution with a library, a console app and tests, a NuGet package, a first look at `async` |
| — | [Journal](journal/) | |

Lessons 5 to 12 are planned and not written yet.

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
