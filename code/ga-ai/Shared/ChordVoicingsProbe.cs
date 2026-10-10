namespace GaAi;

using System.Text.RegularExpressions;
using GA.Business.ML.Agents;
using GA.Business.ML.Search;
using static Report;

// A chord chart on six strings, low E first, as guitarists write it; null is a muted string
public sealed record Shape(int?[] Frets)
{
    static readonly int[] Open = [40, 45, 50, 55, 59, 64];

    public int[] Midi => [.. Frets.Select((f, i) => f is { } v ? Open[i] + v : -1).Where(m => m >= 0)];
    public HashSet<int> Pcs => [.. Midi.Select(m => m % 12)];
    public string Chart => string.Join("-", Frets.Select(f => f?.ToString() ?? "x"));

    // GA's Voicing.Diagram, and the pinned skill's answer, put string 1, the high E, first
    public static Shape FromHighFirst(string diagram) => new([.. Parse(diagram).Reverse()]);
    public static Shape FromChart(string diagram) => new(Parse(diagram));

    static int?[] Parse(string d) => [.. d.Split('-').Select(p => p is "x" or "X" ? (int?)null : int.Parse(p))];
}

// One voicing of the skill's answer, as it prints it
public sealed record Answer(string Name, string Diagram, string Score, Shape Shape);

// Lesson 16's questions to ChordVoicingsSkill. The file is compiled twice: into GaAi against the
// pinned GA, and into GaMain against GA's main, so both ask exactly the same questions.
public static class ChordVoicingsProbe
{
    // ChordVoicingsSkill.ExamplePrompts (lines 32-46 at the pin)
    public static readonly string[] Examples =
    [
        "voicings for Cmaj7", "show me Dm7 voicings", "shapes for F major", "fingerings for G7",
        "Cmaj9 voicings", "drop2 voicings of Cmaj7", "shell voicing for Dm7", "rootless A7 voicings",
        "quartal voicings in C", "all C major voicings on guitar", "open chord shape for E minor",
        "barre voicings for Bb major",
    ];

    // The chord each example asks for, as a textbook writes it
    public static readonly Dictionary<string, (string Root, string Degrees)> ExampleChords = new()
    {
        ["voicings for Cmaj7"] = ("C", "1 3 5 7"), ["show me Dm7 voicings"] = ("D", "1 b3 5 b7"),
        ["shapes for F major"] = ("F", "1 3 5"), ["fingerings for G7"] = ("G", "1 3 5 b7"),
        ["Cmaj9 voicings"] = ("C", "1 3 5 7 9"), ["drop2 voicings of Cmaj7"] = ("C", "1 3 5 7"),
        ["shell voicing for Dm7"] = ("D", "1 b3 5 b7"), ["rootless A7 voicings"] = ("A", "1 3 5 b7"),
        ["quartal voicings in C"] = ("C", "1 4 b7"), ["all C major voicings on guitar"] = ("C", "1 3 5"),
        ["open chord shape for E minor"] = ("E", "1 b3 5"), ["barre voicings for Bb major"] = ("Bb", "1 3 5"),
    };

    static readonly Regex ResultLine = new(@"^- \*\*(?<name>.+?)\*\* `(?<diagram>[^`]+)` \((?<type>[^,]+), score (?<score>[-\d.]+)\)");

    public static (string First, List<Answer> Answers) Ask(IOrchestratorSkill skill, string prompt, bool highFirst)
    {
        var lines = skill.ExecuteAsync(prompt).GetAwaiter().GetResult().Result.ReplaceLineEndings("\n").Split('\n');
        var answers = lines.Select(l => ResultLine.Match(l)).Where(m => m.Success)
            .Select(m => new Answer(m.Groups["name"].Value, m.Groups["diagram"].Value, m.Groups["score"].Value,
                highFirst ? Shape.FromHighFirst(m.Groups["diagram"].Value) : Shape.FromChart(m.Groups["diagram"].Value)))
            .ToList();
        return (lines[0], answers);
    }

    // ---- Textbook chords ----

    static readonly string[] Sharps = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
    static readonly Dictionary<string, int> RootPcs = new()
    {
        ["C"] = 0, ["Db"] = 1, ["D"] = 2, ["Eb"] = 3, ["E"] = 4, ["F"] = 5, ["F#"] = 6, ["G"] = 7,
        ["Ab"] = 8, ["A"] = 9, ["Bb"] = 10, ["B"] = 11,
    };
    static readonly int[] Naturals = [0, 2, 4, 5, 7, 9, 11];

    // A degree's semitones above the root: b3 is 3, #5 is 8, 9 is 14
    public static int Semitones(string degree)
    {
        var number = int.Parse(degree.TrimStart('b', '#'));
        return Naturals[(number - 1) % 7] + (number > 7 ? 12 : 0)
            - degree.Count(c => c == 'b') + degree.Count(c => c == '#');
    }

    public static int RootPc(string root) => RootPcs[root];

    public static HashSet<int> Chord(string root, string degrees) =>
        [.. degrees.Split(' ').Select(d => (RootPcs[root] + Semitones(d)) % 12)];

    public static string Notes(IEnumerable<int> pcs) => string.Join(" ", pcs.Distinct().Order().Select(p => Sharps[p]));

    // The answer plays the chord, the chord and more notes, part of it, or something else
    public static string Verdict(HashSet<int> asked, HashSet<int> played) =>
        played.SetEquals(asked) ? "exact" : played.IsSupersetOf(asked) ? "more" : played.IsSubsetOf(asked) ? "part" : "other";

    static readonly string[] Verdicts = ["exact", "more", "part", "other"];

    // ---- What the skill answers ----

    // The 12 roots and 12 qualities of the grid, each asked as "voicings for <symbol>"
    static readonly string[] GridRoots = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];
    static readonly (string Symbol, string Degrees)[] GridQualities =
    [
        ("", "1 3 5"), ("m", "1 b3 5"), ("7", "1 3 5 b7"), ("maj7", "1 3 5 7"), ("m7", "1 b3 5 b7"),
        ("dim", "1 b3 b5"), ("aug", "1 3 #5"), ("sus4", "1 4 5"), ("m7b5", "1 b3 b5 b7"),
        ("dim7", "1 b3 b5 bb7"), ("6", "1 3 5 6"), ("9", "1 3 5 b7 9"),
    ];

    public static void Answers(IOrchestratorSkill skill, bool highFirst, List<Shape> corpus, string where)
    {
        Title($"The example prompts' answers, {where}: what each voicing plays");
        int[] w = [32, 10, 6, 6, 6, 6];
        Row(w, "prompt", "voicings", "exact", "more", "part", "other");
        foreach (var p in Examples)
        {
            var (root, degrees) = ExampleChords[p];
            var asked = Chord(root, degrees);
            var (_, answers) = Ask(skill, p, highFirst);
            var counts = Verdicts.Select(v => answers.Count(a => Verdict(asked, a.Shape.Pcs) == v)).ToArray();
            Row(w, p, answers.Count, counts[0], counts[1], counts[2], counts[3]);
        }

        Title($"A grid of {GridRoots.Length * GridQualities.Length} chords, {where}: \"voicings for <chord>\" on {GridRoots.Length} roots");
        Line("For each quality, the roots whose answer has only voicings that play the chord, some, or none;");
        Line("the corpus holds every chord of the grid. Then what the voicings that aren't the chord play.");
        int[] g = [8, 6, 6, 6];
        Row(g, "quality", "all", "some", "none", "the other voicings play");
        var total = new int[4];
        foreach (var (symbol, degrees) in GridQualities)
        {
            var all = 0; var some = 0; var none = 0;
            var others = new SortedDictionary<string, int>(StringComparer.Ordinal);
            foreach (var r in GridRoots)
            {
                var asked = Chord(r, degrees);
                if (!corpus.Any(s => s.Pcs.SetEquals(asked))) throw new InvalidOperationException($"{r}{symbol} isn't in the corpus");
                var (_, answers) = Ask(skill, $"voicings for {r}{symbol}", highFirst);
                var verdicts = answers.Select(a => Verdict(asked, a.Shape.Pcs)).ToList();
                for (var i = 0; i < 4; i++) total[i] += verdicts.Count(v => v == Verdicts[i]);
                var exact = verdicts.Count(v => v == "exact");
                if (exact > 0 && exact == answers.Count) all++;
                else if (exact > 0) some++;
                else none++;
                foreach (var v in verdicts.Where(v => v != "exact")) others[v] = others.GetValueOrDefault(v) + 1;
            }

            Row(g, symbol == "" ? "major" : symbol, all, some, none,
                string.Join(", ", others.Select(o => $"{o.Key} {o.Value}")));
        }

        Line($"voicings returned: {total.Sum()}; exact {total[0]}, more {total[1]}, part {total[2]}, other {total[3]}");
    }

    // ---- The techniques ----

    static readonly (string Prompt, string Technique)[] Techniques =
    [
        ("drop2 voicings of Cmaj7", "drop2"), ("shell voicing for Dm7", "shell"), ("rootless A7 voicings", "rootless"),
        ("quartal voicings in C", "quartal"), ("open chord shape for E minor", "open"), ("barre voicings for Bb major", "barre"),
    ];

    // Whether a shape is the technique a prompt names, for the chord it asks for
    public static bool Is(string technique, Shape s, int root, HashSet<int> chord)
    {
        var midi = s.Midi.Order().ToArray();
        var played = s.Frets.Where(f => f is not null).Select(f => f!.Value).ToArray();
        switch (technique)
        {
            // Four notes on four strings, the chord's four notes: raising the lowest an octave gives a
            // close position in which it is the second note from the top
            case "drop2":
                if (midi.Length != 4 || !s.Pcs.SetEquals(chord) || s.Pcs.Count != 4) return false;
                var raised = midi[1..].Append(midi[0] + 12).Order().ToArray();
                return raised[3] - raised[0] < 12 && raised[2] == midi[0] + 12;
            // The root, the third and the seventh, nothing else
            case "shell":
                return s.Pcs.SetEquals(chord.Where(p => (p - root + 12) % 12 is 0 or 3 or 4 or 10 or 11));
            // Chord tones only, at least three of them, without the root
            case "rootless":
                return midi.Length >= 3 && s.Pcs.IsSubsetOf(chord) && !s.Pcs.Contains(root);
            // At least three notes stacked in perfect fourths, from the root up
            case "quartal":
                return midi.Length >= 3 && midi[0] % 12 == root && midi.Zip(midi[1..]).All(p => p.Second - p.First == 5);
            // The chord, with at least one open string
            case "open":
                return s.Pcs.SetEquals(chord) && played.Contains(0);
            // The chord, no open string, and one finger across the lowest and highest strings played
            case "barre":
                if (!s.Pcs.SetEquals(chord) || played.Contains(0)) return false;
                var low = played.Min();
                return s.Frets.First(f => f is not null) == low && s.Frets.Last(f => f is not null) == low;
            default:
                throw new ArgumentException(technique);
        }
    }

    public static void TechniqueAnswers(IOrchestratorSkill skill, bool highFirst, List<Shape> corpus, string where)
    {
        Title($"The techniques the example prompts name, {where}");
        int[] w = [32, 10, 8, 10];
        Row(w, "prompt", "voicings", "chord", "technique", "in the corpus");
        foreach (var (p, technique) in Techniques)
        {
            var (rootName, degrees) = ExampleChords[p];
            var root = RootPc(rootName);
            var chord = Chord(rootName, degrees);
            var (_, answers) = Ask(skill, p, highFirst);
            Row(w, p, answers.Count, answers.Count(a => a.Shape.Pcs.SetEquals(chord)),
                answers.Count(a => Is(technique, a.Shape, root, chord)), corpus.Count(s => Is(technique, s, root, chord)));
        }
    }

    // One answer as the skill writes it, and what each voicing plays
    public static void FullAnswer(IOrchestratorSkill skill, string prompt, bool highFirst)
    {
        var (root, degrees) = ExampleChords[prompt];
        var asked = Chord(root, degrees);
        Title($"\"{prompt}\": the answer, and what each voicing plays (asked: {Notes(asked)})");
        var (first, answers) = Ask(skill, prompt, highFirst);
        Line(first);
        int[] w = [16, 16, 8, 16];
        Row(w, "name", "diagram", "score", "plays", "");
        foreach (var a in answers)
            Row(w, a.Name, a.Diagram, a.Score, Notes(a.Shape.Pcs), Verdict(asked, a.Shape.Pcs));
    }
}
