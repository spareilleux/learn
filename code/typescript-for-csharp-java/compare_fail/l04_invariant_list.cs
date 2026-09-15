// compare_fail/l04_invariant_list.cs
using System.Collections.Generic;

List<Instrument> instruments = new List<Guitar>();
Console.WriteLine(instruments.Count);

record Instrument(string Name);
record Guitar(string Name) : Instrument(Name);
