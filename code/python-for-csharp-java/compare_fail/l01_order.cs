// compare_fail/l01_order.cs
Console.WriteLine($"capo {LineTotal("capo", 9.99, 2)}");
Console.WriteLine($"strings {LineTotal("strings", "12.50", 1)}");

static double WithTax(double price) => price + price * 0.15;

static double LineTotal(string product, double price, int quantity)
{
    if (quantity > 10)
    {
        return WithTax(price) * quantity * discount;
    }
    return WithTax(price) * quantity;
}
