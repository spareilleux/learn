using System.Collections.Immutable;
using System.Globalization;
using GA.Business.Core.Analysis.Voicings;
using GA.Business.Core.Context;
using GA.Domain.Core.Instruments;
using GA.Domain.Core.Instruments.Biomechanics;
using GA.Domain.Core.Instruments.Positions;
using GA.Domain.Core.Instruments.Primitives;
using GA.Domain.Core.Primitives.Notes;
using GA.Domain.Services.Fretboard.Analysis;
using GA.Domain.Services.Fretboard.Biomechanics;
using GA.Domain.Services.Fretboard.Voicings.Analysis;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 15 of the course, run as `l17`: where the frets go, how far a hand reaches, the CAGED shapes, how GA measures
// the effort of a shape, the open tunings of Tunings.toml and the table behind the ga_easier_voicings tool
public static class Lesson17
{
    // ---- The course's side

    static readonly string[] Standard = ["E2", "A2", "D3", "G3", "B3", "E4"]; // string 6 to string 1

    // Distance from the nut to fret n on a scale of length L: d(n) = L(1 − 2^(−n/12))
    static double FromNut(int fret, double scale) => scale * (1 - Math.Pow(2, -fret / 12.0));

    static string F(double value, string format = "F2") => value.ToString(format, CultureInfo.InvariantCulture);

    static string Yes(bool value) => value ? "yes" : "no";

    static string Pretty(string notes) => notes.Replace("#", "♯").Replace("b", "♭");

    // A shape written from string 6: "x32010", or with dashes when a fret is above 9, "8-10-10-9-8-8"; null for a muted string
    static int?[] Frets(string shape) =>
        [.. (shape.Contains('-') ? shape.Split('-') : shape.Select(c => c.ToString())).Select(f => f == "x" ? (int?)null : int.Parse(f, CultureInfo.InvariantCulture))];

    static string Shape(IReadOnlyList<int?> frets)
    {
        var parts = frets.Select(f => f is null ? "x" : f.Value.ToString(CultureInfo.InvariantCulture));
        return frets.Any(f => f > 9) ? string.Join("-", parts) : string.Concat(parts);
    }

    // The sounding notes of a shape in standard tuning, from string 6 to string 1
    static int[] Midi(IReadOnlyList<int?> frets) =>
        [.. frets.Select((f, i) => f is null ? -1 : Theory.MidiOf(Standard[i]) + f.Value).Where(m => m >= 0)];

    static string Pitches(IEnumerable<int> midi) => string.Join(" ", midi.Select(m => Theory.PitchName(m).Replace("#", "♯")));

    // The frets held down: open and muted strings left out
    static int[] Fretted(IEnumerable<int?> frets) => [.. frets.Where(f => f > 0).Select(f => f!.Value)];

    // The distance between the lowest and the highest fret held, in millimetres on 647.7 mm
    static double SpanMm(IEnumerable<int?> frets)
    {
        var held = Fretted(frets);
        return held.Length < 2 ? 0 : FromNut(held.Max(), BiomechanicsConstants.StandardScaleLengthMm) - FromNut(held.Min(), BiomechanicsConstants.StandardScaleLengthMm);
    }

    static string Degree(int semitones) => Theory.Mod12(semitones) switch { 0 => "R", 4 => "3", 7 => "5", var other => other.ToString(CultureInfo.InvariantCulture) };

    // A set of pitch classes named as a major or minor triad when it is one, otherwise listed
    static string ChordName(IEnumerable<int> pitchClasses)
    {
        var set = pitchClasses.Select(Theory.Mod12).Distinct().Order().ToArray();
        for (var root = 0; root < 12; root++)
        {
            var name = Theory.PcName(root).Replace("#", "♯");
            if (set.SequenceEqual(new[] { root, root + 4, root + 7 }.Select(Theory.Mod12).Order())) return name + " major";
            if (set.SequenceEqual(new[] { root, root + 3, root + 7 }.Select(Theory.Mod12).Order())) return name + " minor";
        }
        return string.Join(" ", set.Select(pc => Theory.PcName(pc).Replace("#", "♯")));
    }

    // ---- GA's side

    // A shape as a GA voicing, its positions in string order 1..6 as GA's generator and ExtractPhysicalLayout number them (lesson 14);
    // reversed, string 6 comes first, as the comments of DetectCagedShape read them
    static Voicing ToVoicing(IReadOnlyList<int?> frets, bool reversed = false)
    {
        var positions = new Position[6];
        for (var s = 1; s <= 6; s++)
        {
            var fret = frets[6 - s];
            positions[s - 1] = fret is null
                ? new Position.Muted(new Str(s))
                : new Position.Played(new PositionLocation(new Str(s), new Fret(fret.Value)), Tuning.Default[new Str(s)].MidiNote + fret.Value);
        }
        if (reversed) Array.Reverse(positions);
        return new Voicing(positions, [.. positions.OfType<Position.Played>().Select(p => p.MidiNote)]);
    }

    static PlayabilityInfo Playability(Voicing voicing) =>
        VoicingPhysicalAnalyzer.CalculatePlayability(VoicingPhysicalAnalyzer.ExtractPhysicalLayout(voicing));

    static string[] PhysicalTags(Voicing voicing)
    {
        var layout = VoicingPhysicalAnalyzer.ExtractPhysicalLayout(voicing);
        var playability = VoicingPhysicalAnalyzer.CalculatePlayability(layout);
        return VoicingPhysicalAnalyzer.GeneratePhysicalTags(layout, playability, VoicingPhysicalAnalyzer.AnalyzeErgonomics(layout, playability));
    }

    // The played strings as PhysicalCostService takes them: string number (6 = low E), fret and pitch
    static List<FretboardPosition> CostShape(IReadOnlyList<int?> frets) =>
        [.. frets.Select((f, i) => (Fret: f, String: 6 - i)).Where(x => x.Fret is not null)
            .Select(x => new FretboardPosition(new Str(x.String), x.Fret!.Value, Pitch.FromMidiNote(Tuning.Default[new Str(x.String)].MidiNote + x.Fret.Value)))];

    static BiomechanicalPlayabilityAnalysis Biomechanics(IReadOnlyList<int?> frets, HandSize hand = HandSize.Medium) =>
        new BiomechanicalAnalyzer(hand).AnalyzeChordPlayability(ToVoicing(frets).Positions.ToImmutableList());

    static string BiomechanicsSummary(BiomechanicalPlayabilityAnalysis b) =>
        $"{F(b.OverallScore, "R")} {b.Difficulty} {b.IsPlayable} {b.FingeringEfficiencyAnalysis?.HasBarreChord} {b.WristPostureAnalysis?.WristAngleDegrees}";

    // The guitar entries of Tunings.toml: a `[Guitar.Name]` header, then a `Tuning = "..."` line
    static List<(string Name, string Tuning)> TomlGuitars(string path)
    {
        var entries = new List<(string, string)>();
        string? name = null;
        foreach (var raw in File.ReadAllLines(path))
        {
            var line = raw.Trim();
            if (line.StartsWith('['))
            {
                name = line.StartsWith("[Guitar.", StringComparison.Ordinal) ? line["[Guitar.".Length..^1].Replace("\"", "") : null;
            }
            else if (name is not null && line.StartsWith("Tuning = \"", StringComparison.Ordinal))
            {
                entries.Add((name, line["Tuning = \"".Length..^1]));
            }
        }
        return entries;
    }

    // The OpenVoicings table of GaEasierVoicingsTool, one `("C", "x32010", 1, false, "C, E, G"),` line per voicing
    static List<(string Symbol, string Frets, int Difficulty, bool HasBarre, string Notes)> EasierVoicings(string path)
    {
        var rows = new List<(string, string, int, bool, string)>();
        var inTable = false;
        foreach (var raw in File.ReadAllLines(path))
        {
            var line = raw.Trim();
            if (line.Contains("OpenVoicings =", StringComparison.Ordinal))
            {
                inTable = true;
                continue;
            }
            if (!inTable) continue;
            if (line.StartsWith("];", StringComparison.Ordinal)) break;
            if (!line.StartsWith("(\"", StringComparison.Ordinal)) continue;
            var parts = line.Split('"');
            var middle = parts[4].Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
            rows.Add((parts[1], parts[3], int.Parse(middle[0], CultureInfo.InvariantCulture), bool.Parse(middle[1]), parts[5]));
        }
        return rows;
    }

    // GaEasierVoicingsTool.ExtractRoot, transcribed: the letter, with the next character when it is '#' or 'b'
    static string Root(string symbol) => symbol.Length >= 2 && symbol[1] is '#' or 'b' ? symbol[..2] : symbol[..1];

    // The course's chord for a symbol of the table: root and quality
    static readonly Dictionary<string, int[]> Qualities = new()
    {
        [""] = [0, 4, 7], ["m"] = [0, 3, 7], ["7"] = [0, 4, 7, 10], ["maj7"] = [0, 4, 7, 11], ["m7"] = [0, 3, 7, 10],
        ["sus2"] = [0, 2, 7], ["sus4"] = [0, 5, 7], ["5"] = [0, 7],
    };

    static HashSet<int> SymbolPcs(string symbol)
    {
        var root = Root(symbol);
        return [.. Qualities[symbol[root.Length..]].Select(s => Theory.Mod12(Theory.PitchClassOf(root) + s))];
    }

    static HashSet<int> Played(string shape) => [.. Midi(Frets(shape)).Select(Theory.Mod12)];

    // A played note outside a voicing's Notes, named with the flats of the table's B♭ chords
    static readonly string[] Flats = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"];

    public static void Run()
    {
        const double gaScale = BiomechanicsConstants.StandardScaleLengthMm; // 647.7
        const double calculatorScale = PhysicalFretboardCalculator.ScaleLengths.Default; // 648

        // ---- 1. Where the frets go

        Title("Distance from the nut to fret n, the course's d(n) = L(1 − 2^(−n/12)), against FretboardGeometry.CalculateSpanMm(0, n) on its 647.7 mm and PhysicalFretboardCalculator.CalculateFretPositionMm(n) on its 648 mm (GA.Domain.Services, compiled)");
        Console.WriteLine($"{"fret",-5} {"course, 647.7",-14} {"CalculateSpanMm",-16} {"check",-6} {"course, 648",-12} {"CalculateFretPositionMm",-24} check");
        foreach (var n in new[] { 1, 2, 3, 4, 5, 7, 12, 17, 19, 24 })
        {
            var (course1, ga1) = (F(FromNut(n, gaScale)), F(FretboardGeometry.CalculateSpanMm(0, n)));
            var (course2, ga2) = (F(FromNut(n, calculatorScale)), F(PhysicalFretboardCalculator.CalculateFretPositionMm(n)));
            Console.WriteLine($"{n,-5} {course1,-14} {ga1,-16} {(course1 == ga1 ? "ok" : "DIFF"),-6} {course2,-12} {ga2,-24} {(course2 == ga2 ? "ok" : "DIFF")}");
        }
        var root12 = F(Math.Pow(2, 1 / 12.0), "F6");
        var ratios = Enumerable.Range(0, 24).Select(n =>
            (calculatorScale - PhysicalFretboardCalculator.CalculateFretPositionMm(n)) / (calculatorScale - PhysicalFretboardCalculator.CalculateFretPositionMm(n + 1)));
        Line($"the length left to the saddle, fret n against fret n + 1, for n from 0 to 23: {root12} each time, the twelfth root of two: {ratios.All(r => F(r, "F6") == root12)}");
        Line($"MUS-009's frets 1, 5, 7, 12 and 24 on 648 mm, \"36.4, 162.5, 215.5, 324 and 486\": the calculator gives " +
            string.Join(", ", new[] { 1, 5, 7, 12, 24 }.Select(n => F(PhysicalFretboardCalculator.CalculateFretPositionMm(n), "0.#"))));

        Title("The 5-fret spans quoted in GA's PHYSICAL_PLAYABILITY_IMPROVEMENTS.md, against PhysicalFretboardCalculator.CalculateFretDistanceMm on 648 mm and the course");
        Console.WriteLine($"{"frets",-7} {"the document",-13} {"GA",-8} {"course",-8} check");
        foreach (var (lo, hi, doc) in new[] { (0, 5, "120.11"), (7, 12, "85.42"), (12, 17, "70.09") })
        {
            var ga = F(PhysicalFretboardCalculator.CalculateFretDistanceMm(lo, hi));
            var course = F(FromNut(hi, calculatorScale) - FromNut(lo, calculatorScale));
            Console.WriteLine($"{$"{lo}-{hi}",-7} {doc,-13} {ga,-8} {course,-8} {(doc == ga ? "ok" : "DIFF")}");
        }
        var low = PhysicalFretboardCalculator.CalculateFretDistanceMm(0, 5);
        var high = PhysicalFretboardCalculator.CalculateFretDistanceMm(12, 17);
        Line($"frets 0-5 against 12-17: the document says \"50.02mm (71.4% larger)\"; GA's distances differ by {F(low - high)} mm, {F((low / high - 1) * 100, "F1")}% larger");

        // ---- 2. How far a hand reaches

        const double reach = BiomechanicsConstants.ComfortableReachScaleUnits;
        Title("GA's comfortable reach, BiomechanicsConstants.ComfortableReachScaleUnits (GA.Domain.Core), against the 1 − 2^(−4/12) of its comment, and how far it reaches from each fret, measured with FretboardGeometry.CalculatePhysicalSpan as PhysicalCostService measures a shape (GA.Domain.Services, compiled)");
        Line($"  ComfortableReachScaleUnits = {F(reach)}; 1 − 2^(−4/12) = {F(1 - Math.Pow(2, -4 / 12.0), "F4")}, the nut to fret 4; on 647.7 mm, {F(reach * gaScale, "F1")} mm and {F(FromNut(4, gaScale), "F1")} mm");
        Console.WriteLine($"{"lowest fret",-12} {"highest within reach",-21} {"frets held",-11} mm, 647.7");
        foreach (var k in new[] { 1, 2, 3, 5, 7, 9, 12, 15 })
        {
            var h = Enumerable.Range(k, 25 - k).Last(f => FretboardGeometry.CalculatePhysicalSpan(new List<int> { k, f }) <= reach);
            Console.WriteLine($"{k,-12} {h,-21} {h - k + 1,-11} {F(FretboardGeometry.CalculateSpanMm(k, h), "F1")}");
        }
        var firstPosition = FretboardGeometry.CalculatePhysicalSpan(new List<int> { 1, 4 });
        Line($"  the first position, index finger on fret 1 and little finger on fret 4: CalculatePhysicalSpan {F(firstPosition, "F4")}, within reach: {firstPosition <= reach}");
        var player = new PlayerProfile();
        Line($"  the default PlayerProfile: HandSize {player.HandSize}, MaxComfortableStretchMm {F(player.MaxComfortableStretchMm, "F1")}");

        // ---- 3. CAGED

        var open = new (string Name, string Shape, int Root, string Gtr002)[]
        {
            ("C", "x32010", 0, "R 3 5 R 3"), ("A", "x02220", 9, "R 5 R 3 5"), ("G", "320003", 7, "R 3 5 R 3 R"),
            ("E", "022100", 4, "R 5 R 3 5 R"), ("D", "xx0232", 2, "R 5 R 3"),
        };

        Title("GTR-002's five open shapes in standard tuning: the notes from string 6 to string 1, and each one's degree above the root");
        Console.WriteLine($"{"shape",-6} {"frets",-8} {"notes",-20} {"course",-13} {"GTR-002",-13} check");
        foreach (var (name, shape, root, gtr002) in open)
        {
            var midi = Midi(Frets(shape));
            var degrees = string.Join(" ", midi.Select(m => Degree(m - root)));
            Console.WriteLine($"{name,-6} {shape,-8} {Pitches(midi),-20} {degrees,-13} {gtr002,-13} {(degrees == gtr002 ? "ok" : "DIFF")}");
        }

        Title("C major in the five shapes: each open shape raised by the semitones from its root up to C, a barre in place of the nut");
        Console.WriteLine($"{"shape",-6} {"barre",-6} {"frets",-15} {"notes",-20} {"C E G only",-11} {"frets held",-11} strings playing C");
        var cShapes = new List<(string Name, int Barre, int?[] Frets)>();
        foreach (var (name, shape, root, _) in open)
        {
            var barre = Theory.Mod12(-root);
            int?[] frets = [.. Frets(shape).Select(f => f + barre)];
            cShapes.Add((name, barre, frets));
            var midi = Midi(frets);
            var held = Fretted(frets);
            var playingC = frets.Select((f, i) => (Fret: f, String: 6 - i))
                .Where(x => x.Fret is not null && Theory.Mod12(Theory.MidiOf(Standard[6 - x.String]) + x.Fret.Value) == 0).Select(x => x.String);
            Console.WriteLine($"{name,-6} {barre,-6} {Shape(frets),-15} {Pitches(midi),-20} {Yes(midi.Select(Theory.Mod12).Distinct().Order().SequenceEqual([0, 4, 7])),-11} " +
                $"{held.Max() - held.Min() + 1,-11} {string.Join(" ", playingC)}");
        }
        Columns("barre frets", 12, 20);
        Row("Wikipedia", "0 3 5 8 10", string.Join(" ", cShapes.Select(s => s.Barre)));
        Line($"  C on string 2: {string.Join("; ", cShapes.Where(s => s.Frets[4] is { } f && Theory.Mod12(Theory.MidiOf("B3") + f) == 0).Select(s => $"{s.Name} shape, fret {s.Frets[4]}"))}; " +
            $"string 2 in the other shapes: {string.Join("; ", cShapes.Where(s => !(s.Frets[4] is { } f && Theory.Mod12(Theory.MidiOf("B3") + f) == 0)).Select(s => $"{s.Name} shape, {Theory.PitchName(Theory.MidiOf("B3") + s.Frets[4]!.Value)}"))}");

        Title("The five shapes in order up the neck, in each major key: the barre fret of each shape, from the lowest");
        string[] keys = ["C", "D♭", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"];
        var everyRotation = true;
        var orders = new Dictionary<int, string>();
        for (var key = 0; key < 12; key++)
        {
            var order = open.Select(o => (o.Name, Barre: Theory.Mod12(key - o.Root))).OrderBy(x => x.Barre).ToList();
            everyRotation &= "CAGEDCAGED".Contains(string.Concat(order.Select(x => x.Name)), StringComparison.Ordinal);
            orders[key] = $"{string.Join(" ", order.Select(x => x.Name))} at {string.Join(" ", order.Select(x => x.Barre))}";
            Console.WriteLine($"{keys[key],-3} {orders[key]}");
        }
        Line($"every order is C A G E D read round from one of its letters: {everyRotation}");
        Columns("key", 12, 22);
        Row("G, Wikipedia", "G E D C A at 0 3 5 7 10", orders[7]);

        Title("VoicingPhysicalAnalyzer.CalculatePlayability (GA.Domain.Services, compiled): the CagedShape of each shape, with its positions in GA's string order (string 1 first, as ExtractPhysicalLayout numbers them) and reversed (string 6 first, as the comments of DetectCagedShape read them)");
        Console.WriteLine($"{"frets",-15} {"course",-16} {"GA's order",-11} reversed");
        var asked = open.Select(o => (o.Shape, Course: $"{o.Name} shape, {o.Name}"))
            .Concat(cShapes.Where(s => s.Barre > 0).Select(s => (Shape: Shape(s.Frets), Course: $"{s.Name} shape, C")))
            .Concat([("133211", "E shape, F"), ("x13331", "A shape, B♭"), ("001220", "(none)")]);
        foreach (var (shape, course) in asked)
        {
            Console.WriteLine($"{shape,-15} {course,-16} {Playability(ToVoicing(Frets(shape))).CagedShape ?? "(none)",-11} {Playability(ToVoicing(Frets(shape), reversed: true)).CagedShape ?? "(none)"}");
        }
        foreach (var (name, shape, _, _) in open)
        {
            var raised = Enumerable.Range(0, 13).Select(b => (IReadOnlyList<int?>)[.. Frets(shape).Select(f => f + b)]).ToList();
            var answers = raised.SelectMany(f => new[] { Playability(ToVoicing(f)).CagedShape, Playability(ToVoicing(f, reversed: true)).CagedShape }).ToList();
            Line($"  the {name} shape barred at frets 0 to 12: \"E-Shape\" {raised.Count(f => Playability(ToVoicing(f)).CagedShape == "E-Shape")} times in GA's order, " +
                $"{raised.Count(f => Playability(ToVoicing(f, reversed: true)).CagedShape == "E-Shape")} reversed; any other answer: {answers.Count(a => a is not null and not "E-Shape")}");
        }
        var mirror = Frets("001220");
        Line($"  001220, string 6 to string 1: {Pitches(Midi(mirror))}");
        var shapeTag = PhysicalTags(ToVoicing(Frets("022100"), reversed: true)).FirstOrDefault(t => t.Contains("shape", StringComparison.Ordinal)) ?? "(none)";
        Line($"  the tag GeneratePhysicalTags writes for the reversed E shape: {shapeTag}; with \"CAGED-E\" or \"E shape\" in it, the test of VoicingFilterEngine for CagedShape \"E\": " +
            $"{shapeTag.Contains("CAGED-E", StringComparison.OrdinalIgnoreCase) || shapeTag.Contains("E shape", StringComparison.OrdinalIgnoreCase)}");

        // ---- 4. The effort of a shape

        var shapes = new (string Shape, string Chord)[]
        {
            ("x32010", "C"), ("x02210", "Am"), ("022000", "Em"), ("022100", "E"), ("320003", "G"), ("xx0232", "D"), ("133211", "F"),
            ("x35553", "C"), ("875558", "C"), ("8-10-10-9-8-8", "C"), ("x-x-10-12-13-12", "C"), ("577655", "A"), ("12-14-14-13-12-12", "E"),
        };
        var service = new PhysicalCostService();

        Title("The course's measures of each shape, and PhysicalCostService.CalculateStaticCost with the default PlayerProfile (GA.Domain.Services, compiled): its total and the terms that are not zero");
        Console.WriteLine($"{"frets",-18} {"chord",-6} {"frets held",-11} {"span, mm",-9} {"fretted",-8} {"barre",-6} {"total",-6} terms");
        foreach (var (shape, chord) in shapes)
        {
            var frets = Frets(shape);
            var held = Fretted(frets);
            var cost = service.CalculateStaticCost(CostShape(frets));
            var terms = string.Join(" ", cost.Breakdown.Where(t => Math.Abs(t.Value) > 1e-9).Select(t => $"{t.Key} {F(t.Value)}"));
            Console.WriteLine($"{shape,-18} {chord,-6} {held.Max() - held.Min() + 1,-11} {F(SpanMm(frets), "F1"),-9} {held.Length,-8} {Yes(held.Length > 4),-6} {F(cost.TotalCost),-6} {terms}");
        }

        Title("The same shapes through VoicingPhysicalAnalyzer.CalculatePlayability (Difficulty, DifficultyScore, BarreRequired) and BiomechanicalAnalyzer.AnalyzeChordPlayability (OverallScore, Difficulty, HasBarreChord) (GA.Domain.Services, compiled)");
        Console.WriteLine($"{"frets",-18} {"chord",-6} {"Difficulty",-13} {"Score",-6} {"Barre",-6} {"Overall",-8} {"Difficulty",-11} Barre");
        foreach (var (shape, chord) in shapes)
        {
            var frets = Frets(shape);
            var playability = Playability(ToVoicing(frets));
            var bio = Biomechanics(frets);
            Console.WriteLine($"{shape,-18} {chord,-6} {playability.Difficulty,-13} {F(playability.DifficultyScore),-6} {Yes(playability.BarreRequired),-6} " +
                $"{F(bio.OverallScore),-8} {bio.Difficulty,-11} {Yes(bio.FingeringEfficiencyAnalysis?.HasBarreChord == true)}");
        }
        Line($"BiomechanicalAnalyzer gives the same analysis to every shape for each HandSize ({string.Join(", ", Enum.GetValues<HandSize>())}): " +
            $"{shapes.All(s => Enum.GetValues<HandSize>().All(hand => BiomechanicsSummary(Biomechanics(Frets(s.Shape), hand)) == BiomechanicsSummary(Biomechanics(Frets(s.Shape)))))}");
        Line($"PhysicalCostService gives the same total to every shape with a PlayerProfile of each HandSize and a MaxComfortableStretchMm of 80: " +
            $"{shapes.All(s => Enum.GetValues<HandSize>().All(hand => new PhysicalCostService(new PlayerProfile { HandSize = hand, MaxComfortableStretchMm = 80 }).CalculateStaticCost(CostShape(Frets(s.Shape))).TotalCost == service.CalculateStaticCost(CostShape(Frets(s.Shape))).TotalCost))}");

        Title("PhysicalCostService.CalculateStaticCost under GA's three PlayerProfiles (GA.Business.Core, compiled), on the five shapes of C");
        Console.WriteLine($"{"frets",-15} {"shape",-6} {"Default",-8} {"Beginner",-9} Jazz");
        var beginner = new PhysicalCostService(PlayerProfile.Beginner());
        var jazz = new PhysicalCostService(PlayerProfile.Jazz());
        foreach (var (name, _, frets) in cShapes)
        {
            var positions = CostShape(frets);
            Console.WriteLine($"{Shape(frets),-15} {name,-6} {F(service.CalculateStaticCost(positions).TotalCost),-8} {F(beginner.CalculateStaticCost(positions).TotalCost),-9} {F(jazz.CalculateStaticCost(positions).TotalCost)}");
        }

        // ---- 5. Open tunings

        Title("The guitar entries of Tunings.toml, read as text (GA.Business.Config copies it next to the program), against Instruments.yaml, which GA reads; each six-string tuning as a change from standard, in semitones, and the notes of its open strings");
        var toml = TomlGuitars(Path.Combine(AppContext.BaseDirectory, "Tunings.toml"));
        var yaml = Instruments.Read().Where(e => e.Instrument == "Guitar").ToDictionary(e => e.Variant);
        Console.WriteLine($"{"entry",-14} {"Tuning",-38} {"Instruments.yaml",-17} {"string 6 to 1",-20} {"largest",-8} open strings");
        foreach (var (name, tuning) in toml)
        {
            var pitches = tuning.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            var inYaml = yaml.TryGetValue(name.Replace(" ", ""), out var entry) ? entry.Tuning == tuning ? "the same" : "different" : "absent";
            if (pitches.Length != 6)
            {
                Console.WriteLine($"{name,-14} {tuning,-38} {inYaml}");
                continue;
            }
            var change = pitches.Select((p, i) => Theory.MidiOf(p) - Theory.MidiOf(Standard[i])).ToArray();
            Console.WriteLine($"{name,-14} {tuning,-38} {inYaml,-17} {string.Join(" ", change),-20} {change.Max(Math.Abs),-8} {ChordName(pitches.Select(p => Theory.PitchClassOf(p[..^1])))}");
        }
        Console.WriteLine($"{"entry",-14} {"Wikipedia",-14} {"Tunings.toml",-14} check");
        foreach (var (name, wikipedia) in new[] { ("OpenCMajor", "C G C G C E"), ("OpenDMajor", "D A D F♯ A D"), ("OpenEMajorV1", "E B E G♯ B E"), ("OpenGMajorV1", "D G D G B D") })
        {
            var letters = Pretty(string.Join(" ", toml.Single(t => t.Name == name).Tuning.Split(' ').Select(p => p[..^1])));
            Console.WriteLine($"{name,-14} {wikipedia,-14} {letters,-14} {(letters == wikipedia ? "ok" : "DIFF")}");
        }

        // ---- 6. The table behind ga_easier_voicings

        var table = EasierVoicings(Path.Combine(AppContext.BaseDirectory, "GuitaristProblemTools.cs"));
        Title($"The {table.Count} voicings of ga_easier_voicings (GaMcpServer/Tools/GuitaristProblemTools.cs, read as text): each shape read in standard tuning, against its Notes; HasBarre and Difficulty as written");
        Console.WriteLine($"{"symbol",-7} {"frets",-7} {"notes, string 6 to 1",-21} {"Notes",-15} {"not in Notes",-13} {"not played",-11} {"fretted",-8} {"HasBarre",-9} Difficulty");
        HashSet<int> NotesPcs((string Symbol, string Frets, int Difficulty, bool HasBarre, string Notes) v) => [.. v.Notes.Split(", ").Select(Theory.PitchClassOf)];
        foreach (var v in table)
        {
            var names = v.Notes.Split(", ");
            string Name(int midi) => names.FirstOrDefault(n => Theory.PitchClassOf(n) == Theory.Mod12(midi)) is { } spelled ? Pretty(spelled) : Flats[Theory.Mod12(midi)];
            var played = Played(v.Frets);
            var outside = string.Join(" ", played.Where(pc => !NotesPcs(v).Contains(pc)).Select(Name));
            var missing = Pretty(string.Join(" ", names.Where(n => !played.Contains(Theory.PitchClassOf(n)))));
            Console.WriteLine($"{v.Symbol,-7} {v.Frets,-7} {string.Join(" ", Midi(Frets(v.Frets)).Select(Name)),-21} {Pretty(v.Notes),-15} {(outside.Length == 0 ? "-" : outside),-13} " +
                $"{(missing.Length == 0 ? "-" : missing),-11} {Fretted(Frets(v.Frets)).Length,-8} {v.HasBarre,-9} {v.Difficulty}");
        }
        Line($"Notes are the notes of the symbol: {table.Count(v => NotesPcs(v).SetEquals(SymbolPcs(v.Symbol)))} of {table.Count}; " +
            $"a note outside the Notes: {string.Join(", ", table.Where(v => !Played(v.Frets).IsSubsetOf(NotesPcs(v))).Select(v => v.Symbol))}; " +
            $"a note of the Notes not played: {string.Join(", ", table.Where(v => !NotesPcs(v).IsSubsetOf(Played(v.Frets))).Select(v => v.Symbol))}");
        Line($"HasBarre: {string.Join(", ", table.Where(v => v.HasBarre).Select(v => v.Symbol))}; more than four fretted notes: {string.Join(", ", table.Where(v => Fretted(Frets(v.Frets)).Length > 4).Select(v => v.Symbol))}");

        Title("What ga_easier_voicings offers for each voicing marked HasBarre, under its default constraint \"no-barre\": the table's other voicings on the same root without HasBarre, easiest first (the course's reading of lines 611 to 652)");
        foreach (var barre in table.Where(v => v.HasBarre))
        {
            var offers = table.Where(v => Root(v.Symbol).Equals(Root(barre.Symbol), StringComparison.OrdinalIgnoreCase)
                    && !v.Symbol.Equals(barre.Symbol, StringComparison.OrdinalIgnoreCase) && !v.HasBarre)
                .OrderBy(v => v.Difficulty).Take(5).ToList();
            var described = offers.Select(o => $"{o.Symbol} [{o.Frets}], {(SymbolPcs(barre.Symbol).IsSubsetOf(Played(o.Frets)) ? "all" : "not all")} of {barre.Symbol}'s notes");
            Line($"  {barre.Symbol} [{barre.Frets}]: {(offers.Count == 0 ? "nothing" : string.Join("; ", described))}");
        }
        var fsus2 = Frets("133011");
        Line($"  the description's example, \"F with no-barre → Fmaj7 (103210), Fsus2 (133011), or C/F\": Fsus2 in the table {table.Any(v => v.Symbol == "Fsus2")}, C/F {table.Any(v => v.Symbol == "C/F")}; " +
            $"133011 plays {Pitches(Midi(fsus2))}, {Fretted(fsus2).Length} fretted notes");
    }
}
