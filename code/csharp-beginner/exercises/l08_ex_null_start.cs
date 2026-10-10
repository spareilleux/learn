// Exercise 3, starting point: four warnings, then a crash
string? FindCapo(string song) => song == "Here Comes the Sun" ? "fret 7" : null;

Practice practice = new Practice();
practice.Song = "Blackbird";
string capo = FindCapo(practice.Song);
Console.WriteLine($"{practice.Song}: {capo.ToUpper()}");
Console.WriteLine($"notes: {practice.Notes.Length} letters");

class Practice
{
    public string Song { get; set; }
    public string Notes { get; set; }
}
