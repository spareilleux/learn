using System.Diagnostics;
using System.Runtime.CompilerServices;

// Lesson 5: exceptions, using and null on the C# side.
static class L05
{
    sealed class Connection(string name, bool failOnDispose) : IDisposable
    {
        public string Name => name;

        public void Dispose()
        {
            Console.WriteLine($"dispose {name}");
            if (failOnDispose) throw new InvalidOperationException($"dispose failed: {name}");
        }
    }

    // Exercise 2 starts from this C# method.
    static int? ParsePort(string text) =>
        int.TryParse(text, out var port) && port is >= 0 and <= 65535 ? port : null;

    sealed class Resource(string name, List<string> log) : IDisposable
    {
        public string Name => name;

        public void Dispose()
        {
            log.Add($"close {name}");
            throw new InvalidOperationException($"close {name}");
        }
    }

    record Address(string? City);

    record Customer(string Name, Address? Address);

    [MethodImpl(MethodImplOptions.NoInlining)]
    static void FailDeep() => throw new InvalidOperationException("deep failure");

    [MethodImpl(MethodImplOptions.NoInlining)]
    static void RethrowWithVariable()
    {
        try
        {
            FailDeep();
        }
        catch (InvalidOperationException e)
        {
            throw e;                                      // resets the stack trace (warning CA2200)
        }
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    static void RethrowBare()
    {
        try
        {
            FailDeep();
        }
        catch (InvalidOperationException)
        {
            throw;                                        // keeps the stack trace
        }
    }

    static string TopFrame(Exception e) => new StackTrace(e).GetFrame(0)!.GetMethod()!.Name;

    public static void Run()
    {
        // The Dispose exception replaces the body's exception: "query failed" is lost.
        try
        {
            using var db = new Connection("db", true);
            throw new ArgumentException($"query failed on {db.Name}");
        }
        catch (Exception e)
        {
            Console.WriteLine($"caught: {e.Message}");
        }

        try { RethrowWithVariable(); }
        catch (Exception e) { Console.WriteLine($"throw e: thrown in {TopFrame(e)}"); }
        try { RethrowBare(); }
        catch (Exception e) { Console.WriteLine($"throw;  thrown in {TopFrame(e)}"); }

        // Exception filters have no Java equivalent.
        try
        {
            int.Parse("http");
        }
        catch (FormatException e) when (e.Message.Contains("'http'"))
        {
            Console.WriteLine($"filtered: {e.Message}");
        }

        var customers = new Dictionary<string, Customer>
        {
            ["ada"] = new("Ada", new Address("London")),
            ["alan"] = new("Alan", null),
        };
        foreach (var id in new[] { "ada", "alan", "grace" })
        {
            var city = customers.GetValueOrDefault(id)?.Address?.City ?? "unknown";
            Console.WriteLine($"{id} -> {city}");
        }

        try
        {
            Console.WriteLine(customers.GetValueOrDefault("grace")!.Name.Length);
        }
        catch (NullReferenceException e)
        {
            Console.WriteLine(e.Message);
        }

        Console.WriteLine(ParsePort("9090") ?? 8080);
        Console.WriteLine(ParsePort("http") ?? 8080);
        Console.WriteLine(ParsePort("70000") ?? 8080);

        // Exercise 3 in C#: both resources are disposed, the last exception wins.
        var log = new List<string>();
        try
        {
            using var first = new Resource("first", log);
            using var second = new Resource("second", log);
            throw new ArgumentException($"body {first.Name} {second.Name}");
        }
        catch (Exception e)
        {
            Console.WriteLine($"{e.GetType().Name}: {e.Message}; log: {string.Join(", ", log)}");
        }
    }
}
