#:project ../.ga/Common/GA.Domain.Core/GA.Domain.Core.csproj
// Probe of Guitar Alchemist for lesson 8 of C# for beginners, at GA commit 5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26.
// Experiment 2: what Fret does with an out-of-range number, through its four entry points.
// Experiment 3: PositionLocation(Str, Fret) called with two plain ints, in both orders.
// The journal's 2026-10-02 entry records the hypotheses written before measuring; results.txt holds the output.
//
//   git -C <ga clone> worktree add --no-checkout --detach ../.ga 5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26
//   git -C ../.ga checkout 5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26 -- Directory.Build.props Directory.Build.targets global.json .editorconfig Common/GA.Domain.Core Common/GA.Core Common/GA.Business.Config
//   dotnet build probe.cs
//   dotnet run --no-build probe.cs > results.txt
using GA.Domain.Core.Instruments.Positions;
using GA.Domain.Core.Instruments.Primitives;

Console.WriteLine("=== Experiment 2: Fret with out-of-range numbers ===");
foreach (var n in new[] { 50, -2 })
{
    Console.WriteLine();
    Console.WriteLine($"--- n = {n}");
    Attempt($"new Fret({n})", () => new Fret(n));
    Attempt($"Fret.FromValue({n})", () => Fret.FromValue(n));
    Attempt($"Fret f = {n}; (implicit conversion)", () =>
    {
        Fret f = n;
        return f;
    });

    var result = Fret.TryCreate(n);
    Console.WriteLine($"Fret.TryCreate({n})");
    Console.WriteLine($"    IsSuccess: {result.IsSuccess}");
    Console.WriteLine($"    ToString(): {result}");
    if (result.IsFailure)
    {
        Console.WriteLine($"    GetErrorOrThrow(): {result.GetErrorOrThrow()}");
    }
}

Console.WriteLine();
Console.WriteLine("=== Experiment 3: PositionLocation with plain ints ===");
var asWritten = new PositionLocation(3, 5);
var swapped = new PositionLocation(5, 3);
Show("new PositionLocation(3, 5)", asWritten);
Show("new PositionLocation(5, 3)", swapped);
Console.WriteLine($"asWritten == swapped: {asWritten == swapped}");

static void Attempt(string path, Func<Fret> create)
{
    Console.WriteLine(path);
    try
    {
        var fret = create();
        Console.WriteLine($"    no exception; ToString(): {fret}; Value: {fret.Value}");
    }
    catch (ArgumentOutOfRangeException ex)
    {
        Console.WriteLine($"    exception type: {ex.GetType().FullName}");
        Console.WriteLine($"    Message: {ex.Message}");
        Console.WriteLine($"    ParamName: {ex.ParamName ?? "(null)"}");
        Console.WriteLine($"    ActualValue: {ex.ActualValue ?? "(null)"}");
        PrintGaFrames(ex);
    }
    catch (Exception ex)
    {
        Console.WriteLine($"    exception type: {ex.GetType().FullName}");
        Console.WriteLine($"    Message: {ex.Message}");
        PrintGaFrames(ex);
    }
}

// The stack frames inside GA, with the file name and line kept and the directory dropped.
static void PrintGaFrames(Exception ex)
{
    foreach (var raw in (ex.StackTrace ?? "").Split('\n'))
    {
        var frame = raw.Trim();
        if (!frame.Contains(" GA.")) continue;
        var inIndex = frame.IndexOf(" in ", StringComparison.Ordinal);
        if (inIndex >= 0)
        {
            var location = frame[(inIndex + 4)..];
            var file = location[(location.LastIndexOfAny(['\\', '/']) + 1)..];
            frame = frame[..inIndex] + " in " + file;
        }
        Console.WriteLine($"    frame: {frame}");
    }
}

static void Show(string call, PositionLocation p) =>
    Console.WriteLine(
        $"{call} -> ToString(): {p}; Str: {p.Str} (Value {p.Str.Value}); Fret: {p.Fret} (Value {p.Fret.Value})");
