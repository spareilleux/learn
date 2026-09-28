namespace GaAi;

using System.Text.Json;
using GA.Business.ML.Agents.Skills;
using GA.Business.ML.Search;
using Microsoft.Extensions.Logging.Abstractions;
using static Report;

// Lesson 5: GA's improvisation skill against chord-scale theory. The program calls the skill
// directly, without a model, and checks each answer with a small oracle written from textbook
// definitions: chord tones, scale spellings, and the major-scale collection of a progression.
public static class Lesson5
{
    public static readonly string[] ChordTable =
    [
        "Cmaj7", "C7", "Cm7", "Cm7b5", "Cdim", "Cdim7", "Caug", "C6", "Cm6",
        "C7#11", "Cm7#5", "Cmaj7#5", "C7sus4", "CmMaj7", "Csus4", "Csus2", "C5",
    ];

    public static readonly string[] Progressions =
        ["Dm7 G7 Cmaj7", "Am F C G", "Em C G D", "C A Dm G", "Am Dm E", "C G", "C Fm G C"];

    public static void Run()
    {
        var skill = new ImprovisationSkill(NullLogger<ImprovisationSkill>.Instance, new NoExtractor());
        Answer(skill, "which arpeggio fits Am F C G");
        Chords(skill);
        foreach (var progression in Progressions) Progression(skill, progression);
    }

    static void Answer(ImprovisationSkill skill, string prompt)
    {
        var response = skill.ExecuteAsync(prompt).GetAwaiter().GetResult();
        Title($"ImprovisationSkill.ExecuteAsync(\"{prompt}\")");
        foreach (var line in response.Result.TrimEnd().Split('\n')) Line($"  | {line}".TrimEnd());
        foreach (var assumption in response.Assumptions) Line($"assumption: {assumption}");
    }

    // One run of chords: the skill classifies each chord of a run on its own, so this is the
    // same as asking about each chord, and it returns an arpeggio and scales for every one
    static void Chords(ImprovisationSkill skill)
    {
        var prompt = "arpeggios over " + string.Join(" ", ChordTable);
        var answers = Ask(skill, prompt);
        Title($"ImprovisationSkill.ExecuteAsync(\"{prompt}\")");
        Line($"written: {string.Join(" ", ChordTable)}");
        Line($"read:    {string.Join(" ", answers.Select(a => a.Chord))}");
        Line();
        int[] w = [8, 10, 23, 9, 32];
        Row(w, "written", "read as", "quality", "arpeggio", "lead scale", "check");
        var next = 0;
        foreach (var written in ChordTable)
        {
            // The skill returns the chords it read, in order; one it could not read is missing
            if (next == answers.Count || !written.StartsWith(answers[next].Chord, StringComparison.Ordinal))
            {
                Row(w, written, "(dropped)");
                continue;
            }
            var a = answers[next++];
            var chord = Chord(written);
            var arpeggio = Chord(a.Arpeggio);
            var lead = Scale(a.Scales[0]);
            List<string> problems = [];
            var adds = arpeggio.Where(n => !chord.Any(c => c.Pc == n.Pc)).ToList();
            var drops = chord.Where(c => !arpeggio.Any(n => n.Pc == c.Pc)).ToList();
            var lacks = chord.Where(c => !lead.Any(n => n.Pc == c.Pc)).ToList();
            if (adds.Count > 0) problems.Add($"arpeggio adds {Names(adds)}");
            if (drops.Count > 0) problems.Add($"arpeggio drops {Names(drops)}");
            if (lacks.Count > 0)
            {
                // The skill lists more than one scale; say whether a later choice holds the chord
                var holds = a.Scales.FindIndex(s => chord.All(c => Scale(s).Any(n => n.Pc == c.Pc)));
                problems.Add($"scale lacks {Names(lacks)} " + (holds < 0
                    ? $"(none of {a.Scales.Count} choices has it)"
                    : $"(choice {holds + 1} of {a.Scales.Count} has it)"));
            }
            Row(w, written, a.Chord == written ? "" : a.Chord, a.Quality, a.Arpeggio, a.Scales[0],
                problems.Count == 0 ? "ok" : string.Join("; ", problems));
        }
        if (next != answers.Count) throw new InvalidOperationException("the skill read chords that were not written");
    }

    // A progression: find the major-scale collection that holds the most chord tones, then
    // compare the skill's lead scale for each chord with the textbook chord-scale in that key
    static void Progression(ImprovisationSkill skill, string progression)
    {
        var prompt = "which arpeggio fits " + progression;
        var answers = Ask(skill, prompt);
        var chords = answers.Select(a => Chord(a.Chord)).ToList();
        var outside = Enumerable.Range(0, 12)
            .Select(k => chords.Sum(c => c.Count(n => !Key(k).Any(m => m.Pc == n.Pc))))
            .ToList();
        var fewest = outside.Min();
        var keys = Enumerable.Range(0, 12).Where(k => outside[k] == fewest).ToList();

        Title($"ImprovisationSkill.ExecuteAsync(\"{prompt}\") against the key");
        Line($"key: {string.Join(" or ", keys.Select(KeyName))}; chord tones outside it: {fewest}");
        Line();
        int[] w = [6, 9, 26, 9, 25, 6];
        Row(w, "chord", "arpeggio", "GA lead scale", "foreign", "textbook", "rank", "verdict");
        for (var i = 0; i < answers.Count; i++)
        {
            var a = answers[i];
            var lead = Scale(a.Scales[0]);
            var candidates = a.Scales.Select(Scale).ToList();
            var perKey = keys.Select(k =>
            {
                var textbook = Textbook(chords[i], k);
                var foreign = lead.Where(n => !textbook.Any(t => t.Pc == n.Pc)).ToList();
                var rank = candidates.FindIndex(s => SamePcs(s, textbook));
                return (Name: $"{textbook[0]} {ModeName(textbook)}", Foreign: foreign.Count == 0 ? "-" : Names(foreign),
                        Rank: rank < 0 ? "-" : (rank + 1).ToString(), Same: SamePcs(lead, textbook), Key: k);
            }).ToList();
            var matched = perKey.Where(p => p.Same).Select(p => KeyName(p.Key)).ToList();
            var verdict = matched.Count == perKey.Count ? "same"
                : matched.Count == 0 ? "DIFF"
                : "same in " + string.Join(", ", matched);
            Row(w, a.Chord, a.Arpeggio, a.Scales[0], string.Join(" | ", perKey.Select(p => p.Foreign)),
                string.Join(" | ", perKey.Select(p => p.Name)), string.Join(" | ", perKey.Select(p => p.Rank)), verdict);
        }
    }

    // What the skill returns for each chord of a run, read from AgentResponse.Data
    sealed record ChordAnswer(string Chord, string Quality, string Arpeggio, List<string> Scales);

    static List<ChordAnswer> Ask(ImprovisationSkill skill, string prompt)
    {
        var response = skill.ExecuteAsync(prompt).GetAwaiter().GetResult();
        var data = JsonSerializer.SerializeToElement(response.Data);
        return data.GetProperty("perChord").EnumerateArray().Select(c => new ChordAnswer(
            c.GetProperty("chord").GetString()!,
            c.GetProperty("quality").GetString()!,
            c.GetProperty("arpeggio").GetString()!,
            c.GetProperty("scales").EnumerateArray().Select(s => s.GetProperty("name").GetString()!).ToList())).ToList();
    }

    // The progression path never calls the extractor, the one part of the skill that needs a model
    sealed class NoExtractor : IMusicalQueryExtractor
    {
        public Task<StructuredQuery> ExtractAsync(string query, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("the single-chord path needs a model; this lesson doesn't use it");
    }

    // ---- The oracle: spelled notes, chord and scale formulas, keys ----

    const string Letters = "CDEFGAB";
    static readonly int[] MajorSteps = [0, 2, 4, 5, 7, 9, 11];

    // A spelled note: its letter (0 = C .. 6 = B) and its pitch class
    readonly record struct Note(int Letter, int Pc)
    {
        public override string ToString()
        {
            var offset = ((Pc - MajorSteps[Letter]) % 12 + 18) % 12 - 6;
            return Letters[Letter] + offset switch
            {
                -2 => "bb", -1 => "b", 0 => "", 1 => "#", 2 => "##",
                _ => throw new InvalidOperationException($"no spelling for pitch class {Pc} on {Letters[Letter]}"),
            };
        }
    }

    // A degree such as "b3", "#11" or "bb7" above a root, spelled on the right letter
    static Note Degree(Note root, string degree)
    {
        var flats = degree.TakeWhile(ch => ch == 'b').Count();
        var sharps = degree.TakeWhile(ch => ch == '#').Count();
        var step = (int.Parse(degree[(flats + sharps)..]) - 1) % 7;
        return new Note((root.Letter + step) % 7, (root.Pc + MajorSteps[step] + sharps - flats + 12) % 12);
    }

    static Note Root(string symbol, out string suffix)
    {
        var letter = Letters.IndexOf(symbol[0]);
        var accidental = symbol.Length > 1 && symbol[1] is '#' or 'b' ? symbol[1] : ' ';
        suffix = symbol[(accidental == ' ' ? 1 : 2)..];
        var pc = MajorSteps[letter] + accidental switch { '#' => 1, 'b' => -1, _ => 0 };
        return new Note(letter, (pc + 12) % 12);
    }

    static readonly Dictionary<string, string> ChordFormulas = new()
    {
        [""] = "1 3 5", ["m"] = "1 b3 5", ["6"] = "1 3 5 6", ["m6"] = "1 b3 5 6",
        ["7"] = "1 3 5 b7", ["maj7"] = "1 3 5 7", ["m7"] = "1 b3 5 b7", ["mMaj7"] = "1 b3 5 7",
        ["m7b5"] = "1 b3 b5 b7", ["dim"] = "1 b3 b5", ["dim7"] = "1 b3 b5 bb7", ["aug"] = "1 3 #5",
        ["7sus4"] = "1 4 5 b7", ["sus4"] = "1 4 5", ["sus2"] = "1 2 5", ["5"] = "1 5",
        ["7#11"] = "1 3 5 b7 #11", ["m7#5"] = "1 b3 #5 b7", ["maj7#5"] = "1 3 #5 7",
    };

    static List<Note> Chord(string symbol)
    {
        var root = Root(symbol, out var suffix);
        return ChordFormulas[suffix].Split(' ').Select(d => Degree(root, d)).ToList();
    }

    // Every scale name the skill can return, with its formula
    static readonly Dictionary<string, string> ScaleFormulas = new()
    {
        ["Ionian (major)"] = "1 2 3 4 5 6 7", ["Major scale of the chord root"] = "1 2 3 4 5 6 7",
        ["Lydian"] = "1 2 3 #4 5 6 7", ["Major Pentatonic"] = "1 2 3 5 6",
        ["Mixolydian"] = "1 2 3 4 5 6 b7", ["Lydian Dominant"] = "1 2 3 #4 5 6 b7",
        ["Mixolydian b6"] = "1 2 3 4 5 b6 b7", ["Altered (Super Locrian)"] = "1 b2 b3 b4 b5 b6 b7",
        ["Half-Whole Diminished"] = "1 b2 #2 3 #4 5 6 b7", ["Phrygian Dominant"] = "1 b2 3 4 5 b6 b7",
        ["Phrygian"] = "1 b2 b3 4 5 b6 b7", ["Dorian"] = "1 2 b3 4 5 6 b7",
        ["Aeolian (minor)"] = "1 2 b3 4 5 b6 b7", ["Aeolian (natural minor)"] = "1 2 b3 4 5 b6 b7",
        ["Minor Pentatonic"] = "1 b3 4 5 b7", ["Melodic Minor"] = "1 2 b3 4 5 6 7",
        ["Locrian"] = "1 b2 b3 4 b5 b6 b7", ["Locrian #2"] = "1 2 b3 4 b5 b6 b7",
        ["Whole-Half Diminished"] = "1 2 b3 4 b5 #5 6 7", ["Whole Tone"] = "1 2 3 #4 #5 b7",
        ["Lydian Augmented"] = "1 2 3 #4 #5 6 7",
    };

    // "F Ionian (major)" -> F G A Bb C D E
    static List<Note> Scale(string named)
    {
        var space = named.IndexOf(' ');
        var root = Root(named[..space], out _);
        return ScaleFormulas[named[(space + 1)..]].Split(' ').Select(d => Degree(root, d)).ToList();
    }

    static readonly string[] MajorKeys = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];
    static readonly string[] MinorKeys = ["A", "Bb", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"];

    static string KeyName(int k) => $"{MajorKeys[k]} major / {MinorKeys[k]} minor";

    static List<Note> Key(int k) => Scale($"{MajorKeys[k]} Ionian (major)");

    // The key's notes with each chord tone in place of the key note on the same letter, read
    // from the chord root: the mode of the key for a diatonic chord, and for a secondary
    // dominant the key's notes around the chord's own tones (A in C major: A B C# D E F G)
    static List<Note> Textbook(List<Note> chord, int k)
    {
        var byLetter = Key(k).ToDictionary(n => n.Letter, n => n.Pc);
        foreach (var tone in chord) byLetter[tone.Letter] = tone.Pc;
        return Enumerable.Range(0, 7).Select(i => (chord[0].Letter + i) % 7).Select(l => new Note(l, byLetter[l])).ToList();
    }

    static readonly Dictionary<string, string> ModeNames = new()
    {
        ["0 2 4 5 7 9 11"] = "Ionian", ["0 2 3 5 7 9 10"] = "Dorian", ["0 1 3 5 7 8 10"] = "Phrygian",
        ["0 2 4 6 7 9 11"] = "Lydian", ["0 2 4 5 7 9 10"] = "Mixolydian", ["0 2 3 5 7 8 10"] = "Aeolian",
        ["0 1 3 5 6 8 10"] = "Locrian", ["0 2 4 5 7 8 10"] = "Mixolydian b6", ["0 1 4 5 7 8 10"] = "Phrygian dominant",
    };

    static string ModeName(List<Note> scale)
    {
        var steps = string.Join(" ", scale.Select(n => (n.Pc - scale[0].Pc + 12) % 12));
        return ModeNames.TryGetValue(steps, out var name) ? name : $"({steps})";
    }

    static bool SamePcs(List<Note> a, List<Note> b) =>
        a.Select(n => n.Pc).ToHashSet().SetEquals(b.Select(n => n.Pc));

    static string Names(IEnumerable<Note> notes) => string.Join(" ", notes);
}
