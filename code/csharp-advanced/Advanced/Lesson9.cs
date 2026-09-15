using System.Reactive.Linq;
using System.Reactive.Subjects;
using System.Runtime.CompilerServices;
using System.Threading.Channels;
using System.Threading.Tasks.Dataflow;
using static Advanced.Lesson6;
using static Advanced.Report;

namespace Advanced;

// Lesson 9: IAsyncEnumerable<T> and System.Linq.AsyncEnumerable, then channels, Dataflow, Rx and async streams
// side by side: backpressure, errors in the source, errors in the consumer, and the bridges between them
public static class Lesson9
{
    public static void Run() => RunAsync().GetAwaiter().GetResult();

    static async Task RunAsync()
    {
        await Pull();
        await AsyncLinq();
        await GaTake();
        await Backpressure();
        await SourceFails();
        await ConsumerFails();
        await Bridges();
        await Exercises();
    }

    static readonly string[] Progression = ["Dm7", "G7", "Cmaj7", "A7"];

    static async IAsyncEnumerable<string> Chords(List<string> log, [EnumeratorCancellation] CancellationToken token = default)
    {
        try
        {
            foreach (var chord in Progression)
            {
                await Task.Yield();
                log.Add($"produce {chord}");
                yield return chord;
            }
        }
        finally
        {
            log.Add("source finally");
        }
    }

    static async Task Pull()
    {
        Title("An async iterator runs only when the consumer asks for the next item");
        var log = new List<string>();
        await foreach (var chord in Chords(log))
        {
            log.Add($"consume {chord}");
        }

        Line(string.Join(", ", log));
    }

    static async Task AsyncLinq()
    {
        Title("System.Linq.AsyncEnumerable, part of .NET 10");
        Line($"AsyncEnumerable: {typeof(AsyncEnumerable).Assembly.GetName().Name}, in the shared framework {typeof(AsyncEnumerable).Assembly.Location.Contains("Microsoft.NETCore.App")}");

        var log = new List<string>();
        var firstTwo = await Chords(log).Take(2).ToListAsync();
        Line($"Take(2): {string.Join(" ", firstTwo)}; log: {string.Join(", ", log)}");

        var sevenths = await Progression.ToAsyncEnumerable()
            .Where(async (chord, ct) =>
            {
                await Task.Yield();
                return !chord.Contains("maj");
            })
            .Select((chord, index) => $"{index}:{chord}")
            .ToArrayAsync();
        Line($"Where with an async predicate, then Select with an index: {string.Join(" ", sevenths)}");

        var chunks = await AsyncEnumerable.Range(1, 10).Chunk(4).Select(chunk => $"[{string.Join(" ", chunk)}]").ToListAsync();
        Line($"AsyncEnumerable.Range(1, 10).Chunk(4): {string.Join(" ", chunks)}");
    }

    static async Task GaTake()
    {
        Title("GA's usage example: GenerateAllVoicingsAsync(...).Take(100)");
        var probe = new WindowProbe();
        var taken = await GaShapeVoicings(24, probe).Take(100).CountAsync();
        Line($"GA shape: took {taken}; producer completed within 10 s {await Completes(probe.Producer!, 10)}, windows generated {probe.Generated} of 24");

        probe = new WindowProbe();
        taken = await FixedVoicings(24, probe).Take(100).CountAsync();
        Line($"fixed:    took {taken}; producer already completed {probe.Producer!.IsCompleted}, windows generated fewer than 24 {probe.Generated < 24}");
        Machine($"fixed: windows generated {probe.Generated}");
    }

    // A slow consumer holds the first item; how many items has each source produced once it can go no further?
    static async Task Backpressure()
    {
        Title("A consumer holds item 0: how many of 1,000 items has the source produced?");
        const int total = 1000;

        await Measure("async iterator (IAsyncEnumerable)", async (produced, hold) =>
        {
            async IAsyncEnumerable<int> Source()
            {
                for (var i = 0; i < total; i++)
                {
                    Interlocked.Increment(ref produced.Value);
                    await Task.Yield();
                    yield return i;
                }
            }

            await foreach (var _ in Source())
            {
                await hold;
            }
        });

        await Measure("Channel.CreateBounded(2)", async (produced, hold) =>
        {
            var channel = Channel.CreateBounded<int>(2);
            var producer = Task.Run(async () =>
            {
                for (var i = 0; i < total; i++)
                {
                    Interlocked.Increment(ref produced.Value);
                    await channel.Writer.WriteAsync(i);
                }

                channel.Writer.Complete();
            });
            await foreach (var _ in channel.Reader.ReadAllAsync())
            {
                await hold;
            }

            await producer;
        });

        await Measure("Channel.CreateUnbounded()", async (produced, hold) =>
        {
            var channel = Channel.CreateUnbounded<int>();
            var producer = Task.Run(() =>
            {
                for (var i = 0; i < total; i++)
                {
                    Interlocked.Increment(ref produced.Value);
                    channel.Writer.TryWrite(i);
                }

                channel.Writer.Complete();
            });
            await foreach (var _ in channel.Reader.ReadAllAsync())
            {
                await hold;
            }

            await producer;
        });

        await Measure("ActionBlock, BoundedCapacity 2", async (produced, hold) =>
        {
            var consumer = new ActionBlock<int>(async _ => await hold, new ExecutionDataflowBlockOptions { BoundedCapacity = 2 });
            for (var i = 0; i < total; i++)
            {
                Interlocked.Increment(ref produced.Value);
                await consumer.SendAsync(i);
            }

            consumer.Complete();
            await consumer.Completion;
        });

        await Measure("Rx Subject, no scheduler", async (produced, hold) =>
        {
            var subject = new Subject<int>();
            using var subscription = subject.Subscribe(_ => hold.Wait());
            await Task.Run(() =>
            {
                for (var i = 0; i < total; i++)
                {
                    Interlocked.Increment(ref produced.Value);
                    subject.OnNext(i);
                }

                subject.OnCompleted();
            });
        });

        await Measure("Rx Subject, ObserveOn(TaskPool)", async (produced, hold) =>
        {
            var subject = new Subject<int>();
            var done = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
            using var subscription = subject.ObserveOn(System.Reactive.Concurrency.TaskPoolScheduler.Default)
                .Subscribe(_ => hold.Wait(), () => done.SetResult());
            for (var i = 0; i < total; i++)
            {
                Interlocked.Increment(ref produced.Value);
                subject.OnNext(i);
            }

            subject.OnCompleted();
            await done.Task;
        });
    }

    sealed class Counter
    {
        public int Value;
    }

    static async Task Measure(string name, Func<Counter, Task, Task> run)
    {
        var produced = new Counter();
        var release = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var running = Task.Run(() => run(produced, release.Task));

        // Wait until the count stops moving for 200 ms
        var last = -1;
        while (produced.Value != last)
        {
            last = produced.Value;
            await Task.Delay(200);
        }

        Line($"{name,-34} {last,5}");
        release.SetResult();
        await running;
    }

    static async Task SourceFails()
    {
        Title("The source fails after 3 items: what does the consumer see?");

        var iteratorSeen = new List<string>();
        async IAsyncEnumerable<int> FailingIterator()
        {
            for (var i = 0; i < 3; i++)
            {
                await Task.Yield();
                yield return i;
            }

            throw new InvalidOperationException("source failed");
        }

        try
        {
            await foreach (var i in FailingIterator())
            {
                iteratorSeen.Add($"{i}");
            }
        }
        catch (Exception e)
        {
            iteratorSeen.Add(Describe(e));
        }

        Line($"{"async iterator",-38} {string.Join(", ", iteratorSeen)}");

        foreach (var completeWithError in new[] { false, true })
        {
            var channel = Channel.CreateUnbounded<int>();
            var producer = Task.Run(() =>
            {
                try
                {
                    for (var i = 0; i < 3; i++)
                    {
                        channel.Writer.TryWrite(i);
                    }

                    throw new InvalidOperationException("source failed");
                }
                catch (Exception e) when (completeWithError)
                {
                    channel.Writer.Complete(e);
                }
            });
            var seen = new List<string>();
            var reading = Task.Run(async () =>
            {
                try
                {
                    await foreach (var i in channel.Reader.ReadAllAsync())
                    {
                        lock (seen) seen.Add($"{i}");
                    }

                    lock (seen) seen.Add("end");
                }
                catch (Exception e)
                {
                    lock (seen) seen.Add(Describe(e));
                }
            });
            var finished = await Completes(reading, 1);
            if (!finished)
            {
                lock (seen) seen.Add("still waiting after 1 s");
            }

            Line($"{(completeWithError ? "channel, writer calls Complete(e)" : "channel, writer just throws"),-38} {string.Join(", ", seen)}");
            _ = producer.Exception; // observed
        }

        var source = new TransformBlock<int, int>(i => i < 3 ? i : throw new InvalidOperationException("source failed"));
        var blockSeen = new List<string>();
        var target = new ActionBlock<int>(i => blockSeen.Add($"{i}"));
        source.LinkTo(target, new DataflowLinkOptions { PropagateCompletion = true });
        for (var i = 0; i < 4; i++)
        {
            source.Post(i);
        }

        await Outcome(async () => { await target.Completion; return ""; });
        Line($"{"Dataflow, PropagateCompletion",-38} target.Completion {target.Completion.Status}: {Describe(target.Completion.Exception!.InnerException!)}");
        Machine($"Dataflow target processed before the fault: {string.Join(", ", blockSeen)}");

        var rxSeen = new List<string>();
        Observable.Range(0, 3).Concat(Observable.Throw<int>(new InvalidOperationException("source failed")))
            .Subscribe(i => rxSeen.Add($"{i}"), e => rxSeen.Add($"OnError({Describe(e)})"));
        Line($"{"Rx",-38} {string.Join(", ", rxSeen)}");
    }

    static async Task ConsumerFails()
    {
        Title("The consumer fails on item 1: does the source stop?");

        var produced = 0;
        var finallyRan = false;
        async IAsyncEnumerable<int> Source()
        {
            try
            {
                for (var i = 0; i < 1000; i++)
                {
                    produced++;
                    await Task.Yield();
                    yield return i;
                }
            }
            finally
            {
                finallyRan = true;
            }
        }

        var outcome = await Outcome(async () =>
        {
            await foreach (var i in Source())
            {
                if (i == 1) throw new InvalidOperationException("consumer failed");
            }

            return "completed";
        });
        Line($"{"async iterator",-34} consumer: {outcome}; source produced {produced}, its finally ran {finallyRan}");

        var channel = Channel.CreateBounded<int>(2);
        var channelProduced = 0;
        var producer = Task.Run(async () =>
        {
            for (var i = 0; i < 1000; i++)
            {
                await channel.Writer.WriteAsync(i);
                channelProduced++;
            }
        });
        outcome = await Outcome(async () =>
        {
            await foreach (var i in channel.Reader.ReadAllAsync())
            {
                if (i == 1) throw new InvalidOperationException("consumer failed");
            }

            return "completed";
        });
        Line($"{"Channel.CreateBounded(2)",-34} consumer: {outcome}; producer finished within 1 s {await Completes(producer, 1)}, Reader.Count {channel.Reader.Count}");

        var block = new ActionBlock<int>(i => { if (i == 1) throw new InvalidOperationException("consumer failed"); },
            new ExecutionDataflowBlockOptions { BoundedCapacity = 2 });
        var sent = 0;
        while (sent < 1000 && await block.SendAsync(sent))
        {
            sent++;
        }

        Line($"{"ActionBlock, BoundedCapacity 2",-34} block {block.Completion.Status}; SendAsync returned false before the end {sent < 1000}");
        Machine($"ActionBlock accepted {sent} items");

        var rxProduced = 0;
        var source = Observable.Create<int>(observer =>
        {
            for (var i = 0; i < 1000; i++)
            {
                rxProduced++;
                observer.OnNext(i);
            }

            observer.OnCompleted();
            return System.Reactive.Disposables.Disposable.Empty;
        });
        outcome = await Outcome(() =>
        {
            source.Subscribe(i => { if (i == 1) throw new InvalidOperationException("consumer failed"); });
            return Task.FromResult("completed");
        });
        Line($"{"Rx, synchronous source",-34} Subscribe: {outcome}; source produced {rxProduced}");
    }

    static async Task Bridges()
    {
        Title("Bridges");
        var channel = Channel.CreateUnbounded<string>();
        foreach (var chord in Progression) channel.Writer.TryWrite(chord);
        channel.Writer.Complete();
        Line($"ChannelReader.ReadAllAsync(): {string.Join(" ", await channel.Reader.ReadAllAsync().ToListAsync())}");

        var buffer = new BufferBlock<string>();
        foreach (var chord in Progression) buffer.Post(chord);
        buffer.Complete();
        Line($"ISourceBlock.ReceiveAllAsync(): {string.Join(" ", await buffer.ReceiveAllAsync().ToListAsync())}");

        var fromObservable = await ReadThrough(Progression.ToObservable(), Channel.CreateUnbounded<string>()).ToListAsync();
        Line($"IObservable through a channel: {string.Join(" ", fromObservable)}");

        var toObservable = await ToObservable(Progression.ToAsyncEnumerable()).ToList();
        Line($"IAsyncEnumerable with Observable.Create: {string.Join(" ", toObservable)}");

        var block = new TransformBlock<string, string>(chord => chord.ToLowerInvariant());
        var fromBlock = new List<string>();
        var observed = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        using (block.AsObservable().Subscribe(fromBlock.Add, () => observed.SetResult()))
        {
            foreach (var chord in Progression) block.Post(chord);
            block.Complete();
            await observed.Task;
        }

        Line($"ISourceBlock.AsObservable(): {string.Join(" ", fromBlock)}");

        Title("A Subject read through a channel: the channel's options decide what happens to a fast source");
        foreach (var (name, queue) in new[]
        {
            ("unbounded", Channel.CreateUnbounded<int>()),
            ("bounded 10, DropOldest", Channel.CreateBounded<int>(new BoundedChannelOptions(10) { FullMode = BoundedChannelFullMode.DropOldest })),
        })
        {
            var subject = new Subject<int>();
            var enumerator = ReadThrough(subject, queue).GetAsyncEnumerator();
            var first = enumerator.MoveNextAsync().AsTask();
            subject.OnNext(0);
            await first;
            for (var i = 1; i < 1000; i++)
            {
                subject.OnNext(i);
            }

            subject.OnCompleted();
            var read = new List<int> { enumerator.Current };
            while (await enumerator.MoveNextAsync())
            {
                read.Add(enumerator.Current);
            }

            await enumerator.DisposeAsync();
            Line($"{name,-24} 1,000 OnNext while the consumer held item 0; it then read {read.Count} items, the last {read[^1]}{(read.Count < 20 ? $": {string.Join(" ", read)}" : "")}");
        }
    }

    // IObservable<T> to IAsyncEnumerable<T>: the subscription writes into a channel, the consumer reads it
    public static async IAsyncEnumerable<T> ReadThrough<T>(IObservable<T> source, Channel<T> channel,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        using var subscription = source.Subscribe(
            item => channel.Writer.TryWrite(item),
            error => channel.Writer.TryComplete(error),
            () => channel.Writer.TryComplete());
        await foreach (var item in channel.Reader.ReadAllAsync(cancellationToken))
        {
            yield return item;
        }
    }

    // IAsyncEnumerable<T> to IObservable<T>: each subscription enumerates the source; disposing it cancels the enumeration
    public static IObservable<T> ToObservable<T>(IAsyncEnumerable<T> source) =>
        Observable.Create<T>(async (observer, cancellationToken) =>
        {
            await foreach (var item in source.WithCancellation(cancellationToken))
            {
                observer.OnNext(item);
            }

            observer.OnCompleted();
        });

    static async Task Exercises()
    {
        Title("Exercise solutions");
        var merged = new List<string>();
        await foreach (var item in Merge(Numbered("a", 3), Numbered("b", 3)))
        {
            merged.Add(item);
        }

        Line($"1. Merge(a, b): {merged.Count} items, a in order {merged.Where(m => m[0] == 'a').SequenceEqual(["a0", "a1", "a2"])}, b in order {merged.Where(m => m[0] == 'b').SequenceEqual(["b0", "b1", "b2"])}");
        Machine($"merged order: {string.Join(" ", merged)}");

        var failing = await Outcome(async () => await Merge(Numbered("a", 3), Failing()).CountAsync());
        Line($"   Merge(a, failing): {failing}");

        var batches = await GaShapeVoicingsBatches();
        Line($"2. FixedVoicings(4 windows of 3).Chunk(5): {batches}");
    }

    static async IAsyncEnumerable<string> Numbered(string prefix, int count)
    {
        for (var i = 0; i < count; i++)
        {
            await Task.Delay(5);
            yield return $"{prefix}{i}";
        }
    }

    static async IAsyncEnumerable<string> Failing()
    {
        await Task.Yield();
        yield return "b0";
        throw new InvalidOperationException("b failed");
    }

    // Exercise 1: reads both sources concurrently into a bounded channel; the first error ends the merge
    public static async IAsyncEnumerable<T> Merge<T>(IAsyncEnumerable<T> first, IAsyncEnumerable<T> second,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        var channel = Channel.CreateBounded<T>(1);

        async Task Pump(IAsyncEnumerable<T> source)
        {
            await foreach (var item in source.WithCancellation(cts.Token))
            {
                await channel.Writer.WriteAsync(item, cts.Token);
            }
        }

        var pumps = Task.WhenAll(Pump(first), Pump(second));
        _ = pumps.ContinueWith(t => channel.Writer.TryComplete(t.Exception?.InnerException), TaskScheduler.Default);
        try
        {
            await foreach (var item in channel.Reader.ReadAllAsync(cts.Token))
            {
                yield return item;
            }
        }
        finally
        {
            cts.Cancel();
            try
            {
                await pumps;
            }
            catch
            {
                // already reported through the channel, or cancelled by us
            }
        }
    }

    static async Task<string> GaShapeVoicingsBatches()
    {
        var probe = new WindowProbe { VoicingsPerWindow = 3 };
        var sizes = await FixedVoicings(4, probe).Chunk(5).Select(chunk => chunk.Length).ToListAsync();
        return string.Join(" ", sizes);
    }
}
