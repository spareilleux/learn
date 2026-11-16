// Lesson 4's twelve projects of GuitarAlchemist/ga, as one list of records, queried with LINQ
List<Project> projects =
[
    new Project("GA.Core", "C#"),
    new Project("GA.Domain.Core", "C#"),
    new Project("GA.Business.Config", "F#"),
    new Project("GA.Business.Core", "C#"),
    new Project("GA.Business.DSL", "F#"),
    new Project("GA.Business.AI", "C#"),
    new Project("GA.Business.ML", "C#"),
    new Project("GA.Business.ProbabilisticGrammar", "F#"),
    new Project("GA.Business.Core.Generated", "F#"),
    new Project("GA.Infrastructure", "C#"),
    new Project("GA.Presentation", "C#"),
    new Project("GA.Testing.Semantic", "C#"),
];

int business = projects.Count(p => p.Name.StartsWith("GA.Business."));
Console.WriteLine($"{business} projects start with GA.Business.");

IEnumerable<string> fsharp = projects.Where(p => p.Language == "F#").Select(p => p.Name);
Console.WriteLine($"F#: {string.Join(", ", fsharp)}");

Project longest = projects.OrderByDescending(p => p.Name.Length).First();
Console.WriteLine($"Longest name: {longest.Name}");

Console.WriteLine("Sorted by language, then by name:");
foreach (Project project in projects.OrderBy(p => p.Language).ThenBy(p => p.Name).Take(4))
{
    Console.WriteLine($"  {project.Language} {project.Name}");
}

Console.WriteLine($"Any F#? {projects.Any(p => p.Language == "F#")}");
Console.WriteLine($"All start with GA.? {projects.All(p => p.Name.StartsWith("GA."))}");

Project? rust = projects.FirstOrDefault(p => p.Language == "Rust");
Console.WriteLine(rust?.Name ?? "no Rust project");

List<string> csharp = projects.Where(p => p.Language == "C#").Select(p => p.Name).ToList();
Console.WriteLine($"{csharp.Count} C# projects, the first is {csharp[0]}");

record Project(string Name, string Language);
