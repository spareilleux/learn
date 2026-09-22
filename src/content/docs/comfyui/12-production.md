---
title: '12. ComfyUI in production: a service, a queue, several GPUs'
description: 'Turning ComfyUI into a render service — what its server gives (one prompt at a time, /prompt, /queue, /history, /interrupt, prompt ids that are not deduplicated) and what it does not, then a worker in C# and Java that takes jobs from a queue, runs them on a pool of GPUs chosen by queue length, retries with backoff, dead-letters what will never work, interrupts on timeout, catches up after a lost WebSocket and runs each job once; tested against a fake ComfyUI built from recorded shapes, on three OSes and against a real ComfyUI on the CPU, with deployment notes and the GA lab experiment as a batch of jobs.'
sidebar:
  order: 12
---

Code: the worker in C# in [`worker/csharp/ComfyWorker/`](https://github.com/spareilleux/learn/tree/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker) and in Java in [`worker/java/`](https://github.com/spareilleux/learn/tree/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/java/src/main/java/dev/learn/comfy/worker), the fake server in [`worker/csharp/FakeComfy/`](https://github.com/spareilleux/learn/tree/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/FakeComfy) with the shapes it replays in [`worker/data/recorded/`](https://github.com/spareilleux/learn/tree/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/data/recorded), the tests, the jobs files and the expected transcripts, all run by [`worker/check.sh`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/check.sh) and the workflow [`comfyui-worker-examples.yml`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/.github/workflows/comfyui-worker-examples.yml).

Lesson 4 sent one prompt and waited for it. A service receives prompts from many clients, at any time, and has to keep its promises when a server answers 500, a WebSocket drops, a GPU runs out of memory, a prompt never ends or a worker is stopped in the middle of a job. ComfyUI's server handles none of that for you: it runs one prompt at a time and checks nothing on your behalf. This lesson reads what the server does give, builds a worker around it in C# and in Java, and tests every failure without a GPU.

## The architecture

```mermaid
flowchart LR
  C1[Client] --> API[Service API]
  C2[Client] --> API
  API -->|job: id + workflow| Q[(Job queue)]
  Q --> W1[Worker 1]
  Q --> W2[Worker 2]
  W1 --> G0[ComfyUI on GPU 0]
  W1 --> G1[ComfyUI on GPU 1]
  W2 --> G2[ComfyUI on GPU 2]
  W1 --> S[(Result storage)]
  W2 --> S
  Q -.->|failed for good| D[(Dead letters)]
  API -.->|reads status and files| S
```

- **Clients** never talk to ComfyUI. They send a job to the **service API** and read its result later. ComfyUI has no authentication, and its queue is global to the server.
- The **job queue** holds jobs until a worker takes one, and gives a job back if the worker dies before acknowledging it. In this lesson it is an in-memory queue for tests and a single machine, then [RabbitMQ](../../rabbitmq/).
- A **worker** takes as many jobs as it has GPUs, sends each to one **ComfyUI process per GPU**, follows it, and downloads the outputs.
- **Result storage** holds the files and a record of each finished job. It is also what makes a job run once.
- **Dead letters** are the jobs that failed for good, with their reason, for a person or a program to look at.

## What ComfyUI itself provides

Everything below is read in ComfyUI v0.36.0, commit [`ee71d5c`](https://github.com/Comfy-Org/ComfyUI/tree/ee71d5c4993f29086b27fde1629a945ae48425bf).

### One prompt at a time

`main.py` starts a single [`prompt_worker`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L319-L397) thread ([line 529](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L529)). It takes the next item from the [`PromptQueue`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L1286-L1341), a heap ordered by the prompt's number, runs it with [`e.execute`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L362), writes the history with [`task_done`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L367-L372), and sends `executing` with `node: null` ([lines 373 and 374](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L373-L374)). One server, one prompt running: to use two GPUs in parallel, you start two servers. A second prompt sent to a busy server waits in its queue, and a client can't tell from `POST /prompt` how long.

### The routes a worker uses

| Route | What the worker does with it | `server.py` |
|---|---|---|
| `GET /ws?clientId=…` | receives the events of the prompts it queued with that client id | [269-327](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L269-L327) |
| `POST /prompt` | queues a prompt with its own `prompt_id`; 200 with `number`, or 400 with `error` and `node_errors` | [1075-1147](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1075-L1147) |
| `GET /queue` | is this prompt running or pending, and how many prompts are ahead | [1067-1073](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1067-L1073) |
| `POST /queue` with `delete` | removes a pending prompt | [1149-1161](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1149-L1161) |
| `GET /history/{prompt_id}` | the outputs and status of a finished prompt | [1048-1065](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1048-L1065) |
| `POST /interrupt` with `prompt_id` | stops that prompt if it is the one running | [1163-1193](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1163-L1193) |
| `POST /free` | unloads models and frees memory at the next idle moment | [1195-1204](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1195-L1204) |
| `GET /system_stats` | is the server up, which device, how much VRAM is free | [689-740](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L689-L740) |

`client_id` is only a routing key. The WebSocket handler keeps one socket per `clientId`, and a new connection with the same id replaces the old one. Events of a prompt go to the client id it was queued with, except `status`, which [`queue_updated`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1399-L1400) broadcasts to everyone each time the queue changes. When the worker recorded a prompt being queued, it received two `status` messages.

### What the server does not do for you

These facts shape the worker. They are read in the source, and the course's [recording script](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/record/record.py) also produced the prompt id cases, the errors and the interruption on a CPU server, and saved the answers and messages in `data/recorded/`.

- **A client may choose the prompt id**, and it must be a lowercase hyphenated UUID: [`validate_job_id`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_execution/jobs.py#L34-L50) rejects any other spelling with a 400 `invalid_prompt_id`.
- **The same prompt id is not deduplicated.** Posted twice, it is queued twice, runs twice, and the second run overwrites the first one's history entry. Idempotency is the caller's job.
- **`execution_success` comes before the history.** It is sent at the end of execution, [line 824](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L824), and `task_done` writes the history afterwards. A client that calls `/history` right after the message can find nothing yet.
- **`execution_interrupted` is broadcast** to every client ([`handle_execution_error`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L686-L712)), while `execution_error` goes only to the prompt's client.
- **A reconnection doesn't replay** what the client missed: the new socket receives a `status`, and `executing` for the current node if it is the running client. A prompt that ended while you were away is only in `/history`.
- **The history entry carries the prompt's number** as `prompt[0]`. When the same prompt id has run twice, it is the only way to tell which run an entry belongs to.
- **Out of memory is an ordinary `execution_error`.** ComfyUI adds tips to the message, then unloads every model ([lines 640 to 644](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L640-L644)), so a second try can work.
- **Validation errors are a 400** with `node_errors` per node ([`validate_prompt`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L1227-L1238)); a body that isn't JSON makes aiohttp answer a 500 in plain text, `500 Internal Server Error` then `Server got itself in trouble`.
- **`/interrupt` with a `prompt_id`** interrupts only if that prompt is running, and answers 200 with an empty body either way; a pending prompt stays queued until `POST /queue` deletes it.
- **The history is bounded**: [`MAXIMUM_HISTORY_SIZE`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L1284) is 10,000 entries, and a restart empties it.

ComfyUI v0.36.0 also has `/api/jobs` routes to list and cancel jobs. The worker doesn't use them, so that it works the same with lesson 4's routes.

### Addresses, ports and devices

In [`comfy/cli_args.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py):

- `--listen` ([line 63](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L63)) defaults to `127.0.0.1`; without a value it listens on `0.0.0.0,::`. `--port` ([line 64](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L64)) defaults to 8188.
- `--cuda-device` ([line 77](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L77)) sets `CUDA_VISIBLE_DEVICES` before PyTorch loads ([`main.py`, lines 97 to 102](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L97-L102)): `--cuda-device 1 --port 8189` is the second GPU's server. On Windows, without `--cuda-device`, ComfyUI forces GPU 0 ([lines 46 to 53](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L46-L53)).
- `--base-directory` ([line 70](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L70)) and `--extra-model-paths-config` ([line 71](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L71)) separate each server's inputs and outputs from a shared models folder.
- There is no authentication. The server has `--tls-keyfile` and `--tls-certfile` ([lines 65 and 66](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L65-L66)), and [`origin_only_middleware`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L159-L197), which refuses cross-site browser requests; it stops a web page from queuing prompts on your machine, not a program on the network. `--multi-user` ([line 218](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L218)) separates user settings, not permissions. Keep ComfyUI on loopback or a private network, and let the service API do the authentication; lesson 11 has the other reasons.

## The worker

The C# worker and the Java worker have the same classes, the same command line and the same log lines, so the transcripts below are compared with the same expected files. The C# code targets .NET 10, the Java code Java 25 with Jackson 3, as in lesson 4.

| Part | C# | Java |
|---|---|---|
| a job, the queue interface, the in-memory queue | `Jobs.cs` | `Jobs.java` |
| one ComfyUI server: health, queue, history, submit, cancel, WebSocket | `ComfyInstance.cs` | `ComfyInstance.java` |
| the pool of servers and the scheduler | `GpuPool.cs` | `GpuPool.java` |
| files and job records, claims | `ResultStore.cs` | `ResultStore.java` |
| one attempt at one job | `JobRunner.cs` | `JobRunner.java` |
| consumer loops, retries, dead letters, shutdown | `Worker.cs` | `Worker.java` |
| RabbitMQ | `RabbitMqJobQueue.cs` | `RabbitMqJobQueue.java` |
| command line | `Program.cs` | `Main.java` |

### A job and its queue

A job is an id and a workflow in API format. The id is chosen by whoever enqueues the job, and it is a UUID, because the worker uses it as ComfyUI's `prompt_id`: a retry on the same server can then find the prompt in `/queue` or `/history`.

```csharp
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
```

The worker sees the queue through two interfaces. A delivery is acknowledged when the job is done, requeued at shutdown, or dead-lettered with a reason:

```csharp
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
```

The in-memory queue in C# is an unbounded [`Channel<T>`](https://learn.microsoft.com/dotnet/core/extensions/channels) with several readers, one per GPU, as in the [channels lesson](../../csharp-advanced/06-channels/#several-producers-several-consumers). In Java it is a [`LinkedBlockingQueue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/LinkedBlockingQueue.html) polled by one [virtual thread](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html) per GPU. Blocking waits in virtual threads are cheap, which is why the Java worker doesn't need Reactor here; the [Reactor lesson](../../spring-cloud-reactor/03-reactor-under-the-hood/#virtual-threads-or-reactive) compares the two approaches.

Each consumer loop takes a job only when it can run it: a worker with two GPUs has two loops, and never holds a third job that another worker could run.

### One attempt, step by step

[`JobRunner`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker/JobRunner.cs) runs one attempt of one job on one server, and never throws for what a server does. It returns an outcome: succeeded, transient failure or permanent failure.

1. **Catch up.** If `/history/{id}` already has a successful entry, a previous attempt or another worker finished the prompt: download its outputs. If `/queue` has the id, follow it instead of posting again.
2. **Connect, then post.** The WebSocket opens with a new client id before `POST /prompt`, so that no event is sent before someone listens. The answer's `number` identifies this run.
3. **Follow** until `execution_success`, `execution_error` or `execution_interrupted` for this prompt id, and only after this run's `execution_start`: an `execution_interrupted` from an earlier run with the same id, broadcast to everyone, must not end this one. Every five seconds, and after each reconnection, it also reads `/history`, and accepts only the entry whose `prompt[0]` is this run's number.
4. **Download** each output with `/view`, write it under a temporary name, then rename it.

The outcome decides what happens next:

```csharp
var (status, body) = await gpu.SubmitAsync(job, clientId, deadline.Token);
if (status == HttpStatusCode.BadRequest)
    return Outcome.Permanent($"POST /prompt 400, {DescribeErrors(body)}");
if ((int)status >= 500)
    return Outcome.Transient($"POST /prompt {(int)status}, {body.Split('\n')[0]}");
```

```csharp
case "execution_error":
    string type = data?["exception_type"]?.GetValue<string>() ?? "";
    string message = (data?["exception_message"]?.GetValue<string>() ?? "").Split('\n')[0];
    string where = $"node {data?["node_id"]} ({data?["node_type"]}): {type}: {message}";
    // An out-of-memory error depends on what else the GPU held (execution.py unloads all models
    // after one): worth another try. Anything else will fail the same way again.
    return IsOutOfMemory(type, data)
        ? Outcome.Transient($"execution_error, {where}")
        : Outcome.Permanent($"execution_error, {where}");
default:
    return Outcome.Transient($"execution_interrupted at node {data?["node_id"]}, by someone else");
```

| What happened | Outcome | Why |
|---|---|---|
| `POST /prompt` 400 | permanent | the workflow is invalid: the same body will be refused again |
| `POST /prompt` 5xx, connection refused, reset or timeout | transient | the server may be restarting |
| `execution_error` with an out-of-memory type or message | transient | memory depends on what else the GPU held |
| any other `execution_error` | permanent | a bug in the workflow or a node |
| `execution_interrupted` without a timeout | transient | someone else pressed Cancel in the interface |
| no end before the job's timeout | transient | the prompt is interrupted first |

### Retries with backoff

A transient failure is retried after a delay that doubles each time, capped at a minute. With jitter on, the default, the delay is a random value between zero and that cap, the "full jitter" of [Marc Brooker's article](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/), so that a hundred jobs failing together don't retry together.

```csharp
public TimeSpan Backoff(int attempt)
{
    double capped = Math.Min(options.MaxDelay.TotalMilliseconds, options.BaseDelay.TotalMilliseconds * Math.Pow(2, attempt - 1));
    return TimeSpan.FromMilliseconds(options.Jitter ? Random.Shared.NextDouble() * capped : capped);
}
```

```java
public Duration backoff(int attempt) {
    double capped = Math.min(options.maxDelay().toMillis(), options.baseDelay().toMillis() * Math.pow(2, attempt - 1));
    return Duration.ofMillis(Math.round(options.jitter() ? ThreadLocalRandom.current().nextDouble() * capped : capped));
}
```

A retry prefers the server of the previous attempt when queues are equal: that server may still hold the prompt in its queue or history. After the last attempt, the job goes to the dead letters with the last reason: `gave up after 4 attempts, last: …`. The defaults are 4 attempts, 2 s base delay, 1 min cap, 10 min job timeout.

### Idempotency: each job runs once

A queue with acknowledgements delivers **at least once**: a worker that dies after finishing a job but before its acknowledgement gets that job delivered again, to itself or another worker. The [RabbitMQ reliability lesson](../../rabbitmq/04-reliability/#duplicates-are-normal-idempotent-consumers) makes the same point. Since ComfyUI doesn't deduplicate either, the worker does it with three checks:

1. **`done.json`** in the job's folder of the result store: the job is finished, acknowledge without running.
2. **A claim file**, created with `FileMode.CreateNew` in C# and `StandardOpenOption.CREATE_NEW` in Java, which fails atomically if the file exists: another worker is running the job. The claim has a lease, one hour by default; a claim older than its lease belongs to a worker that died, and is taken over.
3. **The prompt id** on the server: the catch-up step finds a prompt that an earlier attempt queued or finished.

```csharp
// CreateNew fails if the file exists, atomically, on every OS and on most network file systems.
using var file = new FileStream(path, FileMode.CreateNew, FileAccess.Write);
JsonSerializer.Serialize(file, new JsonObject { ["owner"] = owner, ["expires"] = DateTimeOffset.UtcNow.Add(lease) });
return true;
```

A folder with a claim file stands in for what a real deployment would use: object storage for the files, and a database row with a unique key for the claim and the record. The rule is the same: claim before running, record before acknowledging.

### Timeouts, `/interrupt` and dead letters

Each attempt runs under a deadline linked to the worker's abort token. When the deadline fires, [`CancelPromptAsync`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker/ComfyInstance.cs) posts `/interrupt` with the prompt id, deletes the id from the queue in case it hadn't started, then waits until it has left `/queue`. Without that wait, the retry, which uses the same prompt id, could receive the interrupted run's last messages.

Permanent failures and exhausted retries go to the dead letters with a reason that a person can read. The reason is also written to `failed.txt` in the job's folder, and the claim is released, so that someone can fix the workflow and enqueue the job again.

### A pool of GPUs

A worker is given its servers on the command line, one per GPU: `--gpu gpu0=http://127.0.0.1:8188 --gpu gpu1=http://127.0.0.1:8189`. A semaphore counts the free ones. To pick a server, [`GpuPool`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker/GpuPool.cs) asks every free one for `/system_stats` and `/queue`, each probe limited to 3 seconds, and sorts the healthy ones:

```csharp
var healthy = health.Where(h => h.Health.Healthy)
    .OrderBy(h => h.Health.QueueLength)
    .ThenBy(h => h.Slot.Instance == prefer ? 0 : 1)
    .ThenBy(h => slots.IndexOf(h.Slot))
    .ToList();
```

The queue length matters because a worker is rarely a server's only client: another worker, or a person in the web interface, may have queued prompts there. "Least loaded" means "fewest prompts ahead", which ComfyUI can tell; free VRAM would be a worse signal, since ComfyUI keeps models loaded on purpose. When no server is healthy, the pool logs them and waits 5 seconds.

### Health check and graceful shutdown

`comfy-worker health` probes every server and exits with 0 if at least one is healthy, which is what a readiness probe needs:

```
gpu0: healthy, device cpu, 23238 MiB free, 0 prompt(s) in its queue
gpu1: unreachable (HttpRequestException)
exit code 0
```

The Java worker prints `ConnectException` for the second line. The rest is identical.

A container is stopped with SIGTERM, then killed after a grace period. The worker uses two tokens: `stopReceiving` stops the loops from taking new jobs, and `abort`, fired after `--grace-s` seconds, interrupts the jobs still running and gives them back to the queue. In C#, [`PosixSignalRegistration`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.posixsignalregistration) catches the signal:

```csharp
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
```

In Java, a [shutdown hook](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Runtime.html#addShutdownHook(java.lang.Thread)) runs on SIGTERM or Ctrl+C, and the JVM exits when the hook returns, so the hook waits for the main thread:

```java
Runtime.getRuntime().addShutdownHook(new Thread(() -> {
    if (!main.isAlive()) {
        return;
    }
    log.accept("shutdown: no new jobs, " + grace.toSeconds() + " s for the running ones");
    stopReceiving.cancel();
    abort.cancelAfter(grace);
    try {
        main.join();
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
    }
}));
```

Java has no `CancellationToken`, so [`Cancellation.java`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/java/src/main/java/dev/learn/comfy/worker/Cancellation.java) is a small equivalent: a flag, a parent, a deadline, and waits cut into short slices that check it. Keep the grace period below Kubernetes' `terminationGracePeriodSeconds`, 30 s by default, or the pod is killed before the worker has given its jobs back.

### With RabbitMQ

[`RabbitMqJobQueue`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker/RabbitMqJobQueue.cs) implements the same interface over the [RabbitMQ .NET client](https://www.rabbitmq.com/client-libraries/dotnet) 7.2.2, and its Java twin over the [Java client](https://www.rabbitmq.com/client-libraries/java-client) 5.35.0:

- a durable [quorum queue](https://www.rabbitmq.com/docs/quorum-queues) for jobs, and a second one, `<queue>.dead`, for dead letters;
- manual acknowledgements, and a [prefetch](https://www.rabbitmq.com/docs/consumer-prefetch) equal to the number of GPUs, so that the broker never gives a worker more jobs than it can run;
- a dead letter is published to `<queue>.dead` with the reason in an `x-worker-reason` header, then the original is acknowledged;
- a requeue at shutdown is a `basicNack` with `requeue` set;
- `enqueue` publishes a jobs file with persistent messages, the job id as message id, and publisher confirms.

```java
/** Published to the dead-letter queue with the reason in a header, then acked. */
@Override
public void deadLetter(String reason) throws IOException {
    AMQP.BasicProperties properties = MessageProperties.PERSISTENT_BASIC.builder()
            .messageId(job.id()).contentType("application/json").headers(Map.of("x-worker-reason", reason)).build();
    synchronized (channel) {
        channel.basicPublish("", deadLetterQueue, properties, body);
        channel.basicAck(tag, false);
    }
}
```

The worker publishes the dead letter itself rather than using RabbitMQ's [dead letter exchanges](https://www.rabbitmq.com/docs/dlx), because a `basicReject` can't carry a reason. If the worker dies between the publish and the ack, the job is delivered again, and `failed.txt` doesn't stop it: the dead letter can appear twice. Both adapters compile and are built by CI, but **the course hasn't run them against a broker yet**: the RabbitMQ run is *to verify*. The commands would be:

```bash
java -jar java/target/comfy-worker.jar enqueue --rabbitmq amqp://guest:guest@localhost --queue renders --jobs jobs/happy.jsonl
dotnet csharp/ComfyWorker/bin/Release/net10.0/comfy-worker.dll run --rabbitmq amqp://guest:guest@localhost --queue renders \
  --gpu gpu0=http://127.0.0.1:8188 --store out/store-rabbit
```

## Testing without ComfyUI

### A fake server from recorded shapes

A test that needs a GPU runs rarely. The worker's failures are about HTTP codes, WebSocket messages and timing, and those can be played back. [`record.py`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/record/record.py) starts a real ComfyUI v0.36.0 with `--cpu` in a temporary base directory, provokes each case with workflows that need no model, and saves requests, answers and WebSocket messages to `data/recorded/`: a success, the same prompt id posted twice, three prompts in a row, a validation error, an invalid prompt id, an `IndexError` in `ImageToMask`, an interruption, a 500 and the other routes.

[`FakeComfyServer`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/FakeComfy/FakeComfyServer.cs) is a [minimal API](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis) on [Kestrel](https://learn.microsoft.com/aspnet/core/fundamentals/servers/kestrel) that serves the same routes with those shapes, runs one prompt at a time, writes real PNG files for `SaveImage` nodes, and follows a script, one word per prompt in order of arrival:

| Word | What the fake does |
|---|---|
| `ok` | runs every node, then `execution_success` |
| `500` | answers 500 as aiohttp does when a handler raises |
| `invalid` | 400 with `prompt_outputs_failed_validation` and `node_errors` |
| `error` | `execution_error` at the second node, the recorded `IndexError` |
| `oom` | `execution_error` with the type and tips of an out-of-memory error |
| `drop` | aborts the client's WebSocket at the first node, then finishes |
| `hang` | stops at the second node until `POST /interrupt` |
| `slow` | like `ok`, ten times slower |

`--busy N` adds N prompts from another client to its queue, to test the scheduler. The fake records what it received, per prompt id, so that tests can assert how many times a prompt was posted and executed. The C# tests use it in-process; the Java tests and the transcripts start it as a program.

### The tests

[`WorkerTests.cs`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker.Tests/WorkerTests.cs) uses [xUnit v3](https://xunit.net/docs/getting-started/v3/getting-started), and [`WorkerTest.java`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/java/src/test/java/dev/learn/comfy/worker/WorkerTest.java) [JUnit 6](https://docs.junit.org/). Their names say what they check:

- `Success_stores_the_files_and_a_duplicate_delivery_does_not_run_again`: the same job enqueued twice executes once and is acknowledged twice.
- `Server_error_500_is_retried_with_backoff`: posted twice, executed once.
- `WebSocket_dropping_mid_job_is_followed_again_without_posting_twice`
- `Validation_error_goes_to_the_dead_letter_queue_without_retry`
- `Timeout_interrupts_the_prompt_and_gives_up_after_the_last_attempt`: two interrupts, then the claim is free for an operator.
- `Out_of_memory_is_retried_and_other_execution_errors_are_not`
- `Two_workers_competing_for_the_same_jobs_run_each_job_once`: 8 jobs, each delivered twice, 2 workers on 2 servers; each job executes exactly once, both servers work, 16 acknowledgements.
- `Scheduler_picks_the_instance_with_the_shortest_queue`
- `Shutdown_after_the_grace_period_interrupts_and_requeues`

C# has two more, `Unreachable_instance_is_reported_and_skipped` and `Graceful_shutdown_lets_the_running_job_finish_and_takes_no_new_one`. On the author's Windows machine:

```bash
bash code/comfyui/worker/check.sh build
bash code/comfyui/worker/check.sh test
```

```
   ComfyWorker.Tests  Total: 11, Errors: 0, Failed: 0, Skipped: 0, Not Run: 0, Time: 11.909s
[INFO] Tests run: 9, Failures: 0, Errors: 0, Skipped: 0
```

xUnit v3 test projects are programs: `check.sh` runs the test assembly with `dotnet`. `dotnet test` on .NET 10 needs `"test": {"runner": "Microsoft.Testing.Platform"}` in `global.json`, which the worker's has.

### The failures, from the command line

`check.sh transcripts` runs both workers against fake servers and compares their output with `expected/`. The jobs of [`jobs/failures.jsonl`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/jobs/failures.jsonl) meet the script `500,ok,drop,invalid,oom,ok,error,hang,hang`, with 2 attempts, a 1 s timeout and a 100 ms base delay without jitter:

```bash
dotnet csharp/ComfyWorker/bin/Release/net10.0/comfy-worker.dll run --gpu gpu0=http://127.0.0.1:52100/ \
  --store out/store-failures-cs --jobs jobs/failures.jsonl \
  --name worker-1 --no-jitter --base-delay-ms 100 --poll-ms 200 --attempts 2 --timeout-s 1
```

```
worker worker-1: 1 GPU(s), up to 2 attempts, job timeout 1 s
job 00000003: attempt 1 failed, POST /prompt 500, 500 Internal Server Error; retry in 100 ms
job 00000003 attempt 2 on gpu0: POST /prompt 200
job 00000003: done on gpu0 after 2 attempt(s), 2 file(s): 3-solid_00001_.png 12f8083634dd0a19, 4-inverted_00001_.png 12f8083634dd0a19
job 00000004 attempt 1 on gpu0: POST /prompt 200
job 00000004 attempt 1 on gpu0: WebSocket lost, reconnecting with the same client id
job 00000004: done on gpu0 after 1 attempt(s), 2 file(s): 3-solid_00002_.png 12f8083634dd0a19, 4-inverted_00002_.png 12f8083634dd0a19
job 00000005: dead-lettered, POST /prompt 400, prompt_outputs_failed_validation: node 3 (KSampler): exception_during_inner_validation
job 00000006 attempt 1 on gpu0: POST /prompt 200
job 00000006: attempt 1 failed, execution_error, node 2 (ImageInvert): torch.OutOfMemoryError: Allocation on device ; retry in 100 ms
job 00000006 attempt 2 on gpu0: POST /prompt 200
job 00000006: done on gpu0 after 2 attempt(s), 2 file(s): 3-solid_00003_.png 12f8083634dd0a19, 4-inverted_00003_.png 12f8083634dd0a19
job 00000007 attempt 1 on gpu0: POST /prompt 200
job 00000007: dead-lettered, execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
job 00000008 attempt 1 on gpu0: POST /prompt 200
job 00000008 attempt 1 on gpu0: no result after 1 s, POST /interrupt and remove it from the queue
job 00000008: attempt 1 failed, timed out after 1 s; retry in 100 ms
job 00000008 attempt 2 on gpu0: POST /prompt 200
job 00000008 attempt 2 on gpu0: no result after 1 s, POST /interrupt and remove it from the queue
job 00000008: dead-lettered, gave up after 2 attempts, last: timed out after 1 s
job 00000009 attempt 1 on gpu0: POST /prompt 200
job 00000009: done on gpu0 after 1 attempt(s), 2 file(s): 3-solid_00004_.png 12f8083634dd0a19, 4-inverted_00004_.png 12f8083634dd0a19
worker worker-1: stopped
summary: 4 acknowledged, 3 dead-lettered
  dead letter 00000005: POST /prompt 400, prompt_outputs_failed_validation: node 3 (KSampler): exception_during_inner_validation
  dead letter 00000007: execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
  dead letter 00000008: gave up after 2 attempts, last: timed out after 1 s
```

The port changes from run to run. The Java worker, `java -jar java/target/comfy-worker.jar` with the same arguments, prints exactly the same lines. The first line of job 3 has no "POST /prompt 200" because the attempt failed at the POST. The dropped WebSocket costs no second POST: the worker reconnects with the same client id and finds the end in `/history`. The OOM is retried, the `IndexError` is not.

With two fake servers, the first holding two prompts from someone else, the scheduler sends the first job to the idle one. From the Java run:

```
scheduler: gpu1 chosen, queue lengths gpu0 2, gpu1 0
scheduler: gpu0 chosen, queue lengths gpu0 2, gpu1 0
```

The second line is correct: `gpu1` is now busy with the worker's own job, and only free servers are candidates. Which job lands where depends on timing, so `check.sh` compares only the summary line, `summary: 4 acknowledged, 0 dead-lettered`.

### Against a real ComfyUI on the CPU

`check.sh integration` starts ComfyUI v0.36.0 with `--cpu` through lesson 4's `server.sh`, and runs [`jobs/real.jsonl`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/jobs/real.jsonl): lesson 4's solid color workflow, the same job a second time, a workflow that fails with an `IndexError`, and a slow one, three large blurs of a 1024 × 1024 image. The C# worker first:

```
worker worker-1: 1 GPU(s), up to 2 attempts, job timeout 120 s
job 00000021 attempt 1 on gpu0: POST /prompt 200
job 00000021: done on gpu0 after 1 attempt(s), 2 file(s): 3-solid_00001_.png 413ca196d3253a3a, 4-inverted_00001_.png 6ae2ff48c6792970
job 00000021: already done, acknowledged without running
job 00000022 attempt 1 on gpu0: POST /prompt 200
job 00000022: dead-lettered, execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
job 00000023 attempt 1 on gpu0: POST /prompt 200
job 00000023: done on gpu0 after 1 attempt(s), 1 file(s): 5-slow_00001_.png f4a8fceb7d74373b
worker worker-1: stopped
summary: 3 acknowledged, 1 dead-lettered
  dead letter 00000022: execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
```

Then the Java worker, with another result store, on the same server and the same job ids. It finds the finished prompts in `/history` and downloads them without running them again; the failed one isn't a success in the history, so it is posted and fails again:

```
job 00000021 attempt 1 on gpu0: already in /history, downloading its outputs
job 00000021: done on gpu0 after 1 attempt(s), 2 file(s): 3-solid_00001_.png <sha256>, 4-inverted_00001_.png <sha256>
job 00000021: already done, acknowledged without running
job 00000022 attempt 1 on gpu0: POST /prompt 200
job 00000022: dead-lettered, execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
job 00000023 attempt 1 on gpu0: already in /history, downloading its outputs
```

`check.sh` replaces the hashes with `<sha256>` before comparing, because PNG bytes depend on the zlib build.

### CI

The workflow has two jobs:

- **`fake`**, on Ubuntu, Windows and macOS: .NET 10, Java 25, then `bash code/comfyui/worker/check.sh`, which builds, runs both test suites, and compares the transcripts. No GPU, no model, no ComfyUI.
- **`real`**, on Ubuntu: clones ComfyUI at `v0.36.0`, checks that the tag is commit `ee71d5c`, installs PyTorch 2.13.0 for the CPU and ComfyUI's requirements, then `check.sh build` and `check.sh integration`.

The first CI run found a bug that Windows hid. `check.sh` stops the fake servers with `kill`, and on the Linux runner they stayed alive, so the script waited for them until the job was cancelled; Git Bash's `kill` on Windows had ended them. The fake now waits for SIGTERM or SIGINT with `PosixSignalRegistration`, and each job has a `timeout-minutes`. Run [35178934958](https://github.com/spareilleux/learn/actions/runs/35178934958) then passed on all four jobs.

## Deploying it

Nothing in this section has been run by the course: it is *to verify*, from the documentation cited.

- **A container.** ComfyUI v0.36.0 ships no Dockerfile. An image needs Python, a PyTorch build for its CUDA version, ComfyUI's `requirements.txt`, the custom nodes you checked (lesson 11), and a command such as `python main.py --listen 0.0.0.0 --port 8188 --base-directory /data --extra-model-paths-config /config/extra_model_paths.yaml`. The GPU reaches the container through the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html). Build the worker as a second image; it needs no GPU.
- **Kubernetes and GPUs.** With the NVIDIA device plugin, a container asks for a GPU with `resources.limits: nvidia.com/gpu: 1` ([Schedule GPUs](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/)). GPUs are limits only, and whole: two containers don't share one without time-slicing or MIG. One pod per GPU with ComfyUI and the worker as two containers keeps "one server per GPU" simple; the worker then has a single `--gpu` at `127.0.0.1`. The [pods lesson](../../kubernetes/02-pods/#three-probes) covers the probes: `comfy-worker health` fits a readiness probe, and a [startup probe](../../kubernetes/02-pods/#a-startup-probe-for-the-jvm) gives ComfyUI time to start. Its section on [requests and limits](../../kubernetes/02-pods/#requests-limits-and-qos) applies to the RAM that models take once offloaded from the GPU.
- **Shared read-only models.** A checkpoint of several gigabytes shouldn't be copied into every pod. Mount one volume read-only, and point each server at it with `extra_model_paths.yaml`; the repository's [`extra_model_paths.yaml.example`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/extra_model_paths.yaml.example) shows the format. Keep `output`, `input`, `temp` and `user` per server, under its own `--base-directory`.
- **Cold start.** A new server has to start Python, import PyTorch and the custom nodes, then load each model from disk into RAM and VRAM the first time a prompt needs it. In lesson 8, the first render on a fresh server was mostly loading from an external SSD; from a network volume it can take much longer. Warm a new server with a small prompt before its readiness probe passes, and keep its models loaded rather than scaling to zero if latency matters.
- **`--highvram` and `--lowvram`.** On a server that renders all day, [`--highvram`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L168-L172) keeps models in GPU memory instead of moving them back to CPU memory after use. `--lowvram` runs the text encoders on the CPU, but its help text says it does nothing when dynamic VRAM is on, and [`enables_dynamic_vram`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L317-L320) turns it on by default unless `--highvram`, `--gpu-only`, `--novram` or `--cpu` is given. Measure both on your workflows.
- **Cost.** A GPU costs the same per hour whether it renders or waits. The cost of an image is roughly the hourly price divided by the images per hour at the real utilization, plus storage and transfer. Batching jobs of the same model onto the same server avoids model swaps; the scheduler here doesn't do that, and it's one of the exercises.

## GA experiment

The GA lab's first experiment, [`01-chord-neck.yaml`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/ga-lab/experiments/01-chord-neck.yaml), renders a guitar neck for each of ten chords, from C to Bm7b5, with the GA fretboard map through the ControlNet, for seeds 42 and 43: twenty images. Lesson 14, the Guitar Alchemist lab, will run it with the lab's runner, on one GPU, checking memory before each prompt and measuring where the dots land. The worker is the other side of the same job: the batch as jobs in a queue, spread over whatever GPUs are there, with retries and a results file.

[`jobs/ga-chord-neck.jsonl`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/jobs/ga-chord-neck.jsonl) has one job per image. The id encodes the chord's rank and the seed, `00050043-…` for the fifth chord, D, and seed 43, so that enqueueing the file twice runs nothing twice. Each line sets the same inputs as the experiment:

```json
{"id": "00010042-0000-4000-8000-000000000000", "workflow": "../../ga-lab/workflows/ga-chord-neck.api.json", "set": {"3.seed": 42, "18.chord": "C", "18.note_style": "filled", "18.inlays": "hide", "18.fret_start": 0, "18.fret_end": 5, "22.strength": 0.8}}
```

[`jobs/results.py`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/jobs/results.py) turns the result store into one CSV row per job: its parameters, its status (`done`, `dead-lettered` or `pending`), its server, its attempts and its files. `check.sh` runs the twenty jobs against a fake server that runs out of memory once, which checks the jobs file against the workflow, not the images:

```
job 00020042 attempt 1 on gpu0: POST /prompt 200
job 00020042: attempt 1 failed, execution_error, node 4 (CheckpointLoaderSimple): torch.OutOfMemoryError: Allocation on device ; retry in 100 ms
job 00020042 attempt 2 on gpu0: POST /prompt 200
job 00020042: done on gpu0 after 2 attempt(s), 2 file(s): 9-neck_00003_.png 12f8083634dd0a19, 19-neck-map_00003_.png 12f8083634dd0a19
```

```
summary: 20 acknowledged, 0 dead-lettered
```

The first rows of the CSV:

```bash
python jobs/results.py jobs/ga-chord-neck.jsonl out/store-ga-cs
```

```
job,18.chord,18.fret_end,18.fret_start,18.inlays,18.note_style,22.strength,3.seed,status,gpu,attempts,files,reason
00010042,C,5,0,hide,filled,0.8,42,done,gpu0,1,9-neck_00001_.png:12f8083634dd0a19 19-neck-map_00001_.png:12f8083634dd0a19,
00010043,C,5,0,hide,filled,0.8,43,done,gpu0,1,9-neck_00002_.png:12f8083634dd0a19 19-neck-map_00002_.png:12f8083634dd0a19,
00020042,G,5,0,hide,filled,0.8,42,done,gpu0,2,9-neck_00003_.png:12f8083634dd0a19 19-neck-map_00003_.png:12f8083634dd0a19,
```

On the GPU, with SDXL and the ControlNet loaded, the command would be the same with the real server's address, and a second `--gpu` for a second card. That run is *to verify*: the course never starts ComfyUI on the GPU from its automated checks, and the lab's runner owns that measurement.

## Key takeaways

- One ComfyUI server runs one prompt at a time. Several GPUs mean several servers, each with `--cuda-device` and its own port, and something in front that chooses.
- ComfyUI doesn't deduplicate prompt ids, doesn't replay missed WebSocket events, sends `execution_success` before writing the history and broadcasts `execution_interrupted`. A worker has to check `/queue` and `/history` itself, and match history entries to its run's number.
- Use the job id as the `prompt_id`, claim the job before running it, record it before acknowledging it: at-least-once delivery then runs each job once.
- Classify failures: a 400 or an ordinary `execution_error` is permanent and goes to the dead letters; a 5xx, a lost connection, an out-of-memory error or a timeout is transient and retried with exponential backoff and jitter.
- A timeout isn't done until the prompt is interrupted and has left the server's queue.
- Pick the server with the fewest prompts ahead, and stop taking jobs on SIGTERM before the grace period ends.
- A fake server that replays recorded shapes tests every failure on three OSes in minutes; a CPU server with model-free workflows checks the fake against the real thing.

## Your turn

Run the fake server and make your worker meet one failure for real: kill the ComfyUI process mid-prompt, or return a 500 on `/prompt`, and check that the job comes back exactly once — not zero times, not twice. Then queue two jobs with the same id and see whether your claim really stops the second. A queue is only as good as the day something crashes while holding a job.

## Exercises

1. Compute the delays between attempts with the defaults (4 attempts, 2 s base, 1 min cap) without jitter. With full jitter, what is the expected total wait of a job that fails every time?
2. Swap steps 2 and 3 of an attempt: post first, then open the WebSocket. What can go wrong with a prompt that takes 50 ms, and what in the worker still saves the job?
3. A worker runs with `--timeout-s 7200`, and a job takes 90 minutes. The claim lease is one hour, the default. A second delivery of the job arrives at minute 70 on another worker. What happens, and how would you fix it?
4. With RabbitMQ, a worker writes `done.json`, then its container is killed before `basicAck`. Follow the job to the end. Then answer the same for a kill between the dead letter's publish and its ack.
5. Change the scheduler so that a server whose queue already has `--max-queue` prompts or more isn't a candidate, and the job waits instead. Write the C# test first, with two fake servers and `Busy`.
6. Add a column to `results.py` with each job's wall time, and say where the worker would have to record it.
7. A pod runs ComfyUI and the worker. Write its readiness probe and its `terminationGracePeriodSeconds` for a worker started with `--grace-s 60`.

<details>
<summary>Solution 1</summary>

Without jitter, the delay after attempt n is 2 s × 2^(n−1): 2 s after the first attempt, 4 s after the second, 8 s after the third. There is no delay after the fourth: the job is dead-lettered. Total, 14 s of waiting, plus up to four timeouts of 10 minutes if each attempt hangs. With full jitter, each delay is uniform between 0 and its cap, so its expected value is half: 1 + 2 + 4 = 7 s on average. The cap of one minute only matters from the delay after the sixth attempt, 2 × 2^5 = 64 s.

</details>

<details>
<summary>Solution 2</summary>

The prompt can finish before the socket is open, and its `execution_start` and `execution_success` are sent to a client id that has no socket yet. They are lost: ComfyUI doesn't replay events. The worker would then wait for messages that never come. What saves it is the periodic `/history` poll, every `--poll-ms` (5 s by default): the history entry with this run's number is found, and the job ends normally, a few seconds late. Without the poll it would wait until the job's timeout, interrupt a prompt that has already ended, and retry it.

</details>

<details>
<summary>Solution 3</summary>

At minute 60 the claim expires. At minute 70, the second worker checks `done.json` (absent), then `TryClaim`: the claim is expired, so it deletes it and takes it. If it picks the same server, the catch-up finds the prompt in `/queue` and follows it rather than posting it again. On another server, it posts the job: the prompt runs twice, and both workers write the same outputs. Fixes: make the lease longer than the attempts times the job timeout plus the delays. The defaults respect that, 4 × 10 min + 14 s is less than an hour, but a timeout of two hours needs a lease of more than 8 hours, which leaves a dead worker's job blocked that long. The better fix is to renew the lease while the job runs, with a heartbeat that rewrites `expires` every few minutes. A database claim would do the same with an `UPDATE … WHERE owner = @me`.

</details>

<details>
<summary>Solution 4</summary>

First case: the connection closes without an ack, so RabbitMQ requeues the message and delivers it to another consumer, or to the same worker after its restart. That delivery finds `done.json`, logs `already done, acknowledged without running`, and acks. The job ran once and is acknowledged once. Second case: the dead letter is in `renders.dead`, but the original is delivered again. The worker hasn't recorded the dead letter as done: it finds `failed.txt` but doesn't check it, claims the job, and runs it again. A permanent failure fails again and is dead-lettered a second time, so `renders.dead` has two copies. A consumer of the dead letters should deduplicate them by message id, or the worker could treat `failed.txt` like `done.json`, at the price of never retrying a job that someone fixed without clearing its folder.

</details>

<details>
<summary>Solution 5</summary>

The test, in `WorkerTests.cs`:

```csharp
[Fact]
public async Task Server_with_a_full_queue_is_not_a_candidate()
{
    await using var h = await Harness.StartAsync(output, new FakeOptions { Busy = 5 }, new FakeOptions());
    var job = Harness.NewJob(40);
    await h.Queue.EnqueueAsync(job);

    await h.RunAsync(h.NewWorker("w1"));

    Assert.Empty(h.Fakes[0].Stats.Executed);
    Assert.Equal(1, h.Fakes[1].Stats.Executed[job.Id]);
}
```

It already passes, because the idle server has the shorter queue. Make it fail first: give the second server `Busy = 5` too, and assert that the job isn't posted within a second. Then in `GpuPool.AcquireAsync`, filter `h.Health.QueueLength < maxQueue` before sorting, and treat "no candidate" like "no healthy server": log and wait. The `--busy` prompts never run, so the job then waits forever; stop the worker in the test with `stopReceiving` and assert `Posted` is empty. The code of this solution hasn't been compiled by the course: *to verify*.

</details>

<details>
<summary>Solution 6</summary>

The worker doesn't record it, so `results.py` can't compute it. In `Worker.HandleAsync`, measure from the first claim to `store.Complete` with a `Stopwatch` (C#) or `System.nanoTime()` (Java), and pass it to `Complete`, which writes it to `done.json`, for example `"seconds": 12.4`. Then `results.py` reads `done.get("seconds", "")`. For the lab, the time per attempt is more useful than the time per job, since backoff delays are part of the second: record both.

</details>

<details>
<summary>Solution 7</summary>

```yaml
spec:
  terminationGracePeriodSeconds: 90
  containers:
    - name: worker
      readinessProbe:
        exec:
          command: ["dotnet", "/app/comfy-worker.dll", "health", "--gpu", "gpu0=http://127.0.0.1:8188"]
        periodSeconds: 10
        timeoutSeconds: 8
```

`health` exits with 1 when no server answers, so the pod isn't ready while ComfyUI starts. The grace period has to cover `--grace-s 60`, plus the interrupt and the requeue, plus ComfyUI's own stop: 90 s leaves 30 s. Kubernetes sends SIGTERM to both containers at the same time, so ComfyUI may die before the worker's jobs finish; a `preStop` hook on the ComfyUI container that sleeps for the grace period keeps it alive. That manifest has not been applied by the course: *to verify*.

</details>

## Sources

- ComfyUI at v0.36.0, commit `ee71d5c`: [`server.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py), [`main.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py), [`execution.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py), [`comfy/cli_args.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py), [`comfy_execution/jobs.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_execution/jobs.py), [`extra_model_paths.yaml.example`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/extra_model_paths.yaml.example).
- ComfyUI documentation: [server routes](https://docs.comfy.org/development/comfyui-server/comms_routes), [messages](https://docs.comfy.org/development/comfyui-server/comms_messages).
- .NET: [channels](https://learn.microsoft.com/dotnet/core/extensions/channels), [`PosixSignalRegistration`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.posixsignalregistration), [`ClientWebSocket`](https://learn.microsoft.com/dotnet/api/system.net.websockets.clientwebsocket), [minimal APIs](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis), [Kestrel](https://learn.microsoft.com/aspnet/core/fundamentals/servers/kestrel), [xUnit v3](https://xunit.net/docs/getting-started/v3/getting-started).
- Java: [`LinkedBlockingQueue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/LinkedBlockingQueue.html), [virtual threads](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html), [`Runtime.addShutdownHook`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Runtime.html#addShutdownHook(java.lang.Thread)), [`java.net.http.WebSocket`](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/WebSocket.html), [JUnit](https://docs.junit.org/).
- RabbitMQ: [quorum queues](https://www.rabbitmq.com/docs/quorum-queues), [consumer prefetch](https://www.rabbitmq.com/docs/consumer-prefetch), [dead letter exchanges](https://www.rabbitmq.com/docs/dlx), [.NET client](https://www.rabbitmq.com/client-libraries/dotnet), [Java client](https://www.rabbitmq.com/client-libraries/java-client).
- M. Brooker, [Exponential Backoff And Jitter](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/), AWS Architecture Blog, 2015.
- Kubernetes: [Schedule GPUs](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/), [pod termination](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination); NVIDIA [Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html).
