// Guess the fret: the loop reads answers until one is right
int secret = 7;
int tries = 0;
bool found = false;

while (!found)
{
    Console.Write("Which fret? ");
    string? line = Console.ReadLine();
    if (line == null)
    {
        Console.WriteLine("No more input.");
        break;
    }
    if (!int.TryParse(line, out int guess))
    {
        Console.WriteLine($"\"{line}\" is not a number.");
        continue;
    }

    tries++;
    if (guess < secret)
    {
        Console.WriteLine("Higher.");
    }
    else if (guess > secret)
    {
        Console.WriteLine("Lower.");
    }
    else
    {
        found = true;
        Console.WriteLine($"Found in {tries} tries.");
    }
}
