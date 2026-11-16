using System.Globalization;
using CsvHelper;

namespace Fretboard;

// Reads a CSV file of projects with the CsvHelper package, which knows about quoted values
public static class ProjectFile
{
    // From any text: a file, or a string in a test
    public static List<Project> Read(TextReader text)
    {
        using var csv = new CsvReader(text, CultureInfo.InvariantCulture);
        return csv.GetRecords<Project>().ToList();
    }

    public static List<Project> Read(string path)
    {
        using var reader = new StreamReader(path);
        return Read(reader);
    }

    // The same, but the program can do something else while the file is read
    public static async Task<List<Project>> ReadAsync(string path)
    {
        string text = await File.ReadAllTextAsync(path);
        return Read(new StringReader(text));
    }
}
