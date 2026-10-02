namespace GaAi;

using System.Text.Json;
using GaMcpServer.Tools;
using static Report;

// Lesson 20's questions to GaMcpServer's ga_generate_progression tool, CompositionTools.GaGenerateProgression.
// The file is compiled twice, like the tool: into GaAi against the pinned GA, and into GaMain
// against GA's main, where the tool is the same but the search ga_voice_leading_pair calls changed.
public static class ProgressionProbe
{
    // The nine templates, in the order of the tool's description, and the mode of their key
    public static readonly (string Name, bool Minor)[] Templates =
    [
        ("ii-V-I", false), ("circle-of-fifths", false), ("rhythm-changes-a", false), ("I-V-vi-IV", false),
        ("I-vi-IV-V", false), ("canon", false), ("12-bar-blues", false), ("minor-vamp", true), ("andalusian", true),
    ];

    // The keys a textbook writes: 15 major key signatures, 15 minor ones
    static readonly string[] MajorKeys = ["C", "G", "D", "A", "E", "B", "F#", "C#", "F", "Bb", "Eb", "Ab", "Db", "Gb", "Cb"];
    static readonly string[] MinorKeys = ["A", "E", "B", "F#", "C#", "G#", "D#", "A#", "D", "G", "C", "F", "Bb", "Eb", "Ab"];

    public sealed record Chord(string Roman, string Symbol, int Degree, int[] Pcs);

    // The tool's answer: its chords, or its error
    public static (List<Chord> Chords, string? Error, int Characters) Generate(string root, string template, int? length = null)
    {
        var json = CompositionTools.GaGenerateProgression(root, template, length);
        using var doc = JsonDocument.Parse(json);
        var r = doc.RootElement;
        // The indented JSON ends its lines with the system's newline: one character each, as on Linux
        var characters = json.ReplaceLineEndings("\n").Length;
        if (r.TryGetProperty("error", out var error)) return ([], error.GetString(), characters);
        return ([.. r.GetProperty("chords").EnumerateArray().Select(c => new Chord(
            c.GetProperty("roman").GetString()!, c.GetProperty("symbol").GetString()!, c.GetProperty("degree").GetInt32(),
            [.. c.GetProperty("pitchClasses").EnumerateArray().Select(p => p.GetInt32())]))], null, characters);
    }

    // ---- A textbook's spelling ----

    const string Letters = "CDEFGAB";
    static readonly int[] Natural = [0, 2, 4, 5, 7, 9, 11];

    static int NotePc(string note) =>
        (Natural[Letters.IndexOf(note[0])] + note.Skip(1).Sum(c => c == '#' ? 1 : c == 'b' ? -1 : 0) + 12) % 12;

    static int RomanDegree(string roman)
    {
        var numeral = new string(roman.TrimStart('b', '#').TakeWhile(c => "IViv".Contains(c)).ToArray()).ToUpperInvariant();
        return numeral switch { "I" => 1, "II" => 2, "III" => 3, "IV" => 4, "V" => 5, "VI" => 6, "VII" => 7, _ => throw new ArgumentException(roman) };
    }

    // The chord's root as a textbook writes it in the key: the letter of the Roman numeral's degree,
    // with the accidental that reaches the chord's pitch class
    static string TextbookRoot(string key, string roman, int offset)
    {
        var letter = (Letters.IndexOf(key[0]) + RomanDegree(roman) - 1) % 7;
        var diff = ((NotePc(key) + offset - Natural[letter]) % 12 + 12) % 12;
        return Letters[letter] + diff switch { 0 => "", 1 => "#", 2 => "##", 11 => "b", 10 => "bb", _ => "?" };
    }

    static (string Root, string Quality) Split(string symbol)
    {
        var n = symbol.Length > 1 && symbol[1] is '#' or 'b' ? 2 : 1;
        return (symbol[..n], symbol[n..]);
    }

    static readonly Dictionary<string, int[]> Qualities = new()
    {
        [""] = [0, 4, 7], ["m"] = [0, 3, 7], ["7"] = [0, 4, 7, 10], ["m7"] = [0, 3, 7, 10], ["maj7"] = [0, 4, 7, 11],
    };

    // ---- The questions ----

    public static void TemplatesTable(string where)
    {
        Title($"The nine templates in the keys a textbook writes, {where}, against the textbook's spelling");
        int[] w = [18, 7, 6, 8, 15];
        Row(w, "template", "mode", "keys", "chords", "spelled right", "pitch classes right");
        int chords = 0, spelled = 0, pcsRight = 0;
        var wrong = new SortedDictionary<string, Dictionary<string, int>>(StringComparer.Ordinal);
        var keyOrder = new List<string>();
        foreach (var (name, minor) in Templates)
        {
            var keys = minor ? MinorKeys : MajorKeys;
            int c = 0, s = 0, p = 0;
            foreach (var key in keys)
            {
                var (list, error, _) = Generate(key, name);
                if (error is not null) throw new InvalidOperationException($"{key} {name}: {error}");
                foreach (var chord in list)
                {
                    c++;
                    var (root, quality) = Split(chord.Symbol);
                    var textbook = TextbookRoot(key, chord.Roman, chord.Degree) + quality;
                    if (textbook == chord.Symbol) s++;
                    else
                    {
                        var label = $"{key} {(minor ? "minor" : "major")}";
                        if (!wrong.ContainsKey(label)) { wrong[label] = []; keyOrder.Add(label); }
                        var k = $"{chord.Symbol} for {textbook}";
                        wrong[label][k] = wrong[label].GetValueOrDefault(k) + 1;
                    }

                    var expected = Qualities[quality].Select(o => (NotePc(root) + o) % 12).Order().ToArray();
                    if (expected.SequenceEqual(chord.Pcs)) p++;
                }
            }

            Row(w, name, minor ? "minor" : "major", keys.Length, c, s, p);
            (chords, spelled, pcsRight) = (chords + c, spelled + s, pcsRight + p);
        }

        Line($"chords {chords}: spelled right {spelled}, pitch classes right {pcsRight}");
        Line("the chords spelled otherwise, as the tool writes them, with the textbook's spelling and their count:");
        foreach (var label in keyOrder)
            Line($"  {label,-10} " + string.Join(", ", wrong[label].Select(x => $"{x.Key} {x.Value}")));
    }

    // GA's own twelve-key tables, from ChordProgressions.yaml, read line by line
    public static void YamlTables(string yamlPath, string where)
    {
        Title($"The tool against the twelve-key tables of GA's ChordProgressions.yaml, {where}");
        var lines = File.ReadAllLines(yamlPath);
        var start = Array.FindIndex(lines, l => l.StartsWith("TransposeTables:"));
        var tables = new List<(string Name, List<(string Key, string[] Chords)> Rows)>();
        string? key = null;
        string? i = null, iv = null;
        foreach (var raw in lines.Skip(start + 1))
        {
            var l = raw.Trim();
            if (raw.Length > 0 && !char.IsWhiteSpace(raw[0])) break;
            if (l.StartsWith("- Name:")) { tables.Add((Unquote(l["- Name:".Length..]), [])); continue; }
            if (l.StartsWith("- Key:")) { key = Unquote(l["- Key:".Length..]); continue; }
            if (l.StartsWith("Chords:"))
                tables[^1].Rows.Add((key!, [.. l["Chords:".Length..].Trim().Trim('[', ']').Split(',').Select(Unquote)]));
            if (l.StartsWith("I:")) i = Unquote(l[2..]);
            if (l.StartsWith("IV:")) iv = Unquote(l[3..]);
            if (l.StartsWith("V:")) tables[^1].Rows.Add((key!, [i!, iv!, Unquote(l[2..])]));
        }

        // Each table and the template that answers it; the blues table lists I, IV and V
        (string Table, string Template, string[]? Romans)[] pairs =
        [
            ("ii–V–I (Major) — 12 keys", "ii-V-I", null),
            ("Pop I–V–vi–IV — 12 keys (triads)", "I-V-vi-IV", null),
            ("12-Bar Blues — common guitar keys", "12-bar-blues", ["I7", "IV7", "V7"]),
        ];
        int[] w = [36, 15, 6, 13];
        Row(w, "table", "template", "keys", "same chords", "spelled otherwise by a textbook");
        foreach (var (table, template, romans) in pairs)
        {
            var rows = tables.Single(t => t.Name == table).Rows;
            var same = 0;
            var textbookOff = new List<string>();
            foreach (var (k, chords) in rows)
            {
                var answer = Generate(k, template).Chords;
                var tool = romans is null ? answer.Select(c => c.Symbol).ToArray()
                    : [.. romans.Select(r => answer.First(c => c.Roman == r).Symbol)];
                if (tool.SequenceEqual(chords)) same++;
                var picked = romans is null ? answer : [.. romans.Select(r => answer.First(c => c.Roman == r))];
                var off = picked.Where(c => TextbookRoot(k, c.Roman, c.Degree) + Split(c.Symbol).Quality != c.Symbol).ToList();
                if (off.Count > 0)
                    textbookOff.Add($"{k}: {string.Join(" ", chords)}, textbook " +
                        string.Join(" ", picked.Select(c => TextbookRoot(k, c.Roman, c.Degree) + Split(c.Symbol).Quality)));
            }

            Row(w, table, template, rows.Count, same, textbookOff.Count == 0 ? "none" : string.Join("; ", textbookOff));
        }

        static string Unquote(string s) => s.Trim().Trim('"');
    }

    public static void RootsTable(string where)
    {
        Title($"The roots the tool reads, {where}");
        (string Root, string Template)[] asks =
        [
            ("C", "I-V-vi-IV"), ("c", "I-V-vi-IV"), ("B", "I-V-vi-IV"), ("b", "I-V-vi-IV"), ("Bb", "I-V-vi-IV"),
            ("bb", "I-V-vi-IV"), ("B♭", "I-V-vi-IV"), ("Cb", "I-V-vi-IV"), ("E#", "I-V-vi-IV"),
            ("F major", "I-V-vi-IV"), ("D minor", "I-V-vi-IV"), ("D minor", "andalusian"), ("Dm", "andalusian"),
            ("C", "andalusian"), ("C7b9", "andalusian"),
            ("Cmaj7", "ii-V-I"),
        ];
        int[] w = [10, 14];
        Row(w, "root", "template", "chords, or the error");
        foreach (var (root, template) in asks)
        {
            var (chords, error, _) = Generate(root, template);
            Row(w, root, template, error ?? string.Join(" ", chords.Select(c => c.Symbol)));
        }
    }

    public static void LengthTable(string where)
    {
        Title($"The length, {where}");
        int?[] lengths = [null, 0, -1, 4, 13, 100000];
        int[] w = [8, 14, 9];
        Row(w, "length", "template", "chords", "last chord, characters of JSON");
        foreach (var length in lengths)
        {
            var (chords, error, characters) = Generate("C", "12-bar-blues", length);
            Row(w, length, "12-bar-blues", error ?? $"{chords.Count}", $"{chords[^1].Roman} {chords[^1].Symbol}, {characters}");
        }
    }

    // The tool's own note: compose by chaining ga_voice_leading_pair over consecutive chords
    public static void StitchTable(string where)
    {
        Title($"Each template stitched with ga_voice_leading_pair, in C major or A minor, {where}");
        int[] w = [18, 7, 10, 18, 19];
        Row(w, "template", "chords", "moves", "first pairs meet", "sum of first pairs", "least joined path");
        int junctions = 0, meet = 0, reached = 0;
        var example = new List<string>();
        foreach (var (name, minor) in Templates)
        {
            var chords = Generate(minor ? "A" : "C", name).Chords.Select(c => c.Symbol).ToList();
            var firsts = chords.Zip(chords.Skip(1), (a, b) => VoiceLeadingPairProbe.Ask(a, b).Pairs[0]).ToList();
            var m = firsts.Zip(firsts.Skip(1)).Count(x => x.First.To.Diagram == x.Second.From.Diagram);
            var sum = firsts.Sum(p => p.Distance);

            // The least total motion of one voicing per chord, chosen among the same 15 candidates
            var candidates = chords.Select(c => VoiceLeadingPairProbe.Candidates(c)).ToList();
            var best = candidates[0].Select(_ => 0.0).ToArray();
            var from = new List<int[]>();
            for (var k = 1; k < chords.Count; k++)
            {
                var steps = candidates[k].Select(b => candidates[k - 1]
                    .Select((a, i) => (Total: best[i] + VoiceLeadingPairProbe.Distance(a.Midi, b.Midi), I: i)).MinBy(t => t.Total)).ToList();
                best = [.. steps.Select(t => t.Total)];
                from.Add([.. steps.Select(t => t.I)]);
            }

            var least = best.Min();
            if (name == "I-V-vi-IV")
            {
                var path = new List<int> { Array.IndexOf(best, least) };
                for (var k = from.Count - 1; k >= 0; k--) path.Insert(0, from[k][path[0]]);
                example.Add($"{name}, the first pairs: " + string.Join("; ",
                    firsts.Select(p => $"{p.From.Chart} {p.From.Name} → {p.To.Chart} {p.To.Name}, {p.Distance}")));
                example.Add($"{name}, the least joined path: " + string.Join(" → ",
                    path.Select((c, k) => $"{candidates[k][c].Chart} {candidates[k][c].Name}")) + $", {least}");
            }

            Row(w, name, chords.Count, firsts.Count, $"{m} of {firsts.Count - 1}", $"{sum}", $"{least}");
            junctions += firsts.Count - 1;
            meet += m;
            if (least == sum) reached++;
        }

        Line($"places where two first pairs should meet {junctions}: they meet at {meet}; " +
             $"templates whose least joined path moves as little as the sum of first pairs {reached} of {Templates.Length}");
        foreach (var line in example) Line(line);
    }
}
