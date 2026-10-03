using System.Globalization;

// Exercise 3: write the tuning to a CSV file that every machine reads the same way, then read it back
string[] notes = ["E2", "A2", "D3", "G3", "B3", "E4"];
double[] hertz = [82.41, 110, 146.83, 196, 246.94, 329.63];

List<string> rows = ["String,Note,Frequency"];
for (int i = 0; i < notes.Length; i++)
{
    rows.Add(string.Create(CultureInfo.InvariantCulture, $"{6 - i},{notes[i]},{hertz[i]:F2}"));
}
File.WriteAllLines("tuning.csv", rows);
Console.Write(File.ReadAllText("tuning.csv"));

double total = 0;
foreach (string line in File.ReadLines("tuning.csv").Skip(1))
{
    total += double.Parse(line.Split(',')[2], CultureInfo.InvariantCulture);
}
Console.WriteLine($"Average: {(total / notes.Length).ToString("F2", CultureInfo.InvariantCulture)} Hz");
File.Delete("tuning.csv");
