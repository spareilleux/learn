extern alias dslmain;
extern alias keysmain;

namespace GaAi;

using GA.Business.ML.Agents.Mcp;
using Microsoft.FSharp.Collections;
using Microsoft.FSharp.Control;
using Microsoft.FSharp.Core;
using static Report;
using static Lesson9;
using OnMain = dslmain::GA.Business.DSL.Closures.BuiltinClosures.DomainClosures;
using KeysOnMain = keysmain::GA.Domain.Services.Tonal.KeyIdentificationService;

// Lesson 13: domain.analyzeProgression, the DSL closure that names the key of a chord progression
// and labels each chord with a Roman numeral. The chatbot's progression-analysis skill is still a
// draft, blocked on a tool; the closure it would need already answers through ga_dsl_eval. The
// program asks it the draft's own examples and textbook progressions in the 30 keys, at the pin
// and as it is on main.
public static class Lesson13
{
    const string Closure = "domain.analyzeProgression";

    record Version(string Name, Func<string, string> Analyze);

    // At the pin, through ga_dsl_eval, as a skill of the chatbot would call it
    static readonly Version Pin = new("a826864", chords =>
    {
        var r = DslEvalMcpTools.EvalClosure(Closure, new() { ["chords"] = chords });
        return r.Error is { } e ? $"{e.Code}: {e.Message}" : (r.Result ?? r.ResultJson ?? "").ReplaceLineEndings("\n");
    });

    // On main, main's closure run the way ga_dsl_eval runs a closure once it has found it
    static readonly Version Main = new("6baf32e", chords =>
    {
        var inputs = MapModule.OfSeq([Tuple.Create("chords", (object)chords)]);
        var result = FSharpAsync.RunSynchronously(OnMain.analyzeProgression.Exec.Invoke(inputs),
            FSharpOption<int>.None, FSharpOption<CancellationToken>.None);
        return result.IsOk ? result.ResultValue.ToString()!.ReplaceLineEndings("\n") : $"error: {result.ErrorValue}";
    });

    static readonly Version[] Versions = [Pin, Main];

    public static void Run()
    {
        // What the chatbot's startup does before any skill runs
        GA.Business.DSL.GaClosureBootstrap.init();

        Listed();
        Draft();
        Textbook();
        Outside();
    }

    // The key, the confidence and the numerals of the closure's three lines
    record Analysis(string Key, string Confidence, string[] Numerals);

    static Analysis Read(string answer)
    {
        var lines = answer.Split('\n');
        var head = lines[0]["Key: ".Length..];
        var open = head.IndexOf("  (confidence ", StringComparison.Ordinal);
        return new(head[..open], head[(open + "  (confidence ".Length)..^1],
            lines[2].Split(' ', StringSplitOptions.RemoveEmptyEntries));
    }

    static void Show(Version v, string chords)
    {
        var lines = v.Analyze(chords).Split('\n');
        Line($"  {v.Name,-8} {lines[0]}");
        foreach (var line in lines.Skip(1)) Line($"  {"",-8} {line.TrimEnd()}");
    }

    // ---- What the chatbot is shown ----

    static void Listed()
    {
        Title("What ga_dsl_list_closures and ga_dsl_get_closure_schema show the model");
        var all = DslEvalMcpTools.ListClosures().Closures;
        var entry = all.Single(c => c.Name == Closure);
        Line($"{all.Length} closures listed, among them {entry.Name} ({entry.Category}): {entry.Description}");
        var schema = DslEvalMcpTools.GetClosureSchema(Closure);
        foreach (var (name, type) in schema.InputSchema!) Line($"input  {name}: {type}");
        Line($"output {schema.OutputType}");
    }

    // ---- The draft skill's examples ----

    static readonly (string Chords, string Expected)[] DraftExamples =
    [
        ("C Am F G", "C major, I vi IV V"),
        ("Dm7 G7 Cmaj7", "C major, ii V I"),
        ("D A Bm G", "D major, I V vi IV"),
        ("Fm Bbm C7 Fm", "F minor, i iv V i"),
    ];

    static void Draft()
    {
        Title("The four examples of skills-dev/_pending-tools/progression-analysis/DRAFT.md");
        foreach (var (chords, expected) in DraftExamples)
        {
            Line($"\"{chords}\": the draft expects {expected}");
            foreach (var v in Versions) Show(v, chords);
        }
    }

    // ---- Textbook progressions in the 30 keys ----

    // A degree of the scale, or of the harmonic minor when Raised, with the chord's suffix
    record Step(int Degree, string Suffix, bool Raised = false);

    static readonly (string Name, bool Minor, Step[] Chords, string Numerals)[] Progressions =
    [
        ("I IV V I", false, [new(0, ""), new(3, ""), new(4, ""), new(0, "")], "I IV V I"),
        ("IV V I", false, [new(3, ""), new(4, ""), new(0, "")], "IV V I"),
        ("I vi IV V", false, [new(0, ""), new(5, "m"), new(3, ""), new(4, "")], "I vi IV V"),
        ("ii7 V7 Imaj7", false, [new(1, "m7"), new(4, "7"), new(0, "maj7")], "ii V I"),
        // V is a major triad, from the harmonic minor
        ("i iv V i", true, [new(0, "m"), new(3, "m"), new(4, ""), new(0, "m")], "i iv V i"),
        ("i iv v i", true, [new(0, "m"), new(3, "m"), new(4, "m"), new(0, "m")], "i iv v i"),
        ("iiø7 V7 i", true, [new(1, "m7b5"), new(4, "7"), new(0, "m")], "iiø V i"),
        // vii°7 stands on the leading tone, the raised seventh degree
        ("i iv vii°7 i", true, [new(0, "m"), new(3, "m"), new(6, "dim7", true), new(0, "m")], "i iv vii° i"),
    ];

    // The questions printed in full after the grid
    static readonly (string Progression, string Key)[] Shown =
    [
        ("IV V I", "Bb major"),
        ("ii7 V7 Imaj7", "Gb major"),
        ("i iv v i", "G# minor"),
        ("i iv vii°7 i", "D minor"),
    ];

    // The raised degree keeps its letter: G to G#, Bb to B, F# to F##
    static string Raise(string note) => note.EndsWith('b') ? note[..^1] : note + "#";

    static string[] Chords(string tonic, bool minor, Step[] steps)
    {
        var scale = Scale(tonic, minor);
        return [.. steps.Select(s => (s.Raised ? Raise(scale[s.Degree]) : scale[s.Degree]) + s.Suffix)];
    }

    static void Textbook()
    {
        Title("Eight textbook progressions in the 30 keys");
        var tally = Versions.ToDictionary(v => v, _ => new Dictionary<string, int>());
        var shown = new List<string>();
        var partial = new List<(Version Version, string Name)>();
        foreach (var minor in new[] { false, true })
        {
            var tonics = minor ? MinorKeys : MajorKeys;
            Line();
            Row([22], minor ? "minor keys" : "major keys", string.Join(" ", tonics.Select(t => t.PadRight(2))));
            foreach (var (name, _, steps, numerals) in Progressions.Where(p => p.Minor == minor))
                foreach (var v in Versions)
                {
                    var marks = tonics.Select(tonic =>
                    {
                        var chords = string.Join(" ", Chords(tonic, minor, steps));
                        var key = $"{tonic} {(minor ? "minor" : "major")}";
                        var a = Read(v.Analyze(chords));
                        var (keyTonic, mode) = (a.Key.Split(' ')[0], a.Key.Split(' ')[1]);
                        var sameKey = mode == key.Split(' ')[1] && (Pitch(keyTonic) + 12) % 12 == (Pitch(tonic) + 12) % 12;
                        var mark = !sameKey ? "x"
                            : string.Join(" ", a.Numerals) != numerals ? "n"
                            : a.Key == key ? "=" : "e";
                        tally[v][mark] = tally[v].GetValueOrDefault(mark) + 1;
                        var (count, total) = (a.Confidence.Split('/')[0], a.Confidence.Split('/')[1]);
                        if (count != total) partial.Add((v, name));
                        if (Shown.Contains((name, key)))
                        {
                            if (v == Pin) shown.Add($"{key}, {name}: \"{chords}\"");
                            shown.Add($"  {v.Name,-8} Key: {a.Key} ({a.Confidence}), {string.Join(" ", a.Numerals)}");
                        }
                        return mark;
                    });
                    Row([13, 8], name, v.Name, string.Join(" ", marks.Select(m => m.PadRight(2))));
                }
        }

        Line();
        Line("= the textbook key, spelled as the question, and the textbook numerals; e the same key under its");
        Line("enharmonic name, the textbook numerals; n the key, other numerals; x another key");
        foreach (var v in Versions)
            Line($"{v.Name}: 120 questions, = {tally[v].GetValueOrDefault("=")}, e {tally[v].GetValueOrDefault("e")}, " +
                 $"n {tally[v].GetValueOrDefault("n")}, x {tally[v].GetValueOrDefault("x")}; confidence below the chord count: " +
                 (partial.Any(p => p.Version == v)
                     ? string.Join(", ", partial.Where(p => p.Version == v).GroupBy(p => p.Name).Select(g => $"{g.Key} in {g.Count()} keys"))
                     : "none"));
        Line();
        foreach (var line in shown) Line(line);
    }

    // ---- Chords outside the natural scale ----

    static readonly (string Chords, string Textbook)[] Chromatic =
    [
        ("C Ab G C", "C major, I bVI V I"),
        ("C Eb F C", "C major, I bIII IV I"),
        ("C Bb F C", "C major, I bVII IV I"),
        ("C Ab Bb C", "C major, I bVI bVII I"),
        ("Am G#dim7 Am", "A minor, i vii° i"),
        ("Bm7b5 E7 Am", "A minor, iiø V i"),
    ];

    static void Outside()
    {
        Title("Chords borrowed from the parallel minor, and the harmonic minor's V and vii°");
        foreach (var (chords, textbook) in Chromatic)
        {
            Line($"\"{chords}\": the textbook reads {textbook}");
            foreach (var v in Versions) Show(v, chords);
        }

        // The keys main's closure chooses from: Identify's first three, with their counts
        foreach (var chords in new[] { "C Bb F C", "C Ab Bb C" })
            Line($"KeyIdentificationService.Identify on main, \"{chords}\": " +
                 string.Join(", ", KeysOnMain.Identify(chords.Split(' ')).Take(3).Select(c => $"{c.Key} {c.MatchCount}/{c.TotalChords}")));

        // The confidence counts the chords main's key service calls diatonic
        (string Key, string[] Symbols)[] checks =
        [
            ("A minor", ["Am", "Bdim", "Bm7b5", "E", "E7", "G#dim7"]),
            // G# minor's leading tone is F double sharp
            ("G# minor", ["G#m", "D#7", "F#", "F##dim7"]),
        ];
        foreach (var (key, symbols) in checks)
            Line($"KeyIdentificationService.IsChordDiatonic(\"{key}\", ...) on main: " +
                 string.Join(", ", symbols.Select(c => $"{c} {(KeysOnMain.IsChordDiatonic(key, c) ? "yes" : "no")}")));
    }
}
