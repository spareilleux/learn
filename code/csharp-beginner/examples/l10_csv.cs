// Read Guitar Alchemist's projects from a CSV file: one line per project, values separated by commas
string[] lines = File.ReadAllLines(Path.Combine("data", "ga-projects.csv"));
Console.WriteLine($"Header: {lines[0]}");

List<Project> projects = [];
foreach (string line in lines.Skip(1))                   // every line but the header
{
    string[] fields = line.Split(',');
    projects.Add(new Project(fields[0], fields[1], int.Parse(fields[2]), int.Parse(fields[3])));
}
Console.WriteLine($"{projects.Count} projects");

foreach (Project p in projects.OrderByDescending(p => p.CsFiles + p.FsFiles).Take(3))
{
    Console.WriteLine($"{p.Name}: {p.CsFiles + p.FsFiles} files");
}

Console.WriteLine($"C# files in F# projects: {projects.Where(p => p.Language == "F#").Sum(p => p.CsFiles)}");
Console.WriteLine($"Projects without a source file: {string.Join(", ", projects.Where(p => p.CsFiles + p.FsFiles == 0).Select(p => p.Name))}");

record Project(string Name, string Language, int CsFiles, int FsFiles);
