namespace GaAi;

using System.Reflection;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Intents;
using GA.Business.ML.Agents.Mcp;
using GA.Business.ML.Agents.Skills;
using Microsoft.Extensions.DependencyInjection;
using static Report;

// Lesson 15: the notes of a chord. ChordInfoSkill answers without a model: it spells the chord a
// question names, or names the chord a list of notes makes. ga_chord_info, the MCP tool of the
// chord-info SKILL.md, spells a chord symbol from the same vocabulary, ChordVocabulary. The program
// asks the skill its own example prompts, every suffix the vocabulary knows, symbols beyond it, and
// each chord it spells, then gives it back its own spelling as a list of notes and calls the tool.
public static class Lesson15
{
    public static void Run()
    {
        Lesson4.EnsureIndex();
        using var host = new ChatHost();
        using var client = host.CreateClient();
        host.WaitForWarmup();
        using var scope = host.Services.CreateScope();
        var intent = scope.ServiceProvider.GetServices<IIntent>().Single(i => i.Id == "skill.chordinfo");
        var skill = SkillOf(intent);

        Examples(intent, skill);
        Vocabulary(skill);
        Beyond(skill);
        var spelled = Spelling(skill);
        FromNotes(skill, spelled);
        Tool();
    }

    static IOrchestratorSkill SkillOf(IIntent intent) =>
        (IOrchestratorSkill)intent.GetType().GetFields(BindingFlags.NonPublic | BindingFlags.Instance)
            .Select(f => f.GetValue(intent)).First(o => o is IOrchestratorSkill)!;

    // ---- Reading the skill's answer ----

    // What the skill read: its Evidence lines "Root: …", "Quality: …" and "Notes: …"
    record Read(string Root, string Quality, string[] Notes)
    {
        // "major 7 chord" and "half-diminished chord (m7b5)" name the vocabulary's quality before " chord"
        public string Canonical => Quality[..Quality.IndexOf(" chord", StringComparison.Ordinal)];
        public override string ToString() => $"{Root} {Canonical}: {string.Join(" ", Notes)}";
    }

    static (string Result, Read? Read) Ask(IOrchestratorSkill skill, string prompt)
    {
        var response = skill.ExecuteAsync(prompt).GetAwaiter().GetResult();
        string? Field(string name) =>
            response.Evidence.FirstOrDefault(e => e.StartsWith(name + ": ", StringComparison.Ordinal))?[(name.Length + 2)..];
        var read = Field("Notes") is { } notes ? new Read(Field("Root")!, Field("Quality")!, notes.Split(", ")) : null;
        return (response.Result, read);
    }

    static string Show(Read? read, string result) => read?.ToString() ?? $"no chord: \"{result}\"";

    // ---- The example prompts ----

    // The notes a textbook spells for each example prompt; null where the prompt names a quality and
    // no root
    static readonly (string Prompt, string? Textbook)[] Textbook =
    [
        ("What is a C major chord?", "C E G"),
        ("What notes are in Dm7?", "D F A C"),
        ("Notes in an F minor chord", "F Ab C"),
        ("What chord contains C E G?", "C E G"),
        ("Spell a B7 chord", "B D# F# A"),
        ("What notes are in a Cmaj7?", "C E G B"),
        ("Tell me the tones in F#m7b5", "F# A C E"),
        ("tell me about Dm7", "D F A C"),
        ("tell me about a Cmaj7 chord", "C E G B"),
        ("what makes a chord a major seventh", null),
        ("what makes a chord diminished", null),
        ("what makes a chord a dominant seventh", null),
        ("What chord is C E G", "C E G"),
        ("What chord is F A C E", "F A C E"),
        ("Which chord contains the notes G B D F", "G B D F"),
        ("What chord is C E G Bb D", "C E G Bb D"),
        ("anatomy of a D7sus4 chord", "D G A C"),
        ("break down Gmaj13 for me", "G B D F# A C E"),
        ("what is a C add 9 chord", "C E G D"),
        ("give me the notes of an F#m7b5", "F# A C E"),
        ("tones in a Bb diminished seventh", "Bb Db Fb Abb"),
        ("What is C7b9", "C E G Bb Db"),
        ("What is Cmaj9", "C E G B D"),
        ("What is Dm7b5", "D F Ab C"),
        ("What is F#m7", "F# A C# E"),
        ("What is Bbdim7", "Bb Db Fb Abb"),
        ("what notes are in a C major triad", "C E G"),
        ("what are the notes of an A minor triad", "A C E"),
        ("what notes make up a G7 chord", "G B D F"),
        ("which notes form a B diminished triad", "B D F"),
        ("spell a G7 chord", "G B D F"),
        ("what notes are in an E major chord", "E G# B"),
    ];

    static void Examples(IIntent intent, IOrchestratorSkill skill)
    {
        Title("The skill's own example prompts");
        Line($"{intent.Id}: {skill.GetType().Name}, {intent.ExamplePrompts.Count} example prompts");
        var textbook = Textbook.ToDictionary(t => t.Prompt, t => t.Textbook);
        int same = 0, named = 0, qualityOnly = 0, sameAnswer = 0;
        foreach (var prompt in intent.ExamplePrompts)
        {
            var (result, read) = Ask(skill, prompt);
            var answer = intent.ExecuteAsync(prompt).GetAwaiter().GetResult().Answer;
            if (answer == result) sameAnswer++;
            Line($"\"{prompt}\"  CanHandle {(skill.CanHandle(prompt) ? "yes" : "no")}");
            Line($"  {Show(read, result)}");
            var expected = textbook[prompt];
            if (expected is null)
            {
                qualityOnly++;
                if (read is not null) Line($"  the question names a quality, no root");
                continue;
            }
            named++;
            if (read is not null && string.Join(" ", read.Notes) == expected) same++;
            else Line($"  the textbook: {expected}");
        }
        Line($"The intent's answer is the skill's Result for {sameAnswer} of {intent.ExamplePrompts.Count}");
        Line($"The textbook's notes for {same} of the {named} prompts that name a chord or its notes");
        Line($"CanHandle accepts {intent.ExamplePrompts.Count(skill.CanHandle)} of {intent.ExamplePrompts.Count}");
    }

    // ---- The vocabulary ----

    // The suffixes ChordVocabulary.NormalizeQuality maps (ChordVocabulary.cs lines 59-104), in its
    // order: symbols are asked as "What notes are in C<suffix>?", words as "What notes are in a
    // C <words> chord?"
    static readonly string[] Symbols =
    [
        "M", "M7", "maj", "m", "min", "dim", "aug", "+", "5", "no3", "sus2", "sus4", "sus", "add9",
        "6", "maj6", "m6", "min6", "7", "dom7", "maj7", "ma7", "Δ7", "m7", "min7", "-7", "dim7", "°7",
        "m7b5", "min7b5", "ø", "ø7", "7b5", "7#5", "7+5", "7b9", "7#9", "7alt", "alt",
        "9", "maj9", "m9", "min9", "11", "maj11", "m11", "min11", "13", "maj13", "m13", "min13",
    ];

    static readonly string[] Words =
    [
        "major", "minor", "diminished", "augmented", "power", "dominant", "dominant 7", "major 6",
        "minor 6", "major 7", "minor 7", "diminished 7", "diminished7", "half-diminished",
        "half diminished", "minor 7 flat 5", "dominant 7 flat 5", "dominant 7 sharp 5",
        "dominant 7 flat 9", "dominant 7 sharp 9", "altered", "altered dominant", "dominant 9",
        "major 9", "minor 9", "dominant 11", "major 11", "minor 11", "dominant 13", "major 13",
        "minor 13",
    ];

    static string Vocab(string suffix) => ChordVocabulary.GetFormula(ChordVocabulary.NormalizeQuality(suffix)).Quality;

    static string ToolSays(string symbol) =>
        ChordMcpTools.GetChordInfo(symbol) is { Error: null } r ? r.Quality : "error";

    static void Vocabulary(IOrchestratorSkill skill)
    {
        Title("Every suffix the vocabulary knows");
        var suffixes = Symbols.Select(s => (Suffix: s, Prompt: $"What notes are in C{s}?"))
            .Concat(Words.Select(w => (Suffix: w, Prompt: $"What notes are in a C {w} chord?")))
            .ToArray();
        var skillOk = 0;
        foreach (var (suffix, prompt) in suffixes)
        {
            var vocab = Vocab(suffix);
            var (_, read) = Ask(skill, prompt);
            var skillSays = read is null ? "no chord" : read.Root == "C" ? read.Canonical : $"{read.Root} {read.Canonical}";
            if (skillSays == vocab) skillOk++;
            else Line($"\"{prompt}\"  the vocabulary: {vocab}, the skill: {skillSays}");
        }
        Line($"The skill reads {skillOk} of {suffixes.Length} suffixes as the vocabulary does ({Symbols.Length} symbols, {Words.Length} words)");
        Line($"NormalizeQuality(\"Δ7\") returns \"{ChordVocabulary.NormalizeQuality("Δ7")}\", which GetFormula doesn't know");
        var toolReads = Symbols.Where(s => ToolSays($"C{s}") == Vocab(s)).ToArray();
        Line($"ga_chord_info reads {toolReads.Length} of the {Symbols.Length} symbols: {string.Join(" ", toolReads)}");
    }

    // ---- Beyond the vocabulary ----

    // Symbols and phrasings the vocabulary has no entry for, with the notes a textbook spells
    static readonly (string Prompt, string Textbook)[] Others =
    [
        ("What notes are in Cmaj7#11?", "C E G B F#"),
        ("What notes are in C7#11?", "C E G Bb F#"),
        ("What notes are in C7(b9)?", "C E G Bb Db"),
        ("What notes are in Cm(maj7)?", "C Eb G B"),
        ("What notes are in C6/9?", "C E G A D"),
        ("What notes are in C7#5#9?", "C E G# Bb D#"),
        ("What notes are in C7sus4?", "C F G Bb"),
        ("What notes are in C/E?", "C E G"),
        ("What notes are in B♭7?", "Bb D F Ab"),
        ("What notes are in an E♭ major chord?", "Eb G Bb"),
        ("I am learning Cmaj7, what notes are in it?", "C E G B"),
        ("Am I right that G7 has an F?", "G B D F"),
    ];

    static void Beyond(IOrchestratorSkill skill)
    {
        Title("Beyond the vocabulary");
        foreach (var (prompt, textbook) in Others)
        {
            var (result, read) = Ask(skill, prompt);
            Line($"\"{prompt}\"");
            Line($"  {Show(read, result)}");
            Line($"  the textbook: {textbook}");
        }
    }

    // ---- Spelling ----

    // The 21 roots of ChordVocabulary.PitchClasses, and for each quality the skill spells, a symbol it
    // reads and the chord's degrees
    static readonly string[] Roots =
        ["C", "C#", "Db", "D", "D#", "Eb", "E", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B", "B#", "Cb", "E#", "Fb"];

    static readonly (string Quality, string Symbol, string Degrees)[] Qualities =
    [
        ("major", "maj", "1 3 5"), ("minor", "m", "1 b3 5"), ("diminished", "dim", "1 b3 b5"),
        ("augmented", "aug", "1 3 #5"), ("sus2", "sus2", "1 2 5"), ("sus4", "sus4", "1 4 5"),
        ("add9", "add9", "1 3 5 9"), ("major 6", "6", "1 3 5 6"), ("minor 6", "m6", "1 b3 5 6"),
        ("dominant 7", "7", "1 3 5 b7"), ("major 7", "maj7", "1 3 5 7"), ("minor 7", "m7", "1 b3 5 b7"),
        ("diminished 7", "dim7", "1 b3 b5 bb7"), ("half-diminished", "m7b5", "1 b3 b5 b7"),
        ("dominant 7 flat 5", "7b5", "1 3 b5 b7"), ("dominant 7 sharp 5", "7#5", "1 3 #5 b7"),
        ("dominant 7 flat 9", "7b9", "1 3 5 b7 b9"), ("dominant 7 sharp 9", "7#9", "1 3 5 b7 #9"),
        ("altered dominant", "7alt", "1 3 b5 #5 b7 b9 #9"),
        ("dominant 9", "9", "1 3 5 b7 9"), ("major 9", "maj9", "1 3 5 7 9"), ("minor 9", "m9", "1 b3 5 b7 9"),
        ("dominant 11", "11", "1 3 5 b7 9 11"), ("major 11", "maj11", "1 3 5 7 9 11"),
        ("minor 11", "m11", "1 b3 5 b7 9 11"), ("dominant 13", "13", "1 3 5 b7 9 11 13"),
        ("major 13", "maj13", "1 3 5 7 9 11 13"), ("minor 13", "m13", "1 b3 5 b7 9 11 13"),
    ];

    const string Letters = "CDEFGAB";
    static readonly int[] Naturals = [0, 2, 4, 5, 7, 9, 11];

    // A degree's letter above the root's, and its semitones above the root: 3 is two letters and four
    // semitones up, b3 the same letter a semitone lower
    static string SpellDegree(string root, string degree)
    {
        var number = int.Parse(degree.TrimStart('b', '#'));
        var steps = (number - 1) % 7;
        var semitones = Naturals[steps] + (number > 7 ? 12 : 0)
            - degree.TakeWhile(c => c == 'b').Count() + degree.TakeWhile(c => c == '#').Count();
        var rootLetter = Letters.IndexOf(root[0]);
        var rootPc = Naturals[rootLetter] + root[1..].Sum(c => c == '#' ? 1 : -1);
        var letter = (rootLetter + steps) % 7;
        var accidental = ((rootPc + semitones - Naturals[letter]) % 12 + 18) % 12 - 6;
        return Letters[letter] + new string(accidental < 0 ? 'b' : '#', Math.Abs(accidental));
    }

    static string[] SpellChord(string root, string degrees) => [.. degrees.Split(' ').Select(d => SpellDegree(root, d))];

    static List<(string Root, string Quality, string[] Notes)> Spelling(IOrchestratorSkill skill)
    {
        Title("Spelling: 21 roots, 28 qualities");
        var spelled = new List<(string, string, string[])>();
        var differ = new List<string>();
        var multiple = 0;
        foreach (var (quality, symbol, degrees) in Qualities)
        foreach (var root in Roots)
        {
            var (result, read) = Ask(skill, $"What notes are in {root}{symbol}?");
            if (read is null || read.Root != root || read.Canonical != quality)
            {
                differ.Add($"{root}{symbol}: {Show(read, result)}");
                continue;
            }
            spelled.Add((root, quality, read.Notes));
            var textbook = SpellChord(root, degrees);
            if (!read.Notes.SequenceEqual(textbook))
                differ.Add($"{root}{symbol}: skill {string.Join(" ", read.Notes)}, textbook {string.Join(" ", textbook)}");
            if (read.Notes.Any(n => n.Length > 2)) multiple++;
        }
        var total = Qualities.Length * Roots.Length;
        Line($"The skill spells {total - differ.Count} of {total} chords as the textbook does");
        foreach (var d in differ.Take(3)) Line($"  {d}");
        if (differ.Count > 3) Line($"  … and {differ.Count - 3} more");
        Line($"The chords that differ: {string.Join(", ", differ.GroupBy(d => d[..d.IndexOf(':')].TrimStart(Letters.ToCharArray()).TrimStart('#', 'b')).Select(g => $"{g.Count()} {g.Key}"))}");
        var alt = skill.ExecuteAsync("What notes are in C7alt?").GetAwaiter().GetResult();
        Line($"C7alt: {alt.Evidence.First(e => e.StartsWith("Intervals: ", StringComparison.Ordinal))}");
        Line($"Chords with a double or triple accidental: {multiple} of {spelled.Count}");
        return spelled;
    }

    // ---- From notes to a chord ----

    static void FromNotes(IOrchestratorSkill skill, List<(string Root, string Quality, string[] Notes)> spelled)
    {
        Title("The skill's own spellings, asked back as notes");
        // The qualities the skill names from a list of notes, ChordInfoSkill.CandidateFormulas
        var candidates = ((IEnumerable<(string Quality, ChordFormula Formula)>)typeof(ChordInfoSkill)
            .GetMethod("CandidateFormulas", BindingFlags.NonPublic | BindingFlags.Static)!.Invoke(null, null)!)
            .Select(c => c.Quality).ToHashSet();
        Line($"It names {candidates.Count} qualities from notes; not {string.Join(", ", Qualities.Select(q => q.Quality).Where(q => !candidates.Contains(q)))}");
        string[] groups =
        [
            "a quality it names, single accidentals",
            "a quality it names, a double or triple accidental",
            "a quality it doesn't name, 3 to 5 notes",
            "6 or 7 notes",
        ];
        string GroupOf(string quality, string[] notes) =>
            notes.Length > 5 ? groups[3]
            : !candidates.Contains(quality) ? groups[2]
            : notes.Any(n => n.Length > 2) ? groups[1]
            : groups[0];
        foreach (var group in groups)
        {
            int count = 0, back = 0, other = 0, none = 0;
            string? example = null;
            foreach (var (root, quality, notes) in spelled.Where(s => GroupOf(s.Quality, s.Notes) == group))
            {
                count++;
                var prompt = $"What chord is {string.Join(" ", notes)}";
                var (result, read) = Ask(skill, prompt);
                if (read is not null && read.Root == root && read.Canonical == quality) { back++; continue; }
                if (read is null) none++; else other++;
                example ??= $"\"{prompt}\" → {Show(read, result)}";
            }
            Line($"{group}: {count} chords, named back {back}, as another chord {other}, not named {none}");
            if (example is not null) Line($"  {example}");
        }

        Title("Lists of notes");
        foreach (var prompt in new[]
                 {
                     "What chord is C E G# B",
                     "What chord is C E G Bb Db",
                     "What chord is C Eb Gb Bbb",
                     "What chord is F# A# C##",
                     "Which chord has a C, an E and a G?",
                     "What chord is C E G B♭",
                 })
        {
            var (result, read) = Ask(skill, prompt);
            Line($"\"{prompt}\" → {Show(read, result)}");
        }
    }

    // ---- The tool ----

    static void Tool()
    {
        Title("ga_chord_info, the tool of the SKILL.md");
        // The symbols of the SKILL.md's table "Supported quality suffixes" (lines 60-72)
        string[] table = ["C", "Cmaj", "CM", "Cm", "Cmin", "Cdim", "Caug", "C7", "Cdom7", "Cmaj7", "CM7", "Cm7", "Cmin7", "Cdim7", "Cm7b5", "Cmin7b5"];
        var errors = table.Where(s => ChordMcpTools.GetChordInfo(s).Error is not null).ToArray();
        Line($"The SKILL.md's table lists {table.Length} symbols, the tool reads {table.Length - errors.Length}");
        foreach (var symbol in errors) Line($"  {symbol}: \"{ChordMcpTools.GetChordInfo(symbol).Error}\"");
        // The examples of the tool's description
        (string Symbol, string Notes)[] described =
            [("Cmaj7", "C E G B"), ("F#m", "F# A C#"), ("Bbdim", "Bb Db Fb"), ("Cdim7", "C Eb Gb Bbb"), ("Bm7b5", "B D F A")];
        var agree = described.Count(d => string.Join(" ", ChordMcpTools.GetChordInfo(d.Symbol).Notes) == d.Notes);
        Line($"The tool returns the notes its description gives for {agree} of its {described.Length} examples");
    }
}
