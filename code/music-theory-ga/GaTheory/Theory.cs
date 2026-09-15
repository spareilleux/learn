// The course's own implementation of the theory, written from the textbook definitions
// and independent of Guitar Alchemist: every lesson compares these results with GA's.
namespace GaTheory;

public static class Theory
{
    // Letters in scale order with their pitch class (C = 0)
    public const string Letters = "CDEFGAB";
    static readonly int[] LetterPc = [0, 2, 4, 5, 7, 9, 11];

    public static int Mod12(int value) => ((value % 12) + 12) % 12;

    // "C#", "Db", "Bbb", "E" -> pitch class
    public static int PitchClassOf(string name)
    {
        var pc = LetterPc[Letters.IndexOf(char.ToUpperInvariant(name[0]))];
        foreach (var c in name[1..])
        {
            pc += c switch { '#' => 1, 'b' => -1, 'x' => 2, _ => throw new FormatException(name) };
        }
        return Mod12(pc);
    }

    // "E2" -> MIDI number, with C4 (middle C) = 60
    public static int MidiOf(string pitch)
    {
        var digits = pitch.IndexOfAny("-0123456789".ToCharArray(), 1);
        var octave = int.Parse(pitch[digits..]);
        var name = pitch[..digits];
        var letterPc = LetterPc[Letters.IndexOf(name[0])];
        var accidental = PitchClassOf(name) - letterPc;
        if (accidental > 6) accidental -= 12;
        if (accidental < -6) accidental += 12;
        return 12 * (octave + 1) + letterPc + accidental;
    }

    static readonly string[] SharpNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

    public static string PitchName(int midi) => $"{SharpNames[Mod12(midi)]}{midi / 12 - 1}";

    public static string PcName(int pc) => SharpNames[Mod12(pc)];

    // A simple interval between two spelled notes: the number comes from the letters, the
    // quality from the semitones (major/perfect reference = the major scale above the lower note)
    public static (string Name, int Semitones) Interval(string from, string to)
    {
        var number = Mod7(Letters.IndexOf(to[0]) - Letters.IndexOf(from[0])) + 1;
        var semitones = Mod12(PitchClassOf(to) - PitchClassOf(from));
        int[] majorOrPerfect = [0, 2, 4, 5, 7, 9, 11];
        var difference = semitones - majorOrPerfect[number - 1];
        if (difference > 6) difference -= 12;
        if (difference < -6) difference += 12;
        var perfect = number is 1 or 4 or 5;
        var quality = (perfect, difference) switch
        {
            (true, 0) => "P",
            (true, -1) => "d",
            (true, 1) => "A",
            (false, 0) => "M",
            (false, -1) => "m",
            (false, -2) => "d",
            (false, 1) => "A",
            _ => "?"
        };
        return ($"{quality}{number}", semitones);
    }

    static int Mod7(int value) => ((value % 7) + 7) % 7;

    public static int IntervalClass(int semitones)
    {
        var s = Mod12(semitones);
        return Math.Min(s, 12 - s);
    }

    // Spell the note `semitones` above `root` on the letter `degree - 1` steps above the root's letter
    public static string Spell(string root, int degree, int semitones)
    {
        var letterIndex = (Letters.IndexOf(root[0]) + degree - 1) % 7;
        var letter = Letters[letterIndex];
        var accidental = Mod12(PitchClassOf(root) + semitones - LetterPc[letterIndex]);
        if (accidental > 6) accidental -= 12;
        return letter + accidental switch
        {
            -2 => "bb", -1 => "b", 0 => "", 1 => "#", 2 => "x", _ => "?"
        };
    }

    // ---- Pitch-class sets as 12-bit numbers (bit n = pitch class n)

    public static int SetId(IEnumerable<int> pitchClasses) =>
        pitchClasses.Aggregate(0, (id, pc) => id | 1 << Mod12(pc));

    public static int[] PitchClasses(int id) => [.. Enumerable.Range(0, 12).Where(pc => (id >> pc & 1) == 1)];

    public static int Transpose(int id, int n) => SetId(PitchClasses(id).Select(pc => pc + n));

    public static int Invert(int id) => SetId(PitchClasses(id).Select(pc => -pc));

    public static int Complement(int id) => ~id & 0xFFF;

    public static string Binary(int id) => Convert.ToString(id, 2).PadLeft(12, '0');

    public static string Format(IEnumerable<int> pitchClasses) =>
        string.Join(" ", pitchClasses.Select(pc => pc switch { 10 => "T", 11 => "E", _ => pc.ToString() }));

    // Step pattern of a scale, read around the octave from its lowest pitch class
    public static int[] Steps(int id)
    {
        var pcs = PitchClasses(id);
        return [.. pcs.Select((pc, i) => i + 1 < pcs.Length ? pcs[i + 1] - pc : 12 + pcs[0] - pc)];
    }

    public static int FromSteps(IEnumerable<int> steps)
    {
        var pc = 0;
        var pcs = new List<int>();
        foreach (var step in steps)
        {
            pcs.Add(pc);
            pc += step;
        }
        return SetId(pcs);
    }

    // ---- Set classes

    // Interval-class vector: count every pair of pitch classes by interval class 1..6
    public static int[] Icv(int id)
    {
        var pcs = PitchClasses(id);
        var icv = new int[6];
        for (var i = 0; i < pcs.Length; i++)
        {
            for (var j = i + 1; j < pcs.Length; j++)
            {
                icv[IntervalClass(pcs[j] - pcs[i]) - 1]++;
            }
        }
        return icv;
    }

    public static string FormatIcv(IEnumerable<int> icv) => $"<{string.Join(" ", icv)}>";

    // Normal order of a set, packed from the right (Rahn): among the rotations, pick the one with
    // the smallest span first-to-last, then first-to-second-to-last, and so on; return it
    // transposed to start on 0
    public static int[] NormalOrderRahn(int id) => NormalOrder(id, fromRight: true);

    // Forte's variant, packed to the left: ties on the span are broken on first-to-second, then
    // first-to-third, and so on
    public static int[] NormalOrderForte(int id) => NormalOrder(id, fromRight: false);

    static int[] NormalOrder(int id, bool fromRight)
    {
        var pcs = PitchClasses(id);
        if (pcs.Length == 0) return [];
        var rotations = Enumerable.Range(0, pcs.Length)
            .Select(r => pcs.Skip(r).Concat(pcs.Take(r)).Select(pc => Mod12(pc - pcs[r])).ToArray());
        return rotations
            .OrderBy(rotation => SortKey(rotation, fromRight), KeyComparer.Instance)
            .First();
    }

    static int[] SortKey(int[] rotation, bool fromRight)
    {
        // the span first, then the spans to the other notes in the tie-break order
        var n = rotation.Length;
        if (n == 0) return [];
        var inner = Enumerable.Range(1, Math.Max(0, n - 2)).Select(k => rotation[k]);
        return [rotation[n - 1], .. fromRight ? inner.Reverse() : inner];
    }

    // Prime form: the more packed of the set's normal order and its inversion's normal order
    public static int[] PrimeForm(int id, bool fromRight = true)
    {
        var a = NormalOrder(id, fromRight);
        var b = NormalOrder(Invert(id), fromRight);
        return KeyComparer.Instance.Compare(SortKey(a, fromRight), SortKey(b, fromRight)) <= 0 ? a : b;
    }

    sealed class KeyComparer : IComparer<int[]>
    {
        public static readonly KeyComparer Instance = new();

        public int Compare(int[]? x, int[]? y)
        {
            for (var i = 0; i < Math.Min(x!.Length, y!.Length); i++)
            {
                if (x[i] != y[i]) return x[i].CompareTo(y[i]);
            }
            return x.Length.CompareTo(y.Length);
        }
    }

    // The distinct transpositions of a set that contain pitch class 0: its modes, rotations of one scale
    public static int[] Modes(int id) =>
        [.. PitchClasses(id).Select(pc => Transpose(id, -pc)).Distinct().Order()];

    // ---- Keys (lesson 5)

    public static readonly int[] MajorSteps = [2, 2, 1, 2, 2, 2, 1];
    public static readonly int[] NaturalMinorSteps = [2, 1, 2, 2, 1, 2, 2];
    public static readonly int[] HarmonicMinorSteps = [2, 1, 2, 2, 1, 3, 1];

    // Spell a scale from its tonic, one letter per degree
    public static string[] SpellScale(string tonic, IReadOnlyList<int> steps)
    {
        var notes = new string[steps.Count];
        var semitones = 0;
        for (var degree = 1; degree <= steps.Count; degree++)
        {
            notes[degree - 1] = Spell(tonic, degree, semitones);
            semitones += steps[degree - 1];
        }
        return notes;
    }

    // The tonic of the major key with `fifths` sharps (or -fifths flats): C moved that many fifths
    // up (a perfect fifth, letter + 4) or fourths up for flats (a perfect fourth, letter + 3)
    public static string MajorTonic(int fifths)
    {
        var tonic = "C";
        for (var i = 0; i < Math.Abs(fifths); i++)
        {
            tonic = fifths > 0 ? Spell(tonic, 5, 7) : Spell(tonic, 4, 5);
        }
        return tonic;
    }

    // The relative minor shares the signature; its tonic is the major key's sixth degree
    public static string MinorTonic(int fifths) => Spell(MajorTonic(fifths), 6, 9);

    // Sharps are added in the order F C G D A E B, flats in the reverse order
    public static string[] SignatureAccidentals(int fifths) => fifths >= 0
        ? [.. "FCGDAEB"[..fifths].Select(letter => $"{letter}#")]
        : [.. "BEADGCF"[..-fifths].Select(letter => $"{letter}b")];

    // Keys are named as GA prints them: "Key of Eb", "Key of F#m"
    public static string KeyName(int fifths, bool minor) =>
        $"Key of {(minor ? MinorTonic(fifths) + "m" : MajorTonic(fifths))}";

    // The key signature of a tonic, with the fewest accidentals when two spellings exist (Db rather than C#)
    public static int FifthsOf(int tonicPc, bool minor) => Enumerable.Range(-7, 15)
        .Where(n => PitchClassOf(minor ? MinorTonic(n) : MajorTonic(n)) == tonicPc)
        .OrderBy(Math.Abs).ThenByDescending(n => n)
        .First();
}
