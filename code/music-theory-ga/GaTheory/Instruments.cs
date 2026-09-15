namespace GaTheory;

// The course's own reading of GA's Instruments.yaml, used by lessons 8 and 9.
//
// The file is a two-level mapping: an instrument, then one entry per tuning, each with a
// `Tuning:` line holding the pitches separated by spaces. It is not a list, and there is no
// `Instruments:` key — which is what GA's own F# loader looks for. The parser here is a dozen
// lines because the file only ever uses three shapes: `Key: value`, `Key:` opening a mapping,
// and `Icon: |` opening a block of SVG, indented deeper than any key we read.
public static class Instruments
{
    public sealed record Entry(string Instrument, string Variant, string Tuning)
    {
        public string[] Tokens => Tuning.Split(' ', StringSplitOptions.RemoveEmptyEntries);

        // The tokens that are not a pitch: a tuning's name, a separator, a stray number
        public string[] NotPitches => [.. Tokens.Where(token => Instruments.Midi(token) is null)];

        public bool IsValid => NotPitches.Length == 0;

        public int[] MidiNotes() => [.. Tokens.Select(Instruments.Midi).OfType<int>()];

        public override string ToString() => $"{Instrument}.{Variant}";
    }

    // The YAML sits next to the program: GA.Business.Config copies it to the output directory
    public static string Path => System.IO.Path.Combine(AppContext.BaseDirectory, "Instruments.yaml");

    public static IReadOnlyList<Entry> Read()
    {
        var entries = new List<Entry>();
        string instrument = "", variant = "";
        foreach (var raw in File.ReadAllLines(Path))
        {
            var line = raw.TrimEnd();
            if (line.Length == 0) continue;
            var indent = line.Length - line.TrimStart().Length;
            var text = line.TrimStart();
            if (indent == 0 && text.EndsWith(':'))
            {
                instrument = text[..^1];
                variant = "";
            }
            else if (indent == 2 && text.EndsWith(':') && !text.Contains(' '))
            {
                variant = text[..^1];
            }
            else if (indent == 4 && text.StartsWith("Tuning:") && variant.Length > 0)
            {
                entries.Add(new Entry(instrument, variant, text["Tuning:".Length..].Trim()));
            }
        }
        return entries;
    }

    // A pitch name with an octave, or null: the file also holds tuning names ("C6", "E9"), the
    // word "Tuning", an instrument name and a "|" separating a harp guitar's sub-bass strings
    public static int? Midi(string token)
    {
        if (token.Length < 2 || token[0] < 'A' || token[0] > 'G') return null;
        var rest = token[1..];
        var accidental = rest.Length > 0 && rest[0] is '#' or 'b' or 'x' ? 1 : 0;
        if (!int.TryParse(rest[accidental..], out _)) return null;
        return Theory.MidiOf(token);
    }

    // Semitones between consecutive pitches as written, string to string
    public static int[] Steps(IReadOnlyList<int> midi) =>
        [.. midi.Skip(1).Select((m, i) => m - midi[i])];

    // A tuning is re-entrant when its pitches, in string order, neither only rise nor only fall
    public static bool IsReentrant(IReadOnlyList<int> midi)
    {
        var steps = Steps(midi);
        return steps.Any(s => s > 0) && steps.Any(s => s < 0);
    }
}
