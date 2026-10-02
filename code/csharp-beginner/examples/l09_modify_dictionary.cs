// A dictionary allows Remove inside its own foreach, but not adding a key
var semitones = new Dictionary<string, int> { ["C"] = 0, ["D"] = 2, ["E"] = 4 };

foreach (var (name, value) in semitones)
{
    if (name == "D")
    {
        semitones.Remove(name);
    }
}
Console.WriteLine($"after Remove: {string.Join(" ", semitones.Keys)}");

try
{
    foreach (var (name, value) in semitones)
    {
        if (name == "C")
        {
            semitones["B"] = 11;
        }
    }
}
catch (InvalidOperationException ex)
{
    Console.WriteLine($"adding a key: {ex.Message}");
}
