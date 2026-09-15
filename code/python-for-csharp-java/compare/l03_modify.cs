// compare/l03_modify.cs
var stock = new Dictionary<string, int> { ["capo"] = 2, ["strings"] = 0, ["picks"] = 50, ["tuner"] = 0 };

// Since .NET Core 3.0, Remove during the enumeration of a Dictionary is allowed
foreach (var (name, count) in stock)
{
    if (count == 0) stock.Remove(name);
}
Console.WriteLine(string.Join(", ", stock.Keys));

var tuning = new List<string> { "E", "A", "D", "G", "B", "E" };
try
{
    foreach (var note in tuning)
    {
        if (note == "E") tuning.Remove(note);
    }
}
catch (InvalidOperationException e)
{
    Console.WriteLine($"{e.GetType().Name}: {e.Message}");
}

// GetRange copies, like a Python slice
var bass = tuning.GetRange(0, 3);
bass[0] = "D";
Console.WriteLine($"{string.Join(" ", bass)} | {string.Join(" ", tuning)}");
