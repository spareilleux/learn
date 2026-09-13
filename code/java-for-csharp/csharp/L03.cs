// Lesson 3: records, enums and virtual dispatch on the C# side.
static class L03
{
    record Point(int X, int Y);

    // Exercise 1 starts from this C# record.
    public record Product(string Name, decimal Price)
    {
        public string Name { get; } = !string.IsNullOrWhiteSpace(Name) ? Name : throw new ArgumentException("name required");
        public decimal Price { get; } = Price >= 0 ? Price : throw new ArgumentOutOfRangeException(nameof(Price));
    }

    enum Size { Small, Large }

    class Base
    {
        public string Describe() => "base";              // not virtual
        public virtual string DescribeVirtual() => "base";
    }

    class Derived : Base
    {
        public new string Describe() => "derived";       // hides, does not override
        public override string DescribeVirtual() => "derived";
    }

    public static void Run()
    {
        var p = new Point(3, 4);
        Console.WriteLine(p);
        Console.WriteLine(p with { X = 6 });
        Console.WriteLine(p == new Point(3, 4));

        var size = (Size)42;                              // any int is accepted
        Console.WriteLine(size);
        Console.WriteLine(Enum.IsDefined(size));

        Console.WriteLine(new Product("book", 12.5m));
        try
        {
            _ = new Product(" ", 1m);
        }
        catch (ArgumentException e)
        {
            Console.WriteLine(e.Message);
        }

        Base b = new Derived();
        Console.WriteLine(b.Describe());
        Console.WriteLine(b.DescribeVirtual());
    }
}
