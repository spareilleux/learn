using System.Globalization;

GuitarString lowE = new GuitarString("E2", 82.41);
GuitarString a = new GuitarString("A2", 110.0);

Console.WriteLine($"{lowE.Name}: {lowE.FrequencyAt(12).ToString("F2", CultureInfo.InvariantCulture)} Hz");
Console.WriteLine($"Created: {GuitarString.CreatedCount}");

GuitarString sameString = lowE;
sameString.Rename("E2 (retuned)");
Console.WriteLine(lowE.Name);
Console.WriteLine(a.Name);

sealed class GuitarString
{
    private readonly double _openHz;

    public string Name { get; private set; }
    public double OpenHz => _openHz;
    public static int CreatedCount { get; private set; }

    public GuitarString(string name, double openHz)
    {
        Name = name;
        _openHz = openHz;
        CreatedCount++;
    }

    public void Rename(string name) => Name = name;

    public double FrequencyAt(int fret) => _openHz * Math.Pow(2, fret / 12.0);
}
