---
title: "Appendix 4: plugins without MEF"
description: Four modules loaded by one host, each in its own collectible AssemblyLoadContext, registering their services in one dependency-injection container — two versions of Newtonsoft.Json side by side, a module that uses another module's service without referencing it, one assembly that gives two types, and a timer that keeps its module loaded or not depending on what its callback captures. Seven scenarios, each predicted before it ran, in one output checked on three OSes.
sidebar:
  label: "Appendix 4: plugins without MEF"
  order: 92
---

[MEF](https://learn.microsoft.com/dotnet/framework/mef/), the Managed Extensibility Framework, is how .NET Framework 4 applications found their plugins: parts marked `[Export]` and `[Import]`, a catalog that scans a folder, and a container that wires the parts together. It is still maintained — its lightweight version, [`System.Composition`](https://www.nuget.org/packages/System.Composition), is at 10.0.13 — but a new host usually builds the same thing from two pieces of .NET itself:

- one [`AssemblyLoadContext`](https://learn.microsoft.com/dotnet/api/system.runtime.loader.assemblyloadcontext) per module, which keeps the module's dependencies apart from everyone else's and can be unloaded;
- the [dependency-injection container](../13-dependency-injection-options/) the host already has, in which each module registers what it offers and from which it receives what it needs.

The isolation and the unloading come from the first piece, not from leaving MEF behind: nothing stops a MEF host from loading its parts into collectible contexts as well (not tried here). What the container replaces is MEF's attributes and catalogs.

| Job | MEF | Here |
|---|---|---|
| Find the parts | a `DirectoryCatalog` scans a folder | the host is given each module's main assembly and creates its `IModule` |
| Say what a part offers | `[Export(typeof(ITool))]` | `services.AddSingleton<ITool, Spell>()` in `IModule.Register` |
| Say what a part needs | `[Import]`, `[ImportingConstructor]` | constructor parameters |
| Wire the parts | `CompositionContainer` | `ServiceProvider` |
| Keep each part's dependencies apart | not part of MEF | one `AssemblyLoadContext` per module |
| Unload a part | not part of MEF; in .NET Framework, a whole `AppDomain` | a collectible context, once nothing holds it |

This appendix builds such a host with four small modules and runs seven scenarios. Each hypothesis was written down before its first run, and the [journal](../journal/) keeps them. Every prediction held; one measurement, the number of collections an unload takes, changed the host.

## Running it

```bash
bash code/csharp-advanced/check.sh       # every lesson and appendix, compared with expected/
cd code/csharp-advanced
dotnet build Plugins/Plugins.slnx -c Release
dotnet Plugins/Host/bin/Release/net10.0/Host.dll \
  Plugins/ModuleA/bin/Release/net10.0/ModuleA.dll Plugins/ModuleB/bin/Release/net10.0/ModuleB.dll \
  Plugins/ModuleC/bin/Release/net10.0/ModuleC.dll Plugins/ModuleD/bin/Release/net10.0/ModuleD.dll
```

The host references no module: it is given their main assemblies on the command line, as a configuration file would give them. The code is in [`code/csharp-advanced/Plugins`](https://github.com/spareilleux/learn/tree/main/code/csharp-advanced/Plugins):

```text
Plugins/
├── Plugins.slnx  builds the host and the modules
├── Contracts/    IModule, ITool, IChordSpeller: the only types that cross from one context to another
├── Host/         Program.cs: one context per module, one container, the seven scenarios
├── ModuleA/      a chord speller, and a tool that uses it, with Newtonsoft.Json 13.0.3
├── ModuleB/      a tool that takes module A's speller, with Newtonsoft.Json 13.0.1
├── ModuleC/      a metronome whose tool runs a timer
└── ModuleD/      the same metronome, with a callback that captures nothing
```

```mermaid
flowchart LR
  subgraph default["Default context: the host's"]
    Host
    Contracts["Contracts: IModule, ITool, IChordSpeller"]
    DI["Dependency injection"]
  end
  subgraph ca["Context ModuleA"]
    ModuleA --> NA["Newtonsoft.Json 13.0.3"]
  end
  subgraph cb["Context ModuleB"]
    ModuleB --> NB["Newtonsoft.Json 13.0.1"]
  end
  ModuleA -- "implements IChordSpeller" --> Contracts
  ModuleB -- "asks for IChordSpeller" --> Contracts
```

## Both sides of a module boundary

A module's project file decides what goes into its folder:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <!-- Copies the module's own dependencies next to it and writes the .deps.json that AssemblyDependencyResolver reads -->
    <EnableDynamicLoading>true</EnableDynamicLoading>
  </PropertyGroup>
  <ItemGroup>
    <!-- The contracts come from the host at run time, never from the module's folder -->
    <ProjectReference Include="../Contracts/Contracts.csproj" Private="false" ExcludeAssets="runtime" />
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>
</Project>
```

After a build, `ModuleA/bin/Release/net10.0` holds `ModuleA.dll`, `ModuleA.deps.json`, `ModuleA.runtimeconfig.json`, `ModuleA.pdb` and `Newtonsoft.Json.dll`, and no `Contracts.dll`. These three settings come from Microsoft's [plugin tutorial](https://learn.microsoft.com/dotnet/core/tutorials/creating-app-with-plugin-support).

The host gives each module a context of its own:

```csharp
sealed class PluginLoadContext(string mainAssembly)
    : AssemblyLoadContext(Path.GetFileNameWithoutExtension(mainAssembly), isCollectible: true)
{
    // Loaded once, by the host: a module that brought its own copy would get its own ITool type, which the host's
    // container would not recognise
    static readonly HashSet<string> Shared = ["Contracts", "Microsoft.Extensions.DependencyInjection.Abstractions"];

    readonly AssemblyDependencyResolver resolver = new(mainAssembly);

    // null sends the request to the default context, the host's
    protected override Assembly? Load(AssemblyName name) =>
        Shared.Contains(name.Name!) ? null
        : resolver.ResolveAssemblyToPath(name) is { } path ? LoadFromAssemblyPath(path)
        : null;
}
```

The runtime asks `Load` for each assembly that the module references and that its context hasn't loaded yet. [`AssemblyDependencyResolver`](https://learn.microsoft.com/dotnet/api/system.runtime.loader.assemblydependencyresolver) reads the module's `.deps.json` and answers with a path in the module's folder. Returning `null` passes the request on to the default context, which is how the contracts and the dependency-injection abstractions load once, for everyone.

Then one container for all the modules:

```csharp
// Kept out of line so that no local of the caller holds a module's type or context once it returns
[MethodImpl(MethodImplOptions.NoInlining)]
static List<WeakReference> Run(string[] paths, bool dispose)
{
    var services = new ServiceCollection();
    var contexts = new List<PluginLoadContext>();
    foreach (var path in paths)
    {
        var context = new PluginLoadContext(path);
        contexts.Add(context);
        foreach (var type in context.LoadFromAssemblyPath(path).GetTypes().Where(t => typeof(IModule).IsAssignableFrom(t) && !t.IsAbstract))
        {
            ((IModule)Activator.CreateInstance(type)!).Register(services);
            Console.WriteLine($"   loaded {type.FullName} in context {context.Name}");
        }
    }

    try
    {
        // ValidateOnBuild: a service that no module provides fails here, when the modules are loaded, not at first use
        var provider = services.BuildServiceProvider(new ServiceProviderOptions { ValidateOnBuild = true });
        foreach (var tool in provider.GetServices<ITool>())
            Console.WriteLine($"   {tool.Name}: {tool.Run("""{"chord":"Cmaj7"}""")}");
        if (dispose)
            provider.Dispose();
    }
    catch (AggregateException e)
    {
        Console.WriteLine($"   {e.InnerExceptions.Single().InnerException!.Message}");
    }

    var weak = contexts.Select(c => new WeakReference(c)).ToList();
    contexts.ForEach(c => c.Unload());
    return weak;
}
```

The `NoInlining` method and the weak references follow [How to use and debug assembly unloadability in .NET](https://learn.microsoft.com/dotnet/standard/assembly/unloadability): a context, or a type from it, left in a local of the caller would keep the context loaded.

## 1. Two versions of one library

```text
1. Modules A and B: two versions of one library, and a service that B takes from A
   loaded ModuleA.Module in context ModuleA
   loaded ModuleB.Module in context ModuleB
   A: Cmaj7 = C E G B (Newtonsoft.Json 13.0.3, assembly version 13.0.0.0)
   B: Cmaj7 descending = B G E C (Newtonsoft.Json 13.0.1, assembly version 13.0.0.0)
   unloaded 2 of 2 module contexts; still loaded: []
```

Each module runs the Newtonsoft.Json it was built with. They need two contexts for that: according to [About `AssemblyLoadContext`](https://learn.microsoft.com/dotnet/core/dependency-loading/understanding-assemblyloadcontext), "a single AssemblyLoadContext instance is limited to loading exactly one version of an Assembly per simple assembly name", and a reference is resolved against an assembly already loaded when "the loaded version is equal or higher to the requested version". Both packages carry the assembly version 13.0.0.0, as the output shows. In a single context, module B's request would therefore be met by the 13.0.3 already loaded: no error, just not the code B was built and tested with. That last sentence follows from the documented rule; this appendix doesn't run it.

## 2. A module that uses another module's service

```csharp
// Takes the chord speller that module A registers: module B never references module A, only the contract
sealed class Descend(IChordSpeller speller) : ITool
```

Scenario 1 shows `Descend` receiving module A's speller: `B G E C` is A's spelling, reversed. It works because `IChordSpeller` is a single type for everyone (scenario 3 shows why that matters) and every module registers into the same container. Without module A:

```text
2. Module B without module A
   loaded ModuleB.Module in context ModuleB
   Unable to resolve service for type 'Contracts.IChordSpeller' while attempting to activate 'ModuleB.Descend'.
   unloaded 1 of 1 module contexts; still loaded: []
```

With [`ValidateOnBuild`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.dependencyinjection.serviceprovideroptions.validateonbuild), the missing dependency stops `BuildServiceProvider`, when the modules are loaded, instead of the first request for a tool. The `AggregateException` it throws holds one exception per service that can't be built; this message is the inner one. The failed build holds nothing, and the context still unloads.

## 3. One assembly, two types

```csharp
[MethodImpl(MethodImplOptions.NoInlining)]
static void TwoCopies(string path)
{
    PluginLoadContext first = new(path), second = new(path);
    var a = first.LoadFromAssemblyPath(path).GetType("ModuleA.Module")!;
    var b = second.LoadFromAssemblyPath(path).GetType("ModuleA.Module")!;
    Console.WriteLine($"   ModuleA.Module: same name {a.FullName == b.FullName}, same type {a == b}");
    Console.WriteLine($"   the IModule both implement: same type {a.GetInterface("IModule") == b.GetInterface("IModule")}, the host's {a.GetInterface("IModule") == typeof(IModule)}");
    first.Unload();
    second.Unload();
}
```

```text
3. Module A loaded in two contexts
   ModuleA.Module: same name True, same type False
   the IModule both implement: same type True, the host's True
```

A type is its name *and* the context that loaded it. The same file, loaded twice, gives two `ModuleA.Module` types; the `IModule` they implement is one type, the host's, because both contexts passed `Contracts` on to the default context. That is what the `Shared` list is for: a module that loaded its own `Contracts.dll` would implement an `IModule` that the host's cast and the host's container have never seen.

## 4 to 7. Unloading, and what holds a module

The unloadability article calls unloading "cooperative": `Unload` only starts it, and it finishes once no thread is running the context's code and nothing outside the context references its assemblies, its types or their instances. Module C's tool starts a [`Timer`](https://learn.microsoft.com/dotnet/api/system.threading.timer) and stops it when the container disposes it:

```csharp
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
```

Module D's `Pulse` is the same class with one difference: the counter is static and the callback is `static _ => Interlocked.Increment(ref ticks)`, so it captures nothing.

```text
4. Module C, whose tool runs a timer, with the container disposed
   loaded ModuleC.Module in context ModuleC
   C: metronome started
   unloaded 1 of 1 module contexts; still loaded: []
5. Modules A and B, with the container dropped without being disposed
   loaded ModuleA.Module in context ModuleA
   loaded ModuleB.Module in context ModuleB
   A: Cmaj7 = C E G B (Newtonsoft.Json 13.0.3, assembly version 13.0.0.0)
   B: Cmaj7 descending = B G E C (Newtonsoft.Json 13.0.1, assembly version 13.0.0.0)
   unloaded 2 of 2 module contexts; still loaded: []
6. Module D, whose timer callback captures nothing, with the container dropped without being disposed
   loaded ModuleD.Module in context ModuleD
   D: pulse started
   unloaded 1 of 1 module contexts; still loaded: []
7. Module C, with the container dropped without being disposed
   loaded ModuleC.Module in context ModuleC
   C: metronome started
   unloaded 0 of 1 module contexts; still loaded: [ModuleC]
```

| # | Container | Timer callback | Result | Collections |
|---|---|---|---|---|
| 4 | disposed | captures the metronome | unloaded | 2 |
| 5 | dropped | no timer: the control | unloaded | 2 |
| 6 | dropped | captures nothing | unloaded | 3 |
| 7 | dropped | captures the metronome | still loaded | 100, then the host gives up |

The `Timer` documentation explains the difference between 6 and 7: "As long as you are using a Timer, you must keep a reference to it", and "the fact that a Timer is still active does not prevent it from being collected." Once the container is dropped, module D's `Pulse` and its timer are unreachable; the timer is collected and stops, and the context goes, one collection later than the others. Module C's callback increments a field of the `Metronome`, so it holds the `Metronome`, which holds the timer, while the runtime holds the callback for as long as the timer runs. The timer keeps itself alive through its own callback, and with it the type, the assembly and the context. Scenario 5 rules out the other reading: a container dropped without `Dispose` is not, by itself, what keeps a module loaded.

The article's list of what holds a context names threads and `RegisteredWaitHandle` callbacks, not `Timer`; this case falls under its first item, a reference from outside the context. Two ways out: dispose the container before unloading, since it disposes the singletons it created (scenario 4, and [lesson 13](../13-dependency-injection-options/)), or let the module stop its own work in the context's [`Unloading`](https://learn.microsoft.com/dotnet/api/system.runtime.loader.assemblyloadcontext.unloading) event.

The last column changed the host. The article's waiting loop stops after ten collections, run back to back. Module D unloaded within ten in 36 runs out of 40; in the other four, its context was still alive when the loop gave up. With 10 ms between collections, three were enough in 40 runs out of 40: what D waits for is time, not collections. The host now collects up to a hundred times, 10 ms apart, and prints the count on a line starting with `# `, which `check.sh` shows without comparing it.

## The same thing in Java

- [`ServiceLoader`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/ServiceLoader.html), "a facility to load implementations of a service", finds the providers: it plays the catalog's part, and the module's `Register` method.
- One [`URLClassLoader`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/net/URLClassLoader.html) per plugin plays the context's part. Java's [`ClassLoader`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ClassLoader.html) asks its parent first, so a plugin that needs its own version of a library the host also has needs a child-first loader; here, `Load` is asked first, and the shared list is the exception.
- Identity is the same rule: the [JVM specification, §5.3](https://docs.oracle.com/javase/specs/jvms/se25/html/jvms-5.html#jvms-5.3), says a class is "determined not by its name alone, but by a pair: its binary name … and its defining class loader". The Java form of scenario 3 is a `ClassCastException` between two classes with the same name.
- Unloading is cooperative too: per the [Java Language Specification, §12.7](https://docs.oracle.com/javase/specs/jls/se25/html/jls-12.html#jls-12.7), a class "may be unloaded if and only if its defining class loader may be reclaimed by the garbage collector".

## What this appendix doesn't cover

- A configuration file that lists the modules, and replacing a module while the host runs: not tried.
- Native dependencies, through `LoadUnmanagedDll`: not tried.
- MEF parts loaded into collectible contexts: not tried.
- The reference chain that holds module C was not dumped with `dotnet-dump`'s `gcroot`: the page reads it from scenarios 6 and 7. *To verify.*
- The counts were measured on the author's Windows machine, then found identical in CI's first run on Linux, macOS and Windows (2, 2, 2, 2, 3 and 100 collections): one run each, so a slower runner could still need more.
