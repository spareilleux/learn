// Twelve projects of the Common folder of GuitarAlchemist/ga, and their languages,
// copied from code/ladybugdb/data/ga/projects.csv
string[] names =
[
    "GA.Core", "GA.Domain.Core", "GA.Business.Config", "GA.Business.Core",
    "GA.Business.DSL", "GA.Business.AI", "GA.Business.ML", "GA.Business.ProbabilisticGrammar",
    "GA.Business.Core.Generated", "GA.Infrastructure", "GA.Presentation", "GA.Testing.Semantic",
];
string[] languages = ["C#", "C#", "F#", "C#", "F#", "C#", "C#", "F#", "F#", "C#", "C#", "C#"];

Console.WriteLine($"{CountStartingWith(names, "GA.Business.")} projects start with GA.Business.");

List<string> fsharp = ProjectsIn(names, languages, "F#");
Console.WriteLine($"{fsharp.Count} F# projects:");
foreach (string name in fsharp)
{
    Console.WriteLine($"  {name}");
}

Console.WriteLine($"Longest name: {Longest(names)}");

int CountStartingWith(string[] values, string prefix)
{
    int count = 0;
    foreach (string value in values)
    {
        if (value.StartsWith(prefix))
        {
            count++;
        }
    }
    return count;
}

// The two arrays go together: names[i] is written in languages[i]
List<string> ProjectsIn(string[] projectNames, string[] projectLanguages, string language)
{
    List<string> result = [];
    for (int i = 0; i < projectNames.Length; i++)
    {
        if (projectLanguages[i] == language)
        {
            result.Add(projectNames[i]);
        }
    }
    return result;
}

string Longest(string[] values)
{
    string longest = values[0];
    foreach (string value in values)
    {
        if (value.Length > longest.Length)
        {
            longest = value;
        }
    }
    return longest;
}
