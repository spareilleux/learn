using Microsoft.Extensions.DependencyInjection;

namespace Contracts;

// What the host and every module share. It loads once, in the host's context, so that a module's ITool is the host's.
public interface IModule
{
    void Register(IServiceCollection services);
}

public interface ITool
{
    string Name { get; }
    string Run(string json);
}

// A service that one module provides and another consumes: the interface lives here, its implementation in module A.
public interface IChordSpeller
{
    string[] Spell(string chord);
}
