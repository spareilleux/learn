using System.Diagnostics;
using System.Text.Json;
using ModelContextProtocol.Client;
using ModelContextProtocol.Protocol;

// UTF-8 on every OS: the Windows console would print the em dash of a title as a hyphen
Console.OutputEncoding = System.Text.Encoding.UTF8;

// check <server.dll> <docs>: starts the server the way Claude Code and Codex do, over stdio, and prints what an agent would see
// raw <server.dll> <docs> <session.jsonl>: sends each JSON-RPC line and prints the reply, one request at a time
if (args[0] == "raw")
{
    await Raw(args[1], args[2], args[3]);
    return;
}
var server = args[0];
var docs = args[1];

var transport = new StdioClientTransport(new StdioClientTransportOptions
{
    Name = "learn",
    Command = "dotnet",
    Arguments = [server, "--docs", docs],
});
await using var client = await McpClient.CreateAsync(transport);

Console.WriteLine($"server: {client.ServerInfo.Name}, protocol {client.NegotiatedProtocolVersion}");

Console.WriteLine("== tools/list");
foreach (var tool in (await client.ListToolsAsync()).OrderBy(tool => tool.Name, StringComparer.Ordinal))
{
    Console.WriteLine($"{tool.Name}: {tool.Description}");
    Console.WriteLine($"  input schema: {JsonSerializer.Serialize(tool.JsonSchema)}");
}

Console.WriteLine("== tools/call");
await Call("scale_notes", new() { ["root"] = "F" });
await Call("scale_notes", new() { ["root"] = "F#", ["mode"] = "minor" });
await Call("scale_notes", new() { ["root"] = "Eb", ["mode"] = "dorian" });
await Call("scale_notes", new() { ["root"] = "H" });
await Call("scale_notes", new() { ["root"] = "G#", ["mode"] = "locrian" });
await Call("scale_notes", new() { ["root"] = "C", ["mode"] = "blues" });
await Call("course_outline", new() { ["course"] = "duckdb" });
await Call("course_outline", new() { ["course"] = "../.." });
await Call("does_not_exist", new());

async Task Call(string name, Dictionary<string, object?> arguments)
{
    Console.WriteLine($"{name} {JsonSerializer.Serialize(arguments)}");
    try
    {
        var result = await client.CallToolAsync(name, arguments);
        var text = string.Join("", result.Content.OfType<TextContentBlock>().Select(block => block.Text));
        Console.WriteLine($"  isError: {result.IsError ?? false}");
        Console.WriteLine("  " + text.ReplaceLineEndings(Environment.NewLine + "  "));
    }
    catch (Exception e)
    {
        Console.WriteLine($"  {e.GetType().Name}: {e.Message}");
    }
}

static async Task Raw(string server, string docs, string session)
{
    var start = new ProcessStartInfo("dotnet")
    {
        RedirectStandardInput = true,
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        StandardOutputEncoding = System.Text.Encoding.UTF8,
    };
    start.ArgumentList.Add(server);
    start.ArgumentList.Add("--docs");
    start.ArgumentList.Add(docs);
    using var process = Process.Start(start)!;
    // The logs on stderr are not part of the protocol: read them so the pipe never fills, and drop them
    _ = process.StandardError.ReadToEndAsync();
    process.StandardInput.NewLine = "\n";

    foreach (var line in File.ReadLines(session).Where(line => line.Length > 0))
    {
        Console.WriteLine($"--> {line}");
        await process.StandardInput.WriteLineAsync(line);
        await process.StandardInput.FlushAsync();
        // A notification has no id, and gets no reply
        if (JsonDocument.Parse(line).RootElement.TryGetProperty("id", out _))
        {
            Console.WriteLine($"<-- {await process.StandardOutput.ReadLineAsync()}");
        }
    }
    // Closing stdin is how a stdio client asks the server to stop
    process.StandardInput.Close();
    await process.WaitForExitAsync();
    Console.WriteLine($"exit code: {process.ExitCode}");
}
