using System.Reactive.Concurrency;
using System.Reactive.Linq;
using System.Reactive.Subjects;
using System.Threading.Channels;
using System.Threading.Tasks.Dataflow;
using BenchmarkDotNet.Attributes;

namespace Benchmarks;

// Lesson 9: 100,000 integers from one producer to one consumer that sums them, through each kind of stream
[MemoryDiagnoser]
public class StreamBenchmarks
{
    private const int Count = 100_000;

    [Benchmark(Baseline = true)]
    public async Task<long> AsyncIterator()
    {
        static async IAsyncEnumerable<int> Source()
        {
            for (var i = 0; i < Count; i++)
            {
                yield return i;
            }

            await Task.CompletedTask;
        }

        long sum = 0;
        await foreach (var i in Source())
        {
            sum += i;
        }

        return sum;
    }

    [Benchmark]
    public Task<long> UnboundedChannel() => ThroughChannel(Channel.CreateUnbounded<int>(new UnboundedChannelOptions { SingleReader = true, SingleWriter = true }));

    [Benchmark]
    public Task<long> BoundedChannel1000() => ThroughChannel(Channel.CreateBounded<int>(new BoundedChannelOptions(1000) { SingleReader = true, SingleWriter = true }));

    private static async Task<long> ThroughChannel(Channel<int> channel)
    {
        var producer = Task.Run(async () =>
        {
            for (var i = 0; i < Count; i++)
            {
                if (!channel.Writer.TryWrite(i))
                {
                    await channel.Writer.WriteAsync(i);
                }
            }

            channel.Writer.Complete();
        });

        long sum = 0;
        while (await channel.Reader.WaitToReadAsync())
        {
            while (channel.Reader.TryRead(out var i))
            {
                sum += i;
            }
        }

        await producer;
        return sum;
    }

    [Benchmark]
    public async Task<long> DataflowBufferToAction()
    {
        long sum = 0;
        var buffer = new BufferBlock<int>(new DataflowBlockOptions { BoundedCapacity = 1000 });
        var action = new ActionBlock<int>(i => sum += i, new ExecutionDataflowBlockOptions { BoundedCapacity = 1000 });
        buffer.LinkTo(action, new DataflowLinkOptions { PropagateCompletion = true });
        for (var i = 0; i < Count; i++)
        {
            if (!buffer.Post(i))
            {
                await buffer.SendAsync(i);
            }
        }

        buffer.Complete();
        await action.Completion;
        return sum;
    }

    [Benchmark]
    public long RxSubject()
    {
        long sum = 0;
        var subject = new Subject<int>();
        using var subscription = subject.Subscribe(i => sum += i);
        for (var i = 0; i < Count; i++)
        {
            subject.OnNext(i);
        }

        subject.OnCompleted();
        return sum;
    }

    [Benchmark]
    public async Task<long> RxObserveOnTaskPool()
    {
        long sum = 0;
        var done = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var subject = new Subject<int>();
        using var subscription = subject.ObserveOn(TaskPoolScheduler.Default).Subscribe(i => sum += i, () => done.SetResult());
        for (var i = 0; i < Count; i++)
        {
            subject.OnNext(i);
        }

        subject.OnCompleted();
        await done.Task;
        return sum;
    }
}
