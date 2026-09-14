// Lesson 9: tasks, async/await, cancellation tokens and AsyncLocal on the C# side.
using System.Diagnostics;

static class L09
{
    static readonly AsyncLocal<string?> RequestUser = new();
    static readonly ThreadLocal<string?> CurrentUser = new();

    static async Task<int> SleepThenReturn(int id)
    {
        await Task.Delay(TimeSpan.FromSeconds(1));
        return id;
    }

    public static void Run() => RunAsync().GetAwaiter().GetResult();

    static async Task RunAsync()
    {
        // 10,000 awaits instead of 10,000 threads.
        var watch = Stopwatch.StartNew();
        int[] ids = await Task.WhenAll(Enumerable.Range(0, 10_000).Select(SleepThenReturn));
        Console.WriteLine($"10,000 tasks slept 1 s each; sum of ids = {ids.Sum(id => (long)id)}");
        Console.WriteLine($"finished in under 5 s: {watch.Elapsed < TimeSpan.FromSeconds(5)}");

        // .Result wraps the exception in AggregateException; await rethrows the original.
        Task<int> failing = Task.Run(() => int.Parse("x"));
        try { _ = failing.Result; }
        catch (AggregateException e) { Console.WriteLine($"Result: {e.GetType().Name} of {e.InnerException!.GetType().Name}"); }
        try { await failing; }
        catch (FormatException e) { Console.WriteLine($"await: {e.GetType().Name}"); }

        // Cancellation is cooperative and explicit: the token is passed down.
        using var cts = new CancellationTokenSource();
        Task sleeping = Task.Delay(TimeSpan.FromMinutes(1), cts.Token);
        cts.Cancel();
        try { await sleeping; }
        catch (TaskCanceledException) { Console.WriteLine($"cancelled: {sleeping.IsCanceled}, status: {sleeping.Status}"); }

        // lock and Interlocked.
        int locked = 0, interlocked = 0;
        var gate = new Lock();
        await Task.WhenAll(Enumerable.Range(0, 1_000).Select(_ => Task.Run(() =>
        {
            for (int i = 0; i < 1_000; i++)
            {
                lock (gate) locked++;
                Interlocked.Increment(ref interlocked);
            }
        })));
        Console.WriteLine($"lock: {locked}, Interlocked: {interlocked}");

        // AsyncLocal flows with the execution context into tasks and threads; ThreadLocal stays on its thread.
        RequestUser.Value = "grace";
        CurrentUser.Value = "ada";
        Console.WriteLine($"AsyncLocal in Task.Run: {await Task.Run(() => RequestUser.Value)}");
        string? asyncLocalSeen = null, threadLocalSeen = null;
        var thread = new Thread(() => { asyncLocalSeen = RequestUser.Value; threadLocalSeen = CurrentUser.Value; });
        thread.Start();
        thread.Join();
        Console.WriteLine($"in a new thread: AsyncLocal {asyncLocalSeen}, ThreadLocal {threadLocalSeen ?? "null"}");

        // PLINQ keeps the order only when asked.
        var squares = Enumerable.Range(1, 10).AsParallel().AsOrdered().Select(x => x * x).ToList();
        Console.WriteLine($"AsOrdered: {string.Join(", ", squares)}");
    }
}
