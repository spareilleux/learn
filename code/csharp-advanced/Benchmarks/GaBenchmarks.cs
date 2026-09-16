using Advanced;
using BenchmarkDotNet.Attributes;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Tonal;

namespace Benchmarks;

// Appendix 1: five members of Guitar Alchemist against the versions in Advanced/GaFast.cs.
// `Advanced -- a1` proves the two answers are identical for all 4096 pitch-class sets; these
// measure what the difference costs.
//
// Every benchmark sweeps the whole domain — all 4096 sets — instead of calling once on one set,
// and that is not a detail. The fast versions take about a nanosecond, and a single call to one
// of them cannot be measured: with a constant argument the JIT folds the call away entirely, and
// even with an argument it cannot fold, BenchmarkDotNet subtracts the cost of an empty method and
// what is left is noise around zero. The first version of this file reported 0.0474 ns with a
// median of 0.0000 ns, which says "unmeasurable", not "fast". Sweeping the domain gives every
// method real work, makes the loop counter the input so nothing can be folded, and leaves a
// per-call figure that is the reported mean divided by 4096.
//
// Each class is run on its own — `--filter "*NormalFormBenchmarks*"` — because BenchmarkDotNet
// reports its ratios against the baseline of its own class.
//
// Every method returns an accumulated value that depends on each answer, so the JIT cannot decide
// the calls are dead and delete the loop.

[MemoryDiagnoser]
public class ClusterFreeBenchmarks
{
    [Benchmark(Baseline = true)]
    public int Ga()
    {
        var count = 0;
        for (var id = 0; id < 4096; id++)
        {
            if (PitchClassSetId.FromValue(id).IsClusterFree) count++;
        }
        return count;
    }

    [Benchmark]
    public int Fast()
    {
        var count = 0;
        for (var id = 0; id < 4096; id++)
        {
            if (GaFast.IsClusterFree(id)) count++;
        }
        return count;
    }
}

[MemoryDiagnoser]
public class IntervalClassVectorBenchmarks
{
    // GA's side reads a property of PitchClassSet, not of the id, and building 4096 of those would
    // be measured instead of the property. They are built once here, outside the benchmark.
    private static readonly PitchClassSet[] Sets =
        [.. Enumerable.Range(0, 4096).Select(id => PitchClassSet.FromId(PitchClassSetId.FromValue(id)))];

    [Benchmark(Baseline = true)]
    public int Ga()
    {
        var total = 0;
        foreach (var set in Sets) total += set.IntervalClassVector.Id.Value;
        return total;
    }

    // The six popcounts, computed on every call
    [Benchmark]
    public int Computed()
    {
        var total = 0;
        for (var id = 0; id < 4096; id++) total += GaFast.IntervalClassVectorId(id);
        return total;
    }

    // The same six popcounts, done once for all 4096 sets at startup
    [Benchmark]
    public int Table()
    {
        var total = 0;
        for (var id = 0; id < 4096; id++) total += GaFast.IntervalClassVectorIds[id];
        return total;
    }
}

[MemoryDiagnoser]
public class ClosestDiatonicKeyBenchmarks
{
    private static readonly PitchClassSet[] Sets =
        [.. Enumerable.Range(0, 4096).Select(id => PitchClassSet.FromId(PitchClassSetId.FromValue(id)))];

    // The mode is read off the answer rather than its name, because ToString would allocate 4096
    // strings and those, not the search, would be what the table below compares
    [Benchmark(Baseline = true)]
    public int Ga()
    {
        var minor = 0;
        foreach (var set in Sets)
        {
            if (set.ClosestDiatonicKey.KeyMode == KeyMode.Minor) minor++;
        }
        return minor;
    }

    [Benchmark]
    public int Fast()
    {
        var minor = 0;
        foreach (var set in Sets)
        {
            if (GaFast.ClosestDiatonicKey(set).KeyMode == KeyMode.Minor) minor++;
        }
        return minor;
    }
}

// The normal form is what was left inside the fast ClosestDiatonicKey: GA builds it once or twice
// per call, only to ask whether it contains one pitch class.
[MemoryDiagnoser]
public class NormalFormBenchmarks
{
    private static readonly PitchClassSet[] Sets =
        [.. Enumerable.Range(0, 4096).Select(id => PitchClassSet.FromId(PitchClassSetId.FromValue(id)))];

    [Benchmark(Baseline = true)]
    public int Ga()
    {
        var total = 0;
        foreach (var set in Sets) total += set.ToNormalForm().Id.Value;
        return total;
    }

    // The same rotations and the same tie-break, on two stack buffers
    [Benchmark]
    public int Computed()
    {
        var total = 0;
        for (var id = 0; id < 4096; id++) total += GaFast.NormalFormMask(id);
        return total;
    }

    // The same answer for all 4096 sets, computed once at startup
    [Benchmark]
    public int Table()
    {
        var total = 0;
        for (var id = 0; id < 4096; id++) total += GaFast.NormalFormMasks[id];
        return total;
    }
}

[MemoryDiagnoser]
public class PrimeFormBenchmarks
{
    [Benchmark(Baseline = true)]
    public int Ga()
    {
        var total = 0;
        for (var id = 0; id < 4096; id++) total += PitchClassSetId.FromValue(id).PrimeForm.Value;
        return total;
    }

    [Benchmark]
    public int Computed()
    {
        var total = 0;
        for (var id = 0; id < 4096; id++) total += GaFast.PrimeFormId(id);
        return total;
    }

    [Benchmark]
    public int Table()
    {
        var total = 0;
        for (var id = 0; id < 4096; id++) total += GaFast.PrimeFormIds[id];
        return total;
    }
}
