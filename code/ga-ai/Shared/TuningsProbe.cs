namespace GaAi;

using System.Text.RegularExpressions;
using GA.Business.ML.Agents;
using static Report;

// Lesson 17's questions to AlternateTuningsSkill. Like ChordVoicingsProbe, the file is compiled
// into GaAi against the pinned GA and into GaMain against GA's main.
public static class TuningsProbe
{
    // A tuning as a textbook writes it: its notes, low string first, and their MIDI numbers
    public sealed record Tuning(string Name, string[] Notes, int[] Midi);

    static Tuning T(string name, string notes, params int[] midi) => new(name, notes.Split(' '), midi);

    public static readonly Tuning Standard = T("standard", "E A D G B E", 40, 45, 50, 55, 59, 64);

    // The nine tunings of the skill's table, with the phrase that names each one
    public static readonly (string Phrase, Tuning Tuning)[] Named =
    [
        ("DADGAD", T("DADGAD", "D A D G A D", 38, 45, 50, 55, 57, 62)),
        ("drop D", T("Drop D", "D A D G B E", 38, 45, 50, 55, 59, 64)),
        ("double drop D", T("Double Drop D", "D A D G B D", 38, 45, 50, 55, 59, 62)),
        ("drop C", T("Drop C", "C G C F A D", 36, 43, 48, 53, 57, 62)),
        ("open G", T("Open G", "D G D G B D", 38, 43, 50, 55, 59, 62)),
        ("open D", T("Open D", "D A D F# A D", 38, 45, 50, 54, 57, 62)),
        ("DGCGCD", T("DGCGCD", "D G C G C D", 38, 43, 48, 55, 60, 62)),
        ("half step down", T("Half-step down (Eb standard)", "Eb Ab Db Gb Bb Eb", 39, 44, 49, 54, 58, 63)),
        ("whole step down", T("Whole-step down (D standard)", "D G C F A D", 38, 43, 48, 53, 57, 62)),
    ];

    // AlternateTuningsSkill.ExamplePrompts (lines 34-48 at the pin), with the tuning each one asks for
    public static readonly (string Prompt, string Expected)[] Examples =
    [
        ("what is DADGAD tuning", "DADGAD"), ("what's drop D tuning", "Drop D"),
        ("how do I tune to drop C", "Drop C"), ("drop C tuning notes", "Drop C"),
        ("how do I tune to open G", "Open G"), ("open D tuning notes", "Open D"),
        ("what is double drop D tuning", "Double Drop D"), ("what's half step down tuning", "Half-step down (Eb standard)"),
        ("whole step down tuning notes", "Whole-step down (D standard)"), ("DGCGCD tuning explained", "DGCGCD"),
        ("how is DADGAD different from standard", "DADGAD"), ("what tuning is Eb Ab Db Gb Bb Eb", "Half-step down (Eb standard)"),
    ];

    static readonly Regex NamedAnswer = new(@"^\*\*(?<name>.+?) tuning\*\* \(low → high\): \*\*(?<notes>[^*]+)\*\*");
    static readonly Regex UnnamedAnswer = new(@"^That tuning \(low → high: \*\*(?<notes>[^*]+)\*\*\) doesn't match");
    static readonly Regex TableRow = new(@"^\| (?<string>\d)[^|]*\| (?<note>[^|]+?) \| (?<delta>[^|]+?) \|$");

    // What the skill answered: the tuning it named, the notes it read, or nothing
    public sealed record Reply(string? Name, string[]? Notes, List<(string Note, string Delta)> Rows)
    {
        public string Short => Name ?? (Notes is { } n ? $"no name, reads {string.Join(" ", n)}" : "declined");
    }

    public static Reply Ask(IOrchestratorSkill skill, string prompt)
    {
        var lines = skill.ExecuteAsync(prompt).GetAwaiter().GetResult().Result.ReplaceLineEndings("\n").Split('\n');
        var rows = lines.Select(l => TableRow.Match(l)).Where(m => m.Success)
            .Select(m => (m.Groups["note"].Value, m.Groups["delta"].Value)).ToList();
        if (NamedAnswer.Match(lines[0]) is { Success: true } n)
            return new(n.Groups["name"].Value, n.Groups["notes"].Value.Split(" – "), rows);
        if (UnnamedAnswer.Match(lines[0]) is { Success: true } u)
            return new(null, u.Groups["notes"].Value.Split(" – "), rows);
        return new(null, null, rows);
    }

    public static void ExampleAnswers(IOrchestratorSkill skill)
    {
        Title("AlternateTuningsSkill's example prompts: the tuning each one gets");
        int[] w = [40, 30];
        Row(w, "prompt", "answer", "verdict");
        foreach (var (prompt, expected) in Examples)
        {
            var r = Ask(skill, prompt);
            Row(w, prompt, r.Short, r.Name == expected ? "right" : "wrong");
        }
    }

    // The skill's table for each named tuning, against a textbook's notes and the semitones each
    // string moves from standard tuning
    public static void Table(IOrchestratorSkill skill)
    {
        Title("The nine tunings of the skill's table: notes and moves from standard, against a textbook");
        int[] w = [30, 22, 26];
        Row(w, "tuning", "notes", "moves from standard", "as a textbook");
        foreach (var (phrase, t) in Named)
        {
            var r = Ask(skill, $"what is {phrase} tuning");
            var moves = Enumerable.Range(0, 6).Select(i => t.Midi[i] - Standard.Midi[i])
                .Select(d => d == 0 ? "same" : d > 0 ? $"+{d}st" : $"{d}st").ToList();
            var notesRight = r.Notes is { } n && n.SequenceEqual(t.Notes);
            var movesRight = r.Rows.Count == 6 && r.Rows.Select(x => x.Delta).SequenceEqual(moves);
            Row(w, t.Name, string.Join(" ", r.Notes ?? []), string.Join(" ", r.Rows.Select(x => x.Delta)),
                notesRight && movesRight ? "right" : $"{(notesRight ? "" : "notes ")}{(movesRight ? "" : $"moves {string.Join(" ", moves)}")}");
        }
    }

    // Notes written four ways, as a guitarist might type them
    static readonly (string Label, Func<string, string> Write)[] Notations =
    [
        ("ASCII", n => n),
        ("♯ and ♭", n => n.Replace("#", "♯").Replace("b", "♭")),
        ("hyphens", n => n.Replace(' ', '-')),
        ("lower case", n => n.ToLowerInvariant()),
    ];

    public static void ByNotes(IOrchestratorSkill skill, string where)
    {
        Title($"\"what tuning is …\" with the six notes, {where}: the tuning each notation gets");
        int[] w = [30, 16, 16, 16];
        Row(w, ["tuning", .. Notations.Select(x => x.Label)]);
        var asked = Named.Select(x => x.Tuning).Append(Standard)
            .Append(new Tuning("Eb standard, in sharps", "D# G# C# F# A# D#".Split(' '), Named[7].Tuning.Midi)).ToList();
        var right = 0; var other = 0; var total = 0;
        var wrong = new List<(string Tuning, string Notation, string Answer)>();
        foreach (var t in asked)
        {
            // The answer a textbook expects: the named tuning with these pitches, or none
            var expected = Named.Select(y => y.Tuning).FirstOrDefault(y => y.Midi.SequenceEqual(t.Midi))?.Name;
            var cells = Notations.Select(x =>
            {
                var r = Ask(skill, $"what tuning is {x.Write(string.Join(" ", t.Notes))}");
                total++;
                var ok = expected is not null ? r.Name == expected
                    : r.Name is null && r.Notes is { } n && n.Select(Pc).SequenceEqual(t.Midi.Select(m => m % 12));
                if (ok) { right++; return "right"; }
                if (r.Name is not null) other++;
                wrong.Add((t.Name, x.Label, r.Short));
                return r.Name is not null ? "another tuning" : r.Notes is not null ? "other notes" : "declined";
            }).ToList();
            Row(w, [t.Name, .. cells]);
        }

        Line($"questions {total}: answered with the tuning asked or its notes {right}, with another named tuning {other}, other answers {total - right - other}");
        foreach (var g in wrong.GroupBy(x => (x.Tuning, x.Answer)))
        {
            var labels = g.Select(x => x.Notation).ToList();
            Line($"  {g.Key.Tuning}, {(labels.Count == Notations.Length ? "every notation" : string.Join(", ", labels))}: {g.Key.Answer}");
        }
    }

    // Tunings and phrasings outside the table
    static readonly (string Prompt, string Expected)[] OtherNames =
    [
        ("what is open D minor tuning", "D A D F A D"), ("what is open G minor tuning", "D G D G Bb D"),
        ("what is open E tuning", "E B E G# B E"), ("what is open C tuning", "C G C G C E"),
        ("what is drop B tuning", "B F# B E G# C#"), ("what is C standard tuning", "C F Bb Eb G C"),
        ("what is drop C# tuning", "C# G# C# F# A# D#"), ("what is drop C♯ tuning", "C# G# C# F# A# D#"),
        ("what is drop D♭ tuning", "Db Ab Db Gb Bb Eb"), ("what is standard tuning", "E A D G B E"),
    ];

    // The class comment promises a caveat about the low string for a chord shape in drop D
    // (AlternateTuningsSkill.cs line 15 at the pin)
    const string ShapeInDropD = "What does an Em shape look like in drop-D";

    public static void Others(IOrchestratorSkill skill, string where)
    {
        Title($"Tunings outside the table, {where}");
        int[] w = [44, 19, 32];
        Row(w, "prompt", "asks for", "answer", "verdict");
        foreach (var (prompt, expected) in OtherNames)
        {
            var r = Ask(skill, prompt);
            var asked = expected.Split(' ').Select(Pc).ToList();
            var verdict = r.Notes is null ? "declined"
                : r.Notes.Select(Pc).SequenceEqual(asked) ? "right"
                : r.Name is not null ? "another tuning" : "other notes";
            Row(w, prompt, expected, r.Notes is null ? "declined" : $"{r.Name ?? "no name"}: {string.Join(" ", r.Notes)}", verdict);
        }

        var shape = skill.ExecuteAsync(ShapeInDropD).GetAwaiter().GetResult().Result;
        Line($"\"{ShapeInDropD}\": {Ask(skill, ShapeInDropD).Short}, the answer names Em: {(shape.Contains("Em", StringComparison.Ordinal) ? "yes" : "no")}");
    }

    // A note's pitch class from its letter and accidentals, ASCII or not
    public static int Pc(string note)
    {
        var n = note.Replace("♯", "#").Replace("♭", "b");
        var pc = char.ToUpperInvariant(n[0]) switch
        {
            'C' => 0, 'D' => 2, 'E' => 4, 'F' => 5, 'G' => 7, 'A' => 9, 'B' => 11,
            _ => throw new ArgumentException(note),
        };
        foreach (var c in n[1..]) pc += c switch { '#' => 1, 'b' => -1, _ => throw new ArgumentException(note) };
        return (pc % 12 + 12) % 12;
    }
}
