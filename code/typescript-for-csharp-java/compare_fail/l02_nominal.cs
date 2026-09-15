// compare_fail/l02_nominal.cs
Celsius water = new Fahrenheit(212);
Console.WriteLine(water);

record Celsius(double Value);
record Fahrenheit(double Value);
