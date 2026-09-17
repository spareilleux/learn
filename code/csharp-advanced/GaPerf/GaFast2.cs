using System.Numerics;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Harmony;
using GA.Domain.Services.Chords;

namespace GaPerf;

// Appendix 2: the changes proposed to Guitar Alchemist's pitch-class code, written against GA's public API so the course
// can compare them with GA's own answers (Appendix2.cs) and time them (GaPerfBenchmarks). The pull requests
// make the same changes inside GA; the proof there compares two builds of GA, this one compares two methods.
//
// Both follow from one fact the whole of Appendix 1 rests on: a pitch-class set is twelve bits, so there are
// 4096 of them. A function of a set alone can be computed once per set, and a function of two sets is a few
// AND gates and a PopCount.
public static class GaFast2
{
    // ---- 1. ChordIntervalPattern.TryMatch, with masks instead of hash sets
    //
    // GA allocates a HashSet for the pattern, and Except, Except and Intersect each build another one inside,
    // to count three things: pattern intervals the voicing lacks, voicing intervals the pattern lacks, and the
    // ones they share. On two 12-bit masks those are three popcounts.
    public static MatchResult? TryMatch(ChordIntervalPattern pattern, IReadOnlyCollection<int> intervalsFromRoot, int maxMissing, int maxExtra)
    {
        if (!TryMask(pattern.Intervals, out var patternMask) || !TryMask(intervalsFromRoot, out var voicingMask))
        {
            // A value outside 0-11 has no bit: GA's set arithmetic is the only faithful answer
            return pattern.TryMatch(intervalsFromRoot, maxMissing, maxExtra);
        }

        return Count(pattern, patternMask, voicingMask, maxMissing, maxExtra);
    }

    static MatchResult? Count(ChordIntervalPattern pattern, int patternMask, int voicingMask, int maxMissing, int maxExtra)
    {
        var missing = BitOperations.PopCount((uint)(patternMask & ~voicingMask));
        var extra = BitOperations.PopCount((uint)(voicingMask & ~patternMask));
        if (missing > maxMissing || extra > maxExtra) return null;

        return new MatchResult(pattern, BitOperations.PopCount((uint)(patternMask & voicingMask)), missing, extra);
    }

    // The loop is written out per type on purpose. A foreach over IEnumerable<int> calls GetEnumerator through
    // the interface: HashSet<int>'s struct enumerator comes back boxed, and an array hands out an enumerator
    // object. Switching on the concrete type first lets the compiler use the array loop or the struct enumerator.
    static bool TryMask(IEnumerable<int> intervals, out int mask)
    {
        mask = 0;
        switch (intervals)
        {
            case int[] array:
                foreach (var interval in array)
                {
                    // One unsigned compare rejects both negative values and values above 11
                    if ((uint)interval > 11) return false;
                    mask |= 1 << interval;
                }
                return true;
            case HashSet<int> set:
                foreach (var interval in set)
                {
                    if ((uint)interval > 11) return false;
                    mask |= 1 << interval;
                }
                return true;
            default:
                return TryMaskThroughInterface(intervals, out mask);
        }
    }

    static bool TryMaskThroughInterface(IEnumerable<int> intervals, out int mask)
    {
        mask = 0;
        foreach (var interval in intervals)
        {
            if ((uint)interval > 11) return false;
            mask |= 1 << interval;
        }
        return true;
    }

    // The first version of this rewrite: the same masks, built through the interface only. Kept for the benchmark.
    public static MatchResult? TryMatchThroughInterface(ChordIntervalPattern pattern, IReadOnlyCollection<int> intervalsFromRoot, int maxMissing, int maxExtra)
    {
        if (!TryMaskThroughInterface(pattern.Intervals, out var patternMask) || !TryMaskThroughInterface(intervalsFromRoot, out var voicingMask))
        {
            return pattern.TryMatch(intervalsFromRoot, maxMissing, maxExtra);
        }

        return Count(pattern, patternMask, voicingMask, maxMissing, maxExtra);
    }

    // ---- 2. CanonicalChordRecognizer.Identify, once per set
    //
    // GA tries every pitch class of the set as a root against every pattern of the catalog, on every call. Its
    // own documentation states the invariant that makes this unnecessary: the name depends on the pitch-class
    // set alone, and the bass only adds a slash suffix. So the search runs once per set, and the bass is
    // applied to the stored answer the way GA applies it: only to a pattern match, only when the bass is not
    // the root.
    static readonly (CanonicalChordResult Result, int? Root)?[] Recognized = new (CanonicalChordResult, int?)?[4096];

    static readonly string[] NoteNames = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];

    public static CanonicalChordResult Identify(PitchClassSet set, PitchClass? bass = null)
    {
        var (result, root) = Recognized[set.Id.Value] ??= Recognize(set);
        if (root is not { } chordRoot || bass is not { } b || b.Value == chordRoot) return result;
        return result with { SlashSuffix = $"/{NoteNames[b.Value]}" };
    }

    static (CanonicalChordResult, int?) Recognize(PitchClassSet set)
    {
        var result = CanonicalChordRecognizer.Identify(set);

        // GA's own call keeps the root private. It is the root name of a pattern match on three or more pitch
        // classes, and nothing else has a slash suffix: sets of 0 to 2 pitch classes, and the Forte fallback
        // (MatchDistance -1), are named without the bass.
        int? root = set.Count >= 3 && result.MatchDistance >= 0 ? Array.IndexOf(NoteNames, result.Root) : null;
        return (result, root);
    }

    // ---- 3. PitchClassSet.IntervalClassVector, once per set
    //
    // The property has no cache: every read builds a normed Cartesian product, as Appendix 1 measured.
    // Appendix 1 replaced the computation with six popcounts; this keeps GA's computation and stores its
    // answer per set, which stays right even if GA changes how it packs the counts. The id is stored plus
    // one, so that 0 can mean "not computed yet": every set of fewer than two pitch classes has the id 0.
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
}
