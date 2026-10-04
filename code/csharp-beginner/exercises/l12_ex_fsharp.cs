#:package CsvHelper@33.1.0
using System.Globalization;
using CsvHelper;

// Exercise 1: the F# projects of data/ga-projects.csv, read with CsvHelper in a file-based app
using var reader = new StreamReader(Path.Combine("data", "ga-projects.csv"));
using var csv = new CsvReader(reader, CultureInfo.InvariantCulture);
foreach (Project project in csv.GetRecords<Project>().Where(p => p.Language == "F#"))
{
    Console.WriteLine($"{project.Name}: F# {project.FsFiles}, C# {project.CsFiles}");
}

record Project(string Name, string Language, int CsFiles, int FsFiles);
