using static Advanced.Report;

namespace Advanced;

// Lesson 11: the generic host owns lifetime; Kestrel owns network transport and limits.
public static class Lesson11
{
    public static void Run() => RunAsync().GetAwaiter().GetResult();

    private static async Task RunAsync()
    {
        await using var app = CourseWebHost.Create();
        var started = false;
        var stopping = false;
        var stopped = false;
        app.Lifetime.ApplicationStarted.Register(() => started = true);
        app.Lifetime.ApplicationStopping.Register(() => stopping = true);
        app.Lifetime.ApplicationStopped.Register(() => stopped = true);
        app.MapGet("/health", () => TypedResults.Ok(new Health("ready")));

        await app.StartAsync();
        using var client = CourseWebHost.Client(app);
        var response = await client.GetAsync("/health");
        var body = await response.Content.ReadAsStringAsync();

        Title("WebApplication composes the host, services, middleware and endpoints");
        Line($"started callback observed: {started}");
        Line($"GET /health: {(int)response.StatusCode} {body}");

        await app.StopAsync();
        Line($"graceful stop callbacks observed: stopping={stopping}, stopped={stopped}");
    }

    private sealed record Health(string Status);
}
