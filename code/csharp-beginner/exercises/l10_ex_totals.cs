// Exercise 2: the number of source files per language, from data/ga-projects.csv
var files = new Dictionary<string, int>();
foreach (string line in File.ReadLines(Path.Combine("data", "ga-projects.csv")).Skip(1))
{
    string[] fields = line.Split(',');
    string language = fields[1];
    files[language] = files.GetValueOrDefault(language) + int.Parse(fields[2]) + int.Parse(fields[3]);
}

foreach (var pair in files.OrderBy(pair => pair.Key))
{
    Console.WriteLine($"{pair.Key}: {pair.Value} files");
}
