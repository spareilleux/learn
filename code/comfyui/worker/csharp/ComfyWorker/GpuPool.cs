namespace Learn.Comfy.Worker;

/// <summary>
/// The ComfyUI instances a worker can use, one per GPU. A worker sends at most one job at a time to each
/// instance it owns, and picks, among its free instances, the one whose server queue is shortest: other
/// workers, or people using the web UI, may have queued prompts there too.
/// </summary>
public sealed class GpuPool
{
    readonly List<Slot> slots;
    readonly SemaphoreSlim free;
    readonly Lock gate = new();
    readonly Action<string> log;
    readonly TimeSpan unhealthyWait;

    public GpuPool(IEnumerable<ComfyInstance> instances, Action<string> log, TimeSpan? unhealthyWait = null)
    {
        slots = instances.Select(i => new Slot(i)).ToList();
        if (slots.Count == 0) throw new ArgumentException("a pool needs at least one ComfyUI instance");
        free = new SemaphoreSlim(slots.Count, slots.Count);
        this.log = log;
        this.unhealthyWait = unhealthyWait ?? TimeSpan.FromSeconds(5);
    }

    public int Count => slots.Count;

    /// <summary>Waits for a free, healthy instance, and reserves it. <paramref name="prefer"/> wins ties: a retry
    /// goes back to the server that may still hold the prompt in its queue or history.</summary>
    public async Task<ComfyInstance> AcquireAsync(ComfyInstance? prefer, CancellationToken cancel)
    {
        await free.WaitAsync(cancel);
        try
        {
            while (true)
            {
                List<Slot> candidates;
                lock (gate) candidates = slots.Where(s => !s.Busy).ToList();
                var health = await Task.WhenAll(candidates.Select(async s => (Slot: s, Health: await s.Instance.CheckHealthAsync(cancel))));
                var healthy = health.Where(h => h.Health.Healthy)
                    .OrderBy(h => h.Health.QueueLength)
                    .ThenBy(h => h.Slot.Instance == prefer ? 0 : 1)
                    .ThenBy(h => slots.IndexOf(h.Slot))
                    .ToList();
                if (healthy.Count == 0)
                {
                    log($"no healthy GPU among {string.Join(", ", health.Select(h => h.Health))}: waiting {unhealthyWait.TotalSeconds:0.#} s");
                    await Task.Delay(unhealthyWait, cancel);
                    continue;
                }
                lock (gate)
                {
                    var chosen = healthy.First(h => !h.Slot.Busy).Slot;
                    chosen.Busy = true;
                    if (health.Length > 1)
                        log($"scheduler: {chosen.Instance.Name} chosen, queue lengths {string.Join(", ", health.Select(h => h.Health.Healthy ? $"{h.Health.Name} {h.Health.QueueLength}" : $"{h.Health.Name} down"))}");
                    return chosen.Instance;
                }
            }
        }
        catch
        {
            free.Release();
            throw;
        }
    }

    public void Release(ComfyInstance instance)
    {
        lock (gate) slots.Single(s => s.Instance == instance).Busy = false;
        free.Release();
    }

    /// <summary>What a readiness probe would report: every instance, busy or not.</summary>
    public Task<GpuHealth[]> HealthAsync(CancellationToken cancel) =>
        Task.WhenAll(slots.Select(s => s.Instance.CheckHealthAsync(cancel)));

    sealed class Slot(ComfyInstance instance)
    {
        public ComfyInstance Instance => instance;
        public bool Busy;
    }
}
