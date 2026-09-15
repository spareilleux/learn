using GA.Domain.Core.Theory.Atonal;
using static GaTheory.Report;

namespace GaTheory;

// Appendix B: the OPTIC hierarchy — from one fingering up to a set class, one equivalence at a
// time (octave, permutation, cardinality, transposition, inversion), counting what each rung
// identifies, and naming GA's type at each level
public static class Lesson10
{
    // The open C chord, string 6 to string 1, and the guitar in standard tuning
    const string Shape = "x32010";
    static readonly string[] Standard = ["E2", "A2", "D3", "G3", "B3", "E4"];

    static int[] Pitches(string shape) =>
        [.. shape.Select((ch, s) => (ch, s)).Where(p => p.ch != 'x').Select(p => Theory.MidiOf(Standard[p.s]) + p.ch - '0')];

    // Every way of playing exactly these pitch classes, one note per played string, frets 0 to 4
    static int CountFingerings(int setId, int frets)
    {
        var count = 0;
        var strings = Standard.Length;
        void Walk(int s, int mask, int played)
        {
            if (s == strings)
            {
                if (mask == setId && played >= 3) count++;
                return;
            }
            Walk(s + 1, mask, played); // muted
            for (var fret = 0; fret <= frets; fret++)
            {
                var pc = Theory.Mod12(Theory.MidiOf(Standard[s]) + fret);
                if ((setId >> pc & 1) == 1) Walk(s + 1, mask | 1 << pc, played + 1);
            }
        }
        Walk(0, 0, 0);
        return count;
    }

    public static void Run()
    {
        var pitches = Pitches(Shape);
        var pitchClasses = pitches.Select(Theory.Mod12).ToArray();
        var set = Theory.SetId(pitchClasses);
        var ga = PitchClassSet.FromId(set);

        Title("One fingering, climbed rung by rung");
        Headings("rung", "the object", "what it forgets", 26, 34);
        Plain("a fingering", Shape, "nothing: strings, frets, muted strings");
        Plain("the pitches", string.Join(" ", pitches.Select(Theory.PitchName)), "which string each note was played on");
        Plain("- O, octave", string.Join(" ", pitchClasses), "the octave of each note");
        Plain("- P, permutation", string.Join(" ", pitchClasses.Order()), "the order of the notes");
        Plain("- C, cardinality", Theory.Format(pitchClasses.Distinct().Order()), "doubled notes");
        Plain("- T, transposition", Theory.Format(Theory.Modes(set).First() is var t ? Theory.PitchClasses(t) : []), "which key it is in");
        Plain("- I, inversion", $"({string.Join("", Theory.PrimeForm(set))})", "major against minor");

        Title("What each rung identifies");
        Headings("rung", "distinct objects", "of the C major triad", 26, 20);
        Plain("fingerings, frets 0 to 4", CountFingerings(set, 4), "ways to play these three pitch classes");
        Plain("pitch multisets", pitches.Length, "notes sounding in x32010");
        Plain("the pitch-class set", 1, "0 4 7");
        Plain("- T: transposition class", 1, "one of the 12 major triads");
        Plain("- I: set class", 1, "one of the 24 major and minor triads");

        Title("How many objects there are at each rung");
        Columns("rung", 30, 8);
        Row("pitch-class sets (P, O, C)", 1 << 12, PitchClassSet.Items.Count);
        Row("transposition classes (+T)", Enumerable.Range(0, 1 << 12).Select(id => Theory.Modes(id).FirstOrDefault()).Distinct().Count(), TranspositionClass.Items.Count);
        Row("set classes (+I)", Enumerable.Range(0, 1 << 12).Select(id => string.Join("", Theory.PrimeForm(id))).Distinct().Count(), SetClass.Items.Count);
        Row("cardinalities (+C)", 13, Enumerable.Range(0, 1 << 12).Select(id => Theory.PitchClasses(id).Length).Distinct().Count());

        Title("The same climb for four chords");
        Headings("chord", "pitch classes", "transposition class / set class", 14, 18);
        foreach (var (name, shape) in new[] { ("C", "x32010"), ("A minor", "x02210"), ("G", "320003"), ("F", "133211") })
        {
            var pcs = Pitches(shape).Select(Theory.Mod12).Distinct().Order().ToArray();
            var id = Theory.SetId(pcs);
            Plain(name, Theory.Format(pcs), $"{Theory.Format(Theory.PitchClasses(Theory.Modes(id).First()))}  /  ({string.Join("", Theory.PrimeForm(id))})");
        }
        Line("C and G are different chords, the same transposition class, the same set class.");
        Line("C and A minor are different transposition classes and the same set class: I joins them.");

        Title("GA's types, one per rung");
        Columns("rung", 26, 26);
        Row("- O, P, C: a set", $"id {set}: {Theory.Format(Theory.PitchClasses(set))}", $"id {ga.Id.Value}: {Theory.Format(ga.Select(pc => pc.Value))}");
        Row("cardinality", pitchClasses.Distinct().Count(), ga.Cardinality.Value);
        Row("- I: prime form", $"({string.Join("", Theory.PrimeForm(set))})", $"({string.Join("", ga.PrimeForm!.Select(pc => pc.Value))})");
        Row("interval-class vector", Theory.FormatIcv(Theory.Icv(set)), ga.IntervalClassVector.ToString());
        var setClass = new SetClass(ga);
        Line($"GA's SetClass for this set: {setClass}");
        Line($"its Forte number: {ForteCatalog.GetForteNumber(setClass.PrimeForm)}");
    }
}
