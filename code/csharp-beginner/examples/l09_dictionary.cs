// A Dictionary<string, int>: each note's name (the key) gives its number of semitones above C (the value)
var semitones = new Dictionary<string, int>
{
    ["C"] = 0, ["D"] = 2, ["E"] = 4, ["F"] = 5, ["G"] = 7, ["A"] = 9, ["B"] = 11,
};
Console.WriteLine($"{semitones.Count} notes; G is {semitones["G"]} semitones above C");

semitones["F#"] = 6;            // a key that isn't there yet: added
semitones.Add("Bb", 10);        // Add also adds...
try
{
    semitones.Add("C", 0);      // ...but refuses a key that is already there
}
catch (ArgumentException ex)
{
    Console.WriteLine(ex.Message);
}
Console.WriteLine($"{semitones.Count} notes");

Console.WriteLine(semitones.ContainsKey("Bb"));
Console.WriteLine(semitones.ContainsKey("H"));   // H is B in German notation, not a key here

if (semitones.TryGetValue("H", out int h))
{
    Console.WriteLine($"H is {h} semitones above C");
}
else
{
    Console.WriteLine("no H in this dictionary");
}

Console.WriteLine(string.Join(" ", semitones));   // each item is a KeyValuePair<string, int>
