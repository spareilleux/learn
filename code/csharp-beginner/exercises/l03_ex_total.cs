// Exercise 3: add up the practice minutes typed one per line; an empty line ends the input
int total = 0;
int days = 0;
while (true)
{
    string? line = Console.ReadLine();
    if (line == null || line == "")
    {
        break;
    }
    if (!int.TryParse(line, out int minutes) || minutes < 0)
    {
        Console.WriteLine($"Skipped: {line}");
        continue;
    }
    total += minutes;
    days++;
}
Console.WriteLine($"{days} days, {total} minutes, {total / 60} h {total % 60} min");
