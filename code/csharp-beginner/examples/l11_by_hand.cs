// A test by hand: call a method, compare its result with the expected value, and say which check failed
int failed = 0;
Check("fret 12 of A2", FretFrequency(110.0, 12), 220.0);
Check("fret 7 of A2", FretFrequency(110.0, 7), 164.81);
Check("fret 5 of E2", FretFrequency(82.41, 5), 110.0);
Check("fret 1 of B3", FretFrequency(246.94, 1), 261.63);   // C4 in a table of note frequencies
Console.WriteLine($"{failed} failed");

void Check(string name, double actual, double expected)
{
    if (actual == expected)
    {
        Console.WriteLine($"ok   {name}");
    }
    else
    {
        Console.WriteLine($"FAIL {name}: expected {expected}, got {actual}");
        failed++;
    }
}

// Lesson 4's method
double FretFrequency(double openString, int fret)
{
    double frequency = openString * Math.Pow(2, fret / 12.0);
    return Math.Round(frequency, 2);
}
