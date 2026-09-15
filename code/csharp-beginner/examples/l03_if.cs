int fret = 12;

// A comparison gives a bool: true or false
Console.WriteLine(fret == 12);
Console.WriteLine(fret != 12);
Console.WriteLine(fret > 5 && fret < 10);   // && : both must be true
Console.WriteLine(fret < 1 || fret > 11);   // || : at least one must be true
Console.WriteLine(!(fret > 5));             // !  : the opposite

// if runs a block only when the condition is true
if (fret == 0)
{
    Console.WriteLine("Open string");
}
else if (fret == 12)
{
    Console.WriteLine("One octave above the open string");
}
else
{
    Console.WriteLine("Somewhere else on the neck");
}

// Strings are compared by their content
string tuning = "E A D G B E";
if (tuning == "E A D G B E")
{
    Console.WriteLine("Standard tuning");
}

// A variable declared inside a block only exists in that block
if (fret > 7)
{
    int distance = fret - 7;
    Console.WriteLine($"{distance} frets above the 7th");
}
