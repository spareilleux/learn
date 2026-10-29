using System.Reflection;
using Contracts;
using Microsoft.Extensions.DependencyInjection;
using Newtonsoft.Json.Linq;

namespace ModuleA;

public sealed class Module : IModule
{
    public void Register(IServiceCollection services)
    {
        services.AddSingleton<IChordSpeller, Speller>();
        services.AddSingleton<ITool, Spell>();
    }
}

sealed class Spell(IChordSpeller speller) : ITool
{
    public string Name => "A";

    public string Run(string json)
    {
        var chord = (string)JObject.Parse(json)["chord"]!;
        // The package version, and the assembly version the runtime's binder compares
        var assembly = typeof(JObject).Assembly;
        var version = assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()!.InformationalVersion.Split('+')[0];
        return $"{chord} = {string.Join(' ', speller.Spell(chord))} ({assembly.GetName().Name} {version}, assembly version {assembly.GetName().Version})";
    }
}

// Enough of a chord speller for the example: a root with an optional sharp, then one of four qualities
sealed class Speller : IChordSpeller
{
    static readonly string[] Names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

    static readonly Dictionary<string, int[]> Qualities = new()
    {
        [""] = [0, 4, 7], ["m"] = [0, 3, 7], ["7"] = [0, 4, 7, 10], ["maj7"] = [0, 4, 7, 11],
    };

    public string[] Spell(string chord)
    {
        var length = chord.Length > 1 && chord[1] == '#' ? 2 : 1;
        var root = Array.IndexOf(Names, chord[..length]);
        return [.. Qualities[chord[length..]].Select(i => Names[(root + i) % 12])];
    }
}
