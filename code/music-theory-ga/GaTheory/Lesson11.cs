using System.Numerics;
using System.Text.RegularExpressions;
using GA.Domain.Core.Instruments;
using GA.Domain.Core.Instruments.Fretboard.Voicings.Core;
using GA.Domain.Core.Instruments.Positions;
using GA.Domain.Core.Instruments.Primitives;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Harmony;
using GA.Domain.Services.Atonal;
using GA.Domain.Services.Fretboard.Voicings.Analysis;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 9 of the course, run as `l11` (l9 and l10 are appendices A and B): common tones, the size
// of a voice leading, parallel fifths and octaves, and distances between chord types
public static partial class Lesson11
{
    // ---- Chords: the types of lesson 3, plus the major ninth

    static readonly (string Suffix, (int Degree, int Semitones)[] Tones)[] Types =
        [.. Lesson3.Chords, ("maj9", [(1, 0), (3, 4), (5, 7), (7, 11), (9, 14)])];

    static (string Root, string Suffix) Split(string chord)
    {
        var rootLength = chord.Length > 1 && chord[1] is '#' or 'b' ? 2 : 1;
        return (chord[..rootLength], chord[rootLength..]);
    }

    // The notes of a chord, root first: spelled name, pitch class, degree, semitones above the root
    static (string Name, int Pc, int Degree, int Semitones)[] Notes(string chord)
    {
        var (root, suffix) = Split(chord);
        return [.. Types.Single(t => t.Suffix == suffix).Tones.Select(t =>
            (Theory.Spell(root, t.Degree, t.Semitones), Theory.Mod12(Theory.PitchClassOf(root) + t.Semitones), t.Degree, t.Semitones))];
    }

    static int[] Pcs(string chord) => [.. Notes(chord).Select(n => n.Pc)];

    // The name of an interval from its degree and its size: P for 1, 4, 5 and their compounds, M or m otherwise
    static string IntervalName(int degree, int semitones)
    {
        int[] majorScale = [0, 2, 4, 5, 7, 9, 11];
        var natural = majorScale[(degree - 1) % 7] + 12 * ((degree - 1) / 7);
        var perfect = (degree - 1) % 7 is 0 or 3 or 4;
        var quality = (perfect, semitones - natural) switch
        {
            (true, 0) => "P",
            (true, -1) => "d",
            (true, 1) => "A",
            (false, 0) => "M",
            (false, -1) => "m",
            (false, -2) => "d",
            (false, 1) => "A",
            _ => "?",
        };
        return quality + degree;
    }

    // ---- Common tones

    static string CommonTones(string a, string b) =>
        Theory.Format(Theory.PitchClasses(Theory.SetId(Pcs(a)) & Theory.SetId(Pcs(b)))) is var s && s.Length > 0 ? s : "(none)";

    static string GaCommonTones(string a, string b) =>
        string.Join(" ", Chord.FromSymbol(a).PitchClassSet.Intersect(Chord.FromSymbol(b).PitchClassSet).OrderBy(pc => pc.Value)) is var s && s.Length > 0 ? s : "(none)";

    // "E: M3 in C, P1 in Em; G: P5 in C, m3 in Em", each note spelled as in each chord
    static string Roles(string a, string b)
    {
        var inB = Notes(b).ToDictionary(n => n.Pc);
        var shared = Notes(a).Where(n => inB.ContainsKey(n.Pc)).OrderBy(n => n.Pc).Select(n =>
        {
            var m = inB[n.Pc];
            var name = n.Name == m.Name ? n.Name : $"{n.Name}/{m.Name}";
            return $"{name}: {IntervalName(n.Degree, n.Semitones)} in {a}, {IntervalName(m.Degree, m.Semitones)} in {b}";
        });
        return string.Join("; ", shared);
    }

    // ---- The size of a voice leading between pitch classes

    // Each voice takes the shorter way round the octave: -6 to +6 semitones
    static int Move(int from, int to)
    {
        var d = Theory.Mod12(to - from);
        return d > 6 ? d - 12 : d;
    }

    // The chord with notes added until it has n voices, every way: each note appears at least once
    static IEnumerable<int[]> Doublings(int[] chord, int n)
    {
        if (chord.Length >= n)
        {
            yield return chord;
            yield break;
        }
        foreach (var extra in Multisets(chord, n - chord.Length, 0)) yield return [.. chord, .. extra];
    }

    static IEnumerable<int[]> Multisets(int[] notes, int k, int start)
    {
        if (k == 0)
        {
            yield return [];
            yield break;
        }
        for (var i = start; i < notes.Length; i++)
        {
            foreach (var rest in Multisets(notes, k - 1, i)) yield return [notes[i], .. rest];
        }
    }

    static IEnumerable<int[]> Permutations(int[] items)
    {
        if (items.Length <= 1)
        {
            yield return items;
            yield break;
        }
        for (var i = 0; i < items.Length; i++)
        {
            foreach (var rest in Permutations([.. items[..i], .. items[(i + 1)..]])) yield return [items[i], .. rest];
        }
    }

    // The course: the smallest total motion over every voice leading, the smaller chord doubling any of its notes
    static (int Size, (int From, int To)[] Voices) Smallest(int[] a, int[] b)
    {
        var n = Math.Max(a.Length, b.Length);
        var best = (Size: int.MaxValue, Voices: Array.Empty<(int, int)>());
        foreach (var from in Doublings(a, n))
        foreach (var target in Doublings(b, n))
        foreach (var to in Permutations(target))
        {
            var size = from.Zip(to, (x, y) => Math.Abs(Move(x, y))).Sum();
            if (size < best.Size) best = (size, [.. from.Zip(to)]);
        }
        return best;
    }

    // GA's VoiceLeadingSkill, rewritten (VoiceLeadingSkill.cs lines 101-110, 139-194 at a826864): the smaller
    // chord padded with its root, then every permutation of the second chord's voices
    static (int Size, (int From, int To)[] Voices) SkillSmallest(int[] chordA, int[] chordB)
    {
        var n = Math.Max(chordA.Length, chordB.Length);
        var paddedA = Pad(chordA, n);
        var paddedB = Pad(chordB, n);
        var perm = Enumerable.Range(0, n).ToArray();
        var bestCost = int.MaxValue;
        var bestPerm = (int[])perm.Clone();
        do
        {
            var cost = 0;
            for (var i = 0; i < n; i++) cost += Math.Abs(Move(paddedA[i], paddedB[perm[i]]));
            if (cost < bestCost)
            {
                bestCost = cost;
                bestPerm = (int[])perm.Clone();
            }
        } while (NextPermutation(perm));
        return (bestCost, [.. Enumerable.Range(0, n).Select(i => (paddedA[i], paddedB[bestPerm[i]]))]);

        static int[] Pad(int[] chord, int targetLen) =>
            chord.Length >= targetLen ? chord : [.. chord, .. Enumerable.Repeat(chord[0], targetLen - chord.Length)];
    }

    static bool NextPermutation(int[] arr)
    {
        var i = arr.Length - 2;
        while (i >= 0 && arr[i] >= arr[i + 1]) i--;
        if (i < 0) return false;
        var j = arr.Length - 1;
        while (arr[j] <= arr[i]) j--;
        (arr[i], arr[j]) = (arr[j], arr[i]);
        Array.Reverse(arr, i + 1, arr.Length - i - 1);
        return true;
    }

    // "C->C 0, E->F +1, G->A +2", with each chord's own spelling
    static string Moves((int From, int To)[] voices, string a, string b)
    {
        var namesA = Notes(a).GroupBy(n => n.Pc).ToDictionary(g => g.Key, g => g.First().Name);
        var namesB = Notes(b).GroupBy(n => n.Pc).ToDictionary(g => g.Key, g => g.First().Name);
        return string.Join(", ", voices.Select(v =>
        {
            var m = Move(v.From, v.To);
            return $"{namesA[v.From]}->{namesB[v.To]} {(m > 0 ? "+" : "")}{m}";
        }));
    }

    // The two-chord pattern of GA's VoiceLeadingSkill, copied as it is (VoiceLeadingSkill.cs lines 55-57 at a826864)
    [GeneratedRegex(@"\b(?<a>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\s+(?:to|→|->|>)\s+(?<b>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b", RegexOptions.IgnoreCase)]
    private static partial Regex SkillTwoChords();

    // Its ten example prompts (lines 35-47)
    static readonly string[] SkillExamples =
    [
        "voice leading from C to F",
        "smooth voice leading C to Am",
        "best voicing from G7 to Cmaj7",
        "how do I voice lead Dm7 to G7",
        "voice leading C major to G major",
        "smoothest voicing from Em to A7",
        "voice leading Fmaj7 to Bm7b5",
        "what's the smoothest voicing from D to A",
        "voice lead C7 to F",
        "best way to move from G7 to C",
    ];

    // ---- Voicings on the guitar: pitches, not pitch classes

    static readonly string[] Standard = ["E2", "A2", "D3", "G3", "B3", "E4"]; // string 6 to string 1

    // A shape such as "x32010" (string 6 first) -> MIDI notes of the played strings, low string first
    static int[] Played(string shape) =>
        [.. shape.Select((ch, s) => (ch, s)).Where(p => p.ch != 'x').Select(p => Theory.MidiOf(Standard[p.s]) + p.ch - '0')];

    // GA's ga_voice_leading_pair distance, copied as it is (CompositionTools.cs lines 320-336 at a826864)
    static double PairDistance(IReadOnlyList<int> midi1, IReadOnlyList<int> midi2)
    {
        if (midi1.Count == 0 || midi2.Count == 0) return double.MaxValue;

        var a = midi1.OrderBy(n => n).ToArray();
        var b = midi2.OrderBy(n => n).ToArray();
        var common = Math.Min(a.Length, b.Length);

        double sum = 0;
        for (var i = 0; i < common; i++)
            sum += Math.Abs(a[i] - b[i]);

        // Penalty for unmatched voices (extra notes on either side).
        var extras = Math.Abs(a.Length - b.Length);
        sum += extras * 3.0;  // soft penalty — 3 semitones per orphan note.
        return sum;
    }

    // The course: each note of the smaller voicing goes to a different note of the larger one, every way,
    // and each note left over costs the same 3 semitones as in GA
    static int VoicingDistance(int[] a, int[] b)
    {
        var (small, large) = a.Length <= b.Length ? (a, b) : (b, a);
        var best = int.MaxValue;
        foreach (var chosen in Arrangements(large, small.Length))
        {
            best = Math.Min(best, small.Zip(chosen, (x, y) => Math.Abs(x - y)).Sum());
        }
        return best + 3 * (large.Length - small.Length);
    }

    // Every ordered choice of k different items
    static IEnumerable<int[]> Arrangements(int[] items, int k)
    {
        if (k == 0)
        {
            yield return [];
            yield break;
        }
        for (var i = 0; i < items.Length; i++)
        {
            foreach (var rest in Arrangements([.. items[..i], .. items[(i + 1)..]], k - 1)) yield return [items[i], .. rest];
        }
    }

    // ---- Parallel fifths and octaves, each string a voice

    // GA's Voicing for a shape, positions in string order 1..6 (as in lesson 3)
    static Voicing GaVoicing(string shape)
    {
        var positions = new Position[6];
        for (var s = 1; s <= 6; s++)
        {
            var ch = shape[6 - s];
            positions[s - 1] = ch == 'x'
                ? new Position.Muted(new Str(s))
                : new Position.Played(new PositionLocation(new Str(s), new Fret(ch - '0')), Tuning.Default[new Str(s)].MidiNote + (ch - '0'));
        }
        return new Voicing(positions, [.. positions.OfType<Position.Played>().Select(p => p.MidiNote)]);
    }

    // The textbook rule: two voices sounding in both chords, both moving in the same direction, a perfect
    // fifth apart before and after (compound fifths included), or an octave or a unison apart before and after
    static string Parallels(string from, string to)
    {
        int? Pitch(string shape, int s) => shape[6 - s] == 'x' ? null : Theory.MidiOf(Standard[6 - s]) + shape[6 - s] - '0';
        var fifths = new List<string>();
        var octaves = new List<string>();
        for (var x = 1; x <= 6; x++)
        for (var y = x + 1; y <= 6; y++)
        {
            if (Pitch(from, x) is not { } x1 || Pitch(to, x) is not { } x2 || Pitch(from, y) is not { } y1 || Pitch(to, y) is not { } y2) continue;
            if (Math.Sign(x2 - x1) == 0 || Math.Sign(x2 - x1) != Math.Sign(y2 - y1)) continue;
            var before = Math.Abs(x1 - y1) % 12;
            var after = Math.Abs(x2 - y2) % 12;
            if (before == 7 && after == 7) fifths.Add($"{y}-{x}");
            if (before == 0 && after == 0) octaves.Add($"{y}-{x}");
        }
        return Summary(fifths, octaves);
    }

    static string GaParallels(string from, string to)
    {
        var issues = ProgressionVoiceLeadingAnalyzer.DetectParallelMotion(GaVoicing(from), GaVoicing(to));
        var fifths = issues.Where(i => i.Type == ParallelMotionType.Fifths).Select(i => $"{Math.Max(i.StringA, i.StringB)}-{Math.Min(i.StringA, i.StringB)}");
        var octaves = issues.Where(i => i.Type == ParallelMotionType.Octaves).Select(i => $"{Math.Max(i.StringA, i.StringB)}-{Math.Min(i.StringA, i.StringB)}");
        return Summary([.. fifths], [.. octaves]);
    }

    static string Summary(List<string> fifths, List<string> octaves) =>
        $"5ths {(fifths.Count == 0 ? "-" : string.Join(" ", fifths.Order(StringComparer.Ordinal)))}; 8ves {(octaves.Count == 0 ? "-" : string.Join(" ", octaves.Order(StringComparer.Ordinal)))}";

    // ---- Distances between chord types: the course's brute force under any of O, P, T and I

    static readonly Dictionary<int, int[][]> IndexPermutations = [];

    static int[][] PermutationsOf(int n) =>
        IndexPermutations.TryGetValue(n, out var p) ? p : IndexPermutations[n] = [.. Permutations([.. Enumerable.Range(0, n)])];

    // Pitches or pitch classes as numbers; with O each voice moves by the shorter way round the octave,
    // with P the voices may be reassigned, with T the second chord may be transposed, with I inverted
    static double Optic(double[] a, double[] b, bool o, bool p, bool t, bool i)
    {
        var n = a.Length;
        int[][] orders = p ? PermutationsOf(n) : [[.. Enumerable.Range(0, n)]];
        var best = double.MaxValue;
        foreach (var sign in i ? [1.0, -1.0] : new[] { 1.0 })
        {
            double[] bs = [.. b.Select(x => sign * x)];
            // the best transposition is a whole number: with O one of 0 to 11, without O one that puts
            // a note of the second chord on a note of the first
            var low = (int)(a.Min() - bs.Max());
            var shifts = !t ? [0] : o ? Enumerable.Range(0, 12) : Enumerable.Range(low, (int)(a.Max() - bs.Min()) - low + 1);
            foreach (var c in shifts)
            foreach (var order in orders)
            {
                var sum = 0.0;
                for (var k = 0; k < n; k++)
                {
                    var d = Math.Abs(a[k] - (bs[order[k]] + c));
                    if (o)
                    {
                        d %= 12;
                        if (d > 6) d = 12 - d;
                    }
                    sum += d;
                }
                if (sum < best) best = sum;
            }
        }
        return best;
    }

    static double[] Vector(string chord) => [.. Pcs(chord).Select(pc => (double)pc)];

    static string Num(double value) => value.ToString(System.Globalization.CultureInfo.InvariantCulture);

    static string PrimeName(SetClass setClass) => $"({string.Join("", setClass.PrimeForm.Select(pc => pc.Value))})";

    public static void Run()
    {
        Title("Common tones: C major and the other chords of its key (GA: Chord.FromSymbol, PitchClassSet.Intersect)");
        Columns("chords", 14, 12);
        foreach (var other in new[] { "Dm", "Em", "F", "G", "Am", "Bdim" })
        {
            Row($"C {other}", CommonTones("C", other), Try(() => GaCommonTones("C", other)));
            if (Roles("C", other) is { Length: > 0 } roles) Line($"  {roles}");
        }

        Title("Common tones of seventh chords and extensions");
        Columns("chords", 14, 12);
        foreach (var (a, b) in new[] { ("G7", "Cmaj7"), ("Dm7", "G7"), ("Bm7b5", "G7"), ("Cmaj9", "Em7"), ("Cdim7", "F7"), ("C6", "Am7"), ("C9", "Gm7") })
        {
            Row($"{a} {b}", CommonTones(a, b), Try(() => GaCommonTones(a, b)));
            Line($"  {Roles(a, b)}");
        }

        Title("The smallest voice leading: the course tries every doubling, GA's VoiceLeadingSkill doubles the root");
        Columns("chords", 14, 6);
        foreach (var (a, b) in new[] { ("C", "F"), ("C", "Am"), ("C", "G"), ("C", "Dm"), ("C", "F#"), ("Dm7", "G7"), ("G7", "Cmaj7"), ("G7", "C"), ("C", "G7"), ("G", "Cmaj7"), ("Fmaj7", "Bm7b5") })
        {
            var course = Smallest(Pcs(a), Pcs(b));
            var ga = SkillSmallest(Pcs(a), Pcs(b));
            Row($"{a} {b}", course.Size, ga.Size);
            Line($"  course: {Moves(course.Voices, a, b)}");
            if (ga.Size != course.Size) Line($"  GA:     {Moves(ga.Voices, a, b)}");
        }

        Title("Every triad to every seventh chord, and back: how often doubling the root misses the minimum");
        var triads = (from root in Enumerable.Range(0, 12) from type in new[] { "", "m", "dim", "aug" } select Theory.PcName(root) + type).ToList();
        var sevenths = (from root in Enumerable.Range(0, 12) from type in new[] { "maj7", "7", "m7", "m7b5", "dim7" } select Theory.PcName(root) + type).ToList();
        Headings("direction", "pairs", "GA above the minimum, largest gap", 18, 8);
        foreach (var (label, pairs) in new[]
                 {
                     ("triad -> seventh", (from x in triads from y in sevenths select (x, y)).ToList()),
                     ("seventh -> triad", (from y in sevenths from x in triads select (y, x)).ToList()),
                 })
        {
            var gaps = pairs.Select(p => (p, Gap: SkillSmallest(Pcs(p.Item1), Pcs(p.Item2)).Size - Smallest(Pcs(p.Item1), Pcs(p.Item2)).Size)).ToList();
            var missed = gaps.Count(g => g.Gap > 0);
            var widest = gaps.MaxBy(g => g.Gap);
            Plain(label, pairs.Count, $"{missed} ({100.0 * missed / pairs.Count:F1} %), {widest.Gap} semitones, first {widest.p.Item1} -> {widest.p.Item2}");
        }

        Title("GA's VoiceLeadingSkill: its own ten example prompts against its own chord pattern");
        foreach (var prompt in SkillExamples)
        {
            var match = SkillTwoChords().Match(prompt);
            Line($"  {prompt,-42} {(match.Success ? $"{match.Groups["a"].Value} -> {match.Groups["b"].Value}" : "(no match: the skill answers \"Ask about voice leading between two chords\")")}");
        }

        Title("Guitar voicings in pitch space: the course pairs the notes every way, GA's ga_voice_leading_pair pairs the lowest");
        Columns("voicings", 20, 6);
        foreach (var (a, b, label) in new[]
                 {
                     ("x32010", "x02210", "C -> Am"),
                     ("320003", "x32010", "G -> C"),
                     ("320001", "x32010", "G7 -> C"),
                     ("xx2010", "x32010", "C (no bass) -> C"),
                     ("x2xx63", "8xx988", "G7/B -> C (MCP)"),
                 })
        {
            Row(label, VoicingDistance(Played(a), Played(b)), Num(PairDistance(Played(a), Played(b))));
            Line($"  {a} {string.Join(" ", Played(a).Select(Theory.PitchName))}  ->  {b} {string.Join(" ", Played(b).Select(Theory.PitchName))}");
        }

        Title("Parallel fifths and octaves, string by string (GA: ProgressionVoiceLeadingAnalyzer)");
        Columns("voicings", 18, 30);
        foreach (var (a, b, label) in new[]
                 {
                     ("133211", "355433", "F -> G barre"),
                     ("022xxx", "355xxx", "E5 -> G5"),
                     ("x32010", "320003", "C -> G open"),
                     ("320001", "x32010", "G7 -> C open"),
                     ("x02210", "xx0231", "Am -> Dm open"),
                 })
        {
            Row(label, Parallels(a, b), GaParallels(a, b));
        }

        Title("Distance from C major under OP, OPT and OPTI (GA: VoiceLeadingSpace)");
        Columns("chords", 14, 12);
        foreach (var (a, b) in new[] { ("C", "F"), ("C", "Eb"), ("C", "Am"), ("C", "Cm"), ("C", "Caug"), ("C", "Cdim"), ("C", "F#"), ("Cmaj7", "C7"), ("C7", "Cdim7") })
        {
            var (va, vb) = (Vector(a), Vector(b));
            var course = string.Join(" ", new[] { (false, false), (true, false), (true, true) }.Select(f => Num(Optic(va, vb, true, true, f.Item1, f.Item2))));
            var ga = string.Join(" ", new[] { (false, false), (true, false), (true, true) }.Select(f => Num(new VoiceLeadingSpace(va.Length, true, true, f.Item1, f.Item2).Distance(va, vb))));
            Row($"{a} {b}", course, ga);
        }

        Title("GA's shortcut (cyclic shifts of the sorted chords) against every assignment of voices");
        Headings("sets", "ordered pairs", "GA differs from the course", 14, 14);
        foreach (var size in new[] { 3, 4 })
        {
            var sets = Enumerable.Range(0, 4096).Where(id => BitOperations.PopCount((uint)id) == size)
                .Select(id => Theory.PitchClasses(id).Select(pc => (double)pc).ToArray()).ToList();
            foreach (var t in new[] { false, true })
            {
                var space = new VoiceLeadingSpace(size, true, true, t, false);
                var differ = sets.Sum(a => sets.Count(b => space.Distance(a, b) != Optic(a, b, true, true, t, false)));
                Plain($"{size} notes, OP{(t ? "T" : "")}", sets.Count * sets.Count, differ);
            }
        }

        Title("Without octave equivalence, with transposition: GA only shifts upward, by 0 to 11 semitones");
        Columns("from -> to", 22, 6);
        int[] c4 = [60, 64, 67], b3 = [59, 63, 66], c5 = [72, 76, 79];
        foreach (var (a, b, label) in new[] { (c4, b3, "C4 major -> B3 major"), (b3, c4, "B3 major -> C4 major"), (c4, c5, "C4 major -> C5 major"), (c5, c4, "C5 major -> C4 major") })
        {
            double[] va = [.. a.Select(x => (double)x)], vb = [.. b.Select(x => (double)x)];
            Row(label, Num(Optic(va, vb, false, true, true, false)), Num(new VoiceLeadingSpace(3, false, true, true, false).Distance(va, vb)));
        }

        Title("Set classes of the same size: GA's SetClassOpticIndex sums each note's nearest neighbour");
        Columns("set classes", 16, 6);
        var trichords = SetClass.Items.Where(sc => sc.PrimeForm.Cardinality.Value == 3).OrderBy(sc => sc.PrimeForm.Id.Value).ToList();
        double CourseClass(SetClass x, SetClass y) =>
            Optic([.. x.PrimeForm.Select(pc => (double)pc.Value)], [.. y.PrimeForm.Select(pc => (double)pc.Value)], true, true, true, false);
        var c012 = trichords.Single(sc => PrimeName(sc) == "(012)");
        var c048 = trichords.Single(sc => PrimeName(sc) == "(048)");
        Row("(012) -> (048)", Num(CourseClass(c012, c048)), Num(SetClassOpticIndex.Distance(c012, c048)));
        Row("(048) -> (012)", Num(CourseClass(c048, c012)), Num(SetClassOpticIndex.Distance(c048, c012)));
        var classPairs = (from x in trichords from y in trichords select (x, y)).ToList();
        Line($"  {trichords.Count} trichord classes, {classPairs.Count} ordered pairs:");
        Line($"  GA below the one-to-one minimum: {classPairs.Count(p => SetClassOpticIndex.Distance(p.x, p.y) < CourseClass(p.x, p.y))}");
        Line($"  GA above it: {classPairs.Count(p => SetClassOpticIndex.Distance(p.x, p.y) > CourseClass(p.x, p.y))}");
        Line($"  GA's answer changes when the two are swapped: {classPairs.Count(p => SetClassOpticIndex.Distance(p.x, p.y) != SetClassOpticIndex.Distance(p.y, p.x))}");

        Title("Exercise solutions");
        Columns("question", 20, 12);
        Row("1. F Dm", CommonTones("F", "Dm"), GaCommonTones("F", "Dm"));
        Line($"  {Roles("F", "Dm")}");
        var exercise2 = Smallest(Pcs("Am"), Pcs("F"));
        Row("2. Am F", exercise2.Size, SkillSmallest(Pcs("Am"), Pcs("F")).Size);
        Line($"  {Moves(exercise2.Voices, "Am", "F")}");
        Row("3. A -> B barre", Parallels("577655", "799877"), GaParallels("577655", "799877"));
        var (vc, veb) = (Vector("C"), Vector("Eb"));
        Row("4. C Eb, OP OPT", $"{Num(Optic(vc, veb, true, true, false, false))} {Num(Optic(vc, veb, true, true, true, false))}",
            $"{Num(new VoiceLeadingSpace(3, true, true, false, false).Distance(vc, veb))} {Num(new VoiceLeadingSpace(3, true, true, true, false).Distance(vc, veb))}");
    }
}
