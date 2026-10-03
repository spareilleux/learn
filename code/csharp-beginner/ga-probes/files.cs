#:project ../.ga/Common/GA.Domain.Services/GA.Domain.Services.csproj
// Probe of Guitar Alchemist for lesson 10 of C# for beginners, at GA commit 5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26:
// where GA looks for its data files, and what it does when it doesn't find them.
// a. IconicChordsConfigLoader.FindYamlFile (Common/GA.Business.Config/Configuration/IconicChordsConfigLoader.cs:91)
//    tries four paths; LoadConfiguration (line 16) swallows a failure and returns one default chord.
// b. ReloadConfiguration (line 107) sets a static readonly field by reflection.
// c. ScaleVideoUrlById (Common/GA.Domain.Core/Theory/Tonal/Scales/ScaleVideoUrlById.cs:27) reads an embedded resource,
//    then a file next to the assembly.
// With --without-yaml, the probe first deletes the YAML files next to itself, as if the build hadn't copied them.
// See README.md for the three runs and their outputs.
#pragma warning disable CS0618 // ScaleVideoUrlById is [Obsolete], but ScaleMetadataRegistry.GetMetadata still calls it
using System.Reflection;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Tonal.Scales;
using GA.Domain.Services;

Console.Out.NewLine = "\n";
string here = AppContext.BaseDirectory;

if (args.Contains("--without-yaml"))
{
    foreach (string yaml in Directory.GetFiles(here, "*.yaml"))
    {
        File.Delete(yaml);
    }
}

Console.WriteLine("=== a. IconicChords.yaml: the four paths that FindYamlFile tries, in order ===");
string cwd = Directory.GetCurrentDirectory();
(string Name, string Path)[] candidates =
[
    ("next to the program", Path.Combine(here, "IconicChords.yaml")),
    ("in the current directory", Path.Combine(cwd, "IconicChords.yaml")),
    ("in <current directory>/Common/GA.Business.Config", Path.Combine(cwd, "Common", "GA.Business.Config", "IconicChords.yaml")),
    ("four folders above the program, then Common/GA.Business.Config",
        Path.Combine(here, "..", "..", "..", "..", "Common", "GA.Business.Config", "IconicChords.yaml")),
];
foreach (var (name, path) in candidates)
{
    Console.WriteLine($"{name}: {(File.Exists(path) ? "found" : "not found")}");
}
var chords = IconicChordsConfigLoader.Configuration.IconicChords;
Console.WriteLine($"Iconic chords loaded: {chords.Count}, the first one: {chords[0].Name}");

Console.WriteLine();
Console.WriteLine("=== b. IconicChordsConfigLoader.ReloadConfiguration() ===");
try
{
    IconicChordsConfigLoader.ReloadConfiguration();
    Console.WriteLine("no exception");
}
catch (Exception ex)
{
    Console.WriteLine($"{ex.GetType().Name}: {ex.Message}");
}

Console.WriteLine();
Console.WriteLine("=== c. ScaleVideoUrlById ===");
Assembly domainCore = typeof(PitchClassSet).Assembly;
string[] resources = domainCore.GetManifestResourceNames();
Console.WriteLine($"GA.Domain.Core resources: {resources.Length}, named *scale_video_urls*: {resources.Count(r => r.Contains("scale_video_urls"))}");
string fallback = Path.Combine(Path.GetDirectoryName(domainCore.Location) ?? "", "Scales", "Data", "scale_video_urls.json");
Console.WriteLine($"Fallback file next to the assembly: {(File.Exists(fallback) ? "found" : "not found")}");
Console.WriteLine($"Scales with a video URL: {ScaleVideoUrlById.ValidScaleNumbers.Count}");
