// Exercise 3: fret 7 is a fifth above the open string. How close is 2^(7/12) to 3/2?
double tempered = Math.Pow(2, 7 / 12.0);
double pure = 3.0 / 2.0;
Console.WriteLine($"Equal temperament: {tempered:F5}");
Console.WriteLine($"Pure fifth:        {pure:F5}");
Console.WriteLine($"Difference:        {(pure - tempered) / pure * 100:F3} %");
