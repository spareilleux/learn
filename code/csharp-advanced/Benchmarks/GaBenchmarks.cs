using Advanced;
using BenchmarkDotNet.Attributes;
using GA.Domain.Core.Theory.Atonal;

namespace Benchmarks;

// Appendix 1: three members of Guitar Alchemist against the versions in Advanced/GaFast.cs.
// `Advanced -- a1` proves the two answers are identical for all 4096 pitch-class sets; these
// measure what the difference costs. One set per call, chosen so the work is representative:
// the major scale has seven notes, which is the common case in GA.

[MemoryDiagnoser]
public class ClusterFreeBenchmarks
{
    private const int MajorScale = 2741;
    private static readonly PitchClassSetId Id = PitchClassSetId.FromValue(MajorScale);

    [Benchmark(Baseline = true)]
    public bool Ga() => Id.IsClusterFree;

    [Benchmark]
    public bool Fast() => GaFast.IsClusterFree(MajorScale);
}

[MemoryDiagnoser]
public class IntervalClassVectorBenchmarks
{
    private const int MajorScale = 2741;
    private static readonly PitchClassSet Set = PitchClassSet.FromId(PitchClassSetId.FromValue(MajorScale));

    [Benchmark(Baseline = true)]
    public int Ga() => Set.IntervalClassVector.Id.Value;

    // The six popcounts, computed on each call
    [Benchmark]
    public int Computed() => GaFast.IntervalClassVectorId(MajorScale);

    // The same six popcounts, done once for all 4096 sets at startup
    [Benchmark]
    public int Table() => GaFast.IntervalClassVectorIds[MajorScale];
}

[MemoryDiagnoser]
public class ClosestDiatonicKeyBenchmarks
{
    private static readonly PitchClassSet Set = PitchClassSet.FromId(PitchClassSetId.FromValue(2741));

    [Benchmark(Baseline = true)]
    public string Ga() => Set.ClosestDiatonicKey.ToString();

    [Benchmark]
    public string Fast() => GaFast.ClosestDiatonicKey(Set).ToString();
}
