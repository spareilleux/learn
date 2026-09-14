using GA.Domain.Core.Instruments;
using GA.Domain.Core.Instruments.Primitives;
using GA.Domain.Core.Primitives.Extensions;
using GA.Domain.Core.Primitives.Intervals;
using GA.Domain.Core.Primitives.Notes;
using GA.Domain.Core.Theory.Atonal;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 1: notes, pitch classes, intervals, the fretboard and tunings
public static class Lesson1
{
    public static void Run()
    {
        Title("Pitches: MIDI number and pitch class (C4 = 60)");
        Columns("pitch", 8);
        foreach (var name in new[] { "E2", "A2", "D3", "G3", "B3", "E4", "C4", "A4", "C#4" })
        {
            var midi = Theory.MidiOf(name);
            var pitch = Pitch.Sharp.Parse(name);
            Row(name, $"midi {midi} pc {Theory.Mod12(midi)}", $"midi {pitch.MidiNote.Value} pc {pitch.PitchClass.Value}");
        }
        Line($"GA prints pitch classes as: {string.Join(" ", PitchClass.Items)}");

        Title("Spellings: many names, one pitch class");
        Columns("note", 8, 6);
        foreach (var name in new[] { "C#", "Db", "B#", "Cb", "E#", "Fb", "Bbb", "Fx" })
        {
            Row(name, Theory.PitchClassOf(name), Note.Accidented.Parse(name, null).PitchClass.Value);
        }

        Title("Intervals: name from the letters, size in semitones, interval class");
        Columns("notes", 8, 14);
        foreach (var (from, to) in new[] { ("C", "E"), ("C", "Eb"), ("C", "D#"), ("C", "G"), ("C", "F#"), ("C", "Gb"), ("B", "F"), ("E", "C") })
        {
            var (name, semitones) = Theory.Interval(from, to);
            var a = Note.Accidented.Parse(from, null);
            var b = Note.Accidented.Parse(to, null);
            var interval = a.GetInterval(b);
            Row($"{from}-{to}", $"{name} {semitones} ic{Theory.IntervalClass(semitones)}",
                $"{interval} {interval.Semitones.Value} ic{a.GetIntervalClass(b).Value}");
        }
        Row("!M3", "m6", !Interval.Simple.Parse("M3", null));

        Title("Standard tuning: string 1 is the highest");
        Columns("string", 8, 10);
        string[] standard = ["E4", "B3", "G3", "D3", "A2", "E2"];
        for (var s = 1; s <= 6; s++)
        {
            Row($"{s}", standard[s - 1], Tuning.Default[new Str(s)]);
        }

        Title("Fretboard: each fret adds one semitone");
        Columns("string/fret", 12, 12);
        var fretboard = Fretboard.Default;
        foreach (var (s, fret) in new[] { (6, 0), (6, 3), (5, 3), (2, 1), (3, 5), (1, 8), (4, 10) })
        {
            var midi = Theory.MidiOf(standard[s - 1]) + fret;
            var gaMidi = Tuning.Default[new Str(s)].MidiNote + fret;
            var gaNote = fretboard.GetNote(s - 1, fret);
            Row($"{s}/{fret}", $"{Theory.PitchName(midi)} {midi}", $"{gaNote}{gaMidi.Octave.Value} {gaMidi.Value}");
        }

        Title("Where is pitch class C on frets 0-12? (string/fret)");
        var course = new List<string>();
        for (var s = 6; s >= 1; s--)
        {
            for (var fret = 0; fret <= 12; fret++)
            {
                if (Theory.Mod12(Theory.MidiOf(standard[s - 1]) + fret) == 0) course.Add($"{s}/{fret}");
            }
        }
        string GaPositions(Note note) => string.Join(" ", fretboard.GetPositionsForNote(note)
            .Where(p => p.Location.Fret.Value <= 12)
            .OrderByDescending(p => p.Location.Str.Value).ThenBy(p => p.Location.Fret.Value)
            .Select(p => $"{p.Location.Str.Value}/{p.Location.Fret.Value}")
            .DefaultIfEmpty("(none)"));
        Line($"course              {string.Join(" ", course)}");
        Line($"GA, Note.Chromatic  {GaPositions(Note.Chromatic.C)}");
        Line($"GA, Note.Sharp      {GaPositions(Note.Sharp.C)}");

        Title("Surprises found while writing this lesson");
        Columns("call", 26, 12);
        Row("Pitch.Flat.DFlat(4)", "Db4", Pitch.Flat.DFlat(4));
        Row("Pitch.Flat.GFlat(4)", "Gb4", Pitch.Flat.GFlat(4));
        Row("Pitch.Flat.FFlat(4)", "Fb4", Pitch.Flat.FFlat(4));
        Row("Pitch.Sharp.TryParse Eb2", "rejected", Pitch.Sharp.TryParse("Eb2", null, out var eb2) ? eb2 : "rejected");
        Row("Note.Flat.Parse B", "B", Note.Flat.Parse("B", null));
        Row("PitchClass.Parse A", "9", PitchClass.Parse("A", null).Value);
        Row("IntervalSize.TryParse x", "False", Try(() => SimpleIntervalSize.TryParse("x", null, out _)));

        Title("Exercise solutions");
        Columns("question", 22, 20);
        var a3 = Theory.MidiOf("D3") + 7;
        var gaA3 = Tuning.Default[new Str(4)].MidiNote + 7;
        Row("1. string 4, fret 7", $"{Theory.PitchName(a3)} midi {a3} pc {Theory.Mod12(a3)}", $"{gaA3.ToSharpPitch()} midi {gaA3.Value} pc {gaA3.PitchClass.Value}");
        foreach (var (from, to) in new[] { ("E", "Bb"), ("A", "C#") })
        {
            var (name, semitones) = Theory.Interval(from, to);
            var a = Note.Accidented.Parse(from, null);
            var b = Note.Accidented.Parse(to, null);
            Row($"2. {from}-{to}", $"{name} {semitones} ic{Theory.IntervalClass(semitones)}", $"{a.GetInterval(b)} {a.GetInterval(b).Semitones.Value} ic{a.GetIntervalClass(b).Value}");
        }
        string[] dropD = ["E4", "B3", "G3", "D3", "A2", "D2"];
        var dropDCourse = new List<string>();
        for (var s = 6; s >= 1; s--)
        {
            for (var fret = 0; fret <= 5; fret++)
            {
                if (Theory.Mod12(Theory.MidiOf(dropD[s - 1]) + fret) == 2) dropDCourse.Add($"{s}/{fret}");
            }
        }
        var dropDBoard = new Fretboard(new Tuning(PitchCollection.Parse("D2 A2 D3 G3 B3 E4")), 5);
        var dropDGa = dropDBoard.GetPositionsForNote(Note.Chromatic.D)
            .OrderByDescending(p => p.Location.Str.Value).ThenBy(p => p.Location.Fret.Value)
            .Select(p => $"{p.Location.Str.Value}/{p.Location.Fret.Value}");
        Row("3. D in drop D, 0-5", string.Join(" ", dropDCourse), string.Join(" ", dropDGa));
    }
}
