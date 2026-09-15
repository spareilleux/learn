// Advanced C#: each lesson prints what it measures; lines starting with "# " depend on the machine
using Advanced;

var lessons = new Dictionary<string, Action>
{
    ["l1"] = Lesson1.Run,
    ["l1-boxing"] = Lesson1.BoxingTable,
    ["l2"] = Lesson2.Run,
    ["l2-modes"] = Lesson2.Modes,
    ["l3"] = Lesson3.Run,
    ["l4"] = Lesson4.Run,
};

if (args.Length != 1 || !lessons.TryGetValue(args[0], out var run))
{
    Console.Error.WriteLine($"usage: Advanced <{string.Join("|", lessons.Keys)}>");
    return 2;
}

Console.WriteLine($"# {args[0]} on .NET {Environment.Version}, {System.Runtime.InteropServices.RuntimeInformation.OSDescription}, {System.Runtime.InteropServices.RuntimeInformation.ProcessArchitecture}");
run();
return 0;
