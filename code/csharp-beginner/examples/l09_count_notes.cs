// How many times each note appears in the first phrase of Beethoven's Ode to Joy
string[] melody = ["E", "E", "F", "G", "G", "F", "E", "D", "C", "C", "D", "E", "E", "D", "D"];

var counts = new Dictionary<string, int>();
foreach (string note in melody)
{
    counts[note] = counts.GetValueOrDefault(note) + 1;   // 0 + 1 the first time
}

foreach (var (note, count) in counts)
{
    Console.WriteLine($"{note}: {count}");
}
