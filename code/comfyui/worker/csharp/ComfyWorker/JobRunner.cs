using System.Net;
using System.Net.WebSockets;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Learn.Comfy.Worker;

/// <summary>One attempt at one job on one ComfyUI instance. It never throws for what a server does: it returns
/// an <see cref="Outcome"/>, and the worker decides between done, retry and dead letter.</summary>
public sealed class JobRunner(ResultStore store, WorkerOptions options, Action<string> log)
{
    public async Task<Outcome> RunAsync(Job job, ComfyInstance gpu, int attempt, CancellationToken abort)
    {
        using var deadline = CancellationTokenSource.CreateLinkedTokenSource(abort);
        deadline.CancelAfter(options.JobTimeout);
        string prefix = $"job {job.Short} attempt {attempt} on {gpu.Name}";
        ClientWebSocket? socket = null;
        try
        {
            // 1. Catch up. A previous attempt may have queued this prompt here, or even finished it,
            //    before its WebSocket or this worker died: the prompt id is the job id, so the server knows it.
            if (await gpu.GetHistoryAsync(job.Id, deadline.Token) is { } previous && Succeeded(previous))
            {
                log($"{prefix}: already in /history, downloading its outputs");
                return await DownloadAsync(job, gpu, previous, deadline.Token);
            }
            var queue = await gpu.GetQueueAsync(deadline.Token);
            bool queued = queue.Contains(job.Id);

            // 2. Connect first, then post: the server sends events only to the client id the prompt was queued with.
            string clientId = Guid.NewGuid().ToString("N");
            socket = await gpu.ConnectAsync(clientId, deadline.Token);
            // The number the server gave this run. The same prompt id can have an older entry in /history, from an
            // attempt that timed out or was interrupted: only the entry with this number is this run's.
            double number;
            if (queued)
            {
                number = queue.Numbers[job.Id];
                log($"{prefix}: already in /queue, following it");
            }
            else
            {
                var (status, body) = await gpu.SubmitAsync(job, clientId, deadline.Token);
                if (status == HttpStatusCode.BadRequest)
                    return Outcome.Permanent($"POST /prompt 400, {DescribeErrors(body)}");
                if ((int)status >= 500)
                    return Outcome.Transient($"POST /prompt {(int)status}, {body.Split('\n')[0]}");
                if (status != HttpStatusCode.OK)
                    return Outcome.Transient($"POST /prompt {(int)status}");
                number = JsonNode.Parse(body)!["number"]!.GetValue<double>();
                log($"{prefix}: POST /prompt 200");
            }

            // 3. Follow until the prompt ends, reconnecting when the WebSocket drops.
            var (end, data) = await FollowAsync(job, gpu, clientId, prefix, s => socket = s, socket, started: queue.Running.Contains(job.Id), number, deadline.Token);
            switch (end)
            {
                case "execution_success":
                    // execution_success is sent before the history is written (execution.py, then main.py's task_done).
                    JsonObject? history;
                    while ((history = await gpu.GetHistoryAsync(job.Id, deadline.Token)) is null || !IsRun(history, number))
                        await Task.Delay(50, deadline.Token);
                    return await DownloadAsync(job, gpu, history, deadline.Token);
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
            }
        }
        catch (OperationCanceledException) when (deadline.IsCancellationRequested && !abort.IsCancellationRequested)
        {
            log($"{prefix}: no result after {options.JobTimeout.TotalSeconds:0.#} s, POST /interrupt and remove it from the queue");
            await TryCancelAsync(gpu, job);
            return Outcome.Transient($"timed out after {options.JobTimeout.TotalSeconds:0.#} s");
        }
        catch (OperationCanceledException) when (abort.IsCancellationRequested)
        {
            // The worker is shutting down and its grace period is over: stop the prompt, the job goes back to the queue.
            log($"{prefix}: shutdown, POST /interrupt");
            await TryCancelAsync(gpu, job);
            throw;
        }
        catch (Exception e) when (e is HttpRequestException or WebSocketException or IOException or JsonException or TaskCanceledException)
        {
            return Outcome.Transient($"{e.GetType().Name}: {e.Message}");
        }
        finally
        {
            socket?.Dispose();
        }
    }

    async Task<(string End, JsonNode? Data)> FollowAsync(Job job, ComfyInstance gpu, string clientId, string prefix,
        Action<ClientWebSocket> replaced, ClientWebSocket socket, bool started, double number, CancellationToken cancel)
    {
        int reconnects = 0;
        Task<JsonNode>? receive = null;
        Task? tick = null;
        while (true)
        {
            receive ??= ComfyInstance.ReceiveJsonAsync(socket, cancel);
            // Wake up now and then even if nothing arrives: an end message sent while we were
            // reconnecting is lost, and only /history has it.
            tick ??= Task.Delay(options.HistoryPoll, cancel);
            var first = await Task.WhenAny(receive, tick);
            cancel.ThrowIfCancellationRequested();
            if (first == tick)
            {
                tick = null;
                if (await gpu.GetHistoryAsync(job.Id, cancel) is { } history && IsRun(history, number))
                    return EndFromHistory(history);
                continue;
            }
            try
            {
                var message = await receive;
                receive = null;
                string type = message["type"]!.GetValue<string>();
                var data = message["data"];
                if (data?["prompt_id"]?.GetValue<string>() != job.Id) continue;
                // An end message before this run's execution_start belongs to an earlier run with the same prompt id:
                // execution_interrupted, for one, is broadcast to every client.
                if (type == "execution_start") started = true;
                else if (started && type is "execution_success" or "execution_error" or "execution_interrupted")
                    return (type, data);
            }
            catch (Exception e) when ((e is WebSocketException or IOException) && !cancel.IsCancellationRequested)
            {
                receive = null;
                if (++reconnects > options.MaxReconnects) throw;
                // The exception's type and message depend on the OS and on how the connection died.
                log($"{prefix}: WebSocket lost, reconnecting with the same client id");
                await Task.Delay(TimeSpan.FromMilliseconds(100 * reconnects), cancel);
                socket.Dispose();
                socket = await gpu.ConnectAsync(clientId, cancel);
                replaced(socket);
                started = true; // its execution_start may have been among the lost messages
                // The server doesn't replay what we missed: if the prompt ended meanwhile, /history says so.
                if (await gpu.GetHistoryAsync(job.Id, cancel) is { } history && IsRun(history, number))
                    return EndFromHistory(history);
            }
        }
    }

    /// <summary>history.status.messages holds the lifecycle messages: the last one says how the prompt ended.</summary>
    static (string End, JsonNode? Data) EndFromHistory(JsonObject history)
    {
        if (Succeeded(history)) return ("execution_success", null);
        var last = history["status"]?["messages"]?.AsArray().LastOrDefault();
        return (last?[0]?.GetValue<string>() ?? "execution_error", last?[1]);
    }

    static bool IsRun(JsonObject history, double number) => history["prompt"]?[0]?.GetValue<double>() == number;

    static bool Succeeded(JsonObject history) => history["status"]?["status_str"]?.GetValue<string>() == "success";

    static bool IsOutOfMemory(string type, JsonNode? data) =>
        type.EndsWith("OutOfMemoryError", StringComparison.Ordinal)
        || (data?["exception_message"]?.GetValue<string>() ?? "").Contains("ran out of memory", StringComparison.Ordinal);

    async Task<Outcome> DownloadAsync(Job job, ComfyInstance gpu, JsonObject history, CancellationToken cancel)
    {
        var files = new List<StoredFile>();
        foreach (var (node, output) in history["outputs"]!.AsObject())
            foreach (var image in output!["images"]?.AsArray() ?? [])
            {
                byte[] bytes = await gpu.ViewAsync(image!, cancel);
                files.Add(await store.SaveFileAsync(job.Id, node, image!["filename"]!.GetValue<string>(), bytes, cancel));
            }
        return Outcome.Success(files, $"{files.Count} file(s): {string.Join(", ", files.Select(f => $"{f.Name} {f.Sha256}"))}");
    }

    static string DescribeErrors(string body)
    {
        try
        {
            var json = JsonNode.Parse(body)!;
            var nodes = json["node_errors"]?.AsObject()
                .SelectMany(n => n.Value!["errors"]!.AsArray().Select(e => $"node {n.Key} ({n.Value["class_type"]}): {e!["type"]}"))
                .ToList() ?? [];
            return nodes.Count > 0 ? $"{json["error"]?["type"]}: {string.Join("; ", nodes)}" : $"{json["error"]?["type"]}: {json["error"]?["message"]}";
        }
        catch (JsonException)
        {
            return body;
        }
    }

    async Task TryCancelAsync(ComfyInstance gpu, Job job)
    {
        try
        {
            await gpu.CancelPromptAsync(job.Id);
        }
        catch (Exception e) when (e is HttpRequestException or OperationCanceledException)
        {
            log($"job {job.Short}: could not cancel on {gpu.Name}: {e.Message}");
        }
    }
}
