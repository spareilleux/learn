namespace GaAi;

using System.Globalization;
using System.Text.Json;
using GA.Business.ML.Embeddings;
using GA.Business.ML.Search;
using GA.Domain.Services;
using GaMcpServer.Tools;
using static Report;

// Lesson 21's questions to ga_search_voicings and ga_voicing_vocabulary. The file is compiled into
// GaAi against the pinned GA and into GaMain against GA's main, where the search changed.
public static class SearchVoicingsProbe
{
    public sealed record Hit(double Score, Shape Shape, string Name);

    public sealed record Answer(string Chord, string Mode, List<string> Tags, List<Hit> Hits)
    {
        public string Voicings => string.Join(" ", Hits.Select(h => h.Shape.Chart));
        public string Scores => string.Join(" ", Hits.Select(h => S(h.Score)));
        public string Reading => string.Join(", ", new[]
        {
            Chord == "" ? "" : $"chord {Chord}", Mode == "" ? "" : $"mode {Mode}", Tags.Count == 0 ? "" : $"tags {string.Join(" ", Tags)}",
        }.Where(x => x != "")) is { Length: > 0 } r ? r : "nothing";
    }

    // The tool's answer, as an MCP client gets it; the server argument is only used for sampling,
    // which stays off
    public static Answer Ask(string query, int limit = 10)
    {
        var json = VoicingSearchTool.GaSearchVoicings(null!, query, limit).GetAwaiter().GetResult();
        var r = JsonDocument.Parse(json).RootElement;
        var i = r.GetProperty("interpreted");
        string Str(string p) => i.ValueKind == JsonValueKind.Object && i.GetProperty(p).ValueKind == JsonValueKind.String ? i.GetProperty(p).GetString()! : "";
        var tags = i.ValueKind == JsonValueKind.Object && i.GetProperty("tags").ValueKind == JsonValueKind.Array
            ? i.GetProperty("tags").EnumerateArray().Select(t => t.GetString()!).ToList() : [];
        var hits = r.GetProperty("results").EnumerateArray().Select(x => new Hit(x.GetProperty("score").GetDouble(),
            Shape.FromHighFirst(x.GetProperty("diagram").GetString()!), x.GetProperty("chordName").GetString() ?? "")).ToList();
        return new(Str("chord"), Str("mode"), tags, hits);
    }

    static string S(double score) => score.ToString("0.0000", CultureInfo.InvariantCulture);

    static (List<string> Roots, List<string> Qualities, List<string> Modes, List<string> Tags, List<(string Said, string Query)> Examples) Vocabulary()
    {
        var v = JsonDocument.Parse(VoicingVocabularyTool.GaVoicingVocabulary()).RootElement;
        List<string> L(string p) => [.. v.GetProperty(p).EnumerateArray().Select(x => x.GetString()!)];
        return (L("roots"), L("chordQualitySuffixes"), L("modes"), L("symbolicTags"),
            [.. v.GetProperty("queryConstructionExamples").EnumerateArray()
                .Select(e => (e.GetProperty("userSaid").GetString()!, e.GetProperty("canonicalQuery").GetString()!))]);
    }

    // Where SymbolicTagRegistry takes each bit's tags from (SymbolicTagRegistry.cs lines 46-111)
    static readonly string[] Sources =
    [
        "SemanticNomenclature, Structure", "SemanticNomenclature, Register", "SemanticNomenclature, Playability",
        "GuitarTechniques.yaml", "ArticulationTechniques.yaml", "SemanticNomenclature, CAGED",
        "SemanticNomenclature, Mood", "SemanticNomenclature, Genre", "AdvancedHarmony.yaml", "VoiceLeading.yaml",
        "AtonalTechniques.yaml, KeyModulationTechniques.yaml", "IconicChords",
    ];

    public static void VocabularyTable(string where)
    {
        Title($"What ga_voicing_vocabulary lists, and how ga_search_voicings reads it, {where}");
        var (roots, qualities, modes, tags, _) = Vocabulary();
        var registry = SymbolicTagRegistry.Instance;
        Line($"roots {roots.Count}, chord-quality suffixes {qualities.Count}, modes {modes.Count}, symbolic tags {tags.Count}");
        Line($"the query's SYMBOLIC partition: {EmbeddingSchema.Partitions.Single(p => p.Name == "SYMBOLIC").Dim} dimensions; a tag sets the one its bit names");
        int[] w = [4, 52, 5];
        Row(w, "bit", "where the registry takes it from", "tags", "the first four");
        for (var bit = 0; bit < Sources.Length; bit++)
        {
            var these = tags.Where(t => registry.GetBitIndex(t) == bit).ToList();
            Row(w, bit, Sources[bit], these.Count, string.Join(", ", these.Take(4)));
        }

        var aliases = tags.Where(t => !t.Contains('-') && tags.Any(o => o != t && o.Replace("-", "") == t)).ToList();
        Line($"entries listed twice, with and without hyphens: {aliases.Count}, {string.Join(", ", aliases.Take(4))}");
        // A famous chord's tag also gives the query that chord (TypedMusicalQueryExtractor.cs lines 157-174)
        var famous = tags.Count(t => Ask(t) is { Chord: not "" } a && a.Tags.Contains(t));
        Line($"tags that also give the query a chord, a famous chord's: {famous}");
        Line("entries read otherwise when typed alone:");
        foreach (var t in tags.Concat(modes))
        {
            var a = Ask(t);
            var right = modes.Contains(t) ? a.Mode == t && a.Tags.Count == 0 : a.Tags.SequenceEqual([t]) && a.Mode == "";
            if (!right) Line($"  {t}: {a.Reading}");
        }
    }

    public static void ExamplesTable(string where)
    {
        Title($"The vocabulary's five examples, as the user said them and as it rewrites them, {where}");
        int[] w = [28, 34, 17, 26, 15];
        Row(w, "the user said", "read as", "rewritten", "read as", "same voicings", "top scores");
        foreach (var (said, query) in Vocabulary().Examples)
        {
            var (a, b) = (Ask(said), Ask(query));
            Row(w, said, a.Reading, query, b.Reading, a.Voicings == b.Voicings ? "yes" : "no",
                $"{S(a.Hits[0].Score)}, {S(b.Hits[0].Score)}");
        }
        var (fminor, fm) = (Ask("F minor"), Ask("Fm"));
        Line($"F minor, read as {fminor.Reading}: {string.Join(", ", fminor.Hits.Take(3).Select(h => $"{h.Shape.Chart} {h.Name}"))}");
        Line($"Fm, read as {fm.Reading}: {string.Join(", ", fm.Hits.Take(3).Select(h => $"{h.Shape.Chart} {h.Name}"))}");
    }

    public static void ModesTable(List<Shape> corpus, string where)
    {
        Title($"The {Vocabulary().Modes.Count} modes after a chord, and alone, {where}");
        var modes = Vocabulary().Modes;
        int[] w = [7, 6, 30];
        Row(w, "chord", "modes", "the same ten voicings as alone", "the others, as read");
        foreach (var chord in new[] { "C", "Am", "G7", "Dm7" })
        {
            var alone = Ask(chord).Voicings;
            var others = modes.Select(m => (m, a: Ask($"{chord} {m}"))).Where(x => x.a.Voicings != alone).ToList();
            Row(w, chord, modes.Count, modes.Count - others.Count,
                string.Join("; ", others.Select(x => $"{x.m}: {x.a.Reading.Replace($"chord {chord}, ", "")}")));
        }

        var answers = modes.Select(m => (m, a: Ask(m))).ToList();
        var zero = answers.Where(x => x.a.Hits.All(h => h.Score == 0)).ToList();
        var first = string.Join(" ", corpus.Take(10).Select(s => s.Chart));
        Line($"modes alone: {zero.Count} of {modes.Count} answer with every score {S(0)}, " +
             $"all the same ten voicings: {(zero.Select(x => x.a.Voicings).Distinct().Count() == 1 ? "yes" : "no")}, " +
             $"the index's first ten: {(zero.Count > 0 && zero[0].a.Voicings == first ? "yes" : "no")}");
        Line($"  {string.Join(", ", zero[0].a.Hits.Select(h => $"{h.Shape.Chart} {h.Name}"))}");
        foreach (var (m, a) in answers.Except(zero)) Line($"  {m}: {a.Reading}, top score {S(a.Hits[0].Score)}");
    }

    public static void TagsTable(string where)
    {
        var tags = Vocabulary().Tags;
        var registry = SymbolicTagRegistry.Instance;
        Title($"The {tags.Count} symbolic tags after a chord, {where}");
        int[] w = [7, 6, 18, 32];
        Row(w, "chord", "tags", "different answers", "the same ten as the chord alone", "bits whose tags all answer alike");
        static string Key(Answer a) => a.Voicings + "|" + a.Scores;
        foreach (var chord in new[] { "Cmaj7", "Dm7", "G7" })
        {
            var alone = Key(Ask(chord));
            // The tags the tool reads as typed, by the bit each sets
            var answers = tags.Select(t => (t, a: Ask($"{chord} {t}"))).ToList();
            var alike = answers.Where(x => x.a.Tags.Contains(x.t)).GroupBy(x => registry.GetBitIndex(x.t))
                .Count(g => g.Select(x => Key(x.a)).Distinct().Count() == 1);
            Row(w, chord, tags.Count, answers.Select(x => Key(x.a)).Distinct().Count(),
                answers.Count(x => Key(x.a) == alone), $"{alike} of {Sources.Length}");
        }

        var bare = Key(Ask("Cmaj7"));
        Line($"for Cmaj7, the bits whose tags change nothing: " + string.Join(", ", Enumerable.Range(0, Sources.Length)
            .Where(b => tags.Where(t => registry.GetBitIndex(t) == b && Ask($"Cmaj7 {t}").Tags.Contains(t))
                .All(t => Key(Ask($"Cmaj7 {t}")) == bare))));
        foreach (var (x, y) in new[] { ("jazz", "rock-guitar"), ("shell-voicing", "rootless"), ("jazz", "shell-voicing") })
            Line($"for Cmaj7, {x} and {y}: the same answer {(Key(Ask($"Cmaj7 {x}")) == Key(Ask($"Cmaj7 {y}")) ? "yes" : "no")}");
    }

    // A rootless voicing of a chord: three notes or more, all the chord's, none of them its root
    public static void RootlessTable(List<Shape> corpus, string where)
    {
        Title($"\"rootless\" after a seventh chord, {where}");
        int[] w = [7, 22, 22];
        Row(w, "chord", "ten voicings, rootless", "rootless in the index", "the first three");
        var (asked, found) = (0, 0);
        foreach (var chord in new[] { "Cmaj7", "Dm7", "Em7", "Fmaj7", "G7", "Am7", "C7", "D7", "E7", "A7" })
        {
            ChordPitchClasses.TryParse(chord, out var root, out var pcs);
            var tones = pcs!.ToHashSet();
            bool Rootless(Shape s) => s.Midi.Length >= 3 && s.Pcs.IsSubsetOf(tones) && !s.Pcs.Contains(root!.Value) && s.Pcs.Count >= 3;
            var a = Ask($"{chord} rootless");
            var right = a.Hits.Count(h => Rootless(h.Shape));
            Row(w, chord, $"{right} of {a.Hits.Count}", corpus.Count(Rootless),
                string.Join(", ", a.Hits.Take(3).Select(h => $"{h.Shape.Chart} {h.Name}")));
            (asked, found) = (asked + a.Hits.Count, found + right);
        }
        Line($"voicings answered {asked}: rootless {found}");
    }

    // GA's own example queries: the tool's description, the vocabulary, the voicing-search SKILL.md and
    // the parked chatbot draft; then three of the course's
    static readonly string[] Prompts =
    [
        "Cmaj7 drop2 jazz", "F# Lydian", "Dm7", "something warm and mellow",
        "show me Cmaj7 voicings", "drop-2 Dm7", "rootless G7 shapes", "Lydian on guitar", "jazz voicings", "shell voicings",
        "voicings with a similar quality to F#m7b5", "something warm and dreamy", "something jazzy in F minor for a ballad",
        "Find me a mellow Cm9", "Rootless Dm7 voicing", "Drop-2 voicing for Gmaj7", "Bright open-position Em",
        "the best G7 voicing", "what is a good Am7 voicing", "a sad chord for the end of a song",
    ];

    public static void WordsTable(string where)
    {
        Title($"GA's example queries, and words read as tags, {where}");
        var registry = SymbolicTagRegistry.Instance;
        var known = registry.GetAllKnownTags().ToList();
        int[] w = [41, 34, 12];
        Row(w, "query", "read as", "top score", "words no tag spells, and the tag they match");
        foreach (var q in Prompts)
        {
            if (q == "the best G7 voicing") Line("the course's:");
            var a = Ask(q);
            var odd = a.Tags.Where(t => !known.Contains(t, StringComparer.OrdinalIgnoreCase))
                .Select(t => $"{t} → {known.First(k => t.Contains(k) || k.Contains(t))}");
            Row(w, q, a.Reading, a.Hits.Count == 0 ? "none" : S(a.Hits[0].Score), string.Join(", ", odd));
        }
    }

    public static void ScoresTable(string where)
    {
        Title($"The scores, {where}");
        var (roots, qualities, _, tags, _) = Vocabulary();
        var filled = EmbeddingSchema.Partitions.Where(p => p.Name is "STRUCTURE" or "SYMBOLIC" or "MODAL" or "ROOT").ToList();
        var empty = EmbeddingSchema.Partitions.Where(p => p.Name is "MORPHOLOGY" or "CONTEXT").ToList();
        Line($"partitions a query fills: {string.Join(", ", filled.Select(p => $"{p.Name} {p.SimilarityWeight:0.00}"))}; " +
             $"always empty: {string.Join(", ", empty.Select(p => $"{p.Name} {p.SimilarityWeight:0.00}"))}");
        Line($"the highest score a query can reach: {filled.Sum(p => p.SimilarityWeight):0.00}");
        var (best, arg) = (0.0, "");
        foreach (var q in roots.SelectMany(r => qualities.Prepend("").Select(s => r + s)))
            if (Ask(q, 1).Hits is [var h] && h.Score > best) (best, arg) = (h.Score, q);
        Line($"chord queries {roots.Count * (qualities.Count + 1)}: the highest top score {S(best)}, for {arg}");
        foreach (var q in new[] { "Cmaj7", "Cmaj7 jazz", "Cmaj7 drop2 jazz", "Cmaj7 shell dreamy jazz", "G7", "G7 shell", "G7 shell for" })
            Line($"  {q}: {S(Ask(q).Hits[0].Score)}");
    }

    // The answer the parked chatbot draft shows for "mellow Cm9" (DRAFT.md lines 57-68), its tab
    // turned into a chart, low E first
    public static void DraftTable(string where)
    {
        Title($"The parked draft's example answer for \"mellow Cm9\", {where}");
        string[] names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
        var shape = Shape.FromChart("x-3-5-3-3-3");
        ChordPitchClasses.TryParse("Cm9", out _, out var pcs);
        Line($"x-3-5-3-3-3 plays {string.Join(" ", shape.Midi.Select(m => names[m % 12]))}; " +
             $"Cm9 is {string.Join(" ", pcs!.Select(p => names[p]))}, and the voicing leaves out " +
             string.Join(" ", pcs!.Where(p => !shape.Pcs.Contains(p)).Select(p => names[p])));
        var tags = Vocabulary().Tags;
        foreach (var t in new[] { "low-density", "rootless-on-bass", "quartal-flavour" })
            Line($"its tag {t}: in the vocabulary {(tags.Contains(t) ? "yes" : "no")}, read as {Ask($"Cm9 {t}").Reading}");
    }
}
