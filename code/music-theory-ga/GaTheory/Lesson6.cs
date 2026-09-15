using GA.Domain.Core.Primitives.Notes;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Harmony;
using GA.Domain.Core.Theory.Tonal;
using GA.Domain.Core.Theory.Tonal.Scales;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 6: the chords of a key, Roman numerals and harmonic functions
public static class Lesson6
{
    // Quality of a chord stacked in thirds, from its semitones above the root, with the name
    // GA's recognition catalog gives the same intervals
    static readonly Dictionary<string, (string Numeral, string Suffix, string Catalog)> Qualities = new()
    {
        ["0,4,7"] = ("upper", "", "major-triad"),
        ["0,3,7"] = ("lower", "m", "minor-triad"),
        ["0,3,6"] = ("lower°", "dim", "diminished-triad"),
        ["0,4,8"] = ("upper+", "aug", "augmented-triad"),
        ["0,4,7,11"] = ("upper7", "maj7", "major-7"),
        ["0,4,7,10"] = ("upper7", "7", "dominant-7"),
        ["0,3,7,10"] = ("lower7", "m7", "minor-7"),
        ["0,3,6,10"] = ("lowerø7", "m7b5", "half-diminished-7"),
        ["0,3,6,9"] = ("lower°7", "dim7", "diminished-7"),
        ["0,3,7,11"] = ("lower7", "mMaj7", "minor-major-7"),
        ["0,4,8,11"] = ("upper+7", "maj7#5", "augmented-major-7"),
    };

    static readonly string[] Numerals = ["I", "II", "III", "IV", "V", "VI", "VII"];

    // Scale-degree names (Open Music Theory): the seventh degree is the leading tone a half step
    // below the tonic, or the subtonic a whole step below
    static string DegreeName(int degree, int semitonesBelowTonic) => degree switch
    {
        1 => "Tonic", 2 => "Supertonic", 3 => "Mediant", 4 => "Subdominant", 5 => "Dominant", 6 => "Submediant",
        _ => semitonesBelowTonic == 1 ? "LeadingTone" : "Subtonic",
    };

    // Stack `size` thirds on each degree of a scale given as (note name, pitch class) pairs
    static (string Root, string Symbol, string Numeral, string Catalog)[] Stack(string[] notes, int size)
    {
        return [.. Enumerable.Range(0, 7).Select(degree =>
        {
            var chord = Enumerable.Range(0, size).Select(k => notes[(degree + 2 * k) % 7]).ToArray();
            var root = Theory.PitchClassOf(chord[0]);
            var key = string.Join(",", chord.Select(n => Theory.Mod12(Theory.PitchClassOf(n) - root)));
            var (numeral, suffix, catalog) = Qualities[key];
            var roman = numeral.StartsWith("upper") ? Numerals[degree] + numeral[5..] : Numerals[degree].ToLowerInvariant() + numeral[5..];
            return (chord[0], chord[0] + suffix, roman, catalog);
        })];
    }

    // GA: the same stacking on a collection of GA notes, named by CanonicalChordPatternCatalog
    static string[] GaStack(IReadOnlyList<Note> notes, int size) =>
        [.. Enumerable.Range(0, 7).Select(degree =>
        {
            var chord = Enumerable.Range(0, size).Select(k => notes[(degree + 2 * k) % 7]).ToArray();
            var root = chord[0].PitchClass.Value;
            var intervals = chord.Select(n => Theory.Mod12(n.PitchClass.Value - root)).ToArray();
            return $"{Ascii(chord[0])} {CanonicalChordPatternCatalog.TryFindExact(intervals)?.Name ?? "(none)"}";
        })];

    static string Ascii(object text) => text.ToString()!.Replace("♯", "#").Replace("♭", "b");

    static void Table(string title, string[] notes, IReadOnlyList<Note> gaNotes, int size, bool functions)
    {
        Title(title);
        Columns("numeral", 9, 32);
        var course = Stack(notes, size);
        var ga = GaStack(gaNotes, size);
        for (var degree = 1; degree <= 7; degree++)
        {
            var (root, _, numeral, catalog) = course[degree - 1];
            var belowTonic = Theory.Mod12(Theory.PitchClassOf(notes[0]) - Theory.PitchClassOf(notes[6]));
            var courseText = $"{root} {catalog}";
            var gaText = ga[degree - 1];
            if (functions)
            {
                courseText += $" {DegreeName(degree, belowTonic)}";
                gaText += $" {HarmonicFunctionExtensions.FromDegree(degree)}";
            }
            Row(numeral, courseText, gaText);
        }
    }

    public static void Run()
    {
        var cMajor = Theory.SpellScale("C", Theory.MajorSteps);
        Table("Triads of C major: numeral, root, quality, function", cMajor, [.. Key.Major.C.Notes], 3, functions: true);
        Line($"symbols: {string.Join(" ", Stack(cMajor, 3).Select(c => c.Symbol))}");

        Table("Seventh chords of C major", cMajor, [.. Key.Major.C.Notes], 4, functions: false);
        Line($"symbols: {string.Join(" ", Stack(cMajor, 4).Select(c => c.Symbol))}");

        var aMinor = Theory.SpellScale("A", Theory.NaturalMinorSteps);
        Table("Triads of A minor, natural minor", aMinor, [.. Key.Minor.Am.Notes], 3, functions: true);
        var aHarmonic = Theory.SpellScale("A", Theory.HarmonicMinorSteps);
        Table("Triads of A minor with the raised leading tone (harmonic minor)", aHarmonic, [.. Scale.HarmonicMinor], 3, functions: true);
        Line($"symbols: {string.Join(" ", Stack(aHarmonic, 3).Select(c => c.Symbol))}");

        Title("The triads of other keys, stacked on the course's notes and on GA's Key.Notes");
        Columns("key", 6, 44);
        foreach (var (n, minor) in new[] { (-3, false), (6, false), (-6, false), (4, true) })
        {
            var tonic = minor ? Theory.MinorTonic(n) : Theory.MajorTonic(n);
            var notes = Theory.SpellScale(tonic, minor ? Theory.NaturalMinorSteps : Theory.MajorSteps);
            Key key = minor ? new Key.Minor(n) : new Key.Major(n);
            var gaNotes = key.Notes.Select(Ascii).ToArray();
            Row($"{tonic}{(minor ? "m" : "")}", string.Join(" ", Stack(notes, 3).Select(c => c.Symbol)),
                string.Join(" ", Stack(gaNotes, 3).Select(c => c.Symbol)));
        }

        Title("Which triads belong to a key? (major, minor and diminished triads on 12 roots)");
        string[] roots = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];
        var triads = (from root in roots from suffix in new[] { "", "m", "dim" } select root + suffix).ToArray();
        foreach (var n in new[] { 1, -2 })
        {
            var scale = Theory.Transpose(Theory.FromSteps(Theory.MajorSteps), Theory.PitchClassOf(Theory.MajorTonic(n)));
            var course = triads.Where(t => (TriadId(t) & ~scale) == 0);
            var key = new Key.Major(n);
            var ga = triads.Where(t => Chord.FromSymbol(t).PitchClassSet.IsSubsetOf(key.PitchClassSet));
            Line($"{Theory.KeyName(n, false),-12} course: {string.Join(" ", course)}");
            Line($"{"",-12} GA:     {string.Join(" ", ga)}");
        }

        Title("Which keys contain a chord? (GA: PitchClassSet.GetCompatibleKeys)");
        Columns("chord", 6, 50);
        foreach (var symbol in new[] { "Dm", "G7", "Bdim", "E" })
        {
            var id = TriadOrSeventhId(symbol);
            var course = Enumerable.Range(-7, 15)
                .SelectMany(n => new[] { (n, false), (n, true) })
                .Where(k => (id & ~KeyId(k.Item1)) == 0)
                .OrderBy(k => Math.Abs(k.Item1)).ThenBy(k => k.Item1).ThenBy(k => k.Item2)
                .Select(k => Theory.KeyName(k.Item1, k.Item2)[7..]);
            var ga = Chord.FromSymbol(symbol).PitchClassSet.GetCompatibleKeys()
                .OrderBy(k => k.KeySignature.AccidentalCount).ThenBy(k => k.KeySignature.Value).ThenBy(k => k.KeyMode)
                .Select(k => Ascii(k)[7..]);
            Row(symbol, string.Join(" ", course), string.Join(" ", ga));
        }

        Title("Exercise solutions");
        Columns("question", 20, 36);
        var gMajor = Theory.SpellScale("G", Theory.MajorSteps);
        Row("1. G major triads", string.Join(" ", Stack(gMajor, 3).Select(c => c.Symbol)),
            string.Join(" ", Stack([.. Key.Major.G.Notes.Select(Ascii)], 3).Select(c => c.Symbol)));
        var dominantOfDMinor = Stack(Theory.SpellScale("D", Theory.HarmonicMinorSteps), 4)[4];
        Line($"2. degree 5 of D harmonic minor, stacked in four: {dominantOfDMinor.Symbol} ({dominantOfDMinor.Numeral})");
        Row("2. A7 pitch classes", Theory.Format(Theory.PitchClasses(TriadOrSeventhId(dominantOfDMinor.Symbol))), Chord.FromSymbol(dominantOfDMinor.Symbol).PitchClassSet);
        var mediant = Stack(Theory.SpellScale("Bb", Theory.MajorSteps), 3)[2];
        Row("3. iii of Bb major", $"{mediant.Root} {mediant.Catalog} {DegreeName(3, 1)}",
            $"{GaStack([.. Key.Major.Bb.Notes], 3)[2]} {HarmonicFunctionExtensions.FromDegree(3)}");
    }

    static int KeyId(int fifths) => Theory.Transpose(Theory.FromSteps(Theory.MajorSteps), Theory.PitchClassOf(Theory.MajorTonic(fifths)));

    // Minor keys share their relative major's pitch classes (natural minor)
    static int TriadId(string symbol) => TriadOrSeventhId(symbol);

    static int TriadOrSeventhId(string symbol)
    {
        var rootLength = symbol.Length > 1 && symbol[1] is '#' or 'b' ? 2 : 1;
        var tones = Lesson3.Chords.Single(c => c.Suffix == symbol[rootLength..]).Tones;
        var root = Theory.PitchClassOf(symbol[..rootLength]);
        return Theory.SetId(tones.Select(t => root + t.Semitones));
    }
}
