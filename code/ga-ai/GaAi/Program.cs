// GA's AI: run each lesson's code against Guitar Alchemist, pinned on one commit, without network
namespace GaAi;

public static class Entry
{
    public static int Main(string[] args)
    {
        var lessons = new Dictionary<string, Action>
        {
            ["l1"] = Lesson1.Run,
            ["l2"] = Lesson2.Run,
            ["l3"] = Lesson3.Run,
            ["l4"] = Lesson4.Run,
            ["l5"] = Lesson5.Run,
            ["l6"] = Lesson6.Run,
            ["l7"] = Lesson7.Run,
            ["l8"] = Lesson8.Run,
            ["l9"] = Lesson9.Run,
            ["l10"] = Lesson10.Run,
            ["l11"] = Lesson11.Run,
            ["l12"] = Lesson12.Run,
            ["l13"] = Lesson13.Run,
            ["l14"] = Lesson14.Run,
            ["l15"] = Lesson15.Run,
            ["l16"] = Lesson16.Run,
            ["l17"] = Lesson17.Run,
            ["l18"] = Lesson18.Run,
            ["l19"] = Lesson19.Run,
            ["l20"] = Lesson20.Run,
            ["l21"] = Lesson21.Run,
            ["l22"] = Lesson22.Run,
            ["l23"] = Lesson23.Run,
            ["l24"] = Lesson24.Run,
            ["l25"] = Lesson25.Run,
        };

        if (args.Length != 1 || !lessons.TryGetValue(args[0], out var run))
        {
            Console.Error.WriteLine($"usage: GaAi <{string.Join("|", lessons.Keys)}>");
            return 2;
        }

        Console.OutputEncoding = System.Text.Encoding.UTF8;
        Console.WriteLine($"# {args[0]}");
        run();
        return 0;
    }
}
