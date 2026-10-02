namespace GaAi;

using System.Reflection;
using System.Text.Json;
using GA.Business.ML.Search;
using GaMcpServer.Tools;
using static Report;

// Lesson 19's questions to GaMcpServer's ga_voice_leading_pair tool, CompositionTools.GaVoiceLeadingPair.
// The file is compiled twice, like the tool: into GaAi against the pinned GA, and into GaMain
// against GA's main, where the tool is the same but the search it calls changed.
public static class VoiceLeadingPairProbe
{
    // VoiceLeadingSkill's ten example prompts (lesson 18), as chord pairs
    public static readonly (string From, string To)[] Pairs =
    [
        ("C", "F"), ("C", "Am"), ("G7", "Cmaj7"), ("Dm7", "G7"), ("C", "G"),
        ("Em", "A7"), ("Fmaj7", "Bm7b5"), ("D", "A"), ("C7", "F"), ("G7", "C"),
    ];

    // Each chord as a textbook spells it: root and degrees
    static readonly Dictionary<string, (string Root, string Degrees)> Textbook = new()
    {
        ["C"] = ("C", "1 3 5"), ["F"] = ("F", "1 3 5"), ["G"] = ("G", "1 3 5"), ["D"] = ("D", "1 3 5"),
        ["A"] = ("A", "1 3 5"), ["Am"] = ("A", "1 b3 5"), ["Em"] = ("E", "1 b3 5"),
        ["G7"] = ("G", "1 3 5 b7"), ["C7"] = ("C", "1 3 5 b7"), ["A7"] = ("A", "1 3 5 b7"),
        ["Cmaj7"] = ("C", "1 3 5 7"), ["Fmaj7"] = ("F", "1 3 5 7"), ["Dm7"] = ("D", "1 b3 5 b7"),
        ["Bm7b5"] = ("B", "1 b3 b5 b7"),
    };

    public static HashSet<int> Chord(string symbol) =>
        ChordVoicingsProbe.Chord(Textbook[symbol].Root, Textbook[symbol].Degrees);

    // ---- The tool, its search and its distance ----

    public sealed record Voicing(string Diagram, string Name, int[] Midi)
    {
        public HashSet<int> Pcs => [.. Midi.Select(m => m % 12)];
        public string Chart => Shape.FromHighFirst(Diagram).Chart;
    }

    public sealed record Pair(double Distance, Voicing From, Voicing To);

    public static (List<Pair> Pairs, string? Error) Ask(string from, string to, int limit = 5, string? instrument = null, int candidates = 15)
    {
        var json = CompositionTools.GaVoiceLeadingPair(from, to, limit, instrument, candidates).GetAwaiter().GetResult();
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;
        if (root.TryGetProperty("error", out var error)) return ([], error.GetString());
        static Voicing V(JsonElement v) => new(v.GetProperty("diagram").GetString()!, v.GetProperty("chordName").GetString()!,
            [.. v.GetProperty("midiNotes").EnumerateArray().Select(m => m.GetInt32())]);
        return ([.. root.GetProperty("pairs").EnumerateArray()
            .Select(p => new Pair(p.GetProperty("distance").GetDouble(), V(p.GetProperty("from")), V(p.GetProperty("to"))))], null);
    }

    static readonly MethodInfo SearchMethod = typeof(CompositionTools)
        .GetMethod("SearchByChordAsync", BindingFlags.NonPublic | BindingFlags.Static)!;
    static readonly MethodInfo DistanceMethod = typeof(CompositionTools)
        .GetMethod("VoiceLeadingDistance", BindingFlags.NonPublic | BindingFlags.Static)!;

    // The candidates the tool pairs for one chord: its private SearchByChordAsync, by reflection
    public static List<Voicing> Candidates(string symbol, int limit = 15, string? instrument = null)
    {
        var task = (Task)SearchMethod.Invoke(null, [symbol, limit, instrument, CancellationToken.None])!;
        task.GetAwaiter().GetResult();
        var outcome = task.GetType().GetProperty("Result")!.GetValue(task)!;
        var hits = (List<VoicingSearchResult>)outcome.GetType().GetProperty("Hits")!.GetValue(outcome)!;
        return [.. hits.Select(h => new Voicing(h.Document.Diagram, h.Document.ChordName ?? "", [.. h.Document.MidiNotes]))];
    }

    // The tool's own distance: its private VoiceLeadingDistance, by reflection
    public static double Distance(int[] a, int[] b) => (double)DistanceMethod.Invoke(null, [a, b])!;

    // The least total motion with the tool's penalty of 3 per extra note, when the smaller voicing
    // may pair with any notes of the larger one, not only its lowest
    public static double Least(int[] a, int[] b)
    {
        var (small, large) = a.Length <= b.Length ? (a.Order().ToArray(), b.Order().ToArray()) : (b.Order().ToArray(), a.Order().ToArray());
        var best = double.MaxValue;
        foreach (var subset in Subsets(large.Length, small.Length))
            best = Math.Min(best, Enumerable.Range(0, small.Length).Sum(i => Math.Abs(small[i] - large[subset[i]])));
        return best + 3.0 * (large.Length - small.Length);
    }

    static IEnumerable<int[]> Subsets(int n, int k, int start = 0)
    {
        if (k == 0) { yield return []; yield break; }
        for (var i = start; i <= n - k; i++)
            foreach (var rest in Subsets(n, k - 1, i + 1))
                yield return [i, .. rest];
    }

    // Between voicings of equal size, the least motion over every pairing of their notes
    public static int LeastOverPairings(int[] a, int[] b) =>
        Permutations(b.Length).Min(p => Enumerable.Range(0, a.Length).Sum(i => Math.Abs(a[i] - b[p[i]])));

    static IEnumerable<int[]> Permutations(int n)
    {
        if (n == 0) { yield return []; yield break; }
        foreach (var p in Permutations(n - 1))
            for (var i = 0; i <= p.Length; i++)
                yield return [.. p[..i], n - 1, .. p[i..]];
    }

    // Every note of the chord; a seventh chord without its perfect fifth, as shell voicings leave
    // it out; every note and more; part of the chord; or notes outside it
    static readonly string[] Verdicts = ["exact", "no fifth", "more", "part", "other"];

    static string Verdict(string symbol, Voicing v)
    {
        var chord = Chord(symbol);
        var verdict = ChordVoicingsProbe.Verdict(chord, v.Pcs);
        var fifth = (ChordVoicingsProbe.RootPc(Textbook[symbol].Root) + 7) % 12;
        return verdict == "part" && chord.Count >= 4 && chord.Contains(fifth) && chord.Except(v.Pcs).SequenceEqual([fifth])
            ? "no fifth" : verdict;
    }

    // The voicing plays the chord a guitarist asked for
    static bool Right(string verdict) => verdict is "exact" or "no fifth";

    static string Show(Voicing v) => $"{v.Chart} {v.Name}";

    // Lesson 18's least motion in pitch classes: as many voices as the larger chord, every note of
    // both chords sounded, any note of the smaller one doubled, each voice by the shorter way
    public static int LeastInPitchClasses(HashSet<int> a, HashSet<int> b)
    {
        var (x, y) = (a.ToArray(), b.ToArray());
        var n = Math.Max(x.Length, y.Length);
        var perms = Permutations(n).ToList();
        int Move(int p, int q) { var d = ((q - p) % 12 + 12) % 12; return Math.Min(d, 12 - d); }
        return Fill(x, n).SelectMany(fx => Fill(y, n).Select(fy => perms.Min(p => Enumerable.Range(0, n).Sum(i => Move(fx[i], fy[p[i]]))))).Min();
    }

    static IEnumerable<int[]> Fill(int[] chord, int n)
    {
        IEnumerable<int[]> Extra(int k, int start)
        {
            if (k == 0) { yield return []; yield break; }
            for (var i = start; i < chord.Length; i++)
                foreach (var rest in Extra(k - 1, i))
                    yield return [chord[i], .. rest];
        }
        return Extra(n - chord.Length, 0).Select(e => (int[])[.. chord, .. e]);
    }

    // ---- The questions ----

    public static void CandidatesTable(List<Shape> corpus, string where)
    {
        Title($"The 15 candidates the tool pairs for each chord, {where}, against the chord a textbook spells");
        int[] w = [8, 7, 10, 6, 6, 7, 19];
        Row(w, "chord", "exact", "no fifth", "more", "part", "other", "exact in the index", "first exact candidate");
        var chords = Pairs.SelectMany(p => new[] { p.From, p.To }).Distinct().ToList();
        var totals = new int[Verdicts.Length];
        foreach (var symbol in chords)
        {
            var verdicts = Candidates(symbol).Select(c => Verdict(symbol, c)).ToList();
            var counts = Verdicts.Select(k => verdicts.Count(v => v == k)).ToArray();
            for (var i = 0; i < counts.Length; i++) totals[i] += counts[i];
            var inIndex = corpus.Count(s => s.Pcs.SetEquals(Chord(symbol)));
            var first = verdicts.IndexOf("exact");
            Row(w, [symbol, .. counts.Cast<object?>(), inIndex, first < 0 ? "none" : $"rank {first + 1}"]);
        }

        Line($"candidates {totals.Sum()}: " + string.Join(", ", Verdicts.Zip(totals).Select(x => $"{x.First} {x.Second}")));
    }

    public static void PairsTable(List<Shape> corpus, string where)
    {
        Title($"The tool's first pair for each prompt, {where}, and the smoothest pair of exact voicings in the index");
        int[] w = [14, 42, 36, 12, 36];
        Row(w, "prompt", "first pair: from", "to", "both right", "smoothest exact pair in the index", "least in pitch classes");
        int rightFirst = 0, moreThanIndex = 0, indexIsLeast = 0;
        Pair? firstAnswer = null;
        foreach (var (from, to) in Pairs)
        {
            var (pairs, error) = Ask(from, to);
            if (error is not null) { Row(w, $"{from} → {to}", error); continue; }
            var top = pairs[0];
            firstAnswer ??= top;
            var (vf, vt) = (Verdict(from, top.From), Verdict(to, top.To));
            if (Right(vf) && Right(vt)) rightFirst++;
            var both = pairs.Count(p => Right(Verdict(from, p.From)) && Right(Verdict(to, p.To)));
            var a = corpus.Where(s => s.Pcs.SetEquals(Chord(from))).ToList();
            var b = corpus.Where(s => s.Pcs.SetEquals(Chord(to))).ToList();
            var best = a.SelectMany(x => b.Select(y => (x, y, d: Distance(x.Midi, y.Midi)))).OrderBy(t => t.d).ToList();
            var least = LeastInPitchClasses(Chord(from), Chord(to));
            if (best.Count > 0 && top.Distance > best[0].d) moreThanIndex++;
            if (best.Count > 0 && best[0].d == least) indexIsLeast++;
            Row(w, $"{from} → {to}", $"{top.Distance}: {Show(top.From)}, {vf}", $"{Show(top.To)}, {vt}", $"{both} of {pairs.Count}",
                best.Count == 0 ? "no exact voicing" : $"{best[0].d}: {best[0].x.Chart} → {best[0].y.Chart}", least);
        }

        Line($"prompts {Pairs.Length}: first pair right on both sides {rightFirst}, " +
             $"moves more than the smoothest exact pair {moreThanIndex}; that pair moves the least in pitch classes {indexIsLeast}");
        // The table writes the diagrams low E first; the tool returns the index's strings as they are
        if (firstAnswer is { } f)
            Line($"the first pair for {Pairs[0].From} → {Pairs[0].To}, as the tool returns it: diagram {f.From.Diagram} → {f.To.Diagram}");
    }

    public static void MoreCandidates(string where)
    {
        Title($"The first pair with 50 candidates per chord, the most the tool allows, {where}");
        int[] w = [14, 10, 12, 12];
        Row(w, "prompt", "distance", "from", "to", "first pair");
        var right = 0;
        foreach (var (from, to) in Pairs)
        {
            var (pairs, error) = Ask(from, to, candidates: 50);
            if (error is not null) { Row(w, $"{from} → {to}", error); continue; }
            var top = pairs[0];
            var (vf, vt) = (Verdict(from, top.From), Verdict(to, top.To));
            if (Right(vf) && Right(vt)) right++;
            Row(w, $"{from} → {to}", $"{top.Distance}", vf, vt, $"{Show(top.From)} → {Show(top.To)}");
        }

        Line($"prompts {Pairs.Length}: first pair right on both sides {right}");
    }

    public static void DistanceCheck(string where)
    {
        Title($"The tool's distance on every pair it weighs for the ten prompts, {where}, against the least motion");
        int equal = 0, equalLeast = 0, unequal = 0, unequalLeast = 0, changed = 0;
        double most = 0;
        (Voicing A, Voicing B, double D, double L)? example = null;
        foreach (var (from, to) in Pairs)
        {
            double toolBest = double.MaxValue, leastBest = double.MaxValue;
            foreach (var a in Candidates(from))
                foreach (var b in Candidates(to))
                {
                    var d = Distance(a.Midi, b.Midi);
                    toolBest = Math.Min(toolBest, d);
                    if (a.Midi.Length == b.Midi.Length)
                    {
                        equal++;
                        if (d == LeastOverPairings(a.Midi, b.Midi)) equalLeast++;
                        leastBest = Math.Min(leastBest, d);
                        continue;
                    }

                    unequal++;
                    var l = Least(a.Midi, b.Midi);
                    leastBest = Math.Min(leastBest, l);
                    if (d == l) unequalLeast++;
                    else if (d - l > most) { most = d - l; example = (a, b, d, l); }
                }

            if (leastBest < toolBest) changed++;
        }

        Line($"pairs of equal size {equal}: the distance is the least over every pairing {equalLeast}");
        Line($"pairs of unequal size {unequal}: the distance is the least over every choice of notes {unequalLeast}");
        if (example is { } e)
            Line($"the largest gap, {most} semitones: {Show(e.A)} [{Ints(e.A.Midi.Order())}] → {Show(e.B)} [{Ints(e.B.Midi.Order())}], distance {e.D}, least {e.L}");
        Line($"prompts whose first pair would move less with the least over every choice of notes: {changed} of {Pairs.Length}");
    }
}
