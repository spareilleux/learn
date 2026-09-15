namespace GaAi;

using GA.Business.Core.Orchestration.Abstractions;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Hooks;
using GA.Business.ML.Agents.Intents;
using GA.Business.ML.Embeddings;
using Microsoft.Extensions.DependencyInjection;
using static Report;

// Lesson 1: the map — what the chatbot host registers, read from its dependency injection container
public static class Lesson1
{
    public static void Run()
    {
        Lesson4.EnsureIndex();
        using var host = new ChatHost();
        using var scope = host.Services.CreateScope();
        var sp = scope.ServiceProvider;

        Title("Orchestrator and application service");
        Line($"IHarmonicChatOrchestrator        {sp.GetRequiredService<IHarmonicChatOrchestrator>().GetType().Name}");
        Line($"IChatApplicationService (host)   {sp.GetRequiredService<GaChatbot.Api.Services.IChatApplicationService>().GetType().Name}");

        var intents = sp.GetServices<IIntent>().ToList();
        Title($"Intents the semantic router chooses from ({intents.Count})");
        int[] w = [28, 9];
        Row(w, "id", "examples", "first example");
        foreach (var i in intents)
            Row(w, i.Id, i.ExamplePrompts.Count, i.ExamplePrompts.FirstOrDefault());

        var agents = sp.GetRequiredService<SemanticRouter>().Agents;
        Title($"Agents behind the LLM path ({agents.Count})");
        foreach (var a in agents) Line($"{a.AgentId,-12} {a.GetType().Name}");

        var hooks = sp.GetServices<IChatHook>().ToList();
        Title($"Hooks, in the order they run ({hooks.Count})");
        foreach (var h in hooks) Line(h.GetType().Name);

        Title("The embedding every voicing gets");
        Line($"{EmbeddingSchema.Version}, {EmbeddingSchema.TotalDimension} dims in {EmbeddingSchema.Partitions.Length} partitions, {EmbeddingSchema.CompactDimension} of them searched");
    }
}
