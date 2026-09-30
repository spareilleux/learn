namespace GaAi;

using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using GA.Business.Core.Orchestration.Helpers;
using GA.Business.ML.Agents.Skills;
using Microsoft.Extensions.Logging.Abstractions;
using static Report;

// Lesson 6: the chatbot's answer on the wire. The program streams answers from the real host as
// server-sent events, reads them back with a reader written from the HTML standard, and checks
// that the text a client puts together is the text GA computed
public static class Lesson6
{
    public const string Voicings = "Show me Cmaj7 voicings";
    public const string Arpeggios = "which arpeggio fits Am F C G";

    public static void Run()
    {
        Lesson4.EnsureIndex();
        using var host = new ChatHost();
        using var client = host.CreateClient();
        host.WaitForWarmup();
        Stream(client);
        Failure(client);
        // GA builds its answers with AppendLine, so their line breaks are CRLF on Windows and LF
        // elsewhere; the lesson compares them with LF line breaks, the same on every system
        var answer = new ImprovisationSkill(NullLogger<ImprovisationSkill>.Instance, new NoExtractor())
            .ExecuteAsync(Arpeggios).GetAwaiter().GetResult().Result.ReplaceLineEndings("\n");
        Sentences(answer);
        Pairs(answer);
    }

    // ---- The real host ----

    static (int Status, string Body) Post(HttpClient client, string path, string message)
    {
        var response = client.PostAsJsonAsync(path, new { message }).GetAwaiter().GetResult();
        return ((int)response.StatusCode, response.Content.ReadAsStringAsync().GetAwaiter().GetResult());
    }

    static void Stream(HttpClient client)
    {
        var (status, body) = Post(client, "/api/chatbot/chat/stream", Voicings);
        Title($"POST /api/chatbot/chat/stream \"{Voicings}\"");
        Line($"HTTP {status}");
        foreach (var line in body.Split('\n')[..^1])
            // the routing event carries the trace, with timings that change on every run
            Line(line.Length > 100 ? $"  | {line[..line.LastIndexOf(',', 60)]},…" : $"  | {line}".TrimEnd());

        var events = Standard(body);
        Title("The same stream, read as the HTML standard says");
        for (var i = 0; i < events.Count; i++)
            Line($"event {i + 1}  {Kind(events[i]),-8} {events[i].Split('\n').Length} line(s)");

        var (chatStatus, chatBody) = Post(client, "/api/chatbot/chat", Voicings);
        using var doc = JsonDocument.Parse(chatBody);
        var answer = doc.RootElement.GetProperty("naturalLanguageAnswer").GetString()!.ReplaceLineEndings("\n");
        var text = string.Concat(events.Where(e => Kind(e) == "text"));
        var written = string.Concat(SseChunker.SplitIntoChunks(answer).Select(GaChatbotEvent)) + "data: [DONE]\n\n";
        Line();
        Line($"POST /api/chatbot/chat               HTTP {chatStatus}, answer of {answer.Length} characters");
        Line($"text events joined, equal to it      {(text == answer ? "yes" : "no")} (line breaks as LF)");
        Line($"the course's copy of the host's writer gives the host's bytes  {(body.EndsWith(written, StringComparison.Ordinal) ? "yes" : "no")}");
    }

    static void Failure(HttpClient client)
    {
        var (chatStatus, _) = Post(client, "/api/chatbot/chat", Arpeggios);
        var (status, body) = Post(client, "/api/chatbot/chat/stream", Arpeggios);
        Title($"\"{Arpeggios}\" with no model server");
        Line($"POST /api/chatbot/chat         HTTP {chatStatus}");
        Line($"POST /api/chatbot/chat/stream  HTTP {status}");
        foreach (var line in body.Split('\n')[..^1]) Line($"  | {line}".TrimEnd());
        Line();
        int[] w = [22];
        Row(w, "reader", "what the user gets");
        Row(w, "HTML standard", string.Join(" | ", Standard(body)));
        Row(w, "GaChatbot page", Page(body));
        Row(w, "ga-client chatService", ChatService(body));
    }

    // ---- Sentences ----

    // The expression #743 put in SseChunker on 2026-09-28: split after the whitespace that
    // follows a sentence, not on it, so the chunks keep every character
    static readonly Regex After743 = new(@"(?<=[.!?]\s+)(?=\S)");

    static IEnumerable<string> ChunksAfter743(string text) => After743.Split(text);

    static void Sentences(string answer)
    {
        var chunks = SseChunker.SplitIntoChunks(answer).ToList();
        Title("SseChunker.SplitIntoChunks on the improvisation skill's answer (GA at a826864)");
        Line($"answer: {Lines(answer)} lines of text, {Breaks(answer)} line breaks, {answer.Length} characters");
        for (var i = 0; i < chunks.Count; i++) Line($"chunk {i + 1}  {Show(chunks[i])}");
        var joined = string.Concat(chunks);
        Line($"joined: {joined.Length} characters, {Compare(answer, joined)}");
        Line("joined, as the page renders it:");
        foreach (var line in joined.Split('\n')) Line($"  | {line}".TrimEnd());

        var fixedChunks = ChunksAfter743(answer).ToList();
        Title($"The same answer split by #743's expression {After743}");
        for (var i = 0; i < fixedChunks.Count; i++) Line($"chunk {i + 1}  {Show(fixedChunks[i])}");
        Line($"joined: {string.Concat(fixedChunks).Length} characters, {Compare(answer, string.Concat(fixedChunks))}");
    }

    // ---- Writers and readers ----

    // GaChatbot.Api's WriteSseLineAsync (ChatbotController.cs lines 449-467 at a826864): every
    // line of the chunk gets its own "data: " prefix, and a blank line ends the event
    static string GaChatbotEvent(string data) =>
        string.Concat(data.Replace("\r", "").Split('\n').Select(l => $"data: {l}\n")) + "\n";

    // GaApi's WriteSseLineAsync (ChatbotController.cs lines 318-322 at a826864): the chunk as is
    static string GaApiEvent(string data) => $"data: {data}\n\n";

    // Server-sent events as the HTML standard reads them: lines end at CRLF, LF or CR; a "data"
    // line adds its value and a LF to the buffer; a blank line dispatches the buffer without its
    // last LF; a line with no colon is a field with an empty value; other fields are ignored here;
    // an event that no blank line ends is discarded
    static List<string> Standard(string stream)
    {
        var events = new List<string>();
        var data = new StringBuilder();
        foreach (var line in Regex.Split(stream, "\r\n|\r|\n"))
        {
            if (line.Length == 0)
            {
                if (data.Length > 0) events.Add(data.ToString(0, data.Length - 1));
                data.Clear();
                continue;
            }
            if (line[0] == ':') continue;
            var colon = line.IndexOf(':');
            var field = colon < 0 ? line : line[..colon];
            var value = colon < 0 ? "" : line[(colon + 1)..];
            if (value.StartsWith(' ')) value = value[1..];
            if (field == "data") data.Append(value).Append('\n');
        }
        return events;
    }

    static string Kind(string data) =>
        data == "[DONE]" ? "[DONE]"
        : data.StartsWith("{\"type\":\"routing\"", StringComparison.Ordinal) ? "routing"
        : data.StartsWith("{\"error\"", StringComparison.Ordinal) ? "error"
        : "text";

    // GaChatbot.Api's page, wwwroot/index.html lines 759-790 at a826864, ported: an event ends
    // at "\n\n", its "data: " lines are joined with "\n", a first JSON event whose type is
    // "routing" is the trace, "[DONE]" ends the answer, and every other event is appended to it
    static string Page(string stream)
    {
        var answer = new StringBuilder();
        var routing = false;
        var buffer = stream;
        int sep;
        while ((sep = buffer.IndexOf("\n\n", StringComparison.Ordinal)) >= 0)
        {
            var rawEvent = buffer[..sep];
            buffer = buffer[(sep + 2)..];
            var dataLines = rawEvent.Split('\n').Where(l => l.StartsWith("data: ", StringComparison.Ordinal)).Select(l => l[6..]).ToList();
            if (dataLines.Count == 0) continue;
            var data = string.Join('\n', dataLines);
            if (data == "[DONE]") break;
            if (!routing && data.StartsWith('{') && data.Contains("\"type\""))
            {
                try
                {
                    using var doc = JsonDocument.Parse(data);
                    if (doc.RootElement.TryGetProperty("type", out var type) && type.GetString() == "routing")
                    {
                        routing = true;
                        continue;
                    }
                }
                catch (JsonException) { }
            }
            answer.Append(data);
        }
        return answer.ToString();
    }

    // ga-client's parseSseBuffer and sendChatMessageStream, src/services/chatService.ts lines 29-77
    // and 125-162 at a826864, ported: an event ends at "\n\n", only its first "data:" line counts,
    // trimmed; "[DONE]" ends the stream, a JSON payload with "error" throws, other JSON is skipped
    static string ChatService(string stream)
    {
        var response = new StringBuilder();
        var events = stream.Split("\n\n");
        foreach (var e in events[..^1])
        {
            var dataLine = e.Split('\n').FirstOrDefault(l => l.StartsWith("data:", StringComparison.Ordinal));
            if (dataLine is null) continue;
            var payload = dataLine[5..].Trim();
            if (payload.Length == 0) continue;
            if (payload == "[DONE]") break;
            if (payload.StartsWith('{'))
            {
                using var doc = JsonDocument.Parse(payload);
                if (doc.RootElement.TryGetProperty("error", out var error))
                    return $"(throws) {error.GetString()}";
                continue;
            }
            response.Append(payload);
        }
        return response.ToString();
    }

    static void Pairs(string answer)
    {
        (string Name, Func<string, string> Write)[] writers = [("GaChatbot.Api", GaChatbotEvent), ("GaApi", GaApiEvent)];
        (string Name, Func<string, string> Read)[] readers =
        [
            ("HTML standard", s => string.Concat(Standard(s).Where(e => e != "[DONE]"))),
            ("GaChatbot page", Page),
            ("ga-client chatService", ChatService),
        ];
        (string Name, List<string> Chunks)[] splits =
        [
            ("a826864", SseChunker.SplitIntoChunks(answer).ToList()),
            ("#743", ChunksAfter743(answer).ToList()),
        ];

        Title("Each writer with each reader, on the improvisation answer");
        int[] w = [14, 22, 44];
        Row(w, "writer", "reader", "chunks at a826864", "chunks after #743");
        foreach (var writer in writers)
        foreach (var reader in readers)
        {
            var results = splits.Select(split =>
            {
                var stream = string.Concat(split.Chunks.Select(writer.Write)) + "data: [DONE]\n\n";
                return Compare(answer, reader.Read(stream));
            }).ToArray();
            Row(w, writer.Name, reader.Name, results[0], results[1]);
        }
    }

    // ---- Measures ----

    static int Lines(string text) => text.Split('\n').Count(l => l.Trim().Length > 0);

    static int Breaks(string text) => text.Count(ch => ch == '\n');

    static string Compare(string original, string got)
    {
        if (got == original) return "exact";
        var textLines = original.Split('\n').Where(l => l.Trim().Length > 0).ToList();
        var missing = textLines.Count(l => !got.Contains(l.Trim(), StringComparison.Ordinal));
        List<string> parts = [];
        if (missing > 0) parts.Add($"{missing} of {textLines.Count} lines missing");
        var breaks = Breaks(original) - Breaks(got);
        if (breaks > 0) parts.Add($"{breaks} line breaks missing");
        return parts.Count == 0 ? "differs" : string.Join(", ", parts);
    }

    static string Show(string s) =>
        "\"" + s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "\\r").Replace("\n", "\\n") + "\"";

    // The improvisation skill's progression path never calls its extractor (lesson 5)
    sealed class NoExtractor : GA.Business.ML.Search.IMusicalQueryExtractor
    {
        public Task<GA.Business.ML.Search.StructuredQuery> ExtractAsync(string query, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("the single-chord path needs a model; this lesson doesn't use it");
    }
}
