using GA.Business.Config;
using GA.Business.Core.Analysis.Voicings;
using GA.Domain.Core.Instruments;
using GA.Domain.Core.Instruments.Fretboard.Voicings.Core;
using GA.Domain.Core.Instruments.Positions;
using GA.Domain.Core.Instruments.Primitives;
using GA.Domain.Core.Primitives.Notes;
using GA.Domain.Services.Fretboard.Voicings.Analysis;
using GA.Domain.Services.Fretboard.Voicings.Filtering;
using GA.Domain.Services.Fretboard.Voicings.Generation;
using YamlDotNet.Serialization;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 14 of the course, run as `l16`: guitar voicings, close and drop voicings, shells and guide tones,
// and how GA generates, labels and filters them
public static class Lesson16
{
    // ---- The course's side: Wikipedia's drop voicings ("Voicing (music)", "Drop voicings"). The default voicing has every voice
    // in the same octave; voices are numbered from the top, and a drop-n voicing lowers voice n by an octave

    // The four seventh chords on C, as semitones above the root
    static readonly (string Name, int[] Tones)[] Sevenths =
    [
        ("Cmaj7", [0, 4, 7, 11]),
        ("C7", [0, 4, 7, 10]),
        ("Cm7", [0, 3, 7, 10]),
        ("Cm7b5", [0, 3, 6, 10]),
    ];

    static readonly string[] ToneNames = ["1", "3", "5", "7"];

    // The degree of a pitch class above a root
    static readonly string[] Degrees = ["1", "♭2", "2", "♭3", "3", "4", "♭5", "5", "♯5", "6", "♭7", "7"];

    static readonly string[] NoteNames = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"];

    static string Notes(IEnumerable<int> midi) => string.Join(" ", midi.Select(m => NoteNames[Theory.Mod12(m)]));

    static string Pitches(IEnumerable<int> midi) => string.Join(" ", midi.Select(m => NoteNames[Theory.Mod12(m)] + (m / 12 - 1)));

    // Close position under a top note: every other pitch class at its highest pitch below the top, listed from the top down
    static int[] CloseFromTop(int top, IEnumerable<int> pcs) =>
        [top, .. pcs.Where(pc => Theory.Mod12(pc - top) != 0).Select(pc => top - Theory.Mod12(top - pc)).OrderDescending()];

    // Lower the given voices of a close position (numbered from the top) by an octave; the result low to high
    static int[] Drop(int[] fromTop, int[] voices) =>
        [.. fromTop.Select((midi, i) => voices.Contains(i + 1) ? midi - 12 : midi).Order()];

    static string DropLabel(int[] voices) => voices.Length == 0 ? "close" : "drop-" + string.Join("-and-", voices);

    // The course's name for a voicing: each note against its place in the close voicing under the same top note
    static string DropName(IReadOnlyList<int> midi)
    {
        if (midi.Select(Theory.Mod12).Distinct().Count() != midi.Count) return "doubled, not named";
        var top = midi.Max();
        var close = CloseFromTop(top, midi.Select(Theory.Mod12));
        var dropped = new List<int>();
        foreach (var note in midi.Where(n => n != top))
        {
            var home = top - Theory.Mod12(top - note);
            var octaves = (home - note) / 12;
            if (octaves > 1) return "beyond drop-n";
            if (octaves == 1) dropped.Add(Array.IndexOf(close, home) + 1);
        }
        return DropLabel([.. dropped.Order()]);
    }

    static readonly string[] SingleDrops = ["close", "drop-2", "drop-3", "drop-4"];

    // ---- GA's side

    static Voicing FromMidi(IEnumerable<int> midi) => new([], [.. midi.Select(m => (MidiNote)m)]);

    // A shape such as "x32010", string 6 first, as a GA voicing: positions and notes in string order 1..6, as in lesson 3
    static Voicing FromShape(string shape)
    {
        var positions = new Position[6];
        for (var s = 1; s <= 6; s++)
        {
            var ch = shape[6 - s];
            positions[s - 1] = ch == 'x'
                ? new Position.Muted(new Str(s))
                : new Position.Played(new PositionLocation(new Str(s), new Fret(ch - '0')), Tuning.Default[new Str(s)].MidiNote + (ch - '0'));
        }
        return new Voicing(positions, [.. positions.OfType<Position.Played>().Select(p => p.MidiNote)]);
    }

    static int[] Midi(Voicing voicing) => [.. voicing.Notes.Select(n => n.Value).Order()];

    // The played strings, low to high: "5-4-3-2"
    static string StringSet(Voicing voicing) =>
        string.Join("-", voicing.Positions.Select((p, i) => (p, String: i + 1)).Where(x => x.p is Position.Played).Select(x => x.String).OrderDescending());

    // GA's diagram is in string order 1..6; the course writes it from string 6, as chord charts do
    static string LowToHigh(Voicing voicing) => string.Join("-", voicing.Diagram.Split('-').Reverse());

    static string Label(string? drop) => drop ?? "(none)";

    // The tags of the three rules that name voicings, as each one gives them
    static readonly string[] Watched = ["rootless", "closed-voicing", "open-voicing", "drop-2-voicings", "drop-3-voicings", "shell-voicing"];

    static string EngineTags(VoicingCharacteristics characteristics, int[] midi) =>
        string.Join(" ", VoicingTagEnricher.Enrich(characteristics, midi).Where(Watched.Contains));

    static string PhysicalShellTag(Voicing voicing)
    {
        var layout = VoicingPhysicalAnalyzer.ExtractPhysicalLayout(voicing);
        var playability = VoicingPhysicalAnalyzer.CalculatePlayability(layout);
        var ergonomics = VoicingPhysicalAnalyzer.AnalyzeErgonomics(layout, playability);
        return VoicingPhysicalAnalyzer.GeneratePhysicalTags(layout, playability, ergonomics).Contains("shell-voicing") ? "shell-voicing" : "-";
    }

    static bool Keeps(Voicing voicing, MusicalVoicingAnalysis analysis, VoicingTypeFilter filter) =>
        VoicingFilters.MatchesCriteria(voicing, analysis, new VoicingFilterCriteria { VoicingType = filter });

    // Every MusicalVoicingAnalysis of the lesson, for the guide-tone check at the end
    static readonly List<MusicalVoicingAnalysis> Analyzed = [];

    static MusicalVoicingAnalysis Analyze(Voicing voicing)
    {
        var analysis = VoicingAnalyzer.Analyze(voicing);
        Analyzed.Add(analysis);
        return analysis;
    }

    // ---- GA's comping recipes: the notes the course reads in each name and degree order (null: no degree order to check)
    static readonly Dictionary<string, (int[] Chord, int[]? Order)> Named = new()
    {
        ["Dm9"] = ([2, 5, 9, 0, 4], [0, 5, 9, 4]),              // degree order 7-3-5-9: C F A E
        ["G7(13,#9)"] = ([7, 11, 2, 5, 10, 4], [11, 5, 10, 4]), // 3-b7-#9-13: B F A♯ E
        ["Cmaj9"] = ([0, 4, 7, 11, 2], [11, 4, 7, 2]),          // 7-3-5-9: B E G D
        ["Dm7b5(11)"] = ([2, 5, 8, 0, 7], [0, 5, 8, 7]),        // b7-b3-b5-11: C F A♭ G
        ["G7(b9,#9)"] = ([7, 11, 2, 5, 8, 10], [11, 5, 8, 10]), // 3-b7-b9-#9: B F A♭ A♯
        ["Cm(maj9)"] = ([0, 3, 7, 11, 2], [11, 3, 7, 2]),       // 7-3-5-9: B E♭ G D
        ["G(add9)"] = ([7, 11, 2, 9], null),
        ["D(add9)/A"] = ([2, 6, 9, 4], null),
        ["Em(add9)"] = ([4, 7, 11, 6], null),
        ["C(add9)/G"] = ([0, 4, 7, 2], null),
        ["A5(add2)"] = ([9, 4, 11], null),
        ["Gsus2"] = ([7, 9, 2], null),
        ["Dsus2/F#"] = ([2, 4, 9, 6], null),
        ["Dm11"] = ([2, 5, 9, 0, 4, 7], null),
        ["Ebm11"] = ([3, 6, 10, 1, 5, 8], null),
    };

    static readonly string[] OpenStrings = ["E4", "B3", "G3", "D3", "A2", "E2"]; // string 1 to string 6

    static int OpenMidi(int str) => Theory.MidiOf(OpenStrings[str - 1]);

    static Dictionary<object, object> Map(object node) => (Dictionary<object, object>)node;

    static List<object> List(object node) => (List<object>)node;

    // A recipe's fingerings: "Name: frets (comment)", under Shapes / ExampleInKey / Fingering or ExampleInKey / Grips
    static IEnumerable<string> Fingerings(Dictionary<object, object> recipe)
    {
        if (recipe.TryGetValue("Shapes", out var shapes))
        {
            foreach (var shape in List(shapes)) yield return (string)Map(Map(shape)["ExampleInKey"])["Fingering"];
        }
        if (recipe.TryGetValue("ExampleInKey", out var example) && Map(example).TryGetValue("Grips", out var grips))
        {
            foreach (var grip in List(grips)) yield return (string)grip;
        }
    }

    public static void Run()
    {
        // ---- 1. Drop voicings, by definition

        Title("Drop voicings of Cmaj7 under B, built from the definition: the course names each one back, GA's VoicingHarmonicAnalyzer.Analyze labels it (GA.Domain.Services, compiled)");
        int[][] dropSets = [[], [2], [3], [4], [2, 3], [2, 4], [3, 4], [2, 3, 4]];
        Console.WriteLine($"{"dropped",-20} {"notes, low to high",-20} {"spread",-7} {"course",-20} {"DropVoicing",-12} {"IsRootless",-11} {"IsOpenVoicing",-14} tags (ChordClassificationEngine)");
        var cmaj7UnderB = CloseFromTop(72 + 11, Sevenths[0].Tones);
        foreach (var voices in dropSets)
        {
            var midi = Drop(cmaj7UnderB, voices);
            var ga = VoicingHarmonicAnalyzer.Analyze(FromMidi(midi));
            Console.WriteLine($"{DropLabel(voices),-20} {Pitches(midi),-20} {midi.Max() - midi.Min(),-7} {DropName(midi),-20} {Label(ga.DropVoicing),-12} {ga.IsRootless,-11} {ga.IsOpenVoicing,-14} {EngineTags(ga, midi)}");
        }

        Title("All 128: four seventh chords on C × four close positions (one per top note) × eight sets of dropped voices");
        var built = (from chord in Sevenths
                     from top in chord.Tones
                     from voices in dropSets
                     let midi = Drop(CloseFromTop(72 + top, chord.Tones), voices)
                     select (Voices: voices, Midi: midi, Ga: VoicingHarmonicAnalyzer.Analyze(FromMidi(midi)))).ToList();
        Console.WriteLine($"{"dropped",-20} {"voicings",-9} {"course right",-13} {"\"Drop-2\"",-9} {"(none)",-7} {"other",-6} {"IsRootless",-11} {"IsOpenVoicing",-14} with the root");
        void Totals(string label, IReadOnlyCollection<(int[] Voices, int[] Midi, VoicingCharacteristics Ga)> group) =>
            Console.WriteLine($"{label,-20} {group.Count,-9} {group.Count(b => DropName(b.Midi) == DropLabel(b.Voices)),-13} " +
                $"{group.Count(b => b.Ga.DropVoicing == "Drop-2"),-9} {group.Count(b => b.Ga.DropVoicing is null),-7} " +
                $"{group.Count(b => b.Ga.DropVoicing is not null and not "Drop-2"),-6} {group.Count(b => b.Ga.IsRootless),-11} " +
                $"{group.Count(b => b.Ga.IsOpenVoicing),-14} {group.Count(b => b.Midi.Any(m => Theory.Mod12(m) == 0))}");
        foreach (var voices in dropSets) Totals(DropLabel(voices), [.. built.Where(b => b.Voices.SequenceEqual(voices))]);
        Totals("all", built);
        Line($"GA says \"Drop-2\" exactly when at most one voice is dropped: {built.All(b => (b.Ga.DropVoicing == "Drop-2") == (b.Voices.Length <= 1))}");

        Title("Wikipedia's examples, rebuilt by the course and read down from the top, with GA's label");
        Console.WriteLine($"{"Wikipedia",-10} {"course",-10} {"check",-6} DropVoicing");
        foreach (var (pcs, tops, voices, quoted) in new (int[], int[], int[], string[])[]
        {
            ([0, 4, 7], [0, 7, 4], [2], ["C E G", "G C E", "E G C"]),
            ([7, 11, 2, 5], [7, 11, 2, 5], [2, 4], ["G D F B", "B F G D", "D G B F", "F B D G"]),
        })
        {
            Line($"-- {(pcs.Length == 3 ? "drop-2 voicings of the C major triad" : "drop-2-and-4 voicings of G7")}");
            for (var i = 0; i < tops.Length; i++)
            {
                var midi = Drop(CloseFromTop(72 + tops[i], pcs), voices);
                var reading = Notes(midi.OrderDescending());
                Console.WriteLine($"{quoted[i],-10} {reading,-10} {(reading == quoted[i] ? "ok" : "DIFF"),-6} {Label(VoicingHarmonicAnalyzer.Analyze(FromMidi(midi)).DropVoicing)}");
            }
        }

        // ---- 2. Rootless and open, on guitar shapes

        Title("Guitar shapes through VoicingAnalyzer.Analyze (GA.Domain.Services, compiled): lesson 3's open chords, MUS-005's \"Drop-2 Cmaj7\" and a drop 2");
        Console.WriteLine($"{"shape",-8} {"chord",-6} {"notes, low to high",-21} {"spread",-7} {"course",-20} {"root",-5} {"DropVoicing",-12} {"IsRootless",-11} {"IsOpenVoicing",-14} tags (ChordClassificationEngine)");
        foreach (var (shape, chord, root) in new[]
        {
            ("x32010", "C", 0), ("032010", "C/E", 0), ("x02210", "Am", 9), ("022100", "E", 4), ("320003", "G", 7), ("xx0232", "D", 2), ("133211", "F", 5),
            ("x3200x", "Cmaj7", 0), ("x3545x", "Cmaj7", 0),
        })
        {
            var voicing = FromShape(shape);
            var midi = Midi(voicing);
            var ga = Analyze(voicing).VoicingCharacteristics;
            var hasRoot = midi.Any(m => Theory.Mod12(m - root) == 0) ? "yes" : "no";
            Console.WriteLine($"{shape,-8} {chord,-6} {Pitches(midi),-21} {midi.Max() - midi.Min(),-7} {DropName(midi),-20} {hasRoot,-5} {Label(ga.DropVoicing),-12} {ga.IsRootless,-11} {ga.IsOpenVoicing,-14} {EngineTags(ga, midi)}");
        }

        // ---- 3. Shells

        Title("Shells, root, third and seventh on MUS-005's Freddie Green strings, then the shapes above: three rules that name a shell");
        Console.WriteLine($"{"shape",-8} {"chord",-6} {"degrees, low to high",-21} {"spread",-7} {"IsRootless",-11} {"ShellFamily",-16} {"physical tag",-13} {"engine tag",-13} ShellVoicings filter");
        foreach (var (shape, chord, root) in new[]
        {
            ("3x34xx", "G7", 7), ("3x44xx", "Gmaj7", 7), ("3x33xx", "Gm7", 7), ("x323xx", "C7", 0), ("x324xx", "Cmaj7", 0), ("x313xx", "Cm7", 0),
            ("x32010", "C", 0), ("032010", "C/E", 0), ("x02210", "Am", 9), ("022100", "E", 4), ("320003", "G", 7), ("xx0232", "D", 2), ("133211", "F", 5),
            ("x3200x", "Cmaj7", 0), ("x3545x", "Cmaj7", 0),
        })
        {
            var voicing = FromShape(shape);
            var midi = Midi(voicing);
            var analysis = Analyze(voicing);
            var ga = analysis.VoicingCharacteristics;
            var engine = VoicingTagEnricher.Enrich(ga, midi).Contains("shell-voicing") ? "shell-voicing" : "-";
            var degrees = string.Join(" ", midi.Select(m => Degrees[Theory.Mod12(m - root)]));
            Console.WriteLine($"{shape,-8} {chord,-6} {degrees,-21} {midi.Max() - midi.Min(),-7} {ga.IsRootless,-11} {analysis.PlayabilityInfo.ShellFamily ?? "(none)",-16} {PhysicalShellTag(voicing),-13} {engine,-13} {Keeps(voicing, analysis, VoicingTypeFilter.ShellVoicings)}");
        }

        // ---- 4. Every voicing GA generates

        Title("VoicingGenerator.GenerateAllVoicings (GA.Domain.Services, compiled) on GA's standard guitar, run in sequence");
        var fretboard = Fretboard.Default;
        var all = VoicingGenerator.GenerateAllVoicings(fretboard, parallel: false);
        // the course's count: windows of five frets (4 + 1) starting on frets 0 to 20, each string muted or on one of the five frets,
        // at least two notes; neighbouring windows share four frets
        int Window(int choices) => (int)Math.Pow(choices, 6) - 1 - 6 * (choices - 1);
        var windows = fretboard.FretCount - 4 + 1;
        Columns("", 22, 12);
        Row("voicings", windows * Window(6) - (windows - 1) * Window(5), all.Count);
        Line($"the course: {windows} windows × {Window(6)} − {windows - 1} shared × {Window(5)}");

        Title("Those that play the four notes of a seventh chord on C on four strings: the course's name against GA's label");
        var chords = Sevenths.ToDictionary(c => Theory.SetId(c.Tones));
        var found = all
            .Where(v => v.Notes.Length == 4)
            .Select(v => (Voicing: v, Midi: Midi(v)))
            .Where(x => x.Midi.Select(Theory.Mod12).Distinct().Count() == 4 && chords.ContainsKey(Theory.SetId(x.Midi)))
            .Select(x => (x.Voicing, x.Midi, Chord: chords[Theory.SetId(x.Midi)], Course: DropName(x.Midi), Analysis: Analyze(x.Voicing)))
            .ToList();
        Line($"voicings: {found.Count}");
        Console.WriteLine($"{"course",-20} {"voicings",-9} {"\"Drop-2\"",-9} {"(none)",-7} other");
        foreach (var name in dropSets.Select(DropLabel).Append("beyond drop-n"))
        {
            var group = found.Where(f => f.Course == name).ToList();
            Console.WriteLine($"{name,-20} {group.Count,-9} {group.Count(f => f.Analysis.VoicingCharacteristics.DropVoicing == "Drop-2"),-9} " +
                $"{group.Count(f => f.Analysis.VoicingCharacteristics.DropVoicing is null),-7} {group.Count(f => f.Analysis.VoicingCharacteristics.DropVoicing is not null and not "Drop-2")}");
        }
        Line($"named otherwise: {found.Count(f => !dropSets.Select(DropLabel).Append("beyond drop-n").Contains(f.Course))}");
        Line($"GA says \"Drop-2\" exactly on the course's close, drop-2, drop-3 and drop-4 voicings: " +
            $"{found.All(f => (f.Analysis.VoicingCharacteristics.DropVoicing == "Drop-2") == SingleDrops.Contains(f.Course))}");

        Title("The string sets of the drop-2 voicings found");
        foreach (var group in found.Where(f => f.Course == "drop-2").GroupBy(f => StringSet(f.Voicing)).OrderByDescending(g => g.Key, StringComparer.Ordinal))
        {
            Line($"  {group.Key}: {group.Count()}");
        }

        Title("MUS-005's shapes: quality × inversion (the chord tone in the bass) × string set, found among GA's voicings");
        foreach (var (kind, sets) in new[] { ("drop-2", new[] { "6-5-4-3", "5-4-3-2", "4-3-2-1" }), ("drop-3", new[] { "6-4-3-2", "5-3-2-1" }) })
        {
            var shapes = found.Where(f => f.Course == kind && sets.Contains(StringSet(f.Voicing)))
                .Select(f => (f.Chord.Name, Bass: Array.IndexOf(f.Chord.Tones, Theory.Mod12(f.Midi[0])), Set: StringSet(f.Voicing)))
                .Distinct().ToList();
            var widest = found.Where(f => f.Course == kind && sets.Contains(StringSet(f.Voicing))).Max(f => f.Voicing.FretSpan);
            Line($"  {kind} on {string.Join(", ", sets)}: {shapes.Count} of {4 * 4 * sets.Length} shapes, the widest spans {widest} frets");
        }

        Title("Cmaj7 in each inversion: the lowest drop-2 on strings 5-4-3-2 and the lowest drop-3 on strings 6-4-3-2, written from string 6");
        Console.WriteLine($"{"bass",-5} {"drop-2, 5-4-3-2",-22} drop-3, 6-4-3-2");
        for (var bass = 0; bass < 4; bass++)
        {
            string Lowest(string kind, string set) => found
                .Where(f => f.Chord.Name == "Cmaj7" && f.Course == kind && StringSet(f.Voicing) == set && Theory.Mod12(f.Midi[0]) == Sevenths[0].Tones[bass])
                .OrderBy(f => f.Midi[0]).Select(f => $"{LowToHigh(f.Voicing)} {Notes(f.Midi)}").FirstOrDefault() ?? "(none)";
            Console.WriteLine($"{ToneNames[bass],-5} {Lowest("drop-2", "5-4-3-2"),-22} {Lowest("drop-3", "6-4-3-2")}");
        }

        Title("VoicingFilters.MatchesCriteria (GA.Domain.Services, compiled) on these voicings, one VoicingTypeFilter at a time, against what each name means to the course");
        Columns("filter", 15, 8);
        int Course(VoicingTypeFilter filter) => filter switch
        {
            VoicingTypeFilter.Drop2 => found.Count(f => f.Course == "drop-2"),
            VoicingTypeFilter.Drop3 => found.Count(f => f.Course == "drop-3"),
            VoicingTypeFilter.Drop2And4 => found.Count(f => f.Course == "drop-2-and-4"),
            VoicingTypeFilter.Rootless => found.Count(f => !f.Midi.Any(m => Theory.Mod12(m) == 0)),
            VoicingTypeFilter.ShellVoicings => found.Count(f => f.Midi.Length == 3),
            VoicingTypeFilter.ClosedPosition => found.Count(f => f.Course == "close"),
            VoicingTypeFilter.OpenPosition => found.Count(f => f.Course != "close"),
            _ => found.Count,
        };
        foreach (var filter in Enum.GetValues<VoicingTypeFilter>().Where(f => f != VoicingTypeFilter.All))
        {
            Row(filter.ToString(), Course(filter), found.Count(f => Keeps(f.Voicing, f.Analysis, filter)));
        }
        Line("course: Rootless, no C; ShellVoicings, root, third and seventh alone; ClosedPosition, close; OpenPosition, the others");
        Line($"GA's Drop2 keeps exactly the course's close, drop-2, drop-3 and drop-4 voicings: {found.All(f => Keeps(f.Voicing, f.Analysis, VoicingTypeFilter.Drop2) == SingleDrops.Contains(f.Course))}");
        Line($"GA's Rootless keeps exactly those spread over more than an octave: {found.All(f => Keeps(f.Voicing, f.Analysis, VoicingTypeFilter.Rootless) == f.Midi[^1] - f.Midi[0] > 12)}");
        Line($"ShellFamily \"3-4 note shell\" on all of them: {found.All(f => f.Analysis.PlayabilityInfo.ShellFamily == "3-4 note shell")}");

        // ---- 5. Guide tones

        var yaml = new DeserializerBuilder().Build().Deserialize<Dictionary<object, object>>(File.ReadAllText(ConfigFileLocator.findFile("ChordProgressions.yaml").Value));

        Title("Guide tones in GA's TransposeTables (ChordProgressions.yaml): third and seventh of each chord, and the four moves of a ii–V–I");
        var table = Map(List(yaml["TransposeTables"])[0]);
        Line($"-- {table["Name"]}");
        Console.WriteLine($"{"key",-4} {"chords",-20} {"thirds",-10} {"sevenths",-10} {"line 1",-10} {"line 2",-10} moves");
        var rowsRight = 0;
        var rows = List(table["Rows"]).Select(Map).ToList();
        foreach (var row in rows)
        {
            var symbols = List(row["Chords"]).Cast<string>().ToArray();
            var guide = symbols.Select(symbol =>
            {
                var rootLength = symbol.Length > 1 && symbol[1] is '#' or 'b' ? 2 : 1;
                var (root, suffix) = (symbol[..rootLength], symbol[rootLength..]);
                var (third, seventh) = suffix switch { "m7" => (3, 10), "7" => (4, 10), "maj7" => (4, 11), _ => throw new FormatException(symbol) };
                return (Third: Theory.Spell(root, 3, third), Seventh: Theory.Spell(root, 7, seventh));
            }).ToArray();
            int Pc(string note) => Theory.PitchClassOf(note);
            // the thirds of ii and V stay as the sevenths of V and I; the sevenths of ii and V fall a half step to the next third
            var moves = Pc(guide[0].Third) == Pc(guide[1].Seventh)
                && Pc(guide[1].Third) == Pc(guide[2].Seventh)
                && Theory.Mod12(Pc(guide[0].Seventh) - 1) == Pc(guide[1].Third)
                && Theory.Mod12(Pc(guide[1].Seventh) - 1) == Pc(guide[2].Third);
            rowsRight += moves ? 1 : 0;
            Console.WriteLine($"{(string)row["Key"],-4} {string.Join(" ", symbols),-20} {string.Join(" ", guide.Select(g => g.Third)),-10} {string.Join(" ", guide.Select(g => g.Seventh)),-10} " +
                $"{$"{guide[0].Third} {guide[1].Seventh} {guide[2].Third}",-10} {$"{guide[0].Seventh} {guide[1].Third} {guide[2].Seventh}",-10} {(moves ? "ok" : "DIFF")}");
        }
        Line($"rows with the four moves: {rowsRight} of {rows.Count}");

        Title("GA's tone inventory: every MusicalVoicingAnalysis of this lesson, from VoicingAnalyzer.AnalyzeEnhanced");
        Line($"  analyses: {Analyzed.Count}; HasGuideTones true: {Analyzed.Count(a => a.ToneInventory.HasGuideTones)}; " +
            $"Tones not empty: {Analyzed.Count(a => a.ToneInventory.Tones.Length > 0)}; OmittedTones not empty: {Analyzed.Count(a => a.ToneInventory.OmittedTones.Length > 0)}");

        // ---- 6. GA's comping recipes

        Title("GA's GuitarCompingRecipes (ChordProgressions.yaml) through YamlKnowledgeLoader (GA.Business.Config, compiled)");
        var recipes = List(yaml["GuitarCompingRecipes"]).Select(Map).ToList();
        var entries = YamlKnowledgeLoader.LoadAllKnowledgeEntries().Where(e => e.SourceFile == "ChordProgressions").ToList();
        Line($"  {entries.Count} entries from ChordProgressions.yaml");
        foreach (var recipe in recipes)
        {
            var entry = entries.FirstOrDefault(e => e.Name == (string)recipe["Name"]);
            var fingerings = Fingerings(recipe).ToList();
            Line($"  {recipe["Name"]}: {(entry is null ? "no entry" : $"an entry with {fingerings.Count(f => entry.Content.Contains(f))} of its {fingerings.Count} fingerings")}");
        }

        Title("Each fingering read low to high on its string set, standard tuning (the file's conventions, line 464); the notes of its name and degree order");
        Console.WriteLine($"{"strings",-8} {"fingering",-28} {"notes, low to high",-20} {"intervals",-11} {"name's notes",-13} degree order's notes");
        foreach (var recipe in recipes)
        {
            Line($"-- {recipe["Name"]}");
            var strings = ((string)recipe["StringSet"]).Split('-').Select(int.Parse).ToArray();
            foreach (var fingering in Fingerings(recipe))
            {
                var name = fingering[..fingering.IndexOf(": ", StringComparison.Ordinal)];
                var frets = fingering[(name.Length + 2)..].Split(' ')[0].Split('-');
                // a fingering with more frets than the set has strings is read from the sixth string up
                var on = frets.Length == strings.Length ? strings : [.. Enumerable.Range(0, frets.Length).Select(i => 6 - i)];
                var midi = frets.Select((fret, i) => fret == "x" ? -1 : OpenMidi(on[i]) + int.Parse(fret)).Where(m => m >= 0).ToArray();
                var intervals = string.Join(" ", midi.Skip(1).Select((m, i) => m - midi[i]));
                var (chord, order) = Named[name];
                var nameMatch = Theory.SetId(midi) == Theory.SetId(chord) ? "yes" : "no";
                var orderMatch = order is null ? "-" : Theory.SetId(midi) == Theory.SetId(order) ? "yes" : "no";
                var where = frets.Length == strings.Length ? string.Join("-", strings) : $"6 to {7 - frets.Length}*";
                Console.WriteLine($"{where,-8} {name + ": " + string.Join("-", frets),-28} {Notes(midi),-20} {intervals,-11} {nameMatch,-13} {orderMatch}");
            }
        }
        Line("  * five frets for a four-string set: read from string 6 to string 2");
        var blues = recipes.Single(r => ((string)r["Name"]).StartsWith("12-Bar Blues", StringComparison.Ordinal));
        Line($"-- {blues["Name"]}, {Map(blues["ExampleInKey"])["I7"]}");
        Line($"  the seventh of E7, D: fret {Theory.Mod12(2 - Theory.Mod12(OpenMidi(4)))} of string 4 (D); the third, G♯: fret {Theory.Mod12(8 - Theory.Mod12(OpenMidi(3)))} of string 3 (G)");
    }
}
