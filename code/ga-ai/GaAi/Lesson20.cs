namespace GaAi;

// Lesson 20: ga_generate_progression, the MCP tool that writes a chord progression from one of nine
// templates in a given key. The program spells every template in the keys a textbook writes,
// compares the tool with GA's own twelve-key tables, tries the roots and lengths it takes, and
// stitches each template with ga_voice_leading_pair, as the tool's answer suggests.
public static class Lesson20
{
    public static void Run()
    {
        Lesson4.EnsureIndex();
        SearchIndex.Use(Lesson3.IndexPath);
        var yaml = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".ga",
            "Common", "GA.Business.Config", "ChordProgressions.yaml"));
        ProgressionProbe.TemplatesTable("at the pin");
        ProgressionProbe.YamlTables(yaml, "at the pin");
        ProgressionProbe.RootsTable("at the pin");
        ProgressionProbe.LengthTable("at the pin");
        ProgressionProbe.StitchTable("at the pin");
    }
}
