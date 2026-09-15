// A List<string> grows and shrinks; the type between < > is the type of its items
List<string> chord = ["C", "E", "G"];
Console.WriteLine($"{chord.Count} notes: {string.Join(" ", chord)}");

chord.Add("B");                         // Cmaj7
Console.WriteLine(string.Join(" ", chord));

chord.Insert(1, "D");                   // at index 1, the others move up
Console.WriteLine(string.Join(" ", chord));

chord.Remove("D");                      // removes the first "D" it finds
Console.WriteLine(string.Join(" ", chord));

Console.WriteLine(chord.Contains("G"));
Console.WriteLine(chord.IndexOf("B"));
Console.WriteLine(chord.IndexOf("F#"));  // -1: not in the list

chord[3] = "Bb";                         // C7
Console.WriteLine(string.Join(" ", chord));

chord.RemoveAt(chord.Count - 1);
Console.WriteLine(string.Join(" ", chord));

// An empty list, filled in a loop
List<int> octaves = [];
for (int midi = 12; midi <= 60; midi += 12)
{
    octaves.Add(midi);
}
Console.WriteLine($"The C notes in MIDI numbers: {string.Join(", ", octaves)}");
