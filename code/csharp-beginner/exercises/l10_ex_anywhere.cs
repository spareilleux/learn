// Exercise 4: find data/ga-projects.csv from the program's folder, and say so clearly when it isn't there
string folder = (string)AppContext.GetData("EntryPointFileDirectoryPath")!;
string path = Path.GetFullPath(Path.Combine(folder, "..", "data", "ga-projects.csv"));

if (!File.Exists(path))
{
    Console.WriteLine($"Can't find {path}");
    return 1;
}

string[] lines = File.ReadAllLines(path);
int fsharp = lines.Skip(1).Count(line => line.Split(',')[1] == "F#");
Console.WriteLine($"{lines.Length - 1} projects in {Path.GetFileName(path)}, {fsharp} in F#");
return 0;
