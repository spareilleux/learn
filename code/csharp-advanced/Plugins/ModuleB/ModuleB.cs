using System.Reflection;
using Contracts;
using Microsoft.Extensions.DependencyInjection;
using Newtonsoft.Json.Linq;

namespace ModuleB;

public sealed class Module : IModule
{
    public void Register(IServiceCollection services) => services.AddSingleton<ITool, Descend>();
}

// Takes the chord speller that module A registers: module B never references module A, only the contract
sealed class Descend(IChordSpeller speller) : ITool
{
    public string Name => "B";

    public string Run(string json)
    {
        var chord = (string)JObject.Parse(json)["chord"]!;
        var notes = speller.Spell(chord);
        Array.Reverse(notes);
        var assembly = typeof(JObject).Assembly;
        var version = assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()!.InformationalVersion.Split('+')[0];
        return $"{chord} descending = {string.Join(' ', notes)} ({assembly.GetName().Name} {version}, assembly version {assembly.GetName().Version})";
    }
}
