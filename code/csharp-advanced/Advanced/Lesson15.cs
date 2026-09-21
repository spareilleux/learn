using System.Threading.Channels;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using static Advanced.Report;

namespace Advanced;

// Lesson 15: the host owns worker lifetime; a channel carries bounded work and each item owns a scope.
public static class Lesson15
{
    public static void Run() => RunAsync().GetAwaiter().GetResult();

    private static async Task RunAsync()
    {
        var probe = new WorkerProbe();
        var builder = Host.CreateApplicationBuilder();
        builder.Logging.ClearProviders();
        builder.Services.AddSingleton(probe);
        builder.Services.AddSingleton<WorkQueue>();
        builder.Services.AddScoped<ScopedWork>();
        builder.Services.AddHostedService<QueuedWorker>();

        using var host = builder.Build();
        await host.StartAsync().WaitAsync(TimeSpan.FromSeconds(5));
        await probe.Started.Task.WaitAsync(TimeSpan.FromSeconds(5));

        var queue = host.Services.GetRequiredService<WorkQueue>();
        var first = queue.Enqueue("C major");
        var second = queue.Enqueue("G major");
        var results = await Task.WhenAll(first, second).WaitAsync(TimeSpan.FromSeconds(5));

        Title("The host starts one singleton worker and the queue owns the work");
        Line($"startup observed: {probe.Started.Task.IsCompletedSuccessfully}");
        Line($"queued results: {string.Join(" | ", results.Select(result => result.Value))}");
        Line($"fresh scope per item: {results[0].ScopeId != results[1].ScopeId}");

        await host.StopAsync().WaitAsync(TimeSpan.FromSeconds(5));
        await probe.CancellationObserved.Task.WaitAsync(TimeSpan.FromSeconds(5));
        Line($"shutdown cancellation observed: {probe.CancellationObserved.Task.Result}");

        Title("A BackgroundService fault stops its host");
        var faultProbe = new FaultProbe();
        var faultBuilder = Host.CreateApplicationBuilder();
        faultBuilder.Logging.ClearProviders();
        faultBuilder.Services.Configure<HostOptions>(options =>
            options.BackgroundServiceExceptionBehavior = BackgroundServiceExceptionBehavior.StopHost);
        faultBuilder.Services.AddSingleton(faultProbe);
        faultBuilder.Services.AddHostedService<FaultingWorker>();
        using var faultHost = faultBuilder.Build();
        var stopping = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        faultHost.Services.GetRequiredService<IHostApplicationLifetime>()
            .ApplicationStopping.Register(() => stopping.TrySetResult());

        await faultHost.StartAsync().WaitAsync(TimeSpan.FromSeconds(5));
        await faultProbe.Started.Task.WaitAsync(TimeSpan.FromSeconds(5));
        faultProbe.Fail.TrySetResult();
        await stopping.Task.WaitAsync(TimeSpan.FromSeconds(5));
        Line($"fault requested host stop: {stopping.Task.IsCompletedSuccessfully}");
        try
        {
            await faultHost.StopAsync().WaitAsync(TimeSpan.FromSeconds(5));
        }
        catch (InvalidOperationException error) when (error.Message == FaultingWorker.FailureMessage)
        {
            // The worker failure remains observable when the host is stopped.
        }
    }

    private sealed class WorkerProbe
    {
        public TaskCompletionSource Started { get; } = NewGate();
        public TaskCompletionSource<bool> CancellationObserved { get; } = NewGate<bool>();
    }

    private sealed class FaultProbe
    {
        public TaskCompletionSource Started { get; } = NewGate();
        public TaskCompletionSource Fail { get; } = NewGate();
    }

    private sealed class WorkQueue
    {
        private readonly Channel<WorkItem> _channel = Channel.CreateBounded<WorkItem>(new BoundedChannelOptions(2)
        {
            FullMode = BoundedChannelFullMode.Wait,
            SingleReader = true,
            SingleWriter = true,
        });

        public ChannelReader<WorkItem> Reader => _channel.Reader;

        public Task<WorkResult> Enqueue(string value)
        {
            var item = new WorkItem(value, NewGate<WorkResult>());
            if (!_channel.Writer.TryWrite(item))
            {
                throw new InvalidOperationException("The bounded course queue unexpectedly filled.");
            }

            return item.Completion.Task;
        }
    }

    private sealed record WorkItem(string Value, TaskCompletionSource<WorkResult> Completion);
    private sealed record WorkResult(string Value, int ScopeId);

    private sealed class ScopedWork
    {
        private static int _nextId;
        public int Id { get; } = Interlocked.Increment(ref _nextId);
        public string Handle(string value) => $"{value}@scope-{Id}";
    }

    private sealed class QueuedWorker(
        WorkQueue queue,
        IServiceScopeFactory scopeFactory,
        WorkerProbe probe) : BackgroundService
    {
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            probe.Started.TrySetResult();
            try
            {
                await foreach (var item in queue.Reader.ReadAllAsync(stoppingToken))
                {
                    using var scope = scopeFactory.CreateScope();
                    var work = scope.ServiceProvider.GetRequiredService<ScopedWork>();
                    item.Completion.TrySetResult(new WorkResult(work.Handle(item.Value), work.Id));
                }
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                probe.CancellationObserved.TrySetResult(true);
            }
        }
    }

    private sealed class FaultingWorker(FaultProbe probe) : BackgroundService
    {
        public const string FailureMessage = "course worker fault";

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            probe.Started.TrySetResult();
            await probe.Fail.Task.WaitAsync(stoppingToken);
            throw new InvalidOperationException(FailureMessage);
        }
    }

    private static TaskCompletionSource NewGate() =>
        new(TaskCreationOptions.RunContinuationsAsynchronously);

    private static TaskCompletionSource<T> NewGate<T>() =>
        new(TaskCreationOptions.RunContinuationsAsynchronously);
}
