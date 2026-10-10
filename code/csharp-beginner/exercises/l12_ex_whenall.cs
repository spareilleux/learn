// Exercise 2: count the lines of two files read at the same time
string csv = Path.Combine("data", "ga-projects.csv");
string guitar = Path.Combine("l12-project", "Fretboard", "Guitar.cs");

// Task.WhenAll of Task<int> gives an int[], in the order of the tasks
int[] counts = await Task.WhenAll(CountLinesAsync(csv), CountLinesAsync(guitar));
Console.WriteLine($"{Path.GetFileName(csv)}: {counts[0]} lines");
Console.WriteLine($"{Path.GetFileName(guitar)}: {counts[1]} lines");

async Task<int> CountLinesAsync(string path)
{
    string[] lines = await File.ReadAllLinesAsync(path);
    return lines.Length;
}
