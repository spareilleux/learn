#:package Polly.Core@8.8.0
// The .NET side of lesson 3: Polly's retry, a bounded channel's full modes, and AsyncLocal across threads.
using System.Threading.Channels;
using Polly;
using Polly.Retry;

// Retry: Polly calls the delegate again, as retry() subscribes again.
var calls = 0;
var pipeline = new ResiliencePipelineBuilder()
    .AddRetry(new RetryStrategyOptions
    {
        ShouldHandle = new PredicateBuilder().Handle<InvalidOperationException>(),
        MaxRetryAttempts = 2,
        Delay = TimeSpan.FromMilliseconds(10),
        BackoffType = DelayBackoffType.Exponential,
        UseJitter = false,
        OnRetry = args =>
        {
            Console.WriteLine($"  retry {args.AttemptNumber + 1} after {args.RetryDelay.TotalMilliseconds} ms");
            return ValueTask.CompletedTask;
        },
    })
    .Build();

string FlakyLookup()
{
    calls++;
    Console.WriteLine($"  call {calls}");
    if (calls < 3) throw new InvalidOperationException("scale service unavailable");
    return "D dorian";
}

Console.WriteLine("Polly, 2 retries:");
Console.WriteLine($"  result: {pipeline.Execute(FlakyLookup)}");

// When the retries are exhausted, Polly rethrows the last exception itself, not a wrapper.
Console.WriteLine("Polly, retries exhausted:");
try
{
    pipeline.Execute(string () => throw new InvalidOperationException("scale service still unavailable"));
}
catch (Exception e)
{
    Console.WriteLine($"  {e.GetType().Name}: {e.Message}");
}

// A bounded channel is a buffer with a policy when it is full, like onBackpressureBuffer and onBackpressureDrop.
var channel = Channel.CreateBounded<int>(new BoundedChannelOptions(3) { FullMode = BoundedChannelFullMode.DropWrite });
// DropWrite drops the item being written, yet TryWrite still returns true for it.
var accepted = Enumerable.Range(1, 10).Count(i => channel.Writer.TryWrite(i));
channel.Writer.Complete();
Console.WriteLine($"bounded channel (3, DropWrite): TryWrite returned true {accepted} times, reader gets {string.Join(", ", await channel.Reader.ReadAllAsync().ToListAsync())}");

// AsyncLocal flows to other threads, like Reactor's context through publishOn; ThreadLocal doesn't.
// A dedicated thread, because a pool thread could be the one that set the ThreadLocal.
var user = new AsyncLocal<string?> { Value = "ada" };
var threadUser = new ThreadLocal<string?> { Value = "ada" };
string? seen = null;
var thread = new Thread(() => seen = $"AsyncLocal={user.Value}, ThreadLocal={threadUser.Value ?? "null"}");
thread.Start();
thread.Join();
Console.WriteLine($"in a new thread: {seen}");
