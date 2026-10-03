// GA's AI: the lessons' questions to GA's main, a second commit next to the pin
namespace GaAi;

using FretboardVoicingsCLI;
using GaMcpServer.Tools;
using GA.Business.ML.Agents.Skills;
using GA.Business.ML.Embeddings;
using GA.Business.ML.Embeddings.Services;
using GA.Business.ML.Rag;
using GA.Business.ML.Search;
using GA.Domain.Core.Instruments;
using GA.Domain.Core.Instruments.Primitives;
using GA.Domain.Services.Fretboard.Voicings.Analysis;
using GA.Domain.Services.Fretboard.Voicings.Generation;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging.Abstractions;

public static class Entry
{
    public static int Main(string[] args)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        switch (args)
        {
            case ["l16"]:
                Lesson16();
                return 0;
            case ["l17"]:
                Lesson17();
                return 0;
            case ["l19"]:
                Lesson19();
                return 0;
            case ["l20"]:
                Lesson20();
                return 0;
            case ["l21"]:
                Lesson21();
                return 0;
            default:
                Console.Error.WriteLine("usage: GaMain l16|l17|l19|l20|l21");
                return 2;
        }
    }

    // Lesson 21: ga_search_voicings, its vocabulary and the readers they call are the same on main,
    // but the search changed; the questions whose answers depend on it, against lesson 3's index
    // built with main's code
    static void Lesson21()
    {
        Console.WriteLine("# l21, GA's main");
        var indexPath = Path.Combine(AppContext.BaseDirectory, "out", "optick-mini-main.index");
        var corpus = WriteIndex(indexPath, print: false);
        SearchIndex.Use(indexPath);
        SearchVoicingsProbe.ExamplesTable("on main");
        SearchVoicingsProbe.ModesTable(corpus, "on main");
        SearchVoicingsProbe.TagsTable("on main");
        SearchVoicingsProbe.RootlessTable(corpus, "on main");
        SearchVoicingsProbe.ScoresTable("on main");
    }

    // Lesson 20: ga_generate_progression and the parser it calls are the same on main; only the
    // stitching with ga_voice_leading_pair depends on main's search
    static void Lesson20()
    {
        Console.WriteLine("# l20, GA's main");
        var indexPath = Path.Combine(AppContext.BaseDirectory, "out", "optick-mini-main.index");
        WriteIndex(indexPath, print: false);
        SearchIndex.Use(indexPath);
        ProgressionProbe.StitchTable("on main");
    }

    // Lesson 19: GaMcpServer's ga_voice_leading_pair is the same on main, but the search it calls
    // changed; the same questions, against lesson 3's index built with main's code
    static void Lesson19()
    {
        Console.WriteLine("# l19, GA's main");
        var indexPath = Path.Combine(AppContext.BaseDirectory, "out", "optick-mini-main.index");
        var corpus = WriteIndex(indexPath, print: false);
        SearchIndex.Use(indexPath);
        VoiceLeadingPairProbe.CandidatesTable(corpus, "on main");
        VoiceLeadingPairProbe.PairsTable(corpus, "on main");
        VoiceLeadingPairProbe.MoreCandidates("on main");
        VoiceLeadingPairProbe.DistanceCheck("on main");
    }

    // Lesson 17: on main, AlternateTuningsSkill's name patterns reject a sharp or flat after the
    // letter; the reading of six notes is the pin's
    static void Lesson17()
    {
        Console.WriteLine("# l17, GA's main");
        var skill = new AlternateTuningsSkill(NullLogger<AlternateTuningsSkill>.Instance);
        TuningsProbe.ByNotes(skill, "on main");
        TuningsProbe.Others(skill, "on main");
    }

    static void Lesson16()
    {
        Console.WriteLine("# l16, GA's main");
        var indexPath = Path.Combine(AppContext.BaseDirectory, "out", "optick-mini-main.index");
        var corpus = WriteIndex(indexPath);
        var skill = new ChordVoicingsSkill(
            NullLogger<ChordVoicingsSkill>.Instance,
            new EnhancedVoicingSearchService(new VoicingIndexingService(), new OptickSearchStrategy(indexPath)),
            Extractor(),
            new MusicalQueryEncoder(new ModalVectorService()));
        // On main the skill prints its diagrams in chart order, low E first
        ChordVoicingsProbe.Answers(skill, highFirst: false, corpus, "on main");
        ChordVoicingsProbe.TechniqueAnswers(skill, highFirst: false, corpus, "on main");
        ChordVoicingsProbe.FullAnswer(skill, "open chord shape for E minor", highFirst: false);
    }

    // The chatbot host's extractor: the typed tier, then a model that is never reached here
    static IMusicalQueryExtractor Extractor() => new CompositeMusicalQueryExtractor(
        new TypedMusicalQueryExtractor(),
        new LlmMusicalQueryExtractor(new NoModel(), new MemoryCache(new MemoryCacheOptions()),
            NullLogger<LlmMusicalQueryExtractor>.Instance));

    // Lesson 3's corpus and index, built with main's generator, analysis, embedding and writer
    static List<Shape> WriteIndex(string path, bool print = true)
    {
        var fretboard = new Fretboard(Tuning.Default, 3);
        var voicings = VoicingGenerator.GenerateAllVoicingsAsync(fretboard, 3, 3, parallel: false).ToBlockingEnumerable().ToList();
        var generator = new MusicalEmbeddingGenerator(new ModalVectorService(), new PhaseSphereService());
        var entries = voicings.Select(v =>
        {
            var analysis = VoicingAnalyzer.Analyze(v);
            var doc = VoicingDocumentFactory.FromAnalysis(v, analysis, tuningId: "guitar");
            var raw = generator.GenerateEmbeddingAsync(doc).GetAwaiter().GetResult();
            return new VoicingEntry(raw, v.Diagram, "guitar", [.. doc.MidiNotes], analysis.ChordId.ChordName);
        }).ToList();
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        using (var writer = new OptickIndexWriter(path))
        {
            writer.WriteIndex(entries);
        }

        if (!print) return [.. voicings.Select(v => Shape.FromHighFirst(v.Diagram))];
        Report.Title("Corpus on main: GA's VoicingGenerator, standard tuning, 3 frets, window 3, at least 3 notes");
        Report.Line($"voicings                 {entries.Count}");
        Report.Line("the names main's analysis gives the voicings of five chords, with their counts:");
        foreach (var (chord, pcs) in Named)
        {
            var names = entries.Where(e => e.MidiNotes.Select(m => m % 12).ToHashSet().SetEquals(pcs))
                .GroupBy(e => e.QualityInferred).OrderByDescending(g => g.Count()).ThenBy(g => g.Key, StringComparer.Ordinal)
                .Select(g => $"{g.Key} {g.Count()}");
            Report.Line($"  {chord,-22} {string.Join(", ", names)}");
        }

        return [.. voicings.Select(v => Shape.FromHighFirst(v.Diagram))];
    }

    static readonly (string Chord, int[] Pcs)[] Named =
    [
        ("C6, C E G A", [0, 4, 7, 9]), ("C6/9, C D E G A", [0, 2, 4, 7, 9]), ("Dsus4, D G A", [2, 7, 9]),
        ("Dbaug, Db F A", [1, 5, 9]), ("Caug, C E G#", [0, 4, 8]),
    ];

    sealed class NoModel : IChatClient
    {
        public Task<ChatResponse> GetResponseAsync(IEnumerable<ChatMessage> messages, ChatOptions? options = null, CancellationToken cancellationToken = default) =>
            throw new HttpRequestException("no model in the course");
        public IAsyncEnumerable<ChatResponseUpdate> GetStreamingResponseAsync(IEnumerable<ChatMessage> messages, ChatOptions? options = null, CancellationToken cancellationToken = default) =>
            throw new HttpRequestException("no model in the course");
        public object? GetService(Type serviceType, object? serviceKey = null) => null;
        public void Dispose() { }
    }
}
