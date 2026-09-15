using GA.Domain.Core.Instruments;
using GA.Domain.Core.Instruments.Primitives;
using GA.Domain.Core.Primitives.Notes;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 8: the ukulele and the bass — re-entrant tunings, tunings in fourths, and what
// stops being true when the instrument is not a six-string guitar
public static class Lesson8
{
    // Written low string to high string, the way GA's Instruments.yaml writes them
    static readonly string[] Guitar = ["E2", "A2", "D3", "G3", "B3", "E4"];
    static readonly string[] GuitarTopFour = ["D3", "G3", "B3", "E4"];
    static readonly string[] GuitarBottomFour = ["E2", "A2", "D3", "G3"];
    static readonly string[] UkuleleLowG = ["G3", "C4", "E4", "A4"];
    static readonly string[] Ukulele = ["G4", "C4", "E4", "A4"];
    static readonly string[] Baritone = ["D3", "G3", "B3", "E4"];
    static readonly string[] Bass = ["E1", "A1", "D2", "G2"];

    static int[] Midi(IEnumerable<string> pitches) => [.. pitches.Select(Theory.MidiOf)];

    static string Names(IEnumerable<int> midi) => string.Join(" ", midi.Select(Theory.PitchName));

    static string Steps(IEnumerable<string> pitches) => string.Join(" ", Instruments.Steps(Midi(pitches)));

    public static void Run()
    {
        Title("Tunings: the ukulele and the bass, string 1 first");
        Columns("string", 12, 12);
        for (var s = 1; s <= 4; s++)
        {
            Row($"ukulele {s}", Ukulele[4 - s], Tuning.Ukulele[new Str(s)]);
        }
        for (var s = 1; s <= 4; s++)
        {
            Row($"bass {s}", Bass[4 - s], Tuning.Bass[new Str(s)]);
        }

        Title("Re-entrant: on a ukulele the fourth string is not the lowest");
        Columns("string", 12, 14);
        for (var s = 1; s <= 4; s++)
        {
            var pitch = Tuning.Ukulele[new Str(s)];
            var course = Ukulele[4 - s];
            Row($"ukulele {s}", $"{course} midi {Theory.MidiOf(course)}", $"{pitch} midi {pitch.MidiNote.Value}");
        }
        Line($"steps from string 4 to string 1: {Steps(Ukulele)}  (the negative step is what makes it re-entrant)");
        Line($"the low G ukulele instead:      {Steps(UkuleleLowG)}  (only rising: not re-entrant)");

        Title("How GA decides which end of a tuning is string 1");
        Columns("instrument", 22, 16);
        // Tuning.BuildPitchArray reverses the list when its first pitch is lower than its last one.
        // It compares the two ends only, so a re-entrant tuning can defeat the test.
        foreach (var (name, written, stringOne) in new[]
        {
            ("guitar", "E2 A2 D3 G3 B3 E4", "E4"),
            ("ukulele", "G4 C4 E4 A4", "A4"),
            ("bass", "E1 A1 D2 G2", "G2"),
            ("banjo, tenor jazz", "C3 G3 D4 A4", "A4"),
            ("banjo, 5 strings", "G4 D3 G3 B3 D4", "D4"),
            ("banjo, C tuning", "G4 C3 G3 B3 D4", "D4"),
        })
        {
            Row(name, stringOne, new Tuning(PitchCollection.Parse(written))[new Str(1)]);
        }
        var banjo = new Tuning(PitchCollection.Parse("G4 D3 G3 B3 D4"));
        Line($"GA, banjo strings 1 to 5: {string.Join(" ", Enumerable.Range(1, 5).Select(s => banjo[new Str(s)].ToString()))}");
        Line("The fifth string of a 5-string banjo is the short drone, the highest of the five, so");
        Line("\"string 1 is the highest\" is not a definition: here GA returns the file's order, reversed.");

        Title("The ukulele has the interval pattern of four guitar strings");
        Headings("instrument", "tuning", "steps between strings", 24, 22);
        foreach (var (name, pitches) in new[]
        {
            ("guitar, strings 4 to 1", GuitarTopFour),
            ("ukulele, low G", UkuleleLowG),
            ("ukulele, baritone", Baritone),
            ("guitar, strings 6 to 3", GuitarBottomFour),
            ("bass", Bass),
        })
        {
            Plain(name, string.Join(" ", pitches), Steps(pitches));
        }
        Plain("ukulele - guitar", string.Join(" ", UkuleleLowG.Select((p, i) => Theory.MidiOf(p) - Theory.MidiOf(GuitarTopFour[i]))), "semitones, string by string");
        Plain("baritone - guitar", string.Join(" ", Baritone.Select((p, i) => Theory.MidiOf(p) - Theory.MidiOf(GuitarTopFour[i]))), "semitones");
        Plain("bass - guitar 6 to 3", string.Join(" ", Bass.Select((p, i) => Theory.MidiOf(p) - Theory.MidiOf(GuitarBottomFour[i]))), "semitones");

        Title("A guitar shape played on a ukulele: the same fingers, a fourth higher");
        Headings("instrument", "sounds", "pitch classes", 24, 22);
        // the top four strings of the open C chord: frets on strings 4, 3, 2, 1
        int[] shape = [2, 0, 1, 0];
        int[] Played(string[] tuning) => [.. shape.Select((fret, i) => Theory.MidiOf(tuning[i]) + fret)];
        var onGuitar = Played(GuitarTopFour);
        var onUkulele = Played(UkuleleLowG);
        string Classes(int[] midi) => Theory.Format(midi.Select(Theory.Mod12).Distinct().Order());
        Plain("guitar, strings 4 to 1", Names(onGuitar), $"{Classes(onGuitar)}  C major");
        Plain("ukulele, low G", Names(onUkulele), $"{Classes(onUkulele)}  F major");
        Plain("ukulele, re-entrant", Names(Played(Ukulele)), $"{Classes(Played(Ukulele))}  F major");
        Plain("difference", string.Join(" ", onUkulele.Select((m, i) => m - onGuitar[i])), "semitones: a perfect fourth");
        Line("The re-entrant ukulele plays the same four pitch classes, with its bass note an octave up.");

        Title("Pitch class C on frets 0 to 12");
        Columns("instrument", 12, 34);
        foreach (var (name, tuning, board) in new[]
        {
            ("ukulele", Ukulele, new Fretboard(Tuning.Ukulele, 12)),
            ("bass", Bass, new Fretboard(Tuning.Bass, 12)),
        })
        {
            var course = new List<string>();
            for (var s = tuning.Length; s >= 1; s--)
            {
                for (var fret = 0; fret <= 12; fret++)
                {
                    if (Theory.Mod12(Theory.MidiOf(tuning[tuning.Length - s]) + fret) == 0) course.Add($"{s}/{fret}");
                }
            }
            var ga = board.GetPositionsForNote(Note.Chromatic.C)
                .OrderByDescending(p => p.Location.Str.Value).ThenBy(p => p.Location.Fret.Value)
                .Select(p => $"{p.Location.Str.Value}/{p.Location.Fret.Value}");
            Row(name, string.Join(" ", course), string.Join(" ", ga));
        }

        Title("A bass is tuned in fourths: one shape, every pair of strings");
        Headings("pair", "semitones", "interval", 16, 12);
        foreach (var (name, tuning) in new[] { ("bass", Bass), ("guitar", Guitar) })
        {
            for (var low = 0; low + 1 < tuning.Length; low++)
            {
                var semitones = Theory.MidiOf(tuning[low + 1]) - Theory.MidiOf(tuning[low]);
                Plain($"{name} {tuning.Length - low}-{tuning.Length - low - 1}", semitones, semitones == 5 ? "a fourth" : "a major third");
            }
        }
        Line("Every pair on the bass is a fourth, so a shape keeps its sound on any pair of strings.");
        Line("On the guitar the 3-2 pair is a major third: that one gap is what makes the shapes irregular.");

        Title("The ukulele and the bass in GA's Instruments.yaml");
        Headings("entry", "tuning as written", "read by the course", 36, 30);
        var catalogue = Instruments.Read();
        foreach (var entry in catalogue.Where(e => e.Instrument.Contains("kulele") || e.Instrument.Contains("Bass")))
        {
            var notes = entry.IsValid ? $"{entry.Tokens.Length} pitches" : $"not a pitch: {string.Join(" ", entry.NotPitches)}";
            Plain(entry.ToString(), entry.Tuning, notes);
        }
        Line();
        Line($"GA's own constants: Tuning.Ukulele = {Tuning.Ukulele} ({Tuning.Ukulele.StringCount} strings), " +
             $"Tuning.Bass = {Tuning.Bass} ({Tuning.Bass.StringCount} strings)");
        Line("A ukulele has four strings: in the five C6 and D6 entries, the tuning's name, C or D, is written as a pitch.");
        Line("A baritone ukulele is tuned like the guitar's top four strings, D3 G3 B3 E4; the two entries");
        Line($"disagree with each other and with that: {catalogue.First(e => e is { Instrument: "Ukulele", Variant: "Baritone" }).Tuning}" +
             $" and {catalogue.First(e => e is { Instrument: "BaritoneUkulele", Variant: "Standard" }).Tuning}.");

        Title("Exercise solutions");
        Headings("question", "answer", "", 28, 30);
        int[] openC = [0, 0, 0, 3];
        var sounds = openC.Select((fret, i) => Theory.MidiOf(Ukulele[i]) + fret).ToArray();
        Plain("1. ukulele 0003", Names(sounds), $"pitch classes {Classes(sounds)}: C major");
        var onBaritone = openC.Select((fret, i) => Theory.MidiOf(Baritone[i]) + fret).ToArray();
        Plain("2. 0003 on a baritone", Names(onBaritone), $"pitch classes {Classes(onBaritone)}: G major");
        var readable = catalogue.Where(e => e.IsValid && e.Tokens.Length >= 3).ToList();
        var reentrant = readable.Where(e => Instruments.IsReentrant(e.MidiNotes())).ToList();
        Plain("3. re-entrant entries", $"{reentrant.Count} of {readable.Count}", "tunings that rise and fall");
        Line($"   first ten: {string.Join(", ", reentrant.Take(10))}");
    }
}
