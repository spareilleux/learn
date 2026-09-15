// Music theory for Guitar Alchemist: recompute each lesson's concepts and compare them with GA
using GaTheory;

var lessons = new Dictionary<string, Action>
{
    ["l1"] = Lesson1.Run,
    ["l2"] = Lesson2.Run,
    ["l3"] = Lesson3.Run,
    ["l4"] = Lesson4.Run,
    ["l5"] = Lesson5.Run,
    ["l6"] = Lesson6.Run,
    ["l7"] = Lesson7.Run,
};

Console.OutputEncoding = System.Text.Encoding.UTF8;

// `svg <dir> [--check]` writes the lessons' diagrams, or checks that the files in <dir> are up to date
if (args.Length is 2 or 3 && args[0] == "svg")
{
    return Diagrams.Run(args[1], check: args.Length == 3 && args[2] == "--check");
}

if (args.Length != 1 || !lessons.TryGetValue(args[0], out var run))
{
    Console.Error.WriteLine($"usage: GaTheory <{string.Join("|", lessons.Keys)}> | svg <dir> [--check]");
    return 2;
}

Console.WriteLine($"# {args[0]}");
run();
return 0;
