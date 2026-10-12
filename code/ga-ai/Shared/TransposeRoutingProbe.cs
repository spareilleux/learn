namespace GaAi;

using System.Net.Http.Json;
using System.Reflection;
using System.Text.Json;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Intents;
using Microsoft.Extensions.DependencyInjection;
using static Report;

// Lesson 25: the questions that reach TransposeSkill. With embeddings, SemanticIntentRouter adds
// +0.06 to every intent whose DefaultRoutingHintProvider rule matches the question; without them,
// the pinned router routes nothing, and main's routes to the first intent, in registration order,
// whose skill's CanHandle accepts the question. The same tables run in the pinned host (GaAi) and
// in main's (GaMain).
public static class TransposeRoutingProbe
{
    const string Transpose = "skill.transpose";

    // GA's prompt corpus at the pin, Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml lines 178,
    // 426, 515 and 560
    static readonly string[] Corpus =
    [
        "Transpose C E G to D", "Transpose C major to E", "Transpose this progression to capo 3",
        "Transpose A minor to C minor",
    ];

    // The course's own phrasings of the same request
    static readonly string[] Course =
    [
        "Transpose Dm7 down a half step", "Move Am up two frets", "Shift the song to the key of E",
        "Put Cmaj7 in the key of A", "Raise Bb7 by a minor third", "Lower G by a tritone",
        "Play this song a whole step down", "Take F#m up a fourth",
    ];

    // The triggers of skills/transpose/SKILL.md (lines 4-11), which SkillMdDrivenSkill.CanHandle
    // looks for as lowercase substrings
    static readonly string[] Triggers =
        ["transpose", "move this chord", "shift this chord", "up a", "down a", "in the key of", "change the key"];

    // TransposeSkill's example prompts, the one phrasing of transpose's SKILL.md that is not among
    // them (line 80), the corpus prompts and the course's
    public static List<(string Source, string Prompt)> Phrasings(IServiceProvider services)
    {
        var examples = services.GetServices<IIntent>().Single(i => i.Id == Transpose).ExamplePrompts;
        return
        [
            .. examples.Select(p => ("example", p)), ("SKILL.md", "Cmaj7 in the key of G"),
            .. Corpus.Select(p => ("corpus", p)), .. Course.Select(p => ("course", p)),
        ];
    }

    static string Triggered(string prompt)
    {
        var lower = prompt.ToLowerInvariant();
        var found = Triggers.Where(lower.Contains).ToList();
        return found.Count == 0 ? "none" : string.Join(", ", found);
    }

    static string Hints(IRoutingHintProvider hints, string prompt)
    {
        var ids = hints.GetDeltas(prompt).Keys.Order(StringComparer.Ordinal).ToList();
        return ids.Count == 0 ? "none" : string.Join(", ", ids);
    }

    // The skill an OrchestratorSkillIntent adapts, from its private field
    static IOrchestratorSkill? SkillOf(IIntent intent) =>
        intent.GetType().GetFields(BindingFlags.NonPublic | BindingFlags.Instance)
            .Select(f => f.GetValue(intent)).OfType<IOrchestratorSkill>().FirstOrDefault();

    static string Cut(string s, int n) => s.Length <= n ? s : s[..(n - 1)] + "…";

    // ---- The routing hints ----

    public static void HintsTable(IServiceProvider services, string where)
    {
        var hints = services.GetRequiredService<IRoutingHintProvider>();
        var phrasings = Phrasings(services);
        Title($"Transpose phrasings: the intents whose routing hint fires, and the triggers of transpose's SKILL.md they contain ({where})");
        int[] w = [8, 44, 40];
        Row(w, "source", "phrasing", "hints, +0.06 each", "SKILL.md triggers");
        foreach (var (source, prompt) in phrasings)
            Row(w, source, prompt, Hints(hints, prompt), Triggered(prompt));
        var deltas = phrasings.Select(x => hints.GetDeltas(x.Prompt)).ToList();
        Line($"{phrasings.Count} phrasings: the transpose hint fires on {deltas.Count(d => d.ContainsKey(Transpose))}; " +
             $"another intent's hint on {deltas.Count(d => d.Keys.Any(k => k != Transpose))}, " +
             $"{deltas.Count(d => d.Count > 0 && !d.ContainsKey(Transpose))} of them without the transpose hint; " +
             $"no hint on {deltas.Count(d => d.Count == 0)}; a SKILL.md trigger in {phrasings.Count(x => Triggered(x.Prompt) != "none")}");
    }

    // Every other intent's example prompts, read by the transpose hint and by the SKILL.md triggers
    public static void OthersTable(IServiceProvider services, string where)
    {
        var hints = services.GetRequiredService<IRoutingHintProvider>();
        var others = services.GetServices<IIntent>().Where(i => i.Id != Transpose)
            .SelectMany(i => i.ExamplePrompts.Select(p => (i.Id, Prompt: p))).ToList();
        Title($"The other intents' example prompts that the transpose hint or transpose's SKILL.md triggers claim ({where})");
        int[] w = [26, 58, 5];
        Row(w, "intent", "example prompt", "hint", "SKILL.md triggers");
        foreach (var (id, prompt) in others)
        {
            var hint = hints.GetDeltas(prompt).ContainsKey(Transpose);
            var triggered = Triggered(prompt);
            if (hint || triggered != "none") Row(w, id, Cut(prompt, 57), hint ? "yes" : "no", triggered);
        }

        Line($"{others.Count} example prompts of {others.Select(x => x.Id).Distinct().Count()} other intents: " +
             $"the transpose hint fires on {others.Count(x => hints.GetDeltas(x.Prompt).ContainsKey(Transpose))}, " +
             $"a SKILL.md trigger is in {others.Count(x => Triggered(x.Prompt) != "none")}");
    }

    // ---- Without embeddings ----

    // The skills that answer a transposition, and the intent behind each one
    public static void SkillsTable(IServiceProvider services, string where)
    {
        var skills = services.GetServices<IOrchestratorSkill>().ToList();
        var intents = services.GetServices<IIntent>().Select(i => (i.Id, Skill: SkillOf(i))).ToList();
        var phrasings = Phrasings(services);
        Title($"The skills registered under the name Transpose, and the intent the router can pick for each ({where})");
        int[] w = [20, 12, 22];
        Row(w, "skill", "name", "intent", "CanHandle accepts");
        // Sorted by type: the two commits register them in a different order
        foreach (var s in skills.Where(s => s.Name.Equals("transpose", StringComparison.OrdinalIgnoreCase))
                     .OrderBy(s => s.GetType().Name, StringComparer.Ordinal))
            Row(w, s.GetType().Name, s.Name, intents.FirstOrDefault(i => ReferenceEquals(i.Skill, s)).Id ?? "none",
                $"{phrasings.Count(x => s.CanHandle(x.Prompt))} of the {phrasings.Count} phrasings");
        var fromMd = skills.Where(s => s.GetType().Name == "SkillMdDrivenSkill").ToList();
        Line($"IOrchestratorSkill registrations {skills.Count}, of them built from a SKILL.md {fromMd.Count}, " +
             $"behind an intent {fromMd.Count(s => intents.Any(i => ReferenceEquals(i.Skill, s)))}");
    }

    public static void OfflineTable(IServiceProvider services, HttpClient client, string where)
    {
        var router = services.GetRequiredService<SemanticIntentRouter>();
        var phrasings = Phrasings(services);
        Title($"Without embeddings: the intent SemanticIntentRouter picks for each phrasing, and what POST /api/chatbot/chat answers ({where})");
        int[] w = [44, 24, 45];
        Row(w, "phrasing", "router picks", "chat: agent (routing method)", "first line of the answer");
        var picks = new List<string>();
        var agents = new List<string>();
        foreach (var (_, prompt) in phrasings)
        {
            var match = router.RouteAsync(prompt, services).GetAwaiter().GetResult();
            var pick = match?.Intent.Id ?? "none";
            picks.Add(pick);
            var (agent, first) = Chat(client, prompt);
            agents.Add(agent);
            Row(w, prompt, pick, agent, first);
        }

        Line($"{phrasings.Count} phrasings; the router picks {Counts(picks)}; the chat endpoint answers with {Counts(agents)}");
    }

    internal static string Counts(IEnumerable<string> values) =>
        string.Join(", ", values.GroupBy(v => v).OrderByDescending(g => g.Count()).ThenBy(g => g.Key, StringComparer.Ordinal)
            .Select(g => $"{g.Key} {g.Count()}"));

    internal static (string Agent, string FirstLine) Chat(HttpClient client, string message)
    {
        var response = client.PostAsJsonAsync("/api/chatbot/chat", new { message }).GetAwaiter().GetResult();
        if (!response.IsSuccessStatusCode) return ($"HTTP {(int)response.StatusCode}", "");
        using var doc = JsonDocument.Parse(response.Content.ReadAsStringAsync().GetAwaiter().GetResult());
        var root = doc.RootElement;
        var answer = root.GetProperty("naturalLanguageAnswer").GetString() ?? "";
        var first = answer.ReplaceLineEndings("\n").Split('\n').Select(l => l.Trim()).FirstOrDefault(l => l.Length > 0) ?? "";
        var method = root.TryGetProperty("routingMethod", out var m) ? m.GetString() : null;
        return ($"{root.GetProperty("agentId").GetString()} ({method ?? "none"})", Cut(first, 50));
    }

    // TransposeSkill itself, called without the router: it hands the question to a model
    public static void DirectAnswer(IServiceProvider services, string where)
    {
        const string prompt = "Transpose Cmaj7 up a perfect fourth";
        var skill = services.GetServices<IOrchestratorSkill>().Single(s => s.GetType().Name == "TransposeSkill");
        var response = skill.ExecuteAsync(prompt).GetAwaiter().GetResult();
        Title($"TransposeSkill called directly with \"{prompt}\" ({where})");
        Line($"confidence {response.Confidence:0.00}");
        Line($"  | {response.Result}");
        foreach (var e in response.Evidence) Line($"  evidence: {e}");
    }
}
