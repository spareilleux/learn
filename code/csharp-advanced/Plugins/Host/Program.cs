using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.Loader;
using Contracts;
using Microsoft.Extensions.DependencyInjection;

// Appendix 4: plugins without MEF. Each module loads in its own collectible AssemblyLoadContext, registers its services
// in one container, and unloads with its context. The arguments are the modules' main assemblies.
var modules = args.Select(Path.GetFullPath).ToDictionary(path => Path.GetFileNameWithoutExtension(path));

Console.WriteLine("1. Modules A and B: two versions of one library, and a service that B takes from A");
Report(Run([modules["ModuleA"], modules["ModuleB"]], dispose: true));

Console.WriteLine("2. Module B without module A");
Report(Run([modules["ModuleB"]], dispose: true));

Console.WriteLine("3. Module A loaded in two contexts");
TwoCopies(modules["ModuleA"]);

Console.WriteLine("4. Module C, whose tool runs a timer, with the container disposed");
Report(Run([modules["ModuleC"]], dispose: true));

Console.WriteLine("5. Modules A and B, with the container dropped without being disposed");
Report(Run([modules["ModuleA"], modules["ModuleB"]], dispose: false));

Console.WriteLine("6. Module D, whose timer callback captures nothing, with the container dropped without being disposed");
Report(Run([modules["ModuleD"]], dispose: false));

Console.WriteLine("7. Module C, with the container dropped without being disposed");
Report(Run([modules["ModuleC"]], dispose: false));

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

// Collects until the contexts are gone, or a hundred times 10 ms apart, then says what is still loaded from a module
// context. The documentation's loop stops after ten collections, which module D sometimes needed more than.
static void Report(List<WeakReference> contexts)
{
    var collections = 0;
    for (; collections < 100 && contexts.Any(w => w.IsAlive); collections++)
    {
        GC.Collect();
        GC.WaitForPendingFinalizers();
        if (contexts.Any(w => w.IsAlive))
            Thread.Sleep(10);
    }
    Console.WriteLine($"# {collections} collections");
    var left = AppDomain.CurrentDomain.GetAssemblies()
        .Where(a => AssemblyLoadContext.GetLoadContext(a) is PluginLoadContext)
        .Select(a => a.GetName().Name)
        .Order();
    Console.WriteLine($"   unloaded {contexts.Count(w => !w.IsAlive)} of {contexts.Count} module contexts; still loaded: [{string.Join(", ", left)}]");
}

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
