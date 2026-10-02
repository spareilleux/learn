// Exercise 2: read frets, one per line, and report the bad ones without stopping
int valid = 0;
int highest = 0;
string? line;
while ((line = Console.ReadLine()) != null)
{
    try
    {
        int fret = ParseFret(line);
        valid++;
        highest = Math.Max(highest, fret);
        Console.WriteLine($"{line}: ok");
    }
    catch (FormatException)
    {
        Console.WriteLine($"{line}: not a number");
    }
    catch (ArgumentOutOfRangeException)
    {
        Console.WriteLine($"{line}: out of range (0 to 24)");
    }
}
Console.WriteLine($"{valid} valid frets, highest {highest}");

int ParseFret(string text)
{
    int fret = int.Parse(text);
    ArgumentOutOfRangeException.ThrowIfNegative(fret);
    ArgumentOutOfRangeException.ThrowIfGreaterThan(fret, 24);
    return fret;
}
