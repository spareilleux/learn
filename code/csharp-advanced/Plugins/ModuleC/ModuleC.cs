using Contracts;
using Microsoft.Extensions.DependencyInjection;

namespace ModuleC;

public sealed class Module : IModule
{
    public void Register(IServiceCollection services) => services.AddSingleton<ITool, Metronome>();
}

// Starts a timer when the container creates it, and stops it only when the container disposes it
sealed class Metronome : ITool, IDisposable
{
    readonly Timer timer;
    int ticks;

    public Metronome() => timer = new Timer(_ => Interlocked.Increment(ref ticks), null, 0, 10);

    public string Name => "C";

    public string Run(string json) => "metronome started";

    public void Dispose() => timer.Dispose();
}
