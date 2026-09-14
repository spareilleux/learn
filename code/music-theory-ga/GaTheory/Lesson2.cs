using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Tonal.Modes.Diatonic;
using GA.Domain.Core.Theory.Tonal.Scales;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 2: scales, modes and pitch-class sets as 12-bit numbers
public static class Lesson2
{
    public static void Run()
    {
        Title("The major scale from its steps (2 = whole step, 1 = half step)");
        int[] majorSteps = [2, 2, 1, 2, 2, 2, 1];
        var major = Theory.FromSteps(majorSteps);
        var gaMajor = Scale.Major.PitchClassSet;
        Columns("", 10, 22);
        Row("steps", string.Join(" ", majorSteps), string.Join(" ", Theory.Steps(gaMajor.Id.Value)));
        Row("pcs", Theory.Format(Theory.PitchClasses(major)), gaMajor);
        Row("intervals", "P1 M2 M3 P4 P5 M6 M7", string.Join(" ", Scale.Major.Intervals));
        Row("binary", Theory.Binary(major), gaMajor.Id.BinaryValue);
        Row("id", major, gaMajor.Id.Value);

        Title("Scale ids (bit n = pitch class n, root on C)");
        Columns("scale", 16, 6);
        var scales = new (string Name, int[] Steps, Scale Ga, int Root)[]
        {
            ("major", majorSteps, Scale.Major, 0),
            ("natural minor", [2, 1, 2, 2, 1, 2, 2], Scale.NaturalMinor, 9),
            ("harmonic minor", [2, 1, 2, 2, 1, 3, 1], Scale.HarmonicMinor, 9),
            ("melodic minor", [2, 1, 2, 2, 2, 2, 1], Scale.MelodicMinor, 9),
            ("major pentatonic", [2, 2, 3, 2, 3], Scale.MajorPentatonic, 0),
            ("blues", [3, 2, 1, 1, 3, 2], Scale.Blues, 0),
            ("whole tone", [2, 2, 2, 2, 2, 2], Scale.WholeTone, 0),
            ("diminished", [2, 1, 2, 1, 2, 1, 2, 1], Scale.Diminished, 0),
        };
        foreach (var (name, steps, ga, root) in scales)
        {
            // GA spells the minor scales from A: transpose them down to C before reading the id
            Row(name, Theory.FromSteps(steps), ga.PitchClassSet.Id.Transpose(-root).Value);
        }
        Line($"Scale.NaturalMinor as GA stores it (A B C D E F G): id {Scale.NaturalMinor.PitchClassSet.Id.Value}");

        Title("Transposing is rotating the bits");
        Columns("major on", 10, 26);
        foreach (var n in new[] { 0, 2, 7 })
        {
            var id = Theory.Transpose(major, n);
            Row($"T{n} {Theory.PcName(n)}", $"{id} {Theory.Binary(id)}", $"{gaMajor.Id.Transpose(n).Value} {gaMajor.Id.Transpose(n).BinaryValue}");
        }

        Title("Modes of the major scale: rotate, then transpose back to 0");
        Columns("mode", 12, 22);
        foreach (var mode in MajorScaleMode.Items)
        {
            var degree = mode.ParentScaleDegree.Value;
            var steps = majorSteps.Skip(degree - 1).Concat(majorSteps.Take(degree - 1));
            var id = Theory.FromSteps(steps);
            var gaNotes = new PitchClassSet(mode.Notes.Select(note => note.PitchClass));
            var gaId = gaNotes.Id.Transpose(-mode.Notes.First().PitchClass.Value);
            Row(mode.Name, $"{id} {Theory.Format(Theory.PitchClasses(id))}", $"{gaId.Value} {gaId.ToPitchClassSet()}");
        }
        Line("GA's formulas (intervals from the mode's root):");
        foreach (var mode in MajorScaleMode.Items)
        {
            Line($"  {mode.Name,-10} {mode.Formula}");
        }

        Title("How many modes does a scale have?");
        Columns("scale", 16, 6);
        foreach (var (name, steps, _, _) in scales)
        {
            var id = Theory.FromSteps(steps);
            var family = PitchClassSet.FromId(id).ModalFamily;
            Row(name, Theory.Modes(id).Length, family?.Modes.Count);
        }

        Title("Other operations on the bits");
        Columns("major", 12, 22);
        var complement = Theory.Complement(major);
        Row("complement", $"{complement} {Theory.Format(Theory.PitchClasses(complement))}", $"{gaMajor.Complement.Id.Value} {gaMajor.Complement}");
        var inversion = Theory.Invert(major);
        Row("inversion I0", $"{inversion} {Theory.Format(Theory.PitchClasses(inversion))}", $"{gaMajor.Inverse.Id.Value} {gaMajor.Inverse}");
        Row("contains 0", (major & 1) == 1, gaMajor.Id.IsScale);

        Title("Counting");
        Columns("sets", 22, 6);
        Row("all subsets of 12", 1 << 12, PitchClassSetId.Items.Count);
        Row("containing pc 0", Enumerable.Range(0, 1 << 12).Count(id => (id & 1) == 1), Scale.Items.Count);

        Title("Exercise solutions");
        Columns("question", 22, 22);
        int[] minorPentatonic = [3, 2, 2, 3, 2];
        var mp = Theory.FromSteps(minorPentatonic);
        var gaMp = PitchClassSet.Parse("0357T");
        Row("1. minor pentatonic", $"{mp} {Theory.Binary(mp)}", $"{gaMp.Id.Value} {gaMp.Id.BinaryValue}");
        string[] modeNames = ["Ionian", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Aeolian", "Locrian"];
        var degree1717 = Enumerable.Range(1, 7).Single(d => Theory.FromSteps(majorSteps.Skip(d - 1).Concat(majorSteps.Take(d - 1))) == 1717);
        var gaMode1717 = MajorScaleMode.Items.Single(m =>
            new PitchClassSet(m.Notes.Select(n => n.PitchClass)).Id.Transpose(-m.Notes.First().PitchClass.Value).Value == 1717);
        Row("2. mode 1717", modeNames[degree1717 - 1], gaMode1717.Name);
        var pentatonicComplement = Theory.Complement(Theory.FromSteps([2, 2, 3, 2, 3]));
        var key = Enumerable.Range(0, 12).Single(n => Theory.Transpose(major, n) == pentatonicComplement);
        var gaComplement = Scale.MajorPentatonic.PitchClassSet.Complement;
        var gaKey = Enumerable.Range(0, 12).Single(n => gaMajor.Id.Transpose(n) == gaComplement.Id);
        Row("3. complement of 661", $"{Theory.Format(Theory.PitchClasses(pentatonicComplement))} = T{key}", $"{gaComplement} = T{gaKey}");
    }
}
