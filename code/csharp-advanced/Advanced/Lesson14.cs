using System.Runtime.CompilerServices;
using Microsoft.AspNetCore.Mvc;
using static Advanced.Report;

namespace Advanced;

// Lesson 14: Minimal APIs and controllers share routing but expose different composition surfaces.
public static class Lesson14
{
    public static void Run() => RunAsync().GetAwaiter().GetResult();

    private static async Task RunAsync()
    {
        var builder = WebApplication.CreateSlimBuilder(new WebApplicationOptions
        {
            ApplicationName = typeof(Lesson14).Assembly.FullName,
            Args = [],
        });
        builder.Logging.ClearProviders();
        builder.WebHost.ConfigureKestrel(options => options.Listen(System.Net.IPAddress.Loopback, 0));
        builder.Services.AddControllers();
        await using var app = builder.Build();

        app.MapGet("/api/scales/{root}", (string root, int notes) =>
                TypedResults.Ok(new ScaleResponse(root, notes)))
            .AddEndpointFilter(async (context, next) =>
                context.HttpContext.Request.Headers.ContainsKey("x-course-key")
                    ? await next(context)
                    : Results.BadRequest(new ErrorResponse("missing x-course-key")));
        app.MapGet("/api/stream", () => Chords());
        app.MapControllers();

        await app.StartAsync();
        using var client = CourseWebHost.Client(app);

        Title("Route and query binding plus an endpoint filter");
        var rejected = await client.GetAsync("/api/scales/C?notes=7");
        client.DefaultRequestHeaders.Add("x-course-key", "local");
        var accepted = await client.GetAsync("/api/scales/C?notes=7");
        Line($"without key: {(int)rejected.StatusCode}; with key: {(int)accepted.StatusCode} {await accepted.Content.ReadAsStringAsync()}");

        Title("A controller uses the same endpoint routing table");
        var controller = await client.GetAsync("/api/chords/Cmaj7");
        Line($"controller: {(int)controller.StatusCode} {await controller.Content.ReadAsStringAsync()}");

        Title("IAsyncEnumerable is streamed as a JSON array");
        var stream = await client.GetStringAsync("/api/stream");
        Line($"stream: {stream}");

        await app.StopAsync();
    }

    private static async IAsyncEnumerable<string> Chords([EnumeratorCancellation] CancellationToken token = default)
    {
        foreach (var chord in (string[])["Dm7", "G7", "Cmaj7"])
        {
            token.ThrowIfCancellationRequested();
            await Task.Yield();
            yield return chord;
        }
    }

    private sealed record ScaleResponse(string Root, int Notes);
    private sealed record ErrorResponse(string Error);
}

[ApiController]
[Route("api/chords")]
public sealed class ChordsController : ControllerBase
{
    [HttpGet("{symbol}")]
    public ActionResult<ChordResponse> Get(string symbol) => Ok(new ChordResponse(symbol, symbol.Length));
}

public sealed record ChordResponse(string Symbol, int Characters);
