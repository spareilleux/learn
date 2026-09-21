using static Advanced.Report;

namespace Advanced;

// Lesson 12: middleware is nested control flow; registration order is observable behavior.
public static class Lesson12
{
    public static void Run() => RunAsync().GetAwaiter().GetResult();

    private static async Task RunAsync()
    {
        await using var app = CourseWebHost.Create();
        var events = new List<string>();
        app.Use(async (context, next) =>
        {
            events.Add("outer:before");
            await next(context);
            events.Add("outer:after");
        });
        app.Use(async (context, next) =>
        {
            if (context.Request.Path == "/blocked")
            {
                events.Add("gate:short-circuit");
                context.Response.StatusCode = StatusCodes.Status429TooManyRequests;
                return;
            }
            await next(context);
        });
        app.MapGet("/ok", () =>
        {
            events.Add("endpoint");
            return "ok";
        });

        await app.StartAsync();
        using var client = CourseWebHost.Client(app);

        var ok = await client.GetAsync("/ok");
        Title("Middleware wraps the next delegate");
        Line($"GET /ok: {(int)ok.StatusCode}; {string.Join(" -> ", events)}");

        events.Clear();
        var blocked = await client.GetAsync("/blocked");
        Title("A short-circuit deliberately omits the endpoint");
        Line($"GET /blocked: {(int)blocked.StatusCode}; {string.Join(" -> ", events)}");

        await app.StopAsync();
    }
}
