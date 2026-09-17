// ComfyUI course, lesson 12: a worker that takes render jobs from a queue and runs them on several ComfyUI instances.
using System.Runtime.InteropServices;
using System.Text.Json.Nodes;
using Learn.Comfy.Worker;

if (args.Length == 0)
{
    Console.Error.WriteLine("""
        usage: comfy-worker <command> ...
          run --gpu name=url [--gpu name=url]... --store dir (--jobs jobs.jsonl | --rabbitmq amqp://host --queue name)
              [--name worker] [--attempts 4] [--base-delay-ms 2000] [--no-jitter] [--timeout-s 600] [--poll-ms 5000] [--grace-s 30]
                                  run jobs until the file is done, or until Ctrl+C or SIGTERM with a queue
          enqueue --rabbitmq amqp://host --queue name --jobs jobs.jsonl
                                  publish jobs to RabbitMQ
          health --gpu name=url [--gpu name=url]...
                                  what a readiness probe would see: exit code 0 if at least one instance answers
        jobs.jsonl: one job per line, {"id": "<uuid>", "workflow": "file.api.json", "set": {"3.seed": 42}}
        """);
    return 2;
}

var options = Options.Parse(args[1..]);
Action<string> log = line => Console.WriteLine(line);
switch (args[0])
{
    case "health":
    {
        var pool = new GpuPool(options.Gpus(), log);
        var health = await pool.HealthAsync(CancellationToken.None);
        foreach (var h in health) Console.WriteLine(h);
        return health.Any(h => h.Healthy) ? 0 : 1;
    }
    case "enqueue":
    {
        foreach (var job in Jobs.Read(options.Single("--jobs")))
        {
            await RabbitMqJobQueue.PublishAsync(new Uri(options.Single("--rabbitmq")), options.Single("--queue"), job);
            Console.WriteLine($"published job {job.Short}");
        }
        return 0;
    }
    case "run":
    {
        var workerOptions = new WorkerOptions
        {
            Name = options.Get("--name") ?? new WorkerOptions().Name,
            MaxAttempts = int.Parse(options.Get("--attempts") ?? "4"),
            BaseDelay = TimeSpan.FromMilliseconds(double.Parse(options.Get("--base-delay-ms") ?? "2000")),
            Jitter = !options.Has("--no-jitter"),
            JobTimeout = TimeSpan.FromSeconds(double.Parse(options.Get("--timeout-s") ?? "600")),
            HistoryPoll = TimeSpan.FromMilliseconds(double.Parse(options.Get("--poll-ms") ?? "5000")),
        };
        var pool = new GpuPool(options.Gpus(), log);
        var store = new ResultStore(options.Single("--store"));

        // Ctrl+C or SIGTERM (what Kubernetes sends before killing a pod): stop taking jobs, let running ones
        // finish for the grace period, then interrupt them and give them back to the queue.
        using var stopReceiving = new CancellationTokenSource();
        using var abort = new CancellationTokenSource();
        var grace = TimeSpan.FromSeconds(double.Parse(options.Get("--grace-s") ?? "30"));
        void Stop(PosixSignalContext context)
        {
            context.Cancel = true;
            if (stopReceiving.IsCancellationRequested) return;
            log($"{context.Signal}: no new jobs, {grace.TotalSeconds:0} s for the running ones");
            stopReceiving.Cancel();
            abort.CancelAfter(grace);
        }
        using var sigint = PosixSignalRegistration.Create(PosixSignal.SIGINT, Stop);
        using var sigterm = PosixSignalRegistration.Create(PosixSignal.SIGTERM, Stop);

        if (options.Get("--rabbitmq") is { } broker)
        {
            await using var queue = await RabbitMqJobQueue.ConnectAsync(new Uri(broker), options.Single("--queue"), (ushort)pool.Count, CancellationToken.None);
            await new Worker(queue, pool, store, workerOptions, log).RunAsync(stopReceiving.Token, abort.Token);
            return 0;
        }

        var memory = new InMemoryJobQueue();
        foreach (var job in Jobs.Read(options.Single("--jobs"))) await memory.EnqueueAsync(job);
        memory.Complete();
        await new Worker(memory, pool, store, workerOptions, log).RunAsync(stopReceiving.Token, abort.Token);
        Console.WriteLine($"summary: {memory.Acked} acknowledged, {memory.DeadLetters.Count} dead-lettered");
        foreach (var (job, reason) in memory.DeadLetters.OrderBy(d => d.Job.Id, StringComparer.Ordinal))
            Console.WriteLine($"  dead letter {job.Short}: {reason}");
        return 0;
    }
    default:
        Console.Error.WriteLine($"unknown command {args[0]}");
        return 2;
}

sealed class Options(List<(string Key, string? Value)> values)
{
    static readonly HashSet<string> Flags = ["--no-jitter"];

    public static Options Parse(string[] args)
    {
        var values = new List<(string, string?)>();
        for (int i = 0; i < args.Length; i++)
            values.Add(Flags.Contains(args[i]) ? (args[i], null) : (args[i], args[++i]));
        return new Options(values);
    }

    public bool Has(string key) => values.Any(v => v.Key == key);
    public string? Get(string key) => values.LastOrDefault(v => v.Key == key).Value;
    public string Single(string key) => Get(key) ?? throw new ArgumentException($"{key} is required");

    public List<ComfyInstance> Gpus() => values.Where(v => v.Key == "--gpu")
        .Select(v => v.Value!.Split('=', 2))
        .Select(p => new ComfyInstance(p[0], new Uri(p[1])))
        .ToList();
}

static class Jobs
{
    public static IEnumerable<Job> Read(string path)
    {
        string dir = Path.GetDirectoryName(Path.GetFullPath(path))!;
        foreach (string line in File.ReadLines(path))
        {
            if (string.IsNullOrWhiteSpace(line)) continue;
            var json = JsonNode.Parse(line)!;
            var workflow = json["workflow"] is JsonValue file
                ? JsonNode.Parse(File.ReadAllText(Path.Combine(dir, file.GetValue<string>())))!.AsObject()
                : json["workflow"]!.DeepClone().AsObject();
            foreach (var (target, value) in json["set"]?.AsObject() ?? [])
            {
                string[] parts = target.Split('.', 2);
                workflow[parts[0]]!["inputs"]![parts[1]] = value!.DeepClone();
            }
            yield return Job.Create(json["id"]!.GetValue<string>(), workflow);
        }
    }
}
