using System.IO.Compression;

// Exercise 4: what dotnet pack put in the library's package, which is a zip file
string package = Path.Combine("l12-project", "Fretboard", "bin", "Release", "Fretboard.1.0.0.nupkg");
using ZipArchive zip = ZipFile.OpenRead(package);
foreach (ZipArchiveEntry entry in zip.Entries)
{
    // The name of this metadata file is random: print a placeholder instead
    string name = entry.FullName.EndsWith(".psmdcp") ? "package/services/metadata/core-properties/(random).psmdcp" : entry.FullName;
    Console.WriteLine(name);
}

// The packages that a project installing Fretboard gets too
using StreamReader nuspec = new StreamReader(zip.GetEntry("Fretboard.nuspec")!.Open());
foreach (string line in nuspec.ReadToEnd().Split('\n').Where(line => line.Contains("<dependency ")))
{
    Console.WriteLine(line.Trim());
}
