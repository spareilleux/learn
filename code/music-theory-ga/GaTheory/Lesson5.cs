using GA.Domain.Core.Primitives.Notes;
using GA.Domain.Core.Theory.Tonal;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 5: keys, key signatures, relative and parallel keys, the circle of fifths
public static class Lesson5
{
    // GA prints sharps and flats as ♯ and ♭ in some types and as # and b in others: use # and b
    static string Ascii(object? text) => (text?.ToString() ?? "(null)").Replace("♯", "#").Replace("♭", "b");

    static string Signed(int fifths) => fifths > 0 ? $"+{fifths}" : $"{fifths}";

    public static void Run()
    {
        Title("Key signatures: major and relative minor tonic, accidentals");
        Columns("fifths", 7, 34);
        for (var n = -7; n <= 7; n++)
        {
            var course = $"{Theory.MajorTonic(n)} {Theory.MinorTonic(n)}m {string.Join(" ", Theory.SignatureAccidentals(n))}";
            var ga = $"{Ascii(new Key.Major(n).Root)} {Ascii(new Key.Minor(n).Root)}m {Ascii(KeySignature.FromValue(n).AccidentedNotes)}";
            Row(Signed(n), course.TrimEnd(), ga.TrimEnd());
        }

        Title("The notes of a key: one letter per degree");
        Columns("key", 10, 24);
        foreach (var (n, minor) in new[] { (-3, false), (4, false), (6, false), (-7, false), (-1, true), (5, true), (-5, true), (7, true) })
        {
            var tonic = minor ? Theory.MinorTonic(n) : Theory.MajorTonic(n);
            var course = Theory.SpellScale(tonic, minor ? Theory.NaturalMinorSteps : Theory.MajorSteps);
            Key key = minor ? new Key.Minor(n) : new Key.Major(n);
            Row($"{tonic}{(minor ? "m" : "")}", string.Join(" ", course), Ascii(key.Notes));
        }

        Title("Relative and parallel keys (GA column: the expressions of GA's MCP key tools)");
        Columns("key", 16, 12);
        foreach (var (n, minor) in new[] { (0, false), (-4, false), (0, true), (1, true) })
        {
            Key key = minor ? new Key.Minor(n) : new Key.Major(n);
            var name = Theory.KeyName(n, minor);
            // relative: same signature, other mode
            Row($"relative {name[7..]}", Theory.KeyName(n, !minor), RelativeAsMcp(key));
            // parallel: same tonic, other mode, three fifths away
            Row($"parallel {name[7..]}", Theory.KeyName(minor ? n + 3 : n - 3, !minor), ParallelAsMcp(key));
        }

        Title("The circle of fifths: clockwise one fifth up and one more sharp");
        var sharps = Enumerable.Range(0, 8).Select(n => Theory.MajorTonic(n));
        var flats = Enumerable.Range(0, 8).Select(n => Theory.MajorTonic(-n));
        Line($"course sharps  {string.Join(" ", sharps)}");
        Line($"GA sharps      {string.Join(" ", Enumerable.Range(0, 8).Select(n => Ascii(new Key.Major(n).Root)))}");
        Line($"course flats   {string.Join(" ", flats)}");
        Line($"GA flats       {string.Join(" ", Enumerable.Range(0, 8).Select(n => Ascii(new Key.Major(-n).Root)))}");
        Columns("pair", 16, 10);
        foreach (var (a, b) in new[] { (5, -7), (6, -6), (7, -5) })
        {
            var same = Theory.PitchClassOf(Theory.MajorTonic(a)) == Theory.PitchClassOf(Theory.MajorTonic(b));
            var gaSame = new Key.Major(a).PitchClassSet.Id == new Key.Major(b).PitchClassSet.Id;
            Row($"{Theory.MajorTonic(a)} = {Theory.MajorTonic(b)}", same ? "same" : "differ", gaSame ? "same" : "differ");
        }
        Columns("neighbours", 16, 10);
        foreach (var (a, b) in new[] { (0, 1), (0, -1), (0, 2), (0, 6) })
        {
            var common = Theory.PitchClasses(Theory.Transpose(Theory.FromSteps(Theory.MajorSteps), Theory.PitchClassOf(Theory.MajorTonic(a))))
                .Intersect(Theory.PitchClasses(Theory.Transpose(Theory.FromSteps(Theory.MajorSteps), Theory.PitchClassOf(Theory.MajorTonic(b))))).Count();
            var gaCommon = new Key.Major(a).PitchClassSet.Intersect(new Key.Major(b).PitchClassSet).Count();
            Row($"{Theory.MajorTonic(a)} and {Theory.MajorTonic(b)}", $"{common} common", $"{gaCommon} common");
        }

        Title("Closely related keys: signatures within one accidental");
        Columns("key", 10, 44);
        foreach (var (n, minor) in new[] { (0, false), (-1, true), (4, false) })
        {
            var course = new[] { n - 1, n, n + 1 }
                .SelectMany(k => new[] { (k, false), (k, true) })
                .Where(k => k != (n, minor) && Math.Abs(k.Item1) <= 7)
                .Select(k => Theory.KeyName(k.Item1, k.Item2)[7..]);
            Key key = minor ? new Key.Minor(n) : new Key.Major(n);
            var ga = Key.Items
                .Where(k => Math.Abs(k.KeySignature.Value - key.KeySignature.Value) <= 1 && k != key)
                .OrderBy(k => k.KeySignature.Value).ThenBy(k => k.KeyMode)
                .Select(k => k.ToString()[7..]);
            Row(Theory.KeyName(n, minor)[7..], string.Join(" ", course), string.Join(" ", ga));
        }
        Columns("MCP tool", 26, 20);
        Row("get_neighboring_keys C", "Key of F, Key of G", Try(() => NeighboursAsMcp(Key.Major.C)));

        Title("Surprises found while writing this lesson");
        Columns("call", 30, 12);
        Row("Key.Major.C.GetInterval(E)", "M3", Try(() => Key.Major.C.GetInterval(Note.Accidented.Parse("E", null))));
        Row("Key.Major.G.GetInterval(F#)", "M7", Try(() => Key.Major.G.GetInterval(Note.Accidented.Parse("F#", null))));
        Row("Key.Major.TryParse(\"H\")", "False", Try(() => Key.Major.TryParse("H", out _)));
        Row("Key.Minor.TryParse(\"A\")", "Key of Am", Try(() => Key.Minor.TryParse("A", out var am) ? am : "False"));

        Title("Exercise solutions");
        Columns("question", 22, 32);
        Row("1. E major", $"{string.Join(" ", Theory.SignatureAccidentals(4))} / {string.Join(" ", Theory.SpellScale("E", Theory.MajorSteps))}",
            $"{Ascii(Key.Major.E.KeySignature)} / {Ascii(Key.Major.E.Notes)}");
        Row("2. relative of Ab", Theory.KeyName(-4, true), RelativeAsMcp(Key.Major.Ab));
        Row("2. parallel of Ab", $"{Theory.KeyName(-7, true)} (7 flats)", ParallelAsMcp(Key.Major.Ab));
        var dMinorRelated = new[] { -2, -1, 0 }.SelectMany(k => new[] { (k, false), (k, true) })
            .Where(k => k != (-1, true)).Select(k => Theory.KeyName(k.Item1, k.Item2)[7..]);
        var gaDMinorRelated = Key.Items.Where(k => Math.Abs(k.KeySignature.Value - Key.Minor.Dm.KeySignature.Value) <= 1 && k != Key.Minor.Dm)
            .OrderBy(k => k.KeySignature.Value).ThenBy(k => k.KeyMode).Select(k => k.ToString()[7..]);
        Row("3. related to Dm", string.Join(" ", dMinorRelated), string.Join(" ", gaDMinorRelated));
    }

    // KeyTools.GetRelativeKey and GetParallelKey build the same key: the other mode on the same signature
    static string RelativeAsMcp(Key key) => (key.KeyMode switch
    {
        KeyMode.Major => (Key)new Key.Minor(key.KeySignature),
        _ => new Key.Major(key.KeySignature),
    }).ToString();

    static string ParallelAsMcp(Key key) => (key.KeyMode switch
    {
        KeyMode.Major => (Key)new Key.Minor(key.KeySignature),
        _ => new Key.Major(key.KeySignature),
    }).ToString();

    // KeyTools.GetNeighboringKeys looks the key up again by the name of its key signature
    static string NeighboursAsMcp(Key key)
    {
        int Position(string keyName)
        {
            var found = Key.Items.FirstOrDefault(k => k.ToString() == keyName)
                        ?? throw new InvalidOperationException($"Key not found: {keyName}");
            return found.KeySignature.Value;
        }

        var position = Position(key.KeySignature.ToString());
        return $"{position}";
    }
}
