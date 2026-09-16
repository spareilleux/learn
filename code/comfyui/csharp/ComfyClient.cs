using System.Net.Http.Json;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Learn.Comfy;

public static class ComfyClient
{
    // run <server> <api.json> [--set node.input=json]... [--out dir]
    public static async Task<int> Run(string[] args)
    {
        var server = new Uri(args[0]);
        var workflow = Workflow.Load(args[1]);
        string outDir = "out";
        for (int i = 2; i < args.Length; i += 2)
        {
            if (args[i] == "--out") { outDir = args[i + 1]; continue; }
            if (args[i] != "--set") throw new ArgumentException($"unknown option {args[i]}");
            // --set 3.seed=43 or --set 6.text="a lighthouse"
            string[] parts = args[i + 1].Split('=', 2);
            string[] target = parts[0].Split('.', 2);
            JsonNode? value;
            try { value = JsonNode.Parse(parts[1]); }
            catch (JsonException) { value = JsonValue.Create(parts[1]); }
            workflow[target[0]]!["inputs"]![target[1]] = value;
        }

        using var http = new HttpClient { BaseAddress = server, Timeout = TimeSpan.FromMinutes(10) };
        using var cancel = new CancellationTokenSource(TimeSpan.FromMinutes(20));

        // Connect first: the server only sends a prompt's events to the client id it was queued with,
        // and it doesn't replay the events a client missed.
        string clientId = Guid.NewGuid().ToString("N");
        using var socket = new ClientWebSocket();
        var wsUri = new UriBuilder(server) { Scheme = server.Scheme == "https" ? "wss" : "ws", Path = "/ws", Query = $"clientId={clientId}" }.Uri;
        await socket.ConnectAsync(wsUri, cancel.Token);

        // The client can choose the prompt id: a lowercase UUID.
        string promptId = Guid.NewGuid().ToString();
        var request = new JsonObject { ["prompt"] = workflow, ["client_id"] = clientId, ["prompt_id"] = promptId };
        using var response = await http.PostAsJsonAsync("prompt", request, cancel.Token);
        var body = JsonNode.Parse(await response.Content.ReadAsStringAsync(cancel.Token))!;
        Console.WriteLine($"POST /prompt: {(int)response.StatusCode}");
        if (!response.IsSuccessStatusCode)
        {
            Console.WriteLine($"error {body["error"]?["type"]}: {body["error"]?["message"]}");
            foreach (var (node, errors) in body["node_errors"]!.AsObject())
                foreach (var error in errors!["errors"]!.AsArray())
                    Console.WriteLine($"  node {node} ({errors["class_type"]}): {error!["type"]}: {error["details"]}");
            return 1;
        }

        string outcome = await FollowEvents(socket, promptId, cancel.Token);
        await socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "done", CancellationToken.None);
        if (outcome != "execution_success") return 1;

        // The history holds each output node's files; /view serves them.
        var history = await http.GetFromJsonAsync<JsonObject>($"history/{promptId}", cancel.Token);
        Directory.CreateDirectory(outDir);
        foreach (var (node, output) in history![promptId]!["outputs"]!.AsObject())
            foreach (var image in output!["images"]?.AsArray() ?? [])
            {
                string query = $"filename={Uri.EscapeDataString(image!["filename"]!.GetValue<string>())}"
                    + $"&subfolder={Uri.EscapeDataString(image["subfolder"]!.GetValue<string>())}"
                    + $"&type={image["type"]}";
                byte[] png = await http.GetByteArrayAsync($"view?{query}", cancel.Token);
                string path = Path.Combine(outDir, image["filename"]!.GetValue<string>());
                await File.WriteAllBytesAsync(path, png, cancel.Token);
                var pixels = Png.ReadPixels(Png.ReadChunks(path));
                Console.WriteLine($"GET /view node {node}: {image["subfolder"]}/{image["filename"]}, {pixels.Width} x {pixels.Height}, pixel SHA-256 {Png.PixelHash(pixels)}");
            }
        return 0;
    }

    static async Task<string> FollowEvents(ClientWebSocket socket, string promptId, CancellationToken cancel)
    {
        var buffer = new byte[64 * 1024];
        while (true)
        {
            // A message can arrive in several frames: read until EndOfMessage.
            using var message = new MemoryStream();
            WebSocketReceiveResult result;
            do
            {
                result = await socket.ReceiveAsync(buffer, cancel);
                if (result.MessageType == WebSocketMessageType.Close) throw new IOException("the server closed the WebSocket");
                message.Write(buffer, 0, result.Count);
            } while (!result.EndOfMessage);

            if (result.MessageType == WebSocketMessageType.Binary)
            {
                // Previews: a 4-byte big-endian event type, then the image (protocol.py).
                byte[] bytes = message.ToArray();
                Console.WriteLine($"binary message: type {bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3]}, {bytes.Length} bytes");
                continue;
            }

            var json = JsonNode.Parse(Encoding.UTF8.GetString(message.ToArray()))!;
            string type = json["type"]!.GetValue<string>();
            var data = json["data"]!;
            if (data["prompt_id"] is JsonNode id && id.GetValue<string>() != promptId) continue;

            switch (type)
            {
                case "status":
                    // The first status answers the connection and carries our session id;
                    // the next ones follow the queue, and how many arrive depends on timing.
                    if (data["sid"] is not null)
                        Console.WriteLine($"status: connected, queue_remaining {data["status"]!["exec_info"]!["queue_remaining"]}");
                    break;
                case "execution_start":
                    Console.WriteLine("execution_start");
                    break;
                case "execution_cached":
                    Console.WriteLine($"execution_cached: [{string.Join(", ", data["nodes"]!.AsArray())}]");
                    break;
                case "executing":
                    Console.WriteLine($"executing: node {data["node"]}");
                    break;
                case "progress":
                    Console.WriteLine($"progress: node {data["node"]}, {data["value"]}/{data["max"]}");
                    break;
                case "progress_state":
                    break; // the state of every node so far, sent again at each change
                case "executed":
                    var files = data["output"]?["images"]?.AsArray().Select(i => $"{i!["subfolder"]}/{i["filename"]}") ?? [];
                    Console.WriteLine($"executed: node {data["node"]}, {string.Join(", ", files)}");
                    break;
                case "execution_success":
                    Console.WriteLine("execution_success");
                    return type;
                case "execution_error":
                    Console.WriteLine($"execution_error: node {data["node_id"]} ({data["node_type"]}): {data["exception_message"]}");
                    return type;
                case "execution_interrupted":
                    Console.WriteLine($"execution_interrupted: node {data["node_id"]}");
                    return type;
                default:
                    Console.WriteLine($"{type}");
                    break;
            }
        }
    }

    // object-info <server> <class>...: the definitions a workflow's nodes need, for offline checks.
    public static async Task<int> SaveObjectInfo(Uri server, string[] classes)
    {
        using var http = new HttpClient { BaseAddress = server };
        var all = await http.GetFromJsonAsync<JsonObject>("object_info");
        var subset = new JsonObject();
        foreach (string name in classes)
            subset[name] = all![name]?.DeepClone() ?? throw new ArgumentException($"the server has no node {name}");
        Console.WriteLine(subset.ToJsonString(Workflow.Indented));
        Console.Error.WriteLine($"{classes.Length} of {all!.Count} node types");
        return 0;
    }
}
