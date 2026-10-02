#:project ../.ga/Common/GA.Domain.Services/GA.Domain.Services.csproj
// Probe of Guitar Alchemist for lesson 9 of C# for beginners, at GA commit 5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26.
// MusicalKnowledgeService.GetArtistBreakdown() (Common/GA.Business.Config/Configuration/MusicalKnowledgeService.cs:222)
// counts the entries of GetAllArtists().Take(20) // Top 20 artists, then sorts those 20 by count.
// GetAllArtists() (line 118) ends with OrderBy(a => a): which 20 does it keep, and does it miss bigger ones?
// GetStatistics() (line 72) exposes the result as ArtistBreakdown. artists-results.txt holds the output.
//
//   git -C <ga clone> archive 5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26 Directory.Build.props Directory.Build.targets global.json .editorconfig Common/GA.Domain.Services Common/GA.Business.Config Common/GA.Core Common/GA.Domain.Core Common/GA.Domain.Repositories Common/GA.Business.Core | tar -x -C ../.ga
//   dotnet build artists.cs
//   dotnet run --no-build artists.cs > artists-results.txt
using System.Globalization;
using GA.Domain.Services;

// The same line endings on every OS, so that two outputs compare with a plain diff.
Console.Out.NewLine = "\n";

// OrderBy(a => a) compares strings with the current culture's rules.
Console.WriteLine($"CurrentCulture: {CultureInfo.CurrentCulture.Name}");

// a. Each loader falls back to a one-item default when it can't find or can't read its YAML file:
//    a count of 1 would measure that default, not GA's data.
Console.WriteLine();
Console.WriteLine("=== a. Items loaded by each service ===");
Loaded("IconicChords.yaml", IconicChordsService.GetAllChords().Count(), IconicChordsService.GetAllArtists().Count());
Loaded("ChordProgressions.yaml", ChordProgressionsService.GetAllProgressions().Count(),
    ChordProgressionsService.GetAllArtists().Count());
Loaded("GuitarTechniques.yaml", GuitarTechniquesService.GetAllTechniques().Count(),
    GuitarTechniquesService.GetAllArtists().Count());
Loaded("SpecializedTunings.yaml", SpecializedTuningsService.GetAllTunings().Count(),
    SpecializedTuningsService.GetAllArtists().Count());

// b. The artists GetArtistBreakdown() starts from.
var all = MusicalKnowledgeService.GetAllArtists().ToList();
var stats = MusicalKnowledgeService.GetStatistics();
Console.WriteLine();
Console.WriteLine("=== b. Distinct artists ===");
Console.WriteLine($"GetAllArtists().Count(): {all.Count}");
Console.WriteLine($"GetStatistics().UniqueArtists: {stats.UniqueArtists}");

// Every artist's count, with the four calls GetArtistBreakdown() makes.
var counts = new Dictionary<string, int>();
foreach (var artist in all)
{
    counts[artist] = CountFor(artist);
}

// c. What GetArtistBreakdown() keeps: the first 20 in GetAllArtists() order.
var kept = all.Take(20).ToList();
var keptSet = kept.ToHashSet();
var smallestKept = kept.Min(a => counts[a]);
Console.WriteLine();
Console.WriteLine("=== c. GetAllArtists().Take(20), in that order ===");
for (var i = 0; i < kept.Count; i++)
{
    Console.WriteLine($"{i + 1,2}. {counts[kept[i]],3}  {kept[i]}");
}
Console.WriteLine($"Smallest count kept: {smallestKept}");
var ordinalFirst20 = all.Order(StringComparer.Ordinal).Take(20).ToHashSet();
Console.WriteLine($"Same 20 when sorted with StringComparer.Ordinal: {(ordinalFirst20.SetEquals(keptSet) ? "yes" : "no")}");

// d. What GetStatistics() returns, in the order a foreach reads it.
Console.WriteLine();
Console.WriteLine("=== d. GetStatistics().ArtistBreakdown, in enumeration order ===");
var position = 0;
foreach (var pair in stats.ArtistBreakdown)
{
    position++;
    Console.WriteLine($"{position,2}. {pair.Value,3}  {pair.Key}");
}
Console.WriteLine($"Entries: {stats.ArtistBreakdown.Count}");

// e. The 20 artists with the most entries, over all artists.
var ranked = all.OrderByDescending(a => counts[a]).ThenBy(a => a, StringComparer.Ordinal).ToList();
Console.WriteLine();
Console.WriteLine("=== e. Top 20 over all artists, by count descending then name (ordinal) ===");
for (var i = 0; i < 20 && i < ranked.Count; i++)
{
    var mark = keptSet.Contains(ranked[i]) ? "  [kept]" : "";
    Console.WriteLine($"{i + 1,2}. {counts[ranked[i]],3}  {ranked[i]}{mark}");
}
if (ranked.Count >= 20)
{
    var twentieth = counts[ranked[19]];
    Console.WriteLine(
        $"Count of the 20th: {twentieth}; artists with at least that count: {ranked.Count(a => counts[a] >= twentieth)}");
}

// f. Artists GetArtistBreakdown() leaves out although they outnumber one it keeps.
var missed = ranked.Where(a => !keptSet.Contains(a) && counts[a] > smallestKept).ToList();
Console.WriteLine();
Console.WriteLine($"=== f. Left out of c with a count greater than {smallestKept} ===");
Console.WriteLine($"Number: {missed.Count}");
foreach (var artist in missed)
{
    Console.WriteLine($"{counts[artist],3}  {artist}");
}

static int CountFor(string artist) =>
    IconicChordsService.FindChordsByArtist(artist).Count() +
    ChordProgressionsService.FindProgressionsByArtist(artist).Count() +
    GuitarTechniquesService.FindTechniquesByArtist(artist).Count() +
    SpecializedTuningsService.FindTuningsByArtist(artist).Count();

static void Loaded(string file, int items, int artists) =>
    Console.WriteLine(
        $"{file}: {items} items, {artists} distinct artists; file next to the program: {(File.Exists(Path.Combine(AppContext.BaseDirectory, file)) ? "yes" : "no")}");
