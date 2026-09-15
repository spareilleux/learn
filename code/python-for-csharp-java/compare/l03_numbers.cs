// compare/l03_numbers.cs
// Integer division truncates toward zero, and % takes the sign of the dividend
Console.WriteLine($"{7 / 2} {-7 / 2} {-7 % 2}");

// Math.Round rounds half to even by default too; decimal is exact for decimal fractions
Console.WriteLine($"{Math.Round(2.5)} {Math.Round(3.5)} {Math.Round(2.5, MidpointRounding.AwayFromZero)}");
Console.WriteLine($"{0.1 + 0.2} {0.1m + 0.2m}");

// int has 32 bits: without checked, it wraps around
int max = int.MaxValue;
Console.WriteLine(max + 1);
