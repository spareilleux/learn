Console.Write("What is your name? ");
string? name = Console.ReadLine();

Console.Write("How many years have you played the guitar? ");
string? answer = Console.ReadLine();

if (int.TryParse(answer, out int years))
{
    Console.WriteLine($"Hello {name}, {years} years is {years * 12} months of practice.");
}
else
{
    Console.WriteLine($"Hello {name}, \"{answer}\" is not a whole number.");
}
