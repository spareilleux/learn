namespace GaAi;

using System.Reflection;
using System.Text.RegularExpressions;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Skills;
using Microsoft.Extensions.Logging.Abstractions;
using static Report;

// Lesson 27: outside notes. OutsideNotesSkill answers "why does F sound outside over Cmaj7?" by
// classifying the note against the chord: a chord tone, an available tension, or an avoid note, which
// it defines as a semitone above a chord tone. The skill only marks its refusal Declined on GA's main.
// The program checks the rule against the usual chord scales of five seventh chords, then asks the
// skill about every spelling of a note and many spellings of a chord, and checks how it spells the
// chord's notes.
public static class Lesson27
{
    static readonly MethodInfo ClassifyMethod =
        typeof(OutsideNotesSkill).GetMethod("Classify", BindingFlags.NonPublic | BindingFlags.Static)!;

    // "ChordTone", "Tension" or "Avoid"
    static string Kind(string quality, int rel)
    {
        var verdict = ClassifyMethod.Invoke(null, [0, quality, rel])!;
        return verdict.GetType().GetProperty("Kind")!.GetValue(verdict)!.ToString()!;
    }

    public static void Run()
    {
        var skill = new OutsideNotesSkill(NullLogger<OutsideNotesSkill>.Instance);
        Rule();
        Answers(skill);
        Extended(skill);
        Notes(skill);
        Chords(skill);
        Spelling(skill);
        Examples(skill);
    }

    static string Ask(OutsideNotesSkill skill, string prompt) =>
        skill.ExecuteAsync(prompt).GetAwaiter().GetResult().Result.ReplaceLineEndings("\n");

    static string FirstLine(string text) => text.Split('\n')[0];

    // The skill's evidence line that starts with "name: ", without the prefix; null when it declined
    static string? Evidence(OutsideNotesSkill skill, string prompt, string name)
    {
        var response = skill.ExecuteAsync(prompt).GetAwaiter().GetResult();
        return response.Evidence.FirstOrDefault(e => e.StartsWith(name + ": ", StringComparison.Ordinal))?[(name.Length + 2)..];
    }

    // ---- The rule against a textbook ----

    static readonly string[] Degrees = ["1", "b9", "9", "#9", "3", "11", "#11", "5", "b13", "13", "b7", "7"];

    // A textbook's usual chord scales for each chord, in semitones above the root
    static readonly (string Quality, string Symbol, int[] Chord, int[][] Scales)[] Usual =
    [
        ("major 7", "maj7", [0, 4, 7, 11], [
            [0, 2, 4, 5, 7, 9, 11],      // Ionian
            [0, 2, 4, 6, 7, 9, 11]]),    // Lydian
        ("minor 7", "m7", [0, 3, 7, 10], [
            [0, 2, 3, 5, 7, 9, 10],      // Dorian
            [0, 2, 3, 5, 7, 8, 10],      // Aeolian
            [0, 1, 3, 5, 7, 8, 10]]),    // Phrygian
        ("dominant 7", "7", [0, 4, 7, 10], [
            [0, 2, 4, 5, 7, 9, 10],      // Mixolydian
            [0, 2, 4, 6, 7, 9, 10],      // Lydian dominant
            [0, 2, 4, 5, 7, 8, 10],      // Mixolydian b13
            [0, 1, 4, 5, 7, 8, 10],      // Phrygian dominant
            [0, 1, 3, 4, 6, 8, 10],      // altered
            [0, 1, 3, 4, 6, 7, 9, 10],   // half-whole diminished
            [0, 2, 4, 6, 8, 10]]),       // whole tone
        ("half-diminished", "m7b5", [0, 3, 6, 10], [
            [0, 1, 3, 5, 6, 8, 10],      // Locrian
            [0, 2, 3, 5, 6, 8, 10]]),    // Locrian #2
        ("diminished 7", "dim7", [0, 3, 6, 9], [
            [0, 2, 3, 5, 6, 8, 9, 11]]), // whole-half diminished
    ];

    // c chord tone; o in none of the usual scales; a avoid note, a semitone above a chord tone, except
    // the b9 and b13 of a dominant chord, which are its altered tensions; t any other note of the scales
    static char Textbook(string quality, int[] chord, int[][] scales, int rel) =>
        chord.Contains(rel) ? 'c'
        : !scales.Any(s => s.Contains(rel)) ? 'o'
        : chord.Contains((rel + 11) % 12) && !(quality == "dominant 7" && rel is 1 or 8) ? 'a'
        : 't';

    static char Letter(string kind) => kind switch { "ChordTone" => 'c', "Tension" => 't', _ => 'a' };

    static void Rule()
    {
        Title("The rule against a textbook: c chord tone, t available tension, a avoid note, o in none of the chord's usual scales");
        int[] w = [18, 9, .. Enumerable.Repeat(4, 11)];
        Row(w, ["chord", "", .. Degrees]);
        var same = 0; var avoidOutside = 0; var cells = 0;
        var tensionOutside = new List<string>(); var avoidTension = new List<string>();
        foreach (var (quality, symbol, chord, scales) in Usual)
        {
            var skill = Enumerable.Range(0, 12).Select(r => Letter(Kind(quality, r))).ToArray();
            var book = Enumerable.Range(0, 12).Select(r => Textbook(quality, chord, scales, r)).ToArray();
            Row(w, [$"C{symbol}", "skill", .. skill.Select(c => c.ToString())]);
            Row(w, ["", "textbook", .. book.Select(c => c.ToString())]);
            for (var r = 0; r < 12; r++)
            {
                cells++;
                if (skill[r] == book[r]) same++;
                else if (skill[r] == 'a' && book[r] == 'o') avoidOutside++;
                else if (skill[r] == 't' && book[r] == 'o') tensionOutside.Add($"{Degrees[r]} over C{symbol}");
                else if (skill[r] == 'a' && book[r] == 't') avoidTension.Add($"{Degrees[r]} over C{symbol}");
                else throw new InvalidOperationException($"unexpected {skill[r]}/{book[r]} for {Degrees[r]} over C{symbol}");
            }
        }
        Line($"cells {cells}: the same {same}; avoid notes no usual scale holds {avoidOutside}; " +
             $"tensions no usual scale holds {tensionOutside.Count}: {string.Join(", ", tensionOutside)}; " +
             $"avoid notes the textbook makes tensions {avoidTension.Count}: {string.Join(", ", avoidTension)}");
    }

    // ---- A few answers, in full ----

    static void Answers(OutsideNotesSkill skill)
    {
        Title("A few of OutsideNotesSkill's answers");
        foreach (var prompt in new[]
                 {
                     "why does Db sound outside over C7",
                     "why does D# sound outside over Cmaj7",
                     "why does Bb sound outside over Cmaj7",
                     "why does A sound outside over Cm7b5",
                 })
        {
            Line(prompt);
            foreach (var line in Ask(skill, prompt).TrimEnd('\n').Split('\n').Where(l => l.Length > 0))
                Line("  | " + line);
        }
    }

    // ---- The eleventh over extended chords ----

    static void Extended(OutsideNotesSkill skill)
    {
        Title("F over C and its extended chords: the first line of the answer, and the chord's notes");
        int[] w = [8, 77];
        Row(w, "chord", "answer", "notes");
        foreach (var symbol in new[] { "C", "Cmaj7", "Cmaj9", "Cmaj11", "Cmaj13", "C7", "C9", "C11", "C13", "Cm7", "Cm11" })
        {
            var prompt = $"why does F sound outside over {symbol}";
            var notes = Evidence(skill, prompt, "Chord")?.Split(" — tones ")[1];
            Row(w, symbol, FirstLine(Ask(skill, prompt)), notes);
        }
    }

    // ---- Reading the note ----

    static readonly string[] Naturals = ["C", "D", "E", "F", "G", "A", "B"];
    static readonly int[] NaturalPcs = [0, 2, 4, 5, 7, 9, 11];

    static void Notes(OutsideNotesSkill skill)
    {
        Title("\"why does <note> sound outside over Cmaj7\": the note the skill reads, for each way to write it");
        var spellings = new List<(string Kind, string Text, int Pc)>();
        for (var i = 0; i < 7; i++)
        {
            spellings.Add(("natural", Naturals[i], NaturalPcs[i]));
            spellings.Add(("sharp, #", Naturals[i] + "#", (NaturalPcs[i] + 1) % 12));
            spellings.Add(("flat, b", Naturals[i] + "b", (NaturalPcs[i] + 11) % 12));
            spellings.Add(("sharp, ♯", Naturals[i] + "♯", (NaturalPcs[i] + 1) % 12));
            spellings.Add(("flat, ♭", Naturals[i] + "♭", (NaturalPcs[i] + 11) % 12));
            spellings.Add(("lowercase", Naturals[i].ToLowerInvariant(), NaturalPcs[i]));
        }
        int[] w = [12, 9, 9, 9];
        Row(w, "written", "notes", "read", "misread", "not read");
        var wrong = new List<string>();
        foreach (var group in spellings.GroupBy(s => s.Kind))
        {
            int read = 0, misread = 0, none = 0;
            foreach (var (_, text, pc) in group)
            {
                var note = Evidence(skill, $"why does {text} sound outside over Cmaj7", "Note");
                var m = note is null ? null : Regex.Match(note, @"^(\S+) \(pitch class (\d+)\)$");
                if (m is null) { none++; wrong.Add($"{text}: no answer"); }
                else if (int.Parse(m.Groups[2].Value) == pc) read++;
                else { misread++; wrong.Add($"{text}: {m.Groups[1].Value}"); }
            }
            Row(w, group.Key, group.Count(), read, misread, none);
        }
        Line("not read right: " + string.Join("; ", wrong));
    }

    // ---- Reading the chord ----

    // How the chord might be written after "over C", and the notes it means, in semitones above C;
    // ChordVocabulary has every chord but the last five, though not every way to write it
    static readonly (string Suffix, int[] Pcs)[] Suffixes =
    [
        ("", [0, 4, 7]), ("M", [0, 4, 7]), ("m", [0, 3, 7]), ("min", [0, 3, 7]), ("-", [0, 3, 7]),
        ("dim", [0, 3, 6]), ("°", [0, 3, 6]), ("o", [0, 3, 6]), ("aug", [0, 4, 8]), ("+", [0, 4, 8]),
        ("sus4", [0, 5, 7]), ("sus2", [0, 2, 7]), ("6", [0, 4, 7, 9]), ("m6", [0, 3, 7, 9]),
        ("7", [0, 4, 7, 10]), ("dom7", [0, 4, 7, 10]),
        ("maj7", [0, 4, 7, 11]), ("M7", [0, 4, 7, 11]), ("ma7", [0, 4, 7, 11]), ("Δ7", [0, 4, 7, 11]), ("Δ", [0, 4, 7, 11]),
        ("m7", [0, 3, 7, 10]), ("min7", [0, 3, 7, 10]), ("-7", [0, 3, 7, 10]), ("mi7", [0, 3, 7, 10]),
        ("m7b5", [0, 3, 6, 10]), ("m7♭5", [0, 3, 6, 10]), ("ø", [0, 3, 6, 10]), ("ø7", [0, 3, 6, 10]), ("-7b5", [0, 3, 6, 10]),
        ("dim7", [0, 3, 6, 9]), ("°7", [0, 3, 6, 9]), ("o7", [0, 3, 6, 9]),
        ("7b9", [0, 1, 4, 7, 10]), ("7#9", [0, 3, 4, 7, 10]), ("7♯9", [0, 3, 4, 7, 10]), ("7alt", [0, 1, 3, 4, 6, 8, 10]),
        ("9", [0, 2, 4, 7, 10]), ("maj9", [0, 2, 4, 7, 11]), ("m9", [0, 2, 3, 7, 10]),
        ("7sus4", [0, 5, 7, 10]), ("mMaj7", [0, 3, 7, 11]), ("m(maj7)", [0, 3, 7, 11]), ("7#11", [0, 4, 6, 7, 10]), ("maj7#11", [0, 4, 6, 7, 11]),
    ];

    static readonly Dictionary<string, int> PitchClass = new()
    {
        ["C"] = 0, ["C#"] = 1, ["Db"] = 1, ["D"] = 2, ["D#"] = 3, ["Eb"] = 3, ["E"] = 4, ["F"] = 5,
        ["F#"] = 6, ["Gb"] = 6, ["G"] = 7, ["G#"] = 8, ["Ab"] = 8, ["A"] = 9, ["A#"] = 10, ["Bb"] = 10, ["B"] = 11,
    };

    static void Chords(OutsideNotesSkill skill)
    {
        Title("\"why does F sound outside over C<chord>\": the chord the skill reads, for each way to write it");
        int[] w = [10, 22, 18];
        Row(w, "written", "read as", "its notes", "the chord's notes");
        int right = 0, absentRight = 0;
        foreach (var (i, (suffix, pcs)) in Suffixes.Index())
        {
            var chord = Evidence(skill, $"why does F sound outside over C{suffix}", "Chord");
            var parts = chord?.Split(" — tones ");
            var read = parts?[1].Split(", ").Select(n => PitchClass[n]).Order().ToArray();
            var ok = read is not null && read.SequenceEqual(pcs.Order());
            var absent = i >= Suffixes.Length - 5;
            if (ok) { if (absent) absentRight++; else right++; }
            var meant = string.Join(" ", pcs.Order().Select(p => PitchName(p)));
            if (!ok) Row(w, "C" + suffix, parts?[0] ?? "(no answer)", parts?[1].Replace(", ", " "), meant);
        }
        Line($"chords written {Suffixes.Length}: chords ChordVocabulary has {Suffixes.Length - 5}, read right {right}; " +
             $"chords it doesn't have 5, read right {absentRight}");
    }

    static readonly string[] FlatNames = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];

    static string PitchName(int pc) => FlatNames[pc];

    // ---- Spelling the chord's notes ----

    static readonly string[] Roots = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];

    // The chord's notes with one letter per chord step: the root's letter plus the formula's letter steps
    static string Spell(string root, ChordFormula formula)
    {
        var letter = "CDEFGAB".IndexOf(root[0]);
        var rootPc = PitchClass[root];
        return string.Join(", ", formula.Intervals.Zip(formula.LetterSteps).Select(x =>
        {
            var l = (letter + x.Second) % 7;
            var acc = ((rootPc + x.First - NaturalPcs[l]) % 12 + 18) % 12 - 6;
            return Naturals[l] + acc switch { -2 => "bb", -1 => "b", 0 => "", 1 => "#", 2 => "##", _ => "?" };
        }));
    }

    static void Spelling(OutsideNotesSkill skill)
    {
        Title("The chord's notes in the skill's evidence, against one letter per chord step, on 12 roots");
        int[] w = [16, 7, 9];
        Row(w, "chord", "symbol", "right", "the first that differs: the skill's, a textbook's");
        foreach (var (quality, symbol) in new[]
                 {
                     ("major", ""), ("minor", "m"), ("dominant 7", "7"), ("major 7", "maj7"), ("minor 7", "m7"),
                     ("half-diminished", "m7b5"), ("diminished 7", "dim7"), ("augmented", "aug"),
                 })
        {
            var formula = ChordVocabulary.GetFormula(quality);
            var ok = 0; string? first = null;
            foreach (var root in Roots)
            {
                var tones = Evidence(skill, $"why does F sound outside over {root}{symbol}", "Chord")!.Split(" — tones ")[1];
                var book = Spell(root, formula);
                if (tones == book) ok++;
                else first ??= $"{root}{symbol}: {tones.Replace(",", "")}; {book.Replace(",", "")}";
            }
            Row(w, quality, symbol, $"{ok} of 12", first ?? "-");
        }
    }

    // ---- The example prompts ----

    static void Examples(OutsideNotesSkill skill)
    {
        Title("OutsideNotesSkill's example prompts, and a few other ways to ask: CanHandle, and the first line of the answer");
        int[] w = [50, 10];
        Row(w, "prompt", "CanHandle", "answer");
        var prompts = skill.ExamplePrompts.Concat(
        [
            "why does F sound outside over a minor chord",
            "why does F sound outside over a dominant chord",
            "why does F sound outside on top of Cmaj7",
            "why does the 11 clash over Cmaj7",
        ]).ToList();
        foreach (var prompt in prompts)
            Row(w, prompt, skill.CanHandle(prompt) ? "yes" : "no", FirstLine(Ask(skill, prompt)));
        var refused = skill.ExamplePrompts.Count(p => Evidence(skill, p, "Note") is null);
        Line($"example prompts {skill.ExamplePrompts.Count}: CanHandle accepts {skill.ExamplePrompts.Count(skill.CanHandle)}, the skill refuses {refused}");
    }
}
