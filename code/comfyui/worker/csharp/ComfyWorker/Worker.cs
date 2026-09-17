namespace Learn.Comfy.Worker;

public sealed record WorkerOptions
{
    public string Name { get; init; } = $"{Environment.MachineName}-{Environment.ProcessId}";
    public int MaxAttempts { get; init; } = 4;
    public TimeSpan BaseDelay { get; init; } = TimeSpan.FromSeconds(2);
    public TimeSpan MaxDelay { get; init; } = TimeSpan.FromMinutes(1);
    /// <summary>Full jitter spreads the retries of many workers; off, the delays are predictable (for the course's transcripts).</summary>
    public bool Jitter { get; init; } = true;
    public TimeSpan JobTimeout { get; init; } = TimeSpan.FromMinutes(10);
    public TimeSpan HistoryPoll { get; init; } = TimeSpan.FromSeconds(5);
    public int MaxReconnects { get; init; } = 5;
    public TimeSpan ClaimLease { get; init; } = TimeSpan.FromHours(1);
}

/// <summary>
/// Takes jobs from a queue and runs them on a pool of ComfyUI instances: one consumer loop per GPU,
/// retries with exponential backoff, a dead-letter queue for what will never work, and a result store
/// that makes a job id run once even when the queue delivers it twice.
/// </summary>
public sealed class Worker(IJobQueue queue, GpuPool pool, ResultStore store, WorkerOptions options, Action<string> log)
{
    readonly JobRunner runner = new(store, options, log);

    /// <summary>
    /// Runs until the queue is completed and empty, or until <paramref name="stopReceiving"/> fires.
    /// Jobs already running then get to finish, until <paramref name="abort"/> fires: those are interrupted and requeued.
    /// </summary>
    public async Task RunAsync(CancellationToken stopReceiving, CancellationToken abort)
    {
        log($"worker {options.Name}: {pool.Count} GPU(s), up to {options.MaxAttempts} attempts, job timeout {options.JobTimeout.TotalSeconds:0.#} s");
        await Task.WhenAll(Enumerable.Range(0, pool.Count).Select(_ => Task.Run(() => ConsumeAsync(stopReceiving, abort))));
        log($"worker {options.Name}: stopped");
    }

    async Task ConsumeAsync(CancellationToken stopReceiving, CancellationToken abort)
    {
        while (!stopReceiving.IsCancellationRequested)
        {
            IDelivery? delivery;
            try
            {
                delivery = await queue.ReceiveAsync(stopReceiving);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            if (delivery is null) break;
            await HandleAsync(delivery, abort);
        }
    }

    async Task HandleAsync(IDelivery delivery, CancellationToken abort)
    {
        var job = delivery.Job;
        if (store.IsDone(job.Id))
        {
            log($"job {job.Short}: already done, acknowledged without running");
            await delivery.AckAsync();
            return;
        }
        if (!store.TryClaim(job.Id, options.Name, options.ClaimLease))
        {
            // Another worker is running it. Its outcome will be acked or dead-lettered by that worker.
            log($"job {job.Short}: claimed by another worker, acknowledged without running");
            await delivery.AckAsync();
            return;
        }
        if (store.IsDone(job.Id))
        {
            // Finished by another worker between the first check and the claim.
            store.ReleaseClaim(job.Id, options.Name);
            log($"job {job.Short}: already done, acknowledged without running");
            await delivery.AckAsync();
            return;
        }

        ComfyInstance? last = null;
        for (int attempt = 1; ; attempt++)
        {
            ComfyInstance gpu;
            Outcome outcome;
            try
            {
                gpu = await pool.AcquireAsync(last, abort);
                try
                {
                    outcome = await runner.RunAsync(job, gpu, attempt, abort);
                }
                finally
                {
                    pool.Release(gpu);
                }
            }
            catch (OperationCanceledException) when (abort.IsCancellationRequested)
            {
                store.ReleaseClaim(job.Id, options.Name);
                await delivery.RequeueAsync();
                log($"job {job.Short}: requeued at shutdown");
                return;
            }
            last = gpu;

            switch (outcome.Kind)
            {
                case OutcomeKind.Succeeded:
                    store.Complete(job.Id, options.Name, gpu.Name, attempt, outcome.Files);
                    await delivery.AckAsync();
                    log($"job {job.Short}: done on {gpu.Name} after {attempt} attempt(s), {outcome.Detail}");
                    return;
                case OutcomeKind.Permanent:
                    store.Fail(job.Id, options.Name, outcome.Detail);
                    await delivery.DeadLetterAsync(outcome.Detail);
                    log($"job {job.Short}: dead-lettered, {outcome.Detail}");
                    return;
                case OutcomeKind.Transient when attempt >= options.MaxAttempts:
                    string reason = $"gave up after {attempt} attempts, last: {outcome.Detail}";
                    store.Fail(job.Id, options.Name, reason);
                    await delivery.DeadLetterAsync(reason);
                    log($"job {job.Short}: dead-lettered, {reason}");
                    return;
                default:
                    var delay = Backoff(attempt);
                    log($"job {job.Short}: attempt {attempt} failed, {outcome.Detail}; retry in {delay.TotalMilliseconds:0} ms");
                    try
                    {
                        await Task.Delay(delay, abort);
                    }
                    catch (OperationCanceledException)
                    {
                        store.ReleaseClaim(job.Id, options.Name);
                        await delivery.RequeueAsync();
                        log($"job {job.Short}: requeued at shutdown");
                        return;
                    }
                    break;
            }
        }
    }

    /// <summary>Exponential: base × 2^(attempt−1), capped; with full jitter, a random delay between 0 and that.</summary>
    public TimeSpan Backoff(int attempt)
    {
        double capped = Math.Min(options.MaxDelay.TotalMilliseconds, options.BaseDelay.TotalMilliseconds * Math.Pow(2, attempt - 1));
        return TimeSpan.FromMilliseconds(options.Jitter ? Random.Shared.NextDouble() * capped : capped);
    }
}
