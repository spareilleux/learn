#:package System.Reactive@7.0.0
// The .NET side of lesson 2: when does the work start, for Task, IAsyncEnumerable and IObservable?
using System.Reactive.Linq;

static string LookUp(string root, string mode)
{
    Console.WriteLine($"  looking up {root} {mode}");
    return $"{root} {mode}";
}

// A Task is hot: calling the method starts the work, and awaiting it twice doesn't run it again.
Console.WriteLine("Task:");
Task<string> task = Task.Run(() => LookUp("E", "phrygian"));
await task;
Console.WriteLine($"  awaited twice, same result: {ReferenceEquals(await task, await task)}");

// An IAsyncEnumerable is lazy: nothing runs until the enumeration, and each enumeration runs again.
static async IAsyncEnumerable<string> Dorian()
{
    await Task.Yield();
    yield return LookUp("D", "dorian");
}
Console.WriteLine("IAsyncEnumerable:");
var dorian = Dorian();
Console.WriteLine("  created, not enumerated");
await foreach (var scale in dorian) Console.WriteLine($"  got {scale}");
await foreach (var scale in dorian) Console.WriteLine($"  got {scale}");

// .NET 10 ships LINQ for IAsyncEnumerable in the framework (System.Linq.AsyncEnumerable).
var roots = new[] { "C", "G", "D", "A" }.ToAsyncEnumerable();
Console.WriteLine($"  LINQ: {string.Join(" ", await roots.Where(r => r != "G").Select(r => r + "m").ToListAsync())}");

// Rx.NET is Reactor's closest relative: Observable.Return takes a value, Observable.Defer postpones it.
Console.WriteLine("Observable.Return:");
var eager = Observable.Return(LookUp("F", "lydian"));
Console.WriteLine("  created, no subscriber yet");
Console.WriteLine("Observable.Defer:");
var deferred = Observable.Defer(() => Observable.Return(LookUp("G", "mixolydian")));
Console.WriteLine("  created, no subscriber yet");
await deferred;
await eager;
