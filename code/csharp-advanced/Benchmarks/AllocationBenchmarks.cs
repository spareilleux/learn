using Advanced;
using BenchmarkDotNet.Attributes;
using GA.Domain.Core.Theory.Atonal;
using Snippets;

namespace Benchmarks;

// Lesson 2: bytes allocated per operation, and the collections they cause
[MemoryDiagnoser]
public class AllocationBenchmarks
{
    private static readonly PitchClassSetId[] CachedIds = [.. PitchClassSetId.Items];

    [Benchmark(Baseline = true)]
    public int GaPitchClassSetIdItemsSpan() => PitchClassSetId.ItemsSpan.Length;

    [Benchmark]
    public int CachedArraySpan() => new ReadOnlySpan<PitchClassSetId>(CachedIds).Length;

    [Benchmark]
    public int GaPitchClassItemsSpan() => PitchClass.ItemsSpan.Length;

    [Benchmark]
    public int VoicingWithSplit() => Lesson1.SumWithSplit("x 3 2 0 1 0");

    [Benchmark]
    public int VoicingWithSpans() => Lesson1.SumWithSpans("x 3 2 0 1 0");

    [Benchmark]
    public string Format() => Boxing.Format(12345);

    [Benchmark]
    public string Interpolate() => Boxing.Interpolate(12345);
}
