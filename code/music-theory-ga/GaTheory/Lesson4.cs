using GA.Domain.Core.Theory.Atonal;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 4: set classes, interval-class vectors, transposition and inversion
public static class Lesson4
{
    // Rows copied from the set class table of Open Music Theory, "Set Class and Prime Form"
    static readonly (string Prime, string Forte, string Icv)[] Table =
    [
        ("037", "3-11", "001110"),
        ("0158", "4-20", "101220"),
        ("0358", "4-26", "012120"),
        ("0258", "4-27", "012111"),
        ("0369", "4-28", "004002"),
        ("0146", "4-Z15", "111111"),
        ("0137", "4-Z29", "111111"),
        ("01568", "5-20", "211231"),
        ("023679", "6-Z29", "224232"),
        ("014579", "6-31", "223431"),
        ("02468T", "6-35", "060603"),
        ("013568T", "7-35", "254361"),
        ("0145679", "7-Z18", "434442"),
        ("0125679", "7-20", "433452"),
    ];

    static int ParsePrime(string prime) => Theory.SetId(prime.Select(ch => ch switch { 'T' => 10, 'E' => 11, _ => ch - '0' }));

    static string Compact(IEnumerable<int> pcs) => $"({string.Join("", pcs.Select(pc => pc switch { 10 => "T", 11 => "E", _ => pc.ToString() }))})";

    static PitchClassSet Ga(int id) => PitchClassSet.FromId(id);

    public static void Run()
    {
        Title("Transposition and inversion of a C major triad (0 4 7)");
        Columns("operation", 10, 10);
        var cMajor = Theory.SetId([0, 4, 7]);
        var gaC = Ga(cMajor).Id;
        Row("T2", Theory.Format(Theory.PitchClasses(Theory.Transpose(cMajor, 2))), gaC.Transpose(2).ToPitchClassSet());
        Row("I0", Theory.Format(Theory.PitchClasses(Theory.Invert(cMajor))), gaC.Inverse.ToPitchClassSet());
        Row("T2I", Theory.Format(Theory.PitchClasses(Theory.Transpose(Theory.Invert(cMajor), 2))), gaC.Inverse.Transpose(2).ToPitchClassSet());

        Title("Interval-class vectors");
        Columns("set", 18, 20);
        foreach (var (name, pcs) in new (string, int[])[]
                 {
                     ("C major triad", [0, 4, 7]), ("A minor triad", [9, 0, 4]), ("C7", [0, 4, 7, 10]),
                     ("Cm7b5", [0, 3, 6, 10]), ("Cdim7", [0, 3, 6, 9]), ("C major scale", [0, 2, 4, 5, 7, 9, 11]),
                     ("11 pitch classes", [.. Enumerable.Range(1, 11)]), ("all 12", [.. Enumerable.Range(0, 12)]),
                 })
        {
            var id = Theory.SetId(pcs);
            Row(name, Theory.FormatIcv(Theory.Icv(id)), Ga(id).IntervalClassVector);
        }

        Title("Prime forms and Forte numbers (each set transposed by 5 first)");
        Columns("table row", 16, 30);
        foreach (var (prime, forte, icv) in Table)
        {
            var id = Theory.Transpose(ParsePrime(prime), 5);
            var ga = Ga(id);
            var gaPrime = ga.PrimeForm!;
            var coursePrime = Theory.PrimeForm(id);
            // the course's prime form and vector must match the table's row; the Forte number is the table's
            var courseIcv = string.Join("", Theory.Icv(id));
            var matchesTable = Compact(coursePrime) == $"({prime})" && courseIcv == icv ? "" : " (not the table's)";
            Row($"({prime}) {forte}", $"{Compact(coursePrime)} {forte} <{courseIcv}>{matchesTable}",
                $"{Compact(gaPrime.Select(pc => pc.Value))} {ForteCatalog.GetForteNumber(gaPrime)} <{string.Join("", ga.IntervalClassVector)}>");
        }

        Title("Packed from the right (Rahn) or to the left (Forte)?");
        var classes = Enumerable.Range(0, 1 << 12)
            .Select(id => Compact(Theory.PrimeForm(id)))
            .Distinct().Count();
        var differing = Enumerable.Range(0, 1 << 12)
            .Where(id => Compact(Theory.PrimeForm(id)) is var rahn && rahn != Compact(Theory.PrimeForm(id, fromRight: false)))
            .Select(id => (Rahn: Compact(Theory.PrimeForm(id)), Forte: Compact(Theory.PrimeForm(id, fromRight: false))))
            .Distinct()
            .OrderBy(pair => pair.Rahn.Length).ThenBy(pair => pair.Rahn)
            .ToList();
        Line($"set classes where the two packings disagree: {differing.Count}");
        foreach (var (rahn, forte) in differing)
        {
            Line($"  Rahn {rahn,-15} Forte {forte}");
        }
        var gaAgreesWithRahn = Enumerable.Range(0, 1 << 12)
            .Count(id => Compact(Ga(id).PrimeForm!.Select(pc => pc.Value)) == Compact(Theory.PrimeForm(id)));
        Line($"sets whose GA prime form is Rahn's: {gaAgreesWithRahn} of 4096");

        Title("Counting classes");
        Columns("equivalence", 22, 6);
        Row("T and I (set classes)", classes, SetClass.Items.Count);
        Row("T only", Enumerable.Range(0, 1 << 12).Select(id => Theory.Modes(id).FirstOrDefault()).Distinct().Count(),
            TranspositionClass.Items.Count);

        Title("Z-relation: same vector, different set classes");
        Columns("set", 8, 28);
        foreach (var prime in new[] { "0146", "0137" })
        {
            var id = ParsePrime(prime);
            var ga = Ga(id);
            var forte = Table.Single(row => row.Prime == prime).Forte;
            Row(prime, $"{Theory.FormatIcv(Theory.Icv(id))} {Compact(Theory.PrimeForm(id))} {forte}",
                $"{ga.IntervalClassVector} {Compact(ga.PrimeForm!.Select(pc => pc.Value))} {ForteCatalog.GetForteNumber(ga.PrimeForm!)}");
        }

        Title("Modal families: GA counts the sets containing 0 that share the vector");
        Columns("set (rotations)", 24, 6);
        foreach (var (name, pcs) in new (string, int[])[]
                 {
                     ("major triad", [0, 4, 7]), ("dominant 7th", [0, 4, 7, 10]), ("major scale", [0, 2, 4, 5, 7, 9, 11]),
                     ("harmonic minor", [0, 2, 3, 5, 7, 8, 11]), ("0146", [0, 1, 4, 6]),
                 })
        {
            var id = Theory.SetId(pcs);
            var icv = Theory.FormatIcv(Theory.Icv(id));
            var sameIcv = Enumerable.Range(0, 1 << 12).Count(other => (other & 1) == 1 && Theory.FormatIcv(Theory.Icv(other)) == icv);
            Row($"{name} ({Theory.Modes(id).Length})", sameIcv, Ga(id).ModalFamily!.Modes.Count);
        }

        Title("Same set class as Am, then G7, among 12 roots x 12 chord types");
        string[] roots = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];
        (string Suffix, int[] Intervals)[] vocabulary =
        [
            ("", [0, 4, 7]), ("m", [0, 3, 7]), ("dim", [0, 3, 6]), ("aug", [0, 4, 8]), ("7", [0, 4, 7, 10]),
            ("maj7", [0, 4, 7, 11]), ("m7", [0, 3, 7, 10]), ("dim7", [0, 3, 6, 9]), ("m7b5", [0, 3, 6, 10]),
            ("maj9", [0, 4, 7, 11, 14]), ("9", [0, 4, 7, 10, 14]), ("m9", [0, 3, 7, 10, 14]),
        ];
        foreach (var symbol in new[] { "Am", "G7" })
        {
            var target = symbol == "Am" ? Theory.SetId([9, 0, 4]) : Theory.SetId([7, 11, 2, 5]);
            var candidates = (from root in Enumerable.Range(0, 12)
                              from chord in vocabulary
                              select (Name: roots[root] + chord.Suffix, Id: Theory.SetId(chord.Intervals.Select(i => i + root))))
                .Where(c => c.Name != symbol).ToList();
            var course = candidates.Where(c => Compact(Theory.PrimeForm(c.Id)) == Compact(Theory.PrimeForm(target))).Select(c => c.Name);
            var gaPrime = Ga(target).PrimeForm!;
            var ga = candidates.Where(c => Ga(c.Id).PrimeForm!.Equals(gaPrime)).Select(c => c.Name);
            Line($"{symbol} course: {string.Join(" ", course)}");
            Line($"{symbol} GA:     {string.Join(" ", ga)}");
        }

        Title("Exercise solutions");
        Columns("question", 20, 26);
        var minorPentatonic = Theory.SetId([0, 3, 5, 7, 10]);
        var gaMp = Ga(minorPentatonic);
        Row("1. minor pentatonic", $"{Theory.FormatIcv(Theory.Icv(minorPentatonic))} {Compact(Theory.PrimeForm(minorPentatonic))}",
            $"{gaMp.IntervalClassVector} {Compact(gaMp.PrimeForm!.Select(pc => pc.Value))} {ForteCatalog.GetForteNumber(gaMp.PrimeForm!)}".Replace(" 5-35", ""));
        var cmaj7 = Theory.SetId([0, 4, 7, 11]);
        var am7 = Theory.SetId([9, 0, 4, 7]);
        Row("2. Cmaj7 vs Am7", $"{Compact(Theory.PrimeForm(cmaj7))} {Compact(Theory.PrimeForm(am7))}",
            $"{Compact(Ga(cmaj7).PrimeForm!.Select(pc => pc.Value))} {Compact(Ga(am7).PrimeForm!.Select(pc => pc.Value))}");
        var z29 = ParsePrime("023679");
        var partner = Enumerable.Range(0, 1 << 12)
            .Where(id => Theory.FormatIcv(Theory.Icv(id)) == Theory.FormatIcv(Theory.Icv(z29)))
            .Select(id => Compact(Theory.PrimeForm(id))).Distinct().Single(p => p != "(023679)");
        var gaPartner = SetClass.Items
            .Where(sc => sc.IntervalClassVector == Ga(z29).IntervalClassVector && !sc.PrimeForm.Equals(Ga(z29).PrimeForm))
            .Select(sc => $"{Compact(sc.PrimeForm.Select(pc => pc.Value))} {ForteCatalog.GetForteNumber(sc.PrimeForm)}").Single();
        Row("3. partner of 6-Z29", $"{partner} 6-Z50", gaPartner);
    }
}
