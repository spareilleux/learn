---
title: "Appendix 2: profiling GA, then proving and measuring"
description: Appendix 1 chose its members by reading the code; this one starts from a profiler on Guitar Alchemist's real indexing pipeline. Chord recognition with 12-bit masks and computed once per pitch-class set, an interval-class vector cached instead of rebuilt, and a LINQ query that allocated 38 MB per OPTIC-K search — each proved byte for byte against GA's own output on every input and a corpus of 667,125 voicings, measured with BenchmarkDotNet, and sent upstream as a pull request, with what was measured and dropped.
sidebar:
  label: "Appendix 2: GA, profiled"
  order: 91
---

[Appendix 1](../appendix-benchmarks/) picked five members of [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) by reading them, and proved each rewrite on the 4096 pitch-class sets before timing it. The method was right, but the choice of members was a guess. A member that allocates 175 KB is only a problem if something calls it often.

This appendix makes no guess about *where* to look. It runs GA's own pipeline — generating every guitar voicing, analysing it, turning it into a document and an embedding, and searching the OPTIC-K index — and lets a profiler say where the time goes. The same rules then apply to what the profiler finds:

1. **Proof first.** Each change is checked against GA's own answers: on every input when the domain is small enough, and always on a real corpus. The check compares two *builds of GA*, before and after, byte for byte.
2. **Then the measurement.** [BenchmarkDotNet](https://benchmarkdotnet.org/) with `[MemoryDiagnoser]`, before and after, on the same machine.
3. **Then upstream.** One GA branch and one pull request per topic, with the numbers and the proof in the description.

GA links point to commit [`66bdd04`](https://github.com/GuitarAlchemist/ga/tree/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e), the head of `main` when the measurements were made. The pull requests are [#695](https://github.com/GuitarAlchemist/ga/pull/695) (chord recognition), [#694](https://github.com/GuitarAlchemist/ga/pull/694) (interval-class vector) and [#693](https://github.com/GuitarAlchemist/ga/pull/693) (OPTIC-K search).

## Running it

```bash
bash code/csharp-advanced/check.sh                                     # every lesson and both appendices, compared with expected/
dotnet run --project code/csharp-advanced/GaPerf -c Release -- a2      # this appendix's proof only, after check.sh
cd code/csharp-advanced
dotnet run -c Release --project GaPerfBenchmarks -- --filter "*RecognitionBenchmarks*"
```

Appendix 2 builds against its own GA commit, which `fetch-ga.sh` fetches into `.ga-perf/` next to Appendix 1's `.ga/`: the two appendices read different commits and neither moves the other. The rewrites are in [`GaPerf/GaFast2.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/GaPerf/GaFast2.cs) and [`GaPerf/OptickDimension.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/GaPerf/OptickDimension.cs), the proof in [`GaPerf/Appendix2.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/GaPerf/Appendix2.cs), the timings in [`GaPerfBenchmarks/GaPerfBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/GaPerfBenchmarks/GaPerfBenchmarks.cs).

## Where the time goes

A small probe program called each stage of the pipeline on 20,000 guitar voicings and printed wall time and [`GC.GetTotalAllocatedBytes`](https://learn.microsoft.com/dotnet/api/system.gc.gettotalallocatedbytes) around it:

| Stage | Per voicing | Allocated per voicing |
|---|---|---|
| Generate all 667,125 guitar voicings, parallel | 1,419 ms in total | 364 MB in total |
| Generate all 667,125 guitar voicings, sequential | 711 ms in total | 305 MB in total |
| `VoicingAnalyzer.Analyze` | 173 µs | 347 KB |
| `VoicingHarmonicAnalyzer.Analyze` | 95 µs | 321 KB |
| `VoicingDocumentFactory.FromAnalysis` | 68 µs | 113 KB |
| `MusicalEmbeddingGenerator.GenerateEmbeddingAsync` | 93 µs | 125 KB |
| `KeyIdentificationService.Identify`, per progression | 25 µs | 16 KB |
| `OptickSearchStrategy.SemanticSearchAsync`, per query | 6.95 ms | **38 MB** |

Two lines stand out before any profiler: an analysis that allocates a third of a megabyte per voicing, and a search that allocates 38 MB per query.

[`dotnet-trace`](https://learn.microsoft.com/dotnet/core/diagnostics/dotnet-trace) with the `dotnet-sampled-thread-time` profile, reported with `dotnet-trace report … topN --inclusive`, then split the analysis. Of the main thread's samples:

- **about 52%** were in `CanonicalChordRecognizer.IdentifyChordSet`, and most of that in `HashSet<int>` construction inside `ChordIntervalPattern.TryMatch`;
- about 13.5% in `PitchClassSet.GetCompatibleKeys`;
- about 11% in `NormedPairExtensions.ByNormCounts`, which is the interval-class vector of Appendix 1's section 2, again.

The search had no hot frame at all: `TensorPrimitives.Dot` over a memory-mapped file allocates nothing. That is the part the next sections explain.

## 1. Three hash sets to count three numbers

`CanonicalChordRecognizer` names a chord by trying every pitch class of the set as a root, and every pattern of the catalog against the intervals from that root. At this commit the catalog has 62 patterns, so a four-note voicing makes 248 calls to [`TryMatch`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Domain.Core/Theory/Harmony/ChordIntervalPattern.cs#L37-L54):

```csharp
var patternSet = new HashSet<int>(Intervals);
var voicingSet = intervalsFromRoot is HashSet<int> hs ? hs : [.. intervalsFromRoot];

var missing = patternSet.Except(voicingSet).Count();
var extra = voicingSet.Except(patternSet).Count();

if (missing > maxMissing || extra > maxExtra)
    return null;

return new MatchResult(this, Overlap: patternSet.Intersect(voicingSet).Count(), Missing: missing, Extra: extra);
```

One `HashSet` for the pattern, and one more inside each of [`Except`](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.except), `Except` and [`Intersect`](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.intersect), which build a set of their second argument to test membership against. Four sets per call, to count three numbers.

Intervals from a root are pitch classes, 0 to 11. So both sides are 12-bit sets, and the three counts are what Appendix 1 used everywhere: an AND, an AND-NOT and a [`PopCount`](https://learn.microsoft.com/dotnet/api/system.numerics.bitoperations.popcount).

```csharp
var missing = BitOperations.PopCount((uint)(patternMask & ~voicingMask));
var extra = BitOperations.PopCount((uint)(voicingMask & ~patternMask));
if (missing > maxMissing || extra > maxExtra) return null;

return new MatchResult(pattern, BitOperations.PopCount((uint)(patternMask & voicingMask)), missing, extra);
```

The method takes an `IReadOnlyCollection<int>`, which can hold anything: a 12, a −1, a duplicate. A value outside 0 to 11 has no bit, so the rewrite doesn't try to find one. It falls back to GA's set code for that call, which makes it right by construction on inputs no caller sends today.

### The first version still allocated

The first mask version built each mask with a `foreach` over `IEnumerable<int>`. It was ten times faster, and it still allocated 8.6 MB for 2,000 voicings:

| Method (2,000 voicings × 62 patterns) | Mean | Per voicing | Allocated | Ratio |
|---|---|---|---|---|
| `Ga` | 40.110 ms | 20.1 µs | 147.2 MB | 1.00 |
| `MasksThroughInterface` | 3.869 ms | 1.93 µs | 8.6 MB | 0.10 |
| `Masks` | 1.427 ms | 0.71 µs | 62.5 KB | 0.04 |

A `foreach` over an interface calls `GetEnumerator()` through the interface. `HashSet<int>`'s enumerator is a struct, which comes back boxed, and an array hands out a small enumerator object: 72 bytes per call for the two masks. [Lesson 4](../04-measured-performance/) showed dynamic PGO removing such an allocation in a tight loop. It didn't here. This call site sees two types, an array and a `HashSet`, and whether that is the reason is *to verify*. `Masks` switches on the concrete type first, so the compiler uses the array loop and the struct enumerator:

```csharp
switch (intervals)
{
    case int[] array:
        foreach (var interval in array) { if ((uint)interval > 11) return false; mask |= 1 << interval; }
        return true;
    case HashSet<int> set:
        foreach (var interval in set) { if ((uint)interval > 11) return false; mask |= 1 << interval; }
        return true;
    default:
        return TryMaskThroughInterface(intervals, out mask);
}
```

Another 2.7 times, and the allocation is gone. The 62.5 KB left are 32 bytes per voicing, most likely the benchmark's own `foreach` over the catalog, which is typed as an `IReadOnlyList`. `(uint)interval > 11` is one compare for both ends of the range, because a negative `int` becomes a very large `uint`.

## 2. The same search, 266 times

Making `TryMatch` 28 times faster still leaves 248 calls per four-note voicing. The better question is whether they are needed at all.

The recognizer's own documentation answers it. Recognition "depends only on pitch-class content and the optional bass hint for slash notation", and the ranking comment calls this *invariant #33*: the bass must not influence which pattern wins. So the result for a set, without the bass, is a function of 12 bits. The proof program counted how often that function is called with the same argument while analysing the corpus:

```text
== How often the same set comes back
recognitions per distinct set  16.8                 in the sample
in the whole corpus            265.9
```

667,125 guitar voicings use about 2,500 distinct pitch-class sets. **Each set's pattern search was repeated 266 times on average.** The fix is to remember the answer:

```csharp
static readonly (CanonicalChordResult Result, int? Root)?[] Recognized = new (CanonicalChordResult, int?)?[4096];

public static CanonicalChordResult Identify(PitchClassSet set, PitchClass? bass = null)
{
    var (result, root) = Recognized[set.Id.Value] ??= Recognize(set);
    if (root is not { } chordRoot || bass is not { } b || b.Value == chordRoot) return result;
    return result with { SlashSuffix = $"/{NoteNames[b.Value]}" };
}
```

An array of 4096 is the whole cache: no dictionary, no hashing, no eviction, because the key space is the index space. Two threads that race on one slot compute equal immutable results, and the last write wins harmlessly.

### The bass is where it could go wrong

The cache is only correct if the bass is applied *exactly* as GA applies it, and GA doesn't apply it everywhere:

- sets of 0, 1 and 2 pitch classes have their own code paths, which ignore the bass;
- a set that matches no pattern falls back to its Forte number, which ignores the bass too;
- a pattern match adds `/X` only when the bass differs from the chord's root.

So the stored entry keeps the root *only* on the pattern-match path, and `null` everywhere else. The course version can't see GA's private root. It rebuilds it from the public result, and the proof is what says that rebuilding is right: 4096 sets × no bass and 12 basses × two passes (the second one reads the cache), every field compared:

```text
CanonicalChordRecognizer       106,496/106,496      4096 sets x 13 basses x 2 passes
```

| Method (2,000 voicings) | Mean | Per voicing | Allocated | Ratio |
|---|---|---|---|---|
| `Ga` | 198,958 µs | 99.5 µs | 677.1 MB | 1.000 |
| `OncePerSet` | 26.22 µs | 13 ns | 158.8 KB | 0.0001 |

**7,600 times faster, and 347 KB per voicing no longer allocated.** The 79 bytes per voicing that remain are the `with` copy for voicings whose bass is not the root. As in Appendix 1, the measurement is a steady state: the warm-up iterations have already seen the corpus's sets. The first call for each set costs what it always did, and there are at most 4096 first calls in a process.

This is the change that matters, and it is not a clever one. The mask rewrite of section 1 is the kind of thing a performance appendix is expected to contain. The cache is what the profile asked for.

## 3. The interval-class vector, which Appendix 1 already rewrote

Appendix 1's section 2 replaced `IntervalClassVector`'s computation with six popcounts, and kept an arithmetic defect on purpose: the base-12 packing carries for the chromatic aggregate. The profile shows the property is still on the hot path in GA: `VoicingHarmonicAnalyzer` reads it once per voicing, and `VoicingAnalyzer` up to four times.

For the pull request, a different rewrite was the safer one: **keep GA's computation, and compute it once per set.** A table of popcounts would have to reproduce the packing, carry included, and would quietly diverge if GA ever changed it. A cache of GA's own answer can't diverge, because on a miss it calls the unchanged code:

```csharp
static readonly int[] IntervalClassVectorIdPlusOne = new int[4096];

public static IntervalClassVectorId IntervalClassVectorId(PitchClassSet set)
{
    var stored = IntervalClassVectorIdPlusOne[set.Id.Value];
    if (stored == 0)
    {
        stored = set.IntervalClassVector.Id.Value + 1;
        IntervalClassVectorIdPlusOne[set.Id.Value] = stored;
    }
    return new(stored - 1);
}
```

The `+ 1` is how an `int` array says "not computed yet" without a second array: every set with fewer than two pitch classes has the id 0, which would otherwise be indistinguishable from an empty slot.

| Method (2,000 voicings) | Mean | Per voicing | Allocated | Ratio |
|---|---|---|---|---|
| `Ga` | 6,323.165 µs | 3.16 µs | 16.2 MB | 1.000 |
| `OncePerSet` | 1.147 µs | 0.57 ns | — | 0.0002 |

In GA the cache sits inside `ToIntervalClassVector<T>`. It applies only when the collection is the `ImmutableSortedSet<PitchClass>` with the default comparer that `PitchClassSet` passes, and every other shape of collection takes the general path. On its own, that pull request barely moves voicing analysis: the benchmark said 9%, which is within this machine's noise, because chord recognition still dominates. After section 2, the interval-class vector is the largest cost left in harmonic analysis, and the two together are what the end-to-end numbers below show.

## 4. A LINQ query, 626,000 times per search

The search allocated 38 MB per query, and the scan allocates nothing. The first suspect was [`Parallel.For`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.parallel.for): [`OptickSearchStrategy`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L185-L220) runs one iteration per indexed voicing, with a heap per worker. So an experiment ran the same scan sequentially:

```text
identical top-10 lists: 64/64
current x200                                      1,337.3 ms      7,646.8 MB
chunked x200                                      1,236.8 ms      7,651.3 MB
sequential x50                                    1,670.5 ms      1,910.7 MB
```

38 MB per query in all three. The parallelism was innocent: the bytes came from inside the loop. The loop body reads one vector, and [`GetVector`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Search/OptickIndexReader.cs#L179-L183) is two lines:

```csharp
public static int Dimension => EmbeddingSchema.CompactDimension;

public ReadOnlySpan<float> GetVector(long i)
{
    if ((ulong)i >= (ulong)_count) throw new ArgumentOutOfRangeException(nameof(i));
    return new ReadOnlySpan<float>(_vectors + i * Dimension, Dimension);
}
```

And [`CompactDimension`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L147-L148) is not a constant:

```csharp
public static int CompactDimension =>
    SimilarityPartitions.Sum(p => p.Dim);

public static IEnumerable<EmbeddingPartition> SimilarityPartitions =>
    Partitions.Where(p => p.Role == PartitionRole.Similarity);
```

Each read filters the 11-entry partition registry and sums it, allocating LINQ iterators on the way. `GetVector` reads `Dimension` twice, and the scan calls `GetVector` once for each of the 313,047 indexed voicings: **626,094 LINQ queries per search, to compute 124 each time.**

Nothing about the property's name says so. `Dimension` looks like a field and `=>` looks like a getter. The design is reasonable, since the registry is the single source of truth for the layout. The cost only exists because a hot loop reads it. The fix keeps the property and reads the registry once:

```csharp
public static int Dimension { get; } = EmbeddingSchema.CompactDimension;
```

The course can't build GA's search project, which pulls in Semantic Kernel, ONNX Runtime and ILGPU. So `OptickDimension.cs` copies the registry and the two properties from GA's commit, and measures the offset arithmetic of one scan:

| Method (313,047 vectors) | Mean | Per vector | Allocated | Ratio |
|---|---|---|---|---|
| `Computed` | 25,849.42 µs | 82.6 ns | 40,070,016 B | 1.000 |
| `Stored` | 67.50 µs | 0.22 ns | — | 0.003 |

Exactly 128 bytes per vector, 64 per read of the property. Once the JIT has read a `static readonly` value it can use it as a constant, so `Stored` is the multiplication and nothing else.

In GA itself, with the real 313,047-entry index, BenchmarkDotNet measured before and after:

| Benchmark | Before | After |
|---|---|---|
| `SemanticSearchAsync`, top 10 | 4.986 ms, 38.25 MB | 2.162 ms, 41,306 B |
| `GetVector` for every entry | 31.955 ms, 38.21 MB | 1.689 ms, 0 B |

### What was dropped

Once `GetVector` was fixed, the partitioning experiment ran again:

```text
identical top-10 lists: 64/64
current x200                                        827.2 ms          3.1 MB
chunked x200                                      1,009.9 ms          7.2 MB
sequential x50                                      857.6 ms          0.0 MB
```

Range partitioning with [`Partitioner.Create`](https://learn.microsoft.com/dotnet/api/system.collections.concurrent.partitioner.create) was *slower* than GA's per-element loop, so `SearchInternal` is unchanged. It would have been easy to ship the partitioning change on the strength of the first experiment, where it looked 8% faster. It was noise on top of 38 MB of garbage.

## What the proofs print

```text
== Exhaustive check
member                         agree                inputs
ChordIntervalPattern.TryMatch  6,856,704/6,856,704  62 patterns x 4096 sets x 9 tolerances x 3 shapes
CanonicalChordRecognizer       106,496/106,496      4096 sets x 13 basses x 2 passes
IntervalClassVector.Id         4,096/4,096          4096 sets

== Real corpus: guitar voicings from GA's generator
voicings generated             667,125
voicings checked               41,696               every 16th
distinct pitch-class sets      2,482                of 4096
chord name, canonical, slash   41,696/41,696

== A few voicings, as GA names them
x-3-2-0-1-0                    C
3-2-0-0-0-3                    G
x-x-0-2-3-2                    D
0-2-2-1-0-0                    E
x-5-4-5-3-x                    D7(shell)

== OPTIC-K reader: the dimension, read once
compact dimension              124                  sum of the similarity partitions
GetVector offset and length    313,047/313,047      one per indexed voicing
```

That is the course's proof, which compares two methods in one process, and CI runs it on three OSes. The pull requests use a stronger one. The *same* dump program is built twice, once against GA's `main` and once against the branch, and writes every answer of the path to a file. Then `cmp` compares the files:

| Dump | Contents | Lines | Result |
|---|---|---|---|
| `trymatch` | every pattern × 4096 interval sets × 9 tolerances, as array and `HashSet`, plus out-of-range and duplicate inputs | 258,048 | identical |
| `identify` | 4096 sets × 13 basses × 2 passes | 106,496 | identical |
| `icv` | 4096 sets × 2 passes: id, text, counts, and three derived properties | 8,192 | identical |
| `voicings` | all 667,125 guitar voicings through `VoicingAnalyzer.Analyze`: chord fields, consonance, drop voicing, tags, mode | 667,125 | identical |
| search | 2,048 top-10 searches on the real index | 2,048 | identical |

A comparison of two builds catches what a comparison of two methods can't: a change in a caller, in a type the rewrite forgot, or in the order the analyzer reads things.

## End to end

GA's `FretboardVoicingsCLI --export-embeddings` builds the OPTIC-K index: 688,351 voicings for guitar, bass and ukulele, 313,047 after deduplication, each analysed and embedded. It ran four times, alternating GA's `main` and a build with the chord and interval-class-vector changes:

| Round | GA `main` | Both changes |
|---|---|---|
| 1 | 142.8 s | 62.9 s |
| 2 | 95.0 s | 38.3 s |

The four index files are identical entry by entry. The analysis benchmarks in GA, on the same 2,000 voicings:

| Benchmark | GA `main` | Chord change | Both changes |
|---|---|---|---|
| `VoicingHarmonicAnalyzer.Analyze` | 213.19 ms, 700.8 MB | 8.48 ms, 23.6 MB | 2.47 ms, 7.3 MB |
| `VoicingAnalyzer.Analyze` | 234.34 ms, 759.3 MB | 30.23 ms, 82.1 MB | 8.94 ms, 22.1 MB |

`VoicingAnalyzer.Analyze` goes from 117 µs and 380 KB per voicing to 4.5 µs and 11 KB. The export, which also embeds and writes, is 2.3 to 2.5 times faster.

## The measurements, and how much to trust them

```text
BenchmarkDotNet v0.15.8, Windows 11 (10.0.26200.9457/25H2/2025Update/HudsonValley2)
Intel Core Ultra 9 285K 3.70GHz, 1 CPU, 24 logical and 24 physical cores
.NET SDK 10.0.112
  [Host]     : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
```

Appendix 1 was measured on an idle machine. This one wasn't, and the difference is worth stating:

- **The machine was shared.** The course's benchmarks ran on a desktop that other sessions were using, with Microsoft Defender, Docker and WSL busy. Every series ran under a machine-wide lock that kept other builds and GPU jobs out, and the free RAM and the busiest processes were logged at the start of each series: 13.6 to 18.5 GB free, 32% to 100% total CPU.
- **Allocations are exact; times are indicative.** The course's tables above use the default job. GA's before-and-after tables use `ShortRun` (three iterations), whose error bars reached 10 to 50% of the mean on the busiest runs.
- **The export varied by a factor of 1.5 between rounds** for the same binary, 142.8 s then 95.0 s. The ratio within a round held, and that is why the rounds alternate.
- **Every speed-up claimed is far outside the noise.** None is below 2.3 times, and the largest are in the thousands. A 10% claim on this machine would not have been publishable, which is why section 3 doesn't make one.

## Measured, and not changed

- **`VoicingGenerator`'s parallel path** generated the 667,125 voicings in 1,419 ms and 364 MB, and the sequential path in 711 ms and 305 MB: parallel is twice as slow. That file belongs to another set of GA fixes in progress, so the finding went to that work instead of into a pull request here.
- **`PitchClassSet.GetCompatibleKeys`**, 13.5% of the analysis profile, and the `Key` members it calls. These files also have fixes in progress elsewhere; the same once-per-set cache applies, and was written up as a proposal.
- **`KeyIdentificationService.Identify`**: 25 µs per progression, called once per request, not per voicing.
- **The value-object allocations of [lesson 5](../05-generics-in-depth/)** (`Items`, `Values`, `ValueObjectCache<T>`): real, measured, and absent from this profile. None of them is on the indexing path.
- **Range partitioning of the search**: slower, see section 4.
- **The index export is not always reproducible.** The four alternating exports above are identical, and so are two earlier exports made back to back with the two binaries. But the first export of the evening, from GA's `main`, differs from all of them in 266 of 313,047 entries when entries are keyed by instrument and diagram, and the three groups of files differ in size by a few dozen bytes. Every comparison in this appendix is between exports of the same group, so the conclusions stand. The cause is *to verify*.
