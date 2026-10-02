using System.Reflection;
using GA.Business.Config;
using GA.Core.Abstractions;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Tonal.Modes;
using GA.Domain.Core.Theory.Tonal.Modes.Exotic;
using GA.Domain.Core.Theory.Tonal.Modes.Symmetric;
using GA.Domain.Core.Theory.Tonal.Scales;
using GA.Domain.Services.Chords.Analysis.Atonal;
using GA.Domain.Services.Unified;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 12 of the course, run as `l14`: the sets a transposition maps onto themselves, Messiaen's modes of limited
// transposition, GA's symmetric mode classes, and what GA's code means by "symmetric"
public static class Lesson14
{
    // ---- The course's side: the transpositions and inversions that map a set onto itself

    // How many of the twelve transpositions T0 to T11 leave the set unchanged: always 1, 2, 3, 4, 6 or 12
    static int Fixing(int id) => Enumerable.Range(0, 12).Count(n => Theory.Transpose(id, n) == id);

    static bool Limited(int id) => Fixing(id) > 1;

    static int Transpositions(int id) => 12 / Fixing(id);

    // A scale's distinct modes: its distinct rotations moved to 0, as lesson 2 counts them
    static int ModeCount(int id) => Theory.Modes(id).Length;

    // The inversions In (pitch class p goes to n − p) that leave the set unchanged: its mirror axes on the bracelet
    internal static int[] Mirrors(int id) =>
        [.. Enumerable.Range(0, 12).Where(n => Theory.SetId(Theory.PitchClasses(id).Select(pc => n - pc)) == id)];

    // A transposition class by its smallest id among the twelve transpositions (it always contains 0)
    static int TranspositionForm(int id) => Enumerable.Range(0, 12).Min(n => Theory.Transpose(id, n));

    // The smallest id among the 24 transpositions and inversions: the id of the prime form (lesson 4)
    static int PrimeId(int id) =>
        Enumerable.Range(0, 12).SelectMany(n => new[] { Theory.Transpose(id, n), Theory.Transpose(Theory.Invert(id), n) }).Min();

    static string Compact(IEnumerable<int> pcs) => string.Concat(pcs.Select(pc => pc switch { 10 => "T", 11 => "E", _ => pc.ToString() }));

    static string StepsOf(int id) => string.Join(" ", Theory.Steps(id));

    // Messiaen's seven modes, from the intervals Wikipedia lists for each ("Mode of limited transposition"),
    // and the transpositions and modes his list gives
    static readonly int[][] MessiaenSteps =
    [
        [2, 2, 2, 2, 2, 2],
        [1, 2, 1, 2, 1, 2, 1, 2],
        [2, 1, 1, 2, 1, 1, 2, 1, 1],
        [1, 1, 3, 1, 1, 1, 3, 1],
        [1, 4, 1, 1, 4, 1],
        [2, 2, 1, 1, 2, 2, 1, 1],
        [1, 1, 1, 2, 1, 1, 1, 1, 2, 1],
    ];

    static readonly (int Transpositions, int Modes)[] MessiaenList = [(2, 1), (3, 2), (4, 3), (6, 4), (6, 3), (6, 4), (6, 5)];

    // The tritone scale, C D♭ E G♭ G B♭: the notes of the Petrushka chord (Wikipedia, "Hexatonic scale" and "Petrushka chord")
    static readonly int TritoneScale = Theory.SetId([0, 1, 4, 6, 7, 10]);

    // Names for the fifteen classes, matched by transposition class
    static readonly (string Name, int Id)[] Named =
    [
        ("tritone", Theory.FromSteps([6, 6])),
        ("augmented triad", Theory.FromSteps([4, 4, 4])),
        ("diminished seventh", Theory.FromSteps([3, 3, 3, 3])),
        ("whole-tone scale, Messiaen 1", Theory.FromSteps(MessiaenSteps[0])),
        ("octatonic scale, Messiaen 2", Theory.FromSteps(MessiaenSteps[1])),
        ("Messiaen 3", Theory.FromSteps(MessiaenSteps[2])),
        ("Messiaen 4", Theory.FromSteps(MessiaenSteps[3])),
        ("Messiaen 5", Theory.FromSteps(MessiaenSteps[4])),
        ("Messiaen 6", Theory.FromSteps(MessiaenSteps[5])),
        ("Messiaen 7", Theory.FromSteps(MessiaenSteps[6])),
        ("augmented scale", Theory.FromSteps([3, 1, 3, 1, 3, 1])),
        ("tritone scale", TritoneScale),
        ("tritone scale, inverted", Theory.Invert(TritoneScale)),
    ];

    static string NameOf(int id) => Named.FirstOrDefault(n => TranspositionForm(n.Id) == TranspositionForm(id)).Name ?? "";

    // Forte numbers of the classes in this lesson, from Wikipedia's "List of set classes", keyed by prime form
    static readonly Dictionary<string, string> Forte = new()
    {
        ["06"] = "2-6", ["048"] = "3-12", ["0167"] = "4-9", ["0268"] = "4-25", ["0369"] = "4-28",
        ["012678"] = "6-7", ["014589"] = "6-20", ["013679"] = "6-30", ["014679"] = "6-Z50", ["02468T"] = "6-35",
        ["01236789"] = "8-9", ["0124678T"] = "8-25", ["0134679T"] = "8-28", ["01245689T"] = "9-12", ["012346789T"] = "10-6",
    };

    static string PrimeText(int id)
    {
        var prime = Compact(Theory.PrimeForm(id));
        return Forte.TryGetValue(prime, out var forte) ? $"({prime}) {forte}" : $"({prime})";
    }

    static string Ascii(string notes) => notes.Replace("♯", "#");

    // ---- GA's side

    static readonly Dictionary<int, PitchClassSet> GaSets = PitchClassSet.Items.ToDictionary(set => set.Id.Value);

    // AtonalChordAnalysisService (GA.Domain.Services, compiled) keeps its symmetry test private: the course calls it by reflection
    static readonly MethodInfo IsSymmetricalSetMethod =
        typeof(AtonalChordAnalysisService).GetMethod("IsSymmetricalSet", BindingFlags.NonPublic | BindingFlags.Static)!;

    static bool IsSymmetricalSet(PitchClassSet set) => (bool)IsSymmetricalSetMethod.Invoke(null, [set])!;

    static readonly UnifiedModeService Service = new();

    // UnifiedModeService keeps IsSymmetricSet private too; FromPitchClassSet stores its answer on the class
    static bool? IsSymmetricSet(PitchClassSet set)
    {
        try
        {
            return Service.FromPitchClassSet(set, PitchClass.C).Class.IsSymmetric;
        }
        catch (Exception)
        {
            return null;
        }
    }

    static int? MessiaenIndex(PitchClassSet set) => Service.Describe(Service.FromPitchClassSet(set, PitchClass.C)).MessiaenModeIndex;

    // A mode moved to C: the pitch classes of its notes, minus the pitch class of its first note
    static int OnC(ScaleMode mode)
    {
        var pcs = mode.Notes.Select(note => note.PitchClass.Value).ToList();
        return Theory.SetId(pcs.Select(pc => pc - pcs[0]));
    }

    static void ModeClass<TDegree>(string scale, IEnumerable<SymmetricScaleMode<TDegree>> gaModes, int courseId)
        where TDegree : IValueObject
    {
        var modes = gaModes.ToList();
        Title($"{scale}: GA's {modes.Count} modes, each moved to C, against the course's count");
        Console.WriteLine($"{"degree",-7} {"GA's Name",-24} {"notes",-26} {"steps",-17} set on C");
        foreach (var (mode, i) in modes.Select((mode, i) => (mode, i)))
        {
            Console.WriteLine($"{i + 1,-7} {mode.Name,-24} {Ascii(string.Join(" ", mode.Notes)),-26} {StepsOf(OnC(mode)),-17} {OnC(mode)}");
        }
        Line();
        Columns("", 16, 8);
        Row("transpositions", Transpositions(courseId), modes[0].TranspositionCount);
        Row("limited", Limited(courseId), modes[0].HasLimitedTranspositions);
        Row("distinct modes", ModeCount(courseId), modes.Select(OnC).Distinct().Count());
    }

    public static void Run()
    {
        var all = Enumerable.Range(0, 4096).ToList();

        // ---- 1. Limited transposition

        Title("Limited transposition: the 4096 sets, by how many of the twelve transpositions map each onto itself");
        Console.WriteLine($"{"fixing",-7} {"transpositions",-15} {"sets",-6} transposition classes");
        foreach (var group in all.GroupBy(Fixing).OrderBy(g => g.Key))
        {
            Console.WriteLine($"{group.Key,-7} {12 / group.Key,-15} {group.Count(),-6} {group.Select(TranspositionForm).Distinct().Count()}");
        }
        var limited = all.Where(Limited).ToList();
        var classes = limited.Select(TranspositionForm).Distinct().ToList();
        Line();
        Line($"sets with limited transpositions: {limited.Count}, in {classes.Count} transposition classes");
        var fifteen = classes.Where(id => id != 0 && id != 0xFFF)
            .OrderBy(Transpositions).ThenBy(id => Theory.PitchClasses(id).Length).ThenBy(id => id).ToList();
        Line($"without the empty set and the chromatic scale: {fifteen.Count} classes, {fifteen.Select(PrimeId).Distinct().Count()} set classes");

        Title("The fifteen classes: notes from 0, steps, distinct transpositions and modes, mirror axes");
        Console.WriteLine($"{"prime form",-18} {"pitch classes",-20} {"steps",-20} {"transp.",-8} {"modes",-6} {"mirrors",-8} name");
        foreach (var id in fifteen)
        {
            Console.WriteLine($"{PrimeText(id),-18} {Theory.Format(Theory.PitchClasses(id)),-20} {StepsOf(id),-20} {Transpositions(id),-8} {ModeCount(id),-6} {Mirrors(id).Length,-8} {NameOf(id)}".TrimEnd());
        }

        Title("Messiaen's seven modes, from Wikipedia's intervals: the course's counts against his list");
        Console.WriteLine($"{"mode",-5} {"steps",-20} {"transp.",-8} {"modes",-6} {"his list",-9} check");
        for (var k = 0; k < 7; k++)
        {
            var id = Theory.FromSteps(MessiaenSteps[k]);
            var course = $"{Transpositions(id)} {ModeCount(id)}";
            var list = $"{MessiaenList[k].Transpositions} {MessiaenList[k].Modes}";
            Console.WriteLine($"{k + 1,-5} {StepsOf(id),-20} {Transpositions(id),-8} {ModeCount(id),-6} {list,-9} {(course == list ? "ok" : "DIFF")}");
        }

        Title("UnifiedModeService (GA.Domain.Services, compiled): IsSymmetricSet over the 4096 sets, through FromPitchClassSet");
        var gaSymmetric = PitchClassSet.Items.Select(set => (Id: set.Id.Value, Ga: IsSymmetricSet(set))).ToList();
        Columns("", 22, 8);
        Row("sets", limited.Count, gaSymmetric.Count(s => s.Ga == true));
        Row("agree", 4096, gaSymmetric.Count(s => s.Ga == Limited(s.Id)));
        Line($"sets FromPitchClassSet throws on: {gaSymmetric.Count(s => s.Ga is null)}");

        Title("UnifiedModeService.Describe(...).MessiaenModeIndex for Messiaen's seven modes, with each prime form's id");
        Columns("mode", 16, 8);
        for (var k = 0; k < 7; k++)
        {
            var id = Theory.FromSteps(MessiaenSteps[k]);
            Row($"{k + 1} ({PrimeId(id)})", k + 1, MessiaenIndex(GaSets[id]));
        }
        Line();
        Line("The ids IdentifyMessiaenMode compares the prime form with (UnifiedModeService.cs, lines 298-341):");
        Console.WriteLine($"{"GA's mode",-10} {"id",-6} {"pitch classes",-22} {"the course's mode",-18} prime form");
        foreach (var (mode, id) in new[] { (1, 1365), (2, 1755), (2, 2925), (3, 1911), (4, 2535), (5, 2275), (6, 3315), (7, 3055) })
        {
            var courseMode = Enumerable.Range(0, 7).First(k => TranspositionForm(Theory.FromSteps(MessiaenSteps[k])) == TranspositionForm(id)
                || TranspositionForm(Theory.Invert(Theory.FromSteps(MessiaenSteps[k]))) == TranspositionForm(id)) + 1;
            var prime = PrimeId(id) == id ? "yes" : $"no, {PrimeId(id)}";
            Console.WriteLine($"{mode,-10} {id,-6} {Theory.Format(Theory.PitchClasses(id)),-22} {courseMode,-18} {prime}");
        }

        // ---- 2. GA's symmetric mode classes

        ModeClass("WholeToneScaleMode", WholeToneScaleMode.Items, Theory.FromSteps(MessiaenSteps[0]));
        ModeClass("DiminishedScaleMode", DiminishedScaleMode.Items, Theory.FromSteps(MessiaenSteps[1]));
        ModeClass("AugmentedScaleMode", AugmentedScaleMode.Items, Theory.FromSteps([3, 1, 3, 1, 3, 1]));

        Title("DiminishedScaleMode: GA's names for degrees 1 and 2 against the name of their step pattern");
        Columns("degree", 8, 24);
        foreach (var (mode, i) in DiminishedScaleMode.Items.Take(2).Select((mode, i) => (mode, i)))
        {
            var name = Theory.Steps(OnC(mode))[0] == 2 ? "Whole-half diminished" : "Half-whole diminished";
            Row($"{i + 1}", name, mode.Name);
        }

        Title("Scale.Tritone against the tritone scale, C D♭ E G♭ G B♭");
        var gaTritone = Theory.SetId(Scale.Tritone.Select(note => note.PitchClass.Value));
        Headings("", "Scale.Tritone", "tritone scale", 22, 22);
        Plain("notes", Ascii(string.Join(" ", Scale.Tritone)), "C Db E Gb G Bb");
        Plain("pitch classes", Theory.Format(Theory.PitchClasses(gaTritone)), Theory.Format(Theory.PitchClasses(TritoneScale)));
        Plain("steps", StepsOf(gaTritone), StepsOf(TritoneScale));
        Plain("prime form", PrimeText(gaTritone), PrimeText(TritoneScale));
        Plain("vector, course", Theory.FormatIcv(Theory.Icv(gaTritone)), Theory.FormatIcv(Theory.Icv(TritoneScale)));
        Plain("vector, GA", GaSets[gaTritone].IntervalClassVector, GaSets[TritoneScale].IntervalClassVector);
        Plain("transpositions", Transpositions(gaTritone), Transpositions(TritoneScale));
        Plain("modes", ModeCount(gaTritone), ModeCount(TritoneScale));
        Plain("GA's IsSymmetricSet", IsSymmetricSet(GaSets[gaTritone]), IsSymmetricSet(GaSets[TritoneScale]));
        var tritoneModes = TritoneScaleMode.Items.ToList();
        Line();
        Line($"TritoneScaleMode.Items: {tritoneModes.Count} modes, {tritoneModes.Select(OnC).Distinct().Count()} distinct sets on C");

        // ---- 3. What GA calls symmetric

        Title("Three tests GA calls symmetric, over the 4096 sets, against limited transposition");
        var tests = new (string Name, Func<PitchClassSet, bool> Test)[]
        {
            ("course: limited transpositions", set => Limited(set.Id.Value)),
            ("UnifiedModeService.IsSymmetricSet", set => IsSymmetricSet(set) == true),
            ("PitchClassSet.IsMonomodal", set => set.IsMonomodal),
            ("AtonalChordAnalysisService.IsSymmetricalSet", set => IsSymmetricalSet(set)),
        };
        Console.WriteLine($"{"test",-44} {"sets",-6} {"limited",-8} {"not limited",-12} limited, not flagged");
        foreach (var (name, test) in tests)
        {
            var flagged = PitchClassSet.Items.Where(test).Select(set => set.Id.Value).ToList();
            Console.WriteLine($"{name,-44} {flagged.Count,-6} {flagged.Count(Limited),-8} {flagged.Count(id => !Limited(id)),-12} {limited.Count(id => !flagged.Contains(id))}");
        }
        Line();
        var monomodal = PitchClassSet.Items.Where(set => set.IsMonomodal).ToList();
        Line($"IsMonomodal, by number of notes: {string.Join(", ", monomodal.GroupBy(set => set.Count).OrderBy(g => g.Key).Select(g => $"{g.Key}: {g.Count()}"))}");
        Line($"IsSymmetricalSet: C D E {IsSymmetricalSet(GaSets[Theory.SetId([0, 2, 4])])}, B♭ C D {IsSymmetricalSet(GaSets[Theory.SetId([10, 0, 2])])}");
        Line($"sets whose SetClass.IsModal is false, the only way into GenerateAtonalName's symmetry branch: {PitchClassSet.Items.Count(set => !new SetClass(set).IsModal)}");

        Title("AtonalModalFamilies.yaml (GA.Business.Config, read by AtonalModalFamiliesConfig): IsSymmetric against limited transposition");
        var families = AtonalModalFamiliesConfig.GetAll().ToList();
        Line($"families: {families.Count}; IsSymmetric: {families.Count(f => f.IsSymmetric)}; with limited transpositions: {families.Count(f => Limited(f.PrimeModeId))}");
        Line();
        Columns("first mode, family", 52, 8);
        foreach (var f in families.Where(f => f.IsSymmetric || Limited(f.PrimeModeId)))
        {
            Row($"{Theory.Format(Theory.PitchClasses(f.PrimeModeId))}  {f.FamilyName}", Limited(f.PrimeModeId), f.IsSymmetric);
        }

        Title("ModesSkill's answer to \"modes of limited transposition\" (GA.Business.ML, not compiled), rebuilt from its format and the same data");
        var symmetric = AtonalModalFamiliesConfig.GetSymmetricFamilies().ToList();
        Line($"**{symmetric.Count} symmetric / modes-of-limited-transposition families** in the atonal catalog:");
        Line();
        foreach (var f in symmetric.OrderBy(f => f.NoteCount).ThenBy(f => f.IntervalClassVector))
        {
            Line($"- **{f.FamilyName}** — ICV `{f.IntervalClassVector}` — {f.NoteCount} notes" + (f.ForteNumbers.Any() ? $" (Forte {string.Join("/", f.ForteNumbers)})" : ""));
        }
        Line();
        Line("These are Messiaen's classical category — scales that repeat under rotation by fewer than 12 transpositions. The whole-tone scale (2 transpositions), octatonic (3), and hexatonic (4) are the most common in jazz / film vocabulary.");

        Title("The Forte labels of AtonalModalFamilies.yaml against GA's ForteCatalog (CanonicalForteCatalog, lesson 4)");
        string CatalogLabels(AtonalModalFamiliesConfig.AtonalModalFamily f) => string.Join("/",
            f.Modes.Select(m => ForteCatalog.GetForteNumber(GaSets[m.PitchClassSetId])?.ToString() ?? "?").Distinct().Order(StringComparer.Ordinal));
        string FileLabels(AtonalModalFamiliesConfig.AtonalModalFamily f) => string.Join("/", f.ForteNumbers.Order(StringComparer.Ordinal));
        Console.WriteLine($"{"notes",-6} {"families",-9} same labels");
        foreach (var group in families.GroupBy(f => f.NoteCount).OrderBy(g => g.Key))
        {
            Console.WriteLine($"{group.Key,-6} {group.Count(),-9} {group.Count(f => CatalogLabels(f) == FileLabels(f))}");
        }
        Line($"all    {families.Count,-9} {families.Count(f => CatalogLabels(f) == FileLabels(f))}");
        Line();
        Console.WriteLine($"{"symmetric family",-22} {"ForteCatalog",-13} {"the file",-9} check");
        foreach (var f in symmetric)
        {
            Console.WriteLine($"{Theory.Format(Theory.PitchClasses(f.PrimeModeId)),-22} {CatalogLabels(f),-13} {FileLabels(f),-9} {(CatalogLabels(f) == FileLabels(f) ? "ok" : "DIFF")}");
        }

        // ---- 4. Mirror symmetry

        Title("Mirror symmetry: TranspositionClass.IsInversionallySymmetric (GA.Domain.Core) against the course's mirror axes");
        var courseClasses = all.Select(TranspositionForm).Distinct().ToList();
        var gaClasses = TranspositionClass.Items;
        Columns("", 24, 8);
        Row("transposition classes", courseClasses.Count, gaClasses.Count);
        Row("mirror-symmetric", courseClasses.Count(id => Mirrors(id).Length > 0), gaClasses.Count(c => c.IsInversionallySymmetric));
        Row("agree", courseClasses.Count, gaClasses.Count(c => c.IsInversionallySymmetric == Mirrors(c.PrimeForm.Id.Value).Length > 0));
        Line();
        Line($"sets with mirror axes but not as many as the transpositions that fix them: {all.Count(id => Mirrors(id).Length != 0 && Mirrors(id).Length != Fixing(id))}");
        Line();
        Headings("scale", "fixing transpositions", "mirror axes", 18, 22);
        foreach (var (name, id) in new[]
        {
            ("major", Theory.FromSteps(Theory.MajorSteps)),
            ("harmonic minor", Theory.FromSteps(Theory.HarmonicMinorSteps)),
            ("melodic minor", Theory.FromSteps([2, 1, 2, 2, 2, 2, 1])),
            ("whole-tone", Theory.FromSteps(MessiaenSteps[0])),
            ("octatonic", Theory.FromSteps(MessiaenSteps[1])),
            ("augmented scale", Theory.FromSteps([3, 1, 3, 1, 3, 1])),
            ("tritone scale", TritoneScale),
            ("Scale.Tritone", gaTritone),
        })
        {
            Plain(name, Fixing(id), Mirrors(id).Length);
        }
    }
}
