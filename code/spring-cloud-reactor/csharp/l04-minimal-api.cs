#:sdk Microsoft.NET.Sdk.Web
#:property PublishAot=false
// The .NET side of lesson 4: the same endpoints as a minimal API, called with HttpClient on a free local port.
using System.Net;
using System.Runtime.CompilerServices;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Hosting.Server.Features;

var builder = WebApplication.CreateBuilder(args);
builder.Logging.ClearProviders();
builder.WebHost.ConfigureKestrel(kestrel => kestrel.Listen(IPAddress.Loopback, 0));
builder.Services.AddProblemDetails();
var app = builder.Build();

string[] Notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
int[] Major = [0, 2, 4, 5, 7, 9, 11];

// app.MapGet is WebFlux's route().GET(...); returning a value writes JSON, Results.Problem writes RFC 9457.
app.MapGet("/scales/{root}", (string root) =>
{
    var index = Array.IndexOf(Notes, root);
    return index < 0
        ? Results.Problem(detail: $"unknown note: {root}", statusCode: 400, title: "Unknown note or mode")
        : Results.Ok(new { root, notes = Major.Select(i => Notes[(index + i) % 12]) });
});

// .NET 10 writes server-sent events from an IAsyncEnumerable, like a Flux<ServerSentEvent>.
app.MapGet("/progressions/{root}", (string root, CancellationToken cancellation) =>
    TypedResults.ServerSentEvents(Progression(root, cancellation), eventType: "chord"));

static async IAsyncEnumerable<string> Progression(string root, [EnumeratorCancellation] CancellationToken cancellation)
{
    foreach (var chord in new[] { "G", "Em", "C", "D" })
    {
        await Task.Delay(20, cancellation);
        yield return chord;
    }
}

await app.StartAsync();
var address = app.Services.GetRequiredService<IServer>().Features.Get<IServerAddressesFeature>()!.Addresses.First();
using var http = new HttpClient { BaseAddress = new Uri(address) };

foreach (var path in new[] { "/scales/D", "/scales/H", "/progressions/G" })
{
    using var response = await http.GetAsync(path);
    Console.WriteLine($"GET {path}");
    Console.WriteLine($"{(int)response.StatusCode} {response.Content.Headers.ContentType}");
    // The trace id changes with every request.
    Console.WriteLine(Regex.Replace((await response.Content.ReadAsStringAsync()).TrimEnd(), "\"traceId\":\"[^\"]+\"", "\"traceId\":\"...\""));
    Console.WriteLine();
}

// GetFromJsonAsync throws on an error status, like WebClient's retrieve().
try
{
    await http.GetFromJsonAsync<object>("/scales/H");
}
catch (HttpRequestException e)
{
    Console.WriteLine($"{e.GetType().Name}: {e.Message}");
}

await app.StopAsync();
