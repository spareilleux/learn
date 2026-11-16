// The order of a foreach over a dictionary: remove a key, add another
var semitones = new Dictionary<string, int> { ["C"] = 0, ["D"] = 2, ["E"] = 4, ["G"] = 7, ["A"] = 9 };
Console.WriteLine(string.Join(" ", semitones.Keys));

semitones.Remove("D");
semitones.Add("F#", 6);
Console.WriteLine(string.Join(" ", semitones.Keys));
