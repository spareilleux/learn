// Lesson 6: delegates, closures and events on the C# side.
static class L06
{
    class PriceFeed
    {
        public event Action<double>? PriceChanged;

        public void Publish(double price) => PriceChanged?.Invoke(price);

        public int ListenerCount => PriceChanged?.GetInvocationList().Length ?? 0;
    }

    class Display
    {
        public void OnPrice(double price) => Console.WriteLine($"display: {price}");
    }

    public static void Run()
    {
        // Since C# 10 a lambda has a natural type.
        var length = (string s) => s.Length;
        Console.WriteLine(length.GetType().Name);

        // A for loop shares one variable across iterations; foreach gets a fresh one.
        var fromFor = new List<Func<int>>();
        for (int i = 0; i < 3; i++) fromFor.Add(() => i);
        Console.WriteLine(string.Join(" ", fromFor.Select(f => f())));
        var fromForeach = new List<Func<int>>();
        foreach (var value in new[] { 0, 1, 2 }) fromForeach.Add(() => value);
        Console.WriteLine(string.Join(" ", fromForeach.Select(f => f())));

        // Closures capture variables: the lambda can change a local.
        int clicks = 0;
        Action click = () => clicks++;
        click();
        click();
        Console.WriteLine($"clicks: {clicks}");

        // Delegates are multicast and compare by target and method.
        Action hello = () => Console.Write("hello ");
        Action world = () => Console.WriteLine("world");
        (hello + world)();

        var feed = new PriceFeed();
        var display = new Display();
        feed.PriceChanged += display.OnPrice;
        feed.Publish(10.5);
        Action<double> first = display.OnPrice;
        Action<double> second = display.OnPrice;
        Console.WriteLine($"equal: {first.Equals(second)}");
        feed.PriceChanged -= display.OnPrice;
        Console.WriteLine($"listeners: {feed.ListenerCount}");
    }
}
