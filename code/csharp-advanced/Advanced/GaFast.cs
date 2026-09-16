using System.Numerics;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Tonal;

namespace Advanced;

// Appendix: faster versions of three members of Guitar Alchemist, written for the benchmarks of
// `Benchmarks/GaBenchmarks.cs` and checked against GA's own answers for all 4096 pitch-class sets
// by `Appendix1.Run`. Each one must return exactly what GA returns, defects included: a rewrite
// that "fixes" an answer on the way past is a different change, and this one is not allowed to.
public static class GaFast
{
    const int Mask12 = 0xFFF;

    // Rotate a 12-bit word right: bit i of the result is bit i + n of the input, wrapping at 12
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
            var count = BitOperations.PopCount((uint)(set & Rotr12(set, ic)));
            if (ic == 6) count /= 2;
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

    static int Mask(Key key) => key.Notes.Aggregate(0, (mask, note) => mask | 1 << note.PitchClass.Value);

    public static Key ClosestDiatonicKey(PitchClassSet set)
    {
        // GA's tie-break: a set whose normal form contains pitch class 3 is expected to be minor
        var normalForm = set.IsNormalForm ? set : set.ToNormalForm();
        var expectMinor = normalForm.Contains(GA.Domain.Core.Primitives.Notes.Note.Chromatic.DSharpOrEFlat.PitchClass);

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
}
