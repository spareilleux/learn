using System.Text.RegularExpressions;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Harmony;
using GA.Domain.Core.Theory.Tonal;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 7: cadences, ii-V-I, voice leading from V7 to I, and finding the key of a progression
public static partial class Lesson7
{
    static readonly string[] Numerals = ["I", "II", "III", "IV", "V", "VI", "VII"];

    static int Mod7(int value) => ((value % 7) + 7) % 7;

    static (string Root, string Suffix) Split(string chord)
    {
        var slash = chord.IndexOf('/');
        if (slash >= 0) chord = chord[..slash];
        var rootLength = chord.Length > 1 && chord[1] is '#' or 'b' ? 2 : 1;
        return (chord[..rootLength], chord[rootLength..]);
    }

    static bool HasMinorThird(string suffix) => (suffix.StartsWith('m') && !suffix.StartsWith("maj")) || suffix.StartsWith("dim");

    // A Roman numeral from the chord's root and third, measured against the scale of the key:
    // the number from the letters, a flat or sharp when the root differs from that scale degree
    public static string Numeral(string chord, string tonic, IReadOnlyList<int> steps)
    {
        var (root, suffix) = Split(chord);
        var degree = Mod7(Theory.Letters.IndexOf(root[0]) - Theory.Letters.IndexOf(tonic[0])) + 1;
        var reference = steps.Take(degree - 1).Sum();
        var difference = Theory.Mod12(Theory.PitchClassOf(root) - Theory.PitchClassOf(tonic) - reference);
        if (difference > 6) difference -= 12;
        var accidental = difference switch { 0 => "", -1 => "b", 1 => "#", _ => "?" };
        var numeral = Numerals[degree - 1];
        return accidental + (HasMinorThird(suffix) ? numeral.ToLowerInvariant() : numeral);
    }

    static int[] StepsOf(string mode) => mode switch
    {
        "Major" => Theory.MajorSteps,
        "Minor" => Theory.NaturalMinorSteps,
        "Phrygian" => [.. Theory.MajorSteps.Skip(2).Concat(Theory.MajorSteps.Take(2))],
        _ => throw new FormatException(mode),
    };

    // Pitch classes of a chord symbol, with the chord types of lesson 3
    public static int ChordId(string chord)
    {
        var (root, suffix) = Split(chord);
        var tones = Lesson3.Chords.Single(c => c.Suffix == suffix).Tones;
        return Theory.SetId(tones.Select(t => Theory.PitchClassOf(root) + t.Semitones));
    }

    [GeneratedRegex("\"([^\"]*)\"")]
    private static partial Regex Quoted();

    [GeneratedRegex("^[b#]?(?:VII|VI|IV|V|III|II|I|vii|vi|iv|v|iii|ii|i)")]
    private static partial Regex LeadingNumeral();

    // The few fields of GA's Cadences.yaml this lesson reads; the file is a flat list, so a line reader is enough
    static List<(string Name, string[] Numerals, string InKey, string[] Chords)> ReadCadences(string path)
    {
        var cadences = new List<(string, string[], string, string[])>();
        string? name = null, inKey = null;
        string[]? numerals = null, chords = null;
        foreach (var raw in File.ReadLines(path))
        {
            var line = raw.Trim();
            string[] QuotedValues() => [.. Quoted().Matches(line[..(line.IndexOf(']') + 1)]).Select(m => m.Groups[1].Value)];
            if (line.StartsWith("- Name:"))
            {
                Flush();
                name = Quoted().Match(line).Groups[1].Value;
            }
            else if (line.StartsWith("RomanNumerals:")) numerals = QuotedValues();
            else if (line.StartsWith("InKey:")) inKey = Quoted().Match(line).Groups[1].Value;
            else if (line.StartsWith("Chords:")) chords = QuotedValues();
        }
        Flush();
        return cadences;

        void Flush()
        {
            if (name is not null && numerals is not null && inKey is not null && chords is not null)
                cadences.Add((name, numerals, inKey, chords));
            name = inKey = null;
            numerals = chords = null;
        }
    }

    // The course's key finder: every chord must fit in the key's collection (major scale; natural minor
    // plus the raised leading tone), then the key whose tonic chord ends, or else starts, the progression
    public static string CourseKey(string[] chords)
    {
        var ids = chords.Select(ChordId).ToArray();
        var candidates =
            from tonic in Enumerable.Range(0, 12)
            from minor in new[] { false, true }
            let scale = Theory.Transpose(Theory.FromSteps(minor ? Theory.NaturalMinorSteps : Theory.MajorSteps), tonic)
            let collection = minor ? scale | 1 << Theory.Mod12(tonic - 1) : scale
            let fits = ids.Count(id => (id & ~collection) == 0)
            let endsOnTonic = IsTonicChord(chords[^1], tonic, minor)
            let startsOnTonic = IsTonicChord(chords[0], tonic, minor)
            orderby fits descending, endsOnTonic descending, startsOnTonic descending
            select (tonic, minor, fits, rank: (fits, endsOnTonic, startsOnTonic));
        var list = candidates.ToList();
        var best = list.Where(c => c.rank == list[0].rank)
            .Select(c => Theory.KeyName(Theory.FifthsOf(c.tonic, c.minor), c.minor));
        return string.Join(" or ", best);
    }

    static bool IsTonicChord(string chord, int tonic, bool minor)
    {
        var (root, suffix) = Split(chord);
        return Theory.PitchClassOf(root) == tonic && HasMinorThird(suffix) == minor && !suffix.StartsWith("dim");
    }

    // The rule of GA's MCP tools ga_key_from_progression and ga_analyze_progression, rewritten here:
    // count the chord *roots* that belong to each major or natural minor scale, prefer the key on the first root
    static string RootsOnlyKey(string[] chords)
    {
        int[] major = [0, 2, 4, 5, 7, 9, 11], minor = [0, 2, 3, 5, 7, 8, 10];
        string[] flats = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];
        string[] sharps = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
        var roots = chords.Select(c => Theory.PitchClassOf(Split(c).Root)).ToList();
        var best = (
            from tonic in Enumerable.Range(0, 12)
            from mode in new[] { ("major", major), ("minor", minor) }
            let score = roots.Count(r => mode.Item2.Select(o => (tonic + o) % 12).Contains(r))
            orderby score descending, tonic == roots[0] ? 1 : 0 descending
            select (name: $"{(tonic is 1 or 3 or 8 or 10 ? flats[tonic] : sharps[tonic])} {mode.Item1}", score)).First();
        return $"{best.name} {best.score}/{chords.Length}";
    }

    public static void Run()
    {
        Title("GA's Cadences.yaml: its Roman numerals, and the course's from the chords and the key");
        Columns("cadence", 34, 16);
        foreach (var (name, numerals, inKey, chords) in ReadCadences(Path.Combine(AppContext.BaseDirectory, "Cadences.yaml")))
        {
            var tonic = inKey.Split(' ')[0];
            var steps = StepsOf(inKey.Split(' ')[1]);
            var course = string.Join(" ", chords.Select(c => Numeral(c, tonic, steps)));
            var ga = string.Join(" ", numerals.Select(n => LeadingNumeral().Match(n).Value));
            Row(name.Length > 34 ? name[..34] : name, course, ga);
        }

        Title("ii-V-I: chord qualities from the key (major, then minor with the raised leading tone)");
        Columns("progression", 18, 40);
        foreach (var (label, chords, _) in new[]
                 {
                     ("Dm7 G7 Cmaj7", new[] { "Dm7", "G7", "Cmaj7" }, "minor-7 dominant-7 major-7"),
                     ("Dm7b5 G7 Cm7", new[] { "Dm7b5", "G7", "Cm7" }, "half-diminished-7 dominant-7 minor-7"),
                 })
        {
            // course: stack the key's degrees 2, 5 and 1 in thirds and name the qualities
            var minor = label.EndsWith("Cm7");
            var courseQualities = new[] { 2, 5, 1 }.Select(degree =>
            {
                var steps = minor && degree != 1 ? Theory.HarmonicMinorSteps : minor ? Theory.NaturalMinorSteps : Theory.MajorSteps;
                var notes = Theory.SpellScale("C", steps);
                var chord = Enumerable.Range(0, 4).Select(k => Theory.PitchClassOf(notes[(degree - 1 + 2 * k) % 7])).ToArray();
                var intervals = chord.Select(pc => Theory.Mod12(pc - chord[0])).ToArray();
                return CanonicalNameOf(intervals);
            });
            var ga = chords.Select(symbol =>
            {
                var chord = Chord.FromSymbol(symbol);
                var root = chord.Root.PitchClass.Value;
                var intervals = chord.PitchClassSet.Select(pc => Theory.Mod12(pc.Value - root)).Order().ToArray();
                return CanonicalChordPatternCatalog.TryFindExact(intervals)?.Name ?? "(none)";
            });
            Row(label, string.Join(" ", courseQualities), string.Join(" ", ga));
            Line($"  numerals in C {(minor ? "minor" : "major")}: {string.Join(" ", chords.Select(c => Numeral(c, "C", minor ? Theory.NaturalMinorSteps : Theory.MajorSteps)))}; roots {string.Join(" ", chords.Select(c => Split(c).Root))}, each a fifth below the one before");
        }

        Title("Common tones between neighbouring chords (GA: PitchClassSet.Intersect)");
        Columns("chords", 14, 12);
        foreach (var (a, b) in new[] { ("G7", "C"), ("Dm7", "G7"), ("G7", "Cmaj7"), ("C", "Am"), ("C", "F#") })
        {
            var course = Theory.Format(Theory.PitchClasses(ChordId(a) & ChordId(b)));
            var ga = string.Join(" ", Chord.FromSymbol(a).PitchClassSet.Intersect(Chord.FromSymbol(b).PitchClassSet).OrderBy(pc => pc.Value));
            Row($"{a} {b}", course == "" ? "(none)" : course, ga == "" ? "(none)" : ga);
        }

        Title("Resolving V7 to I: each tone of G7 to the nearest tone of C");
        var c = Theory.PitchClasses(ChordId("C"));
        foreach (var (tone, name) in new[] { (7, "G (root)"), (11, "B (third, leading tone)"), (2, "D (fifth)"), (5, "F (seventh)") })
        {
            var moves = c.Select(target => (target, move: Theory.Mod12(target - tone) > 6 ? Theory.Mod12(target - tone) - 12 : Theory.Mod12(target - tone)))
                .GroupBy(m => Math.Abs(m.move)).OrderBy(g => g.Key).First()
                .Select(m => $"{Theory.PcName(m.target)} ({(m.move > 0 ? "+" : "")}{m.move})");
            Line($"  {name,-24} -> {string.Join(" or ", moves)}");
        }
        var g7 = Chord.FromSymbol("G7").PitchClassSet;
        Columns("tritone", 14, 12);
        Row("in G7", Theory.Icv(ChordId("G7"))[5], g7.IntervalClassVector.Tritonia);
        Row("in C", Theory.Icv(ChordId("C"))[5], Chord.FromSymbol("C").PitchClassSet.IntervalClassVector.Tritonia);

        Title("Finding the key: the course, then GA's PitchClassSet.ClosestDiatonicKey on all the notes");
        Columns("progression", 14, 18);
        var progressions = new[] { "C F G C", "G D Em C", "Dm7 G7 Cmaj7", "Am Dm E7 Am", "Am F C G", "C Am F G7" };
        foreach (var progression in progressions)
        {
            var chords = progression.Split(' ');
            var union = chords.Aggregate(0, (id, chord) => id | ChordId(chord));
            var set = PitchClassSet.FromId(union);
            Row(progression, CourseKey(chords), set.ClosestDiatonicKey);
            Line($"  notes {set}, GA normal form {set.ToNormalForm()}; GA compatible keys: {string.Join(", ", set.GetCompatibleKeys().Select(k => k.ToString()[7..]).DefaultIfEmpty("(none)"))}; roots only: {RootsOnlyKey(chords)}");
        }

        Title("Exercise solutions");
        Columns("question", 20, 14);
        Line($"1. F Gm C7 F in F major: {string.Join(" ", "F Gm C7 F".Split(' ').Select(ch => Numeral(ch, "F", Theory.MajorSteps)))}");
        Row("1. all in F major", "F Gm C7 F".Split(' ').All(ch => (ChordId(ch) & ~Theory.Transpose(Theory.FromSteps(Theory.MajorSteps), 5)) == 0),
            "F Gm C7 F".Split(' ').All(ch => Chord.FromSymbol(ch).PitchClassSet.IsSubsetOf(Key.Major.F.PitchClassSet)));
        var exercise2 = "Em Am B7 Em".Split(' ');
        Row("2. Em Am B7 Em", CourseKey(exercise2), PitchClassSet.FromId(exercise2.Aggregate(0, (id, ch) => id | ChordId(ch))).ClosestDiatonicKey);
        Line($"   roots only: {RootsOnlyKey(exercise2)}");
        Row("3. common A7 D", Theory.Format(Theory.PitchClasses(ChordId("A7") & ChordId("D"))),
            string.Join(" ", Chord.FromSymbol("A7").PitchClassSet.Intersect(Chord.FromSymbol("D").PitchClassSet)));
    }

    static string CanonicalNameOf(int[] intervals) => string.Join(",", intervals) switch
    {
        "0,4,7,11" => "major-7",
        "0,4,7,10" => "dominant-7",
        "0,3,7,10" => "minor-7",
        "0,3,6,10" => "half-diminished-7",
        "0,3,6,9" => "diminished-7",
        var other => other,
    };
}
