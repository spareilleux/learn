using System.Net;
using System.Net.Http.Json;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json.Nodes;

namespace Learn.Comfy.Worker;

/// <summary>
/// One ComfyUI server: in production, one process per GPU, started with --cuda-device and its own --port.
/// The calls are lesson 4's, split so that the worker can retry, catch up and interrupt.
/// </summary>
public sealed class ComfyInstance : IDisposable
{
    readonly HttpClient http;

    public ComfyInstance(string name, Uri baseUri, TimeSpan? requestTimeout = null)
    {
        Name = name;
        BaseUri = baseUri;
        http = new HttpClient { BaseAddress = baseUri, Timeout = requestTimeout ?? TimeSpan.FromSeconds(30) };
    }

    public string Name { get; }
    public Uri BaseUri { get; }

    /// <summary>GET /system_stats and GET /queue: is the server up, which device, how many prompts ahead.</summary>
    public async Task<GpuHealth> CheckHealthAsync(CancellationToken cancel)
    {
        // A probe answers quickly or counts as down: a hung server must not hold the scheduler for 30 seconds.
        using var probe = CancellationTokenSource.CreateLinkedTokenSource(cancel);
        probe.CancelAfter(TimeSpan.FromSeconds(3));
        try
        {
            var stats = await http.GetFromJsonAsync<JsonObject>("system_stats", probe.Token);
            var device = stats!["devices"]!.AsArray().FirstOrDefault();
            var queue = await GetQueueAsync(probe.Token);
            return new GpuHealth(Name, true, $"{device?["name"]}", device?["vram_free"]?.GetValue<long>() ?? 0, queue.Running.Count + queue.Pending.Count, null);
        }
        catch (Exception e) when ((e is HttpRequestException or TaskCanceledException or System.Text.Json.JsonException) && !cancel.IsCancellationRequested)
        {
            return new GpuHealth(Name, false, "", 0, 0, e.GetType().Name);
        }
    }

    /// <summary>GET /queue: each entry is [number, prompt_id, prompt, extra_data, outputs_to_execute].</summary>
    public async Task<QueueState> GetQueueAsync(CancellationToken cancel)
    {
        var queue = await http.GetFromJsonAsync<JsonObject>("queue", cancel);
        static List<string> Ids(JsonNode? entries) => entries!.AsArray().Select(e => e![1]!.GetValue<string>()).ToList();
        var numbers = queue!["queue_running"]!.AsArray().Concat(queue["queue_pending"]!.AsArray())
            .GroupBy(e => e![1]!.GetValue<string>())
            .ToDictionary(g => g.Key, g => g.Max(e => e![0]!.GetValue<double>()));
        return new QueueState(Ids(queue["queue_running"]), Ids(queue["queue_pending"]), numbers);
    }

    /// <summary>GET /history/{prompt_id}: {} while the prompt is unknown, queued or running.</summary>
    public async Task<JsonObject?> GetHistoryAsync(string promptId, CancellationToken cancel)
    {
        var history = await http.GetFromJsonAsync<JsonObject>($"history/{promptId}", cancel);
        return history?[promptId] as JsonObject;
    }

    /// <summary>POST /prompt with the job id as prompt_id. The status code decides between retry and dead letter.</summary>
    public async Task<(HttpStatusCode Status, string Body)> SubmitAsync(Job job, string clientId, CancellationToken cancel)
    {
        var request = new JsonObject { ["prompt"] = job.Workflow.DeepClone(), ["client_id"] = clientId, ["prompt_id"] = job.Id };
        using var response = await http.PostAsJsonAsync("prompt", request, cancel);
        return (response.StatusCode, await response.Content.ReadAsStringAsync(cancel));
    }

    /// <summary>POST /interrupt for this prompt only, POST /queue to remove it if it hadn't started, then wait
    /// until it has left the queue: a retry with the same prompt id must not receive this run's last messages.</summary>
    public async Task CancelPromptAsync(string promptId)
    {
        // Not the caller's token: this runs precisely when that token has fired.
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        using (await http.PostAsJsonAsync("interrupt", new JsonObject { ["prompt_id"] = promptId }, timeout.Token)) { }
        using (await http.PostAsJsonAsync("queue", new JsonObject { ["delete"] = new JsonArray(promptId) }, timeout.Token)) { }
        while ((await GetQueueAsync(timeout.Token)).Contains(promptId))
            await Task.Delay(50, timeout.Token);
    }

    public Task<byte[]> ViewAsync(JsonNode image, CancellationToken cancel)
    {
        string query = $"filename={Uri.EscapeDataString(image["filename"]!.GetValue<string>())}"
            + $"&subfolder={Uri.EscapeDataString(image["subfolder"]?.GetValue<string>() ?? "")}"
            + $"&type={Uri.EscapeDataString(image["type"]?.GetValue<string>() ?? "output")}";
        return http.GetByteArrayAsync($"view?{query}", cancel);
    }

    /// <summary>GET /ws?clientId=…: connect before posting, reconnect with the same id after a drop.</summary>
    public async Task<ClientWebSocket> ConnectAsync(string clientId, CancellationToken cancel)
    {
        var socket = new ClientWebSocket();
        var uri = new UriBuilder(BaseUri) { Scheme = BaseUri.Scheme == "https" ? "wss" : "ws", Path = "/ws", Query = $"clientId={clientId}" }.Uri;
        try
        {
            await socket.ConnectAsync(uri, cancel);
            return socket;
        }
        catch
        {
            socket.Dispose();
            throw;
        }
    }

    /// <summary>The next text message as JSON; binary messages (previews) are skipped.</summary>
    public static async Task<JsonNode> ReceiveJsonAsync(ClientWebSocket socket, CancellationToken cancel)
    {
        var buffer = new byte[16 * 1024];
        while (true)
        {
            using var message = new MemoryStream();
            WebSocketReceiveResult result;
            do
            {
                result = await socket.ReceiveAsync(buffer, cancel);
                if (result.MessageType == WebSocketMessageType.Close)
                    throw new WebSocketException(WebSocketError.ConnectionClosedPrematurely, "the server closed the WebSocket");
                message.Write(buffer, 0, result.Count);
            } while (!result.EndOfMessage);
            if (result.MessageType == WebSocketMessageType.Text)
                return JsonNode.Parse(Encoding.UTF8.GetString(message.ToArray()))!;
        }
    }

    public void Dispose() => http.Dispose();
}

/// <summary>Numbers: each prompt's position number, which also appears in its history entry (prompt[0]).</summary>
public sealed record QueueState(IReadOnlyList<string> Running, IReadOnlyList<string> Pending, IReadOnlyDictionary<string, double> Numbers)
{
    public bool Contains(string promptId) => Running.Contains(promptId) || Pending.Contains(promptId);
}

public sealed record GpuHealth(string Name, bool Healthy, string Device, long VramFree, int QueueLength, string? Error)
{
    public override string ToString() => Healthy
        ? $"{Name}: healthy, device {Device}, {VramFree / (1024 * 1024)} MiB free, {QueueLength} prompt(s) in its queue"
        : $"{Name}: unreachable ({Error})";
}
