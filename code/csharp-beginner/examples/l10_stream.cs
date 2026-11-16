// Write line by line with a StreamWriter, then read line by line with File.ReadLines
string path = "frets.txt";

using (StreamWriter writer = new StreamWriter(path))
{
    for (int fret = 0; fret <= 12; fret += 3)
    {
        writer.WriteLine($"Fret {fret}: {110 * Math.Pow(2, fret / 12.0):F1} Hz");
    }
}   // leaving the using block closes the file, even after an exception

// ReadLines reads one line at a time, when the foreach asks for it, like a LINQ query
foreach (string line in File.ReadLines(path))
{
    Console.WriteLine(line);
}
Console.WriteLine($"First line with 220: {File.ReadLines(path).First(l => l.Contains("220"))}");
File.Delete(path);
