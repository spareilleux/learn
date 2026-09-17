using System.Collections.Concurrent;
using System.Text.Json.Nodes;
using System.Threading.Channels;

namespace Learn.Comfy.Worker;

/// <summary>
/// A render job: a workflow in API format, and an id chosen by whoever enqueued it. The id is a lowercase UUID,
/// so that it can be ComfyUI's prompt_id too: a retry on the same server finds the prompt in /queue or /history.
/// </summary>
public sealed record Job(string Id, JsonObject Workflow)
{
    public static Job Create(string id, JsonObject workflow)
    {
        // ComfyUI 0.36.0 refuses any other spelling of a UUID (comfy_execution/jobs.py, validate_job_id).
        if (!Guid.TryParse(id, out var guid) || guid.ToString() != id)
            throw new ArgumentException($"job id {id} is not a lowercase hyphenated UUID");
        return new Job(id, workflow);
    }

    public string Short => Id[..8];
}

public enum OutcomeKind { Succeeded, Transient, Permanent }

/// <summary>What one attempt gave. Transient failures are retried; permanent ones go to the dead-letter queue.</summary>
public sealed record Outcome(OutcomeKind Kind, string Detail, IReadOnlyList<StoredFile> Files)
{
    public static Outcome Success(IReadOnlyList<StoredFile> files, string detail) => new(OutcomeKind.Succeeded, detail, files);
    public static Outcome Transient(string detail) => new(OutcomeKind.Transient, detail, []);
    public static Outcome Permanent(string detail) => new(OutcomeKind.Permanent, detail, []);
}

public sealed record StoredFile(string Node, string Name, long Bytes, string Sha256);

/// <summary>A job handed to the worker, and what the worker tells the queue once it is done with it.</summary>
public interface IDelivery
{
    Job Job { get; }
    ValueTask AckAsync();
    /// <summary>Gives the job back, for another worker: used at shutdown.</summary>
    ValueTask RequeueAsync();
    ValueTask DeadLetterAsync(string reason);
}

public interface IJobQueue
{
    /// <summary>The next job, or null once the queue is completed and empty.</summary>
    ValueTask<IDelivery?> ReceiveAsync(CancellationToken cancel);
}

/// <summary>A queue in the worker's own process, over a <see cref="Channel{T}"/>: for tests, and for a single machine.</summary>
public sealed class InMemoryJobQueue : IJobQueue
{
    readonly Channel<Job> channel = Channel.CreateUnbounded<Job>(new UnboundedChannelOptions { SingleReader = false });

    public ConcurrentQueue<(Job Job, string Reason)> DeadLetters { get; } = new();
    public int Acked => acked;
    int acked;

    public ValueTask EnqueueAsync(Job job) => channel.Writer.WriteAsync(job);

    /// <summary>No more jobs: the workers stop once the queue is empty.</summary>
    public void Complete() => channel.Writer.TryComplete();

    public async ValueTask<IDelivery?> ReceiveAsync(CancellationToken cancel)
    {
        while (await channel.Reader.WaitToReadAsync(cancel))
            if (channel.Reader.TryRead(out var job))
                return new Delivery(this, job);
        return null;
    }

    sealed class Delivery(InMemoryJobQueue queue, Job job) : IDelivery
    {
        public Job Job => job;

        public ValueTask AckAsync()
        {
            Interlocked.Increment(ref queue.acked);
            return ValueTask.CompletedTask;
        }

        // A completed channel refuses writes: at shutdown, a job given back after Complete() would be lost,
        // so it goes to the dead-letter list with its reason instead.
        public ValueTask RequeueAsync()
        {
            if (!queue.channel.Writer.TryWrite(job))
                queue.DeadLetters.Enqueue((job, "requeued after the queue was completed"));
            return ValueTask.CompletedTask;
        }

        public ValueTask DeadLetterAsync(string reason)
        {
            queue.DeadLetters.Enqueue((job, reason));
            return ValueTask.CompletedTask;
        }
    }
}
