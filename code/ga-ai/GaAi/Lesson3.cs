namespace GaAi;

using System.Text;
using FretboardVoicingsCLI;
using GA.Business.ML.Embeddings;
using GA.Business.ML.Embeddings.Services;
using GA.Business.ML.Search;
using GA.Domain.Core.Instruments;
using GA.Domain.Core.Instruments.Primitives;
using GA.Domain.Services.Fretboard.Voicings.Generation;
using static Report;

// Lesson 3: build a small OPTIC-K index with GA's writer, read it back and search it
public static class Lesson3
{
    public const int FretCount = 3;
    public const int WindowSize = 3;
    public const int MinPlayedNotes = 3;

    public static string IndexPath => Path.Combine(AppContext.BaseDirectory, "out", "optick-mini.index");

    public static void Run()
    {
        var corpus = BuildCorpus(print: true);
        WriteIndex(corpus, print: true);
        ReadBack(corpus);
        Search(corpus);
        DeadDimensions(corpus);
    }

    // GA's voicing generator on the first frets of a guitar, then GA's analysis and embedding
    public static List<Embedded> BuildCorpus(bool print)
    {
        var fretboard = new Fretboard(Tuning.Default, FretCount);
        var voicings = VoicingGenerator.GenerateAllVoicingsAsync(fretboard, WindowSize, MinPlayedNotes, parallel: false)
            .ToBlockingEnumerable().ToList();
        var corpus = voicings.Select(v => Voicings.Embed(v.Diagram, v)).ToList();
        if (!print) return corpus;

        Title($"Corpus: GA's VoicingGenerator, standard tuning, {FretCount} frets, window {WindowSize}, at least {MinPlayedNotes} notes");
        Line($"voicings                 {corpus.Count}");
        foreach (var g in corpus.GroupBy(e => e.Doc.MidiNotes.Length).OrderBy(g => g.Key))
            Line($"  with {g.Key} notes           {g.Count()}");
        Line("first three, as generated:");
        int[] w = [14, 18, 12];
        Row(w, "diagram", "MIDI (in order)", "GA name", "doc root");
        foreach (var e in corpus.Take(3))
            Row(w, e.Voicing.Diagram, Ints(e.Doc.MidiNotes), e.Analysis.ChordId.ChordName, Voicings.NoteName(e.Doc.RootPitchClass ?? 0));
        return corpus;
    }

    public static void WriteIndex(List<Embedded> corpus, bool print)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(IndexPath)!);
        var entries = corpus.Select(e => new VoicingEntry(
            e.Raw, e.Voicing.Diagram, "guitar", [.. e.Doc.MidiNotes], e.Analysis.ChordId.ChordName)).ToList();
        using (var writer = new OptickIndexWriter(IndexPath))
        {
            writer.WriteIndex(entries);
        }

        if (!print) return;

        Title("The header OptickIndexWriter wrote (little-endian)");
        using var r = new BinaryReader(File.OpenRead(IndexPath));
        Line($"magic                    {Encoding.ASCII.GetString(r.ReadBytes(4))}");
        Line($"format version           {r.ReadUInt32()}");
        var headerSize = r.ReadUInt32();
        Line($"header size              {headerSize}");
        Line($"schema hash              0x{r.ReadUInt32():X8}");
        Line($"endian marker            0x{r.ReadUInt16():X4}");
        r.ReadUInt16();
        var dim = r.ReadUInt32();
        Line($"dimension                {dim}");
        var count = r.ReadUInt64();
        Line($"voicings                 {count}");
        var instruments = r.ReadByte();
        r.ReadBytes(7);
        Line($"instruments              {instruments}");
        foreach (var name in new[] { "guitar", "bass", "ukulele" })
            Line($"  {name,-8} offset {r.ReadUInt64()}, count {r.ReadUInt64()}");
        var offsetsTable = r.ReadUInt64();
        var vectors = r.ReadUInt64();
        var metadata = r.ReadUInt64();
        var metadataLength = r.ReadUInt64();
        Line($"metadata offsets at      {offsetsTable}");
        Line($"vectors at               {vectors} ({count} x {dim} x 4 bytes = {count * dim * 4})");
        Line($"metadata at              {metadata} ({metadataLength} bytes of msgpack)");
        var weights = Enumerable.Range(0, (int)dim).Select(_ => r.ReadSingle()).ToArray();
        Line($"sqrt weights, first dims {Vec(weights.Take(3))} ... ROOT {Vec(weights.TakeLast(1))}");
        Line($"file size                {new FileInfo(IndexPath).Length} bytes");
    }

    static void ReadBack(List<Embedded> corpus)
    {
        Title("OptickIndexReader");
        using var reader = new OptickIndexReader(IndexPath);
        Line($"Count                    {reader.Count}");
        Line($"guitar range             {reader.GetInstrumentRange("guitar")}");
        Line($"bass range               {reader.GetInstrumentRange("bass")}");
        var first = reader.GetVector(0).ToArray();
        var meta = reader.GetMetadata(0);
        Line($"voicing 0                {meta.Diagram} {meta.QualityInferred} [{Ints(meta.MidiNotes)}]");
        var normSq = 0.0;
        foreach (var v in first) normSq += v * v;
        Line($"its squared norm         {F(normSq)}");
        var expected = EmbeddingSchema.ExtractCompact(corpus[0].RawDouble);
        var maxDiff = expected.Select((x, i) => Math.Abs(x - first[i])).Max();
        Line($"max |disk - ExtractCompact| {maxDiff:0.0e0}");
    }

    static void Search(List<Embedded> corpus)
    {
        var encoder = new MusicalQueryEncoder(new ModalVectorService());
        using var strategy = new OptickSearchStrategy(IndexPath);

        foreach (var symbol in new[] { "Cmaj7", "Am7", "C" })
        {
            var query = encoder.Encode(new StructuredQuery(symbol, null, null, null, null));
            Title($"HybridSearchAsync for \"{symbol}\" (query vector from MusicalQueryEncoder)");
            var lit = EmbeddingSchema.SimilarityPartitions
                .Select((p, i) => (p, i))
                .Select(x => (x.p.Name, Start: EmbeddingSchema.SimilarityPartitions.Take(x.i).Sum(q => q.Dim), x.p.Dim))
                .Where(x => query.Skip(x.Start).Take(x.Dim).Any(v => v != 0))
                .Select(x => x.Name);
            Line($"query partitions set: {string.Join(", ", lit)}");
            PrintResults(strategy.HybridSearchAsync(query, new VoicingSearchFilters(), limit: 5).GetAwaiter().GetResult());
            Line("with the filter ChordName = \"" + symbol + "\":");
            PrintResults(strategy.HybridSearchAsync(query, new VoicingSearchFilters(ChordName: symbol), limit: 5).GetAwaiter().GetResult());
        }

        var openC = corpus.First(e => e.Voicing.Diagram == "0-1-0-2-3-x");
        Title($"Nearest voicings to {openC.Voicing.Diagram} (open C), by its own compact vector");
        PrintResults(strategy.SemanticSearchAsync(EmbeddingSchema.ExtractCompact(openC.RawDouble), limit: 6).GetAwaiter().GetResult());
        var similar = strategy.FindSimilarVoicingsAsync(openC.Voicing.Diagram, limit: 6).GetAwaiter().GetResult();
        Line($"FindSimilarVoicingsAsync(\"{openC.Voicing.Diagram}\") returned {similar.Count} results");
    }

    static void PrintResults(List<VoicingSearchResult> results)
    {
        int[] w = [5, 14, 18, 12];
        Row(w, "rank", "diagram", "MIDI", "name", "score");
        // GA's order: score descending, then index order in the file
        var ordered = results;
        for (var i = 0; i < ordered.Count; i++)
            Row(w, i + 1, ordered[i].Document.Diagram, Ints(ordered[i].Document.MidiNotes), ordered[i].Document.ChordName, ordered[i].Score);
        if (ordered.Count == 0) Line("(no results)");
    }

    static void DeadDimensions(List<Embedded> corpus)
    {
        Title($"Dimensions that never vary over the {corpus.Count} voicings");
        int[] w = [13, 5, 9, 9];
        Row(w, "partition", "dims", "always 0", "constant", "weight");
        var raws = corpus.Select(e => e.Raw).ToList();
        int deadTotal = 0, constantTotal = 0;
        foreach (var p in EmbeddingSchema.Partitions)
        {
            var zero = 0;
            var constant = 0;
            for (var d = p.Start; d <= p.End; d++)
            {
                var first = raws[0][d];
                if (raws.All(v => v[d] == 0f)) zero++;
                else if (raws.All(v => v[d] == first)) constant++;
            }

            if (p.Role == GA.Business.ML.Embeddings.PartitionRole.Similarity)
            {
                deadTotal += zero;
                constantTotal += constant;
            }

            Row(w, p.Name, p.Dim, zero, constant, p.SimilarityWeight.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture));
        }

        Line($"in the {EmbeddingSchema.CompactDimension} compact dims: {deadTotal} always 0, {constantTotal} constant");

        var names = Lesson2.ModalSlotNames();
        var modal = EmbeddingSchema.GetPartition("MODAL");
        var never = names.Where(kv => raws.All(v => v[kv.Key] == 0f)).OrderBy(kv => kv.Key).Select(kv => kv.Value).ToList();
        Line($"named MODAL slots never set ({never.Count} of {names.Count}): {string.Join(", ", never)}");
        var unnamed = Enumerable.Range(modal.Start, modal.Dim).Count(i => !names.ContainsKey(i));
        Line($"MODAL slots without a name constant: {unnamed}");
    }
}
