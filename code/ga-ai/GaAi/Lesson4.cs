namespace GaAi;

using System.Net.Http.Json;
using System.Text.Json;
using System.Text.RegularExpressions;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Intents;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using static Report;

// Lesson 4: from a user message to the chatbot's answer, in the real host, without a model
public static class Lesson4
{
    public static readonly string[] Prompts =
    [
        "Are 0146 and 0137 z-related?",
        "Show me Cmaj7 voicings",
        "What is the relative minor of C major?",
        "Why does a ii-V-I sound resolved?",
    ];

    public static void Run()
    {
        EnsureIndex();
        using var host = new ChatHost();
        using var client = host.CreateClient();
        host.WaitForWarmup();
        foreach (var prompt in Prompts)
        {
            Title($"POST /api/chatbot/chat \"{prompt}\"");
            while (host.Logs.TryDequeue(out _)) { }
            var response = client.PostAsJsonAsync("/api/chatbot/chat", new { message = prompt }).GetAwaiter().GetResult();
            var body = response.Content.ReadAsStringAsync().GetAwaiter().GetResult();
            Line($"HTTP {(int)response.StatusCode}");
            if (response.IsSuccessStatusCode) PrintAnswer(body);
            PrintLogs(host);
        }

        Skills(host);
    }

    public static void EnsureIndex()
    {
        if (File.Exists(Lesson3.IndexPath)) return;
        Lesson3.WriteIndex(Lesson3.BuildCorpus(print: false), print: false);
    }

    static void PrintAnswer(string body)
    {
        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;
        Line($"agentId        {root.GetProperty("agentId").GetString()}");
        Line($"routingMethod  {root.GetProperty("routingMethod").GetString()}");
        Line($"confidence     {root.GetProperty("confidence").GetDouble():0.00}");
        if (root.GetProperty("grounding") is { ValueKind: JsonValueKind.Object } g)
        {
            Line($"grounding      {g.GetProperty("source").GetString()} {g.GetProperty("revision").GetString()} {g.GetProperty("queryType").GetString()}");
            if (g.TryGetProperty("facts", out var facts) && facts.ValueKind == JsonValueKind.Object)
                foreach (var f in facts.EnumerateObject())
                    Line($"  {f.Name,-12} {f.Value.GetString()}");
        }
        else
        {
            Line("grounding      (none)");
        }

        Line("answer:");
        foreach (var l in root.GetProperty("naturalLanguageAnswer").GetString()!.ReplaceLineEndings("\n").Split('\n'))
            Line($"  | {l}");
        Line("trace:");
        foreach (var step in root.GetProperty("trace").GetProperty("steps").EnumerateArray())
            Line($"  {step.GetProperty("name").GetString(),-24} {step.GetProperty("status").GetString()}");
    }

    // Warnings and errors, with the exception type and the innermost GA frame, without
    // messages or paths that differ between operating systems
    static void PrintLogs(ChatHost host)
    {
        var lines = host.Logs
            .Select(l => $"{l.Level} {l.Category.Split('.').Last()}: {l.Message}"
                         + (l.Exception is null ? "" : $" [{l.Exception.GetType().Name}{GaFrame(l.Exception)}]"))
            .Distinct()
            .Order(StringComparer.Ordinal)
            .ToList();
        if (lines.Count == 0) return;
        Line("logged:");
        foreach (var l in lines) Line($"  {l}");
    }

    static string GaFrame(Exception e)
    {
        var frame = (e.StackTrace ?? "").Split('\n')
            .Select(f => f.Trim())
            .FirstOrDefault(f => f.StartsWith("at GA.") || f.StartsWith("at GaChatbot."));
        if (frame is null) return "";
        var m = Regex.Match(frame, @"^at (?<method>[^(]+)\(.*?\)(?: in .*[\\/](?<file>[^\\/]+):line (?<line>\d+))?");
        var method = string.Join('.', m.Groups["method"].Value.Trim().Split('.').TakeLast(2));
        return m.Groups["file"].Success ? $" at {method}, {m.Groups["file"].Value}:{m.Groups["line"].Value}" : $" at {method}";
    }

    // The skills behind the intents, called without the router
    static void Skills(ChatHost host)
    {
        using var scope = host.Services.CreateScope();
        var skills = scope.ServiceProvider.GetServices<IOrchestratorSkill>().ToList();
        Title("IOrchestratorSkill.CanHandle for each prompt (the keyword path the orchestrator no longer calls)");
        foreach (var prompt in Prompts)
        {
            var matching = skills.Where(s => s.CanHandle(prompt)).Select(s => s.Name).ToList();
            Line($"{prompt,-40} {(matching.Count == 0 ? "(none)" : string.Join(", ", matching))}");
        }

        var intent = scope.ServiceProvider.GetServices<IIntent>().First(i => i.Id == "skill.relativekey");
        Title($"The {intent.Id} intent, called directly with \"{Prompts[2]}\"");
        var result = intent.ExecuteAsync(Prompts[2]).GetAwaiter().GetResult();
        Line($"confidence     {result.Confidence:0.00}");
        foreach (var l in result.Answer.ReplaceLineEndings("\n").Split('\n'))
            Line($"  | {l}");
    }
}
