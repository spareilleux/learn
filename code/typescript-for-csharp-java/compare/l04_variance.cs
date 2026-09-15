// compare/l04_variance.cs
using System.Collections.Generic;

Guitar[] guitars = [new Guitar("guitar")];
Instrument[] instruments = guitars; // arrays are covariant in C# too
try { instruments[0] = new Instrument("piano"); }
catch (ArrayTypeMismatchException e) { Console.WriteLine($"instruments[0] = piano: {e.GetType().Name}"); }

IEnumerable<Instrument> sequence = new List<Guitar> { new("guitar") }; // IEnumerable<out T>
Action<Instrument> play = i => Console.WriteLine($"playing {i.Name}");
Action<Guitar> tune = play; // Action<in T>
tune(new Guitar("guitar"));
Console.WriteLine($"sequence: {string.Join(", ", sequence)}");

record Instrument(string Name);
record Guitar(string Name) : Instrument(Name);
