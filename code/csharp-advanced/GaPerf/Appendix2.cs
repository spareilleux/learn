using GA.Domain.Core.Instruments.Primitives;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Harmony;
using GA.Domain.Services.Chords;
using GA.Domain.Services.Fretboard.Voicings.Analysis;
using GA.Domain.Services.Fretboard.Voicings.Generation;

namespace GaPerf;

// Appendix 2: what the profiler found on GA's voicing-indexing path, and the proof that the faster versions
// in GaFast2.cs give GA's answers. Every input of each domain is checked, then a real corpus: guitar voicings
// from GA's own generator. The timings are in GaPerfBenchmarks; this is the part CI runs.
public static class Appendix2
{
    static void Title(string title)
    {
        Console.WriteLine();
        Console.WriteLine($"== {title}");
    }

    static void Row(string label, object? first, object? second = null) =>
        Console.WriteLine($"{label,-30} {first,-20} {second}".TrimEnd());

    static PitchClassSet Set(int id) => PitchClassSet.FromId(PitchClassSetId.FromValue(id));

    // Every field of a recognition result, arrays by content, so that no difference can hide in a reference
    static string Fields(CanonicalChordResult r) =>
        $"{r.CanonicalName}|{r.Root}|{r.Quality}|{r.Extension}|{string.Join(",", r.Alterations)}|{r.SlashSuffix}|{r.PatternName}|{r.MatchDistance}|{r.IsNaturallyOccurring}|{r.DisplayName}";

    static int[] Intervals(int mask) => [.. Enumerable.Range(0, 12).Where(i => (mask & (1 << i)) != 0)];

    public static void Run()
    {
        Title("Exhaustive check");
        Row("member", "agree", "inputs");

        // 1. Every pattern, every interval set, as an array, a HashSet and a List, every tolerance from 0 to 2
        long matchAgree = 0, matchTotal = 0;
        foreach (var pattern in CanonicalChordPatternCatalog.All)
        {
            for (var mask = 0; mask < 4096; mask++)
            {
                var array = Intervals(mask);
                IReadOnlyCollection<int>[] shapes = [array, new HashSet<int>(array), new List<int>(array)];
                for (var maxMissing = 0; maxMissing <= 2; maxMissing++)
                for (var maxExtra = 0; maxExtra <= 2; maxExtra++)
                {
                    foreach (var shape in shapes)
                    {
                        matchTotal++;
                        var ga = pattern.TryMatch(shape, maxMissing, maxExtra);
                        if (Equals(ga, GaFast2.TryMatch(pattern, shape, maxMissing, maxExtra)) &&
                            Equals(ga, GaFast2.TryMatchThroughInterface(pattern, shape, maxMissing, maxExtra))) matchAgree++;
                    }
                }
            }
        }
        Row("ChordIntervalPattern.TryMatch", $"{matchAgree:N0}/{matchTotal:N0}", $"{CanonicalChordPatternCatalog.All.Count} patterns x 4096 sets x 9 tolerances x 3 shapes");

        // 2. Every set, with no bass and with each of the twelve, twice: the second pass reads the stored answers
        int identifyAgree = 0, identifyTotal = 0;
        for (var pass = 0; pass < 2; pass++)
        for (var id = 0; id < 4096; id++)
        {
            var set = Set(id);
            identifyTotal++;
            if (Fields(CanonicalChordRecognizer.Identify(set)) == Fields(GaFast2.Identify(set))) identifyAgree++;
            for (var bass = 0; bass < 12; bass++)
            {
                identifyTotal++;
                var b = PitchClass.FromValue(bass);
                if (Fields(CanonicalChordRecognizer.Identify(set, b)) == Fields(GaFast2.Identify(set, b))) identifyAgree++;
            }
        }
        Row("CanonicalChordRecognizer", $"{identifyAgree:N0}/{identifyTotal:N0}", "4096 sets x 13 basses x 2 passes");

        var icvAgree = 0;
        for (var id = 0; id < 4096; id++)
        {
            if (Set(id).IntervalClassVector.Id == GaFast2.IntervalClassVectorId(Set(id))) icvAgree++;
        }
        Row("IntervalClassVector.Id", $"{icvAgree:N0}/4,096", "4096 sets");

        // 3. A real corpus: every 16th guitar voicing of GA's generator, named by GA and by the fast recognizer
        Title("Real corpus: guitar voicings from GA's generator");
        var voicings = VoicingGenerator.GenerateAllVoicings(Fretboard.Default, 4, 2, parallel: false);
        var sample = voicings.Where((_, i) => i % 16 == 0).ToList();
        int nameAgree = 0;
        var distinctSets = new HashSet<int>();
        foreach (var voicing in sample)
        {
            var ga = VoicingHarmonicAnalyzer.Analyze(voicing).ChordId;
            var set = new PitchClassSet(voicing.Notes.Select(n => n.PitchClass));
            distinctSets.Add(set.Id.Value);
            var bass = voicing.Notes.MinBy(n => n.Value).PitchClass;
            var fast = GaFast2.Identify(set, bass);
            if (ga.ChordName == fast.DisplayName && ga.CanonicalName == fast.CanonicalName && ga.SlashSuffix == fast.SlashSuffix) nameAgree++;
        }
        Row("voicings generated", $"{voicings.Count:N0}");
        Row("voicings checked", $"{sample.Count:N0}", "every 16th");
        Row("distinct pitch-class sets", $"{distinctSets.Count:N0}", "of 4096");
        Row("chord name, canonical, slash", $"{nameAgree:N0}/{sample.Count:N0}");

        // What makes the cache worth it: how often the search would be repeated
        Title("How often the same set comes back");
        Row("recognitions per distinct set", $"{(double)sample.Count / distinctSets.Count:N1}", "in the sample");
        Row("in the whole corpus", $"{(double)voicings.Count / DistinctSets(voicings):N1}");

        Title("A few voicings, as GA names them");
        foreach (var diagram in new[] { "x-3-2-0-1-0", "3-2-0-0-0-3", "x-x-0-2-3-2", "0-2-2-1-0-0", "x-5-4-5-3-x" })
        {
            var voicing = voicings.First(v => v.Diagram == ToGaOrder(diagram));
            Row(diagram, VoicingHarmonicAnalyzer.Analyze(voicing).ChordId.ChordName);
        }

        RunDimension();
    }

    // Section 4: the OPTIC-K reader's dimension, on a copy of GA's registry. The value is the proof; the bytes
    // depend on the runtime (a JIT that could stack-allocate the iterator would print 0), so they are "# " lines.
    public static void RunDimension()
    {
        Title("OPTIC-K reader: the dimension, read once");
        const long entries = 313_047;
        long agree = 0;
        for (long i = 0; i < entries; i++)
            if (OptickDimension.VectorComputed(i) == OptickDimension.VectorStored(i)) agree++;
        Row("compact dimension", OptickDimension.CompactDimension, "sum of the similarity partitions");
        Row("GetVector offset and length", $"{agree:N0}/{entries:N0}", "one per indexed voicing");

        var before = GC.GetAllocatedBytesForCurrentThread();
        for (long i = 0; i < entries; i++) _ = OptickDimension.VectorComputed(i);
        var computed = GC.GetAllocatedBytesForCurrentThread() - before;
        before = GC.GetAllocatedBytesForCurrentThread();
        for (long i = 0; i < entries; i++) _ = OptickDimension.VectorStored(i);
        var stored = GC.GetAllocatedBytesForCurrentThread() - before;
        Console.WriteLine($"# one scan of {entries:N0} vectors allocates {computed:N0} B computed, {stored:N0} B stored");
    }

    static int DistinctSets(IEnumerable<GA.Domain.Core.Instruments.Fretboard.Voicings.Core.Voicing> voicings) =>
        voicings.Select(v => new PitchClassSet(v.Notes.Select(n => n.PitchClass)).Id.Value).Distinct().Count();

    // GA's diagrams list the strings from the high E down to the low E; guitar charts read the other way
    static string ToGaOrder(string lowToHigh) => string.Join("-", lowToHigh.Split('-').Reverse());
}
