// Calling the methods declared below
PrintTitle("Methods");
Console.WriteLine(Square(12));
Console.WriteLine(FretFrequency(110.0, 7));
Console.WriteLine(FretFrequency(82.41, 5));
Console.WriteLine(Describe(0));
Console.WriteLine(Describe(12));
Console.WriteLine(Repeat("la"));                 // default value for times
Console.WriteLine(Repeat("la", 3));
Console.WriteLine(Repeat(times: 2, text: "do")); // named arguments, in any order

// A method with no result: its return type is void
void PrintTitle(string title)
{
    Console.WriteLine($"== {title} ==");
}

// A method that returns an int
int Square(int x)
{
    return x * x;
}

// A method with two parameters, rounded to two decimals
double FretFrequency(double openString, int fret)
{
    double frequency = openString * Math.Pow(2, fret / 12.0);
    return Math.Round(frequency, 2);
}

// return leaves the method at once
string Describe(int fret)
{
    if (fret == 0)
    {
        return "open string";
    }
    return $"fret {fret}";
}

// An optional parameter, and a body written as one expression with =>
string Repeat(string text, int times = 2) => string.Concat(Enumerable.Repeat(text, times));
