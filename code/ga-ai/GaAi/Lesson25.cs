namespace GaAi;

using Microsoft.Extensions.DependencyInjection;

// Lesson 25: what reaches TransposeSkill. The program reads the routing hints a transposition
// question gets, the other intents' example prompts that the transpose hint and transpose's SKILL.md
// triggers also claim, the skills registered under the name Transpose, and what the router and the
// chat endpoint do with each question when nothing can embed it.
public static class Lesson25
{
    public static void Run()
    {
        Lesson4.EnsureIndex();
        using var host = new ChatHost();
        using var client = host.CreateClient();
        host.WaitForWarmup();
        using var scope = host.Services.CreateScope();
        var services = scope.ServiceProvider;
        TransposeRoutingProbe.HintsTable(services, "at the pin");
        TransposeRoutingProbe.OthersTable(services, "at the pin");
        TransposeRoutingProbe.SkillsTable(services, "at the pin");
        TransposeRoutingProbe.OfflineTable(services, client, "at the pin");
        TransposeRoutingProbe.DirectAnswer(services, "at the pin");
    }
}
