namespace GaAi;

using System.Net.Http.Json;
using System.Text.Json;
using System.Text.RegularExpressions;
using GA.Business.ML.Agents.Intents;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;
using static Report;

// Lesson 8: GA's own prompt corpus, the gate its chatbot changes are tested against, read at the
// pinned commit and run without a model. Then the gate itself is tested: its invariants are applied
// to answers they weren't written for, and to the same answers a semitone higher.
public static class Lesson8
{
    public static readonly string CorpusPath = Path.Combine(AppContext.BaseDirectory,
        "..", "..", "..", "..", ".ga-files", "prompts.yaml");

    // The fields of PromptCorpusTests.PromptEntry this lesson reads
    public sealed class CorpusFile
    {
        public List<Entry> Prompts { get; set; } = [];
    }

    public sealed class Entry
    {
        public string Prompt { get; set; } = "";
        public string? Category { get; set; }
        public string? RoutesTo { get; set; }
        public List<string>? Contains { get; set; }
        public List<string>? ContainsAny { get; set; }
        public List<string>? NotContains { get; set; }
        public int? MinLength { get; set; }
        public bool Skip { get; set; }
        public string? Judge { get; set; }
    }

    // One prompt of the corpus and what the host without a model made of it
    sealed record Attempt(int N, Entry Entry, string Served, string? Answer, string? Verdict, List<string> Logs)
    {
        public bool Passed => Answer is not null && Verdict is null;
    }

    public static void Run()
    {
        var corpus = new DeserializerBuilder()
            .WithNamingConvention(UnderscoredNamingConvention.Instance)
            .IgnoreUnmatchedProperties()
            .Build()
            .Deserialize<CorpusFile>(File.ReadAllText(CorpusPath));
        Describe(corpus);

        Lesson4.EnsureIndex();
        using var host = new ChatHost();
        using var client = host.CreateClient();
        host.WaitForWarmup();
        using var scope = host.Services.CreateScope();
        var intents = scope.ServiceProvider.GetServices<IIntent>().ToDictionary(i => i.Id);
        var attempts = corpus.Prompts.Select((e, i) => Ask(host, client, intents, i + 1, e)).ToList();

        Outcomes(attempts);
        PathB(attempts.First(a => a.Entry.RoutesTo == "skill.diatonicchords"));
        Foreign(attempts, Evaluate, "GA's invariants");
        Higher(attempts[50]);
        Accepted(attempts, 26, 31, 38, 39, 49);
        Stricter(attempts);
    }

    static void Describe(CorpusFile corpus)
    {
        var p = corpus.Prompts;
        Title("GA's prompt corpus at a826864 (Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml)");
        Line($"prompts {p.Count}, skipped {p.Count(e => e.Skip)}, with a judge rubric {p.Count(e => e.Judge is not null)}, " +
             $"naming the intent that must answer {p.Count(e => !e.Skip && e.RoutesTo is not null)}");
        var single = p.SelectMany(e => (e.Contains ?? []).Concat(e.ContainsAny ?? [])).Count(s => s.Length == 1);
        Line($"expected strings {p.Sum(e => (e.Contains?.Count ?? 0) + (e.ContainsAny?.Count ?? 0))}, of one character {single}");
    }

    // A prompt that names an intent is sent to that intent directly: without a model the intent
    // router can't embed the question (lesson 4). The others go through the chat endpoint.
    static Attempt Ask(ChatHost host, HttpClient client, Dictionary<string, IIntent> intents, int n, Entry e)
    {
        if (e.Skip) return new(n, e, "skipped", null, null, []);
        while (host.Logs.TryDequeue(out _)) { }
        string served, answer;
        if (e.RoutesTo is { } id && intents.TryGetValue(id, out var intent))
        {
            answer = intent.ExecuteAsync(e.Prompt).GetAwaiter().GetResult().Answer;
            served = id;
        }
        else
        {
            var response = client.PostAsJsonAsync("/api/chatbot/chat", new { message = e.Prompt }).GetAwaiter().GetResult();
            if (!response.IsSuccessStatusCode) return new(n, e, $"chat: HTTP {(int)response.StatusCode}", null, null, []);
            using var doc = JsonDocument.Parse(response.Content.ReadAsStringAsync().GetAwaiter().GetResult());
            answer = doc.RootElement.GetProperty("naturalLanguageAnswer").GetString() ?? "";
            served = $"chat: {doc.RootElement.GetProperty("agentId").GetString()}";
        }
        answer = answer.ReplaceLineEndings("\n");
        // The skills' own log lines, not the host's: lesson 4 read those
        var logs = host.Logs
            .Where(l => l.Category.StartsWith("GA.Business.ML.Agents.Skills.", StringComparison.Ordinal))
            .Select(l => $"{l.Level} {l.Category[29..]}: {l.Message.TrimEnd()} ({l.Exception?.GetType().Name ?? "no exception"})")
            .ToList();
        return new(n, e, served, answer, Evaluate(e, answer), logs);
    }

    static void Outcomes(List<Attempt> attempts)
    {
        Title("Each prompt without a model, checked as PromptCorpusTests checks it");
        int[] w = [3, 46, 26];
        Row(w, "#", "prompt", "answered by", "verdict");
        foreach (var a in attempts)
            Row(w, a.N, Cut(a.Entry.Prompt, 45), a.Served, a.Answer is null ? "" : a.Verdict ?? "pass");
        var answered = attempts.Where(a => a.Answer is not null).ToList();
        Line();
        Line($"{attempts.Count} prompts: {attempts.Count(a => a.Entry.Skip)} skipped, " +
             $"{attempts.Count(a => a.Served.StartsWith("chat: HTTP", StringComparison.Ordinal))} end in an HTTP error, " +
             $"{answered.Count} answered: {answered.Count(a => a.Passed)} pass, {answered.Count(a => !a.Passed)} fail, " +
             $"{answered.Count(a => a.Verdict == Degraded)} of them flagged as a degraded backend");
    }

    static void PathB(Attempt a)
    {
        Title($"#{a.N} {a.Entry.Prompt}: the intent's answer and the skills' log lines");
        Line($"  | {a.Answer}");
        foreach (var log in a.Logs) Line(log);
    }

    // ---- GA's invariants, ported from PromptCorpusTests.EvaluatePromptAsync ----

    static readonly string[] UniversalBannedMarkers =
    [
        "Reproduce the catalog below verbatim",
        "Pure pedagogy",
        "Use when a learner asks",
        "Use when a visitor asks",
        "doesn't need a tool call",
        "returned no matches",
        "not yet implemented",
        "index is not loaded",
    ];

    static readonly string[] BackendDegradedMarkers =
    [
        "The chatbot can't serve a request right now",
        "right now. Please try again.",
    ];

    const string Degraded = "BACKEND_DEGRADED";

    // The text invariants in GA's order; routing, grounding and trace don't apply to an intent
    // called directly. `contains` decides how an expected string is looked for.
    static string? Evaluate(Entry e, string answer) => Check(e, answer, GaContains);

    static bool GaContains(string answer, string s) => answer.Contains(s, StringComparison.OrdinalIgnoreCase);

    static string? Check(Entry e, string answer, Func<string, string, bool> contains)
    {
        if (string.IsNullOrWhiteSpace(answer)) return "empty response";
        foreach (var marker in BackendDegradedMarkers)
            if (answer.Contains(marker, StringComparison.OrdinalIgnoreCase)) return Degraded;
        var minLen = e.MinLength ?? 50;
        if (answer.Length < minLen) return $"too short ({answer.Length} < {minLen} chars)";
        foreach (var marker in UniversalBannedMarkers)
            if (answer.Contains(marker, StringComparison.OrdinalIgnoreCase)) return $"banned \"{marker}\"";
        foreach (var marker in e.NotContains ?? [])
            if (contains(answer, marker)) return $"contains \"{marker}\"";
        foreach (var must in e.Contains ?? [])
            if (!contains(answer, must)) return $"missing \"{must}\"";
        if (e.ContainsAny is { Count: > 0 } any && !any.Any(s => contains(answer, s)))
            return "none of contains_any";
        return null;
    }

    // ---- Testing the invariants ----

    // Each passing prompt's invariants applied to every other answer of the run, and to its own
    // answer a semitone higher when the prompt names a note or a chord
    static void Foreign(List<Attempt> attempts, Func<Entry, string, string?> check, string label)
    {
        var pool = attempts.Where(a => a.Answer is not null).DistinctBy(a => a.Answer).ToList();
        Title($"{label} applied to the other answers, and to the same answer a semitone higher");
        int[] w = [3, 42, 26];
        Row(w, "#", "prompt", "other answers pass", "a semitone higher");
        var passed = attempts.Where(a => a.Answer is not null && check(a.Entry, a.Answer) is null).ToList();
        var total = 0;
        foreach (var a in passed)
        {
            var others = pool.Where(o => o.Answer != a.Answer).ToList();
            var passing = others.Where(o => check(a.Entry, o.Answer!) is null).Select(o => o.N).ToList();
            total += passing.Count;
            Row(w, a.N, Cut(a.Entry.Prompt, 41), $"{passing.Count} of {others.Count}{Example(passing)}",
                NamesPitch(a.Entry.Prompt) ? check(a.Entry, Transpose(a.Answer!)) ?? "pass" : "n/a");
        }
        Line();
        Line($"{passed.Count} passing prompts; other answers accepted: {total}; " +
             $"accepted a semitone higher: {passed.Count(a => NamesPitch(a.Entry.Prompt) && check(a.Entry, Transpose(a.Answer!)) is null)} " +
             $"of {passed.Count(a => NamesPitch(a.Entry.Prompt))} that name a pitch");
    }

    static void Higher(Attempt a)
    {
        var higher = Transpose(a.Answer!);
        Title($"#{a.N} {a.Entry.Prompt}, the answer a semitone higher: GA {Evaluate(a.Entry, higher) ?? "pass"}, strict {Strict(a.Entry, higher) ?? "pass"}");
        foreach (var line in higher.Split('\n').Take(3)) Line($"  | {line}".TrimEnd());
    }

    static string Example(List<int> ns) => ns.Count == 0 ? "" : $" (#{string.Join(", #", ns.Take(3))}{(ns.Count > 3 ? ", …" : "")})";

    // Where each expected string was found in an answer the gate accepted
    static void Accepted(List<Attempt> attempts, params int[] ns)
    {
        foreach (var a in ns.Select(n => attempts[n - 1]))
        {
            Title($"#{a.N} {a.Entry.Prompt}: {a.Verdict ?? "pass"}");
            var lines = a.Answer!.TrimEnd().Split('\n');
            foreach (var line in lines.Take(6)) Line($"  | {line}".TrimEnd());
            if (lines.Length > 6) Line($"  | … {lines.Length - 6} more lines");
            var found = (a.Entry.Contains ?? []).ToList();
            if (a.Entry.ContainsAny?.FirstOrDefault(s => GaContains(a.Answer, s)) is { } any) found.Add(any);
            foreach (var s in found)
            {
                var i = a.Answer.IndexOf(s, StringComparison.OrdinalIgnoreCase);
                var line = a.Answer[..i].Count(ch => ch == '\n') + 1;
                Line($"\"{s}\" matches \"{Word(a.Answer, i, s.Length)}\" on line {line}");
            }
        }
    }

    // The token around a match: letters, digits and accidentals on both sides
    static string Word(string text, int start, int length)
    {
        var end = start + length;
        while (start > 0 && IsTokenChar(text[start - 1])) start--;
        while (end < text.Length && IsTokenChar(text[end])) end++;
        return text[start..end];
    }

    // ---- Note names ----

    static bool IsTokenChar(char c) => char.IsLetterOrDigit(c) || c is '#' or '♯' or '♭' or '°' or 'ø' or '+';

    static readonly Regex Token = new(@"[A-Za-z0-9#♯♭°ø+]+");

    // A note name or a chord symbol written with a capital letter: C, F#, Bb, Am, Cmaj9, F#m7b5
    static readonly Regex NoteToken = new(
        @"^(?<root>[A-G][#b♯♭]?)(maj|min|dim|aug|sus|add|mMaj|m|M|ø|°|\+)?[0-9]*((b|#|♭|♯|add|sus)[0-9]+)*$");

    static bool NamesPitch(string prompt) => Token.Matches(prompt).Any(m => NoteToken.IsMatch(m.Value));

    static readonly string[] Sharps = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

    // Every note name and chord root of an answer one semitone higher, spelled with sharps
    static string Transpose(string answer) => Token.Replace(answer, m =>
    {
        var note = NoteToken.Match(m.Value);
        if (!note.Success) return m.Value;
        var root = note.Groups["root"].Value;
        var pc = "C D EF G A B".IndexOf(root[0]) + (root.Length > 1 ? root[1] is '#' or '♯' ? 1 : -1 : 0);
        return Sharps[(pc + 13) % 12] + m.Value[root.Length..];
    });

    // ---- A stricter reading of the same invariants ----

    // An expected string that starts with a note name must appear with the same capital letter and
    // accidental, and every expected string must stand alone: no letter, digit or accidental
    // against either end of it
    static bool StrictContains(string answer, string s)
    {
        var comparison = NoteToken.IsMatch(s.Split(' ')[0]) ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
        for (var i = answer.IndexOf(s, comparison); i >= 0; i = answer.IndexOf(s, i + 1, comparison))
        {
            var end = i + s.Length;
            if ((i == 0 || !IsTokenChar(answer[i - 1])) && (end == answer.Length || !IsTokenChar(answer[end])))
                return true;
        }
        return false;
    }

    static string? Strict(Entry e, string answer) => Check(e, answer, StrictContains);

    static void Stricter(List<Attempt> attempts)
    {
        Title("The same invariants, read strictly: each prompt's own answer");
        var failing = attempts.Where(a => a.Answer is not null && (a.Verdict is null) != (Strict(a.Entry, a.Answer) is null)).ToList();
        foreach (var a in failing)
            Line($"#{a.N} {a.Entry.Prompt}: GA {a.Verdict ?? "pass"}, strict {Strict(a.Entry, a.Answer!) ?? "pass"}");
        if (failing.Count == 0) Line("(the strict reading gives every answer the same verdict as GA's)");
        Foreign(attempts, Strict, "The strict reading");
    }

    static string Cut(string s, int max) => s.Length <= max ? s : s[..(max - 1)] + "…";
}
