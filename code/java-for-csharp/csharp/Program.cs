// Runs the C# side of one lesson: dotnet run -- l02
var lessons = new Dictionary<string, Action>
{
    ["l02"] = L02.Run,
    ["l03"] = L03.Run,
    ["l04"] = L04.Run,
};

if (args.Length != 1 || !lessons.TryGetValue(args[0], out var run))
{
    Console.Error.WriteLine($"usage: dotnet run -- <{string.Join('|', lessons.Keys)}>");
    return 2;
}

run();
return 0;
