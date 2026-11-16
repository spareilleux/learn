using System.Globalization;
using Fretboard;

// A small command-line tool on top of the library: the first argument is the command
const string Usage = "usage: fret <open-string-hz> <fret> | transpose <semitones> <notes...> | projects <file.csv>";

if (args.Length == 0)
{
    Console.Error.WriteLine(Usage);
    return 1;
}

try
{
    switch (args[0])
    {
        case "fret" when args.Length == 3:
            double openString = double.Parse(args[1], CultureInfo.InvariantCulture);
            int fret = Guitar.ParseFret(args[2]);
            Console.WriteLine(Guitar.FretFrequency(openString, fret).ToString(CultureInfo.InvariantCulture));
            return 0;

        case "transpose" when args.Length >= 3:
            List<string> notes = [.. args[2..]];
            Console.WriteLine(string.Join(" ", Guitar.Transpose(notes, int.Parse(args[1]))));
            return 0;

        case "projects" when args.Length == 2:
            List<Project> projects = await ProjectFile.ReadAsync(args[1]);
            Console.WriteLine($"{projects.Count} projects, {projects.Sum(p => p.SourceFiles)} source files");
            return 0;

        default:
            Console.Error.WriteLine(Usage);
            return 1;
    }
}
catch (Exception e) when (e is FormatException or ArgumentException or IOException)
{
    // A message and exit code 1: a script that runs the tool sees that it failed
    Console.Error.WriteLine($"error: {e.Message}");
    return 1;
}
