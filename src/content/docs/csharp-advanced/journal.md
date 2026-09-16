---
title: Journal
description: Dated progress notes for the Advanced C# course — the GA pin, checking IL and compiler errors on three OSes, what the JIT and the runtime did that the documentation doesn't say, benchmarks on a hybrid processor, deterministic programs for channels, Dataflow and Rx, the new outline, GA findings and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Course code: the lessons' program, the decompiled examples, the rejected snippets and the benchmarks, compared with their expected output by `check.sh`
- [x] CI on Linux, Windows and macOS, with a dry run of every benchmark
- [x] Lesson 1: memory, values, references and spans
- [x] Lesson 2: the garbage collector
- [x] Lesson 3: async and await under the hood
- [x] Lesson 4: measured performance
- [ ] Lesson 5: generics in depth
- [x] A new outline in four parts and 24 lessons, with ASP.NET Core in depth and Spring and Reactor equivalents
- [x] Lesson 6: channels
- [x] Lesson 7: TPL Dataflow
- [x] Lesson 8: Rx.NET
- [x] Lesson 9: choosing a stream
- [x] Appendix 1: five GA members optimised, proved on all 4096 pitch-class sets, then measured — with the benchmarks rewritten once they turned out to be measuring the JIT

## 2026-09-14 — Setup and the GA pin

- The course builds against three GA projects, `GA.Core`, `GA.Domain.Core` and `GA.Business.Config`, fetched by [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/fetch-ga.sh) from commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the head of GA's `main` that day, with a blobless, sparse clone: about 11 MB instead of the whole repository. It's the same commit and the same script as the [music theory course](../../music-theory-ga/journal/), so both courses read the same code.
- My machine has the .NET 10.0.112 SDK and an 11.0 preview. The course's `global.json` pins `10.0.100` with `rollForward: latestFeature`, so `dotnet` picks 10.0.112 there and the preview elsewhere.
- `GA.Core` references the [`Microsoft.Net.Compilers.Toolset`](https://www.nuget.org/packages/Microsoft.Net.Compilers.Toolset) package in version 4.11.0: that project is compiled by the Roslyn 4.11 of the package, not by the SDK's Roslyn 5.0. It builds fine; I haven't looked for a difference in the IL it produces, *to verify*.
- `ilspycmd` 11.0.0.9375 is a local tool, restored by `check.sh`. Two surprises: `-il` disassembles the whole assembly and ignores `-t Type`, so `check.sh` disassembles the `Snippets` assembly once; and the IL contains `// Method begins at RVA 0x…` comments, which change with every edit of an unrelated method, so `check.sh` removes them before comparing.
- Decompiling with `-lv CSharp4` shows the async state machine: at C# 4 language level, ILSpy can't turn it back into `await`.

## 2026-09-14 — Checking compiler errors

- The rejected snippets are compiled in memory by a small Roslyn program, [`CompileFail`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/CompileFail/Program.cs), rather than one project per snippet: one build instead of eleven. It adds the SDK's implicit `using`s as a separate syntax tree and references the runtime's assemblies. Its messages are identical to those of `dotnet build`.
- **CS4007 was missing** at first: the checker called `compilation.GetDiagnostics()`, and a `Span<int>` used across an `await` compiled without error. That error is reported only while the compiler rewrites the method into a state machine, which `GetDiagnostics()` doesn't do. The checker now calls `compilation.Emit(Stream.Null)` and reads its diagnostics.
- I expected CS8175 for a span captured by a lambda, from memory of older compilers; Roslyn 5.0 reports **CS9108** ("Cannot use parameter 'frets' that has ref-like type inside an anonymous method…"). Lesson 1 quotes the real one.
- The CS8425 snippet produces a warning, not an error: the checker expects it and fails if it's missing.

## 2026-09-14 — What the runtime did that the IL doesn't say

- **Boxing removed by the JIT.** A `box` followed by `unbox.any` of the same type allocates nothing, even in tier 0. With `DOTNET_TieredCompilation=0`, a box that doesn't escape the method is allocated on the stack, including when the value is cast to an interface: the object stack allocation of .NET 9, extended in .NET 10. `check.sh` runs lesson 1 both ways.
- **The large object heap threshold** is checked on the size before rounding: `byte[84,975]` costs 85,000 bytes and stays in generation 0, `byte[84,976]` costs the same and goes to the LOH (lesson 2).
- **Literals are on a frozen heap**: `GC.GetGeneration("C major")` and `GC.GetGeneration(typeof(PitchClass))` return `int.MaxValue`.
- A first version of the allocation-budget loop of lesson 2 kept its arrays in a local variable, and the JIT could allocate them on the stack after OSR, leaving no garbage to collect. The arrays now escape into a ring of 16.
- `Task.WhenAll` keeps the inner exceptions in the order the tasks failed, which changes between runs: the program sorts them, and prints the actual order on a machine-dependent line.
- `SearchValues.Create("#b")` returns `Any2CharPackedSearchValues` on x64 and ``Any2SearchValues`2`` on Arm64 (the macOS runner): another machine-dependent line.
- The gen0 budget depends on the machine's cache size: 18 MB on my machine, 16 MB on the Linux runner, 24 MB on the Windows runner and 6 MB on the macOS runner, where the same 32 MB of garbage caused five collections instead of one.

## 2026-09-14 — Benchmarks

- BenchmarkDotNet 0.15.8. Machine: Intel Core Ultra 9 285K (24 cores), 64 GB, Windows 11 25H2, .NET SDK 10.0.112, runtime 10.0.12. BenchmarkDotNet switched the Windows power plan to *High performance* for each run and back afterwards.
- CI runs every benchmark with `--job Dry`. The first dry run took **8 min 30 s**: `JitBenchmarks` declares its four jobs in a config, and `--job Dry` *added* a dry job to them instead of replacing them. The config now uses `Job.Dry` when `BENCHMARKS_DRY=1`, and the whole dry run takes about 30 s locally, 17 to 53 s on the runners.
- The full run of the seven classes, one after the other with nothing else running, took about 45 minutes. `JitBenchmarks` alone runs four jobs and took 4 minutes.
- **The same code measured 31 ns in warmup and 41 to 52 ns in the actual iterations** (`VoicingWithSpans`). Pinned to one core with `--affinity`, it measured 32.4 ns, on the first core as on the last. The Core Ultra 9 285K has performance and efficiency cores; I haven't checked which kind those two cores are, nor confirmed that thread migration explains the slower iterations, *to verify*. Lesson 4 tells the story and keeps the unpinned tables, since that's what a reader will get by default.
- I added `[MemoryDiagnoser]` to `JitBenchmarks` while the other classes were running, without rebuilding: the run used the previous build and printed no `Allocated` column. Rebuilt and rerun, it showed the result lesson 4 is built on: with PGO, the loop over `IEnumerable<int>` no longer allocates its 40-byte enumerator, and runs 9 times faster.
- Two expectations of mine were wrong: `FrozenDictionary` was no faster than `Dictionary` on twelve short chord suffixes, and `SearchValues` was 1.7 times *slower* than a loop on chord symbols of 1 to 6 characters. Both are in lesson 4 as measured.

## 2026-09-14 — Dogfooding: what the lessons found in GA

None of these has been reported upstream yet; they are listed for the GA maintainers to decide on.

- [`PitchClassSetId.ItemsSpan`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L59-L71) copies the 4,096 ids into a new array on every call, 16,408 bytes. `Items` is declared as `IReadOnlyCollection<PitchClassSetId>` and initialized with a collection expression, so the compiler creates a `<>z__ReadOnlyList<PitchClassSetId>`, and the `is PitchClassSetId[]` test that should avoid the copy is always false (lessons 1 and 2).
- [`PitchClass`'s `-` operator](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L110-L137) looks up a `FrozenDictionary` of 144 tuples to compute `(a - b + 12) % 12`. It takes 583 ns for the 144 pairs, against 134 ns for the arithmetic and 41.5 ns for a flat array of 144 values (lesson 4).
- [`Try.OfAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Functional/Try.cs#L62-L73) awaits without `ConfigureAwait(false)`, so blocking on it under a single-threaded synchronization context deadlocks, and it catches `OperationCanceledException`, turning a cancellation into an ordinary failure (lesson 3).
- [`LazyWithExpiration<T>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Utilities/LazyWithExpiration.cs#L20-L40) measures its expiration with a `Thread.Sleep` on a thread-pool thread, one per value. With 64 values expiring after one second, an unrelated `Task.Run` waited 2 s on my machine and 10 to 12 s on the 3- and 4-core runners (lesson 3). I haven't looked for the places where GA uses it, *to verify*.

## 2026-09-14 — CI

- Commit [`d85a319`](https://github.com/spareilleux/learn/commit/d85a319), run [34915741516](https://github.com/spareilleux/learn/actions/runs/34915741516): green on the three OSes, lessons' code only.
- Commit [`8ba378e`](https://github.com/spareilleux/learn/commit/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3), run [34919815590](https://github.com/spareilleux/learn/actions/runs/34919815590): the exercise solutions, green on the three OSes. Jobs took 1 min 23 s on Linux, 2 min on macOS and 3 min 14 s on Windows, of which the dry run of the 37 benchmarks took 23 s, 27 s and 53 s. About 14 s of each job is lesson 3's `LazyWithExpiration` demonstration: a `Task.Run` waited 11,001 ms on Linux, 11,766 ms on macOS and 11,050 ms on Windows, where the previous run had measured 9,878 ms.
- The Windows runner reported the same vector widths and the same floating-point differences as my machine; the Linux runner has AVX-512.

## 2026-09-15 — A new outline, and part 2 starts

- The course grows from 12 to 24 lessons in four parts: runtime and performance, concurrency and data flow, ASP.NET Core in depth, metaprogramming and tooling. Lessons 1 to 4 keep their slugs; the old lessons 6 and 12 become lessons 10 and 19, and lessons 2 and 3 now point there. Lessons 6 to 9 were written before lesson 5.
- Parts 2 and 3 compare each topic with Spring and Reactor, from C# to Java. The [Spring Boot, Spring Cloud and Reactor course](../../spring-cloud-reactor/) makes the comparison in the other direction, so the lessons link to its pages instead of explaining Reactor again, and part 3 will build the ASP.NET Core counterpart of its scales service.

## 2026-09-15 — Making concurrent programs deterministic

Every behaviour in lessons 6 to 9 is printed by the program and compared with `expected/`, on three OSes. A first version of each lesson printed something that changed between runs; each lesson ran at least nine times in a row before its output was committed.

- **Gates, not delays.** Items are held with a `TaskCompletionSource` until the program has seen what it wants to show, and "the producer is stuck" is measured by waiting until a counter stops moving, then printing the counter.
- **Continuations run when they like.** A `WriteAsync(...).AsTask()` that had completed still reported `IsCompleted` false on some runs, because its continuation is asynchronous: the program now awaits it. The same with `Fault` on a Dataflow block, whose `Completion.Exception` was still `null` right after the call.
- **`EnsureOrdered = false` doesn't mean "reversed".** A first test expected the slow item 0 to come out last; it didn't in 8 runs of 20. Lesson 7 now shows what a consumer can receive while item 0 runs.
- **Boundaries in virtual time.** Notes at exactly 500 or 1,000 ms fell on the edge of `Sample` and `Buffer` windows; lesson 8's notes are placed away from them.
- **`Reader.Count` throws** `NotSupportedException` on an unbounded channel created with `SingleReader = true`: its `CanCount` is `false`. The program drains the channel to count what's left.
- **Rx.NET 7.0 has no bridge to `IAsyncEnumerable`**: `ToAsyncEnumerable()` on an observable didn't compile. Lesson 9 writes both directions by hand.
- Lesson 7's first version labelled Dm7 as Forte 4-3, from GA's `ProgrammaticForteCatalog`; Forte's table says 4-26. The lesson now takes the labels from `CanonicalForteCatalog` and prints both.
- Commits [`69bb214`](https://github.com/spareilleux/learn/commit/69bb2145cf22795d6394209ff82220e8a2bdf0d4) and [`b4d713f`](https://github.com/spareilleux/learn/commit/b4d713f86711b770a75d7504f334c5871c95f820), runs [34994143077](https://github.com/spareilleux/learn/actions/runs/34994143077) and [34995561655](https://github.com/spareilleux/learn/actions/runs/34995561655): green on the three OSes.
- The stream benchmark of lesson 9 ran alone for 5 minutes on the same machine as lesson 4. BenchmarkDotNet reported a bimodal distribution for `RxObserveOnTaskPool`.

## 2026-09-15 — Dogfooding: channels, Dataflow and Rx in GA

GA uses channels in its voicing generator and its index command, and TPL Dataflow and Rx.NET in a performance demo. None of these has been reported upstream yet.

- [`VoicingGenerator.GenerateAllVoicingsAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Generation/VoicingGenerator.cs#L180-L249): a consumer that stops early, like the usage example's `.Take(100)`, leaves the producers generating every window into an unbounded channel; a window that throws leaves the consumer waiting forever, because `Writer.Complete()` is never reached; the summary says the order is preserved, the comments below it say it isn't (lessons 6 and 9).
- [`IndexVoicingsCommand`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaCLI/Commands/IndexVoicingsCommand.cs#L158-L251): when the consumer fails, the database being down for example, it logs and returns, and the producers wait forever on the full channel (lesson 6). The bounded channel in `Wait` mode is the right choice.
- [`PerformanceOptimizationDemo`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Performance/PerformanceOptimizationDemo/Program.cs): the Dataflow part counts results from a `List<T>` filled by another thread without awaiting that thread, and ignores `SendAsync`'s result (lesson 7); the Rx part counts batches as events, 10 instead of 1,000, and waits a fixed 500 ms instead of awaiting the pipeline (lesson 8). Its channel part is correct.
- The same demo and `MusicalAnalysisApp`, both `net10.0`, reference the `System.Threading.Tasks.Dataflow` 9.0.10 package, which .NET 10 already has in its shared framework. A new `net10.0` project with the same reference gets warning NU1510 at restore, and loads the framework's assembly anyway.
- `ProgrammaticForteCatalog`'s numbers follow another ordering than Forte's table, although its remarks call the differences minor: 4-3 for the minor seventh chord where Forte says 4-26 (lesson 7).
- GA has several `BackgroundService` classes, among them the cache warming and the voicing index initialization; lesson 15 is the place to read them.

## 2026-09-15 — Appendix 1: optimising GA, with the proof first

Lesson 4 measured GA's code as it is. This appendix rewrites three members of it, and the interesting part turned out not to be the speed-up but what the rewrite is *not* allowed to change.

- The three are `PitchClassSetId.IsClusterFree`, `PitchClassSet.IntervalClassVector` and `PitchClassSet.ClosestDiatonicKey`. They all take a 12-bit set, so the whole input domain is 4096 values: `Advanced -- a1` compares each rewrite with GA's own answer for every one of them, and CI runs that on three OSes. Writing the proof before the benchmark changed what I was willing to claim.
- `IntervalClassVectorId` packs six counts as base-12 digits, and the chromatic aggregate's counts of 12 carry. GA documents it as a known limitation. Packing it correctly would change set 4095's id, and `ProgrammaticForteCatalog` orders each cardinality by that id, so every Forte number could move — the fast version reproduces the carry instead. A "fix" smuggled into a performance change is the thing this appendix is about.
- `ClosestDiatonicKey`'s answer depends on `OrderByDescending` being stable: ties fall to whichever key `Key.Items` lists first, the 15 major ones before the 15 minor ones. A loop that replaced its incumbent on `>=` rather than `>` would quietly return a different key on every tie; the one that replaces on `>` agrees with GA on all 4096 sets.
- **The first benchmarks were wrong, and flattering.** Calling each member once on a `const` argument let the JIT fold the call into a literal: the fast `IsClusterFree` came out at 0.0107 ns, a twenty-fifth of a cycle. A mutable static removed the folding and still gave a median of zero, because BenchmarkDotNet subtracts an empty method. Rewritten to sweep all 4096 sets, `IsClusterFree` is 4 times faster, not 31 — and I would have published the 31.
- The 175 KB is the finding, not the microseconds. `IdentifyClosestKey` receives a `Dictionary<Key, IReadOnlyCollection<PitchClass>>` and destructures it as `foreach (var (key, _) in items)`: the values are built for all 30 keys and never read. No profiler was needed — just reading the method.
- `ToNormalForm` and `PrimeForm` are done too, so the appendix now proves five members rather than three. Tabulating the normal form took the last 16 KB out of the fast `ClosestDiatonicKey`, which now allocates nothing: 1,615 times faster, 175 KB per call gone. `PrimeForm`, which was already bit arithmetic, only gave 1.8 — the honest ceiling on rewriting correct arithmetic, and worth having next to the 1,615.
- None of this has been reported upstream.

## To verify

- Whether `PoolingAsyncValueTaskMethodBuilder` removes the 104 bytes of `ValueTaskAfterYield` (lesson 3).
- The IL of `GA.Core` compiled by Roslyn 4.11 against the SDK's Roslyn 5.0.
- The lessons were written on x64; the Arm64 results come only from the macOS runner's machine-dependent lines, never from a benchmark.
