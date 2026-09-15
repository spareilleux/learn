// compare/l03_linq.cs
Chord[] chords =
[
    new("C", "major", ["C", "E", "G"]),
    new("A", "minor", ["A", "C", "E"]),
    new("G", "dominant 7", ["G", "B", "D", "F"]),
    new("E", "minor", ["E", "G", "B"]),
    new("D", "major", ["D", "F#", "A"]),
    new("F", "major 7", ["F", "A", "C", "E"]),
];

var minor = chords.Where(c => c.Quality == "minor").Select(c => $"{c.Root}m");
Console.WriteLine(string.Join(", ", minor));

var sizes = chords.ToDictionary(c => c.Root, c => c.Notes.Length);
Console.WriteLine(string.Join(", ", sizes.Select(pair => $"{pair.Key}: {pair.Value}")));

var allNotes = chords.SelectMany(c => c.Notes).Distinct().Order(StringComparer.Ordinal);
Console.WriteLine(string.Join(", ", allNotes));

Console.WriteLine($"{chords.Any(c => c.Notes.Length == 4)} {chords.All(c => c.Notes.Contains("E"))}");
Console.WriteLine(chords.Sum(c => c.Notes.Length));
var largest = chords.MaxBy(c => c.Notes.Length)!;
Console.WriteLine($"{largest.Root} {largest.Quality}"); // the first of the largest

foreach (var c in chords.OrderByDescending(c => c.Notes.Length).ThenBy(c => c.Root, StringComparer.Ordinal))
{
    Console.WriteLine($"{c.Root,-2} {c.Quality,-11} {string.Join(" ", c.Notes)}");
}

// GroupBy keeps the order in which each key first appears, and doesn't need sorted data
foreach (var group in chords.GroupBy(c => c.Quality))
{
    Console.Write($"{group.Key}: {string.Join(" ", group.Select(c => c.Root))}; ");
}
Console.WriteLine();

record Chord(string Root, string Quality, string[] Notes);
