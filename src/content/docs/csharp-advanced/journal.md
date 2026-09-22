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
- [x] Lesson 5: generics in depth
- [x] A new outline in four parts and 24 lessons, with ASP.NET Core in depth and Spring and Reactor equivalents
- [x] Lesson 6: channels
- [x] Lesson 7: TPL Dataflow
- [x] Lesson 8: Rx.NET
- [x] Lesson 9: choosing a stream
- [x] Lessons 10-14: shared state and the ASP.NET Core request path
- [x] Lesson 15: hosted services and background work
- [x] Lesson 16: authentication and authorization
- [x] Lesson 17: a bounded Petri specification oracle translated into deterministic Channel, TPL Dataflow and Rx test design
- [x] Appendix 1: five GA members optimised, proved on all 4096 pitch-class sets, then measured — with the benchmarks rewritten once they turned out to be measuring the JIT
- [x] Appendix 2: GA's indexing pipeline profiled, three changes proved against GA's own output and measured, and sent upstream as pull requests

## QA

This course profiles [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), a public repository, and runs on .NET 10 and BenchmarkDotNet — so everything below is somebody else's code, even where the author of GA and the author of the course are the same person. Three rows went upstream as pull requests and were merged; the rest were never reported, and the Status column says which is which.

| Expected | What happens | Where | Measure | Status |
|---|---|---|---|---|
| Recognising a chord for each voicing costs what one recognition costs | 667,125 voicings use about 2,500 distinct pitch-class sets, so each set's pattern search was repeated about 266 times | `CanonicalChordRecognizer.IdentifyChordSet` | `dotnet-trace` put about 52% of the main thread there, most of it building `HashSet`s. With a 4096-slot cache, `VoicingAnalyzer.Analyze` went from 234.34 ms and 759 MB to 8.94 ms and 22 MB | Fixed upstream, [PR #695](https://github.com/GuitarAlchemist/ga/pull/695) [2026-09-17](#2026-09-17--appendix-2-profiling-ga-with-pull-requests) |
| The interval-class vector is computed once per set | It was recomputed per call | GA's atonal theory | Part of the same analysis path; the dump of 8,192 vectors is byte-identical before and after | Fixed upstream, [PR #694](https://github.com/GuitarAlchemist/ga/pull/694) [2026-09-17](#2026-09-17--appendix-2-profiling-ga-with-pull-requests) |
| `OptickIndexReader.Dimension` is read once | It was read per query, through a property running a LINQ `Where` + `Sum` over the partition registry | `OptickIndexReader.Dimension` | The 38 MB per query attributed to the search were allocated here, not by `Parallel.For`: a sequential scan allocated the same 38 MB | Fixed upstream, [PR #693](https://github.com/GuitarAlchemist/ga/pull/693) [2026-09-17](#2026-09-17--appendix-2-profiling-ga-with-pull-requests) |
| The OPTIC-K index export is reproducible from one commit | The first export of the evening differs from the later ones in 266 of 313,047 entries, from the same GA commit | OPTIC-K export | 266 entries of 313,047, keyed by instrument and diagram | Reproduced, cause unknown, not reported. Every comparison in the appendix is between exports of the same group [2026-09-17](#2026-09-17--appendix-2-profiling-ga-with-pull-requests) |
| `ValueObjectUtils<TSelf>.Items` returns the collection it holds | It creates a new 32-byte `ValueObjectCollection<TSelf>` on each call | [`ValueObjectUtils.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L10) | 32 bytes per call | Reproduced, not reported [2026-09-16](#2026-09-16--dogfooding-gas-value-object-interfaces) |
| `IRangeValueObject<TSelf>.EnsureValueInRange` normalizes over the real range | It normalizes with a range size computed off by one | [`IRangeValueObject.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IRangeValueObject.cs#L55-L63) | Wrong value at the boundary | Reproduced, not reported [2026-09-16](#2026-09-16--dogfooding-gas-value-object-interfaces) |
| `default(Str)` gives a valid value object | It gives string 0, which `Str`'s own range check forbids — as does `new Str[n]` and `new T()` in a generic method | Every GA value object whose minimum is 1 | Lesson 5 shows the three ways in | Reproduced, a limit of the pattern rather than a defect [2026-09-16](#2026-09-16--dogfooding-gas-value-object-interfaces) |
| The `out` of `IStaticReadonlyCollection<out TSelf>` buys variance | It buys nothing: 13 of its 17 implementers are structs, and the interface has no instance members | `IStaticReadonlyCollection<out TSelf>` | 13 of 17 | Reproduced, harmless [2026-09-16](#2026-09-16--dogfooding-gas-value-object-interfaces) |
| `ValueObjectCache<T>` builds what its callers use | It builds two `FrozenSet`s at first use that nothing reads | [`ValueObjectCache.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectCache.cs#L38-L52) | Two sets built, zero readers | Reproduced, not reported [2026-09-16](#2026-09-16--dogfooding-gas-value-object-interfaces) |
| A benchmark's warmup measures what its iterations measure | The same code measured 31 ns in warmup and 41 to 52 ns in the iterations | BenchmarkDotNet, `VoicingWithSpans` | Pinned to one core with `--affinity` it measured 32.4 ns, on the first core as on the last: the Core Ultra 9 285K's cores are not alike | Understood, and it is why the lesson pins the core [2026-09-14](#2026-09-14--benchmarks) |
| Adding `[MemoryDiagnoser]` to a running series adds its column | Without a rebuild, the run used the previous build and printed no `Allocated` column, silently | BenchmarkDotNet | No column, no warning | Reproduced, user error made invisible by the tool [2026-09-14](#2026-09-14--benchmarks) |
| Dynamic PGO removes the enumerator allocation as it does in lesson 4 | It did not: the first mask version still allocated 72 bytes per call, from enumerators obtained through `IEnumerable<int>` | .NET 10 dynamic PGO | Switching to `int[]` and `HashSet<int>` removed the 72 bytes and made it 2.7 times faster again | Reproduced; why lesson 4's case devirtualises and this one does not is still open [2026-09-17](#2026-09-17--appendix-2-profiling-ga-with-pull-requests) |

## Experiments

Performance work invites reading a prediction back out of its own result, so these rows keep the hypothesis as it was written and let it be wrong. Two of the six are refuted, and the appendix's method — comparing two builds of GA rather than two methods, and checking that every answer is byte-identical — is itself the third row.

| Question | Hypothesis | Result | Verdict | Where |
|---|---|---|---|---|
| Is `FrozenDictionary` faster than `Dictionary` for twelve short chord suffixes? | Written in advance: yes, that is what it is for | It was not faster | Refuted | [2026-09-14](#2026-09-14--benchmarks) |
| Is `SearchValues` faster than a loop over chord symbols of 1 to 6 characters? | Written in advance: yes | 1.7 times slower | Refuted | [2026-09-14](#2026-09-14--benchmarks) |
| Does a build with the analysis changes give byte-identical answers to `main`? | Written in advance, and it is the whole method: the proof compares two builds of GA, not two methods | Identical on all five dumps: `TryMatch` 258,048 lines, recognition 106,496, interval-class vectors 8,192, all 667,125 voicings, 2,048 searches on the real 313,047-entry index | Confirmed | [2026-09-17](#2026-09-17--appendix-2-profiling-ga-with-pull-requests) |
| Were the search's 38 MB per query caused by `Parallel.For`? | Written in advance: parallelism was the suspect | A sequential scan allocated the same 38 MB, which cleared `Parallel.For` and pointed at `GetVector` | Refuted | [2026-09-17](#2026-09-17--appendix-2-profiling-ga-with-pull-requests) |
| Does range partitioning of the search survive the allocation fix? | Not written as a prediction: it measured 8% faster before the fix, so it looked worth keeping | 22% slower after it. Dropped | Refuted | [2026-09-17](#2026-09-17--appendix-2-profiling-ga-with-pull-requests) |
| Does the whole OPTIC-K export get faster end to end, not just the benchmark? | Written in advance: the analysis is most of the export | Four runs alternating `main` and the changed build: 142.8 s against 62.9 s, then 95.0 s against 38.3 s. The same `main` binary took 142.8 s then 95.0 s, so the machine was not idle and the pairs, not the absolute times, are the result | Confirmed | [2026-09-17](#2026-09-17--appendix-2-profiling-ga-with-pull-requests) |

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

## 2026-09-16 — Lesson 5: generics in depth

- Lesson 5 fills the gap between lessons 4 and 6, which were written first. Its outputs come from the same machine and the same SDK as the rest of the course; code commit [`378eec1`](https://github.com/spareilleux/learn/commit/378eec1333390889e29fd0c42af0fae47512035e).
- CI run [35173274425](https://github.com/spareilleux/learn/actions/runs/35173274425): green on Linux, Windows and macOS. The machine-dependent lines were the same on the three runners as on my machine, the Arm64 one included: 4,592 bytes for the first access to `Str`'s cache, and 1 then 0 methods compiled for `Shared<string>` then `Shared<object>`.
- **The JIT's own summary as a test.** `DOTNET_JitDisasmSummary=1` and `DOTNET_JitStdOutFile` work in the shipped runtime, so `check.sh` compares the list of `Shared<T>.Describe` compilations: four for six type arguments, one of them over `System.__Canon`. It starts `Advanced.dll` directly: through `dotnet run`, the SDK's own process would inherit the variables and write to the same file.
- **What the runtime doesn't check.** `MakeGenericMethod` accepted `(int, string)` for a `where T : unmanaged` parameter; the compiler rejects it with CS8377. `notnull` leaves nothing in `GenericParameterAttributes`.
- **A snippet I expected to fail compiled.** GA's `IStaticReadonlyCollectionFromValues<TSelf>` hides the static abstract `Items` with a `new static` property that has a body. I expected `T.Items` on a type parameter constrained to it to be rejected; Roslyn 5.0 compiled it. I dropped the snippet; which member that call binds to is *to verify*.
- **The disassembly changed my reading of the benchmark.** In shared code, reading a static field of `Counter<T>` calls `CORINFO_HELP_GET_NONGCSTATIC_BASE` on every iteration, at tier 1 as with tiering off, yet the loop was only 1.46 times slower than the `int` version.
- **PGO again.** A `foreach` over `PitchClass.Items` allocates 72 bytes in the program's first calls and 40 bytes in the benchmark, after dynamic PGO.

## 2026-09-16 — Dogfooding: GA's value-object interfaces

None of these has been reported upstream yet.

- [`ValueObjectUtils<TSelf>.Items`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L10) creates a new 32-byte `ValueObjectCollection<TSelf>` on every read, although the interface documents `Items` as memoized; a `foreach` over it allocates 72 bytes (lesson 5).
- `Values` is declared `IReadOnlyList<int>` in [`IStaticValueObjectList<TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Collections/Abstractions/IStaticValueObjectList.cs#L57), and the implementers return an `ImmutableArray<int>`: 24 bytes of boxing per read. Twelve reads took 41.8 ns and 288 bytes, against 3.1 ns and nothing through the `ImmutableArray` (lesson 5).
- [`ValueObjectCache<T>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectCache.cs#L38-L52) builds two `FrozenSet`s at its first use, which nothing in the three fetched projects reads: 4,592 bytes for `Str`'s 26 values (lesson 5).
- [`IRangeValueObject<TSelf>.EnsureValueInRange`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IRangeValueObject.cs#L55-L63) normalizes with a range size of `max - min` instead of `max - min + 1`: 12 becomes 2 for a pitch class. No caller in the fetched projects passes `normalize: true`, so it's latent (lesson 5).
- `default(Str)`, `new Str[n]` and `new T()` give string 0, which `Str`'s range check forbids; the same holds for every GA value object whose minimum is 1 (lesson 5).
- The `out` of `IStaticReadonlyCollection<out TSelf>` has no effect: 13 of its 17 implementers are structs, and the interface has no instance members (lesson 5).

## 2026-09-17 — Appendix 2: profiling GA, with pull requests

Appendix 1 chose what to optimise by reading GA. This time a profiler chose, on GA's own pipeline at commit [`66bdd04`](https://github.com/GuitarAlchemist/ga/tree/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e), and each change went upstream. The work ran from the evening of 2026-09-16 to the early hours of 2026-09-17.

- **Three pull requests.**
  - [#695](https://github.com/GuitarAlchemist/ga/pull/695): chord recognition with 12-bit masks, computed once per pitch-class set.
  - [#694](https://github.com/GuitarAlchemist/ga/pull/694): the interval-class vector computed once per set.
  - [#693](https://github.com/GuitarAlchemist/ga/pull/693): `OptickIndexReader.Dimension` read once.

  Each was made on its own branch from `main`. The GA tests passed before each PR was opened: GA.Domain.Core.Tests 458/458 and 459/459, and the chord and voicing tests of GA.Business.Core.Tests 421/421 and 419/419. For GA.Business.ML.Tests, the search and schema tests passed 227 of 228; the failing test fails the same way on `main`.
- **Where the time went.** `dotnet-trace` over voicing analysis put about 52% of the main thread in `CanonicalChordRecognizer.IdentifyChordSet`, most of it building `HashSet`s. A probe put `VoicingAnalyzer.Analyze` at 173 µs and 347 KB per voicing, and an OPTIC-K search at 38 MB per query.
- **The proof compares two builds of GA, not two methods.** One dump program is built against `main` and against the branch, writes every answer, and `cmp` compares the files. All were byte-identical:
  - `TryMatch`: 258,048 lines;
  - recognition: 106,496 lines, every set × 13 basses × 2 passes;
  - interval-class vectors: 8,192 lines;
  - all 667,125 guitar voicings through `VoicingAnalyzer.Analyze`;
  - 2,048 searches on the real 313,047-entry index.

  The course's own proof, `GaPerf -- a2`, checks 6,856,704 `TryMatch` calls and 106,496 recognitions, and runs in CI.
- **The cache was the finding, not the masks.** 667,125 voicings use about 2,500 distinct pitch-class sets, so each set's pattern search was repeated 266 times. With a 4096-slot array, recognition is 7,600 times faster in the course's benchmark. In GA, `VoicingAnalyzer.Analyze` went from 234.34 ms and 759 MB to 8.94 ms and 22 MB for 2,000 voicings with both changes.
- **The search's 38 MB were not in the search.** An experiment with a sequential scan allocated the same 38 MB as the parallel one, which cleared `Parallel.For`. The bytes came from `GetVector`, which read a property that runs a LINQ `Where` + `Sum` over the partition registry: 626,094 queries per search. Read once, one search went from 4.986 ms and 38.25 MB to 2.162 ms and 41 KB.
- **Two results I didn't expect.**
  - The first mask version still allocated 72 bytes per call, from enumerators obtained through `IEnumerable<int>`. Switching on `int[]` and `HashSet<int>` removed them and made it 2.7 times faster again. Dynamic PGO didn't remove this allocation, unlike the one in lesson 4; why not is *to verify*.
  - Range partitioning of the search, which looked 8% faster before the fix, was 22% slower after it. I dropped it.
- **End to end**, the OPTIC-K export ran four times, alternating GA's `main` and a build with both analysis changes: 142.8 s against 62.9 s, then 95.0 s against 38.3 s. The index files were identical entry by entry.
- **The machine was not idle, and the numbers say so.**
  - Other sessions were running. Every build and benchmark series took a machine-wide lock, and each BenchmarkDotNet series also took the GPU lock.
  - Free RAM and the busiest processes were logged at the start of each series: 13.6 to 18.5 GB free, 32% to 100% total CPU, with Microsoft Defender, Docker and WSL on top.
  - The same export binary took 142.8 s, then 95.0 s.
  - The coordinator reported two headless Chrome captures by another session between 00:47 and 00:49. None of my series ran in that window: the benchmarks before it ended at 00:42:38, and the next one started at 00:50:22. The GA series that had been running just before were rerun anyway, with the same allocations and times within the error bars.
  - GA's before-and-after tables use `ShortRun`. Their allocations are exact; the times are indicative.
  - One run of the chord series did not happen: my script pointed at a worktree that didn't exist, and it was rerun.
- **Measured and not changed.**
  - `VoicingGenerator`'s parallel path is twice as slow as its sequential one (1,419 ms against 711 ms for 667,125 voicings), and `PitchClassSet.GetCompatibleKeys` takes 13.5% of the analysis profile. Both files belong to GA fixes in progress in another session, so these went there as proposals.
  - `KeyIdentificationService.Identify` is not on the hot path: 25 µs, once per request.
  - Lesson 5's value-object allocations don't appear in this profile.
- **The index export is not always reproducible.** The first export of the evening differs from the later ones in 266 of 313,047 entries, keyed by instrument and diagram, although it came from the same GA commit. Every comparison above is between exports of the same group; the cause is *to verify*.

## 2026-09-21 — Lessons 10-14: concurrency and the ASP.NET Core request path

- Added five executable lessons against .NET 10.0.12: one deterministic lost-update schedule, `Lock` and `Interlocked`, `ConcurrentDictionary`, and a bounded `Parallel.ForEachAsync` probe.
- Started real Kestrel instances on ephemeral loopback ports. Verified the host lifecycle, one successful request, graceful shutdown, middleware nesting, and a deliberate `429` short-circuit.
- Verified singleton/scoped identity, captive-dependency rejection with scope validation, keyed services, and options validation.
- Verified one Minimal API with route/query binding and an endpoint filter, one controller in the same routing table, and an `IAsyncEnumerable<string>` JSON response.
- The portable output is checked in `expected/l10.txt` through `expected/l14.txt`. Thread-pool minimums remain machine-dependent evidence and are excluded with the existing `#` convention.
- These are local protocol probes. They do not yet measure proxy buffering, production Kestrel limits, a real identity provider, or a remote dependency under thread-pool starvation.

## 2026-09-21 — Lessons 15-16: hosted work and local authorization

- The hosted-service proof uses completion gates rather than delays. One bounded channel feeds a singleton worker, and two operations resolve different scoped-service instances (`scope-1` and `scope-2`). Host cancellation is observed while the worker is waiting for more work.
- A second host releases a deliberate worker fault and observes `ApplicationStopping` under `BackgroundServiceExceptionBehavior.StopHost`. This proves the host policy, not retry or recovery.
- The authentication proof starts Kestrel on an ephemeral loopback port. Missing, malformed, expired and wrongly signed bearer tokens return 401; a valid identity without `scope=scales.read` returns 403; the authorized identity returns `200 C major`.
- Both signing keys are generated in memory for one process. The lifetime decision uses a fixed course instant, and no key or token is printed or persisted.
- `Advanced` built locally with zero warnings, and both new transcripts matched `expected/l15.txt` and `expected/l16.txt`. Three-OS CI, a real authorization server, key discovery/rotation and deployment behind a proxy remain to verify.

## 2026-09-21 — Lesson 17: Petri oracles for C# pipeline tests

- Reused the executable one-item, one-slot lifecycle from [Petri lesson 14](../../petri-nets/14-on-our-systems/) rather than creating a second model. Its focused suite explores all eight reachable markings, classifies the three terminal dead markings and checks the Channel queue invariant `free + queued = 1`.
- Recorded the boundary between the model and the runtime. The Petri tests validate the finite specification; they do not execute `Channel<T>`, TPL Dataflow or Rx.NET and therefore do not prove the current GA implementation.
- Turned each model path into a deterministic runtime-test recipe based on gates rather than delays. The recipe requires the public exception or completion result and settlement of every owned participant.
- Kept capacity semantics separate: Channel capacity counts queued items in this model, Dataflow execution-block capacity includes the running item, and Rx has no bound until the design adds one.
- Documented two deliberate limits: cancellation is atomic and pre-start, and the one-item net cannot reproduce a producer already blocked by backpressure after consumer failure. A two-item model and runtime fixtures remain to verify.

## To verify

- Execute the lesson 17 runtime recipes against pinned Channel, Dataflow and Rx fixtures, including a two-item blocked-producer schedule; the current evidence is the Petri oracle only.
- Why dynamic PGO didn't remove the boxed enumerators of the first mask version of `TryMatch` (appendix 2).
- Why GA's OPTIC-K index export differs between sessions in 266 of 313,047 entries (appendix 2).
- Which member `T.Items` binds to when a derived interface hides a static abstract property with a `new static` property (lesson 5).
- Why a helper call per iteration made the shared `ReadStatic<string>` loop only 1.46 times slower (lesson 5).
- Which of the two objects of a `foreach` over `PitchClass.Items` dynamic PGO stops allocating (lesson 5).
- Whether `PoolingAsyncValueTaskMethodBuilder` removes the 104 bytes of `ValueTaskAfterYield` (lesson 3).
- The IL of `GA.Core` compiled by Roslyn 4.11 against the SDK's Roslyn 5.0.
- The lessons were written on x64; the Arm64 results come only from the macOS runner's machine-dependent lines, never from a benchmark.
