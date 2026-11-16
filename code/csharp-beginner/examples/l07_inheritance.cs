// Guitar and Ukulele derive from StringInstrument: they inherit its members
List<StringInstrument> instruments = [new Guitar(), new Ukulele()];

foreach (StringInstrument instrument in instruments)
{
    // The variable's type is StringInstrument; the object's class picks the Describe that runs
    Console.WriteLine(instrument.Describe());
}

Guitar guitar = new Guitar();
Console.WriteLine($"{guitar.Name} has {guitar.StringCount} strings and {guitar.FretCount} frets");
Console.WriteLine(guitar);                  // Console.WriteLine calls the ToString override

class StringInstrument
{
    public string Name { get; }
    public string[] Tuning { get; }

    public StringInstrument(string name, string[] tuning)
    {
        Name = name;
        Tuning = tuning;
    }

    public int StringCount => Tuning.Length;

    public virtual string Describe() => $"{Name}: {string.Join(" ", Tuning)}";

    public override string ToString() => $"{Name} ({StringCount} strings)";
}

sealed class Guitar : StringInstrument
{
    public int FretCount => 22;

    public Guitar() : base("Guitar", ["E2", "A2", "D3", "G3", "B3", "E4"])
    {
    }
}

sealed class Ukulele : StringInstrument
{
    public Ukulele() : base("Ukulele", ["G4", "C4", "E4", "A4"])
    {
    }

    public override string Describe() => base.Describe() + ", re-entrant: G4 is above C4";
}
