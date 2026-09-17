namespace GaPerf;

// Appendix 2, section 4: the OPTIC-K reader's vector dimension. GA's search lives in GA.Business.ML, which pulls in
// Semantic Kernel, ONNX Runtime and ILGPU, so the course does not build it. This file copies the few lines that
// matter from GA commit 66bdd049 (EmbeddingSchema.cs and OptickIndexReader.cs), unchanged apart from the names:
// the partition registry, the property that sums it, and the offset arithmetic of GetVector.
public enum PartitionRole { Identity, Similarity, Info }

public readonly record struct EmbeddingPartition(string Name, int Start, int End, float SimilarityWeight, PartitionRole Role)
{
    public int Dim => End - Start + 1;
}

public static class OptickDimension
{
    public static readonly EmbeddingPartition[] Partitions =
    [
        new("IDENTITY",     0,   5,   0.00f, PartitionRole.Identity),
        new("STRUCTURE",    6,   29,  0.45f, PartitionRole.Similarity),
        new("MORPHOLOGY",   30,  53,  0.25f, PartitionRole.Similarity),
        new("CONTEXT",      54,  65,  0.20f, PartitionRole.Similarity),
        new("SYMBOLIC",     66,  77,  0.10f, PartitionRole.Similarity),
        new("EXTENSIONS",   78,  95,  0.00f, PartitionRole.Info),
        new("SPECTRAL",     96,  108, 0.00f, PartitionRole.Info),
        new("MODAL",        109, 148, 0.10f, PartitionRole.Similarity),
        new("HIERARCHY",    149, 163, 0.00f, PartitionRole.Info),
        new("ATONAL_MODAL", 164, 227, 0.00f, PartitionRole.Info),
        new("ROOT",         228, 239, 0.05f, PartitionRole.Similarity),
    ];

    public static IEnumerable<EmbeddingPartition> SimilarityPartitions => Partitions.Where(p => p.Role == PartitionRole.Similarity);

    // GA: EmbeddingSchema.CompactDimension, a LINQ query run on every read
    public static int CompactDimension => SimilarityPartitions.Sum(p => p.Dim);

    // GA before: OptickIndexReader.Dimension forwards to it
    public static int DimensionComputed => CompactDimension;

    // GA after: the same value, read once when the type is initialised
    public static int DimensionStored { get; } = CompactDimension;

    // GetVector's arithmetic: the start of vector i and its length, each of which reads the dimension
    public static (long Offset, int Length) VectorComputed(long i) => (i * DimensionComputed, DimensionComputed);

    public static (long Offset, int Length) VectorStored(long i) => (i * DimensionStored, DimensionStored);
}
