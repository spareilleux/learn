using GA.Business.Config;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Core.Theory.Harmony;
using GA.Domain.Services.Chords;
using GA.Domain.Services.Chords.Parsing;
using Microsoft.FSharp.Core;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 13 of the course, run as `l15`: extended and altered chords, how GA reads their symbols and names them,
// upper structures and polychords
public static class Lesson15
{
    // ---- The course's side: a symbol names the chord's highest extension and implies the ones below it (Open Music Theory,
    // "Chord Symbols"): the ninth, eleventh and thirteenth default to major, perfect and major, the seventh to minor

    // 41 symbols on C in four groups, with the pitch classes the course reads in each; null: not a chord symbol.
    // The spellings come from Open Music Theory and Wikipedia ("Chord names and symbols (popular music)"); the first 11
    // are the extended chords in GA's two suffix tables
    static readonly (string Group, string Symbol, int[]? Pcs)[] Symbols =
    [
        ("extended", "C9", [0, 2, 4, 7, 10]),
        ("extended", "Cmaj9", [0, 2, 4, 7, 11]),
        ("extended", "Cm9", [0, 2, 3, 7, 10]),
        ("extended", "C11", [0, 2, 4, 5, 7, 10]),
        ("extended", "Cmaj11", [0, 2, 4, 5, 7, 11]),
        ("extended", "Cm11", [0, 2, 3, 5, 7, 10]),
        ("extended", "C13", [0, 2, 4, 5, 7, 9, 10]),
        ("extended", "Cmaj13", [0, 2, 4, 5, 7, 9, 11]),
        ("extended", "Cm13", [0, 2, 3, 5, 7, 9, 10]),
        ("extended", "C6/9", [0, 2, 4, 7, 9]),
        ("extended", "Cadd9", [0, 2, 4, 7]),
        ("extended", "Cadd2", [0, 2, 4, 7]),
        ("extended", "C7sus", [0, 5, 7, 10]),
        ("extended", "C9sus4", [0, 2, 5, 7, 10]),
        ("altered", "C7b9", [0, 1, 4, 7, 10]),
        ("altered", "C7#9", [0, 3, 4, 7, 10]),
        ("altered", "C7#11", [0, 4, 6, 7, 10]),
        ("altered", "C7b13", [0, 4, 7, 8, 10]),
        ("altered", "C7b5", [0, 4, 6, 10]),
        ("altered", "C7#5", [0, 4, 8, 10]),
        ("altered", "C7alt", [0, 1, 3, 4, 6, 8, 10]),
        ("altered", "C9#11", [0, 2, 4, 6, 7, 10]),
        ("altered", "C7b9#11", [0, 1, 4, 6, 7, 10]),
        ("altered", "C7#9b13", [0, 3, 4, 7, 8, 10]),
        ("altered", "Cmaj7#11", [0, 4, 6, 7, 11]),
        ("spellings", "Cmi", [0, 3, 7]),
        ("spellings", "Cmi7", [0, 3, 7, 10]),
        ("spellings", "Cma7", [0, 4, 7, 11]),
        ("spellings", "CM7", [0, 4, 7, 11]),
        ("spellings", "CΔ7", [0, 4, 7, 11]),
        ("spellings", "C∆7", [0, 4, 7, 11]),
        ("spellings", "Co7", [0, 3, 6, 9]),
        ("spellings", "Cø7", [0, 3, 6, 10]),
        ("spellings", "Cm(b5)", [0, 3, 6]),
        ("spellings", "Cm7♭5", [0, 3, 6, 10]),
        ("spellings", "C+7", [0, 4, 8, 10]),
        ("spellings", "Cm(maj7)", [0, 3, 7, 11]),
        ("slash chords and words", "C/E", [0, 4, 7]),
        ("slash chords and words", "C/F#", [0, 4, 6, 7]),
        ("slash chords and words", "Can", null),
        ("slash chords and words", "Give", null),
    ];

    static IEnumerable<(string Group, string Symbol, int[]? Pcs)> Extended => Symbols.Take(11);

    // GA's nine altered chords on C (ChordAlterationService.GetCommonAlteredChords), with the pitch classes their names mean;
    // C7alt is Wikipedia's C7♯5♭9♯9♯11 ("Altered scale")
    static readonly Dictionary<string, int[]> AlteredOnC = new()
    {
        ["C7alt"] = [0, 1, 3, 4, 6, 8, 10],
        ["C7(b9)"] = [0, 1, 4, 7, 10],
        ["C7(#9)"] = [0, 3, 4, 7, 10],
        ["C7(b5)"] = [0, 4, 6, 10],
        ["C7(#5)"] = [0, 4, 8, 10],
        ["C7(#11)"] = [0, 4, 6, 7, 10],
        ["C7(b13)"] = [0, 4, 7, 8, 10],
        ["C7(b9,#11)"] = [0, 1, 4, 6, 7, 10],
        ["Cmaj7(#11)"] = [0, 4, 6, 7, 11],
    };

    // Chords whose fifth is the lowered or raised one by definition
    static readonly (string Symbol, int[] Pcs)[] FifthChords =
        [("Cdim", [0, 3, 6]), ("Caug", [0, 4, 8]), ("Cm7b5", [0, 3, 6, 10]), ("Cdim7", [0, 3, 6, 9])];

    // The degree a pitch class plays above C in a dominant chord, the names upper structures use
    static readonly string[] Degrees = ["1", "♭9", "9", "♯9", "3", "11", "♯11", "5", "♭13", "13", "♭7", "7"];

    static string DegreesOf(IEnumerable<int> pcs) => string.Join(" ", pcs.Select(pc => Degrees[Theory.Mod12(pc)]));

    // Wikipedia's upper structures ("Upper structure", after Levine, The Jazz Piano Book, ch. 14), keyed by triad root and quality,
    // with the chord each one makes over C7
    static readonly Dictionary<(int Root, bool Minor), (string Label, string Result)> Wikipedia = new()
    {
        [(2, false)] = ("USII", "C13♯11"),
        [(3, false)] = ("US♭III", "C7♯9"),
        [(6, false)] = ("US♭V", "C7♭9♯11"),
        [(8, false)] = ("US♭VI", "C7♯9♭13"),
        [(9, false)] = ("USVI", "C13♭9"),
        [(0, true)] = ("USi", "C7♯9"),
        [(1, true)] = ("US♭ii", "C7♭9♭13"),
        [(3, true)] = ("US♭iii", "C7♯9♯11"),
        [(6, true)] = ("US♯iv", "C13♭9♯11"),
    };

    static readonly string[] Flats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"];

    // Wikipedia writes G♭ major (US♭V) but F♯ minor (US♯iv)
    static string TriadName(int root, bool minor) => (minor && root == 6 ? "F♯" : Flats[root]) + (minor ? "m" : "");

    // The 28 modes of lesson 11: major, melodic minor, harmonic minor and harmonic major, with their textbook names
    static readonly (string[] Names, int[] Steps)[] Scales =
    [
        (Lesson13.MajorNames, Theory.MajorSteps),
        (Lesson13.MelodicMinorNames, Lesson13.MelodicMinorSteps),
        (Lesson13.HarmonicMinorNames, Theory.HarmonicMinorSteps),
        (Lesson13.HarmonicMajorNames, Lesson13.HarmonicMajorSteps),
    ];

    // Mode k of a scale, on a root: the step pattern read from its k-th step
    static int ModeOn(int[] steps, int k, int root) => Theory.Transpose(Theory.FromSteps([.. steps[k..], .. steps[..k]]), root);

    static IEnumerable<string> ModesContaining(int id, int root) =>
        from scale in Scales
        from k in Enumerable.Range(0, 7)
        where (ModeOn(scale.Steps, k, root) & id) == id
        select scale.Names[k];

    // ---- GA's side

    static readonly ChordSymbolParser Parser = new();

    // A parsed symbol's pitch classes; a parser that throws ArgumentException rejects the symbol
    static string Read(Func<Chord> parse)
    {
        try
        {
            return parse().PitchClassSet.ToString();
        }
        catch (ArgumentException)
        {
            return "rejects";
        }
        catch (Exception e)
        {
            return $"throws {e.GetType().Name}";
        }
    }

    static string FromSymbol(string symbol) => Read(() => Chord.FromSymbol(symbol));

    static string Parsed(string symbol) => Read(() => Parser.Parse(symbol));

    static string Catalog(IEnumerable<int> pcs) => CanonicalChordPatternCatalog.TryFindExact([.. pcs.Order()])?.Name ?? "(none)";

    static PitchClassSet Set(IEnumerable<int> pcs) => new(pcs.Select(PitchClass.FromValue));

    static string Check(string a, string b) => a == b ? "ok" : "DIFF";

    // The extension GA's chord template factory was asked for: the word after "Degree<n>" in the template's name
    // (ChordTemplateFactory.cs, line 477)
    static string Requested(ChordTemplate template)
    {
        var name = template.Name;
        return name[(name.LastIndexOf(" Degree", StringComparison.Ordinal) + 1)..].Split(' ')[1];
    }

    // ga_polychord (GaMcpServer/Tools/ChordAtonalTool.cs, not compiled) copied as it is, lines 23-30, 32-34, 53-54, 61-69
    // and 99-125, with one change: its chord pitch classes come from the F# closure domain.chordIntervals of GA.Business.DSL,
    // which the course cannot compile; for a major or minor triad that closure returns P1 M3 P5 or P1 m3 P5
    // (DomainClosures.fs, lines 78-92 and 199-227), and the course does the same

    private static readonly IReadOnlyDictionary<string, int> IntervalSemitones =
        new Dictionary<string, int>
        {
            ["P1"] = 0, ["m2"] = 1, ["M2"] = 2,  ["m3"] = 3,
            ["M3"] = 4, ["P4"] = 5, ["TT"] = 6,  ["P5"] = 7,
            ["m6"] = 8, ["M6"] = 9, ["m7"] = 10, ["M7"] = 11,
            ["M9"] = 14, ["P11"] = 17, ["M13"] = 21
        };

    private static readonly IReadOnlyDictionary<string, int> NoteToSemitone =
        new Dictionary<string, int>
        { ["C"]=0,["D"]=2,["E"]=4,["F"]=5,["G"]=7,["A"]=9,["B"]=11 };

    private static readonly string[] NoteNames =
        ["C","C#","D","Eb","E","F","F#","G","Ab","A","Bb","B"];

    private static int ParseRootPc(string symbol)
    {
        if (string.IsNullOrEmpty(symbol)) return 0;
        var letter = symbol[0].ToString().ToUpperInvariant();
        if (!NoteToSemitone.TryGetValue(letter, out var s)) return 0;
        var acc = symbol.Length > 2 && symbol[1..3] is "##" or "bb" ? symbol[1..3]
                : symbol.Length > 1 ? symbol[1..2] : "";
        return ((s + acc switch { "#" => 1, "b" => -1, "##" => 2, "bb" => -2, _ => 0 }) % 12 + 12) % 12;
    }

    // The course's stand-in for GetIntervalNamesAsync, for major and minor triads only
    static string[] TriadIntervalNames(string symbol) => symbol.EndsWith('m') ? ["P1", "m3", "P5"] : ["P1", "M3", "P5"];

    // GetPitchClassesAsync, lines 87-97, without the async call
    private static int[] GetPitchClasses(string symbol)
    {
        var rootPc = ParseRootPc(symbol);
        var intervals = TriadIntervalNames(symbol);
        return [.. intervals
            .Select(iv => IntervalSemitones.TryGetValue(iv, out var s) ? (int?)(rootPc + s) % 12 : null)
            .Where(s => s.HasValue)
            .Select(s => s!.Value)
            .Distinct()
            .Order()];
    }

    private static PitchClassSet ToPitchClassSet(IEnumerable<int> pcs) =>
        new(pcs.Select(PitchClass.FromValue));

    private static string FormatPcs(IEnumerable<int> pcs) =>
        "{" + string.Join(", ", pcs.Select(pc => NoteNames[pc])) + "}";

    private static string AtonalCard(string label, int[] pcs)
    {
        var set = ToPitchClassSet(pcs);
        var icv = set.IntervalClassVector;
        var prime = set.PrimeForm;
        var forte = prime != null ? ForteCatalog.GetForteNumber(prime) : null;
        var family = set.ModalFamily;
        var modeOpt = ModesConfig.TryGetModeByIntervalClassVector(icv.Id.ToString());
        var modeName = FSharpOption<ModesConfig.ModeInfo>.get_IsSome(modeOpt) ? modeOpt.Value.Name : null;

        var sb = new System.Text.StringBuilder();
        sb.AppendLine($"{label,-12}{FormatPcs(pcs)} ({pcs.Length} tones)");
        sb.AppendLine($"  ICV:        {icv}");
        if (forte.HasValue)  sb.AppendLine($"  Forte:      {forte.Value}");
        if (prime != null)   sb.AppendLine($"  Prime form: {prime}");
        if (family != null)
            sb.AppendLine($"  Modal fam.: {family.NoteCount}-note / {family.Modes.Count} modes" +
                          $" (mode {set.ModeIndex + 1})");
        if (modeName != null) sb.AppendLine($"  Scale:      {modeName}");
        return sb.ToString().TrimEnd();
    }

    // GaPolychord, lines 199-218, without the async calls
    static string GaPolychord(string chord1, string chord2)
    {
        var pcs1 = GetPitchClasses(chord1);
        var pcs2 = GetPitchClasses(chord2);
        if (pcs1.Length == 0) return $"Error: could not parse '{chord1}'";
        if (pcs2.Length == 0) return $"Error: could not parse '{chord2}'";

        var merged = pcs1.Union(pcs2).Order().ToArray();

        var sb = new System.Text.StringBuilder();
        sb.AppendLine($"Polychord: {chord2}/{chord1}");
        sb.AppendLine(AtonalCard("Merged:", merged));
        sb.AppendLine($"  from {chord1}: {FormatPcs(pcs1)}");
        sb.Append($"  from {chord2}: {FormatPcs(pcs2)}");
        return sb.ToString();
    }

    public static void Run()
    {
        // ---- 1. Extended chords

        Title("Extended chords on C: the course's full stacks against Chord.FromSymbol (GA.Domain.Core)");
        Columns("symbol", 8, 16);
        foreach (var (_, symbol, pcs) in Extended)
        {
            Row(symbol, Theory.Format(pcs!), FromSymbol(symbol));
        }

        Title("Naming them back: CanonicalChordPatternCatalog.TryFindExact, ChordFormula.GetSymbolSuffix, and GenerateChordName (BasicChordExtensionsService, GA.Domain.Services, compiled)");
        Console.WriteLine($"{"symbol",-8} {"TryFindExact",-22} {"C + GetSymbolSuffix",-26} GenerateChordName");
        var (found, suffixes, names) = (0, 0, 0);
        foreach (var (_, symbol, pcs) in Extended)
        {
            var formula = Chord.FromSymbol(symbol).Formula;
            var suffix = "C" + formula.GetSymbolSuffix();
            var name = BasicChordExtensionsService.GenerateChordName(PitchClass.C, formula.Quality, formula.Extension);
            var catalog = Catalog(pcs!);
            Console.WriteLine($"{symbol,-8} {catalog,-22} {suffix,-8} {Check(suffix, symbol),-17} {name,-8} {Check(name, symbol)}");
            found += catalog == "(none)" ? 0 : 1;
            suffixes += suffix == symbol ? 1 : 0;
            names += name == symbol ? 1 : 0;
        }
        Line($"TryFindExact names {found} of 11; GetSymbolSuffix gives back {suffixes}, GenerateChordName {names}");

        Title("C13 as a full stack: the pitch classes of Fmaj13, Gm13 and the F major scale");
        var c13 = Theory.SetId(Symbols.Single(s => s.Symbol == "C13").Pcs!);
        var fMaj13 = Theory.Transpose(Theory.SetId(Symbols.Single(s => s.Symbol == "Cmaj13").Pcs!), 5);
        var gM13 = Theory.Transpose(Theory.SetId(Symbols.Single(s => s.Symbol == "Cm13").Pcs!), 7);
        var fMajor = Theory.Transpose(Theory.FromSteps(Theory.MajorSteps), 5);
        Headings("", "course", "Chord.FromSymbol", 14, 22);
        Plain("C13", Theory.Format(Theory.PitchClasses(c13)), FromSymbol("C13"));
        Plain("Fmaj13", Theory.Format(Theory.PitchClasses(fMaj13)), FromSymbol("Fmaj13"));
        Plain("Gm13", Theory.Format(Theory.PitchClasses(gM13)), FromSymbol("Gm13"));
        Plain("F major scale", Theory.Format(Theory.PitchClasses(fMajor)));
        Line($"the four sets are equal: {c13 == fMaj13 && c13 == gM13 && c13 == fMajor}");
        int[] withoutEleventh = [0, 2, 4, 7, 9, 10];
        Line($"C13 without the 11th (Wikipedia, \"Thirteenth\"): {Theory.Format(withoutEleventh)}, TryFindExact: {Catalog(withoutEleventh)}");

        Title("Three guitar voicings in the course's figure (standard tuning): the degrees they keep over C");
        Headings("shape", "degrees, low to high", "TryFindExact on the intervals from the bass", 12, 22);
        foreach (var (shape, symbol) in new[] { ("x3233x", "C9"), ("x32335", "C13"), ("x3234x", "C7#9") })
        {
            var played = Lesson3.Played(shape);
            Plain($"{shape} {symbol}", DegreesOf(played), Catalog(played.Select(midi => Theory.Mod12(midi - played[0])).Distinct()));
        }

        // ---- 2. Reading the symbols

        Title("41 symbols on C: the course's reading against GA's two parsers, Chord.FromSymbol and ChordSymbolParser.Parse (GA.Domain.Services, compiled)");
        Console.WriteLine($"{"symbol",-9} {"course",-16} {"FromSymbol",-16} {"",-5} {"ChordSymbolParser",-17} check");
        foreach (var group in Symbols.GroupBy(s => s.Group))
        {
            Line($"-- {group.Key}");
            foreach (var (_, symbol, pcs) in group)
            {
                var course = pcs is null ? "rejects" : Theory.Format(pcs);
                var (a, b) = (FromSymbol(symbol), Parsed(symbol));
                Console.WriteLine($"{symbol,-9} {course,-16} {a,-16} {Check(a, course),-5} {b,-17} {Check(b, course)}");
            }
        }
        Line();
        Console.WriteLine($"{"group",-24} {"symbols",-8} {"FromSymbol right",-17} {"rejects",-8} {"Parser right",-13} rejects");
        void Counts(string label, IEnumerable<(string Group, string Symbol, int[]? Pcs)> symbols)
        {
            var list = symbols.ToList();
            string CourseOf(int[]? pcs) => pcs is null ? "rejects" : Theory.Format(pcs);
            Console.WriteLine($"{label,-24} {list.Count,-8} {list.Count(s => FromSymbol(s.Symbol) == CourseOf(s.Pcs)),-17} " +
                $"{list.Count(s => FromSymbol(s.Symbol) == "rejects"),-8} {list.Count(s => Parsed(s.Symbol) == CourseOf(s.Pcs)),-13} " +
                $"{list.Count(s => Parsed(s.Symbol) == "rejects")}");
        }
        foreach (var group in Symbols.GroupBy(s => s.Group)) Counts(group.Key, group);
        Counts("all", Symbols);

        // ---- 3. Naming the alterations

        Title("GA's nine altered chords on C (ChordAlterationService, GA.Domain.Services, compiled), through ChordTemplate.Analytical.FromPitchClassSet");
        Console.WriteLine($"{"GA's list",-12} {"pitch classes",-16} {"quality",-10} {"extension",-10} {"alterations",-12} {"GenerateNameWithAlterations",-28} check");
        void Altered(string symbol, int[] pcs)
        {
            var template = ChordTemplate.Analytical.FromPitchClassSet(Set(pcs), PitchClass.C, symbol);
            var analysis = ChordAlterationService.AnalyzeAlterations(template);
            var name = ChordAlterationService.GenerateNameWithAlterations(PitchClass.C, template);
            var alterations = analysis.AlterationString == "" ? "(none)" : analysis.AlterationString;
            Console.WriteLine($"{symbol,-12} {Theory.Format(pcs),-16} {template.Quality,-10} {template.Extension,-10} {alterations,-12} {name,-28} {Check(name, symbol)}");
        }
        var common = ChordAlterationService.GetCommonAlteredChords(PitchClass.C).ToList();
        foreach (var (symbol, _) in common) Altered(symbol, AlteredOnC[symbol]);
        Line();
        Console.WriteLine($"{"GA's list",-12} {"IsAlteredDominant",-18} {"SuggestedNotation",-34} {"TryFindExact",-22} GA's description");
        foreach (var (symbol, description) in common)
        {
            var template = ChordTemplate.Analytical.FromPitchClassSet(Set(AlteredOnC[symbol]), PitchClass.C, symbol);
            var analysis = ChordAlterationService.AnalyzeAlterations(template);
            Console.WriteLine($"{symbol,-12} {analysis.IsAlteredDominant,-18} {analysis.SuggestedNotation,-34} {Catalog(AlteredOnC[symbol]),-22} {description}");
        }

        Title("Chords whose fifth is lowered or raised by definition, through the same calls");
        Console.WriteLine($"{"symbol",-12} {"pitch classes",-16} {"quality",-10} {"extension",-10} {"alterations",-12} {"GenerateNameWithAlterations",-28} check");
        foreach (var (symbol, pcs) in FifthChords) Altered(symbol, pcs);

        // ---- 4. The alterations GA's chord templates can carry

        Title("ChordTemplateFactory.GenerateAllPossibleChords (GA.Domain.Services, compiled): the alterations ChordAlterationService finds, by requested extension");
        var templates = ChordTemplateFactory.GenerateAllPossibleChords().ToList();
        var half = templates.Count / 2;
        var repeats = templates.Count % 2 == 0 && Enumerable.Range(0, half).All(i =>
            templates[i].Name == templates[half + i].Name && templates[i].PitchClassSet.ToString() == templates[half + i].PitchClassSet.ToString());
        Line($"templates: {templates.Count}; the second half repeats the first, name and pitch classes: {repeats}");
        Line($"distinct names: {templates.Select(t => t.Name).Distinct().Count()}");
        Line();
        var types = Enum.GetValues<ChordAlterationService.AlterationType>();
        var found4 = templates.Select(t => (Requested: Requested(t), Alterations: ChordAlterationService.AnalyzeAlterations(t).Alterations)).ToList();
        Console.WriteLine($"{"extension",-12} {"templates",-10} " + string.Join(" ", types.Select(t => $"{t,-15}")).TrimEnd());
        foreach (var group in found4.GroupBy(t => t.Requested))
        {
            Console.WriteLine($"{group.Key,-12} {group.Count(),-10} " + string.Join(" ", types.Select(type => $"{group.Count(t => t.Alterations.Contains(type)),-15}")).TrimEnd());
        }
        Console.WriteLine($"{"all",-12} {found4.Count,-10} " + string.Join(" ", types.Select(type => $"{found4.Count(t => t.Alterations.Contains(type)),-15}")).TrimEnd());

        // ---- 5. Upper structures

        Title("Upper structures over C7 (C E G B♭): the 24 major and minor triads that avoid F (the 11th) and B (the major 7th)");
        Console.WriteLine($"{"triad",-7} {"degrees over C",-16} {"with C7",-22} Wikipedia");
        var kept = 0;
        foreach (var minor in new[] { false, true })
        {
            foreach (var root in Enumerable.Range(0, 12))
            {
                int[] triad = [root, Theory.Mod12(root + (minor ? 3 : 4)), Theory.Mod12(root + 7)];
                if (triad.Contains(5) || triad.Contains(11)) continue;
                kept++;
                var withC7 = Theory.Format(Theory.PitchClasses(Theory.SetId([0, 4, 7, 10, .. triad])));
                var label = Wikipedia.TryGetValue((root, minor), out var us) ? $"{us.Label}, {us.Result}" : "";
                Console.WriteLine($"{TriadName(root, minor),-7} {DegreesOf(triad),-16} {withC7,-22} {label}".TrimEnd());
            }
        }
        Line($"triads kept: {kept} of 24, {Wikipedia.Count} of them in Wikipedia's list");
        Line($"CanonicalChordPatternCatalog patterns named upper structure or polychord: {CanonicalChordPatternCatalog.All.Count(p => p.Name.Contains("upper", StringComparison.OrdinalIgnoreCase) || p.Name.Contains("poly", StringComparison.OrdinalIgnoreCase))} of {CanonicalChordPatternCatalog.All.Count}");

        // ---- 6. Polychords

        Title("ga_polychord (GaMcpServer, not compiled), rebuilt above, on five polychords; then the modes of lesson 11 that contain each");
        Line("its description: \"Example: B triad over C triad → Lydian mode set {C,D,E,F#,G,B}.\" (ChordAtonalTool.cs, line 198)");
        foreach (var (lower, upper, source) in new[]
        {
            ("C", "B", "the tool's description"),
            ("C", "Bm", "the set the description names"),
            ("F#", "C", "AdvancedHarmony.yaml, line 102: \"C major over F# major\""),
            ("Eb", "D", "skills-dev/_pending-tools/polychord/DRAFT.md, line 46: \"D over Eb\""),
            ("D", "C", "DRAFT.md, line 45: \"C/D\""),
        })
        {
            Line();
            Line($"-- {upper} over {lower}, from {source}");
            Line(GaPolychord(lower, upper));
            var root = ParseRootPc(lower);
            var merged = Theory.SetId([.. GetPitchClasses(lower), .. GetPitchClasses(upper)]);
            var modes = ModesContaining(merged, root).ToList();
            Line($"  the 28 modes on {lower} that contain it: {(modes.Count == 0 ? "none" : string.Join(", ", modes))}");
            Line($"  octatonic on {lower}: half-whole {(Theory.Transpose(Theory.FromSteps([1, 2, 1, 2, 1, 2, 1, 2]), root) & merged) == merged}, " +
                $"whole-half {(Theory.Transpose(Theory.FromSteps([2, 1, 2, 1, 2, 1, 2, 1]), root) & merged) == merged}");
        }

        // ---- 7. What GA's content files say

        Title("GA's YamlKnowledgeLoader (GA.Business.Config, compiled): the entries of ExtendedChords.yaml, AdvancedHarmony.yaml and the Petrushka chord of IconicChords.yaml");
        var entries = YamlKnowledgeLoader.LoadAllKnowledgeEntries().ToList();
        foreach (var file in new[] { "ExtendedChords", "AdvancedHarmony" })
        {
            var fromFile = entries.Where(e => e.SourceFile == file).ToList();
            Line($"  {fromFile.Count} entries from {file}.yaml: {string.Join(", ", fromFile.Select(e => e.Name))}");
        }
        foreach (var line in entries.Where(e => e.SourceFile == "ExtendedChords").SelectMany(e => e.Content.Split('\n')).Where(l => l.StartsWith("Formula:")))
        {
            Line($"    {line}");
        }
        var polychords = entries.Single(e => e.SourceFile == "AdvancedHarmony" && e.Name == "Polychords");
        Line($"  \"Creates all 12 chromatic pitches\" in the Polychords entry: {(polychords.Content.Contains("Creates all 12 chromatic pitches") ? "yes" : "no")}");
        foreach (var petrushka in entries.Where(e => e.SourceFile == "IconicChords" && e.Name == "Petrushka Chord"))
        {
            foreach (var line in petrushka.Content.Split('\n').Where(l => l.StartsWith("TheoreticalName:") || l.StartsWith("PitchClasses:")))
            {
                Line($"    IconicChords.yaml, Petrushka Chord, {line}");
            }
        }
    }
}
