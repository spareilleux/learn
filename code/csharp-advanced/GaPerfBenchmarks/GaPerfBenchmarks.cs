using BenchmarkDotNet.Attributes;
using GA.Domain.Core.Instruments.Fretboard.Voicings.Core;
using GA.Domain.Core.Instruments.Primitives;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Harmony;
using GA.Domain.Services.Chords;
using GA.Domain.Services.Fretboard.Voicings.Generation;
using GaPerf;

namespace GaPerfBenchmarks;

// Appendix 2. Like Appendix 1, every benchmark sweeps a corpus rather than calling once, so the JIT cannot fold
// the work away and every method has real work to do. The corpus is 2,000 guitar voicings spread evenly over
// the 667,125 that GA generates for the default fretboard; the per-voicing figures are the mean divided by 2,000.
public static class Corpus
{
    public static readonly Voicing[] Voicings = Build();

    static Voicing[] Build()
    {
        var all = VoicingGenerator.GenerateAllVoicings(Fretboard.Default, 4, 2, parallel: false);
        var step = all.Count / 2000;
        return [.. Enumerable.Range(0, 2000).Select(i => all[i * step])];
    }

    // Each voicing's pitch-class set and its lowest note, which is what GA's harmonic analysis passes on
    public static readonly (PitchClassSet Set, PitchClass Bass)[] Sets =
        [.. Voicings.Select(v => (new PitchClassSet(v.Notes.Select(n => n.PitchClass)), v.Notes.MinBy(n => n.Value).PitchClass))];

    // Each set's intervals from its lowest pitch class, as the recognizer builds them for one candidate root
    public static readonly HashSet<int>[] RootIntervals =
        [.. Sets.Select(s => s.Set.Select(p => p.Value).ToArray()).Select(pcs => new HashSet<int>(pcs.Select(pc => (pc - pcs[0] + 12) % 12)))];
}

// Every pattern of the catalog against each voicing's intervals: one candidate root's worth of the recognizer
[MemoryDiagnoser]
public class TryMatchBenchmarks
{
    [Benchmark(Baseline = true)]
    public int Ga()
    {
        var matches = 0;
        foreach (var intervals in Corpus.RootIntervals)
            foreach (var pattern in CanonicalChordPatternCatalog.All)
                if (pattern.TryMatch(intervals, 1, 1) is not null) matches++;
        return matches;
    }

    [Benchmark]
    public int MasksThroughInterface()
    {
        var matches = 0;
        foreach (var intervals in Corpus.RootIntervals)
            foreach (var pattern in CanonicalChordPatternCatalog.All)
                if (GaFast2.TryMatchThroughInterface(pattern, intervals, 1, 1) is not null) matches++;
        return matches;
    }

    [Benchmark]
    public int Masks()
    {
        var matches = 0;
        foreach (var intervals in Corpus.RootIntervals)
            foreach (var pattern in CanonicalChordPatternCatalog.All)
                if (GaFast2.TryMatch(pattern, intervals, 1, 1) is not null) matches++;
        return matches;
    }
}

// The recognizer on the corpus, bass included. The fast version has seen these sets before the first
// measured iteration (warm-up runs the same corpus), which is the steady state of an indexing run:
// 667,125 voicings, and at most 4096 different sets among them.
[MemoryDiagnoser]
public class RecognitionBenchmarks
{
    [Benchmark(Baseline = true)]
    public int Ga()
    {
        var total = 0;
        foreach (var (set, bass) in Corpus.Sets) total += CanonicalChordRecognizer.Identify(set, bass).MatchDistance;
        return total;
    }

    [Benchmark]
    public int OncePerSet()
    {
        var total = 0;
        foreach (var (set, bass) in Corpus.Sets) total += GaFast2.Identify(set, bass).MatchDistance;
        return total;
    }
}

[MemoryDiagnoser]
public class IntervalClassVectorReadBenchmarks
{
    [Benchmark(Baseline = true)]
    public int Ga()
    {
        var total = 0;
        foreach (var (set, _) in Corpus.Sets) total += set.IntervalClassVector.Id.Value;
        return total;
    }

    [Benchmark]
    public int OncePerSet()
    {
        var total = 0;
        foreach (var (set, _) in Corpus.Sets) total += GaFast2.IntervalClassVectorId(set).Value;
        return total;
    }
}

// Section 4: the offset arithmetic of one OPTIC-K scan, 313,047 vectors, on the copy of GA's registry in GaPerf
[MemoryDiagnoser]
public class OptickDimensionBenchmarks
{
    const long Entries = 313_047;

    [Benchmark(Baseline = true)]
    public long Computed()
    {
        long total = 0;
        for (long i = 0; i < Entries; i++) total += OptickDimension.VectorComputed(i).Length;
        return total;
    }

    [Benchmark]
    public long Stored()
    {
        long total = 0;
        for (long i = 0; i < Entries; i++) total += OptickDimension.VectorStored(i).Length;
        return total;
    }
}
