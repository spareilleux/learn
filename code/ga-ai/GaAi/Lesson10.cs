namespace GaAi;

using System.Text.Json;
using System.Text.RegularExpressions;
using GA.Business.ML.Agents.Mcp;
using static Report;
using static Lesson9;

// Lesson 10: the three skills that hand the question to a model, Transpose, DiatonicChords and
// CommonTones, tell it to call a closure through the ga_dsl_eval tool and to use what comes back.
// The course calls ga_dsl_eval itself, with the arguments each SKILL.md prescribes, and grades
// the closures with lesson 9's letter arithmetic.
public static class Lesson10
{
    static readonly string[] MajorQualities = ["", "m", "m", "", "", "m", "dim"];
    static readonly string[] MinorQualities = ["m", "dim", "", "m", "m", "", ""];

    // The intervals of transpose's SKILL.md table, with the letter steps each one spans; the
    // tritone, which the table maps to 6 semitones whatever its spelling, is left out
    static readonly (string Name, int Steps, int Semitones)[] Intervals =
    [
        ("P1", 0, 0), ("m2", 1, 1), ("M2", 1, 2), ("m3", 2, 3), ("M3", 2, 4), ("P4", 3, 5),
        ("P5", 4, 7), ("m6", 5, 8), ("M6", 5, 9), ("m7", 6, 10), ("M7", 6, 11), ("P8", 0, 12),
    ];

    public static void Run()
    {
        // What the chatbot's startup does before any skill runs
        GA.Business.DSL.GaClosureBootstrap.init();

        Diatonic();
        Transpose();
        CommonTones();
    }

    static DslEvalResult Eval(string closure, params (string Key, string Value)[] args) =>
        DslEvalMcpTools.EvalClosure(closure, args.ToDictionary(a => a.Key, a => a.Value));

    // What the model reads back: Result when the closure returns a string, ResultJson otherwise
    static string Answer(DslEvalResult r) =>
        r.Error is { } e ? $"{e.Code}: {e.Message}" : (r.Result ?? r.ResultJson ?? "").ReplaceLineEndings("\n");

    // ---- The textbook ----

    static string Spell(int letter, int pitch)
    {
        var accidental = ((pitch - Natural[letter]) % 12 + 18) % 12 - 6;
        return Letters[letter] + (accidental < 0 ? new string('b', -accidental) : new string('#', accidental));
    }

    // The note a number of letters and semitones away, up when both are positive
    static string Move(string note, int steps, int semitones) =>
        Spell(((Letters.IndexOf(note[0]) + steps) % 7 + 7) % 7, Pitch(note) + semitones);

    static string[] Triads(string tonic, bool minor)
    {
        var scale = Scale(tonic, minor);
        var qualities = minor ? MinorQualities : MajorQualities;
        return [.. scale.Select((n, i) => n + qualities[i])];
    }

    static string[] TriadNotes(string[] scale, int degree) => [scale[degree], scale[(degree + 2) % 7], scale[(degree + 4) % 7]];

    static readonly Regex Root = new(@"^[A-G](?:bb|b|##|#)?");
    static int PitchClass(string note) => (Pitch(Root.Match(note).Value) % 12 + 12) % 12;

    static IEnumerable<(string Tonic, bool Minor)> AllKeys() =>
        MajorKeys.Select(k => (k, false)).Concat(MinorKeys.Select(k => (k, true)));

    static string KeyName((string Tonic, bool Minor) key) => $"{key.Tonic} {(key.Minor ? "minor" : "major")}";

    // ---- domain.diatonicChords ----

    static void Diatonic()
    {
        Title("ga_dsl_eval \"domain.diatonicChords\" on the 30 keys with at most seven sharps or flats");
        var right = 0;
        foreach (var key in AllKeys())
        {
            var r = Eval("domain.diatonicChords", ("root", key.Tonic), ("scale", key.Minor ? "minor" : "major"));
            var ga = r.Error is null ? JsonSerializer.Deserialize<string[]>(r.ResultJson!)! : [Answer(r)];
            var textbook = Triads(key.Tonic, key.Minor);
            if (ga.SequenceEqual(textbook)) { right++; continue; }
            Line($"{KeyName(key),-9}  GA       {string.Join(" ", ga)}");
            Line($"{"",-9}  textbook {string.Join(" ", textbook)}");
        }
        Line();
        Line($"30 keys: {right} right, {30 - right} with a chord on another letter");

        Title("The results diatonic-chords' SKILL.md gives for the closure");
        foreach (var (root, scale, claim) in new[]
                 {
                     ("C", "major", "[\"C\", \"Dm\", \"Em\", \"F\", \"G\", \"Am\", \"B°\"]"),
                     ("A", "minor", "[\"Am\", \"B°\", \"C\", \"Dm\", \"Em\", \"F\", \"G\"]"),
                     ("Bb", "major", "[\"Bb\",\"Cm\",\"Dm\",\"Eb\",\"F\",\"Gm\",\"A°\"]"),
                     ("Gb", "major", "Gb major returns Cm, not B#m"),
                     ("F#", "minor", "F# minor returns G#°, not Ab°"),
                 })
        {
            Line($"{root + " " + scale,-8}  GA       {Answer(Eval("domain.diatonicChords", ("root", root), ("scale", scale)))}");
            Line($"{"",-8}  SKILL.md {claim}");
        }
    }

    // ---- domain.transposeChord ----

    static string Transposed(string symbol, int semitones) =>
        Answer(Eval("domain.transposeChord", ("symbol", symbol), ("semitones", semitones.ToString())));

    static void Transpose()
    {
        Title("ga_dsl_eval \"domain.transposeChord\": the 21 note names up each interval of transpose's SKILL.md but the tritone");
        Line(". right   ~ right pitch, another letter   d the textbook needs a double sharp or flat   x wrong pitch");
        Line();
        Line("note    " + string.Join(" ", Intervals.Select(i => i.Name)));
        var counts = new Dictionary<char, int> { ['.'] = 0, ['~'] = 0, ['d'] = 0, ['x'] = 0 };
        foreach (var note in Names)
        {
            var cells = new List<string>();
            foreach (var (_, steps, semitones) in Intervals)
            {
                var ga = Transposed(note, semitones);
                var textbook = Move(note, steps, semitones);
                var mark = ga == textbook ? '.'
                    : !Root.IsMatch(ga) || Root.Match(ga).Value != ga || PitchClass(ga) != PitchClass(textbook) ? 'x'
                    : textbook.Length > 2 ? 'd'
                    : '~';
                counts[mark]++;
                cells.Add(mark.ToString().PadRight(2));
            }
            Line($"{note,-7} " + string.Join(" ", cells));
        }
        Line();
        Line($"{Names.Length * Intervals.Length} questions: {counts['.']} right, {counts['~']} on another letter, " +
             $"{counts['d']} where the textbook needs a double accidental, {counts['x']} wrong pitch");

        Title("Transpose's example prompts, with the arguments its SKILL.md maps them to, one call per chord");
        Line("prompt                                symbol    semitones  GA           textbook");
        foreach (var (prompt, symbols, semitones, textbook) in new[]
                 {
                     ("Transpose Cmaj7 up a perfect fourth", "Cmaj7", 5, "Fmaj7"),
                     ("Move this F chord down a minor third", "F", -3, "D"),
                     ("What's Dm7 up a whole step?", "Dm7", 2, "Em7"),
                     ("Transpose G7 to Eb", "G7", 8, "Eb7"),
                     ("", "G7", -4, "Eb7"),
                     ("Shift Am7 up a fifth", "Am7", 7, "Em7"),
                     ("transpose C-Am-F-G to G major", "C Am F G", 7, "G Em C D"),
                     ("transpose C-Am-F-G to Eb major", "C Am F G", 3, "Eb Cm Ab Bb"),
                 })
        {
            var ga = string.Join(" ", symbols.Split(' ').Select(c => Transposed(c, semitones)));
            Line($"{prompt,-37} {symbols,-9} {semitones,9}  {ga,-12} {textbook}");
        }
        var up = Transposed("Bb", 2);
        Line();
        Line($"Bb up a whole step, then back down: {up}, then {Transposed(up, -2)}");

        Title("The chord symbols the closures return, passed back in");
        Line($"B° up a semitone             {Transposed("B°", 1)}");
        Line($"Bdim up a semitone           {Transposed("Bdim", 1)}");
    }

    // ---- domain.commonTones ----

    static readonly Regex SharedNote = new(@"^\s+(\S+) \(", RegexOptions.Multiline);

    static void CommonTones()
    {
        Title("ga_dsl_eval \"domain.commonTones\" on every pair of triads in each of the 30 keys");
        Line("key        misspelled pairs  the key's note as GA writes it");
        int pairs = 0, notesRight = 0, spelledRight = 0;
        foreach (var key in AllKeys())
        {
            var scale = Scale(key.Tonic, key.Minor);
            var triads = Triads(key.Tonic, key.Minor);
            var misspelled = 0;
            var wrong = new List<string>();
            var spellings = new SortedSet<string>(StringComparer.Ordinal);
            for (var a = 0; a < 7; a++)
            for (var b = a + 1; b < 7; b++)
            {
                pairs++;
                var answer = Answer(Eval("domain.commonTones", ("chord1", triads[a]), ("chord2", triads[b])));
                var ga = SharedNote.Matches(answer).Select(m => m.Groups[1].Value).OrderBy(PitchClassOrMinus).ToList();
                var textbook = TriadNotes(scale, a).Intersect(TriadNotes(scale, b)).OrderBy(PitchClass).ToList();
                if (!ga.Select(PitchClassOrMinus).SequenceEqual(textbook.Select(PitchClass)))
                {
                    wrong.Add($"{triads[a]} and {triads[b]}: {answer.Split('\n')[0]}");
                    continue;
                }
                notesRight++;
                var differ = textbook.Zip(ga).Where(p => p.First != p.Second).ToList();
                foreach (var (t, g) in differ) spellings.Add($"{t} as {g}");
                if (differ.Count == 0) spelledRight++;
                else misspelled++;
            }
            if (misspelled == 0 && wrong.Count == 0) continue;
            Line($"{KeyName(key),-10} {$"{misspelled} of 21",-16}  {string.Join(", ", spellings)}");
            foreach (var w in wrong) Line($"           {w}");
        }
        Line();
        Line($"{pairs} pairs: shared notes right {notesRight}, spelled as the key spells them {spelledRight}");

        Title("Common-tones' SKILL.md example, and a pair from A major");
        foreach (var (chord1, chord2) in new[] { ("Cmaj7", "Am7"), ("A", "C#m") })
        {
            Line($"{chord1} and {chord2}");
            foreach (var l in Answer(Eval("domain.commonTones", ("chord1", chord1), ("chord2", chord2))).Split('\n'))
                Line($"  | {l}");
        }
    }

    static int PitchClassOrMinus(string note) => Root.IsMatch(note) ? PitchClass(note) : -1;
}
