using GA.Business.Config;
using GA.Domain.Core.Instruments;
using static GaTheory.Report;

namespace GaTheory;

// Appendix A: GA's whole instrument catalogue, read by the course, next to what GA's own
// configuration loader returns for the same file
public static class Lesson9
{
    public static void Run()
    {
        var catalogue = Instruments.Read();
        var instruments = catalogue.Select(e => e.Instrument).Distinct().ToList();

        Title("Instruments.yaml: what is in the file, and what GA's loader returns");
        Columns("count", 22, 14);
        var loaded = InstrumentsConfig.getAllInstruments().ToList();
        Row("instruments", instruments.Count, loaded.Count);
        Row("tunings", catalogue.Count, loaded.Sum(i => i.Tunings.Length));
        Line();
        Line($"GA returns: {string.Join("; ", loaded.Select(i => $"{i.Name} ({string.Join(", ", i.Tunings.Select(t => $"{t.Name} = {t.Tuning}"))})"))}");
        Line("That is InstrumentsConfig's built-in fallback, not the file. The file is found and read:");
        Line($"  the loader locates it at {(ConfigFileLocator.findFile("Instruments.yaml") is { } path && path.Value.Length > 0 ? "a path next to the program" : "(not found)")}");
        Line("  and then deserialises it into a record with one field, `Instruments`, which the file has no key for,");
        Line("  so the result is empty or the deserialiser throws, and both paths fall back to the two guitar tunings.");

        Title("Tunings the course cannot read as pitches");
        Headings("entry", "tuning as written", "not a pitch", 34, 38);
        foreach (var entry in catalogue.Where(e => !e.IsValid))
        {
            Plain(entry.ToString(), entry.Tuning, string.Join(" ", entry.NotPitches));
        }

        Title("Instruments with two entries for the same tuning name");
        Headings("tuning", "entries", "", 32, 66);
        foreach (var group in catalogue.GroupBy(e => e.Tuning).Where(g => g.Count() > 1).OrderByDescending(g => g.Count()).ThenBy(g => g.Key, StringComparer.Ordinal).Take(12))
        {
            Plain(group.Key, string.Join(", ", group.Select(e => e.ToString())));
        }

        Title("How many pitches each tuning lists");
        Headings("pitches", "tunings", "first three", 8, 8);
        foreach (var group in catalogue.GroupBy(e => e.Tokens.Length).OrderBy(g => g.Key))
        {
            Plain(group.Key.ToString(), group.Count().ToString(), string.Join(", ", group.Take(3).Select(e => e.ToString())));
        }

        Title("Every instrument and every tuning");
        Headings("instrument", "tuning", "pitches", 22, 34);
        foreach (var instrument in instruments)
        {
            var first = true;
            foreach (var entry in catalogue.Where(e => e.Instrument == instrument))
            {
                Plain(first ? instrument : "", entry.Variant, entry.Tuning);
                first = false;
            }
        }

        Title("The tunings GA's own constants use");
        Columns("constant", 22, 24);
        Row("Tuning.Default", "E2 A2 D3 G3 B3 E4", Tuning.Default);
        Row("Tuning.Ukulele", "G4 C4 E4 A4", Tuning.Ukulele);
        Row("Tuning.Bass", "E1 A1 D2 G2", Tuning.Bass);
        Row("Tuning.Guitar7String", "B1 E2 A2 D3 G3 B3 E4", Tuning.Guitar7String);
        Line();
        Line("Four constants against 280 tunings in the file: everything else needs the catalogue.");
    }
}
