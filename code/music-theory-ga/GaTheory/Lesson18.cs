using System.Collections;
using System.Globalization;
using System.Reflection;
using GA.Business.Config;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Skills;
using GA.Business.ML.Search;
using GA.Domain.Core.Theory.Tonal.Modes;
using GA.Domain.Core.Theory.Tonal.Modes.Diatonic;
using GA.Domain.Core.Theory.Tonal.Modes.Pentatonic;
using GA.Domain.Core.Theory.Tonal.Modes.Symmetric;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 16 of the course, run as `l18`: arpeggios, the scale that goes with each chord, the ga_arpeggio_suggestions tool,
// the two skills of GA's chatbot that pair chords with scales and judge a note over a chord, and the improvisation
// entries of GA's config
public static class Lesson18
{
    // ---- The course's side

    static readonly string[] MajorNames = ["Ionian", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Aeolian", "Locrian"];
    static readonly int[] MelodicMinorSteps = [2, 1, 2, 2, 2, 2, 1];
    static readonly int[] MajorOffsets = [0, 2, 4, 5, 7, 9, 11];

    static int[] Rotate(int[] steps, int k) => [.. Enumerable.Range(0, steps.Length).Select(i => steps[(k + i) % steps.Length])];

    // The semitones of each degree above the tonic: 0, then the steps added up
    static int[] Offsets(int[] steps) => [.. Enumerable.Range(0, steps.Length).Select(i => steps.Take(i).Sum())];

    // The textbook scales, as steps, under the names GA's tool and skills use (Wikipedia, "Chord-scale system", "Jazz scale")
    static readonly Dictionary<string, int[]> Scales = new()
    {
        ["Ionian (major)"] = Rotate(Theory.MajorSteps, 0),
        ["Major scale of the chord root"] = Rotate(Theory.MajorSteps, 0),
        ["Dorian"] = Rotate(Theory.MajorSteps, 1),
        ["Phrygian"] = Rotate(Theory.MajorSteps, 2),
        ["Lydian"] = Rotate(Theory.MajorSteps, 3),
        ["Mixolydian"] = Rotate(Theory.MajorSteps, 4),
        ["Aeolian (minor)"] = Rotate(Theory.MajorSteps, 5),
        ["Aeolian (natural minor)"] = Rotate(Theory.MajorSteps, 5),
        ["Locrian"] = Rotate(Theory.MajorSteps, 6),
        ["Melodic Minor"] = Rotate(MelodicMinorSteps, 0),
        ["Lydian Augmented"] = Rotate(MelodicMinorSteps, 2),
        ["Lydian Dominant"] = Rotate(MelodicMinorSteps, 3),
        ["Mixolydian b6"] = Rotate(MelodicMinorSteps, 4),
        ["Locrian #2"] = Rotate(MelodicMinorSteps, 5),
        ["Altered (Super Locrian)"] = Rotate(MelodicMinorSteps, 6),
        ["Phrygian Dominant"] = Rotate(Theory.HarmonicMinorSteps, 4),
        ["Half-Whole Diminished"] = [1, 2, 1, 2, 1, 2, 1, 2],
        ["Whole-Half Diminished"] = [2, 1, 2, 1, 2, 1, 2, 1],
        ["Whole Tone"] = [2, 2, 2, 2, 2, 2],
        ["Major Pentatonic"] = [2, 2, 3, 2, 3],
        ["Minor Pentatonic"] = [3, 2, 2, 3, 2],
    };

    static HashSet<int> ScaleOn(int rootPc, string name) => [.. Offsets(Scales[name]).Select(o => Theory.Mod12(rootPc + o))];

    // The interval of a degree above the tonic, written as the tool writes it: R, m2, M2, ..., A4, d5, ..., M7
    static string IntervalName(int degreeIndex, int semitones)
    {
        if (degreeIndex == 0) return "R";
        var difference = semitones - MajorOffsets[degreeIndex];
        var perfect = degreeIndex is 3 or 4;
        var quality = (perfect, difference) switch
        {
            (true, 0) => "P", (true, 1) => "A", (true, -1) => "d",
            (false, 0) => "M", (false, -1) => "m", (false, 1) => "A", (false, -2) => "d",
            _ => "?",
        };
        return $"{quality}{degreeIndex + 1}";
    }

    static string Intervals(int[] offsets) => string.Join(", ", offsets.Select((o, i) => IntervalName(i, o)));

    // The quality of the seventh chord built from a third, a fifth and a seventh above its root
    static string SeventhSuffix(int third, int fifth, int seventh) => (third, fifth, seventh) switch
    {
        (4, 7, 11) => "maj7",
        (3, 7, 10) => "m7",
        (4, 7, 10) => "7",
        (3, 6, 10) => "m7b5",
        (3, 7, 11) => "mMaj7",
        (4, 8, 11) => "maj7#5",
        (3, 6, 9) => "dim7",
        _ => "?",
    };

    // The seventh chord on each degree of a scale, thirds stacked within it: (root, symbol, the four notes)
    static List<(string Root, string Symbol, string[] Notes)> Sevenths(string tonic, int[] steps)
    {
        var scale = Theory.SpellScale(tonic, steps);
        var offsets = Offsets(steps);
        int Above(int i, int j) => offsets[(i + j) % 7] + ((i + j) >= 7 ? 12 : 0) - offsets[i];
        return [.. Enumerable.Range(0, 7).Select(i =>
            (scale[i], scale[i] + SeventhSuffix(Above(i, 2), Above(i, 4), Above(i, 6)),
             new[] { scale[i], scale[(i + 2) % 7], scale[(i + 4) % 7], scale[(i + 6) % 7] }))];
    }

    static string Pretty(string notes) => notes.Replace("#", "♯").Replace("b", "♭");

    static readonly string[] OnC = ["C", "D♭", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"];

    // The course's reading of the chord symbols of section 3: a root and one of five qualities, spelled from the root
    static (string Root, string[] Notes) Chord(string symbol)
    {
        var rootLength = symbol.Length > 1 && symbol[1] is '#' or 'b' ? 2 : 1;
        var root = symbol[..rootLength];
        (int Degree, int Semitones)[] tones = symbol[rootLength..] switch
        {
            "" => [(1, 0), (3, 4), (5, 7)],
            "m" => [(1, 0), (3, 3), (5, 7)],
            "7" => [(1, 0), (3, 4), (5, 7), (7, 10)],
            "m7" => [(1, 0), (3, 3), (5, 7), (7, 10)],
            "maj7" => [(1, 0), (3, 4), (5, 7), (7, 11)],
            var quality => throw new FormatException(quality),
        };
        return (root, [.. tones.Select(t => Theory.Spell(root, t.Degree, t.Semitones))]);
    }

    static string Outside(IEnumerable<string> notes, HashSet<int> scale)
    {
        var outside = notes.Where(n => !scale.Contains(Theory.PitchClassOf(n))).Select(Pretty).ToList();
        return outside.Count == 0 ? "-" : string.Join(" ", outside);
    }

    // The chords of section 4, written on C, with the notes the course gives each (Wikipedia, "Chord names and symbols
    // (popular music)" and "Jazz chord")
    static readonly (string Symbol, string Notes)[] Symbols =
    [
        ("C", "C E G"), ("Cm", "C Eb G"), ("C6", "C E G A"), ("C69", "C E G A D"), ("Cadd9", "C E G D"),
        ("Csus2", "C D G"), ("Csus4", "C F G"), ("C5", "C G"),
        ("Cmaj7", "C E G B"), ("CM7", "C E G B"), ("Cmaj9", "C E G B D"), ("Cmaj7#11", "C E G B F#"), ("Cmaj7#5", "C E G# B"),
        ("C7", "C E G Bb"), ("C9", "C E G Bb D"), ("C13", "C E G Bb D A"), ("C7sus4", "C F G Bb"), ("C7#11", "C E G Bb F#"),
        ("C7b9", "C E G Bb Db"), ("C7#9", "C E G Bb D#"), ("C7b13", "C E G Bb Ab"), ("C7#5", "C E G# Bb"), ("C7+5", "C E G# Bb"),
        ("Caug", "C E G#"),
        ("Cm7", "C Eb G Bb"), ("Cm9", "C Eb G Bb D"), ("Cm6", "C Eb G A"), ("CmMaj7", "C Eb G B"), ("Cm7b5", "C Eb Gb Bb"),
        ("Cdim", "C Eb Gb"), ("Cdim7", "C Eb Gb Bbb"),
    ];

    // ---- ga_arpeggio_suggestions, read as text: GaMcpServer/Tools/GuitaristProblemTools.cs is not compiled, since it needs
    // the MCP and F# packages of GA's server; the course reads its tables and applies lines 425 to 486 to them

    static string Declaration(string[] source, string name) => source.First(line => line.Contains($" {name} =", StringComparison.Ordinal));

    static int[] IntArray(string[] source, string name)
    {
        var line = Declaration(source, name);
        var open = line.IndexOf('[', line.IndexOf('='));
        return [.. line[(open + 1)..line.LastIndexOf(']')].Split(',').Select(s => int.Parse(s.Trim(), CultureInfo.InvariantCulture))];
    }

    static string[] StringArray(string[] source, string name) =>
        [.. Declaration(source, name).Split('=', 2)[1].Split('"').Where((_, i) => i % 2 == 1)];

    // The rows of one of the tool's two tables: ("maj7",  "Ionian (major)",     "R, M2, M3, P4, P5, M6, M7"),
    static List<(string Arpeggio, string Mode, string Notes)> Table(string[] source, string name)
    {
        var start = Array.FindIndex(source, line => line.Contains($"{name} =", StringComparison.Ordinal));
        var rows = new List<(string, string, string)>();
        for (var i = start + 1; !source[i].Trim().StartsWith("];", StringComparison.Ordinal); i++)
        {
            var parts = source[i].Split('"');
            if (parts.Length >= 7) rows.Add((parts[1], parts[3], parts[5]));
        }
        return rows;
    }

    // GuitaristHelpers.NoteToSemitone: ["C"]  = 0,  ["C#"] = 1,  ["Db"] = 1,
    static Dictionary<string, int> NoteToSemitone(string[] source)
    {
        var map = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
        var start = Array.FindIndex(source, line => line.Contains("NoteToSemitone =", StringComparison.Ordinal));
        for (var i = start + 1; !source[i].Trim().StartsWith("};", StringComparison.Ordinal); i++)
        {
            foreach (var entry in source[i].Split(',').Select(s => s.Trim()).Where(s => s.StartsWith("[\"", StringComparison.Ordinal)))
            {
                map[entry.Split('"')[1]] = int.Parse(entry[(entry.IndexOf('=') + 1)..].Trim(), CultureInfo.InvariantCulture);
            }
        }
        return map;
    }

    // The three strings the tool returns for a chord outside the key (lines 469 to 473)
    static (string Suffix, string Mode, string Notes) Chromatic(string[] source)
    {
        var at = Array.FindIndex(source, line => line.Contains("scaleDegree = \"chromatic\"", StringComparison.Ordinal));
        string Quoted(string line) => line.Split('"')[1];
        return (Quoted(source[at + 1]), Quoted(source[at + 2]), Quoted(source[at + 3]));
    }

    sealed record Tool(
        List<(string Arpeggio, string Mode, string Notes)> Major, List<(string Arpeggio, string Mode, string Notes)> Minor,
        int[] MajorOffsets, int[] MinorOffsets, string[] MajorRomans, string[] MinorRomans,
        Dictionary<string, int> Notes, (string Suffix, string Mode, string Notes) Chromatic);

    static Tool ReadTool(string path)
    {
        var source = File.ReadAllLines(path);
        return new(Table(source, "MajorDegreeModes"), Table(source, "MinorDegreeModes"),
            IntArray(source, "MajorOffsets"), IntArray(source, "MinorOffsets"),
            StringArray(source, "MajorRomans"), StringArray(source, "MinorRomans"),
            NoteToSemitone(source), Chromatic(source));
    }

    // GuitaristHelpers.ChordRootPc: the first two characters if they name a note, else the first one
    static int RootPc(Tool tool, string symbol)
    {
        if (string.IsNullOrWhiteSpace(symbol)) return -1;
        if (symbol.Length >= 2 && tool.Notes.TryGetValue(symbol[..2], out var two)) return two;
        return tool.Notes.TryGetValue(symbol[..1], out var one) ? one : -1;
    }

    // Lines 425 to 431 and 448 to 486, for a request that names its key: the key's first word is the tonic, its second the mode
    static (string Key, List<(string Chord, string Degree, string Arpeggio, string Mode)> Rows) Suggest(Tool tool, string[] chords, string key)
    {
        var parts = key.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
        var keyName = parts.Length >= 1 ? parts[0] : "C";
        var modeName = parts.Length >= 2 ? parts[1].ToLowerInvariant() : "major";
        var keyPc = RootPc(tool, keyName);
        if (keyPc < 0) keyPc = 0;
        var isMinor = modeName.Equals("minor", StringComparison.OrdinalIgnoreCase);
        var offsets = isMinor ? tool.MinorOffsets : tool.MajorOffsets;
        var romans = isMinor ? tool.MinorRomans : tool.MajorRomans;
        var table = isMinor ? tool.Minor : tool.Major;
        var rows = chords.Select(chord =>
        {
            var chordPc = RootPc(tool, chord);
            if (chordPc < 0) return (chord, "?", "?", "unknown");
            var degree = Array.FindIndex(offsets, o => (keyPc + o) % 12 == chordPc);
            if (degree < 0) return (chord, "chromatic", chord + tool.Chromatic.Suffix, tool.Chromatic.Mode);
            return (chord, romans[degree], chord + table[degree].Arpeggio, table[degree].Mode);
        }).ToList();
        return ($"{keyName} {modeName}", rows);
    }

    // ---- GA's side

    static readonly MethodInfo ScalesFor =
        typeof(ImprovisationSkill).GetMethod("ScalesFor", BindingFlags.NonPublic | BindingFlags.Static)!;

    // ImprovisationSkill keeps ScalesFor and its Scale record private: the names of the scales it returns, best first
    static List<string> ScaleNames(string symbol)
    {
        var scales = (IEnumerable)ScalesFor.Invoke(null, [ImprovisationSkill.InferQuality(symbol)])!;
        return [.. scales.Cast<object>().Select(s => (string)s.GetType().GetProperty("Name")!.GetValue(s)!)];
    }

    // A GA mode as the semitones of its notes above its first note
    static int[] GaOffsets(ScaleMode mode)
    {
        var pcs = mode.Notes.Select(note => note.PitchClass.Value).ToList();
        return [.. pcs.Select(pc => Theory.Mod12(pc - pcs[0])).Order()];
    }

    static string Kind(OutsideNotesSkill.Verdict v) => v.Kind switch
    {
        OutsideNotesSkill.RelationKind.ChordTone => "chord tone",
        OutsideNotesSkill.RelationKind.Tension => "tension",
        _ => "avoid",
    };

    static string Short(string label) => label.Split(" (")[0];

    public static void Run()
    {
        var tool = ReadTool(Path.Combine(AppContext.BaseDirectory, "GuitaristProblemTools.cs"));

        // ---- 1. Arpeggios

        Title("The seventh chord on each degree, thirds stacked within C major and within A minor, against the arpeggio suffix of ga_arpeggio_suggestions's two tables (GuitaristProblemTools.cs, read as text) and ImprovisationSkill.ArpeggioFor (GA.Business.ML, compiled) for the course's symbol");
        foreach (var (tonic, steps, table, romans) in new[] { ("C", Theory.MajorSteps, tool.Major, tool.MajorRomans), ("A", Theory.NaturalMinorSteps, tool.Minor, tool.MinorRomans) })
        {
            Console.WriteLine($"{"degree",-7} {"notes",-14} {"course",-8} {"tool",-6} {"check",-6} {"ImprovisationSkill",-19} check");
            foreach (var (row, i) in Sevenths(tonic, steps).Select((row, i) => (row, i)))
            {
                var suffix = row.Symbol[row.Root.Length..];
                var improv = ImprovisationSkill.ArpeggioFor(ImprovisationSkill.ExtractRoot(row.Symbol), ImprovisationSkill.InferQuality(row.Symbol));
                Console.WriteLine($"{romans[i],-7} {Pretty(string.Join(" ", row.Notes)),-14} {row.Symbol,-8} {table[i].Arpeggio,-6} {(table[i].Arpeggio == suffix ? "ok" : "DIFF"),-6} {improv,-19} {(improv == row.Symbol ? "ok" : "DIFF")}");
            }
        }

        // ---- 2. The scale on each chord

        Title("The mode on each degree of C major: its intervals from the course's steps, against the Mode and Notes columns of the tool's major table, and against GA's MajorScaleMode");
        Console.WriteLine($"{"degree",-7} {"course",-11} {"tool",-16} {"intervals (course)",-27} {"tool's Notes",-12} {"MajorScaleMode",-14} name");
        for (var k = 0; k < 7; k++)
        {
            var course = Intervals(Offsets(Rotate(Theory.MajorSteps, k)));
            var ga = Intervals(GaOffsets(MajorScaleMode.Get(k + 1)));
            var name = tool.Major[k].Mode.StartsWith(MajorNames[k], StringComparison.Ordinal) ? "ok" : "DIFF";
            Console.WriteLine($"{tool.MajorRomans[k],-7} {MajorNames[k],-11} {tool.Major[k].Mode,-16} {course,-27} {(tool.Major[k].Notes == course ? "ok" : "DIFF"),-12} {(ga == course ? "ok" : "DIFF"),-14} {name}");
        }
        Title("The tool's minor table, row by row: the mode on that degree of A minor (the course rotates the steps of natural minor), against the row's Mode and Notes");
        for (var k = 0; k < 7; k++)
        {
            var mode = MajorNames[(k + 5) % 7];
            var course = Intervals(Offsets(Rotate(Theory.NaturalMinorSteps, k)));
            Line($"{tool.MinorRomans[k],-7} {mode,-11} {tool.Minor[k].Mode,-16} {(tool.Minor[k].Mode.StartsWith(mode, StringComparison.Ordinal) ? "ok" : "DIFF"),-5} {(tool.Minor[k].Notes == course ? "ok" : "DIFF")}");
        }
        Title("The textbook scales the tool and the skills name, against GA's mode with that place in its class");
        (string Name, ScaleMode Mode)[] gaModes =
        [
            ("Melodic Minor", MelodicMinorMode.Get(1)), ("Lydian Augmented", MelodicMinorMode.Get(3)), ("Lydian Dominant", MelodicMinorMode.Get(4)),
            ("Mixolydian b6", MelodicMinorMode.Get(5)), ("Locrian #2", MelodicMinorMode.Get(6)), ("Altered (Super Locrian)", MelodicMinorMode.Get(7)),
            ("Phrygian Dominant", HarmonicMinorMode.Get(5)), ("Half-Whole Diminished", DiminishedScaleMode.Get(1)), ("Whole-Half Diminished", DiminishedScaleMode.Get(2)),
            ("Whole Tone", WholeToneScaleMode.Get(1)), ("Major Pentatonic", MajorPentatonicMode.Get(1)), ("Minor Pentatonic", MajorPentatonicMode.Get(5)),
        ];
        Console.WriteLine($"{"name",-24} {"course",-28} {"GA's mode",-24} check");
        foreach (var (name, mode) in gaModes)
        {
            var course = string.Join(" ", Offsets(Scales[name]));
            Console.WriteLine($"{name,-24} {course,-28} {mode.Name,-24} {(string.Join(" ", GaOffsets(mode)) == course ? "ok" : "DIFF")}");
        }

        // ---- 3. ga_arpeggio_suggestions

        Title("What ga_arpeggio_suggestions returns when the request names its key (the course's reading of lines 413 to 495), and the notes of each chord outside the mode it pairs with the chord");
        (string Label, string[] Chords, string Key)[] requests =
        [
            ("the tool's own example", ["Am", "F", "C", "G"], "C major"),
            ("a ii-V-I written with sevenths", ["Dm7", "G7", "Cmaj7"], "C major"),
            ("Wikipedia's chord-scale example", ["A7", "E7", "D7"], "A major"),
            ("an A major chord in C major", ["C", "A", "Dm", "G"], "C major"),
            ("a minor key with its dominant", ["Am", "Dm", "E7", "Am"], "A minor"),
            ("the key written \"Am\"", ["Am", "Dm", "E7"], "Am"),
            ("a chord outside the key", ["C", "Bb", "F"], "C major"),
        ];
        foreach (var (label, chords, key) in requests)
        {
            var (keyRead, rows) = Suggest(tool, chords, key);
            Line($"{label}: [{string.Join(", ", chords)}], key \"{key}\" read as \"{keyRead}\"");
            foreach (var (chord, degree, arpeggio, mode) in rows)
            {
                var (root, notes) = Chord(chord);
                var outside = Scales.ContainsKey(mode) ? Outside(notes, ScaleOn(Theory.PitchClassOf(root), mode)) : "(no scale)";
                Line($"  {chord,-6} {degree,-10} {arpeggio,-34} {mode,-20} outside the mode: {outside}");
            }
        }
        Line($"for a chord outside the key the tool returns the arpeggio \"<chord>{tool.Chromatic.Suffix}\", the mode \"{tool.Chromatic.Mode}\" and the notes \"{tool.Chromatic.Notes}\"");

        // ---- 4. ImprovisationSkill

        Title("ImprovisationSkill (GA.Business.ML, compiled): the quality InferQuality reads in each symbol, the arpeggio ArpeggioFor names, the first scale ScalesFor offers and the chord's notes outside it, and the first of its scales that holds them all");
        Console.WriteLine($"{"symbol",-9} {"notes",-15} {"quality",-23} {"arpeggio",-10} {"first scale",-30} {"outside",-9} holds every note");
        foreach (var (symbol, notes) in Symbols)
        {
            var quality = ImprovisationSkill.InferQuality(symbol);
            var arpeggio = ImprovisationSkill.ArpeggioFor(ImprovisationSkill.ExtractRoot(symbol), quality);
            var names = ScaleNames(symbol);
            var tones = notes.Split(' ');
            var holds = names.FirstOrDefault(n => Outside(tones, ScaleOn(0, n)) == "-") ?? "none";
            Console.WriteLine($"{symbol,-9} {Pretty(notes),-15} {quality.Display,-23} {arpeggio,-10} {names[0],-30} {Outside(tones, ScaleOn(0, names[0])),-9} {(holds == names[0] ? "the first" : holds)}");
        }
        var skill = new ImprovisationSkill(new SilentLogger<ImprovisationSkill>(), new NoExtractor());
        var turnedDown = skill.ExamplePrompts.Where(p => !skill.CanHandle(p)).ToList();
        Line($"CanHandle on its {skill.ExamplePrompts.Count} example prompts: {skill.ExamplePrompts.Count - turnedDown.Count} accepted; turned down: {string.Join("; ", turnedDown.Select(p => $"\"{p}\""))}");
        Title("ImprovisationSkill.ExecuteAsync on requests that name two chords or more: two of its own example prompts, Wikipedia's chord-scale example and GAA-003's Dorian and Mixolydian vamps");
        foreach (var prompt in new[] { "which arpeggio fits Am F C G", "what scales fit over the progression Cmaj7 A7 Dm7 G7", "how do I improvise over A7 E7 D7", "improvise over Am7 D7", "improvise over A7 G/A" })
        {
            Line($"\"{prompt}\": CanHandle {skill.CanHandle(prompt)}, chords read {string.Join(" ", ImprovisationSkill.ExtractChordRun(prompt))}");
            var response = skill.ExecuteAsync(prompt).GetAwaiter().GetResult();
            foreach (var line in response.Result.Split('\n', StringSplitOptions.RemoveEmptyEntries).Where(l => l.StartsWith("- ", StringComparison.Ordinal)))
            {
                Line($"  {line.TrimEnd()}");
            }
        }

        // ---- 5. Outside notes

        (string Symbol, string Quality)[] chords4 = [("Cmaj7", "major 7"), ("C7", "dominant 7"), ("Cm7", "minor 7"), ("Cm7b5", "half-diminished")];
        Title("OutsideNotesSkill.Classify (GA.Business.ML, compiled): each of the twelve notes over Cmaj7, C7, Cm7 and Cm7b5");
        Console.WriteLine($"{"note",-5} {string.Join(" ", chords4.Select(c => c.Symbol.PadRight(29)))}".TrimEnd());
        for (var pc = 0; pc < 12; pc++)
        {
            var cells = chords4.Select(c => OutsideNotesSkill.Classify(0, c.Quality, pc)).Select(v => $"{Kind(v)}: {Short(v.DegreeLabel)}".PadRight(29));
            Console.WriteLine($"{OnC[pc],-5} {string.Join(" ", cells)}".TrimEnd());
        }
        Title("The notes Classify calls a tension that none of the scales ImprovisationSkill offers for the same chord contains");
        foreach (var (symbol, quality) in chords4)
        {
            var names = ScaleNames(symbol);
            var tensions = Enumerable.Range(0, 12).Where(pc => OutsideNotesSkill.Classify(0, quality, pc).Kind == OutsideNotesSkill.RelationKind.Tension).ToList();
            var none = tensions.Where(pc => names.All(n => !ScaleOn(0, n).Contains(pc))).Select(pc => $"{OnC[pc]} ({Short(OutsideNotesSkill.Classify(0, quality, pc).DegreeLabel)})");
            var missing = string.Join(", ", none);
            Line($"{symbol,-6} scales: {string.Join(", ", names)}; tensions: {string.Join(" ", tensions.Select(pc => OnC[pc]))}; in none of them: {(missing.Length == 0 ? "-" : missing)}");
        }
        var notesSkill = new OutsideNotesSkill(new SilentLogger<OutsideNotesSkill>());
        Title("OutsideNotesSkill on its own example prompts: CanHandle, then the first line of ExecuteAsync's answer");
        foreach (var prompt in notesSkill.ExamplePrompts)
        {
            var response = notesSkill.ExecuteAsync(prompt).GetAwaiter().GetResult();
            Line($"\"{prompt}\": {notesSkill.CanHandle(prompt)}; {response.Result.Split('\n')[0].TrimEnd()}");
        }
        // Added after the first run
        Title("Added after the first run: OutsideNotesSkill.ExecuteAsync's whole answer for B over C7, and for E and B over CM7, the symbol ImprovisationSkill reads as minor 7");
        foreach (var prompt in new[] { "is B an avoid note over C7", "is E a chord tone over CM7", "is B a chord tone over CM7" })
        {
            var response = notesSkill.ExecuteAsync(prompt).GetAwaiter().GetResult();
            // AppendLine ends lines with \r\n on Windows and \n elsewhere: trim each line, then drop the blank ones
            Line($"\"{prompt}\": {string.Join(" ", response.Result.Split('\n').Select(l => l.Trim()).Where(l => l.Length > 0))}");
        }
        Title("GAA-003's claims, through Classify: the notes of A minor pentatonic over Am7 and over A7, and the notes the module says pull each mode away");
        foreach (var name in new[] { "A", "C", "D", "E", "G" })
        {
            var pc = Theory.PitchClassOf(name);
            var overMinor = OutsideNotesSkill.Classify(9, "minor 7", pc);
            var overDominant = OutsideNotesSkill.Classify(9, "dominant 7", pc);
            Line($"{name,-3} over Am7: {$"{Kind(overMinor)}, {Short(overMinor.DegreeLabel)}",-27} over A7: {Kind(overDominant)}, {Short(overDominant.DegreeLabel)}");
        }
        foreach (var (mode, note, quality, chord) in new[] { ("Dorian", "F", "minor 7", "Am7"), ("Mixolydian", "G#", "dominant 7", "A7"), ("Lydian", "D", "major 7", "Amaj7") })
        {
            var v = OutsideNotesSkill.Classify(9, quality, Theory.PitchClassOf(note));
            Line($"{mode,-11} {Pretty(note),-3} over {chord,-6} {Kind(v)}, {Short(v.DegreeLabel)}");
        }
        Line("GAA-003's targets, the third of each dominant chord of a blues in A, from ChordVocabulary.GetFormula(\"dominant 7\"): " +
            string.Join(", ", new[] { "A", "D", "E" }.Select(root =>
                $"{root}7 {Pretty(Theory.PcName(Theory.PitchClassOf(root) + ChordVocabulary.GetFormula("dominant 7").Intervals[1]))}")));

        // ---- 6. Improvisation in GA's config and in GAA-003

        var entries = YamlKnowledgeLoader.LoadAllKnowledgeEntries().ToList();
        var improvisation = entries.Where(e => e.SourceFile == "ImprovisationConcepts").ToList();
        Title($"YamlKnowledgeLoader.LoadAllKnowledgeEntries (GA.Business.Config): {entries.Count} entries from {entries.Select(e => e.SourceFile).Distinct().Count()} files; the {improvisation.Count} of ImprovisationConcepts.yaml");
        foreach (var e in improvisation)
        {
            Line($"{e.Name,-22} category \"{e.Category}\", tags {string.Join(", ", e.Tags)}; content: {e.Content.Replace("\n", " | ")}");
        }
        Title("GAA-003's box 1 of A minor pentatonic, read on the strings in standard tuning, against GA's fifth mode of the major pentatonic");
        (string String, string Open, int[] Frets)[] box = [("E", "E2", [5, 8]), ("A", "A2", [5, 7]), ("D", "D3", [5, 7]), ("G", "G3", [5, 7]), ("B", "B3", [5, 8]), ("e", "E4", [5, 8])];
        var boxPcs = new HashSet<int>();
        foreach (var (name, open, frets) in box)
        {
            var notes = frets.Select(f => Theory.MidiOf(open) + f).ToList();
            boxPcs.UnionWith(notes.Select(Theory.Mod12));
            Line($"{name}: frets {string.Join(", ", frets)} -> {string.Join(" ", notes.Select(Theory.PitchName))}");
        }
        var minorPentatonic = MajorPentatonicMode.Get(5);
        Line($"notes of the box: {string.Join(" ", boxPcs.Order().Select(Theory.PcName))}; GA's {minorPentatonic.Name}: {string.Join(" ", minorPentatonic.Notes)}; " +
            $"the same notes {boxPcs.SetEquals(minorPentatonic.Notes.Select(n => n.PitchClass.Value))}");
        Title("GAA-003's three modes on A, as the module spells them, against the course's spelling from the steps");
        Console.WriteLine($"{"mode",-11} {"course",-20} {"GAA-003",-20} check");
        foreach (var (mode, k, written) in new[] { ("Dorian", 1, "A B C D E F# G"), ("Mixolydian", 4, "A B C# D E F# G"), ("Lydian", 3, "A B C# D# E F# G#") })
        {
            var course = string.Join(" ", Theory.SpellScale("A", Rotate(Theory.MajorSteps, k)));
            Console.WriteLine($"{mode,-11} {Pretty(course),-20} {Pretty(written),-20} {(course == written ? "ok" : "DIFF")}");
        }
    }
}
