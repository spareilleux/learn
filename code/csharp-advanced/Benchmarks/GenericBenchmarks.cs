using Advanced;
using BenchmarkDotNet.Attributes;
using GA.Core.ValueObjects;
using GA.Domain.Core.Theory.Atonal;

namespace Benchmarks;

// Lesson 5: a generic-math Sum against the loop written for one type
public class GenericMathBenchmarks
{
    private readonly int[] _ints = [.. Enumerable.Range(0, 1024)];
    private readonly double[] _doubles = [.. Enumerable.Range(0, 1024).Select(i => i * 0.5)];

    [Benchmark(Baseline = true)]
    public int IntLoop()
    {
        var sum = 0;
        foreach (var value in _ints) sum += value;
        return sum;
    }

    [Benchmark]
    public int IntGeneric() => Lesson5.Sum<int>(_ints);

    [Benchmark]
    public double DoubleLoop()
    {
        var sum = 0.0;
        foreach (var value in _doubles) sum += value;
        return sum;
    }

    [Benchmark]
    public double DoubleGeneric() => Lesson5.Sum<double>(_doubles);
}

// Lesson 5: a static field of a generic class, read 1,000 times from code specialized for int
// and from the code shared by every reference type
public class SharedGenericBenchmarks
{
    [Benchmark(Baseline = true)]
    public int ValueTypeInstantiation() => Lesson5.ReadStatic<int>(1000);

    [Benchmark]
    public int ReferenceTypeInstantiation() => Lesson5.ReadStatic<string>(1000);
}

// Lesson 5: summing GA's 12 pitch classes through IReadOnlyCollection<T>, through the cached span,
// and through a generic method over IRangeValueObject<T>
[MemoryDiagnoser]
public class ValueObjectListBenchmarks
{
    [Benchmark(Baseline = true)]
    public int ItemsForeach()
    {
        var sum = 0;
        foreach (var pitchClass in PitchClass.Items) sum += pitchClass.Value;
        return sum;
    }

    [Benchmark]
    public int ItemsSpanForeach()
    {
        var sum = 0;
        foreach (var pitchClass in PitchClass.ItemsSpan) sum += pitchClass.Value;
        return sum;
    }

    [Benchmark]
    public int GenericSumAll() => Lesson5.SumAll<PitchClass>();

    [Benchmark]
    public int ValuesIndexer()
    {
        var sum = 0;
        for (var i = 0; i < 12; i++) sum += PitchClass.Values[i];
        return sum;
    }

    [Benchmark]
    public int ImmutableArrayValues()
    {
        var sum = 0;
        var values = ValueObjectUtils<PitchClass>.Values;
        for (var i = 0; i < values.Length; i++) sum += values[i];
        return sum;
    }
}
