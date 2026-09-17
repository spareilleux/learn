using System.Collections.Concurrent;
using System.IO.Compression;
using System.Net;
using System.Net.WebSockets;
using System.Reflection;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Threading.Channels;
using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Hosting.Server.Features;

namespace Learn.Comfy.Fake;

/// <summary>
/// A fake ComfyUI for tests: the routes and WebSocket messages a worker uses, with the shapes recorded from a real
/// ComfyUI 0.36.0 (data/recorded), one prompt at a time like the real server, and no model and no GPU.
/// What each POST /prompt does comes from a script, in the order the prompts arrive:
///   ok       runs every node, "saves" an image for each SaveImage node, then execution_success
///   500      answers 500 as aiohttp does when a handler raises
///   invalid  answers 400 with prompt_outputs_failed_validation and node_errors
///   error    execution_error at the second node (IndexError, as recorded)
///   oom      execution_error at the second node, with the exception type and tips of an out-of-memory error
///   drop     aborts the client's WebSocket at the first node, then finishes normally
///   hang     stops at the second node until POST /interrupt
///   slow     like ok, ten times slower
/// When the script is exhausted, every prompt is ok. --busy N adds N prompts from another client to /queue,
/// which never run: they only make the server look loaded to a scheduler.
/// </summary>
public sealed class FakeComfyServer : IAsyncDisposable
{
    readonly WebApplication app;
    readonly FakeOptions options;
    readonly Lock gate = new();
    readonly Queue<string> script;
    readonly List<Prompt> pending = [];
    readonly Dictionary<string, JsonObject> history = [];
    readonly ConcurrentDictionary<string, Client> clients = new();
    readonly Channel<Prompt> work = Channel.CreateUnbounded<Prompt>();
    readonly Dictionary<string, int> fileCounters = [];
    readonly CancellationTokenSource stopping = new();
    readonly Task executor;
    Prompt? running;
    string? lastNode;
    int number;

    public FakeStats Stats { get; } = new();
    public Uri BaseUri { get; private set; } = null!;

    FakeComfyServer(WebApplication app, FakeOptions options)
    {
        this.app = app;
        this.options = options;
        script = new Queue<string>(options.Script);
        executor = Task.Run(ExecuteAllAsync);
    }

    public static async Task<FakeComfyServer> StartAsync(FakeOptions options, int port = 0)
    {
        var builder = WebApplication.CreateSlimBuilder();
        builder.Logging.ClearProviders();
        builder.WebHost.UseKestrel(k => k.Listen(IPAddress.Loopback, port));
        var app = builder.Build();
        var server = new FakeComfyServer(app, options);
        server.MapRoutes();
        await app.StartAsync();
        string address = app.Services.GetRequiredService<IServer>().Features.Get<IServerAddressesFeature>()!.Addresses.First();
        server.BaseUri = new Uri(address.Replace("[::1]", "localhost") + "/");
        return server;
    }

    void MapRoutes()
    {
        app.UseWebSockets();
        app.MapGet("/system_stats", () => Json(Recorded("system_stats")["body"]!));
        app.MapGet("/queue", QueueState);
        app.MapGet("/history/{id}", (string id) =>
        {
            lock (gate) return Json(history.TryGetValue(id, out var entry) ? new JsonObject { [id] = entry.DeepClone() } : new JsonObject());
        });
        // Cast to a Func: as a RequestDelegate, the IResult they return would be discarded (analyzer ASP0016).
        app.MapPost("/prompt", (Func<HttpContext, Task<IResult>>)PostPrompt);
        app.MapPost("/interrupt", (Func<HttpContext, Task<IResult>>)PostInterrupt);
        app.MapPost("/queue", (Func<HttpContext, Task<IResult>>)PostQueue);
        app.MapPost("/free", () => Results.Ok());
        app.MapGet("/view", (string filename) => Results.Bytes(Png(64, 48), "image/png"));
        app.MapGet("/fake/stats", () => Json(Stats.ToJson()));
        app.Map("/ws", WebSocketAsync);
    }

    async Task<IResult> PostPrompt(HttpContext context)
    {
        JsonObject body;
        try
        {
            body = (await JsonNode.ParseAsync(context.Request.Body))!.AsObject();
        }
        catch (JsonException)
        {
            var recorded = Recorded("server_error");
            return Results.Text(recorded["body"]!.GetValue<string>(), "text/plain", statusCode: 500);
        }
        string id = body["prompt_id"]?.GetValue<string>() ?? Guid.NewGuid().ToString();
        if (!Guid.TryParse(id, out var guid) || guid.ToString() != id)
            return Json(Recorded("validation_error")["invalid_prompt_id"]!["body"]!, 400);

        string behaviour;
        lock (gate) behaviour = script.TryDequeue(out var next) ? next : "ok";
        Stats.Posted.AddOrUpdate(id, 1, (_, n) => n + 1);
        switch (behaviour)
        {
            case "500":
                return Results.Text(Recorded("server_error")["body"]!.GetValue<string>(), "text/plain", statusCode: 500);
            case "invalid":
                return Json(Recorded("validation_error")["post_prompt"]!["body"]!, 400);
        }

        var prompt = new Prompt(Interlocked.Increment(ref number) - 1, id, body["prompt"]!.AsObject(), body["client_id"]?.GetValue<string>() ?? "", behaviour);
        lock (gate) pending.Add(prompt);
        await work.Writer.WriteAsync(prompt);
        // The real server sends two status messages when a prompt is queued (data/recorded/success.json).
        await BroadcastStatusAsync();
        await BroadcastStatusAsync();
        return Json(new JsonObject { ["prompt_id"] = id, ["number"] = prompt.Number, ["node_errors"] = new JsonObject() });
    }

    async Task<IResult> PostInterrupt(HttpContext context)
    {
        string? id = null;
        try
        {
            id = (await JsonNode.ParseAsync(context.Request.Body))?["prompt_id"]?.GetValue<string>();
        }
        catch (JsonException)
        {
        }
        lock (gate)
        {
            Stats.Interrupts.Enqueue(id ?? "(global)");
            // Like server.py: with a prompt id, only if that prompt is the one running.
            if (running is not null && (id is null || running.Id == id)) running.Interrupt.TrySetResult();
        }
        return Results.Ok();
    }

    async Task<IResult> PostQueue(HttpContext context)
    {
        var body = (await JsonNode.ParseAsync(context.Request.Body))!;
        lock (gate)
            foreach (var id in body["delete"]?.AsArray() ?? [])
                foreach (var prompt in pending.Where(p => p.Id == id!.GetValue<string>()).ToList())
                {
                    pending.Remove(prompt);
                    prompt.Deleted = true;
                }
        return Results.Ok();
    }

    IResult QueueState()
    {
        JsonArray Entry(Prompt p) => new(p.Number, p.Id, p.Workflow.DeepClone(), new JsonObject { ["client_id"] = p.ClientId }, new JsonArray());
        lock (gate)
        {
            var pendingEntries = new JsonArray(pending.Where(p => p != running).Select(p => (JsonNode)Entry(p)).ToArray());
            for (int i = 0; i < options.Busy; i++)
                pendingEntries.Add(new JsonArray(1000 + i, $"{i:D8}-ffff-4000-8000-000000000000", new JsonObject(), new JsonObject { ["client_id"] = "someone-else" }, new JsonArray()));
            return Json(new JsonObject
            {
                ["queue_running"] = running is null ? new JsonArray() : new JsonArray(Entry(running)),
                ["queue_pending"] = pendingEntries,
            });
        }
    }

    async Task WebSocketAsync(HttpContext context)
    {
        if (!context.WebSockets.IsWebSocketRequest)
        {
            context.Response.StatusCode = 400;
            return;
        }
        using var socket = await context.WebSockets.AcceptWebSocketAsync();
        string sid = context.Request.Query["clientId"].FirstOrDefault() is { Length: > 0 } given ? given : Guid.NewGuid().ToString("N");
        var client = new Client(socket, context);
        clients[sid] = client;
        Stats.Connections.AddOrUpdate(sid, 1, (_, n) => n + 1);
        try
        {
            await client.SendAsync("status", new JsonObject { ["status"] = QueueInfo(), ["sid"] = sid });
            string? node;
            lock (gate) node = running?.ClientId == sid ? lastNode : null;
            if (node is not null) await client.SendAsync("executing", new JsonObject { ["node"] = node });
            var buffer = new byte[4096];
            while (socket.State == WebSocketState.Open)
            {
                var result = await socket.ReceiveAsync(buffer, stopping.Token);
                if (result.MessageType == WebSocketMessageType.Close) break;
            }
        }
        catch (Exception e) when (e is WebSocketException or OperationCanceledException or IOException)
        {
        }
        finally
        {
            clients.TryRemove(new KeyValuePair<string, Client>(sid, client));
        }
    }

    async Task ExecuteAllAsync()
    {
        try
        {
            await foreach (var prompt in work.Reader.ReadAllAsync(stopping.Token))
            {
                lock (gate)
                {
                    if (prompt.Deleted) continue;
                    running = prompt;
                }
                await ExecuteAsync(prompt);
                lock (gate)
                {
                    pending.Remove(prompt);
                    running = null;
                    lastNode = null;
                }
                await BroadcastStatusAsync();
                await SendAsync(prompt.ClientId, "executing", new JsonObject { ["node"] = null, ["prompt_id"] = prompt.Id });
            }
        }
        catch (OperationCanceledException)
        {
        }
    }

    async Task ExecuteAsync(Prompt prompt)
    {
        Stats.Executed.AddOrUpdate(prompt.Id, 1, (_, n) => n + 1);
        var lifecycle = new JsonArray();
        async Task Lifecycle(string type, JsonObject data, bool broadcast = false)
        {
            data["timestamp"] = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
            lifecycle.Add(new JsonArray(type, data.DeepClone()));
            if (broadcast) await BroadcastAsync(type, data);
            else await SendAsync(prompt.ClientId, type, data);
        }

        await Lifecycle("execution_start", new JsonObject { ["prompt_id"] = prompt.Id });
        await Lifecycle("execution_cached", new JsonObject { ["nodes"] = new JsonArray(), ["prompt_id"] = prompt.Id });
        var outputs = new JsonObject();
        var executed = new JsonArray();
        var nodes = prompt.Workflow.Select(n => n.Key).OrderBy(k => int.TryParse(k, out int i) ? i : int.MaxValue).ThenBy(k => k).ToList();
        int step = options.StepMs * (prompt.Behaviour == "slow" ? 10 : 1);
        string status = "success";

        for (int index = 0; index < nodes.Count; index++)
        {
            string node = nodes[index];
            string classType = prompt.Workflow[node]!["class_type"]!.GetValue<string>();
            lock (gate) lastNode = node;
            await SendAsync(prompt.ClientId, "progress_state", new JsonObject
            {
                ["prompt_id"] = prompt.Id,
                ["nodes"] = new JsonObject { [node] = new JsonObject { ["value"] = 0.0, ["max"] = 1.0, ["state"] = "running", ["node_id"] = node, ["prompt_id"] = prompt.Id, ["display_node_id"] = node, ["parent_node_id"] = null, ["real_node_id"] = node } },
            });
            await SendAsync(prompt.ClientId, "executing", new JsonObject { ["node"] = node, ["display_node"] = node, ["prompt_id"] = prompt.Id });

            if (prompt.Behaviour == "drop" && index == 0 && clients.TryGetValue(prompt.ClientId, out var victim))
            {
                Stats.Drops.Enqueue(prompt.Id);
                victim.Abort();
            }

            bool interrupted;
            if (prompt.Behaviour == "hang" && index == 1)
                interrupted = await Task.WhenAny(prompt.Interrupt.Task, Task.Delay(Timeout.Infinite, stopping.Token)) == prompt.Interrupt.Task;
            else
                interrupted = await Task.WhenAny(prompt.Interrupt.Task, Task.Delay(step)) == prompt.Interrupt.Task;
            if (interrupted)
            {
                await Lifecycle("execution_interrupted", new JsonObject { ["prompt_id"] = prompt.Id, ["node_id"] = node, ["node_type"] = classType, ["executed"] = executed.DeepClone() }, broadcast: true);
                status = "error";
                break;
            }

            if (prompt.Behaviour is "error" or "oom" && index == 1)
            {
                var data = Recorded("execution_error")["messages"]!.AsArray().First(m => m!["type"]?.GetValue<string>() == "execution_error")!["data"]!.DeepClone().AsObject();
                data.Remove("timestamp");
                data["prompt_id"] = prompt.Id;
                data["node_id"] = node;
                data["node_type"] = classType;
                data["executed"] = executed.DeepClone();
                if (prompt.Behaviour == "oom")
                {
                    // Not recorded (it needs a GPU to run out of): the type torch raises, and the tips execution.py adds.
                    data["exception_type"] = "torch.OutOfMemoryError";
                    data["exception_message"] = "Allocation on device \nThis error means you ran out of memory on your GPU.\n\nTIPS: If the workflow worked before you might have accidentally set the batch_size to a large number.";
                }
                await Lifecycle("execution_error", data);
                status = "error";
                break;
            }

            if (classType == "SaveImage")
            {
                string prefix = prompt.Workflow[node]!["inputs"]?["filename_prefix"]?.GetValue<string>() ?? "ComfyUI";
                string subfolder = prefix.Contains('/') ? prefix[..prefix.LastIndexOf('/')] : "";
                string name = prefix[(prefix.LastIndexOf('/') + 1)..];
                int counter;
                lock (gate) counter = fileCounters[prefix] = fileCounters.GetValueOrDefault(prefix) + 1;
                var images = new JsonArray(new JsonObject { ["filename"] = $"{name}_{counter:D5}_.png", ["subfolder"] = subfolder, ["type"] = "output" });
                outputs[node] = new JsonObject { ["images"] = images };
                await SendAsync(prompt.ClientId, "executed", new JsonObject { ["node"] = node, ["display_node"] = node, ["output"] = new JsonObject { ["images"] = images.DeepClone() }, ["prompt_id"] = prompt.Id });
            }
            executed.Add(node);
        }

        if (status == "success")
            await Lifecycle("execution_success", new JsonObject { ["prompt_id"] = prompt.Id });
        // The real server sends execution_success before it writes the history (execution.py, then main.py's
        // task_done): a client that reads /history at once can find nothing yet. The fake leaves the same gap.
        await Task.Delay(5);
        lock (gate)
            history[prompt.Id] = new JsonObject
            {
                ["prompt"] = new JsonArray(prompt.Number, prompt.Id, prompt.Workflow.DeepClone(), new JsonObject { ["client_id"] = prompt.ClientId }, new JsonArray()),
                ["outputs"] = status == "success" ? outputs : new JsonObject(),
                ["status"] = new JsonObject { ["status_str"] = status, ["completed"] = status == "success", ["messages"] = lifecycle },
                ["meta"] = new JsonObject(),
            };
    }

    JsonObject QueueInfo()
    {
        int remaining;
        lock (gate) remaining = pending.Count + options.Busy;
        return new JsonObject { ["exec_info"] = new JsonObject { ["queue_remaining"] = remaining } };
    }

    Task BroadcastStatusAsync() => BroadcastAsync("status", new JsonObject { ["status"] = QueueInfo() });

    async Task BroadcastAsync(string type, JsonObject data)
    {
        foreach (var client in clients.Values) await client.SendAsync(type, (JsonObject)data.DeepClone());
    }

    async Task SendAsync(string clientId, string type, JsonObject data)
    {
        // Sent only to the prompt's client id, and lost if it isn't connected: the server keeps no backlog.
        if (clients.TryGetValue(clientId, out var client)) await client.SendAsync(type, data);
    }

    static readonly ConcurrentDictionary<string, JsonObject> recorded = new();

    static JsonObject Recorded(string name) => recorded.GetOrAdd(name, n =>
    {
        using var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream($"recorded.{n}.json")
            ?? throw new InvalidOperationException($"no recorded {n}.json");
        return JsonNode.Parse(stream)!.AsObject();
    });

    static IResult Json(JsonNode node, int status = 200) => Results.Text(node.ToJsonString(), "application/json", Encoding.UTF8, status);

    /// <summary>A real PNG of one gray color: signature, IHDR, one zlib IDAT, IEND.</summary>
    static byte[] Png(int width, int height)
    {
        using var png = new MemoryStream();
        png.Write([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
        void Chunk(string type, byte[] data)
        {
            Span<byte> length = stackalloc byte[4];
            System.Buffers.Binary.BinaryPrimitives.WriteInt32BigEndian(length, data.Length);
            png.Write(length);
            byte[] typed = [.. Encoding.ASCII.GetBytes(type), .. data];
            png.Write(typed);
            System.Buffers.Binary.BinaryPrimitives.WriteUInt32BigEndian(length, Crc32(typed));
            png.Write(length);
        }
        byte[] header = new byte[13];
        System.Buffers.Binary.BinaryPrimitives.WriteInt32BigEndian(header, width);
        System.Buffers.Binary.BinaryPrimitives.WriteInt32BigEndian(header.AsSpan(4), height);
        header[8] = 8; // bit depth
        header[9] = 0; // grayscale
        Chunk("IHDR", header);
        using var raw = new MemoryStream();
        using (var zlib = new ZLibStream(raw, CompressionLevel.SmallestSize, leaveOpen: true))
            for (int y = 0; y < height; y++)
            {
                zlib.WriteByte(0); // filter: none
                for (int x = 0; x < width; x++) zlib.WriteByte(0x80);
            }
        Chunk("IDAT", raw.ToArray());
        Chunk("IEND", []);
        return png.ToArray();
    }

    static uint Crc32(byte[] data)
    {
        uint crc = 0xFFFFFFFF;
        foreach (byte b in data)
        {
            crc ^= b;
            for (int k = 0; k < 8; k++) crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
        }
        return ~crc;
    }

    public async ValueTask DisposeAsync()
    {
        stopping.Cancel();
        work.Writer.TryComplete();
        foreach (var client in clients.Values) client.Abort();
        await app.StopAsync();
        try { await executor; } catch (OperationCanceledException) { }
        await app.DisposeAsync();
    }

    sealed class Prompt(int number, string id, JsonObject workflow, string clientId, string behaviour)
    {
        public int Number => number;
        public string Id => id;
        public JsonObject Workflow => workflow;
        public string ClientId => clientId;
        public string Behaviour => behaviour;
        public bool Deleted { get; set; }
        public TaskCompletionSource Interrupt { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
    }

    sealed class Client(WebSocket socket, HttpContext context)
    {
        readonly SemaphoreSlim sending = new(1, 1);

        public async Task SendAsync(string type, JsonObject data)
        {
            byte[] bytes = Encoding.UTF8.GetBytes(new JsonObject { ["type"] = type, ["data"] = data }.ToJsonString());
            await sending.WaitAsync();
            try
            {
                if (socket.State == WebSocketState.Open)
                    await socket.SendAsync(bytes, WebSocketMessageType.Text, endOfMessage: true, CancellationToken.None);
            }
            catch (Exception e) when (e is WebSocketException or IOException or ObjectDisposedException)
            {
            }
            finally
            {
                sending.Release();
            }
        }

        /// <summary>The connection dies without a close handshake, as when a proxy or the network drops it.</summary>
        public void Abort()
        {
            socket.Abort();
            context.Abort();
        }
    }
}

public sealed record FakeOptions
{
    public string[] Script { get; init; } = [];
    public int StepMs { get; init; } = 20;
    public int Busy { get; init; }
}

public sealed class FakeStats
{
    public ConcurrentDictionary<string, int> Posted { get; } = new();
    public ConcurrentDictionary<string, int> Executed { get; } = new();
    public ConcurrentDictionary<string, int> Connections { get; } = new();
    public ConcurrentQueue<string> Interrupts { get; } = new();
    public ConcurrentQueue<string> Drops { get; } = new();

    public JsonObject ToJson()
    {
        static JsonObject Counts(ConcurrentDictionary<string, int> d) => new(d.OrderBy(p => p.Key, StringComparer.Ordinal).Select(p => KeyValuePair.Create(p.Key, (JsonNode?)p.Value)));
        return new JsonObject
        {
            ["posted"] = Counts(Posted),
            ["executed"] = Counts(Executed),
            ["interrupts"] = new JsonArray(Interrupts.Select(i => (JsonNode)i).ToArray()),
            ["drops"] = new JsonArray(Drops.Select(i => (JsonNode)i).ToArray()),
        };
    }
}
