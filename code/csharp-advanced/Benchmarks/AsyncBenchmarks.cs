using Advanced;
using BenchmarkDotNet.Attributes;

namespace Benchmarks;

// Lesson 3: Task<T> and ValueTask<T>, when the method completes synchronously and when it doesn't
[MemoryDiagnoser]
public class AsyncBenchmarks
{
    [Benchmark(Baseline = true)]
    public int TaskCompletedSynchronously() => Lesson3.TaskOf(500).GetAwaiter().GetResult();

    [Benchmark]
    public int ValueTaskCompletedSynchronously() => Lesson3.ValueTaskOf(500).GetAwaiter().GetResult();

    [Benchmark]
    public async Task<int> TaskAfterYield()
    {
        await Task.Yield();
        return 500;
    }

    [Benchmark]
    public async ValueTask<int> ValueTaskAfterYield()
    {
        await Task.Yield();
        return 500;
    }
}
