using System.Numerics.Tensors;
using Advanced;
using BenchmarkDotNet.Attributes;
using GA.Core.Numerics;

namespace Benchmarks;

// Lesson 4: dot products, scalar and vectorized
public class DotBenchmarks
{
    private double[] _a = [];
    private double[] _b = [];

    [Params(16, 1024)]
    public int Length { get; set; }

    [GlobalSetup]
    public void Setup()
    {
        _a = Lesson4.Embedding(Length, 1, integers: false);
        _b = Lesson4.Embedding(Length, 2, integers: false);
    }

    [Benchmark(Baseline = true)]
    public double Scalar() => Lesson4.DotScalar(_a, _b);

    [Benchmark]
    public double GaSimdOps() => SimdOps.Dot(_a, _b);

    [Benchmark]
    public double TensorPrimitivesDot() => TensorPrimitives.Dot<double>(_a, _b);
}
