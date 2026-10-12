namespace GaAi;

using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Intents;
using Microsoft.Extensions.DependencyInjection;
using static Report;

// Lesson 28: the comparison questions. GaAi asks them of TheoryComparisonSkill at the pin; GaMain asks
// main's chatbot host, whose router can't embed them without a model and falls back on the skills'
// CanHandle, which is always false for TheoryComparisonSkill.
public static class ComparisonProbe
{
    public const string Comparison = "skill.theorycomparison";

    // The course's phrasings of a comparison, with and without the major/minor pair the skill reads
    public static readonly string[] Course =
    [
        "Minor vs major",
        "Major vs. minor",
        "Compare minor with major",
        "What is the difference between minor and major",
        "What's the difference between major and minor keys",
        "Major and minor difference",
        "How are major and minor different",
        "Major or minor: what's the difference?",
        "Majors vs minors",
        "What is the difference between the major and minor scales",
        "Difference between a major and a minor chord",
        "Explain the major vs minor difference",
        "Which sounds sadder, a major vs minor chord?",
        "C major vs C minor",
        "What's the difference between C major and C minor",
        "Major vs major",
        "Major vs dorian",
        "Dorian vs Aeolian",
        "Harmonic minor vs melodic minor",
        "Major pentatonic vs minor pentatonic",
    ];

    // The course's phrasings asked of main's chatbot host too: each chat request takes seconds there
    public static readonly string[] OnMain =
        ["Minor vs major", "Difference between a major and a minor chord", "C major vs C minor"];

    public static List<(string Source, string Prompt)> Phrasings(IEnumerable<string> examples) =>
        [.. examples.Select(p => ("example", p)), .. Course.Select(p => ("course", p))];

    // Main's chatbot host without embeddings: the router's pick and the chat endpoint's answer
    public static void OfflineTable(IServiceProvider services, HttpClient client, string where)
    {
        var router = services.GetRequiredService<SemanticIntentRouter>();
        var examples = services.GetServices<IIntent>().Single(i => i.Id == Comparison).ExamplePrompts;
        List<(string Source, string Prompt)> phrasings = [.. examples.Select(p => ("example", p)), .. OnMain.Select(p => ("course", p))];
        Title($"Without embeddings: the intent SemanticIntentRouter picks for the example prompts and three of the course's phrasings, and what POST /api/chatbot/chat answers ({where})");
        int[] w = [58, 24, 45];
        Row(w, "phrasing", "router picks", "chat: agent (routing method)", "first line of the answer");
        var picks = new List<string>();
        var agents = new List<string>();
        foreach (var (_, prompt) in phrasings)
        {
            var match = router.RouteAsync(prompt, services).GetAwaiter().GetResult();
            var pick = match?.Intent.Id ?? "none";
            picks.Add(pick);
            var (agent, first) = TransposeRoutingProbe.Chat(client, prompt);
            agents.Add(agent);
            Row(w, prompt, pick, agent, first);
        }

        Line($"{phrasings.Count} phrasings; the router picks {TransposeRoutingProbe.Counts(picks)}; " +
             $"the chat endpoint answers with {TransposeRoutingProbe.Counts(agents)}");
    }
}
