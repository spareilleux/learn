using GA.Domain.Core.Instruments;
using GA.Domain.Core.Instruments.Fretboard.Voicings.Core;
using GA.Domain.Core.Instruments.Positions;
using GA.Domain.Core.Instruments.Primitives;
using GA.Domain.Core.Primitives.Notes;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Harmony;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 3: chords, symbols, inversions and voicings on the fretboard
public static class Lesson3
{
    // Chord suffix -> (degree, semitones above the root), stacked in thirds
    public static readonly (string Suffix, (int Degree, int Semitones)[] Tones)[] Chords =
    [
        ("", [(1, 0), (3, 4), (5, 7)]),
        ("m", [(1, 0), (3, 3), (5, 7)]),
        ("dim", [(1, 0), (3, 3), (5, 6)]),
        ("aug", [(1, 0), (3, 4), (5, 8)]),
        ("sus2", [(1, 0), (2, 2), (5, 7)]),
        ("sus4", [(1, 0), (4, 5), (5, 7)]),
        ("6", [(1, 0), (3, 4), (5, 7), (6, 9)]),
        ("7", [(1, 0), (3, 4), (5, 7), (7, 10)]),
        ("maj7", [(1, 0), (3, 4), (5, 7), (7, 11)]),
        ("m7", [(1, 0), (3, 3), (5, 7), (7, 10)]),
        ("m7b5", [(1, 0), (3, 3), (5, 6), (7, 10)]),
        ("dim7", [(1, 0), (3, 3), (5, 6), (7, 9)]),
        ("9", [(1, 0), (3, 4), (5, 7), (7, 10), (9, 14)]),
        ("add9", [(1, 0), (3, 4), (5, 7), (9, 14)]),
    ];

    static string Spelled(string root, (int Degree, int Semitones)[] tones) =>
        string.Join(" ", tones.Select(t => Theory.Spell(root, t.Degree, t.Semitones)));

    static readonly string[] Standard = ["E4", "B3", "G3", "D3", "A2", "E2"];

    // A shape such as "x32010" (string 6 first) -> MIDI notes of the played strings, low to high
    static int[] Played(string shape) =>
        [.. shape.Select((ch, i) => ch == 'x' ? -1 : Theory.MidiOf(Standard[5 - i]) + ch - '0').Where(m => m >= 0)];

    // Name a voicing: try the bass as the root first, then the other notes (slash chord)
    static string NameOf(int[] played)
    {
        var bass = Theory.Mod12(played.Min());
        var pcs = Theory.PitchClasses(Theory.SetId(played));
        foreach (var root in pcs.OrderBy(pc => pc == bass ? 0 : 1))
        {
            var intervals = Theory.SetId(pcs.Select(pc => pc - root));
            var match = Chords.FirstOrDefault(ch => Theory.SetId(ch.Tones.Select(t => t.Semitones)) == intervals);
            if (match.Tones is null) continue;
            return Theory.PcName(root) + match.Suffix + (root == bass ? "" : "/" + Theory.PcName(bass));
        }
        return "(unknown)";
    }

    // GA's catalog matches intervals measured from the lowest note
    static string GaNameOf(int[] played)
    {
        var bass = Theory.Mod12(played.Min());
        var fromBass = Theory.PitchClasses(Theory.SetId(played)).Select(pc => Theory.Mod12(pc - bass)).Order().ToArray();
        return CanonicalChordPatternCatalog.TryFindExact(fromBass)?.Name ?? "(none)";
    }

    // GA prints sharps as ♯ and flats as b: use # for both columns
    static string Ascii(object text) => text.ToString()!.Replace("♯", "#");

    public static void Run()
    {
        Title("Chord symbols on C: pitch classes");
        Columns("symbol", 8, 14);
        foreach (var (suffix, tones) in Chords)
        {
            var pcs = Theory.PitchClasses(Theory.SetId(tones.Select(t => t.Semitones)));
            Row($"C{suffix}", Theory.Format(pcs), Chord.FromSymbol($"C{suffix}").PitchClassSet);
        }

        Title("Pitch classes back to a symbol: GA's ChordFormula.GetSymbolSuffix");
        Columns("symbol", 8, 8);
        foreach (var (suffix, _) in Chords)
        {
            var gaSuffix = Chord.FromSymbol($"C{suffix}").Formula.GetSymbolSuffix();
            Row($"C{suffix}", suffix == "" ? "(major)" : suffix, gaSuffix == "" ? "(major)" : gaSuffix);
        }

        Title("GA's recognition catalog (CanonicalChordPatternCatalog.TryFindExact)");
        foreach (var (suffix, tones) in Chords)
        {
            var intervals = tones.Select(t => Theory.Mod12(t.Semitones)).Order().ToArray();
            Line($"  C{suffix,-6} {string.Join(",", intervals),-12} {CanonicalChordPatternCatalog.TryFindExact(intervals)?.Name ?? "(none)"}");
        }

        Title("Spelling: one letter per chord degree");
        Columns("symbol", 8, 16);
        foreach (var symbol in new[] { "Cm", "Eb", "Ab", "F#", "Bbm7", "Cdim", "Cdim7", "Gb7" })
        {
            var rootLength = symbol.Length > 1 && symbol[1] is '#' or 'b' ? 2 : 1;
            var tones = Chords.Single(c => c.Suffix == symbol[rootLength..]).Tones;
            Row(symbol, Spelled(symbol[..rootLength], tones), Ascii(string.Join(" ", Chord.FromSymbol(symbol).Notes)));
        }

        Title("Inversions of C major");
        Columns("inversion", 10, 30);
        var c = Chord.FromSymbol("C");
        string[] expected = ["C bass C inversion 0 Major", "C/E bass E inversion 1 Major", "C/G bass G inversion 2 Major"];
        for (var i = 0; i < 3; i++)
        {
            var inverted = c.ToInversion(i);
            var slash = i == 0 ? inverted.Symbol : $"{inverted.Symbol}/{inverted.Bass}";
            Row($"{i}", expected[i], $"{slash} bass {inverted.Bass} inversion {inverted.GetInversion()} {inverted.Quality}");
        }

        Title("Voicings: fret numbers from string 6 (low E) to string 1 (high E)");
        Columns("shape", 8, 32);
        foreach (var shape in new[] { "x32010", "032010", "x02210", "022100", "320003", "xx0232", "133211" })
        {
            // course: read the shape low to high
            var frets = shape.Select(ch => ch == 'x' ? -1 : ch - '0').ToArray(); // index 0 = string 6
            var midi = frets.Select((fret, i) => fret < 0 ? -1 : Theory.MidiOf(Standard[5 - i]) + fret).ToArray();
            var played = midi.Where(m => m >= 0).ToArray();
            var fretted = frets.Where(f => f > 0).ToArray();
            var span = fretted.Length == 0 ? 0 : fretted.Max() - fretted.Min();
            var barre = frets.Where(f => f > 0).GroupBy(f => f).Any(g => g.Count() >= 3); // one finger across fretted strings
            var highFirst = string.Join("-", frets.Reverse().Select(f => f < 0 ? "x" : f.ToString()));
            var coursePcs = Theory.Format(Theory.PitchClasses(Theory.SetId(played)));

            // GA: positions and notes in string order 1..6
            var positions = new Position[6];
            for (var s = 1; s <= 6; s++)
            {
                var fret = frets[6 - s];
                positions[s - 1] = fret < 0
                    ? new Position.Muted(new Str(s))
                    : new Position.Played(new PositionLocation(new Str(s), new Fret(fret)), Tuning.Default[new Str(s)].MidiNote + fret);
            }
            var voicing = new Voicing(positions, [.. positions.OfType<Position.Played>().Select(p => p.MidiNote)]);
            var gaPcs = new PitchClassSet(voicing.Notes.Select(n => n.PitchClass));

            Row(shape, $"{highFirst} {coursePcs} span {span}{(barre ? " barre" : "")}",
                $"{voicing.Diagram} {gaPcs} span {voicing.FretSpan}{(voicing.HasBarre() ? " barre" : "")}");
        }

        Title("Naming a voicing: course tries the bass first, GA's catalog reads from the bass");
        foreach (var shape in new[] { "x32010", "032010", "x02210", "022100", "320003", "xx0232", "133211" })
        {
            Line($"  {shape}  course {NameOf(Played(shape)),-6} GA {GaNameOf(Played(shape))}");
        }

        Title("Exercise solutions");
        Columns("question", 16, 20);
        var fSharpDim7 = Chords.Single(ch => ch.Suffix == "dim7").Tones;
        Row("1. F#dim7", Spelled("F#", fSharpDim7), Ascii(string.Join(" ", Chord.FromSymbol("F#dim7").Notes)));
        foreach (var shape in new[] { "x35543", "x02010" })
        {
            var played = Played(shape);
            Line($"2. {shape}  notes {string.Join(" ", played.Select(Theory.PitchName))}  course {NameOf(played)}  GA {GaNameOf(played)}");
        }
    }
}
