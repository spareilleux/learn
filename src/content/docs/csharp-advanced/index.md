---
title: Advanced C# — Mission
description: What happens under the hood of C# 14 and .NET 10 — memory layout, the garbage collector, the async state machine and measured performance — each claim checked by a program, the IL or a benchmark, on real Guitar Alchemist code.
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
Every output in the lessons comes from [`code/csharp-advanced`](https://github.com/spareilleux/learn/tree/main/code/csharp-advanced). [`check.sh`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/check.sh) builds the course program against [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) cloned at commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), runs each lesson, disassembles the examples with [ILSpy's command-line tool](https://github.com/icsharpcode/ILSpy/tree/master/ICSharpCode.ILSpyCmd), compiles every rejected snippet with [Roslyn](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/), and compares all of it with the expected files. [`.github/workflows/csharp-advanced-examples.yml`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/.github/workflows/csharp-advanced-examples.yml) does the same on Linux, Windows and macOS, and checks that every benchmark runs. Lines that depend on the machine start with `# ` and are not compared; benchmark timings come from the author's machine, never from CI. Outputs captured in September 2026 with the .NET SDK 10.0.112 and the .NET 10.0.12 runtime.
:::

## Why I'm learning this

I have written C# for years, and most of what I know about its performance is folklore: "structs are faster", "avoid LINQ", "always `ConfigureAwait(false)`", "`FrozenDictionary` is the fast one". Some of it was true in .NET Framework 4.5 and is wrong on .NET 10, where the JIT removes allocations the IL asks for. This course replaces each piece of folklore with something I can look at: the size of an object, the IL the compiler emitted, the state machine behind `await`, the generation of an array, a BenchmarkDotNet table.

The measurements run on real code, not toy classes: [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA), a large .NET 10 code base about music theory. Its value objects, its caches and its vector helpers are exactly the kind of code where these questions come up, and the lessons found several places where GA pays for something it didn't intend to.

## Who this course is for

You write C# every day and know the language well: generics, LINQ, `async`/`await`, records, pattern matching. You want to know what the compiler, the JIT and the garbage collector do with that code, and to measure before you optimize. If you are starting with C#, begin with the [C# for beginners](../csharp-beginner/) course, which ends where this one starts.

## By the end of this course, I will be able to

- predict the size of a value or an object, spot boxing in IL, and tell when the JIT removes it;
- use `ref`, `in`, `ref readonly`, `Span<T>` and `stackalloc` without defensive copies or escaping references;
- explain generations, the large and pinned object heaps and the GC modes, and read `GC.GetGCMemoryInfo`;
- read the state machine the compiler generates for an `async` method, choose between `Task` and `ValueTask`, and avoid deadlocks and lost cancellations;
- write a BenchmarkDotNet benchmark that measures what I think it measures, and interpret tiered compilation and PGO;
- choose between `Dictionary`, `FrozenDictionary`, `SearchValues` and plain arithmetic, and vectorize a loop with `Vector<T>` or `TensorPrimitives`;
- and, in the later lessons: generic math, source generators, Roslyn analyzers, interop, Native AOT and production diagnostics.

## Outline

| # | Lesson | Under the hood | Measured on GA |
|---|---|---|---|
| 1 | [Memory: values, references and spans](01-memory-values-and-spans/) | object layout, boxing in IL, `ref`/`in`, `ref struct`, `Span<T>`, `stackalloc` | `PitchClass`, `PitchClassSetId.ItemsSpan` |
| 2 | [The garbage collector](02-garbage-collector/) | generations, LOH and POH, workstation and server GC, DATAS, finalizers, `GC.GetGCMemoryInfo` | allocations of `ItemsSpan` with `[MemoryDiagnoser]` |
| 3 | [async and await under the hood](03-async-under-the-hood/) | the generated state machine, `ValueTask`, `SynchronizationContext`, `ConfigureAwait`, cancellation, `IAsyncEnumerable` | `Try.OfAsync`, `LazyWithExpiration` |
| 4 | [Measured performance](04-measured-performance/) | BenchmarkDotNet, tiered JIT and PGO, `SearchValues`, `FrozenDictionary`, `Vector<T>` | `PitchClass` subtraction, `SimdOps.Dot` |
| 5 | Generics in depth | constraints, static abstract members, generic math, `allows ref struct`, how the JIT shares generic code | GA's `IStaticValueObjectList<TSelf>` |
| 6 | Concurrency primitives | `System.Threading.Lock`, `Interlocked`, `Channel<T>`, `Parallel.ForEachAsync`, the thread pool | |
| 7 | Delegates, closures and expression trees | what a lambda compiles to, `Expression<T>`, compiling expressions at run time | |
| 8 | Reflection and source generators | the cost of reflection, incremental generators, `[GeneratedRegex]` | |
| 9 | Roslyn analyzers and code fixes | syntax and semantic models, writing an analyzer and its tests | |
| 10 | Interop and unsafe code | `[LibraryImport]`, function pointers, `Unsafe`, `MemoryMarshal`, pinning | |
| 11 | Native AOT and trimming | what AOT removes, trimming warnings, startup and size measured | |
| 12 | Diagnostics in production | `dotnet-counters`, `dotnet-trace`, `dotnet-dump`, EventPipe, `System.Diagnostics.Metrics` | |
| — | [Journal](journal/) | | |

Lessons 5 to 12 are planned and not written yet.

## Prerequisites

- The [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) and [Git](https://git-scm.com/downloads). On Windows, run the course scripts from Git Bash.
- `check.sh` restores [`ilspycmd`](https://www.nuget.org/packages/ilspycmd) as a local .NET tool (version 11.0.0.9375, pinned in [`.config/dotnet-tools.json`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/.config/dotnet-tools.json)) and fetches the three GA projects the program uses, about 11 MB.
- For the benchmarks, a machine you can keep quiet for a few minutes: close the browser, plug in the laptop.

## Related courses on this site

- [C# for beginners](../csharp-beginner/): the language from zero, written at the same time as this course.
- [Music theory for Guitar Alchemist](../music-theory-ga/) reads the same GA projects for what they compute; this course reads them for how they run.
- [Rust for C#/Java developers](../rust-for-csharp-java/) makes explicit what .NET decides for you: ownership instead of a garbage collector, borrowing instead of `ref` safety rules.

## Resources

- [.NET fundamentals: memory management and garbage collection](https://learn.microsoft.com/dotnet/standard/garbage-collection/), and the [GC configuration settings](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector).
- [C# language reference](https://learn.microsoft.com/dotnet/csharp/language-reference/), in particular [ref structs](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct) and [asynchronous programming](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/).
- Stephen Toub, [Performance Improvements in .NET 10](https://devblogs.microsoft.com/dotnet/performance-improvements-in-net-10/) and [How async/await really works in C#](https://devblogs.microsoft.com/dotnet/how-async-await-really-works/), on the .NET blog.
- The [dotnet/runtime](https://github.com/dotnet/runtime) repository: the lessons link the lines of the runtime they rely on, at tag `v10.0.12` (commit `4271d88`).
- [BenchmarkDotNet](https://benchmarkdotnet.org/) and its [good practices](https://benchmarkdotnet.org/articles/guides/good-practices.html).
- Konrad Kokosa, *Pro .NET Memory Management* (Apress, 2018): older than .NET 10, still the deepest book on the GC.
