---
title: "Appendix 1: three optimisations, proved then measured"
description: Three members of Guitar Alchemist rewritten with rotations, popcounts and a lookup table — an exhaustive equivalence check over all 4096 pitch-class sets first, BenchmarkDotNet second, and one documented defect the fast version is not allowed to fix.
sidebar:
  label: "Appendix 1: optimisations, proved"
  order: 90
---

A benchmark on its own proves nothing. "Two thousand times faster" is a claim about two programs, and it is only interesting if they are the *same* program — the easiest way to win a benchmark is to quietly stop doing some of the work.

This appendix takes three members of [Guitar Alchemist](https://github.com/GuitarAlchemist/ga), rewrites each one, and does the proof before the measurement. All three take a **pitch-class set**: a subset of the twelve pitch classes, which is a 12-bit number, which means the whole input domain is 4096 values. There is nothing to sample and nothing to argue about. The program asserts that the rewrite returns what GA returns for **every** input, and CI runs it on Linux, Windows and macOS on every push. Only then are the timings worth reading.

GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6).

## Running it

```bash
bash code/csharp-advanced/check.sh                                   # every lesson, compared with expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- a1  # the proof only, after check.sh
cd code/csharp-advanced
dotnet run -c Release --project Benchmarks -- --filter "*IntervalClassVectorBenchmarks*"
```

The rewrites are in [`Advanced/GaFast.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/GaFast.cs), the proof in [`Advanced/Appendix1.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/Appendix1.cs), the timings in [`Benchmarks/GaBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Benchmarks/GaBenchmarks.cs).

| | Member | The move | What the proof has to work for |
|---|---|---|---|
| 1 | `PitchClassSetId.IsClusterFree` | hoist a loop-invariant, then delete the loop | nothing — it is a clean win |
| 2 | `PitchClassSet.IntervalClassVector` | count pairs with `PopCount`, then precompute all 4096 | a documented arithmetic defect that must be **kept** |
| 3 | `PitchClassSet.ClosestDiatonicKey` | delete a dictionary nobody reads | a stable-sort tie-break that must be reproduced exactly |

## 1. A loop that does the same thing twelve times

A set is *cluster-free* when it contains no three chromatically adjacent pitch classes, counted around the circle. GA's version:

```csharp
public bool IsClusterFree
{
    get
    {
        for (var i = 0; i < 12; i++)
        {
            var extended = Value | (Value << 12);
            if (((extended >> i) & 7) == 7)
            {
                return false;
            }
        }

        return true;
    }
}
```

Two things are wrong with it, and only one of them is the obvious one.

`extended` does not depend on `i`. It is rebuilt on every iteration — a shift and an OR, twelve times, for a value that never changes. The JIT may well hoist it out; the point is that the source asks for it.

The more interesting problem is the loop itself. `((extended >> i) & 7) == 7` asks "are bits *i*, *i+1* and *i+2* all set?", and the answer for all twelve *i* at once is one expression:

```csharp
const int Mask12 = 0xFFF;

// Rotate a 12-bit word right: bit i of the result is bit i + n of the input, wrapping at 12
static int Rotr12(int value, int n) => ((value >> n) | (value << (12 - n))) & Mask12;

public static bool IsClusterFree(int set) => (set & Rotr12(set, 1) & Rotr12(set, 2)) == 0;
```

`Rotr12(v, 1)` puts bit *i + 1* where bit *i* was, and `Rotr12(v, 2)` puts bit *i + 2* there. Bit *i* of the AND is therefore exactly GA's test for that *i*, and the set is cluster-free when no bit survives. Two rotates, two ANDs, one compare against zero, no branch.

| Method | Mean | Ratio |
|---|---|---|
| `Ga` | 3.5344 ns | 1.00 |
| `Fast` | 0.1131 ns | 0.03 |

Thirty-one times faster, and 0.11 ns is below the cost of a single branch mispredict — the method has effectively dissolved into its caller. Neither version allocates.

## 2. Counting pairs, and a defect that has to survive

An **interval-class vector** counts, for each interval class 1 to 6, how many unordered pairs of the set are that far apart. It is the fingerprint of [lesson 4 of the music theory course](../../music-theory-ga/04-set-classes/), and in GA it is a property with no cache:

```csharp
public IntervalClassVector IntervalClassVector => _pitchClassesSet.ToIntervalClassVector();
```

`ToIntervalClassVector` builds a generic *normed Cartesian product*, and constructing that, before a single pair has been looked at, does this:

```csharp
Elements = [.. elements];
Base = new(Elements.Count);
Count = BigInteger.Pow(Base, length);
IndexFormat = Count > 0 ? $"D{(int)Math.Floor(BigInteger.Log10(Count) + 1)}" : "D1";

_indexByElement = Elements.Select((o, i) => (o, i)).ToImmutableDictionary(t => t.o, t => t.i);
_elementByIndex = Elements.Select((o, i) => (o, i)).ToImmutableDictionary(t => t.i, t => t.o);
```

A `BigInteger.Pow`, a `BigInteger.Log10`, a `string.Format` and two `ImmutableDictionary` instances — to count six small numbers. Then n² pairs are enumerated, filtered through delegates, grouped into an `ILookup` and folded into an `ImmutableSortedDictionary`; and reading the resulting vector's `Vector` property rebuilds *another* one, because it too is computed on each access.

The six counts are three operations each. For interval class `ic`, the pairs are the pitch classes *p* where *p* and *p + ic* are both present — `v & Rotr12(v, ic)` — and [`BitOperations.PopCount`](https://learn.microsoft.com/dotnet/api/system.numerics.bitoperations.popcount) counts them:

```csharp
public static int IntervalClassVectorId(int set)
{
    var value = 0;
    for (var ic = 1; ic <= 6; ic++)
    {
        var count = BitOperations.PopCount((uint)(set & Rotr12(set, ic)));
        if (ic == 6) count /= 2;
        value = value * 12 + count;
    }
    return value;
}
```

Interval class 6 is halved because *p* and *p + 6* name the same pair from both ends. And since the domain is 4096 values, the whole thing can be done once, at startup:

```csharp
public static readonly int[] IntervalClassVectorIds =
    [.. Enumerable.Range(0, 4096).Select(IntervalClassVectorId)];
```

| Method | Mean | Allocated | Ratio |
|---|---|---|---|
| `Ga` | 5,518.86 ns | 16,304 B | 1.00 |
| `Computed` | 2.62 ns | — | 0.0005 |
| `Table` | 0.0799 ns | — | 0.00001 |

Two thousand times faster computed on each call, sixty-nine thousand times from the table, and sixteen kilobytes of allocation per property read becomes zero. That last number is the one that matters in a service: `PitchClassSet`'s own static constructor builds a lookup over all 4096 sets keyed by this property, and `SetClass.ToString()` calls it, so every log line naming a set class paid 16 KB.

### The part that makes this a proof

`IntervalClassVectorId` packs the six counts as base-12 digits, count 1 most significant. A base-12 digit holds 0 to 11. The chromatic aggregate — all twelve pitch classes — has five counts of exactly **12**, which do not fit, and carry:

```text
== The defect the fast version has to keep, not fix
chromatic aggregate          id                 decoded
GA                           3257430            <1 1 1 1 0 6>
the fast version             3257430            <1 1 1 1 0 6>
```

The true vector is `<12 12 12 12 12 6>`. GA documents the packing in the type's own comments, together with an earlier bug where a hardcoded base-10 literal decoded to the wrong vector once the encoding moved to base 12.

So the rewrite has a choice, and only one of the two options is an optimisation. Packing the counts *correctly* would change the id of set 4095 — and `ProgrammaticForteCatalog` orders each cardinality by this id to assign Forte ordinals, so Forte numbers across the catalogue would move. That is a behaviour change wearing a performance change's clothes. The rewrite reproduces the carry, the exhaustive check confirms it, and the catalogue is checked separately:

```text
== Forte numbering is unchanged
set classes                  224                224 vector ids identical
distinct Forte numbers       224
```

Fixing the packing is a good idea. It is a *different* change, with its own migration, and it does not belong in a commit whose message says "faster".

## 3. A dictionary nobody reads

`ClosestDiatonicKey` answers "which of the 30 keys shares the most notes with this set". Its implementation opens like this:

```csharp
var dict = new Dictionary<Key, IReadOnlyCollection<PitchClass>>();
foreach (var key in Key.Items)
{
    var accidentedKeyNotes = key.Notes.Where(note => note.Accidental != null);
    var accidentedPitchClasses = accidentedKeyNotes.Select(note => note.PitchClass).ToImmutableArray();

    dict.Add(key, accidentedPitchClasses);
}
```

The dictionary is passed to `IdentifyClosestKey`, which destructures it as `foreach (var (key, _) in items)`. **The values are never read.** Thirty `ImmutableArray` instances are built, each from a filter and a projection over a freshly rebuilt note collection, and thrown away.

Underneath that, `Key.Items` is a property, not a field: every access concatenates the 15 major and 15 minor keys and materialises a new `ImmutableList`, and the method touches it twice. `key.Notes` rebuilds its collection on every access too. `IdentifyClosestKey` then allocates, per key, a `List`, an `ImmutableList`, two printable wrappers and a sorted `ImmutableList` — and uses one number out of all of it, `Matches.Count`.

The whole computation is, per key, one AND and one `PopCount` against a precomputed 12-bit mask:

```csharp
static readonly (Key Key, int Mask, bool IsMinor)[] Keys =
    [.. Key.Items.Select(key => (key, Mask(key), key.KeyMode == KeyMode.Minor))];

static int Mask(Key key) => key.Notes.Aggregate(0, (mask, note) => mask | 1 << note.PitchClass.Value);

public static Key ClosestDiatonicKey(PitchClassSet set)
{
    // GA's tie-break: a set whose normal form contains pitch class 3 is expected to be minor
    var normalForm = set.IsNormalForm ? set : set.ToNormalForm();
    var expectMinor = normalForm.Contains(Note.Chromatic.DSharpOrEFlat.PitchClass);

    var mask = set.Aggregate(0, (bits, pitchClass) => bits | 1 << pitchClass.Value);
    var best = Keys[0];
    var bestScore = -1;
    var bestExpected = false;
    foreach (var candidate in Keys)
    {
        var score = BitOperations.PopCount((uint)(mask & candidate.Mask));
        var expected = candidate.IsMinor == expectMinor;
        if (score > bestScore || (score == bestScore && expected && !bestExpected))
        {
            (best, bestScore, bestExpected) = (candidate, score, expected);
        }
    }
    return best.Key;
}
```

| Method | Mean | Allocated | Ratio |
|---|---|---|---|
| `Ga` | 68.211 µs | 175.66 KB | 1.00 |
| `Fast` | 6.195 µs | 15.69 KB | 0.09 |

**175 kilobytes to read one property.** Eleven times faster and eleven times lighter — and the remaining 15.69 KB is not the key search at all: it is `ToNormalForm()`, called to decide whether to expect a major or a minor answer, and untouched here. It is the next candidate.

### The tie-break is the whole difficulty

GA picks the answer like this:

```csharp
list.OrderByDescending(tuple => tuple.Matches.Count)
    .ThenByDescending(tuple => tuple.Key.KeyMode == expectedKeyMode)
    .First()
```

[LINQ to Objects sorts stably](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.orderbydescending), so when several keys tie on both criteria the winner is whichever came first in `Key.Items` — the 15 major keys, then the 15 minor ones. A loop that replaced the incumbent on `>=` instead of `>` would return a *different key* for many sets: the same count, a different name. The rewrite walks the keys in `Key.Items` order and replaces only on a strictly better score, and the 4096-case check is what says that is right.

It is worth seeing what the answers actually are:

```text
== A few sets, so the tables above are readable
set                          interval-class vector closest key, cluster-free
major scale                  2741: <2 5 4 3 6 1> Key of Am, True
C major triad                145: <0 0 1 1 1 0> Key of Dm, True
whole tone                   1365: <0 6 0 6 0 3> Key of Cb, True
chromatic aggregate          4095: <1 1 1 1 0 6> Key of Abm, False
```

A C major scale's closest diatonic key is A minor, and a C major triad's is D minor. Both are wrong, for a reason [lesson 7 of the music theory course](../../music-theory-ga/07-cadences-and-progressions/#finding-the-key-of-a-progression) takes apart: a pitch-class set has no tonic. `C F G C` and `Am F C G` are the same set, so no function of the set alone can choose between two relative keys, and GA's tie-break tries anyway by reading a mode off a normal form, which cannot encode one. [Appendix C of that course](../../music-theory-ga/appendix-ga-findings/) files it as defect 19.

The optimisation reproduces all of it, because that is what an optimisation is.

## What the exhaustive check prints

```text
== Exhaustive check: all 4096 twelve-bit pitch-class sets
member                       agree              verdict
IsClusterFree                4096/4096          identical
IntervalClassVector.Id       4096/4096          identical
ClosestDiatonicKey           4096/4096          identical
sets with no chromatic cluster: 1499 of 4096
```

Three lines, and they are the reason the timings above are allowed to be quoted. `ClosestDiatonicKey` is compared on the key's *string* form rather than by record equality, so that a change in how `Key` compares itself cannot hide a difference.

## The measurements

[BenchmarkDotNet](https://benchmarkdotnet.org/) v0.15.8, one benchmark class at a time on an otherwise idle machine:

```text
BenchmarkDotNet v0.15.8, Windows 11 (10.0.26200.9445/25H2/2025Update/HudsonValley2)
Intel Core Ultra 9 285K 3.70GHz, 1 CPU, 24 logical and 24 physical cores
.NET SDK 10.0.112
  [Host]     : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
  DefaultJob : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
```

Each `[Benchmark]` method does exactly one call, on the major scale (2741) — seven notes, the common case in GA. CI runs the same classes with `--job Dry`, which checks that they still run and measures nothing, because timings from a shared runner are noise. Absolute times on your machine will differ; the ratios are the claim.

The allocation figures are not statistical at all:

```text
# GA   IntervalClassVector.Id.Value    16,432 bytes
# fast IntervalClassVectorIds[id]           0 bytes
# GA   IsClusterFree                        0 bytes
# fast IsClusterFree                        0 bytes
# GA   ClosestDiatonicKey             179,848 bytes
# fast ClosestDiatonicKey              16,064 bytes
```

They come from [`GC.GetAllocatedBytesForCurrentThread`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread) around a single call, after a warm-up call has run the static constructors — the technique from [lesson 1](../01-memory-values-and-spans/). They are machine-dependent enough to be printed with a `# ` prefix and left out of the comparison, and stable enough to be worth printing. They are also slightly higher than `[MemoryDiagnoser]`'s, which subtracts its own overhead.

## Key takeaways

- The input domain of a 12-bit set is 4096 values. When the domain is that small, "I tested it" should mean *all of it*, and that test belongs in CI next to the benchmark.
- A rewrite that returns a different answer is not a faster version of anything. GA's base-12 carry is a real defect, and the fast version reproduces it exactly; fixing it is a separate change with a separate blast radius.
- Stable sorts are load-bearing. `OrderByDescending(…).ThenByDescending(…).First()` hides a tie-break in the *input order*, and a hand-written loop has to be told about it.
- A property with no cache is a method with a misleading name. `IntervalClassVector` and `Key.Items` both rebuild everything on each access, and both are read in loops elsewhere in GA.
- The headline number here is not a time, it is 175 KB of allocation to read one property — and no profiler was needed to find it, only reading a method that fills a dictionary and then ignores its values.

## Sources

- BenchmarkDotNet: [how it works](https://benchmarkdotnet.org/articles/guides/how-it-works.html), [good practices](https://benchmarkdotnet.org/articles/guides/good-practices.html).
- Microsoft Learn: [`BitOperations.PopCount`](https://learn.microsoft.com/dotnet/api/system.numerics.bitoperations.popcount), [`GC.GetAllocatedBytesForCurrentThread`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread), [`Enumerable.OrderByDescending`](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.orderbydescending), [`BigInteger`](https://learn.microsoft.com/dotnet/api/system.numerics.biginteger).
- Guitar Alchemist at `a826864`: [`PitchClassSetId.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L42-L57), [`PitchClassSet.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L597-L658), [`AtonalExtensions.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/AtonalExtensions.cs#L28-L35), [`VariationsWithRepetitions.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Combinatorics/VariationsWithRepetitions.cs#L55-L73), [`IntervalClassVector.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/IntervalClassVector.cs), [`Key.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L49-L50).
- The course code: [`GaFast.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/GaFast.cs), [`Appendix1.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/Appendix1.cs), [`GaBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Benchmarks/GaBenchmarks.cs), [`expected/a1.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/a1.txt).
- The same code read as music, not as performance: [Music theory for Guitar Alchemist](../../music-theory-ga/), in particular [lesson 4](../../music-theory-ga/04-set-classes/), [lesson 7](../../music-theory-ga/07-cadences-and-progressions/) and [its appendix C](../../music-theory-ga/appendix-ga-findings/).
