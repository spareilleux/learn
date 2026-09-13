using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// GET / : who am I, and where am I running?
app.MapGet("/", () => new
{
    App = "csharp-api",
    Runtime = RuntimeInformation.FrameworkDescription,
    Os = RuntimeInformation.OSDescription,
    Machine = Environment.MachineName
});

// GET /ticks : a stream of 3 Server-Sent Events, one per second
app.MapGet("/ticks", (CancellationToken ct) => TypedResults.ServerSentEvents(Ticks(ct)));

app.Run();

static async IAsyncEnumerable<int> Ticks([EnumeratorCancellation] CancellationToken ct)
{
    for (var i = 0; i < 3; i++)
    {
        await Task.Delay(TimeSpan.FromSeconds(1), ct);
        yield return i;
    }
}
