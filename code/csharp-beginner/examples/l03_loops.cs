// while: repeats as long as the condition is true
int countdown = 3;
while (countdown > 0)
{
    Console.WriteLine($"{countdown}...");
    countdown--;                   // same as countdown = countdown - 1
}
Console.WriteLine("Play!");

// for: start; condition; step
for (int fret = 0; fret <= 12; fret += 3)
{
    Console.Write($"{fret} ");
}
Console.WriteLine();

// foreach: every item of a collection, here every character of a string
foreach (char letter in "EADGBE")
{
    Console.Write($"[{letter}]");
}
Console.WriteLine();

// break leaves the loop, continue goes to the next turn
for (int i = 1; i <= 10; i++)
{
    if (i % 2 == 0)
    {
        continue;                  // skip even numbers
    }
    if (i > 7)
    {
        break;                     // stop after 7
    }
    Console.Write($"{i} ");
}
Console.WriteLine();

// do-while: the block runs at least once, the condition is checked after
int tries = 0;
do
{
    tries++;
    Console.WriteLine($"Try {tries}");
} while (tries < 2);
