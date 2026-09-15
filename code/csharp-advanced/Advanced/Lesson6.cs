using System.Runtime.CompilerServices;
using System.Threading.Channels;
using static Advanced.Report;

namespace Advanced;

// Lesson 6: System.Threading.Channels: implementations, backpressure, full modes, completion and errors,
// several producers and consumers, cancellation, and the channel pipelines of two GA commands
public static class Lesson6
{
    public static void Run() => RunAsync().GetAwaiter().GetResult();

    static async Task RunAsync()
    {
        Implementations();
        await Backpressure();
        await FullModes();
        await CompletionAndErrors();
        await ProducersAndConsumers();
        await Cancellation();
        await GaVoicingGenerator();
        await GaIndexCommand();
        await Exercises();
    }

    static readonly string[] Progression = ["Dm7", "G7", "Cmaj7", "A7"];

    static void Implementations()
    {
        Title("Which channel you get");
        Show("CreateUnbounded<int>()", Channel.CreateUnbounded<int>());
        Show("CreateUnbounded<int>(SingleReader = true)", Channel.CreateUnbounded<int>(new UnboundedChannelOptions { SingleReader = true }));
        Show("CreateBounded<int>(10)", Channel.CreateBounded<int>(10));
        Show("CreateBounded<int>(10, SingleReader = true)", Channel.CreateBounded<int>(new BoundedChannelOptions(10) { SingleReader = true }));
        Show("CreateUnboundedPrioritized<int>()", Channel.CreateUnboundedPrioritized<int>());

        static void Show(string call, Channel<int> channel) =>
            Line($"{call,-44} {TypeName(channel.GetType()),-36} CanCount {channel.Reader.CanCount}, CanPeek {channel.Reader.CanPeek}");
    }

    static string TypeName(Type type) => type.IsGenericType ? type.Name[..type.Name.IndexOf('`')] + "<T>" : type.Name;

    static async Task Backpressure()
    {
        Title("Backpressure: a bounded channel of capacity 2 makes the writer wait");
        var channel = Channel.CreateBounded<string>(new BoundedChannelOptions(2) { FullMode = BoundedChannelFullMode.Wait });
        var writes = new List<Task>();
        foreach (var chord in Progression)
        {
            var write = channel.Writer.WriteAsync(chord);
            Line($"WriteAsync({chord}): completed {write.IsCompleted}, Reader.Count {channel.Reader.Count}");
            writes.Add(write.AsTask());
        }

        Line($"TryWrite(Dm7): {channel.Writer.TryWrite("Dm7")}");
        var first = await channel.Reader.ReadAsync();
        Line($"ReadAsync: {first}; Reader.Count {channel.Reader.Count}, Cmaj7 moved in from the waiting writer");
        await writes[2];
        Line($"WriteAsync(Cmaj7) has completed; WriteAsync(A7) still waiting {!writes[3].IsCompleted}");

        var rest = new List<string> { first };
        for (var i = 1; i < Progression.Length; i++)
        {
            rest.Add(await channel.Reader.ReadAsync());
        }

        await Task.WhenAll(writes);
        Line($"the reader got {string.Join(" ", rest)}, in the order written");
    }

    static async Task FullModes()
    {
        Title("A full channel: BoundedChannelFullMode, capacity 3, TryWrite 1 to 6");
        foreach (var mode in Enum.GetValues<BoundedChannelFullMode>())
        {
            var dropped = new List<int>();
            var channel = Channel.CreateBounded<int>(new BoundedChannelOptions(3) { FullMode = mode }, dropped.Add);
            var accepted = Enumerable.Range(1, 6).Select(i => channel.Writer.TryWrite(i)).ToList();
            channel.Writer.Complete();
            var read = await channel.Reader.ReadAllAsync().ToListAsync();
            Line($"{mode,-12} TryWrite {string.Join(" ", accepted.Select(a => a ? "true " : "false")),-35} reader gets {string.Join(" ", read),-6} dropped {(dropped.Count == 0 ? "-" : string.Join(" ", dropped))}");
        }
    }

    static async Task CompletionAndErrors()
    {
        Title("Completion: the reader drains what was written, then sees the end");
        var done = Channel.CreateUnbounded<string>();
        done.Writer.TryWrite("Dm7");
        done.Writer.TryWrite("G7");
        done.Writer.Complete();
        Line($"after Complete(): Reader.Count {done.Reader.Count}, Reader.Completion.IsCompleted {done.Reader.Completion.IsCompleted}");
        var drained = await done.Reader.ReadAllAsync().ToListAsync();
        Line($"ReadAllAsync: {string.Join(" ", drained)}; Reader.Completion {done.Reader.Completion.Status}");
        Line($"WaitToReadAsync: {await done.Reader.WaitToReadAsync()}, TryRead: {done.Reader.TryRead(out _)}");

        Title("Completion with an error");
        var failed = Channel.CreateUnbounded<string>();
        failed.Writer.TryWrite("Dm7");
        failed.Writer.TryWrite("G7");
        failed.Writer.Complete(new InvalidOperationException("the chord source failed"));
        var seen = new List<string>();
        try
        {
            await foreach (var chord in failed.Reader.ReadAllAsync())
            {
                seen.Add(chord);
            }
        }
        catch (Exception e)
        {
            Line($"ReadAllAsync: {string.Join(" ", seen)}, then {Describe(e)}");
        }

        Line($"ReadAsync: {await Outcome(async () => await failed.Reader.ReadAsync())}");
        Line($"Reader.Completion: {failed.Reader.Completion.Status}, {Describe(failed.Reader.Completion.Exception!.InnerException!)}");
        Line($"WriteAsync after Complete: {await Outcome(async () => { await failed.Writer.WriteAsync("Cmaj7"); return "written"; })}");
        Line($"TryWrite after Complete: {failed.Writer.TryWrite("Cmaj7")}, TryComplete: {failed.Writer.TryComplete()}, Complete: {await Outcome(() => { failed.Writer.Complete(); return Task.FromResult("completed"); })}");
    }

    // "ExceptionType: message", followed by the inner exception if there is one
    public static string Describe(Exception e) =>
        $"{e.GetType().Name}: {e.Message}{(e.InnerException is { } inner ? $" (inner {Describe(inner)})" : "")}";

    public static async Task<string> Outcome<T>(Func<Task<T>> action)
    {
        try
        {
            return $"{await action()}";
        }
        catch (Exception e)
        {
            return Describe(e);
        }
    }

    static async Task ProducersAndConsumers()
    {
        Title("Three producers, two consumers, one bounded channel");
        var channel = Channel.CreateBounded<(int Producer, int Index)>(new BoundedChannelOptions(2) { SingleReader = false, SingleWriter = false });
        var received = new List<(int Consumer, int Producer, int Index)>();

        var consumers = Enumerable.Range(1, 2).Select(consumer => Task.Run(async () =>
        {
            await foreach (var (producer, index) in channel.Reader.ReadAllAsync())
            {
                lock (received)
                {
                    received.Add((consumer, producer, index));
                }
            }
        })).ToList();

        var producers = Enumerable.Range(1, 3).Select(producer => Task.Run(async () =>
        {
            for (var index = 0; index < 100; index++)
            {
                await channel.Writer.WriteAsync((producer, index));
            }
        })).ToList();

        try
        {
            await Task.WhenAll(producers);
            channel.Writer.Complete();
        }
        catch (Exception e)
        {
            channel.Writer.Complete(e);
        }

        await Task.WhenAll(consumers);

        var everyItemOnce = received.Select(r => (r.Producer, r.Index)).Distinct().Count() == 300 && received.Count == 300;
        var inOrderPerProducerAndConsumer = received.GroupBy(r => (r.Consumer, r.Producer)).All(g => g.Select(r => r.Index).SequenceEqual(g.Select(r => r.Index).Order()));
        Line($"300 items written, received {received.Count}, each exactly once: {everyItemOnce}");
        Line($"each consumer saw each producer's items in the order written: {inOrderPerProducerAndConsumer}");
        Machine($"consumer 1 read {received.Count(r => r.Consumer == 1)}, consumer 2 read {received.Count(r => r.Consumer == 2)}");
    }

    static async Task Cancellation()
    {
        Title("Cancellation: a write waiting for room, a read waiting for an item");
        var channel = Channel.CreateBounded<string>(1);
        await channel.Writer.WriteAsync("Dm7");
        using var writeCts = new CancellationTokenSource();
        var waitingWrite = channel.Writer.WriteAsync("G7", writeCts.Token).AsTask();
        writeCts.Cancel();
        try
        {
            await waitingWrite;
        }
        catch (OperationCanceledException e)
        {
            Line($"WriteAsync(G7) cancelled: {e.GetType().Name}, e.CancellationToken == token {e.CancellationToken == writeCts.Token}");
        }

        Line($"Reader.Count {channel.Reader.Count}: G7 was not written; the reader gets {await channel.Reader.ReadAsync()}");

        using var readCts = new CancellationTokenSource();
        var waitingRead = channel.Reader.ReadAsync(readCts.Token).AsTask();
        readCts.Cancel();
        Line($"ReadAsync on an empty channel, cancelled: {await Outcome(async () => await waitingRead)}");
        Line($"the channel still works: TryWrite(Cmaj7) {channel.Writer.TryWrite("Cmaj7")}, TryRead {(channel.Reader.TryRead(out var next) ? next : "nothing")}");
    }

    // Counts the windows generated by the voicing generators below, and lets a test fail or hold one window
    public sealed class WindowProbe
    {
        private int _generated;
        public int Generated => _generated;
        public int FailAt { get; init; } = -1;
        public int VoicingsPerWindow { get; init; } = 100;
        public Task? Producer { get; set; }
        public ChannelReader<(int WindowIndex, List<string> Voicings)>? Reader { get; set; }
        // Window 0 waits for this before it returns, when set
        public Task? HoldWindowZero { get; init; }

        public List<string> Generate(int window)
        {
            if (window == 0 && HoldWindowZero is { } hold)
            {
                hold.Wait(TimeSpan.FromSeconds(10));
            }

            Interlocked.Increment(ref _generated);
            if (window == FailAt)
            {
                throw new InvalidOperationException($"window {window} failed");
            }

            return [.. Enumerable.Range(0, VoicingsPerWindow).Select(v => $"w{window}-v{v}")];
        }
    }

    // The shape of GA's VoicingGenerator.GenerateAllVoicingsAsync, parallel branch (VoicingGenerator.cs L180-L249):
    // parallel producers write whole windows to an unbounded channel from Task.Run, the writer is completed after the
    // loop, and the producer task is awaited after the reader's loop. The windows' contents are replaced by strings.
    public static async IAsyncEnumerable<string> GaShapeVoicings(int windows, WindowProbe probe,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        var channel = Channel.CreateUnbounded<(int WindowIndex, List<string> Voicings)>(new()
        {
            SingleReader = true,
            SingleWriter = false
        });
        probe.Reader = channel.Reader;

        var producerTask = Task.Run(async () =>
        {
            await Parallel.ForEachAsync(
                Enumerable.Range(0, windows),
                new ParallelOptions { MaxDegreeOfParallelism = 4, CancellationToken = cancellationToken },
                async (window, ct) =>
                {
                    var voicings = probe.Generate(window);
                    await channel.Writer.WriteAsync((window, voicings), ct);
                });

            channel.Writer.Complete();
        }, cancellationToken);
        probe.Producer = producerTask;

        await foreach (var result in channel.Reader.ReadAllAsync(cancellationToken))
        {
            foreach (var voicing in result.Voicings)
            {
                yield return voicing;
            }
        }

        await producerTask;
    }

    // The same generator with a bounded channel, the error passed to the reader, and the producers stopped
    // and awaited whenever the reader stops: at the end, on an error, or when the consumer leaves early
    public static async IAsyncEnumerable<string> FixedVoicings(int windows, WindowProbe probe, bool cancelInFinally = true,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        var channel = Channel.CreateBounded<(int WindowIndex, List<string> Voicings)>(new BoundedChannelOptions(4)
        {
            SingleReader = true,
            SingleWriter = false
        });
        probe.Reader = channel.Reader;

        var producerTask = Task.Run(async () =>
        {
            try
            {
                await Parallel.ForEachAsync(
                    Enumerable.Range(0, windows),
                    new ParallelOptions { MaxDegreeOfParallelism = 4, CancellationToken = cts.Token },
                    async (window, ct) => await channel.Writer.WriteAsync((window, probe.Generate(window)), ct));
                channel.Writer.Complete();
            }
            catch (Exception e)
            {
                channel.Writer.Complete(e); // the reader throws it instead of waiting forever
            }
        });
        probe.Producer = producerTask;

        try
        {
            await foreach (var result in channel.Reader.ReadAllAsync(cts.Token))
            {
                foreach (var voicing in result.Voicings)
                {
                    yield return voicing;
                }
            }
        }
        finally
        {
            if (cancelInFinally)
            {
                cts.Cancel(); // the reader stopped: stop the producers
            }

            await producerTask; // never throws: its errors went to the channel
        }
    }

    static async Task GaVoicingGenerator()
    {
        Title("GA's voicing generator shape: the consumer stops after one voicing");
        var probe = new WindowProbe();
        await foreach (var voicing in GaShapeVoicings(24, probe))
        {
            Line("one voicing read, then break");
            Machine($"it was {voicing}");
            break;
        }

        var completed = await Completes(probe.Producer!, 10);
        var unread = 0;
        while (probe.Reader!.TryRead(out _)) unread++; // SingleReader = true: this channel has no Count
        Line($"producer completed within 10 s: {completed}; windows generated {probe.Generated} of 24, left unread in the channel {unread}");

        Title("GA's voicing generator shape: window 5 throws");
        probe = new WindowProbe { FailAt = 5 };
        var consumed = 0;
        var consumer = Task.Run(async () =>
        {
            await foreach (var _ in GaShapeVoicings(24, probe))
            {
                Interlocked.Increment(ref consumed);
            }
        });
        Line($"producer: {await Faults(probe.Producer ?? await WaitForProducer(probe))}");
        Line($"consumer finished within 1 s: {await Completes(consumer, 1)}");
        Machine($"the consumer had read {consumed} voicings, and waits for a writer that will never complete the channel");

        Title("GA's voicing generator shape: does window order survive?");
        var firstRead = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        probe = new WindowProbe { HoldWindowZero = firstRead.Task, VoicingsPerWindow = 1 };
        var order = new List<string>();
        await foreach (var voicing in GaShapeVoicings(8, probe))
        {
            order.Add(voicing);
            firstRead.TrySetResult();
        }

        Line($"window 0 held until the reader got something: first voicing from window 0 {order[0] == "w0-v0"}, 8 windows read {order.Count == 8}");
        Machine($"order read: {string.Join(" ", order)}");

        Title("Fixed generator: the consumer stops after one voicing");
        probe = new WindowProbe();
        await foreach (var voicing in FixedVoicings(24, probe))
        {
            Line("one voicing read, then break");
            Machine($"it was {voicing}");
            break;
        }

        Line($"producer already completed when the loop exited: {probe.Producer!.IsCompleted}, windows generated fewer than 24: {probe.Generated < 24}");
        Machine($"windows generated {probe.Generated}");

        Title("Fixed generator: window 5 throws");
        probe = new WindowProbe { FailAt = 5 };
        consumed = 0;
        var fixedConsumer = Task.Run(async () =>
        {
            await foreach (var _ in FixedVoicings(24, probe))
            {
                consumed++;
            }
        });
        Line($"consumer: {await Faults(fixedConsumer, 10)}");
        Machine($"the consumer had read {consumed} voicings");
    }

    static async Task<Task> WaitForProducer(WindowProbe probe)
    {
        while (probe.Producer is null)
        {
            await Task.Delay(1);
        }

        return probe.Producer;
    }

    public static async Task<bool> Completes(Task task, int seconds)
    {
        var finished = await Task.WhenAny(task, Task.Delay(TimeSpan.FromSeconds(seconds)));
        return finished == task;
    }

    public static async Task<string> Faults(Task task, int seconds = 10)
    {
        if (!await Completes(task, seconds))
        {
            return $"still running after {seconds} s";
        }

        return task.Status switch
        {
            TaskStatus.Faulted => $"faulted with {Describe(task.Exception!.InnerException!)}",
            var status => status.ToString(),
        };
    }

    // The shape of GA's IndexVoicingsCommand (IndexVoicingsCommand.cs L158-L251): parallel producers write entities
    // to a bounded channel that waits when full, one consumer upserts them in batches, and each side logs its exceptions
    public static async Task GaShapeIndex(int items, Func<List<int>, Task> bulkUpsert, List<string> log, Action<ChannelReader<int>> expose)
    {
        const int batchSize = 4;
        var channel = Channel.CreateBounded<int>(new BoundedChannelOptions(batchSize * 2)
        {
            SingleWriter = false,
            SingleReader = true,
            FullMode = BoundedChannelFullMode.Wait
        });
        expose(channel.Reader);

        var consumerTask = Task.Run(async () =>
        {
            var batch = new List<int>(batchSize);
            try
            {
                await foreach (var entity in channel.Reader.ReadAllAsync())
                {
                    batch.Add(entity);
                    if (batch.Count >= batchSize)
                    {
                        await bulkUpsert(batch);
                        batch.Clear();
                    }
                }

                if (batch.Count > 0)
                {
                    await bulkUpsert(batch);
                }
            }
            catch (Exception ex)
            {
                lock (log) log.Add($"Error in DB Writer Consumer: {ex.Message}");
            }
        });

        await Parallel.ForEachAsync(Enumerable.Range(0, items), new ParallelOptions { MaxDegreeOfParallelism = 4 }, async (item, ct) =>
        {
            try
            {
                await channel.Writer.WriteAsync(item, ct);
            }
            catch (Exception ex)
            {
                lock (log) log.Add($"Failed to process voicing: {ex.Message}");
            }
        });

        channel.Writer.Complete();
        await consumerTask;
    }

    // The same command, where a failed consumer completes the channel with its exception, which stops the producers
    public static async Task FixedIndex(int items, Func<List<int>, Task> bulkUpsert)
    {
        const int batchSize = 4;
        var channel = Channel.CreateBounded<int>(new BoundedChannelOptions(batchSize * 2) { SingleReader = true });

        var consumerTask = Task.Run(async () =>
        {
            try
            {
                var batch = new List<int>(batchSize);
                await foreach (var entity in channel.Reader.ReadAllAsync())
                {
                    batch.Add(entity);
                    if (batch.Count >= batchSize)
                    {
                        await bulkUpsert(batch);
                        batch.Clear();
                    }
                }

                if (batch.Count > 0)
                {
                    await bulkUpsert(batch);
                }
            }
            catch (Exception ex)
            {
                channel.Writer.TryComplete(ex); // writers waiting for room get a ChannelClosedException
                throw;
            }
        });

        try
        {
            await Parallel.ForEachAsync(Enumerable.Range(0, items), new ParallelOptions { MaxDegreeOfParallelism = 4 },
                async (item, ct) => await channel.Writer.WriteAsync(item, ct));
            channel.Writer.TryComplete();
        }
        catch (ChannelClosedException)
        {
            // the consumer failed: awaiting it below rethrows its exception
        }

        await consumerTask;
    }

    static async Task GaIndexCommand()
    {
        Title("GA's index command shape: the first batch upsert fails");
        var log = new List<string>();
        ChannelReader<int>? reader = null;
        var upserts = 0;
        var command = GaShapeIndex(100, _ => { upserts++; throw new IOException("database unavailable"); }, log, r => reader = r);
        Line($"command finished within 1 s: {await Completes(command, 1)}");
        Line($"upserts tried {upserts}, Reader.Count {reader!.Count} (capacity 8), log: {string.Join(" | ", log)}");

        Title("Fixed index command: the first batch upsert fails");
        upserts = 0;
        var fixedCommand = FixedIndex(100, _ => { upserts++; throw new IOException("database unavailable"); });
        Line($"command: {await Faults(fixedCommand, 10)}, upserts tried {upserts}");
    }

    static async Task Exercises()
    {
        Title("Exercise solutions");
        var dropped = new List<string>();
        var oldest = Channel.CreateBounded<string>(new BoundedChannelOptions(2) { FullMode = BoundedChannelFullMode.DropOldest }, dropped.Add);
        foreach (var chord in Progression)
        {
            oldest.Writer.TryWrite(chord);
        }

        oldest.Writer.Complete();
        Line($"1. DropOldest, capacity 2: reader gets {string.Join(" ", await oldest.Reader.ReadAllAsync().ToListAsync())}, dropped {string.Join(" ", dropped)}");

        var batches = Channel.CreateUnbounded<int>();
        for (var i = 1; i <= 10; i++)
        {
            batches.Writer.TryWrite(i);
        }

        batches.Writer.Complete();
        var sizes = new List<string>();
        await foreach (var batch in ReadBatchesAsync(batches.Reader, 4))
        {
            sizes.Add($"[{string.Join(" ", batch)}]");
        }

        Line($"2. ReadBatchesAsync(max 4) over 1 to 10: {string.Join(" ", sizes)}");

        var probe = new WindowProbe();
        var enumerator = FixedVoicings(24, probe, cancelInFinally: false).GetAsyncEnumerator();
        await enumerator.MoveNextAsync();
        var dispose = enumerator.DisposeAsync().AsTask();
        Line($"3. without cts.Cancel() in finally, leaving after one voicing: DisposeAsync completed within 1 s {await Completes(dispose, 1)}, Reader.Count {probe.Reader!.Count} (capacity 4)");
    }

    // Exercise 2: waits for at least one item, then takes what is already there, up to max
    public static async IAsyncEnumerable<List<T>> ReadBatchesAsync<T>(ChannelReader<T> reader, int max,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        while (await reader.WaitToReadAsync(cancellationToken))
        {
            var batch = new List<T>(max);
            while (batch.Count < max && reader.TryRead(out var item))
            {
                batch.Add(item);
            }

            yield return batch;
        }
    }
}
