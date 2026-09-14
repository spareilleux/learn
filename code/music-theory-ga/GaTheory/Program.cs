// Music theory for Guitar Alchemist: recompute each lesson's concepts and compare them with GA
using GaTheory;

var lessons = new Dictionary<string, Action>
{
    ["l1"] = Lesson1.Run,
    ["l2"] = Lesson2.Run,
    ["l3"] = Lesson3.Run,
    ["l4"] = Lesson4.Run,
};

if (args.Length != 1 || !lessons.TryGetValue(args[0], out var run))
{
    Console.Error.WriteLine($"usage: GaTheory <{string.Join("|", lessons.Keys)}>");
    return 2;
}

Console.OutputEncoding = System.Text.Encoding.UTF8;
Console.WriteLine($"# {args[0]}");
run();
return 0;
