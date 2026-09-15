---
title: "Lesson 2: The garbage collector"
description: Generations and promotion, the exact large object heap threshold, the pinned and frozen heaps, weak references and finalizers, workstation, server and concurrent GC, what GC.GetGCMemoryInfo reports, and allocations measured with BenchmarkDotNet's MemoryDiagnoser on Guitar Alchemist.
sidebar:
  label: 2. The garbage collector
  order: 2
---

Lesson 1 counted the bytes of each allocation. This lesson follows those bytes after they are allocated: which heap receives them, when the garbage collector (GC) looks at them again, what it does with objects that survive, and how its configuration changes all of that. Each behaviour is observed from inside the program with the [`GC`](https://learn.microsoft.com/dotnet/api/system.gc) class, then the allocations of real GA code are measured with [BenchmarkDotNet](https://benchmarkdotnet.org/).

GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6); runtime links point to commit [`4271d88`](https://github.com/dotnet/runtime/tree/4271d88e0aebf3d04f188f1334c2220d80555ef6) of `dotnet/runtime`, tagged `v10.0.12`.

## Running the lesson's program

```bash
bash code/csharp-advanced/check.sh                                   # every lesson, compared with expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- l2  # this lesson only, after check.sh
```

The code is [`Advanced/Lesson2.cs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson2.cs). Lines starting with `# ` depend on the machine (heap sizes, pause times, processor count): the lesson quotes them from the author's machine, an Intel Core Ultra 9 285K with 24 cores and 64 GB of memory, and from the CI runners where they differ in an interesting way.

## Generations

The .NET GC is *generational*: it assumes that most objects die young, and collects young objects far more often than old ones ([Fundamentals of garbage collection](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals#generations)). New objects go to generation 0. An object still referenced when its generation is collected is *promoted* to the next one, up to generation 2. A gen0 collection scans only gen0 (plus the references old objects hold to young ones, tracked by the write barrier); a gen2 collection, also called a *full* collection, scans everything.

The program allocates a three-note chord and calls [`GC.Collect()`](https://learn.microsoft.com/dotnet/api/system.gc.collect), which forces a full, blocking collection ([`Lesson2.cs#L58-L73`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson2.cs#L58-L73)):

```text
== Generations: an object that survives a collection is promoted
new int[3]           generation 0
after GC.Collect()   generation 1
after a second one   generation 2
after a third one    generation 2
GC.Collect(0) then new int[3]: generation 0
```

Two collections were enough to make the chord old. That's the trap of calling `GC.Collect()` in application code: it doesn't free memory sooner in any useful way, but it promotes every live object, which then waits for the next full collection, the most expensive kind, to be reclaimed. The course program calls it only to make the GC's behaviour visible.

## The large object heap, to the byte

Objects of 85,000 bytes or more go to the large object heap (LOH), which is collected only with generation 2 and not compacted by default ([The large object heap](https://learn.microsoft.com/dotnet/standard/garbage-collection/large-object-heap)). The documentation says "85,000 bytes"; the program finds the exact boundary.

```text
== Large object heap: 85,000 bytes and more, counted with the object header
new byte[   84,975]  object size    85,000  generation 0
new byte[   84,976]  object size    85,000  generation 2
new byte[1,000,000]  object size 1,000,024  generation 2
new double[10,622]   object size    85,000  generation 2
```

`GC.GetGeneration` reports LOH objects as generation 2. Both of the first two arrays cost 85,000 bytes, yet only the second one is large. The runtime decides before rounding: in [`gchelpers.cpp#L644-L659`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/vm/gchelpers.cpp#L644-L659), an array's `totalSize` is its element count times the element size plus the 24-byte base size, and the array goes to the LOH when `totalSize >= LARGE_OBJECT_SIZE`, defined as 85,000 in [`gc.h#L105`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/gc/gc.h#L105). 24 + 84,975 = 84,999 bytes stays small, and is rounded up to 85,000 afterwards. 24 + 84,976 = 85,000 is large. An array of 10,622 `double`s reaches 85,000 exactly.

The threshold is configurable with `GCLOHThreshold` ([`gcconfig.h#L82`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/gc/gcconfig.h#L82), [GC settings](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector#large-object-heap-threshold)), and the program reads its current value in the next section. Large buffers allocated and dropped in a loop are a classic cause of gen2 collections; [`ArrayPool<T>.Shared`](https://learn.microsoft.com/dotnet/api/system.buffers.arraypool-1.shared) exists to reuse them instead.

## The pinned object heap

Native code, or an I/O operation in progress, may need an array that the GC must not move while it compacts the heap. Pinning an ordinary array with `fixed` or a `GCHandle` blocks compaction around it and fragments generation 0. Since .NET 5, [`GC.AllocateArray<T>(length, pinned: true)`](https://learn.microsoft.com/dotnet/api/system.gc.allocatearray) allocates on a separate pinned object heap (POH) instead, which, like the LOH, is collected with generation 2.

```text
== Pinned object heap: GC.AllocateArray(pinned: true)
pinned byte[1024]    generation 2
ordinary byte[1024]  generation 0
heaps in GCGenerationInfo: 5 (gen0, gen1, gen2, LOH, POH)
```

[`GCMemoryInfo.GenerationInfo`](https://learn.microsoft.com/dotnet/api/system.gcmemoryinfo.generationinfo) describes five heaps: the three generations, the LOH and the POH. On the author's machine, after the collection, the POH held 9,232 bytes: the runtime itself had already put 8,184 bytes there before the program's kilobyte.

## Reachability: weak references and finalizers

The GC frees an object when nothing *reachable* refers to it any more: no local variable of a running method, no static field, no field of another reachable object. A [`WeakReference`](https://learn.microsoft.com/dotnet/standard/garbage-collection/weak-references) points to an object without keeping it alive ([`Lesson2.cs#L99-L135`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson2.cs#L99-L135)). The objects are created in a separate, non-inlined method: in the method that runs `GC.Collect()`, a local variable might still hold them, especially in unoptimized code.

```text
== Reachability: a weak reference does not keep an object alive
only weakly reachable:  IsAlive False
still referenced:       IsAlive True (4 notes)
```

A class with a [finalizer](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/finalizers) (`~Finalizable()`) takes a longer path. When the GC finds it unreachable, it can't free it yet: it moves it to a queue, and a dedicated finalizer thread runs its finalizer. The object, reachable again from that queue, is freed by a later collection. A *short* weak reference stops tracking the object as soon as it's unreachable; a *long* weak reference, created with `trackResurrection: true`, follows it until it's really gone.

```text
== Finalizers: a finalizable object is freed one collection later
after 1 collection:  finalized 1, short weak IsAlive False, long weak IsAlive True
after 2 collections: finalized 1, short weak IsAlive False, long weak IsAlive False
bytes of new Finalizable(): 24, of new object(): 24
```

The finalizable object costs no more bytes, but it survives one more collection, possibly getting promoted on the way, and its registration in the finalization queue makes allocation slower. That's why [`IDisposable`](https://learn.microsoft.com/dotnet/standard/garbage-collection/implementing-dispose) classes that have a finalizer call `GC.SuppressFinalize(this)` in `Dispose()`, and why most classes shouldn't have a finalizer at all: wrap native handles in a [`SafeHandle`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.safehandle), which already has one.

## Workstation, server and concurrent GC

The runtime ships one GC with several modes ([Workstation and server garbage collection](https://learn.microsoft.com/dotnet/standard/garbage-collection/workstation-server-gc)):

- **Workstation** GC, the default for console and desktop applications, uses one heap and collects on the thread that triggered the collection.
- **Server** GC, the default for ASP.NET Core, uses one heap and one GC thread per logical processor, with much larger gen0 budgets: more throughput, more memory. Since .NET 9, [DATAS](https://learn.microsoft.com/dotnet/standard/garbage-collection/datas) (dynamic adaptation to application sizes) is on by default for server GC and adjusts the number of heaps to the load.
- **Concurrent** (background) GC, on by default in both, runs most of a gen2 collection while the application keeps running.

You choose them in the project file (`<ServerGarbageCollection>`, `<ConcurrentGarbageCollection>`), in `runtimeconfig.json` (`System.GC.Server`, `System.GC.Concurrent`), or with environment variables ([GC settings](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector)). `check.sh` runs the program three times: with the defaults, with `DOTNET_gcServer=1`, and with `DOTNET_gcConcurrent=0`. [`GC.GetConfigurationVariables()`](https://learn.microsoft.com/dotnet/api/system.gc.getconfigurationvariables) returns the settings the GC actually uses.

```text
== GC mode
GCSettings.IsServerGC: False
GCSettings.LatencyMode: Interactive
GC.MaxGeneration: 2
GC.GetConfigurationVariables()["ServerGC"]: False
GC.GetConfigurationVariables()["ConcurrentGC"]: True
GC.GetConfigurationVariables()["LOHThreshold"]: 85000
GC.GetConfigurationVariables()["GCDynamicAdaptationMode"]: 1
```

```text
== GC mode
GCSettings.IsServerGC: True
GCSettings.LatencyMode: Interactive
GC.MaxGeneration: 2
GC.GetConfigurationVariables()["ServerGC"]: True
GC.GetConfigurationVariables()["ConcurrentGC"]: True
GC.GetConfigurationVariables()["LOHThreshold"]: 85000
GC.GetConfigurationVariables()["GCDynamicAdaptationMode"]: 1
```

```text
== GC mode
GCSettings.IsServerGC: False
GCSettings.LatencyMode: Batch
GC.MaxGeneration: 2
GC.GetConfigurationVariables()["ServerGC"]: False
GC.GetConfigurationVariables()["ConcurrentGC"]: False
GC.GetConfigurationVariables()["LOHThreshold"]: 85000
GC.GetConfigurationVariables()["GCDynamicAdaptationMode"]: 1
```

[`GCSettings.LatencyMode`](https://learn.microsoft.com/dotnet/api/system.runtime.gcsettings.latencymode) reflects concurrency: `Interactive` with background GC, `Batch` without it. `GCDynamicAdaptationMode` is 1 in all three runs: the setting is on, but it only applies when server GC is. The machine-dependent lines show what server GC costs in memory:

| Machine | Processors | Workstation heaps | Workstation `GCGen0MaxBudget` | Server heaps | Server `GCGen0MaxBudget` |
|---|---:|---:|---:|---:|---:|
| Author (Windows, x64) | 24 | 1 | 18,874,368 | 24 | 209,715,200 |
| CI Linux (x64) | 4 | 1 | 16,777,216 | 4 | 209,715,200 |
| CI Windows (x64) | 4 | 1 | 25,165,824 | 4 | 209,715,200 |
| CI macOS (Arm64) | 3 | 1 | 6,291,456 | 3 | 209,715,200 |

The gen0 budget is the amount of allocation after which a gen0 collection starts; for workstation GC, the runtime derives it from the processor's cache size, so it changes from one machine to the next. Non-concurrent workstation GC reported 134,217,728 bytes on all four machines.

## What `GC.GetGCMemoryInfo` reports

[`GC.GetGCMemoryInfo()`](https://learn.microsoft.com/dotnet/api/system.gc.getgcmemoryinfo) describes the last collection: its generation, whether it compacted, its pause times, and the size of each heap before and after. The program forces a blocking, compacting gen2 collection with `GC.Collect(2, GCCollectionMode.Forced, blocking: true, compacting: true)`, then reads it:

```text
== GC.GetGCMemoryInfo after an induced, blocking, compacting collection
Generation 2, Compacted True, Concurrent False
# Index 11, PauseDurations[0] 0.156 ms, PauseTimePercentage 4.3%
# HeapSizeBytes 275,648, FragmentedBytes 528, TotalCommittedBytes 1,495,040
# TotalAvailableMemoryBytes 68,403,589,120, HighMemoryLoadThresholdBytes 61,563,230,208
#   gen0: before 4,200, after 560
#   gen1: before 416, after 0
#   gen2: before 277,504, after 266,904
#   LOH: before 0, after 0
#   POH: before 8,184, after 8,184
```

This was the program's eleventh collection (`Index`), paused the process for 0.16 ms, and left a 276 KB heap: a small program, even with GA's static tables loaded. `TotalAvailableMemoryBytes` is the physical memory the GC thinks it may use, or the container's limit when there is one; above `HighMemoryLoadThresholdBytes` (90% by default), it collects more aggressively. The same values are exported as [runtime metrics](https://learn.microsoft.com/dotnet/core/diagnostics/built-in-metrics-runtime) such as `dotnet.gc.last_collection.heap.size`, which a monitoring dashboard can follow in production; lesson 12 uses them.

## Short-lived objects are cheap, until they aren't

The generational hypothesis makes short-lived objects cheap: a gen0 collection only looks at live objects, and dead ones cost nothing to skip. The program allocates a million small arrays, each one kept only until the next sixteen replace it ([`Lesson2.cs#L160-L177`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson2.cs#L160-L177)):

```text
== Allocation budget: many short-lived objects, few collections
allocated 32,000,152 bytes for 1,000,000 arrays of 2 ints, 16 still referenced
```

32 MB of garbage caused one gen0 collection on the author's machine, on CI Linux and on CI Windows, and five on CI macOS, whose gen0 budget is 6 MB. None was promoted. The cost comes back when short-lived objects become large (the LOH), or live just long enough to be promoted to gen1 or gen2: a request-scoped cache, a buffer that survives an `await`. The GC then has to copy them, and eventually run a full collection to free them.

## Measuring allocations with BenchmarkDotNet

`GC.GetAllocatedBytesForCurrentThread()` is fine for one call. For code that runs millions of times, BenchmarkDotNet's [`[MemoryDiagnoser]`](https://benchmarkdotnet.org/articles/configs/diagnosers.html) reports, per operation, the bytes allocated and the number of gen0, gen1 and gen2 collections per 1,000 operations. [`Benchmarks/AllocationBenchmarks.cs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Benchmarks/AllocationBenchmarks.cs) measures the allocations of lesson 1, including GA's `PitchClassSetId.ItemsSpan` against a cached array:

```csharp
[MemoryDiagnoser]
public class AllocationBenchmarks
{
    private static readonly PitchClassSetId[] CachedIds = [.. PitchClassSetId.Items];

    [Benchmark(Baseline = true)]
    public int GaPitchClassSetIdItemsSpan() => PitchClassSetId.ItemsSpan.Length;

    [Benchmark]
    public int CachedArraySpan() => new ReadOnlySpan<PitchClassSetId>(CachedIds).Length;
```

```bash
cd code/csharp-advanced
dotnet run -c Release --project Benchmarks -- --filter "*AllocationBenchmarks*"
```

On the author's machine, with nothing else running:

```text
BenchmarkDotNet v0.15.8, Windows 11 (10.0.26200.9445/25H2/2025Update/HudsonValley2)
Intel Core Ultra 9 285K 3.70GHz, 1 CPU, 24 logical and 24 physical cores
.NET SDK 10.0.112
  [Host]     : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
  DefaultJob : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
```

| Method                     | Mean          | Error      | StdDev      | Median        | Ratio | RatioSD | Gen0   | Allocated | Alloc Ratio |
|--------------------------- |--------------:|-----------:|------------:|--------------:|------:|--------:|-------:|----------:|------------:|
| GaPitchClassSetIdItemsSpan | 1,158.0046 ns | 70.7784 ns | 208.6918 ns | 1,173.2269 ns | 1.035 |    0.28 | 0.8698 |   16408 B |       1.000 |
| CachedArraySpan            |     0.0899 ns |  0.0292 ns |   0.0860 ns |     0.0770 ns | 0.000 |    0.00 |      - |         - |       0.000 |
| GaPitchClassItemsSpan      |     0.0543 ns |  0.0258 ns |   0.0761 ns |     0.0130 ns | 0.000 |    0.00 |      - |         - |       0.000 |
| VoicingWithSplit           |    60.0266 ns |  1.2168 ns |   2.3151 ns |    60.1405 ns | 0.054 |    0.01 | 0.0114 |     216 B |       0.013 |
| VoicingWithSpans           |    46.0624 ns |  0.9406 ns |   2.2536 ns |    46.1613 ns | 0.041 |    0.01 |      - |         - |       0.000 |
| Format                     |    19.1902 ns |  0.4152 ns |   0.8759 ns |    19.1456 ns | 0.017 |    0.00 | 0.0030 |      56 B |       0.003 |
| Interpolate                |    12.4961 ns |  0.3073 ns |   0.7479 ns |    12.6991 ns | 0.011 |    0.00 | 0.0017 |      32 B |       0.002 |

The timings come from one machine and one run, and CI never compares them. The allocations don't depend on the machine:

- `GaPitchClassSetIdItemsSpan` allocates **16,408 bytes on every call**, the copy of 4,096 ids that lesson 1 found, and triggers 0.87 gen0 collections per thousand calls: a loop that reads `ItemsSpan` a thousand times causes almost one collection. It also takes about a microsecond, and its timings are spread out (BenchmarkDotNet warns that the distribution is *multimodal*), because some calls pay for a collection and others don't.
- `CachedArraySpan` and GA's own `PitchClass.ItemsSpan`, which returns a cached array, allocate nothing. Their means, a tenth of a nanosecond, are below what BenchmarkDotNet can measure: it reports *ZeroMeasurement*, "indistinguishable from the empty method". The JIT reduced them to reading a length.
- Parsing the voicing `"x 3 2 0 1 0"` with `string.Split` allocates 216 bytes (the array and six strings); the span version allocates nothing and is about a quarter faster.
- `Format` allocates 56 bytes, the box and the string, and `Interpolate` 32, the string alone, as measured in lesson 1. The `Gen0` column turns those bytes into collections: 3 per million calls for `Format`.

Read `Allocated` first: it is exact and repeatable. Read `Mean` with its `Error` and `StdDev`, and with the warnings BenchmarkDotNet prints under the table. Lesson 4 is about getting timings you can trust.

## Exercises

1. What is the smallest `char[]` that goes to the large object heap?
2. [`GC.TryStartNoGCRegion`](https://learn.microsoft.com/dotnet/api/system.gc.trystartnogcregion) asks the GC not to collect while a critical section allocates less than a given amount. Start a region of 1 MB, allocate a thousand arrays of 100 bytes, and report the latency mode and the number of gen0 collections inside the region.
3. `GC.GetGeneration("C major")` returns neither 0, 1 nor 2. What does it return, and why? Try `typeof(PitchClass)` too.

<details>
<summary>Solutions</summary>

1. A `char` takes 2 bytes, and the array's base size is 24 bytes: 24 + 2 × *n* ≥ 85,000 gives *n* = **42,488**. One element less, and the array stays in generation 0.

    ```text
    1. new char[42,487] generation 0, new char[42,488] generation 2
    ```

2. The region starts, the latency mode becomes `NoGCRegion`, and a thousand arrays of 128 bytes each (24 + 100, rounded up) fit in the 1 MB reserved: no collection. `EndNoGCRegion` restores the previous mode. Allocating more than the amount requested ends the region silently, and `EndNoGCRegion` then throws `InvalidOperationException`.

    ```text
    2. TryStartNoGCRegion(1 MB) True, LatencyMode NoGCRegion, gen0 collections for 1,000 arrays 0
       after EndNoGCRegion: LatencyMode Interactive, 16 arrays kept
    ```

3. It returns `int.MaxValue`. Since .NET 8, string literals, `RuntimeType` objects and some other objects the runtime knows will live forever are allocated on a non-GC, *frozen* heap, which the GC never scans ([breaking change note](https://learn.microsoft.com/dotnet/core/compatibility/core-libraries/8.0/getgeneration-return-value)). A string built at run time with the same characters is an ordinary gen0 object. Code that used the generation as an array index breaks on these objects.

    ```text
    3. GC.GetGeneration("C major") 2147483647, of new string('C', 7) 0, of typeof(PitchClass) 2147483647
    ```

</details>

## Key takeaways

- New objects start in generation 0; each collection they survive promotes them, up to generation 2. `GC.Collect()` in application code mostly promotes live objects.
- An array goes to the large object heap when its unrounded size, 24 bytes plus its elements, reaches 85,000 bytes: `byte[84,976]`, `char[42,488]`, `double[10,622]`. The LOH and the pinned object heap are collected with generation 2.
- A finalizer delays freeing by at least one collection. Prefer `IDisposable` and `SafeHandle`.
- Server GC trades memory for throughput: one heap per processor and a gen0 budget of 200 MB, tuned by DATAS since .NET 9. Workstation budgets depend on the machine.
- `GC.GetGCMemoryInfo()` and `GC.GetConfigurationVariables()` show what the GC did and how it's configured, from inside the process.
- `[MemoryDiagnoser]` turns "this allocates" into bytes and collections per operation. GA's `PitchClassSetId.ItemsSpan` shows up there as 16,408 bytes per call and almost one gen0 collection per thousand calls.

## Sources

- Microsoft Learn: [Fundamentals of garbage collection](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals), [The large object heap](https://learn.microsoft.com/dotnet/standard/garbage-collection/large-object-heap), [Workstation and server GC](https://learn.microsoft.com/dotnet/standard/garbage-collection/workstation-server-gc), [DATAS](https://learn.microsoft.com/dotnet/standard/garbage-collection/datas), [GC configuration settings](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector), [Weak references](https://learn.microsoft.com/dotnet/standard/garbage-collection/weak-references), [Finalizers](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/finalizers), [`GC.GetGeneration` might return `Int32.MaxValue`](https://learn.microsoft.com/dotnet/core/compatibility/core-libraries/8.0/getgeneration-return-value), [.NET runtime metrics](https://learn.microsoft.com/dotnet/core/diagnostics/built-in-metrics-runtime).
- dotnet/runtime at `v10.0.12` (commit `4271d88`): [`gchelpers.cpp`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/vm/gchelpers.cpp#L644-L659), [`gc.h`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/gc/gc.h#L105), [`gcconfig.h`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/gc/gcconfig.h#L82).
- BenchmarkDotNet: [Diagnosers](https://benchmarkdotnet.org/articles/configs/diagnosers.html).
