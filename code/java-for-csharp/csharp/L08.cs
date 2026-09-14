// Lesson 8: C# patterns that Java lacks, and the ones it shares.
static class L08
{
    record Point(double X, double Y);

    record Order(string Customer, double Total, List<string> Items);

    static string Sign(int n) => n switch
    {
        < 0 => "negative",
        0 => "zero",
        _ => "positive",
    };

    static string Size(Order order) => order switch
    {
        { Items.Count: 0 } => "empty",
        { Total: > 1000 } => "large",
        { Customer: "ada" or "alan", Total: >= 100 and <= 1000 } => "regular customer",
        _ => "normal",
    };

    static string Shape(int[] values) => values switch
    {
        [] => "empty",
        [var only] => $"one: {only}",
        [var first, .., var last] => $"from {first} to {last}",
    };

    public static void Run()
    {
        Console.WriteLine($"{Sign(-3)} {Sign(0)} {Sign(8)}");
        Console.WriteLine(Size(new Order("ada", 50, [])));
        Console.WriteLine(Size(new Order("grace", 1500, ["gpu"])));
        Console.WriteLine(Size(new Order("alan", 250, ["desk"])));
        Console.WriteLine(Shape([]) + " | " + Shape([7]) + " | " + Shape([1, 2, 3]));

        object value = new Point(0, 2);
        if (value is Point { X: 0 } p) Console.WriteLine($"on the Y axis at {p.Y}");
        if (value is Point(var x, var y)) Console.WriteLine($"deconstructed {x}, {y}");
        if (value is not null) Console.WriteLine("not null");
    }
}
