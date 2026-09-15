// compare_fail/l01_types.cs
var lines = new[]
{
    new Line("capo", "9.99", 2),
    new Line("strings", 12.5m, 1),
};
foreach (var line in lines)
{
    Console.WriteLine($"{line.Product} {line.Price * 1.15m * line.Quantity}");
}

record Line(string Product, decimal Price, int Quantity);
