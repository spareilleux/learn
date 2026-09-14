// Runs the C# side of one lesson: dotnet run -- l02
using System.Globalization;

// Culture-sensitive formatting gives the same output on every machine; lesson 12 passes named cultures explicitly.
CultureInfo.DefaultThreadCurrentCulture = CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;

var lessons = new Dictionary<string, Action>
{
    ["l02"] = L02.Run,
    ["l03"] = L03.Run,
    ["l04"] = L04.Run,
    ["l05"] = L05.Run,
    ["l06"] = L06.Run,
    ["l07"] = L07.Run,
    ["l08"] = L08.Run,
    ["l09"] = L09.Run,
    ["l12"] = L12.Run,
};

if (args.Length != 1 || !lessons.TryGetValue(args[0], out var run))
{
    Console.Error.WriteLine($"usage: dotnet run -- <{string.Join('|', lessons.Keys)}>");
    return 2;
}

run();
return 0;
