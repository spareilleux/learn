---
title: "Appendix 1: five optimisations, proved then measured"
description: Five members of Guitar Alchemist rewritten with rotations, popcounts and lookup tables — an exhaustive equivalence check over all 4096 pitch-class sets first, BenchmarkDotNet second, one documented defect the fast version is not allowed to fix, and a benchmark that had to be thrown away because it was measuring the JIT rather than the code.
sidebar:
  label: "Appendix 1: optimisations, proved"
  order: 90
---

A benchmark on its own proves nothing. "A thousand times faster" is a claim about two programs, and it is only interesting if they are the *same* program — the easiest way to win a benchmark is to quietly stop doing some of the work.

This appendix takes five members of [Guitar Alchemist](https://github.com/GuitarAlchemist/ga), rewrites each one, and does the proof before the measurement. All five take a **pitch-class set**: a subset of the twelve pitch classes, which is a 12-bit number, which means the whole input domain is 4096 values. There is nothing to sample and nothing to argue about. The program asserts that the rewrite returns what GA returns for **every** input, and CI runs it on Linux, Windows and macOS on every push. Only then are the timings worth reading.

The measurement turned out to need the same scepticism as the code. The first version of the benchmarks called each member once and reported that the fast `IsClusterFree` ran in 0.0107 ns — a twenty-fifth of a cycle, which is not a speed but a symptom. That story is in [the measurements](#the-measurements) at the end, and it is the reason every number below is a sweep of the whole domain.

GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6).

## Running it

```bash
bash code/csharp-advanced/check.sh                                   # every lesson, compared with expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- a1  # the proof only, after check.sh
cd code/csharp-advanced
dotnet run -c Release --project Benchmarks -- --filter "*NormalFormBenchmarks*"
```

The rewrites are in [`Advanced/GaFast.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/GaFast.cs), the proof in [`Advanced/Appendix1.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/Appendix1.cs), the timings in [`Benchmarks/GaBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Benchmarks/GaBenchmarks.cs).

| | Member | The move | What the proof has to work for |
|---|---|---|---|
| 1 | `PitchClassSetId.IsClusterFree` | hoist a loop-invariant, then delete the loop | nothing — it is a clean win |
| 2 | `PitchClassSet.IntervalClassVector` | count pairs with `PopCount`, then precompute all 4096 | a documented arithmetic defect that must be **kept** |
| 3 | `PitchClassSet.ClosestDiatonicKey` | delete a dictionary nobody reads | a stable-sort tie-break that must be reproduced exactly |
| 4 | `PitchClassSet.ToNormalForm` | rotate bits instead of building sorted sets | a compactness rule that is not the textbook one |
| 5 | `PitchClassSetId.PrimeForm` | the same arithmetic, then a table | nothing — it was already bit arithmetic |

Everything rests on one representation, which is worth stating once. Bit *p* of the number is set when pitch class *p* is in the set. Transposing by *n* semitones is rotating those twelve bits by *n*: nothing is added or removed, the ring turns. "How many pitch classes satisfy X" is a population count, which is one instruction. And the domain is small enough that any function of a set can be tabulated at startup.

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

| Method | All 4096 sets | Per set | Ratio |
|---|---|---|---|
| `Ga` | 9.582 µs | 2.34 ns | 1.00 |
| `Fast` | 2.378 µs | 0.58 ns | 0.25 |

**Four times, not thirty.** This is the member where the honest measurement is least flattering, and it is worth dwelling on: the same pair of methods, benchmarked one call at a time, reported 3.25 ns against 0.0107 ns and a ratio of 0.003. Neither version allocates. GA's loop exits early on a cluster — 2,597 of the 4096 sets have one — so on average it runs far fewer than twelve iterations, and the branch predictor learns it.

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
        // Bit p of the AND is set when p and p + ic are both in the set: one bit per pair
        var count = BitOperations.PopCount((uint)(set & Rotr12(set, ic)));

        // A tritone is its own complement, so the AND counted every such pair from both ends
        if (ic == 6) count /= 2;

        // GA's packing: shift the digits up one base-12 place and add this count
        value = value * 12 + count;
    }
    return value;
}
```

And since the domain is 4096 values, the whole thing can be done once, at startup:

```csharp
public static readonly int[] IntervalClassVectorIds =
    [.. Enumerable.Range(0, 4096).Select(IntervalClassVectorId)];
```

| Method | All 4096 sets | Per set | Allocated, per set | Ratio |
|---|---|---|---|---|
| `Ga` | 18.747 ms | 4,577 ns | 13,513 B | 1.000 |
| `Computed` | 15.480 µs | 3.78 ns | — | 0.001 |
| `Table` | 828.4 ns | 0.20 ns | — | 0.00004 |

**Reading this property for all 4096 sets allocates 55 MB.** A thousand times faster computed on each call, twenty-two thousand from the table, and the allocation goes to zero. That last number is the one that matters in a service: `PitchClassSet`'s own static constructor builds a lookup over all 4096 sets keyed by this property, and `SetClass.ToString()` calls it, so every log line naming a set class paid for it.

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
    // `Id` is a stored property, not a computed one, so this is the set's twelve bits for free
    var mask = set.Id.Value;

    // GA's tie-break: a set whose normal form contains pitch class 3 is expected to be minor.
    // Here it is one array load, because section 4 tabulated the normal form of every set.
    var expectMinor = (NormalFormMasks[mask] & (1 << 3)) != 0;

    var best = Keys[0];
    var bestScore = -1;
    var bestExpected = false;
    foreach (var candidate in Keys)
    {
        // The AND keeps the key's notes the set contains, and PopCount is GA's `Matches.Count`
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

| Method | All 4096 sets | Per set | Allocated, per set | Ratio |
|---|---|---|---|---|
| `Ga` | 279.681 ms | 68.28 µs | 175,650 B | 1.000 |
| `Fast` | 173.2 µs | 42.3 ns | — | 0.001 |

**175 kilobytes to read one property**, and 719 MB to read it for every set in the domain. Sixteen hundred times faster, and nothing allocated.

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

## 4. The normal form, which was hiding inside the last one

The paragraph above used `NormalFormMasks`, and that table is the reason the fast `ClosestDiatonicKey` allocates nothing. Before it existed, the rewrite still called `set.ToNormalForm()`, and that single call was the whole of its remaining 16 KB.

GA's `ToNormalForm` transposes the set once per member, so that member sitting on 0, and keeps the transposition whose circular gap sequence has the smallest *largest gap minus smallest gap*, ties broken lexicographically on the gaps. That is worth reading twice, because it is **not** the textbook normal form, which minimises the span from the first pitch class to the last; GA's own remarks say so. The rewrite has to reproduce GA's rule, not the one in the books.

The cost is not the rule, it is what the rule is made of — one `ImmutableSortedSet` per rotation, two `ImmutableArray` of gaps per comparison, a `List<PitchClass>` for the incumbent and a `PitchClassSet` for the answer. A transposition is a rotation and the gaps are read off the bits, so the whole thing fits in two stack buffers:

```csharp
public static int NormalFormMask(int set)
{
    if (set == 0) return 0;

    Span<int> gaps = stackalloc int[12];
    Span<int> bestGaps = stackalloc int[12];
    var count = BitOperations.PopCount((uint)set);
    var best = 0;
    var bestSpan = int.MaxValue;

    // Ascending, because GA enumerates an ImmutableSortedSet and keeps the rotation it saw first
    for (var member = 0; member < 12; member++)
    {
        if ((set & (1 << member)) == 0) continue;

        // Transposing so this member lands on 0 is rotating the set down by `member`
        var rotation = Rotr12(set, member);
        Gaps(rotation, count, gaps);
        var span = Span(gaps, count);

        // A smaller span always wins; an equal span goes to the smaller gap sequence
        if (span > bestSpan) continue;
        if (span == bestSpan && !MoreCompact(gaps, bestGaps, count)) continue;

        best = rotation;
        bestSpan = span;
        gaps[..count].CopyTo(bestGaps);
    }

    return best;
}
```

One detail is worth keeping even though it changes nothing. GA measures each gap as `(pitchClasses[(i + 1) % n] - pitchClasses[i])`, so for a one-note set the only gap is the distance from the member to itself — **0**, not the twelve semitones a "circular gap" would suggest. The rewrite mirrors that, and the exhaustive check is what proves the choice is free: a one-note set has exactly one rotation, so no comparison is ever made and either reading returns the same answer for all twelve of them. That is the kind of thing worth knowing rather than assuming, and the only way to know it is to run every input.

| Method | All 4096 sets | Per set | Allocated, per set | Ratio |
|---|---|---|---|---|
| `Ga` | 11.085 ms | 2,706 ns | 6,657 B | 1.000 |
| `Computed` | 1.172 ms | 286 ns | — | 0.106 |
| `Table` | 834.5 ns | 0.20 ns | — | 0.00008 |

Note the gap between `Computed` and `Table` here. The rewrite is only 9.5 times faster than GA's, because unlike the interval-class vector it still does real work per call — up to twelve rotations and a lexicographic comparison. That is what makes the table worth its 16 KB: the cost is not in the allocations alone.

```text
== Normal form and prime form, on the same sets
set                          GA's normal form         prime form
major scale                  0 1 3 5 6 8 T            0 1 3 5 6 8 T
C major triad                0 3 8                    0 3 7
whole tone                   0 2 4 6 8 T              0 2 4 6 8 T
chromatic aggregate          0 1 2 3 4 5 6 7 8 9 T E  0 1 2 3 4 5 6 7 8 9 T E
```

The second row is GA's rule showing its face: the C major triad's normal form is `0 3 8`, while its prime form is `0 3 7`. The gaps of `0 3 8` are 3, 5, 4 — a span of 2 — against 4, 3, 5 for `0 4 7`, also a span of 2, and `3 5 4` wins the lexicographic tie-break against `4 3 5`. A textbook normal form would have answered `0 4 7`.

## 5. PrimeForm, which was already right

GA's `PitchClassSetId.PrimeForm` is the one member here that needed no rethinking. It is already pure id arithmetic — the smallest of the twelve transpositions and the twelve transpositions of the inversion — and it allocates nothing:

```csharp
var min = Value;
var inverse = Inverse;
for (var i = 0; i < 12; i++)
{
    var t = Transpose(i).Value;
    if (t < min) min = t;

    var ti = inverse.Transpose(i).Value;
    if (ti < min) min = ti;
}
```

What it pays for is the packaging. `Inverse` is a property that runs a twelve-iteration loop to mirror the bits; `Transpose` is called 24 times, each call constructing a `PitchClassSetId` through a constructor that range-checks its argument. Writing the same arithmetic on plain `int` is 1.8 times faster, and the table 415 times:

| Method | All 4096 sets | Per set | Ratio |
|---|---|---|---|
| `Ga` | 347.4 µs | 84.8 ns | 1.000 |
| `Computed` | 193.9 µs | 47.3 ns | 0.562 |
| `Table` | 836.9 ns | 0.20 ns | 0.002 |

A factor of 1.8 for rewriting a method that was already correct is the honest ceiling on "micro-optimise the arithmetic", and it is worth putting next to the 1,600× of section 3. The large wins in this appendix did not come from clever bit tricks. They came from deleting work that was never needed: a dictionary nobody read, a Cartesian product built to count six numbers, a sorted set per rotation.

## What the exhaustive check prints

```text
== Exhaustive check: all 4096 twelve-bit pitch-class sets
member                       agree              verdict
IsClusterFree                4096/4096          identical
IntervalClassVector.Id       4096/4096          identical
ClosestDiatonicKey           4096/4096          identical
ToNormalForm                 4096/4096          identical
PrimeForm                    4096/4096          identical
sets with no chromatic cluster: 1499 of 4096
```

Five lines, and they are the reason the timings above are allowed to be quoted. `ClosestDiatonicKey` is compared on the key's *string* form rather than by record equality, so that a change in how `Key` compares itself cannot hide a difference.

## The measurements

[BenchmarkDotNet](https://benchmarkdotnet.org/) v0.15.8, one benchmark class at a time on an otherwise idle machine:

```text
BenchmarkDotNet v0.15.8, Windows 11 (10.0.26200.9445/25H2/2025Update/HudsonValley2)
Intel Core Ultra 9 285K 3.70GHz, 1 CPU, 24 logical and 24 physical cores
.NET SDK 10.0.112
  [Host]     : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
  DefaultJob : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
```

### The benchmark that had to be thrown away

The first version of these benchmarks did the obvious thing: one call per `[Benchmark]` method, on the major scale. It reported this for `IsClusterFree`:

```text
| Method | Mean      | Ratio |
| Ga     | 3.2472 ns |  1.000 |
| Fast   | 0.0107 ns |  0.003 |
```

0.0107 ns on a 3.7 GHz processor is a twenty-fifth of a cycle. No method runs in a twenty-fifth of a cycle. The argument was a `const`, so the JIT folded the whole call into a literal, and what was being measured was the folding.

A `static readonly` field would not have helped either: the JIT promotes those to constants once tiered compilation has settled. Making it a mutable `static int` removed the folding and still produced 0.0474 ns with a **median of 0.0000 ns**: below the resolution of the technique, because BenchmarkDotNet subtracts the cost of an empty method and there was nothing left.

So every benchmark here sweeps the whole domain instead, accumulating a value the JIT cannot prove dead:

```csharp
[Benchmark]
public int Fast()
{
    var count = 0;
    for (var id = 0; id < 4096; id++)
    {
        if (GaFast.IsClusterFree(id)) count++;
    }
    return count;
}
```

The loop counter is the input, so nothing can be folded; every method has milliseconds or microseconds of real work; and the per-set columns above are the mean divided by 4096. The three `Table` rows landing on 828.4 ns, 834.5 ns and 836.9 ns — the same number three times, for three different tables — is the floor of the technique: a bounds-checked array load and a loop iteration, about 0.20 ns, included in every figure in this appendix.

This is not a footnote. The discarded benchmark would have published "thirty-one times faster" for a member that is four times faster, and it would have looked more impressive than everything the appendix actually found.

### Allocations

These are not statistical at all:

```text
# GA   IntervalClassVector.Id.Value    16,432 bytes
# fast IntervalClassVectorIds[id]           0 bytes
# GA   IsClusterFree                        0 bytes
# fast IsClusterFree                        0 bytes
# GA   ClosestDiatonicKey             179,848 bytes
# fast ClosestDiatonicKey                   0 bytes
# GA   ToNormalForm                     8,000 bytes
# fast NormalFormMask                       0 bytes
# GA   PrimeForm                        1,704 bytes
# fast PrimeFormIds[id]                     0 bytes
```

They come from [`GC.GetAllocatedBytesForCurrentThread`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread) around a single call, after a warm-up call has run the static constructors — the technique from [lesson 1](../01-memory-values-and-spans/). They are machine-dependent enough to be printed with a `# ` prefix and left out of the comparison, and stable enough to be worth printing. They are higher than the per-set figures in the tables, which are `[MemoryDiagnoser]`'s averages over the whole sweep with its own overhead subtracted; a single cold-ish call costs a little more than the average of 4096.

CI runs every benchmark class with `--job Dry`, which checks that they still run and measures nothing, because timings from a shared runner are noise.

## Key takeaways

- The input domain of a 12-bit set is 4096 values. When the domain is that small, "I tested it" should mean *all of it*, and that test belongs in CI next to the benchmark.
- A rewrite that returns a different answer is not a faster version of anything. GA's base-12 carry is a real defect and the fast version reproduces it; so is a one-note set whose "circular gap" is zero.
- **Benchmark your benchmark.** A number below one cycle is not a result, it is a bug in the measurement: a `const` or `static readonly` argument gets folded, and BenchmarkDotNet's overhead subtraction takes the rest. Sweep a domain, accumulate a result, and divide.
- The big wins came from deleting work, not from bit tricks: a dictionary whose values are never read, a Cartesian product built to count six numbers, a sorted set per rotation. Rewriting arithmetic that was already correct bought 1.8×.
- A property with no cache is a method with a misleading name. `IntervalClassVector` and `Key.Items` both rebuild everything on each access, and both are read in loops elsewhere in GA.

## Sources

- BenchmarkDotNet: [how it works](https://benchmarkdotnet.org/articles/guides/how-it-works.html), [good practices](https://benchmarkdotnet.org/articles/guides/good-practices.html).
- Microsoft Learn: [`BitOperations.PopCount`](https://learn.microsoft.com/dotnet/api/system.numerics.bitoperations.popcount), [`GC.GetAllocatedBytesForCurrentThread`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread), [`Enumerable.OrderByDescending`](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.orderbydescending), [`BigInteger`](https://learn.microsoft.com/dotnet/api/system.numerics.biginteger), [`stackalloc`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/stackalloc).
- Guitar Alchemist at `a826864`: [`PitchClassSetId.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L42-L57) and its [`PrimeForm`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L133-L156), [`PitchClassSet.ToNormalForm`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L412-L475) and [`FindClosestDiatonicKey2`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L597-L658), [`AtonalExtensions.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/AtonalExtensions.cs#L28-L35), [`VariationsWithRepetitions.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Combinatorics/VariationsWithRepetitions.cs#L55-L73), [`Key.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L49-L50).
- The course code: [`GaFast.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/GaFast.cs), [`Appendix1.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/Appendix1.cs), [`GaBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Benchmarks/GaBenchmarks.cs), [`expected/a1.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/a1.txt).
- The same code read as music, not as performance: [Music theory for Guitar Alchemist](../../music-theory-ga/), in particular [lesson 4](../../music-theory-ga/04-set-classes/), [lesson 7](../../music-theory-ga/07-cadences-and-progressions/) and [its appendix C](../../music-theory-ga/appendix-ga-findings/).
