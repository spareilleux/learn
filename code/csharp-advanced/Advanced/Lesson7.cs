using System.Threading.Tasks.Dataflow;
using GA.Domain.Core.Theory.Atonal;
using static Advanced.Lesson6;
using static Advanced.Report;

namespace Advanced;

// Lesson 7: TPL Dataflow: a pipeline of blocks over GA's pitch-class sets, order and parallelism, bounded capacity,
// errors and completion, cancellation, and what GA's Dataflow demo and index command teach
public static class Lesson7
{
    public static void Run() => RunAsync().GetAwaiter().GetResult();

    static async Task RunAsync()
    {
        Assemblies();
        await Pipeline();
        await Order();
        await Capacity();
        await Errors();
        await CompletionIsNotYourConsumer();
        await FaultsDoNotFlowUpstream();
        await Cancellation();
        await Exercises();
    }

    // ii-V-I-vi in C as pitch-class sets: Dm7, G7, Cmaj7, Am7
    static readonly string[] Progression = ["0259", "257E", "047E", "0479"];

    static readonly DataflowLinkOptions Propagate = new() { PropagateCompletion = true };

    // The exception types from the outside in: AggregateException > PitchClassSetParseException
    static string Chain(Exception e) => e.InnerException is { } inner ? $"{e.GetType().Name} > {Chain(inner)}" : e.GetType().Name;

    static string Named(PitchClassSet set) => $"{set.Name} ({ProgrammaticForteCatalog.GetForteNumber(set)})";

    static void Assemblies()
    {
        Title("Where the types come from");
        Line($"TransformBlock<,>: {typeof(TransformBlock<,>).Assembly.GetName().Name}, in the shared framework {typeof(TransformBlock<,>).Assembly.Location.Contains("Microsoft.NETCore.App")}");
    }

    static async Task Pipeline()
    {
        Title("A pipeline: parse, describe, batch by 3, write");
        var parse = new TransformBlock<string, PitchClassSet>(s => PitchClassSet.Parse(s));
        var describe = new TransformBlock<PitchClassSet, string>(Named);
        var batch = new BatchBlock<string>(3);
        var written = new List<string>();
        var write = new ActionBlock<string[]>(names => written.Add($"[{string.Join(", ", names)}]"));

        parse.LinkTo(describe, Propagate);
        describe.LinkTo(batch, Propagate);
        batch.LinkTo(write, Propagate);

        foreach (var chord in Progression.Concat(Progression.Take(3)))
        {
            parse.Post(chord);
        }

        parse.Complete();
        await write.Completion;
        foreach (var line in written)
        {
            Line(line);
        }

        Line($"Completion: parse {parse.Completion.Status}, describe {describe.Completion.Status}, batch {batch.Completion.Status}, write {write.Completion.Status}");
    }

    // Item 0 runs until the test releases it, after items 1 to 3 have finished: what can a consumer receive meanwhile?
    static async Task<(List<int> WhileZeroRuns, List<int> Afterwards)> HoldFirst(bool ensureOrdered)
    {
        var release = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var othersFinished = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var done = 0;
        var block = new TransformBlock<int, int>(async i =>
        {
            if (i == 0)
            {
                await release.Task;
            }
            else if (Interlocked.Increment(ref done) == 3)
            {
                othersFinished.SetResult();
            }

            return i;
        }, new ExecutionDataflowBlockOptions { MaxDegreeOfParallelism = 4, EnsureOrdered = ensureOrdered });

        for (var i = 0; i < 4; i++)
        {
            block.Post(i);
        }

        block.Complete();
        await othersFinished.Task;

        // Receive for up to 500 ms while item 0 is still running
        var whileZeroRuns = new List<int>();
        using (var timeout = new CancellationTokenSource(TimeSpan.FromMilliseconds(500)))
        {
            try
            {
                while (whileZeroRuns.Count < 3 && await block.OutputAvailableAsync(timeout.Token))
                {
                    while (whileZeroRuns.Count < 3 && block.TryReceive(out var item))
                    {
                        whileZeroRuns.Add(item);
                    }
                }
            }
            catch (OperationCanceledException)
            {
            }
        }

        release.SetResult();
        var afterwards = new List<int>();
        while (await block.OutputAvailableAsync())
        {
            while (block.TryReceive(out var item))
            {
                afterwards.Add(item);
            }
        }

        await block.Completion;
        return (whileZeroRuns, afterwards);
    }

    static async Task Order()
    {
        Title("MaxDegreeOfParallelism 4: items 1 to 3 have finished, item 0 is still running");
        foreach (var ensureOrdered in new[] { true, false })
        {
            var (whileZeroRuns, afterwards) = await HoldFirst(ensureOrdered);
            var early = whileZeroRuns.Count == 0 ? "nothing" : string.Join(" ", whileZeroRuns.Order());
            Line($"EnsureOrdered = {ensureOrdered,-5}  received while item 0 runs: {early,-8} then: {string.Join(" ", afterwards)}");
            if (!ensureOrdered)
            {
                Machine($"received while item 0 runs, in arrival order: {string.Join(" ", whileZeroRuns)}");
            }
        }
    }

    static async Task Capacity()
    {
        Title("BoundedCapacity 2: Post refuses, SendAsync waits");
        var gate = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var slow = new ActionBlock<int>(async _ => await gate.Task, new ExecutionDataflowBlockOptions { BoundedCapacity = 2 });
        var posts = Enumerable.Range(1, 4).Select(i => slow.Post(i)).ToList();
        Line($"Post 1 to 4 while item 1 is running: {string.Join(" ", posts)}");
        var send = slow.SendAsync(5);
        Line($"SendAsync(5): completed {send.IsCompleted}");
        gate.SetResult();
        Line($"once item 1 finishes: SendAsync(5) returned {await send}");
        slow.Complete();
        await slow.Completion;
    }

    static async Task Errors()
    {
        Title("Errors: '04X7' does not parse");
        var parse = new TransformBlock<string, PitchClassSet>(s => PitchClassSet.Parse(s));
        var describe = new TransformBlock<PitchClassSet, string>(Named);
        var results = new BufferBlock<string>();
        parse.LinkTo(describe, Propagate);
        describe.LinkTo(results, Propagate);

        Line($"SendAsync(0259) {await parse.SendAsync("0259")}, SendAsync(04X7) {await parse.SendAsync("04X7")}");
        Line($"await parse.Completion: {await Outcome(async () => { await parse.Completion; return "completed"; })}");
        Line($"after the fault: SendAsync(047E) {await parse.SendAsync("047E")}, Post(0479) {parse.Post("0479")}");
        Line($"parse.Completion.Exception: {Chain(parse.Completion.Exception!)}");
        await Outcome(async () => { await results.Completion; return ""; });
        Line($"describe: {describe.Completion.Status}, results: {results.Completion.Status}");
        Line($"results.Completion.Exception: {Chain(results.Completion.Exception!)}");
        Line($"results.OutputAvailableAsync(): {await Outcome(async () => await results.OutputAvailableAsync())}, results.Count {results.Count}");
    }

    static async Task CompletionIsNotYourConsumer()
    {
        Title("Completion says the block is empty, not that your consumer is done");
        var block = new TransformBlock<int, int>(i => i);
        var results = new List<int>();
        var mayAddLast = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var consumer = Task.Run(async () =>
        {
            while (await block.OutputAvailableAsync())
            {
                var item = await block.ReceiveAsync();
                if (item == 2)
                {
                    await mayAddLast.Task; // still working on the last item
                }

                results.Add(item);
            }
        });

        block.Post(1);
        block.Post(2);
        block.Complete();
        await block.Completion;
        Line($"await block.Completion returned: results.Count {results.Count}");
        mayAddLast.SetResult();
        await consumer;
        Line($"await consumer returned: results.Count {results.Count}");
    }

    // The shape of GA's IndexVoicingsCommand with blocks instead of a channel: a bounded batch block feeding a writer
    static async Task<(bool Finished, BatchBlock<int> Batches, int Sent)> IndexWithBlocks(bool faultUpstream)
    {
        var batches = new BatchBlock<int>(4, new GroupingDataflowBlockOptions { BoundedCapacity = 8 });
        var writer = new ActionBlock<int[]>(_ => throw new IOException("database unavailable"),
            new ExecutionDataflowBlockOptions { BoundedCapacity = 1 });
        batches.LinkTo(writer, Propagate);
        if (faultUpstream)
        {
            _ = writer.Completion.ContinueWith(t => ((IDataflowBlock)batches).Fault(t.Exception!.InnerException!),
                TaskContinuationOptions.OnlyOnFaulted);
        }

        var sent = 0;
        var producer = Task.Run(async () =>
        {
            for (var i = 0; i < 100; i++)
            {
                if (!await batches.SendAsync(i))
                {
                    return;
                }

                sent++;
            }
        });
        return (await Completes(producer, 1), batches, sent);
    }

    static async Task FaultsDoNotFlowUpstream()
    {
        Title("GA's index command with blocks: the writer fails on its first batch");
        var (finished, batches, _) = await IndexWithBlocks(faultUpstream: false);
        Line($"producer finished within 1 s: {finished}; batch block completed {batches.Completion.IsCompleted}, OutputCount {batches.OutputCount}");

        Title("The same, with the writer's fault passed to the batch block");
        (finished, batches, var sent) = await IndexWithBlocks(faultUpstream: true);
        await Completes(batches.Completion, 10); // Fault() declines at once; Completion becomes Faulted just after
        Line($"producer finished within 1 s: {finished}, before sending all 100 items {sent < 100}; batch block: {batches.Completion.Status}, {Describe(batches.Completion.Exception!.InnerException!)}");
        Machine($"items accepted before the fault: {sent}");
    }

    static async Task Cancellation()
    {
        Title("Cancellation: the token in the block options");
        using var cts = new CancellationTokenSource();
        var started = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var block = new ActionBlock<int>(async _ =>
        {
            started.TrySetResult();
            await Task.Delay(Timeout.Infinite, cts.Token);
        }, new ExecutionDataflowBlockOptions { CancellationToken = cts.Token });
        block.Post(1);
        block.Post(2);
        await started.Task;
        cts.Cancel();
        Line($"Completion: {await Outcome(async () => { await block.Completion; return "completed"; })}, status {block.Completion.Status}");
        Line($"Post after cancellation: {block.Post(3)}, InputCount {block.InputCount}");
    }

    static async Task Exercises()
    {
        Title("Exercise solutions");
        // 1. A message that no link accepts stays at the head of the output buffer, and blocks the ones behind it
        foreach (var withNullTarget in new[] { false, true })
        {
            var parse = new TransformBlock<string, PitchClassSet>(s => PitchClassSet.Parse(s));
            var triads = new List<string>();
            var tetrads = new List<string>();
            var triadBlock = new ActionBlock<PitchClassSet>(s => triads.Add(s.Name));
            var tetradBlock = new ActionBlock<PitchClassSet>(s => tetrads.Add(s.Name));
            parse.LinkTo(triadBlock, Propagate, s => s.Cardinality.Value == 3);
            parse.LinkTo(tetradBlock, Propagate, s => s.Cardinality.Value == 4);
            if (withNullTarget)
            {
                parse.LinkTo(DataflowBlock.NullTarget<PitchClassSet>());
            }

            foreach (var chord in new[] { "047", "0259", "02479", "037", "257E" })
            {
                parse.Post(chord);
            }

            parse.Complete();
            var finished = await Completes(Task.WhenAll(triadBlock.Completion, tetradBlock.Completion), 1);
            Line($"1. {(withNullTarget ? "with NullTarget:   " : "without NullTarget:")} completed within 1 s {finished}, triads [{string.Join(", ", triads)}], tetrads [{string.Join(", ", tetrads)}], parse.OutputCount {parse.OutputCount}");
        }

        // 2. GA's DemoDataflowAsync, fixed: stop sending when the pipeline declines, await the consumer, report the fault
        var (sentCount, received, outcome) = await FixedDemo([.. Enumerable.Range(0, 1000).Select(i => i == 500 ? "musical_input_x" : $"musical_input_{i}")]);
        Line($"2. fixed demo: sending stopped before the end {sentCount < 1000}, pipeline {outcome}");
        Machine($"inputs accepted {sentCount}, results received {received}");

        // 3. TransformManyBlock: one set in, its pitch classes out
        var spread = new TransformManyBlock<PitchClassSet, PitchClass>(set => set);
        var pitchClasses = new BufferBlock<PitchClass>();
        spread.LinkTo(pitchClasses, Propagate);
        spread.Post(PitchClassSet.Parse("257E"));
        spread.Complete();
        var all = new List<PitchClass>();
        while (await pitchClasses.OutputAvailableAsync())
        {
            all.Add(await pitchClasses.ReceiveAsync());
        }

        Line($"3. TransformManyBlock over 257E: {string.Join(" ", all)}");
    }

    // Exercise 2: the pipeline of GA's DemoDataflowAsync with its parse step, fixed
    static async Task<(int Sent, int Received, string Outcome)> FixedDemo(string[] inputs)
    {
        var options = new ExecutionDataflowBlockOptions { MaxDegreeOfParallelism = 4, BoundedCapacity = 100 };
        var parseBlock = new TransformBlock<string, int>(input => int.Parse(input.Split('_')[2]) % 12, options);
        var analyzeBlock = new TransformBlock<int, string>(pc => pc switch { 0 => "C Major", 4 => "E Major", 7 => "G Major", _ => "Unknown" }, options);
        parseBlock.LinkTo(analyzeBlock, Propagate);

        var results = new List<string>();
        var outputTask = Task.Run(async () =>
        {
            while (await analyzeBlock.OutputAvailableAsync())
            {
                while (analyzeBlock.TryReceive(out var result))
                {
                    results.Add(result);
                }
            }
        });

        var sent = 0;
        foreach (var input in inputs)
        {
            if (!await parseBlock.SendAsync(input))
            {
                break;
            }

            sent++;
        }

        parseBlock.Complete();
        var outcome = await Outcome(async () => { await analyzeBlock.Completion; return "completed"; });
        var consumerFinished = await Completes(outputTask, 10);
        return (sent, results.Count, $"{outcome}, consumer finished {consumerFinished}");
    }
}
