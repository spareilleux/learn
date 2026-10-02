using GA.Business.Config;
using GA.Core.Abstractions;
using GA.Core.ValueObjects;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Tonal.Modes;
using GA.Domain.Core.Theory.Tonal.Modes.Diatonic;
using GA.Domain.Core.Theory.Tonal.Primitives;
using GA.Domain.Core.Theory.Tonal.Primitives.Diatonic;
using GA.Domain.Core.Theory.Tonal.Scales;
using GA.Domain.Services.Unified;
using Microsoft.FSharp.Core;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 11 of the course, run as `l13`: the modes of melodic and harmonic minor, the brightness of a mode,
// and modal families, in GA's generic mode classes and in its Modes.yaml
public static class Lesson13
{
    // ---- The course's side: a scale is a step pattern, its modes are the rotations of the pattern

    internal static readonly int[] MelodicMinorSteps = [2, 1, 2, 2, 2, 2, 1];
    internal static readonly int[] HarmonicMajorSteps = [2, 2, 1, 2, 1, 3, 1];

    // The textbook names: Wikipedia, "Jazz scale", "Harmonic minor scale" and "Harmonic major scale"
    internal static readonly string[] MajorNames = ["Ionian", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Aeolian", "Locrian"];
    internal static readonly string[] MelodicMinorNames = ["melodic minor", "Dorian ♭2", "Lydian augmented", "Lydian dominant", "Mixolydian ♭6", "Locrian ♮2", "altered"];
    internal static readonly string[] HarmonicMinorNames = ["harmonic minor", "Locrian ♮6", "Ionian ♯5", "Dorian ♯4", "Phrygian dominant", "Lydian ♯2", "altered ♭♭7"];
    internal static readonly string[] HarmonicMajorNames = ["harmonic major", "Dorian ♭5", "Phrygian ♭4", "Lydian ♭3", "Mixolydian ♭2", "Lydian augmented ♯2", "Locrian ♭♭7"];

    static int[] Rotate(int[] steps, int k) => [.. Enumerable.Range(0, steps.Length).Select(i => steps[(k + i) % steps.Length])];

    // The semitones of each degree above the tonic: 0, then the steps added up
    static int[] Offsets(int[] steps) => [.. Enumerable.Range(0, steps.Length).Select(i => steps.Take(i).Sum())];

    static readonly int[] MajorOffsets = [0, 2, 4, 5, 7, 9, 11];
    static readonly int[] AeolianOffsets = [0, 2, 3, 5, 7, 8, 10];

    // Lesson 2's notation: each degree written against the major scale; `>` marks a degree that differs from the
    // reference mode (Aeolian when the third is minor, Ionian otherwise), and ♮ a degree the reference lowers
    static string Formula(int[] offsets)
    {
        var reference = offsets[2] == 3 ? AeolianOffsets : MajorOffsets;
        return string.Join(" ", offsets.Select((semitones, i) =>
        {
            var mark = semitones != reference[i] ? ">" : "";
            var natural = semitones == MajorOffsets[i] && reference[i] != MajorOffsets[i] ? "♮" : "";
            var accidental = (semitones - MajorOffsets[i]) switch { -2 => "bb", -1 => "b", 0 => "", 1 => "♯", _ => "?" };
            return $"{mark}{natural}{accidental}{i + 1}";
        }));
    }

    // The course's brightness of a mode: the semitones of its degrees above the tonic, added up
    static int Brightness(int[] steps) => Offsets(steps).Sum();

    static string Collapse(string text) => string.Join(" ", text.Split(' ', StringSplitOptions.RemoveEmptyEntries));

    static string Ascii(string notes) => notes.Replace("♯", "#");

    // ---- GA's side: one table for any of GA's mode classes, since ScaleMode<TDegree> is generic over its degree type

    static void ModeTable<TDegree>(string scale, IEnumerable<ScaleMode<TDegree>> gaModes, string tonic, int[] steps, string[] names)
        where TDegree : IValueObject
    {
        var modes = gaModes.ToList();
        var parent = Theory.SpellScale(tonic, steps);
        Title($"The modes of {scale}: GA's ModeFormula against the course's, from the steps {string.Join(" ", steps)}");
        Columns("mode", 20, 26);
        for (var k = 0; k < 7; k++)
        {
            Row(names[k], Formula(Offsets(Rotate(steps, k))), Collapse(modes[k].Formula.ToString()));
        }
        Line();
        Columns("notes", 20, 26);
        for (var k = 0; k < 7; k++)
        {
            Row(names[k], string.Join(" ", Theory.SpellScale(parent[k], Rotate(steps, k))), Ascii(string.Join(" ", modes[k].Notes)));
        }
        Line();
        Headings("textbook name", "GA's Name", "", 20, 26);
        for (var k = 0; k < 7; k++)
        {
            Plain(names[k], modes[k].Name);
        }
    }

    // The same interface on five degree types: one generic method reads them all
    static string ShortNames<TDegree>() where TDegree : IRangeValueObject<TDegree>, IScaleDegreeNaming =>
        string.Join(" ", ValueObjectUtils<TDegree>.Items.Select(degree => degree.ToShortName()));

    // The course's numeral for the triad on each degree, read against the scale itself:
    // lower case for a minor or diminished triad, then ° (diminished) or + (augmented)
    static string TriadNumerals(string tonic, int[] steps)
    {
        string[] romans = ["I", "II", "III", "IV", "V", "VI", "VII"];
        var scale = Theory.SpellScale(tonic, steps);
        return string.Join(" ", Enumerable.Range(0, 7).Select(d =>
        {
            var third = Theory.Mod12(Theory.PitchClassOf(scale[(d + 2) % 7]) - Theory.PitchClassOf(scale[d]));
            var fifth = Theory.Mod12(Theory.PitchClassOf(scale[(d + 4) % 7]) - Theory.PitchClassOf(scale[d]));
            var numeral = third == 3 ? romans[d].ToLowerInvariant() : romans[d];
            return numeral + (third, fifth) switch { (3, 6) => "°", (4, 8) => "+", _ => "" };
        }));
    }

    /// <summary>
    ///     Brightness proxy: bright-to-dark interval balance from the ICV, normalised to [0, 1].
    ///     Major-3rd + perfect-5th lean bright; minor-2nd + tritone lean dark. Octave-invariant.
    /// </summary>
    // Copied as it is from GA's TheoryVectorService (GA.Business.ML, where it is internal): dimension 21 of the embeddings
    internal static double IcvBrightness(int[] icv)
    {
        var total = 0;
        for (var i = 0; i < 6; i++) total += icv[i];
        if (total == 0) return 0.5;
        var bright = icv[3] + icv[4]; // ic4 + ic5
        var dark = icv[0] + icv[5];   // ic1 + ic6
        var net = (double)(bright - dark) / total; // range ~[-1, 1]
        return (net + 1.0) / 2.0;                  // map to [0, 1]
    }

    // GA prints a vector as "<2 5 4 3 6 1>", the format of Modes.yaml
    static int[] ParseIcv(string icv) => [.. icv.Trim('<', '>').Split(' ', StringSplitOptions.RemoveEmptyEntries).Select(int.Parse)];

    static PitchClassSet SetOf<TDegree>(ScaleMode<TDegree> mode) where TDegree : IValueObject =>
        new(mode.Notes.Select(note => note.PitchClass));

    // The vector GA computes for notes written as Modes.yaml writes them, and the course's
    static string GaIcv(string notes) => Try(() => new Scale(notes).PitchClassSet.IntervalClassVector.Id.ToString());

    static string CourseIcv(string notes) =>
        Theory.FormatIcv(Theory.Icv(Theory.SetId(notes.Split(' ', StringSplitOptions.RemoveEmptyEntries).Select(Theory.PitchClassOf))));

    public static void Run()
    {
        ModeTable<MelodicMinorScaleDegree>("melodic minor", MelodicMinorMode.Items, "A", MelodicMinorSteps, MelodicMinorNames);
        ModeTable<HarmonicMinorScaleDegree>("harmonic minor", HarmonicMinorMode.Items, "A", Theory.HarmonicMinorSteps, HarmonicMinorNames);

        Title("The short names: IScaleDegreeNaming.ToShortName against the triad on each degree");
        Columns("degree type", 16, 30);
        (string Scale, string Course, string Ga)[] shortNames =
        [
            ("major", TriadNumerals("C", Theory.MajorSteps), ShortNames<MajorScaleDegree>()),
            ("natural minor", TriadNumerals("A", Theory.NaturalMinorSteps), ShortNames<NaturalMinorScaleDegree>()),
            ("harmonic minor", TriadNumerals("A", Theory.HarmonicMinorSteps), ShortNames<HarmonicMinorScaleDegree>()),
            ("melodic minor", TriadNumerals("A", MelodicMinorSteps), ShortNames<MelodicMinorScaleDegree>()),
            ("harmonic major", TriadNumerals("C", HarmonicMajorSteps), ShortNames<HarmonicMajorScaleDegree>()),
        ];
        var differ = 0;
        foreach (var (scale, course, ga) in shortNames)
        {
            Row(scale, course, ga);
            differ += course.Split(' ').Zip(ga.Split(' ')).Count(pair => pair.First != pair.Second);
        }
        Line($"degrees that differ: {differ} of {5 * 7}");

        Title("Brightness: the course's sum of degrees against GA's StepBrightness and IcvBrightness");
        Line($"{"mode",-20} {"course sum",10} {"StepBrightness",15} {"IcvBrightness",14}");
        (string Scale, IReadOnlyList<PitchClassSet> Sets, int[] Steps, string[] Names)[] scales =
        [
            ("major", [.. MajorScaleMode.Items.Select(mode => SetOf(mode))], Theory.MajorSteps, MajorNames),
            ("melodic minor", [.. MelodicMinorMode.Items.Select(mode => SetOf(mode))], MelodicMinorSteps, MelodicMinorNames),
            ("harmonic minor", [.. HarmonicMinorMode.Items.Select(mode => SetOf(mode))], Theory.HarmonicMinorSteps, HarmonicMinorNames),
        ];
        foreach (var (_, sets, steps, names) in scales)
        {
            for (var k = 0; k < 7; k++)
            {
                var icv = IcvBrightness(ParseIcv(sets[k].IntervalClassVector.Id.ToString()));
                Line($"{names[k],-20} {Brightness(Rotate(steps, k)),10} {sets[k].StepBrightness,15:F4} {icv,14:F6}");
            }
        }
        Line();
        Line("StepBrightness over GA's 4096 sets, by value:");
        var byValue = PitchClassSet.Items
            .GroupBy(set => set.StepBrightness)
            .OrderByDescending(group => group.Key)
            .ToList();
        foreach (var group in byValue)
        {
            var sizes = group.Select(set => set.Count).Distinct().Order();
            Line($"  {group.Key:F4}  sets of {string.Join(", ", sizes)} notes ({group.Count()} sets)");
        }
        Line($"{byValue.Count} values");

        // The course's name for each mode on C of the four scales, by 12-bit number, to label GA's ranking
        (int[] Steps, string[] Names)[] parents =
            [(Theory.MajorSteps, MajorNames), (MelodicMinorSteps, MelodicMinorNames), (Theory.HarmonicMinorSteps, HarmonicMinorNames), (HarmonicMajorSteps, HarmonicMajorNames)];
        var nameOf = parents
            .SelectMany(p => Enumerable.Range(0, 7).Select(k => (Id: Theory.FromSteps(Rotate(p.Steps, k)), Name: p.Names[k])))
            .ToDictionary(m => m.Id, m => m.Name);
        var service = new UnifiedModeService();
        (string Scale, ScaleMode First, int[] Steps, string[] Names)[] families =
        [
            ("major", MajorScaleMode.Items.First(), Theory.MajorSteps, MajorNames),
            ("melodic minor", MelodicMinorMode.Items.First(), MelodicMinorSteps, MelodicMinorNames),
            ("harmonic minor", HarmonicMinorMode.Items.First(), Theory.HarmonicMinorSteps, HarmonicMinorNames),
        ];
        foreach (var (scale, first, steps, names) in families)
        {
            Title($"UnifiedModeService.RankByBrightness (GA.Domain.Services, compiled) for the family of {scale}, against the course's ranking of its modes");
            var instance = service.FromScaleMode(first, PitchClass.C);
            var ranked = service.RankByBrightness(instance.Class, PitchClass.C).ToList();
            var course = Enumerable.Range(0, 7)
                .Select(k => (Name: names[k], Sum: Brightness(Rotate(steps, k))))
                .OrderByDescending(m => m.Sum)
                .ToList();
            Columns("rank", 6, 28);
            for (var i = 0; i < Math.Max(course.Count, ranked.Count); i++)
            {
                var ga = i < ranked.Count
                    ? $"{(nameOf.TryGetValue(ranked[i].Instance.RotationSet.Id.Value, out var name) ? name : ranked[i].Instance.RotationSet.ToString())} {ranked[i].Brightness}"
                    : null;
                Row($"{i + 1}", i < course.Count ? $"{course[i].Name} {course[i].Sum}" : null, ga);
            }
        }

        Title("Modes.yaml (GA.Business.Config, read by ModesConfig): each family's declared vector against the vector of its first mode's notes");
        var all = ModesConfig.GetAllModes();
        var yamlFamilies = all.GroupBy(mode => mode.FamilyName.Value).ToList();
        Line($"{yamlFamilies.Count} families, {all.Count} modes, {yamlFamilies.Count(f => f.First().IntervalClassVector != "")} families with a declared vector");
        var agree = all.Count(mode => GaIcv(mode.Notes) == CourseIcv(mode.Notes));
        Line($"GA's PitchClassSet and the course give the same vector for the notes of {agree} of the {all.Count} modes");
        Line("course: the vector of the first mode's notes; GA: the vector the family declares");
        Columns("family", 28, 22);
        var wrong = 0;
        foreach (var family in yamlFamilies.Where(f => f.First().IntervalClassVector != ""))
        {
            var computed = CourseIcv(family.First().Notes);
            wrong += computed == family.First().IntervalClassVector ? 0 : 1;
            Row(family.Key.Replace(" Family", ""), computed, family.First().IntervalClassVector);
        }
        Line($"declared vectors that differ: {wrong}");
        Line();
        Line("Modes whose notes do not have the vector of their family's first mode:");
        var members = 0;
        var outside = 0;
        foreach (var family in yamlFamilies)
        {
            var reference = GaIcv(family.First().Notes);
            var others = family.Skip(1).ToList();
            var count = others.Count(mode => GaIcv(mode.Notes) != reference);
            members += others.Count;
            outside += count;
            if (count > 0)
            {
                Line($"  {family.Key,-32} {count} of {others.Count}");
            }
        }
        Line($"{outside} of {members}");
        foreach (var name in new[] { "Harmonic Minor Family", "Melodic Minor Family" })
        {
            Line();
            Headings(name, "Notes", "GA's vector", 22, 24);
            foreach (var mode in yamlFamilies.Single(f => f.Key == name))
            {
                Plain(mode.Name, mode.Notes, GaIcv(mode.Notes));
            }
        }

        Title("ModesConfig.TryGetModeByIntervalClassVector, the \"Scale:\" line of ga_chord_to_set, with the vectors GA computes");
        Line("course: the entry of Modes.yaml whose notes are the set; GA: what the lookup returns");
        Columns("set", 18, 26);
        (string Label, string Notes, string Entry)[] lookups =
        [
            ("C major", "C D E F G A B", "Ionian"),
            ("A harmonic minor", "A B C D E F G#", "Harmonic Minor"),
            ("A melodic minor", "A B C D E F# G#", "Melodic Minor"),
            ("Cmaj7", "C E G B", "Major Seventh"),
            ("G7", "G B D F", "Dominant Seventh"),
            ("Bm7b5", "B D F A", "Half Diminished Seventh"),
            ("C", "C E G", "Major Triad"),
            ("Cm", "C Eb G", "Minor Triad"),
        ];
        foreach (var (label, notes, entry) in lookups)
        {
            var found = ModesConfig.TryGetModeByIntervalClassVector(GaIcv(notes));
            Row(label, entry, FSharpOption<ModesConfig.ModeInfo>.get_IsSome(found) ? found.Value.Name : null);
        }

        Title("ModesConfig.TryGetModeByName, behind get_mode_info, with the names of GA's two mode classes");
        Headings("name", "found", "", 22, 30);
        var gaNames = MelodicMinorMode.Items.Select(mode => mode.Name).Concat(HarmonicMinorMode.Items.Select(mode => mode.Name)).ToList();
        var foundCount = 0;
        foreach (var name in gaNames.Concat(["Super Locrian", "Acoustic Scale", "Spanish Phrygian", "Ultralocrian"]))
        {
            var found = ModesConfig.TryGetModeByName(name);
            var isFound = FSharpOption<ModesConfig.ModeInfo>.get_IsSome(found);
            foundCount += isFound && gaNames.Contains(name) ? 1 : 0;
            Plain(name, isFound ? $"{found.Value.Name} ({found.Value.FamilyName.Value})" : "not found");
        }
        Line($"GA's names found: {foundCount} of {gaNames.Count}");
        var kept = ModesConfig.GetModalFamilies().Sum(family => family.Modes.Sum(mode => mode.AlternateNames.Count));
        var withAlternates = all.Count(mode => FSharpOption<IReadOnlyList<string>>.get_IsSome(mode.AlternateNames));
        Line($"alternate names: GetModalFamilies keeps {kept}; GetAllModes keeps them on {withAlternates} of {all.Count} modes");

        // Added after the first run, in its own commit: the two things the first run showed without a test
        Title("Added after the first run: the names written in Modes.yaml against the names ModesConfig returns");
        Line("course: the name as the file writes it; GA: the name the loader returns (YAML reads \" #\" as the start of a comment)");
        var lines = File.ReadAllLines(ModesConfig.getConfigPath().Value);
        var written = Enumerable.Range(0, lines.Length)
            .Where(i => lines[i].StartsWith("      - Name:", StringComparison.Ordinal))
            .Select(i => (Line: i + 1, Name: Unquote(lines[i]["      - Name:".Length..].Trim())))
            .ToList();
        Columns("line", 6, 34);
        var truncated = 0;
        foreach (var (entry, mode) in written.Zip(all))
        {
            if (entry.Name != mode.Name)
            {
                Row($"{entry.Line}", entry.Name, mode.Name);
                truncated++;
            }
        }
        Line($"names that differ: {truncated} of {written.Count}");
        var repeated = all.GroupBy(mode => mode.Name).Where(group => group.Count() > 1).ToList();
        Line($"names ModesConfig returns more than once: {repeated.Count}");
        foreach (var group in repeated)
        {
            Line($"  {group.Key}: {string.Join(", ", group.Select(mode => mode.FamilyName.Value.Replace(" Family", "")))}");
        }
        Line();
        Line("The modes whose vector GA's PitchClassSet and the course disagree on:");
        foreach (var mode in all.Where(mode => GaIcv(mode.Notes) != CourseIcv(mode.Notes)))
        {
            Line($"  {mode.Name}: {mode.Notes}, GA {GaIcv(mode.Notes)}, course {CourseIcv(mode.Notes)}");
        }
    }

    static string Unquote(string value) => value.Length > 1 && value[0] == '\'' && value[^1] == '\'' ? value[1..^1] : value;
}
