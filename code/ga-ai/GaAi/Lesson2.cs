namespace GaAi;

using System.Numerics.Tensors;
using System.Reflection;
using GA.Business.ML.Embeddings;
using GA.Business.ML.Embeddings.Services;
using GA.Domain.Core.Theory.Atonal;
using static Report;

// Lesson 2: the OPTIC-K schema, real embeddings of a few voicings, and what they are invariant to
public static class Lesson2
{
    public static readonly (string Shape, string Label)[] Chords =
    [
        ("x32010", "C, open"),
        ("x35553", "C, barre at 3"),
        ("032010", "C/E, open"),
        ("x32000", "Cmaj7, open"),
        ("x02210", "Am, open"),
        ("320003", "G, open"),
    ];

    public static void Run()
    {
        Schema();
        var embedded = Chords.Select(c => Voicings.Embed(c.Shape)).ToList();
        Documents(embedded);
        PositionalRecords(embedded);
        Partitions(embedded[0]);
        Similarities(embedded);
        Transpositions();
        McpDiagram();
    }

    static void Schema()
    {
        Title($"EmbeddingSchema.Partitions ({EmbeddingSchema.Version})");
        int[] w = [13, 8, 5, 11];
        Row(w, "partition", "raw", "dims", "role", "weight");
        foreach (var p in EmbeddingSchema.Partitions)
            Row(w, p.Name, $"{p.Start}-{p.End}", p.Dim, p.Role, p.SimilarityWeight.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture));
        Line($"TotalDimension          {EmbeddingSchema.TotalDimension}");
        Line($"sum of dims             {EmbeddingSchema.Partitions.Sum(p => p.Dim)}");
        Line($"sum of weights          {EmbeddingSchema.Partitions.Sum(p => (double)p.SimilarityWeight):0.00}");
        Line($"CompactDimension        {EmbeddingSchema.CompactDimension}");
        Line($"CompactLayoutV4         {EmbeddingSchema.CompactLayoutV4}");
        Line($"SchemaHashV4            0x{EmbeddingSchema.SchemaHashV4:X8}");

        Title("Loose constants next to the registry");
        int[] c = [24, 10];
        Row(c, "constant", "value", "registry");
        Row(c, "HierarchyDim", EmbeddingSchema.HierarchyDim, EmbeddingSchema.GetPartition("HIERARCHY").Dim);
        Row(c, "AtonalModalDim", EmbeddingSchema.AtonalModalDim, EmbeddingSchema.GetPartition("ATONAL_MODAL").Dim);
        Row(c, "ExtensionsEnd", EmbeddingSchema.ExtensionsEnd, EmbeddingSchema.TotalDimension);
    }

    static void Documents(List<Embedded> embedded)
    {
        Title("From a chord shape to GA's voicing document");
        int[] w = [7, 12, 13, 8, 15, 8, 5, 4];
        Row(w, "shape", "GA diagram", "GA name", "pcs", "MIDI", "doc root", "inv", "rootless", "function");
        foreach (var e in embedded)
            Row(w, e.Shape, e.Voicing.Diagram, e.Analysis.ChordId.ChordName, Ints(e.Doc.PitchClasses),
                Ints(e.Doc.MidiNotes), $"{e.Doc.RootPitchClass} {Voicings.NoteName(e.Doc.RootPitchClass ?? 0)}",
                e.Doc.Inversion, e.Doc.IsRootless ? "yes" : "no", e.Doc.HarmonicFunction);
    }

    // VoicingCharacteristics and PerceptualQualities are positional records, and two of their
    // constructor calls pass arguments in the wrong slots
    static void PositionalRecords(List<Embedded> embedded)
    {
        Title("VoicingCharacteristics and PerceptualQualities, as VoicingAnalyzer fills them");
        int[] w = [7, 7, 11, 9, 11, 12, 11];
        Row(w, "shape", "span", "IsRootless", "IsOpen", "Consonance", "Brightness", "ConsonanceScore");
        foreach (var e in embedded)
        {
            var c = e.Analysis.VoicingCharacteristics;
            var p = e.Analysis.PerceptualQualities;
            Row(w, e.Shape, c.IntervalSpread, c.IsRootless, c.IsOpenVoicing, c.Consonance, p.Brightness, p.ConsonanceScore);
        }
    }

    static void Partitions(Embedded e)
    {
        Title($"The 240 values of {e.Shape} ({e.Analysis.ChordId.ChordName}), partition by partition");
        foreach (var p in EmbeddingSchema.Partitions)
        {
            var slice = e.Slice(p.Name);
            var nonZero = slice.Count(v => v != 0f);
            // Long, mostly empty partitions are printed up to their last non-zero value
            var last = Array.FindLastIndex(slice, v => v != 0f);
            var shown = slice.Length > 24 ? slice[..(last + 1)] : slice;
            var suffix = shown.Length < slice.Length ? $" (+{slice.Length - shown.Length} zeros)" : "";
            Line($"{p.Name,-13}{nonZero,3}/{p.Dim,-3} {Vec(shown)}{suffix}");
        }

        var modalNames = ModalSlotNames();
        var modal = EmbeddingSchema.GetPartition("MODAL");
        var lit = Enumerable.Range(modal.Start, modal.Dim).Where(i => e.Raw[i] != 0f)
            .Select(i => $"{modalNames.GetValueOrDefault(i, $"slot {i}")}={e.Raw[i]:0.##}");
        Line($"MODAL slots set: {string.Join(", ", lit)}");
    }

    // Names of the MODAL slots, from the EmbeddingSchema.Modal* constants
    public static Dictionary<int, string> ModalSlotNames() =>
        typeof(EmbeddingSchema).GetFields(BindingFlags.Public | BindingFlags.Static)
            .Where(f => f.IsLiteral && f.FieldType == typeof(int) && f.Name.StartsWith("Modal")
                        && f.Name is not ("ModalOffset" or "ModalDim" or "ModalEnd"))
            .ToDictionary(f => (int)f.GetRawConstantValue()!, f => f.Name["Modal".Length..]);

    static readonly string[] Scored = ["STRUCTURE", "MORPHOLOGY", "CONTEXT", "SYMBOLIC", "MODAL", "ROOT"];

    static void Similarities(List<Embedded> embedded)
    {
        Title("Cosine per partition, and GA's weighted score, against open C");
        int[] w = [16, 10, 11, 8, 9, 6, 6, 9];
        Row(w, ["pair", .. Scored.Select(s => s.ToLowerInvariant()), "weighted", "compact dot"]);
        var c = embedded[0];
        foreach (var other in embedded.Skip(1))
        {
            var cosines = Scored.Select(name => (object?)PartitionCosine(c, other, name));
            var weighted = EmbeddingSchema.WeightedPartitionCosine(c.RawDouble, other.RawDouble);
            var dot = TensorPrimitives.Dot(
                EmbeddingSchema.ExtractCompact(c.RawDouble).AsSpan(),
                EmbeddingSchema.ExtractCompact(other.RawDouble).AsSpan());
            Row(w, [$"{c.Shape} {other.Shape}", .. cosines, weighted, dot]);
        }

        var self = EmbeddingSchema.WeightedPartitionCosine(c.RawDouble, c.RawDouble);
        Line($"open C with itself: {F(self)}");
    }

    public static double PartitionCosine(Embedded a, Embedded b, string name)
    {
        var p = EmbeddingSchema.GetPartition(name);
        var cos = TensorPrimitives.CosineSimilarity(
            a.RawDouble.AsSpan(p.Start, p.Dim), b.RawDouble.AsSpan(p.Start, p.Dim));
        return double.IsNaN(cos) ? 0.0 : cos;
    }

    static void Transpositions()
    {
        Title("STRUCTURE of C major (0 4 7) against its 11 transpositions (TheoryVectorService)");
        int[] pcs = [0, 4, 7];
        var t0 = TheoryVectorService.ComputeEmbedding(pcs, 0, "<0 0 1 1 1 0>");
        int[] w = [4, 10, 10];
        Row(w, "T", "pcs", "structure", "icv dims");
        for (var t = 1; t < 12; t++)
        {
            var moved = pcs.Select(p => (p + t) % 12).Order().ToArray();
            var tk = TheoryVectorService.ComputeEmbedding(moved, moved.Min(), "<0 0 1 1 1 0>");
            Row(w, t, Ints(moved),
                TensorPrimitives.CosineSimilarity(t0.AsSpan(), tk.AsSpan()),
                TensorPrimitives.CosineSimilarity(t0.AsSpan(12, 7), tk.AsSpan(12, 7)));
        }

        // The sweep of Tools/GaStructureInvariance: every set class of 2 notes or more, 12 transpositions
        var mins = new List<double>();
        foreach (var sc in SetClass.Items)
        {
            if ((int)sc.Cardinality < 2) continue;
            var basePcs = Enumerable.Range(0, 12).Where(i => (sc.PrimeForm.Id.Value & (1 << i)) != 0).ToList();
            var icv = sc.IntervalClassVector.ToString();
            var v0 = TheoryVectorService.ComputeEmbedding(basePcs, basePcs.Min(), icv);
            var min = 1.0;
            for (var t = 1; t < 12; t++)
            {
                var moved = basePcs.Select(p => (p + t) % 12).ToList();
                var vt = TheoryVectorService.ComputeEmbedding(moved, moved.Min(), icv);
                min = Math.Min(min, TensorPrimitives.CosineSimilarity(v0.AsSpan(), vt.AsSpan()));
            }

            mins.Add(min);
        }

        Line($"set classes swept                 {mins.Count}");
        Line($"invariant (min cosine > 0.9999)   {mins.Count(m => m > 0.9999)}");
        Line($"mean of the minimum cosines       {F(mins.Average())}");
        Line($"worst minimum cosine              {F(mins.Min())}");
    }

    static void McpDiagram()
    {
        Title("ga_generate_voicing_embedding's example diagram, x-3-2-0-1-0");
        int[] w = [22, 12, 16, 16];
        Row(w, "parsed by", "GA diagram", "MIDI", "GA name", "pcs");
        var mcp = Voicings.Embed("x-3-2-0-1-0", Voicings.FromMcpDiagram("x-3-2-0-1-0"));
        var chart = Voicings.Embed("x32010");
        Row(w, "the MCP tool's parser", mcp.Voicing.Diagram, Ints(mcp.Doc.MidiNotes), mcp.Analysis.ChordId.ChordName, Ints(mcp.Doc.PitchClasses));
        Row(w, "chord chart x32010", chart.Voicing.Diagram, Ints(chart.Doc.MidiNotes), chart.Analysis.ChordId.ChordName, Ints(chart.Doc.PitchClasses));
    }
}
