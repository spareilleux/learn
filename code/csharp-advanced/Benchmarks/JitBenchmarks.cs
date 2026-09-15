using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Configs;
using BenchmarkDotNet.Jobs;
using GA.Domain.Core.Theory.Atonal;

namespace Benchmarks;

// Lesson 4: the same code under four JIT settings, set through environment variables
[Config(typeof(JitConfig))]
public class JitBenchmarks
{
    private sealed class JitConfig : ManualConfig
    {
        public JitConfig()
        {
            // CI sets BENCHMARKS_DRY=1: one iteration per job, only to check that the four jobs run
            var job = Environment.GetEnvironmentVariable("BENCHMARKS_DRY") == "1" ? Job.Dry : Job.Default;
            AddJob(job.WithId("Default").AsBaseline());
            AddJob(job.WithEnvironmentVariable("DOTNET_TieredPGO", "0").WithId("NoPGO"));
            AddJob(job.WithEnvironmentVariable("DOTNET_TieredCompilation", "0").WithId("NoTiering"));
            AddJob(job.WithEnvironmentVariable("DOTNET_ReadyToRun", "0").WithId("NoReadyToRun"));
        }
    }

    private static readonly IEnumerable<int> Values = PitchClassSetId.Items.Select(id => id.Value).ToList();

    // A loop over an interface: with PGO, the JIT sees that Values is always a List<int> and devirtualizes the calls
    [Benchmark]
    public long SumThroughInterface()
    {
        long sum = 0;
        foreach (var value in Values) sum += value;
        return sum;
    }

    // GA's collection of the 4096 sets, enumerated through IReadOnlyCollection<PitchClassSetId>
    [Benchmark]
    public int CardinalityOfEverySet()
    {
        var notes = 0;
        foreach (var id in PitchClassSetId.Items) notes += id.Cardinality;
        return notes;
    }
}
