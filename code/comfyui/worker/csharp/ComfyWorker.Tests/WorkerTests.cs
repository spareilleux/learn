using System.Collections.Concurrent;
using System.Text.Json.Nodes;
using Learn.Comfy.Fake;
using Xunit;

namespace Learn.Comfy.Worker.Tests;

/// <summary>The worker against fake ComfyUI servers: no GPU, no model, no Python.</summary>
public sealed class WorkerTests(ITestOutputHelper output)
{
    [Fact]
    public async Task Success_stores_the_files_and_a_duplicate_delivery_does_not_run_again()
    {
        await using var h = await Harness.StartAsync(output, new FakeOptions());
        var job = Harness.NewJob(1);
        await h.Queue.EnqueueAsync(job);
        await h.Queue.EnqueueAsync(job); // the queue delivers it twice: at-least-once delivery

        await h.RunAsync(h.NewWorker("w1"));

        Assert.True(h.Store.IsDone(job.Id));
        Assert.Equal(2, Directory.GetFiles(Path.Combine(h.Store.Root, job.Id, "outputs")).Length);
        Assert.Equal(1, h.Fakes[0].Stats.Executed[job.Id]);
        Assert.Equal(2, h.Queue.Acked);
        Assert.Empty(h.Queue.DeadLetters);
        Assert.Contains(h.Log, l => l.EndsWith("already done, acknowledged without running"));
    }

    [Fact]
    public async Task Server_error_500_is_retried_with_backoff()
    {
        await using var h = await Harness.StartAsync(output, new FakeOptions { Script = ["500", "ok"] });
        var job = Harness.NewJob(2);
        await h.Queue.EnqueueAsync(job);

        await h.RunAsync(h.NewWorker("w1"));

        Assert.True(h.Store.IsDone(job.Id));
        Assert.Equal(2, h.Fakes[0].Stats.Posted[job.Id]);
        Assert.Equal(1, h.Fakes[0].Stats.Executed[job.Id]);
        Assert.Contains(h.Log, l => l.Contains("attempt 1 failed, POST /prompt 500, 500 Internal Server Error; retry in 20 ms"));
    }

    [Fact]
    public async Task WebSocket_dropping_mid_job_is_followed_again_without_posting_twice()
    {
        await using var h = await Harness.StartAsync(output, new FakeOptions { Script = ["drop"], StepMs = 50 });
        var job = Harness.NewJob(3);
        await h.Queue.EnqueueAsync(job);

        await h.RunAsync(h.NewWorker("w1"));

        Assert.True(h.Store.IsDone(job.Id));
        Assert.Single(h.Fakes[0].Stats.Drops);
        Assert.Equal(1, h.Fakes[0].Stats.Posted[job.Id]);
        Assert.Contains(h.Log, l => l.Contains("WebSocket lost, reconnecting with the same client id"));
        Assert.Contains(h.Log, l => l.Contains("done on gpu0 after 1 attempt(s)"));
    }

    [Fact]
    public async Task Validation_error_goes_to_the_dead_letter_queue_without_retry()
    {
        await using var h = await Harness.StartAsync(output, new FakeOptions { Script = ["invalid"] });
        var job = Harness.NewJob(4);
        await h.Queue.EnqueueAsync(job);

        await h.RunAsync(h.NewWorker("w1"));

        var (deadJob, reason) = Assert.Single(h.Queue.DeadLetters);
        Assert.Equal(job.Id, deadJob.Id);
        Assert.Equal("POST /prompt 400, prompt_outputs_failed_validation: node 3 (KSampler): exception_during_inner_validation", reason);
        Assert.Equal(1, h.Fakes[0].Stats.Posted[job.Id]);
        Assert.False(h.Store.IsDone(job.Id));
    }

    [Fact]
    public async Task Timeout_interrupts_the_prompt_and_gives_up_after_the_last_attempt()
    {
        await using var h = await Harness.StartAsync(output, new FakeOptions { Script = ["hang", "hang"] });
        var job = Harness.NewJob(5);
        await h.Queue.EnqueueAsync(job);

        await h.RunAsync(h.NewWorker("w1", o => o with { MaxAttempts = 2, JobTimeout = TimeSpan.FromMilliseconds(500) }));

        var (_, reason) = Assert.Single(h.Queue.DeadLetters);
        Assert.Equal("gave up after 2 attempts, last: timed out after 0.5 s", reason);
        Assert.Equal(new[] { job.Id, job.Id }, h.Fakes[0].Stats.Interrupts.ToArray());
        // The claim is released: an operator can replay the dead letter.
        Assert.True(h.Store.TryClaim(job.Id, "operator", TimeSpan.FromMinutes(1)));
    }

    [Fact]
    public async Task Out_of_memory_is_retried_and_other_execution_errors_are_not()
    {
        await using var h = await Harness.StartAsync(output, new FakeOptions { Script = ["oom", "ok", "error"] });
        var oom = Harness.NewJob(6);
        var broken = Harness.NewJob(7);
        await h.Queue.EnqueueAsync(oom);
        await h.Queue.EnqueueAsync(broken);

        await h.RunAsync(h.NewWorker("w1"));

        Assert.True(h.Store.IsDone(oom.Id));
        Assert.Contains(h.Log, l => l.Contains("attempt 1 failed, execution_error, node 2 (ImageInvert): torch.OutOfMemoryError: Allocation on device ; retry in 20 ms"));
        var (deadJob, reason) = Assert.Single(h.Queue.DeadLetters);
        Assert.Equal(broken.Id, deadJob.Id);
        Assert.Equal("execution_error, node 2 (ImageInvert): IndexError: index 3 is out of bounds for dimension 3 with size 3", reason);
    }

    [Fact]
    public async Task Two_workers_competing_for_the_same_jobs_run_each_job_once()
    {
        await using var h = await Harness.StartAsync(output, new FakeOptions { StepMs = 30 }, new FakeOptions { StepMs = 30 });
        var jobs = Enumerable.Range(10, 8).Select(Harness.NewJob).ToList();
        foreach (var job in jobs.Concat(jobs)) await h.Queue.EnqueueAsync(job); // every job delivered twice

        await h.RunAsync(h.NewWorker("w1"), h.NewWorker("w2"));

        Assert.All(jobs, job => Assert.True(h.Store.IsDone(job.Id)));
        Assert.All(jobs, job => Assert.Equal(1, h.Fakes.Sum(f => f.Stats.Executed.GetValueOrDefault(job.Id))));
        Assert.All(h.Fakes, f => Assert.NotEmpty(f.Stats.Executed));
        Assert.Equal(16, h.Queue.Acked);
        Assert.Empty(h.Queue.DeadLetters);
    }

    [Fact]
    public async Task Scheduler_picks_the_instance_with_the_shortest_queue()
    {
        await using var h = await Harness.StartAsync(output, new FakeOptions { Busy = 3 }, new FakeOptions());
        var job = Harness.NewJob(20);
        await h.Queue.EnqueueAsync(job);

        await h.RunAsync(h.NewWorker("w1"));

        Assert.Equal(1, h.Fakes[1].Stats.Executed[job.Id]);
        Assert.Empty(h.Fakes[0].Stats.Executed);
        Assert.Contains("scheduler: gpu1 chosen, queue lengths gpu0 3, gpu1 0", h.Log);
    }

    [Fact]
    public async Task Unreachable_instance_is_reported_and_skipped()
    {
        await using var h = await Harness.StartAsync(output, new FakeOptions());
        var job = Harness.NewJob(21);
        await h.Queue.EnqueueAsync(job);
        // A port nothing listens on: a server that crashed, or is still loading its models.
        var dead = new ComfyInstance("gpu-dead", new Uri("http://127.0.0.1:9/"));
        var pool = new GpuPool([dead, new ComfyInstance("gpu0", h.Fakes[0].BaseUri)], h.Write);

        var health = await pool.HealthAsync(CancellationToken.None);
        await h.RunAsync(new Worker(h.Queue, pool, h.Store, Harness.Options("w1"), h.Write));

        Assert.False(health[0].Healthy);
        Assert.True(health[1].Healthy);
        Assert.StartsWith("gpu0: healthy, device cpu, ", health[1].ToString());
        Assert.EndsWith(" MiB free, 0 prompt(s) in its queue", health[1].ToString());
        Assert.True(h.Store.IsDone(job.Id));
    }

    [Fact]
    public async Task Graceful_shutdown_lets_the_running_job_finish_and_takes_no_new_one()
    {
        await using var h = await Harness.StartAsync(output, new FakeOptions { Script = ["slow"], StepMs = 30 });
        var first = Harness.NewJob(30);
        var second = Harness.NewJob(31);
        await h.Queue.EnqueueAsync(first);
        await h.Queue.EnqueueAsync(second);
        using var stop = new CancellationTokenSource();
        using var abort = new CancellationTokenSource();

        var run = h.NewWorker("w1").RunAsync(stop.Token, abort.Token);
        await h.WaitForLogAsync("POST /prompt 200");
        stop.Cancel();                                // SIGTERM
        abort.CancelAfter(TimeSpan.FromSeconds(10));  // the grace period
        await run.WaitAsync(TimeSpan.FromSeconds(30));

        Assert.True(h.Store.IsDone(first.Id));
        Assert.False(h.Fakes[0].Stats.Posted.ContainsKey(second.Id));
    }

    [Fact]
    public async Task Shutdown_after_the_grace_period_interrupts_and_requeues()
    {
        await using var h = await Harness.StartAsync(output, new FakeOptions { Script = ["hang"] });
        var job = Harness.NewJob(32);
        await h.Queue.EnqueueAsync(job);
        using var stop = new CancellationTokenSource();
        using var abort = new CancellationTokenSource();

        var run = h.NewWorker("w1").RunAsync(stop.Token, abort.Token);
        await h.WaitForLogAsync("POST /prompt 200");
        stop.Cancel();
        abort.CancelAfter(TimeSpan.FromMilliseconds(300));
        await run.WaitAsync(TimeSpan.FromSeconds(30));

        Assert.Equal(new[] { job.Id }, h.Fakes[0].Stats.Interrupts.ToArray());
        Assert.Contains(h.Log, l => l.EndsWith("requeued at shutdown"));
        var again = await h.Queue.ReceiveAsync(CancellationToken.None);
        Assert.Equal(job.Id, again!.Job.Id);
        Assert.True(h.Store.TryClaim(job.Id, "w2", TimeSpan.FromMinutes(1)));
    }
}

sealed class Harness : IAsyncDisposable
{
    readonly ITestOutputHelper output;
    readonly ConcurrentQueue<string> log = new();

    Harness(ITestOutputHelper output, List<FakeComfyServer> fakes)
    {
        this.output = output;
        Fakes = fakes;
        Store = new ResultStore(Path.Combine(Path.GetTempPath(), "comfy-worker-tests", Guid.NewGuid().ToString("N")));
    }

    public List<FakeComfyServer> Fakes { get; }
    public InMemoryJobQueue Queue { get; } = new();
    public ResultStore Store { get; }
    public IReadOnlyCollection<string> Log => log;

    public static async Task<Harness> StartAsync(ITestOutputHelper output, params FakeOptions[] fakes)
    {
        var servers = new List<FakeComfyServer>();
        foreach (var options in fakes) servers.Add(await FakeComfyServer.StartAsync(options));
        return new Harness(output, servers);
    }

    public void Write(string line)
    {
        log.Enqueue(line);
        try { output.WriteLine(line); } catch (InvalidOperationException) { } // after the test ended
    }

    public static WorkerOptions Options(string name) => new()
    {
        Name = name,
        MaxAttempts = 3,
        BaseDelay = TimeSpan.FromMilliseconds(20),
        Jitter = false,
        JobTimeout = TimeSpan.FromSeconds(10),
        HistoryPoll = TimeSpan.FromMilliseconds(200),
    };

    /// <summary>Each worker has its own pool, over the same servers: like two processes on two machines.</summary>
    public Worker NewWorker(string name, Func<WorkerOptions, WorkerOptions>? configure = null)
    {
        var pool = new GpuPool(Fakes.Select((f, i) => new ComfyInstance($"gpu{i}", f.BaseUri)), Write, TimeSpan.FromMilliseconds(100));
        var options = Options(name);
        return new Worker(Queue, pool, Store, configure?.Invoke(options) ?? options, Write);
    }

    public async Task RunAsync(params Worker[] workers)
    {
        Queue.Complete();
        await Task.WhenAll(workers.Select(w => w.RunAsync(CancellationToken.None, CancellationToken.None)))
            .WaitAsync(TimeSpan.FromSeconds(60));
    }

    public async Task WaitForLogAsync(string fragment)
    {
        var deadline = DateTime.UtcNow.AddSeconds(20);
        while (!log.Any(l => l.Contains(fragment)))
        {
            if (DateTime.UtcNow > deadline) throw new TimeoutException($"no log line with \"{fragment}\"");
            await Task.Delay(10);
        }
    }

    /// <summary>The CI workflow of lesson 4: two images, no model. Job ids are fixed so that logs are readable.</summary>
    public static Job NewJob(int n) => Job.Create($"{n:D8}-0000-4000-8000-000000000000", JsonNode.Parse("""
        {
          "1": { "class_type": "EmptyImage", "inputs": { "width": 64, "height": 48, "batch_size": 1, "color": 3368601 } },
          "2": { "class_type": "ImageInvert", "inputs": { "image": ["1", 0] } },
          "3": { "class_type": "SaveImage", "inputs": { "filename_prefix": "ci/solid", "images": ["1", 0] } },
          "4": { "class_type": "SaveImage", "inputs": { "filename_prefix": "ci/inverted", "images": ["2", 0] } }
        }
        """)!.AsObject());

    public async ValueTask DisposeAsync()
    {
        foreach (var fake in Fakes) await fake.DisposeAsync();
        try { Directory.Delete(Store.Root, recursive: true); } catch (DirectoryNotFoundException) { }
    }
}
