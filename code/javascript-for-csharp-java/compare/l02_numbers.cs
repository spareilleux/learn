// Lesson 2, the C# side: dotnet run l02_numbers.cs (.NET 10)
using System.Globalization;
using System.Numerics;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;

Console.WriteLine($"0.1 + 0.2              {0.1 + 0.2}");
Console.WriteLine($"7 / 2                  {7 / 2}");
Console.WriteLine($"7.0 / 2                {7.0 / 2}");
Console.WriteLine($"1.0 / 0                {1.0 / 0}");
double nan = 0.0 / 0.0;
Console.WriteLine($"NaN == NaN             {nan == 0.0 / 0.0}");
int zero = 0;
try
{
    Console.WriteLine(1 / zero);
}
catch (DivideByZeroException e)
{
    Console.WriteLine($"1 / zero               {e.GetType().Name}: {e.Message}");
}
int max = int.MaxValue;
Console.WriteLine($"int.MaxValue + 1       {unchecked(max + 1)}");
Console.WriteLine($"long.MaxValue          {long.MaxValue}");
Console.WriteLine($"BigInteger.Pow(2, 64)  {BigInteger.Pow(2, 64)}");
Console.WriteLine($"\"1\" + 2                {"1" + 2}");
Console.WriteLine($"guitar emoji .Length    {"🎸".Length}");
Console.WriteLine($"-0.0 == 0.0            {-0.0 == 0.0}");
