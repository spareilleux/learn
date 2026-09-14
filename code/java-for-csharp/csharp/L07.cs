// Lesson 7: collections and LINQ on the C# side.
static class L07
{
    record Order(string Customer, string Product, int Quantity, double Price)
    {
        public double Total => Quantity * Price;
    }

    static readonly List<Order> Orders =
    [
        new("ada", "keyboard", 1, 80.0),
        new("alan", "mouse", 2, 25.0),
        new("ada", "monitor", 2, 199.0),
        new("grace", "mouse", 1, 25.0),
        new("alan", "cable", 5, 4.5),
    ];

    static void Attempt(string label, Action action)
    {
        try
        {
            action();
            Console.WriteLine($"{label}: ok");
        }
        catch (Exception e)
        {
            Console.WriteLine($"{label}: {e.GetType().Name}: {e.Message}");
        }
    }

    public static void Run()
    {
        // The indexer throws for a missing key.
        var stock = new Dictionary<string, int> { ["apples"] = 3 };
        Attempt("indexer", () => Console.WriteLine(stock["pears"]));
        Console.WriteLine(stock.GetValueOrDefault("pears"));

        var numbers = new List<int> { 1, 2, 3, 4, 5, 6 };
        Attempt("remove in foreach", () =>
        {
            foreach (var n in numbers)
                if (n % 2 == 0) numbers.Remove(n);
        });

        var bigOrders = Orders.Where(o => o.Total >= 50)
            .OrderByDescending(o => o.Total)
            .Select(o => $"{o.Customer}:{o.Product}")
            .ToList();
        Console.WriteLine(string.Join(", ", bigOrders));

        // An IEnumerable can be enumerated again: the query simply runs twice.
        var query = Orders.Select(o => o.Product);
        Console.WriteLine($"{query.Count()} {query.Count()}");

        Console.WriteLine(string.Join(" | ", Enumerable.Range(1, 7).Chunk(3).Select(c => string.Join(",", c))));
        Console.WriteLine(string.Join(", ", Orders.Select(o => o.Product).Zip(Orders.Select(o => o.Quantity), (p, q) => $"{p}x{q}")));

        Attempt("ToDictionary", () => Orders.ToDictionary(o => o.Customer, o => o.Product));
    }
}
