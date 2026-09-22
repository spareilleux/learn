using Microsoft.Extensions.Options;
using static Advanced.Report;

namespace Advanced;

// Lesson 13: DI lifetimes are ownership rules; options validation turns configuration into a startup contract.
public static class Lesson13
{
    public static void Run()
    {
        Title("Singleton and scoped lifetimes are different ownership boundaries");
        var services = new ServiceCollection();
        services.AddSingleton<SingletonProbe>();
        services.AddScoped<ScopedProbe>();
        services.AddKeyedSingleton<IFormatter, CompactFormatter>("compact");
        services.AddKeyedSingleton<IFormatter, VerboseFormatter>("verbose");
        using var provider = services.BuildServiceProvider(new ServiceProviderOptions { ValidateScopes = true });
        var singletonSame = ReferenceEquals(provider.GetRequiredService<SingletonProbe>(), provider.GetRequiredService<SingletonProbe>());
        Guid first;
        Guid second;
        using (var scope = provider.CreateScope())
        {
            var one = scope.ServiceProvider.GetRequiredService<ScopedProbe>();
            first = one.Id;
            Line($"same scope returns same instance: {ReferenceEquals(one, scope.ServiceProvider.GetRequiredService<ScopedProbe>())}");
        }
        using (var scope = provider.CreateScope()) second = scope.ServiceProvider.GetRequiredService<ScopedProbe>().Id;
        Line($"singleton returns same instance: {singletonSame}");
        Line($"different scopes return different instances: {first != second}");
        Line($"keyed services: {provider.GetRequiredKeyedService<IFormatter>("compact").Format("C major")} | {provider.GetRequiredKeyedService<IFormatter>("verbose").Format("C major")}");

        Title("Scope validation rejects a singleton that captures a scoped service");
        var captive = new ServiceCollection();
        captive.AddScoped<ScopedProbe>();
        captive.AddSingleton<CaptiveSingleton>();
        var captiveRejected = false;
        try
        {
            using var invalid = captive.BuildServiceProvider(new ServiceProviderOptions
            {
                ValidateOnBuild = true,
                ValidateScopes = true,
            });
        }
        catch (AggregateException error) when (error.InnerExceptions.Any(e => e is InvalidOperationException))
        {
            captiveRejected = true;
        }
        Line($"captive scoped dependency rejected: {captiveRejected}");

        Title("Options validation rejects invalid configuration at the boundary");
        var configured = new ServiceCollection();
        configured.AddOptions<QueueSettings>()
            .Configure(settings => settings.Capacity = 0)
            .Validate(settings => settings.Capacity > 0, "Capacity must be positive");
        using var configuredProvider = configured.BuildServiceProvider();
        var optionsRejected = false;
        try
        {
            _ = configuredProvider.GetRequiredService<IOptions<QueueSettings>>().Value;
        }
        catch (OptionsValidationException)
        {
            optionsRejected = true;
        }
        Line($"invalid options rejected: {optionsRejected}");
    }

    private sealed class SingletonProbe;
    private sealed class ScopedProbe { public Guid Id { get; } = Guid.NewGuid(); }
    private sealed class CaptiveSingleton(ScopedProbe dependency) { public ScopedProbe Dependency { get; } = dependency; }
    private interface IFormatter { string Format(string value); }
    private sealed class CompactFormatter : IFormatter { public string Format(string value) => value.Replace(" ", "", StringComparison.Ordinal); }
    private sealed class VerboseFormatter : IFormatter { public string Format(string value) => $"chord={value}"; }
    private sealed class QueueSettings { public int Capacity { get; set; } }
}
