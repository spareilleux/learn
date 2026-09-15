using System.Collections.Concurrent;
using System.Reflection;
using System.Runtime.CompilerServices;
using GA.Core.Functional;
using Snippets;
using static Advanced.Report;

namespace Advanced;

// Lesson 3: the async state machine, ValueTask, synchronization contexts, exceptions and cancellation
public static class Lesson3
{
    public static void Run()
    {
        StateMachine();
        SynchronousCompletion();
        Contexts();
        Exceptions();
        Cancellation();
        Streams();
        Expiration();
    }

    static void StateMachine()
    {
        Title("The state machine behind AsyncMachine.AddLaterAsync (reflection)");
        var method = typeof(AsyncMachine).GetMethod(nameof(AsyncMachine.AddLaterAsync))!;
        var type = method.GetCustomAttribute<AsyncStateMachineAttribute>()!.StateMachineType;
        Line($"[AsyncStateMachine(typeof({type.Name}))], a {(type.IsValueType ? "struct" : "class")} implementing {string.Join(", ", type.GetInterfaces().Select(i => i.Name))}");
        foreach (var field in type.GetFields(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic).OrderBy(f => f.MetadataToken))
        {
            Line($"  {(field.IsPublic ? "public " : "private")} {TypeName(field.FieldType),-30} {field.Name}");
        }
        Line($"AddLaterAsync(2, 3).Result = {AsyncMachine.AddLaterAsync(2, 3).Result}");
    }

    static string TypeName(Type type) => type.IsGenericType
        ? $"{type.Name[..type.Name.IndexOf('`')]}<{string.Join(", ", type.GetGenericArguments().Select(TypeName))}>"
        : type.IsNested ? $"{type.DeclaringType!.Name}.{type.Name}" : type.Name;

    static void SynchronousCompletion()
    {
        Title("Completing synchronously: bytes allocated by one call");
        Line($"{"TaskOf(5)",-24} {Allocated(() => TaskOf(5).GetAwaiter().GetResult()),4}  (Task<int> results from -1 to 8 are cached)");
        Line($"{"TaskOf(500)",-24} {Allocated(() => TaskOf(500).GetAwaiter().GetResult()),4}");
        Line($"{"ValueTaskOf(500)",-24} {Allocated(() => ValueTaskOf(500).GetAwaiter().GetResult()),4}");
        Line($"{"Task.FromResult(true)",-24} {Allocated(() => Task.FromResult(true).GetAwaiter().GetResult()),4}");
    }

    public static async Task<int> TaskOf(int value)
    {
        await Task.CompletedTask;
        return value;
    }

    public static async ValueTask<int> ValueTaskOf(int value)
    {
        await Task.CompletedTask;
        return value;
    }

    static void Contexts()
    {
        Title("SynchronizationContext: where the code after await runs");
        using var ui = new SingleThreadContext("ui");
        ui.Run(async () =>
        {
            Line($"before await:                     on ui {ui.IsCurrent}");
            await Task.Delay(10);
            Line($"after await Task.Delay:           on ui {ui.IsCurrent}");
            await Task.Delay(10).ConfigureAwait(false);
            Line($"after ConfigureAwait(false):      on ui {ui.IsCurrent}, pool thread {Thread.CurrentThread.IsThreadPoolThread}");
        });

        Title("Blocking on async code from the ui thread");
        ui.Run(() =>
        {
            var captured = DelayThenAdd(captureContext: true);
            Line($"awaits with the context, .Wait(1 s):         completed {captured.Wait(TimeSpan.FromSeconds(1))}");
            var free = DelayThenAdd(captureContext: false);
            Line($"awaits with ConfigureAwait(false), .Wait(10 s): completed {free.Wait(TimeSpan.FromSeconds(10))}");
            var gaTry = Try.OfAsync(() => DelayThenAdd(captureContext: false));
            Line($"GA Try.OfAsync(...), .Wait(1 s):             completed {gaTry.Wait(TimeSpan.FromSeconds(1))}");
            return Task.CompletedTask;
        });
    }

    static async Task<int> DelayThenAdd(bool captureContext)
    {
        await Task.Delay(10).ConfigureAwait(captureContext);
        return 2 + 3;
    }

    static void Exceptions()
    {
        Title("Exceptions: await rethrows the first one, the Task keeps them all");
        var both = Task.WhenAll(FailAsync("first"), FailAsync("second"));
        try
        {
            both.GetAwaiter().GetResult();
        }
        catch (InvalidOperationException e)
        {
            var inner = both.Exception!.InnerExceptions;
            Line($"Task.Exception holds {inner.Count}: {string.Join(", ", inner.Select(x => x.Message).Order())}; await threw InnerExceptions[0]: {ReferenceEquals(e, inner[0])}");
            Machine($"in completion order: {string.Join(", ", inner.Select(x => x.Message))}");
        }
        var suppressed = Run(async () =>
        {
            await FailAsync("ignored").ConfigureAwait(ConfigureAwaitOptions.SuppressThrowing);
            return "no exception";
        });
        Line($"ConfigureAwaitOptions.SuppressThrowing: {suppressed}");
    }

    static async Task FailAsync(string message)
    {
        await Task.Yield();
        throw new InvalidOperationException(message);
    }

    static void Cancellation()
    {
        Title("Cancellation");
        using var timeout = new CancellationTokenSource(TimeSpan.FromMilliseconds(50));
        Line($"Task.Delay(10 s, token cancelled after 50 ms): {Outcome(() => Task.Delay(TimeSpan.FromSeconds(10), timeout.Token), timeout.Token)}");
        using var parent = new CancellationTokenSource();
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(parent.Token);
        parent.Cancel();
        Line($"linked token after parent.Cancel(): IsCancellationRequested {linked.Token.IsCancellationRequested}");
        Line($"Task.Delay(10 s).WaitAsync(50 ms): {Outcome(() => Task.Delay(TimeSpan.FromSeconds(10)).WaitAsync(TimeSpan.FromMilliseconds(50)), default)}");
        var cancelled = new CancellationToken(canceled: true);
        var gaTry = Try.OfAsync(() => Task.FromCanceled<int>(cancelled)).Result;
        Line($"GA Try.OfAsync(cancelled task): IsFailure {gaTry.IsFailure}, {gaTry.Match(_ => "value", e => e.GetType().Name)}, no exception thrown");
    }

    static string Outcome(Func<Task> start, CancellationToken token)
    {
        try
        {
            start().GetAwaiter().GetResult();
            return "completed";
        }
        catch (OperationCanceledException e)
        {
            return $"{e.GetType().Name}, e.CancellationToken == token {e.CancellationToken == token}";
        }
        catch (TimeoutException e)
        {
            return e.GetType().Name;
        }
    }

    static void Streams()
    {
        Title("IAsyncEnumerable: the token reaches the iterator through [EnumeratorCancellation]");
        Line(Run(async () =>
        {
            using var cts = new CancellationTokenSource();
            var seen = new List<int>();
            try
            {
                await foreach (var fret in Frets().WithCancellation(cts.Token))
                {
                    seen.Add(fret);
                    if (seen.Count == 3)
                    {
                        cts.Cancel();
                    }
                }
                return $"frets {string.Join(" ", seen)}, then completed";
            }
            catch (OperationCanceledException e)
            {
                return $"frets {string.Join(" ", seen)}, then {e.GetType().Name}";
            }
        }));
    }

    static async IAsyncEnumerable<int> Frets([EnumeratorCancellation] CancellationToken token = default)
    {
        for (var fret = 0; fret < 12; fret++)
        {
            await Task.Delay(1, token);
            yield return fret;
        }
    }

    static void Expiration()
    {
        Title("An expiring cache without a sleeping thread: TimeProvider");
        var clock = new ManualClock();
        var computed = 0;
        var cache = new ExpiringLazy<int>(() => ++computed, TimeSpan.FromMinutes(5), clock);
        Line($"t=0:     Value {cache.Value}");
        clock.Advance(TimeSpan.FromMinutes(4));
        Line($"t=4 min: Value {cache.Value}");
        clock.Advance(TimeSpan.FromMinutes(2));
        Line($"t=6 min: Value {cache.Value}");

        Title("GA LazyWithExpiration: one sleeping thread-pool thread per expiring value");
        var before = ThreadPool.ThreadCount;
        var lazies = Enumerable.Range(0, 64)
            .Select(i => new GA.Core.Utilities.LazyWithExpiration<int>(() => i, TimeSpan.FromSeconds(1)))
            .ToList();
        var sum = lazies.Sum(lazy => lazy.Value);
        var latency = System.Diagnostics.Stopwatch.StartNew();
        Task.Run(() => 0).Wait();
        Line($"sum of the 64 values: {sum}");
        Machine($"thread pool threads: {before} before, {ThreadPool.ThreadCount} after; a Task.Run(() => 0) took {latency.ElapsedMilliseconds} ms");
    }

    static T Run<T>(Func<Task<T>> start) => start().GetAwaiter().GetResult();
}

// A value computed again once it is older than the expiration, read from an injectable clock
public sealed class ExpiringLazy<T>(Func<T> create, TimeSpan expiration, TimeProvider clock)
{
    private readonly Lock _lock = new();
    private (T Value, DateTimeOffset CreatedAt)? _entry;

    public T Value
    {
        get
        {
            lock (_lock)
            {
                var now = clock.GetUtcNow();
                if (_entry is not { } entry || now - entry.CreatedAt >= expiration)
                {
                    entry = (create(), now);
                    _entry = entry;
                }
                return entry.Value;
            }
        }
    }
}

public sealed class ManualClock : TimeProvider
{
    private DateTimeOffset _now = new(2026, 9, 14, 0, 0, 0, TimeSpan.Zero);

    public override DateTimeOffset GetUtcNow() => _now;

    public void Advance(TimeSpan by) => _now += by;
}

// A single thread that runs posted callbacks in order, like the UI thread of a desktop application
public sealed class SingleThreadContext : SynchronizationContext, IDisposable
{
    private readonly BlockingCollection<(SendOrPostCallback Callback, object? State)> _queue = new();
    private readonly Thread _thread;

    public SingleThreadContext(string name)
    {
        _thread = new Thread(Loop) { Name = name, IsBackground = true };
        _thread.Start();
    }

    public bool IsCurrent => Thread.CurrentThread == _thread;

    public override void Post(SendOrPostCallback d, object? state) => _queue.Add((d, state));

    // Runs an async function on the thread and blocks the caller (not the thread) until it has finished
    public void Run(Func<Task> function)
    {
        var done = new TaskCompletionSource();
        Post(async _ =>
        {
            try
            {
                await function();
                done.SetResult();
            }
            catch (Exception e)
            {
                done.SetException(e);
            }
        }, null);
        done.Task.GetAwaiter().GetResult();
    }

    private void Loop()
    {
        SetSynchronizationContext(this);
        foreach (var (callback, state) in _queue.GetConsumingEnumerable())
        {
            callback(state);
        }
    }

    public void Dispose() => _queue.CompleteAdding();
}
