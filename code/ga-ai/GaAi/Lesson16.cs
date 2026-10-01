namespace GaAi;

using System.Reflection;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Intents;
using GA.Business.ML.Search;
using GA.Domain.Core.Instruments;
using GA.Domain.Core.Instruments.Primitives;
using GA.Domain.Services.Fretboard.Voicings.Generation;
using Microsoft.Extensions.DependencyInjection;
using static Report;

// Lesson 16: the voicings of a chord. ChordVoicingsSkill answers "voicings for Cmaj7" without a
// model: TypedMusicalQueryExtractor reads the chord, MusicalQueryEncoder turns it into a query
// vector, and the OPTIC-K index returns the nearest voicings. The program asks which prompts reach
// the skill and which chord it reads, then plays every diagram it returns: here at the pin, and in
// GaMain with the voicing pipeline of GA's main.
public static class Lesson16
{
    public static void Run()
    {
        Lesson4.EnsureIndex();
        using var host = new ChatHost();
        using var client = host.CreateClient();
        host.WaitForWarmup();
        using var scope = host.Services.CreateScope();
        var intent = scope.ServiceProvider.GetServices<IIntent>().Single(i => i.Id == "skill.chordvoicings");
        var skill = SkillOf(intent);
        var extractor = scope.ServiceProvider.GetRequiredService<IMusicalQueryExtractor>();

        Examples(skill, extractor);
        Phrasings(skill, extractor);
        Symbols(extractor);
        Words(skill, extractor);
        var corpus = Corpus();
        // At the pin the skill prints GA's diagram strings, string 1 (high E) first
        ChordVoicingsProbe.Answers(skill, highFirst: true, corpus, "at the pin");
        ChordVoicingsProbe.FullAnswer(skill, "show me Dm7 voicings", highFirst: true);
    }

    static IOrchestratorSkill SkillOf(IIntent intent) =>
        (IOrchestratorSkill)intent.GetType().GetFields(BindingFlags.NonPublic | BindingFlags.Instance)
            .Select(f => f.GetValue(intent)).First(o => o is IOrchestratorSkill)!;

    static string Read(StructuredQuery q) =>
        q.PitchClasses is { Length: > 0 } pcs ? $"{q.ChordSymbol}: {ChordVoicingsProbe.Notes(pcs)}" : "no chord";

    static string Extra(StructuredQuery q) =>
        string.Join(", ", new[]
        {
            q.ModeName is { } m ? $"mode {m}" : null,
            q.Tags is { Count: > 0 } t ? $"tags {string.Join(" ", t)}" : null,
            q.Instrument is { } i ? $"instrument {i}" : null,
        }.Where(s => s is not null));

    static StructuredQuery Extract(IMusicalQueryExtractor extractor, string prompt) =>
        extractor.ExtractAsync(prompt).GetAwaiter().GetResult();

    // ---- Which prompts reach the skill, and what it reads ----

    static void Examples(IOrchestratorSkill skill, IMusicalQueryExtractor extractor)
    {
        Title("The skill's example prompts: CanHandle, and the chord TypedMusicalQueryExtractor reads");
        int[] w = [32, 10, 22];
        Row(w, "prompt", "CanHandle", "chord read", "also read");
        foreach (var p in ChordVoicingsProbe.Examples)
        {
            var q = Extract(extractor, p);
            Row(w, p, skill.CanHandle(p) ? "yes" : "no", Read(q), Extra(q));
        }
    }

    static readonly string[] OtherPhrasings =
    [
        "voicings for C", "G chord shapes", "how do I play a D chord", "voicings for A minor",
        "voicings for Am", "voicings for am", "Bb voicings please", "voicings for F#m7b5",
        "voicings for C7(b9)", "voicings for C/G",
    ];

    static void Phrasings(IOrchestratorSkill skill, IMusicalQueryExtractor extractor)
    {
        Title("Other phrasings");
        int[] w = [32, 10, 22];
        Row(w, "prompt", "CanHandle", "chord read", "also read");
        foreach (var p in OtherPhrasings)
        {
            var q = Extract(extractor, p);
            Row(w, p, skill.CanHandle(p) ? "yes" : "no", Read(q), Extra(q));
        }
    }

    // ---- The symbols and the words ----

    // The 51 symbols of ChordVocabulary.NormalizeQuality (lesson 15), with their textbook degrees
    static readonly (string Symbol, string Degrees)[] SymbolChords =
    [
        ("M", "1 3 5"), ("M7", "1 3 5 7"), ("maj", "1 3 5"), ("m", "1 b3 5"), ("min", "1 b3 5"), ("dim", "1 b3 b5"),
        ("aug", "1 3 #5"), ("+", "1 3 #5"), ("5", "1 5"), ("no3", "1 5"), ("sus2", "1 2 5"), ("sus4", "1 4 5"),
        ("sus", "1 4 5"), ("add9", "1 3 5 9"), ("6", "1 3 5 6"), ("maj6", "1 3 5 6"), ("m6", "1 b3 5 6"),
        ("min6", "1 b3 5 6"), ("7", "1 3 5 b7"), ("dom7", "1 3 5 b7"), ("maj7", "1 3 5 7"), ("ma7", "1 3 5 7"),
        ("Δ7", "1 3 5 7"), ("m7", "1 b3 5 b7"), ("min7", "1 b3 5 b7"), ("-7", "1 b3 5 b7"), ("dim7", "1 b3 b5 bb7"),
        ("°7", "1 b3 b5 bb7"), ("m7b5", "1 b3 b5 b7"), ("min7b5", "1 b3 b5 b7"), ("ø", "1 b3 b5 b7"),
        ("ø7", "1 b3 b5 b7"), ("7b5", "1 3 b5 b7"), ("7#5", "1 3 #5 b7"), ("7+5", "1 3 #5 b7"),
        ("7b9", "1 3 5 b7 b9"), ("7#9", "1 3 5 b7 #9"), ("7alt", "1 3 b5 #5 b7 b9 #9"), ("alt", "1 3 b5 #5 b7 b9 #9"),
        ("9", "1 3 5 b7 9"), ("maj9", "1 3 5 7 9"), ("m9", "1 b3 5 b7 9"), ("min9", "1 b3 5 b7 9"),
        ("11", "1 3 5 b7 9 11"), ("maj11", "1 3 5 7 9 11"), ("m11", "1 b3 5 b7 9 11"), ("min11", "1 b3 5 b7 9 11"),
        ("13", "1 3 5 b7 9 11 13"), ("maj13", "1 3 5 7 9 11 13"), ("m13", "1 b3 5 b7 9 11 13"),
        ("min13", "1 b3 5 b7 9 11 13"),
    ];

    static void Symbols(IMusicalQueryExtractor extractor)
    {
        Title($"The {SymbolChords.Length} symbols of lesson 15, asked as \"voicings for C…\"");
        var wrong = new List<string>();
        foreach (var (symbol, degrees) in SymbolChords)
        {
            var q = Extract(extractor, $"voicings for C{symbol}");
            var textbook = ChordVoicingsProbe.Chord("C", degrees);
            if (q.PitchClasses is { Length: > 0 } pcs && pcs.ToHashSet().SetEquals(textbook)) continue;
            wrong.Add($"C{symbol}: {Read(q)}, a textbook's {ChordVoicingsProbe.Notes(textbook)}");
        }

        Line($"read as a textbook spells them: {SymbolChords.Length - wrong.Count} of {SymbolChords.Length}");
        foreach (var s in wrong) Line($"  {s}");

        // ChordInfoSkill reads the same symbols with ChordVocabulary (lesson 15)
        var disagree = SymbolChords
            .Where(s => !(ChordPitchClasses.TryParse($"C{s.Symbol}", out _, out var pcs)
                          && pcs.ToHashSet().SetEquals(VocabularyChord(s.Symbol))))
            .Select(s => $"C{s.Symbol}").ToList();
        Line($"symbols ChordPitchClasses and ChordVocabulary read as different chords: {disagree.Count}: {string.Join(" ", disagree)}");
    }

    static HashSet<int> VocabularyChord(string symbol) =>
        [.. ChordVocabulary.GetFormula(ChordVocabulary.NormalizeQuality(symbol)).Intervals.Select(i => i % 12)];

    // The 31 words of ChordVocabulary.NormalizeQuality (lesson 15), with their textbook degrees
    static readonly (string Words, string Degrees)[] WordChords =
    [
        ("major", "1 3 5"), ("minor", "1 b3 5"), ("diminished", "1 b3 b5"), ("augmented", "1 3 #5"), ("power", "1 5"),
        ("dominant", "1 3 5 b7"), ("dominant 7", "1 3 5 b7"), ("major 6", "1 3 5 6"), ("minor 6", "1 b3 5 6"),
        ("major 7", "1 3 5 7"), ("minor 7", "1 b3 5 b7"), ("diminished 7", "1 b3 b5 bb7"), ("diminished7", "1 b3 b5 bb7"),
        ("half-diminished", "1 b3 b5 b7"), ("half diminished", "1 b3 b5 b7"), ("minor 7 flat 5", "1 b3 b5 b7"),
        ("dominant 7 flat 5", "1 3 b5 b7"), ("dominant 7 sharp 5", "1 3 #5 b7"), ("dominant 7 flat 9", "1 3 5 b7 b9"),
        ("dominant 7 sharp 9", "1 3 5 b7 #9"), ("altered", "1 3 b5 #5 b7 b9 #9"), ("altered dominant", "1 3 b5 #5 b7 b9 #9"),
        ("dominant 9", "1 3 5 b7 9"), ("major 9", "1 3 5 7 9"), ("minor 9", "1 b3 5 b7 9"), ("dominant 11", "1 3 5 b7 9 11"),
        ("major 11", "1 3 5 7 9 11"), ("minor 11", "1 b3 5 b7 9 11"), ("dominant 13", "1 3 5 b7 9 11 13"),
        ("major 13", "1 3 5 7 9 11 13"), ("minor 13", "1 b3 5 b7 9 11 13"),
    ];

    static void Words(IOrchestratorSkill skill, IMusicalQueryExtractor extractor)
    {
        Title($"The {WordChords.Length} spelled-out qualities, asked as \"voicings for C …\"");
        var right = 0; var handled = 0;
        var reads = new SortedDictionary<string, List<string>>(StringComparer.Ordinal);
        foreach (var (words, degrees) in WordChords)
        {
            var prompt = $"voicings for C {words}";
            if (skill.CanHandle(prompt)) handled++;
            var q = Extract(extractor, prompt);
            if (q.PitchClasses is { Length: > 0 } pcs && pcs.ToHashSet().SetEquals(ChordVoicingsProbe.Chord("C", degrees))) right++;
            var key = Read(q);
            if (!reads.TryGetValue(key, out var list)) reads[key] = list = [];
            list.Add(words);
        }

        Line($"CanHandle accepts {handled} of {WordChords.Length}; read as a textbook spells them: {right}");
        foreach (var (read, words) in reads) Line($"  read as {read}: {words.Count}, {string.Join(", ", words.Take(6))}{(words.Count > 6 ? ", …" : "")}");
    }

    // Lesson 3's corpus: GA's voicing generator on the first three frets, as in the index
    static List<Shape> Corpus()
    {
        var fretboard = new Fretboard(Tuning.Default, Lesson3.FretCount);
        return [.. VoicingGenerator.GenerateAllVoicingsAsync(fretboard, Lesson3.WindowSize, Lesson3.MinPlayedNotes, parallel: false)
            .ToBlockingEnumerable().Select(v => Shape.FromHighFirst(v.Diagram))];
    }
}
