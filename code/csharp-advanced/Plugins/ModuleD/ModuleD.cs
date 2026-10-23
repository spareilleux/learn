using Contracts;
using Microsoft.Extensions.DependencyInjection;

namespace ModuleD;

public sealed class Module : IModule
{
    public void Register(IServiceCollection services) => services.AddSingleton<ITool, Pulse>();
}

// Module C's metronome with one difference: the callback is static and captures nothing, so it doesn't hold the Pulse
sealed class Pulse : ITool, IDisposable
{
    static int ticks;
    readonly Timer timer;

    public Pulse() => timer = new Timer(static _ => Interlocked.Increment(ref ticks), null, 0, 10);

    public string Name => "D";

    public string Run(string json) => "pulse started";

    public void Dispose() => timer.Dispose();
}
