namespace GaAi;

using System.Text.RegularExpressions;
using GA.Business.ML.Agents.Intents;
using Microsoft.Extensions.DependencyInjection;
using static Report;

// Lesson 9: the three skills that spell notes without a model, IntervalSkill, ScaleInfoSkill and
// RelativeKeySkill, asked about every pair of note names and every key, and graded by the letter
// arithmetic of a textbook: an interval's number counts letters, its quality counts semitones.
public static class Lesson9
{
    internal const string Letters = "CDEFGAB";
    internal static readonly int[] Natural = [0, 2, 4, 5, 7, 9, 11];
    internal static readonly int[] MajorSteps = [0, 2, 4, 5, 7, 9, 11];
    internal static readonly int[] MinorSteps = [0, 2, 3, 5, 7, 8, 10];
    static readonly string[] Sizes = ["unison", "second", "third", "fourth", "fifth", "sixth", "seventh"];

    // The 21 names a letter and at most one sharp or flat can spell
    internal static readonly string[] Names = [.. Letters.SelectMany(l => new[] { $"{l}b", $"{l}", $"{l}#" })];

    // The fifteen keys of each mode that have at most seven sharps or flats
    internal static readonly string[] MajorKeys = ["Cb", "Gb", "Db", "Ab", "Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#"];
    internal static readonly string[] MinorKeys = ["Ab", "Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#"];

    public static void Run()
    {
        Lesson4.EnsureIndex();
        using var host = new ChatHost();
        using var client = host.CreateClient();
        host.WaitForWarmup();
        using var scope = host.Services.CreateScope();
        var intents = scope.ServiceProvider.GetServices<IIntent>().ToDictionary(i => i.Id);
        string Ask(string id, string question) =>
            intents[id].ExecuteAsync(question).GetAwaiter().GetResult().Answer.ReplaceLineEndings("\n");

        Intervals(Ask);
        Keys(Ask);
        Examples(intents);
    }

    // ---- The textbook ----

    internal static int Accidental(string name) => name[1..] switch { "b" => -1, "bb" => -2, "#" => 1, "##" => 2, _ => 0 };
    internal static int Pitch(string name) => Natural[Letters.IndexOf(name[0])] + Accidental(name);

    // The interval from a up to b: its number from the letters, its quality from the semitones
    static (string Short, string Long, int Semitones) Interval(string a, string b)
    {
        var steps = (Letters.IndexOf(b[0]) - Letters.IndexOf(a[0]) + 7) % 7;
        var semitones = ((Pitch(b) - Pitch(a)) % 12 + 12) % 12;
        var offset = ((semitones - MajorSteps[steps] + 6) % 12 + 12) % 12 - 6;
        var perfect = steps is 0 or 3 or 4;
        var quality = (perfect, offset) switch
        {
            (true, 0) => "P",
            (false, 0) => "M",
            (false, -1) => "m",
            (_, > 0) => new string('A', offset),
            (true, < 0) => new string('d', -offset),
            _ => new string('d', -offset - 1),
        };
        // Counted from the major or perfect interval of that number: C to Cb is a semitone down
        return ($"{quality}{steps + 1}", $"{QualityName(quality)} {Sizes[steps]}", MajorSteps[steps] + offset);
    }

    static string QualityName(string q) => q switch
    {
        "P" => "perfect", "M" => "major", "m" => "minor",
        "A" => "augmented", "AA" => "doubly augmented", "AAA" => "triply augmented",
        "d" => "diminished", "dd" => "doubly diminished", _ => "triply diminished",
    };

    // A key's seven notes, each letter once, spelled from the tonic
    internal static string[] Scale(string tonic, bool minor)
    {
        var steps = minor ? MinorSteps : MajorSteps;
        return [.. Enumerable.Range(0, 7).Select(i =>
        {
            var letter = Letters[(Letters.IndexOf(tonic[0]) + i) % 7];
            var accidental = ((Pitch(tonic) + steps[i] - Natural[Letters.IndexOf(letter)]) % 12 + 18) % 12 - 6;
            return letter + (accidental < 0 ? new string('b', -accidental) : new string('#', accidental));
        })];
    }

    static string Signature(string tonic, bool minor)
    {
        var accidentals = Scale(tonic, minor).Sum(n => Accidental(n));
        return accidentals switch
        {
            0 => "no sharps or flats",
            1 => "1 sharp",
            -1 => "1 flat",
            > 0 => $"{accidentals} sharps",
            _ => $"{-accidentals} flats",
        };
    }

    static string Relative(string tonic, bool minor) =>
        minor ? $"{Scale(tonic, true)[2]} major" : $"{Scale(tonic, false)[5]} minor";

    // ---- Intervals ----

    static readonly Regex IntervalAnswer = new(@"From \*\*(.+?)\*\* to \*\*(.+?)\*\* is a \*\*(.+?)\*\* \((\S+), (-?\d+) semitones\)");

    static void Intervals(Func<string, string, string> ask)
    {
        Title("IntervalSkill, \"What is the interval from X to Y?\" for the 21 x 21 note names");
        Line(". right   # a note read as another   a right interval, quality abbreviated   x wrong interval");
        Line();
        Line("from\\to " + string.Join(" ", Names.Select(n => n.PadRight(2))));
        var counts = new Dictionary<char, int> { ['.'] = 0, ['#'] = 0, ['a'] = 0, ['x'] = 0 };
        var wrong = new List<string>();
        foreach (var a in Names)
        {
            var cells = new List<string>();
            foreach (var b in Names)
            {
                var answer = ask("skill.interval", $"What is the interval from {a} to {b}?");
                var m = IntervalAnswer.Match(answer);
                var expected = Interval(a, b);
                char mark;
                if (!m.Success) mark = 'x';
                else if (m.Groups[1].Value != a || m.Groups[2].Value != b) mark = '#';
                else if (m.Groups[3].Value == expected.Long && int.Parse(m.Groups[5].Value) == expected.Semitones) mark = '.';
                else if (m.Groups[4].Value == expected.Short && int.Parse(m.Groups[5].Value) == expected.Semitones) mark = 'a';
                else mark = 'x';
                counts[mark]++;
                if (mark == 'x')
                    wrong.Add($"{a,-2} to {b,-2}  GA {m.Groups[3].Value} ({m.Groups[4].Value}, {m.Groups[5].Value})".PadRight(46) +
                              $"textbook {expected.Long} ({expected.Short}, {expected.Semitones})");
                cells.Add(mark.ToString().PadRight(2));
            }
            Line($"{a,-7} " + string.Join(" ", cells));
        }
        Line();
        Line($"441 questions: {counts['.']} right, {counts['#']} with a note read as another, " +
             $"{counts['a']} right with the quality abbreviated, {counts['x']} wrong");

        Title("The note names read right, the interval wrong");
        foreach (var w in wrong) Line(w);

        Title("The same question, written another way");
        foreach (var q in new[]
                 {
                     "What is the interval between E and G#?",
                     "What is the interval from C to F♯?",
                     "What is the interval from B♭ to D?",
                 })
        {
            Line(q);
            Line($"  | {ask("skill.interval", q)}");
        }
    }

    // ---- Keys ----

    static readonly Regex ScaleAnswer = new(@"notes: \*\*(.+?)\*\*\. Relative (?:minor|major): (.+?)\.$");
    static readonly Regex RelativeAnswer = new(@"is \*\*(.+?)\*\*");
    static readonly Regex SignatureAnswer = new(@"has (no sharps or flats|\d+ (?:sharp|flat)s?)\.");

    // "Am" and "Eb major", as RelativeKeySkill writes them, in the course's spelling
    static string KeyName(string s) => s.EndsWith(" major") || s.EndsWith(" minor") ? s : s.TrimEnd('m') + " minor";

    static void Keys(Func<string, string, string> ask)
    {
        Title("ScaleInfoSkill and RelativeKeySkill on the 30 keys with at most seven sharps or flats");
        Line("key         notes  relative key: ScaleInfoSkill  RelativeKeySkill  textbook      signature");
        int notesRight = 0, scaleRelRight = 0, relRight = 0, sigRight = 0;
        foreach (var (tonic, minor) in MajorKeys.Select(k => (k, false)).Concat(MinorKeys.Select(k => (k, true))))
        {
            var mode = minor ? "minor" : "major";
            var scale = ScaleAnswer.Match(ask("skill.scaleinfo", $"What notes are in {tonic} {mode}?"));
            var notesOk = scale.Success && scale.Groups[1].Value.Split(" – ").SequenceEqual(Scale(tonic, minor));
            var scaleRel = scale.Success ? scale.Groups[2].Value : "?";
            var rel = KeyName(RelativeAnswer.Match(ask("skill.relativekey",
                $"What is the relative {(minor ? "major" : "minor")} of {tonic} {mode}?")).Groups[1].Value);
            var sigAnswer = SignatureAnswer.Match(ask("skill.relativekey", $"How many sharps in {tonic} {mode}?"));
            var sig = sigAnswer.Success ? sigAnswer.Groups[1].Value : "not read as a key";
            var textbook = Relative(tonic, minor);
            notesRight += notesOk ? 1 : 0;
            scaleRelRight += scaleRel == textbook ? 1 : 0;
            relRight += rel == textbook ? 1 : 0;
            sigRight += sig == Signature(tonic, minor) ? 1 : 0;
            if (notesOk && scaleRel == textbook && rel == textbook && sig == Signature(tonic, minor)) continue;
            Line($"{tonic + " " + mode,-11} {(notesOk ? "right" : "wrong"),-6} {scaleRel,-31} {rel,-17} {textbook,-13} {sig}");
        }
        Line();
        Line($"30 keys: notes right {notesRight}, relative key right: ScaleInfoSkill {scaleRelRight}, " +
             $"RelativeKeySkill {relRight}; signature right {sigRight}");
        Line("How many flats in Cb major?");
        Line($"  | {ask("skill.relativekey", "How many flats in Cb major?")}");

        Title("Keys past seven sharps or flats that RelativeKeySkill reads");
        Line("What notes are in G# major?");
        Line($"  | {ask("skill.scaleinfo", "What notes are in G# major?")}");
        foreach (var (tonic, minor) in new[] { ("D#", false), ("G#", false), ("A#", false), ("Db", true), ("Gb", true) })
        {
            var mode = minor ? "minor" : "major";
            var usual = (minor ? MinorKeys : MajorKeys).First(k => (Pitch(k) - Pitch(tonic)) % 12 == 0);
            Line($"How many sharps in {tonic} {mode}?  textbook {Signature(tonic, minor)}, usually written {usual} {mode}");
            Line($"  | {ask("skill.relativekey", $"How many sharps in {tonic} {mode}?")}");
        }
        var parallel = ask("skill.relativekey", "What is the parallel minor of G# major?").Split('\n').Last(l => l.Length > 0);
        Line($"What is the parallel minor of G# major?  textbook: G# minor has {Signature("G#", true)}");
        Line($"  | {parallel}");
    }

    // ---- Each skill's own example prompts ----

    static void Examples(Dictionary<string, IIntent> intents)
    {
        Title("Each skill's example prompts, which the intent router matches questions against, sent to that skill");
        foreach (var id in new[] { "skill.interval", "skill.scaleinfo", "skill.relativekey" })
        {
            var results = intents[id].ExamplePrompts
                .Select(q => (q, r: intents[id].ExecuteAsync(q).GetAwaiter().GetResult()))
                .ToList();
            var unanswered = results.Where(x => x.r.Confidence < 0.5f).ToList();
            Line($"{id}: {results.Count - unanswered.Count} of {results.Count} answered");
            foreach (var (q, r) in unanswered)
                Line($"  {q,-40} | {r.Answer.ReplaceLineEndings(" ")}");
        }
    }
}
