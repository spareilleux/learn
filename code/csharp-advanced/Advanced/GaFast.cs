using System.Numerics;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Tonal;

namespace Advanced;

// Appendix: faster versions of five members of Guitar Alchemist, written for the benchmarks of
// `Benchmarks/GaBenchmarks.cs` and checked against GA's own answers for all 4096 pitch-class sets
// by `Appendix1.Run`. Each one must return exactly what GA returns, defects included: a rewrite
// that "fixes" an answer on the way past is a different change, and this one is not allowed to.
//
// Everything here rests on one representation. A pitch-class set is a subset of the twelve pitch
// classes, so it is twelve bits: bit p is set when pitch class p is in the set. Three consequences
// run through the whole file.
//   - Transposing by n semitones is rotating the twelve bits by n. Nothing is added or removed,
//     the ring just turns, which is why every member below is written with `Rotr12` or `Rotl12`.
//   - "How many pitch classes satisfy X" is a population count, which is one instruction.
//   - The whole input domain is 4096 values, so any function of a set can be tabulated once at
//     startup and read afterwards — and can be proved equal to GA's on every input, not sampled.
public static class GaFast
{
    // Twelve low bits, one per pitch class. Every rotation ends with this mask, because shifting
    // left pushes pitch classes past bit 11 and they have to come back at the bottom.
    const int Mask12 = 0xFFF;

    // Rotate a 12-bit word right: bit i of the result is bit i + n of the input, wrapping at 12.
    // `value >> n` brings down the pitch classes above n, `value << (12 - n)` brings the ones
    // below n round to the top, and the mask drops what was pushed past bit 11. Read musically:
    // the result is the set transposed down by n semitones.
    static int Rotr12(int value, int n) => ((value >> n) | (value << (12 - n))) & Mask12;

    // ---- 1. IsClusterFree: no three chromatically adjacent pitch classes, cyclically
    //
    // GA loops over the twelve rotations, rebuilding `Value | (Value << 12)` inside the loop, and
    // tests three adjacent bits each time. Bit i of `v & rotr(v, 1) & rotr(v, 2)` is exactly that
    // test for one i, so all twelve run at once and the loop and its branches disappear.
    public static bool IsClusterFree(int set) => (set & Rotr12(set, 1) & Rotr12(set, 2)) == 0;

    // ---- 2. The interval-class vector, as the base-12 id GA stores
    //
    // For interval class ic, the pairs are the pitch classes p with p and p + ic both in the set:
    // `v & rotr(v, ic)`, and `PopCount` counts them. Interval class 6 counts each pair twice,
    // because p and p + 6 are the same pair, so it is halved.
    //
    // The packing is GA's: count(1) is the most significant base-12 digit, count(6) the least.
    // A count of 12 does not fit a base-12 digit and carries into the next one, so the chromatic
    // aggregate's <12 12 12 12 12 6> does not round-trip — a documented defect of
    // `IntervalClassVectorId` that this version reproduces rather than repairs.
    public static int IntervalClassVectorId(int set)
    {
        var value = 0;
        for (var ic = 1; ic <= 6; ic++)
        {
            // `Rotr12(set, ic)` has bit p set when pitch class p + ic is in the set, so the AND
            // has bit p set exactly when p and p + ic are both in it: one bit per pair at that
            // distance, and `PopCount` counts the pairs in one instruction.
            var count = BitOperations.PopCount((uint)(set & Rotr12(set, ic)));

            // A tritone is its own complement: p to p + 6 and p + 6 to p are the same pair, and
            // the AND set both bits, so the count is twice what the vector wants.
            if (ic == 6) count /= 2;

            // GA's packing, kept digit for digit: shift the accumulated digits up by one base-12
            // place and add this count, so count(1) ends up most significant and count(6) least.
            value = value * 12 + count;
        }
        return value;
    }

    // The whole table, built once: 4096 ids, no allocation per call afterwards
    public static readonly int[] IntervalClassVectorIds =
        [.. Enumerable.Range(0, 4096).Select(IntervalClassVectorId)];

    // ---- 3. ClosestDiatonicKey
    //
    // GA builds a Dictionary<Key, …> whose values it never reads, walks `Key.Items` (which
    // rebuilds all 30 key records on every access) twice, and allocates four collections per key
    // to use one of them, `Matches.Count`. All that is needed is, per key, how many of its seven
    // pitch classes the set contains: one AND and one PopCount against a precomputed mask.
    //
    // The order matters. GA orders by match count, then by "is this the expected mode", and takes
    // the first — `OrderByDescending` is stable in LINQ to Objects, so a tie is won by the key
    // that comes first in `Key.Items`. Walking the keys in that same order and replacing only on
    // a strictly better score reproduces it.
    static readonly (Key Key, int Mask, bool IsMinor)[] Keys =
        [.. Key.Items.Select(key => (key, Mask(key), key.KeyMode == KeyMode.Minor))];

    // A key's seven notes, folded into the same twelve-bit shape as the set they are compared with.
    // Built once for all 30 keys in the static field above, so `key.Notes` — which rebuilds its
    // collection on every access in GA — is touched 30 times in the lifetime of the process
    // instead of 30 times per call.
    static int Mask(Key key) => key.Notes.Aggregate(0, (mask, note) => mask | 1 << note.PitchClass.Value);

    public static Key ClosestDiatonicKey(PitchClassSet set)
    {
        // `Id` is a stored property, not a computed one, so this is the set's twelve bits for free
        var mask = set.Id.Value;

        // GA's tie-break: a set whose normal form contains pitch class 3 is expected to be minor.
        // GA writes `IsNormalForm ? this : ToNormalForm()`, and `IsNormalForm` is itself
        // `ToNormalForm().SequenceEqual(this)`, so the normal form is built once or twice per call.
        // Here it is one array load, because the normal form of every set is already tabulated
        // below — the table costs 16 KB of static memory for the whole process.
        var expectMinor = (NormalFormMasks[mask] & (1 << 3)) != 0;

        // `Keys[0]` is only a placeholder: the first candidate always beats a score of -1
        var best = Keys[0];
        var bestScore = -1;
        var bestExpected = false;
        foreach (var candidate in Keys)
        {
            // The AND keeps the key's notes that the set contains, and PopCount is GA's
            // `Matches.Count` — the one number it kept out of four collections per key
            var score = BitOperations.PopCount((uint)(mask & candidate.Mask));
            var expected = candidate.IsMinor == expectMinor;

            // GA's two sort keys, in order, as a single replacement rule: a strictly better score
            // always wins, and on an equal score only moving from unexpected to expected mode
            // wins. Everything else leaves the incumbent in place, which is what makes the loop
            // agree with a stable `OrderByDescending(...).ThenByDescending(...).First()`.
            if (score > bestScore || (score == bestScore && expected && !bestExpected))
            {
                (best, bestScore, bestExpected) = (candidate, score, expected);
            }
        }
        return best.Key;
    }

    // ---- 4. ToNormalForm, the 15.69 KB that was left in ClosestDiatonicKey
    //
    // GA transposes the set once per member so that this member sits on 0, and keeps the
    // transposition whose circular gap sequence has the smallest (max - min), ties broken
    // lexicographically on the gaps. Note that this is not the textbook normal form, which
    // minimises the span from the first pitch class to the last; GA's own remarks say so.
    //
    // The cost is not the algorithm, it is what the algorithm is made of: one
    // `ImmutableSortedSet` per rotation, two `ImmutableArray` of gaps per comparison, a
    // `List<PitchClass>` for the incumbent and a `PitchClassSet` for the answer.
    //
    // A transposition of a 12-bit set is a rotation, and the gaps are read off the bits, so the
    // whole thing fits in two stack buffers. The members are walked in ascending order, as
    // `ImmutableSortedSet` does, and the incumbent is replaced only on a strictly better
    // sequence, so a rotation that ties on everything loses to the earlier one, as in GA.
    public static int NormalFormMask(int set)
    {
        if (set == 0) return 0;

        Span<int> gaps = stackalloc int[12];
        Span<int> bestGaps = stackalloc int[12];
        var count = BitOperations.PopCount((uint)set);
        var best = 0;
        var bestSpan = int.MaxValue;

        // Ascending, because GA enumerates an `ImmutableSortedSet` and its tie-break keeps
        // whichever rotation it saw first. Walking the members in another order would return a
        // different — equally "compact" — rotation for sets like the diminished seventh chord.
        for (var member = 0; member < 12; member++)
        {
            if ((set & (1 << member)) == 0) continue;

            // Transposing so this member lands on 0 is rotating the set down by `member`.
            // This is the whole of GA's `GenerateRotations`, minus an ImmutableSortedSet per turn.
            var rotation = Rotr12(set, member);
            Gaps(rotation, count, gaps);
            var span = Span(gaps, count);

            // GA's two rules, in its order: a smaller span always wins, an equal span goes to the
            // lexicographically smaller gap sequence, and anything else keeps the incumbent
            if (span > bestSpan) continue;
            if (span == bestSpan && !MoreCompact(gaps, bestGaps, count)) continue;

            best = rotation;
            bestSpan = span;
            // Keep this rotation's gaps to compare against, instead of recomputing the
            // incumbent's on every turn as GA's `CalculateIntervals(normalForm)` does
            gaps[..count].CopyTo(bestGaps);
        }

        return best;

        // The gap from each member to the next around the circle. GA's one-note case asks for the
        // distance from the single member to itself, which is 0, not the whole octave.
        static void Gaps(int rotation, int count, Span<int> gaps)
        {
            if (count == 1)
            {
                gaps[0] = 0;
                return;
            }

            // The rotation always has pitch class 0, so start there and measure to each next
            // member in turn; the last gap closes the circle back to 0, which is 12 - the last
            // member. The gaps sum to 12 by construction, which is a useful thing to assert when
            // this is ported.
            var previous = 0;
            var index = 0;
            for (var pitchClass = 1; pitchClass < 12; pitchClass++)
            {
                if ((rotation & (1 << pitchClass)) == 0) continue;
                gaps[index++] = pitchClass - previous;
                previous = pitchClass;
            }
            gaps[index] = 12 - previous;
        }

        static int Span(ReadOnlySpan<int> gaps, int count)
        {
            int min = gaps[0], max = gaps[0];
            for (var i = 1; i < count; i++)
            {
                if (gaps[i] < min) min = gaps[i];
                if (gaps[i] > max) max = gaps[i];
            }
            return max - min;
        }

        // GA's IsMoreCompact: the first gap that differs decides, and equal sequences lose
        static bool MoreCompact(ReadOnlySpan<int> candidate, ReadOnlySpan<int> incumbent, int count)
        {
            for (var i = 0; i < count; i++)
            {
                if (candidate[i] != incumbent[i]) return candidate[i] < incumbent[i];
            }
            return false;
        }
    }

    public static readonly int[] NormalFormMasks =
        [.. Enumerable.Range(0, 4096).Select(NormalFormMask)];

    // ---- 5. PrimeForm
    //
    // GA's is already pure id arithmetic — the smallest of the 12 transpositions and the 12
    // transpositions of the inversion — but `Inverse` runs a 12-iteration loop to mirror the bits,
    // `Transpose` is called 24 times through a property that constructs a value object each time,
    // and `PitchClassSet.PrimeForm` then materialises a `ChromaticNoteSet` and a `PitchClassSet`
    // from the winner. The arithmetic below is the same, and the table removes even that.
    static int Rotl12(int value, int n) => ((value << n) | (value >> (12 - n))) & Mask12;

    // GA's MirrorValue: pitch class i moves to (12 - i) % 12, which is inversion about 0
    static int Mirror(int value)
    {
        var result = 0;
        for (var pitchClass = 0; pitchClass < 12; pitchClass++)
        {
            if ((value & (1 << pitchClass)) != 0) result |= 1 << ((12 - pitchClass) % 12);
        }
        return result;
    }

    public static int PrimeFormId(int set)
    {
        // Every set class contains up to 24 sets — 12 transpositions of the set and 12 of its
        // inversion — and GA names the class by the smallest of their ids. Because the id is the
        // twelve bits read as a number, "smallest" already means "most of the weight at the
        // bottom", so no separate compactness rule is needed here.
        var min = set;
        var inverse = Mirror(set);
        for (var i = 0; i < 12; i++)
        {
            var transposed = Rotl12(set, i);
            if (transposed < min) min = transposed;
            var transposedInverse = Rotl12(inverse, i);
            if (transposedInverse < min) min = transposedInverse;
        }
        return min;
    }

    public static readonly int[] PrimeFormIds =
        [.. Enumerable.Range(0, 4096).Select(PrimeFormId)];
}
