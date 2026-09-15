// Exercise 2: read a price and a quantity, print the total with 15% tax
Console.Write("Price of a set of strings? ");
string? priceText = Console.ReadLine();
Console.Write("How many sets? ");
string? quantityText = Console.ReadLine();

bool priceOk = decimal.TryParse(priceText, out decimal price);
bool quantityOk = int.TryParse(quantityText, out int quantity);

if (priceOk && quantityOk)
{
    decimal subtotal = price * quantity;
    decimal tax = Math.Round(subtotal * 0.15m, 2);
    Console.WriteLine($"Subtotal: {subtotal:F2}");
    Console.WriteLine($"Tax: {tax:F2}");
    Console.WriteLine($"Total: {subtotal + tax:F2}");
}
else
{
    Console.WriteLine("Please type a price such as 12.49 and a whole number.");
}
