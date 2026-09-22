using System.Collections.Concurrent;
using static Advanced.Report;

namespace Advanced;

// Lesson 10: shared state, the synchronization primitive that protects it, and bounded parallel work.
public static class Lesson10
{
    public static void Run() => RunAsync().GetAwaiter().GetResult();

    private static async Task RunAsync()
    {
        Title("A lost update is a schedule, not a rare hardware accident");
        var unsafeCount = 0;
        using (var rendezvous = new Barrier(2))
        {
            var workers = Enumerable.Range(0, 2).Select(_ => Task.Factory.StartNew(() =>
            {
                var snapshot = unsafeCount;
                rendezvous.SignalAndWait();
                unsafeCount = snapshot + 1;
            }, CancellationToken.None, TaskCreationOptions.LongRunning, TaskScheduler.Default)).ToArray();
            await Task.WhenAll(workers);
        }
        Line($"two increments without synchronization: {unsafeCount}");

        Title("Lock protects an invariant; Interlocked protects one atomic update");
        var gate = new Lock();
        var locked = 0;
        Parallel.For(0, 10_000, _ =>
        {
            lock (gate) locked++;
        });
        var atomic = 0;
        Parallel.For(0, 10_000, _ => Interlocked.Increment(ref atomic));
        Line($"Lock count: {locked}");
        Line($"Interlocked count: {atomic}");

        Title("ConcurrentDictionary makes one operation atomic, not a multi-step workflow");
        var counts = new ConcurrentDictionary<string, int>(StringComparer.Ordinal);
        Parallel.For(0, 1_000, _ => counts.AddOrUpdate("Cmaj7", 1, static (_, current) => current + 1));
        Line($"AddOrUpdate count: {counts["Cmaj7"]}");

        Title("Parallel.ForEachAsync bounds active asynchronous bodies");
        var active = 0;
        var maximum = 0;
        await Parallel.ForEachAsync(Enumerable.Range(0, 8),
            new ParallelOptions { MaxDegreeOfParallelism = 2 }, async (_, token) =>
            {
                var now = Interlocked.Increment(ref active);
                InterlockedExtensions.Max(ref maximum, now);
                await Task.Delay(20, token);
                Interlocked.Decrement(ref active);
            });
        Line($"configured degree: 2; maximum observed bodies: {maximum}");

        ThreadPool.GetMinThreads(out var workersMin, out var completionMin);
        Machine($"thread-pool minimums: workers={workersMin}, completion-port={completionMin}");
    }

    private static class InterlockedExtensions
    {
        public static void Max(ref int location, int candidate)
        {
            var current = Volatile.Read(ref location);
            while (candidate > current)
            {
                var observed = Interlocked.CompareExchange(ref location, candidate, current);
                if (observed == current) return;
                current = observed;
            }
        }
    }
}
