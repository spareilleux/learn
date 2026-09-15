#:package Microsoft.Extensions.Hosting@10.0.12
// The .NET side of lesson 1: the same container mistakes as in the Spring examples, and configuration layering.
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

// A missing registration fails when the service is resolved, not when the provider is built.
var missing = new ServiceCollection().AddSingleton<ScaleService>().BuildServiceProvider();
Console.WriteLine("built a provider without INoteSpeller");
try
{
    missing.GetRequiredService<ScaleService>();
}
catch (InvalidOperationException e)
{
    Console.WriteLine($"resolve: {e.Message}");
}

// ValidateOnBuild moves the failure to startup, which is what Spring always does.
try
{
    new ServiceCollection().AddSingleton<ScaleService>().BuildServiceProvider(new ServiceProviderOptions { ValidateOnBuild = true });
}
catch (AggregateException e)
{
    Console.WriteLine($"ValidateOnBuild: {e.InnerExceptions.Count} error(s): {e.InnerExceptions[0].Message}");
}

// Two registrations: the last one wins for a single service, and IEnumerable<T> gets both.
var two = new ServiceCollection()
    .AddSingleton<INoteSpeller, SharpSpeller>()
    .AddSingleton<INoteSpeller, FlatSpeller>()
    .AddSingleton<ScaleService>()
    .BuildServiceProvider();
Console.WriteLine($"two registrations, ScaleService uses {two.GetRequiredService<ScaleService>().SpellerName}");
Console.WriteLine($"IEnumerable<INoteSpeller>: {string.Join(", ", two.GetServices<INoteSpeller>().Select(s => s.GetType().Name))}");

// Keyed services are the closest thing to a bean name.
var keyed = new ServiceCollection()
    .AddKeyedSingleton<INoteSpeller, SharpSpeller>("sharps")
    .AddKeyedSingleton<INoteSpeller, FlatSpeller>("flats")
    .BuildServiceProvider();
Console.WriteLine($"keyed \"flats\": {keyed.GetRequiredKeyedService<INoteSpeller>("flats").GetType().Name}");

// Configuration: later sources win, and "__" in an environment variable stands for the ":" separator.
Environment.SetEnvironmentVariable("Scales__Spelling", "flats");
var configuration = new ConfigurationBuilder()
    .AddInMemoryCollection(new Dictionary<string, string?> { ["Scales:Spelling"] = "sharps", ["Scales:DefaultMode"] = "ionian" })
    .AddEnvironmentVariables()
    .Build();
var options = configuration.GetSection("Scales").Get<ScalesOptions>()!;
Console.WriteLine($"Scales:Spelling = {options.Spelling}, Scales:DefaultMode = {options.DefaultMode}");

interface INoteSpeller;
sealed class SharpSpeller : INoteSpeller;
sealed class FlatSpeller : INoteSpeller;

sealed class ScaleService(INoteSpeller speller)
{
    public string SpellerName => speller.GetType().Name;
}

sealed class ScalesOptions
{
    public string Spelling { get; set; } = "";
    public string DefaultMode { get; set; } = "";
}
