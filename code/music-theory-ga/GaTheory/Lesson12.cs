using System.Numerics;
using System.Text.RegularExpressions;
using GA.Domain.Core.Primitives.Notes;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Services.Atonal.Grothendieck;
using GaApi.Services;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 10 of the course, run as `l12`: chord substitutions (diatonic, tritone, secondary and backdoor
// dominants), the chatbot's ranking by interval-class vector, and chords borrowed from the parallel modes
public static partial class Lesson12
{
    // ---- Chords, spelled from their root: the types of lesson 3, plus the thirteenth

    static readonly (string Suffix, (int Degree, int Semitones)[] Tones)[] Types =
        [.. Lesson3.Chords, ("13", [(1, 0), (3, 4), (5, 7), (7, 10), (9, 14), (13, 21)])];

    static (string Root, string Suffix) Split(string chord)
    {
        var rootLength = chord.Length > 1 && chord[1] is '#' or 'b' ? 2 : 1;
        return (chord[..rootLength], chord[rootLength..]);
    }

    static (int Degree, int Semitones)[] Tones(string chord) => Types.Single(t => t.Suffix == Split(chord).Suffix).Tones;

    static int[] Pcs(string chord) => [.. Tones(chord).Select(t => Theory.Mod12(Theory.PitchClassOf(Split(chord).Root) + t.Semitones))];

    static string Spelled(string chord) => string.Join(" ", Tones(chord).Select(t => Theory.Spell(Split(chord).Root, t.Degree, t.Semitones)));

    // ---- Scales and their triads, spelled one letter per degree

    static readonly int[] MajorOffsets = [0, 2, 4, 5, 7, 9, 11];
    static readonly string[] ModeNames = ["Ionian", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Aeolian", "Locrian"];
    static readonly int[] MelodicMinorSteps = [2, 1, 2, 2, 2, 2, 1];

    // The steps of the major scale's modes, read from degree `mode` (1 = Ionian)
    static int[] ModeSteps(int mode) => [.. Enumerable.Range(0, 7).Select(k => Theory.MajorSteps[(mode - 1 + k) % 7])];

    // The chord stacked in thirds on a degree (0 to 6) of a spelled scale: three notes, or four for a seventh chord
    static string[] Stack(string[] scale, int degree, int size) => [.. Enumerable.Range(0, size).Select(k => scale[(degree + 2 * k) % 7])];

    static int Above(string root, string note) => Theory.Mod12(Theory.PitchClassOf(note) - Theory.PitchClassOf(root));

    // A triad's quality from its third and fifth: the suffix GA's closure writes, and the word GA's YAML writes
    static (string Suffix, string Word) Quality(string[] triad) => (Above(triad[0], triad[1]), Above(triad[0], triad[2])) switch
    {
        (4, 7) => ("", "major"),
        (3, 7) => ("m", "minor"),
        (3, 6) => ("dim", "diminished"),
        (4, 8) => ("aug", "augmented"),
        _ => ("?", "?"),
    };

    // A Roman numeral read against the major scale on the same tonic: b or # when the root is lowered or raised,
    // lower case for a minor or diminished chord, then ° (diminished), + (augmented), 7, ø7 or °7
    static string Numeral(string tonic, int degree, string[] chord)
    {
        string[] romans = ["I", "II", "III", "IV", "V", "VI", "VII"];
        var shift = Theory.Mod12(Above(tonic, chord[0]) - MajorOffsets[degree]);
        var accidental = shift switch { 0 => "", 1 => "#", 11 => "b", _ => "?" };
        var third = Above(chord[0], chord[1]);
        var fifth = Above(chord[0], chord[2]);
        var numeral = third == 3 ? romans[degree].ToLowerInvariant() : romans[degree];
        var mark = (third, fifth) switch { (3, 6) => "°", (4, 8) => "+", _ => "" };
        if (chord.Length == 4)
        {
            mark = (third, fifth, Above(chord[0], chord[3])) switch
            {
                (4, 7, 10) or (3, 7, 10) => "7",
                (4, 7, 11) => "maj7",
                (3, 6, 10) => "ø7",
                (3, 6, 9) => "°7",
                _ => "?7",
            };
        }
        return accidental + numeral + mark;
    }

    static bool SameNotes(string[] a, string[] b) => Theory.SetId(a.Select(Theory.PitchClassOf)) == Theory.SetId(b.Select(Theory.PitchClassOf));

    // ---- The course's diatonic substitutes: the key's triads on the other degrees, by the notes they share

    static List<(string Chord, int Shared)> CourseSubstitutes(string chord, string tonic, bool minor)
    {
        var scale = Theory.SpellScale(tonic, minor ? Theory.NaturalMinorSteps : Theory.MajorSteps);
        var target = Pcs(chord);
        return
        [
            .. Enumerable.Range(0, 7)
                .Select(d => Stack(scale, d, 3))
                .Where(t => Theory.PitchClassOf(t[0]) != Theory.PitchClassOf(Split(chord).Root))
                .Select(t => (Chord: t[0] + Quality(t).Suffix, Shared: t.Count(n => target.Contains(Theory.PitchClassOf(n)))))
                .Where(t => t.Shared > 0)
                .OrderByDescending(t => t.Shared),
        ];
    }

    static string Ranked(IEnumerable<(string Chord, int Shared)> list) => string.Join(", ", list.Select(s => $"{s.Chord} {s.Shared}")) is { Length: > 0 } s ? s : "(none)";

    // ---- GA's ga_chord_substitutions (the MCP server's GaDslTool.cs lines 208-222 at a826864) runs the F# closure
    // domain.chordSubstitutions (DomainClosures.fs lines 535-621), rewritten here with the chord parser it calls
    // (ChordDslService.Parse, which is ChordParser.parse, ChordParser.fs lines 7-89) and the helpers it uses
    // (DomainClosures.fs lines 10-51, 78-116, 263-266, 349-355)

    record ChordAst(string Root, int RootAccidental, string? Quality, string[] Extensions);

    static bool At(string s, int i, string token) => i + token.Length <= s.Length && string.CompareOrdinal(s, i, token, 0, token.Length) == 0;

    static readonly (string Token, string Quality)[] QualityTokens =
    [
        ("maj", "Major"), ("MAJ", "Major"), ("Maj", "Major"), ("M", "Major"), ("Δ", "Major"),
        ("min", "Minor"), ("MIN", "Minor"), ("mi", "Minor"), ("-", "Minor"), ("m", "Minor"),
        ("dim", "Diminished"), ("DIM", "Diminished"), ("°", "Diminished"), ("o", "Diminished"),
        ("aug", "Augmented"), ("AUG", "Augmented"), ("+", "Augmented"),
        ("sus", "Suspended"), ("SUS", "Suspended"),
    ];

    static readonly (string Token, string Extension)[] ExtensionTokens =
    [
        ("13", "13"), ("11", "11"), ("maj7", "maj7"), ("maj9", "maj9"), ("maj11", "maj11"), ("maj13", "maj13"),
        ("m7b5", "m7b5"), ("-7b5", "m7b5"), ("6/9", "6/9"), ("add9", "add9"), ("add11", "add11"), ("add13", "add13"),
        ("add2", "add2"), ("add4", "add4"),
    ];

    // pAccidental (lines 9-21): its length and its semitones, or (0, 0)
    static (int Length, int Semitones) Accidental(string s, int i) =>
        At(s, i, "##") ? (2, 2) : At(s, i, "x") ? (1, 2) : At(s, i, "bb") ? (2, -2)
        : At(s, i, "#") || At(s, i, "♯") ? (1, 1) : At(s, i, "b") || At(s, i, "♭") ? (1, -1) : At(s, i, "♮") ? (1, 0) : (0, 0);

    // pChord (lines 76-84) on the symbols of this lesson: a letter, an accidental, a quality ("maj" not before
    // a digit, "m" not before "a"), then extensions and alterations; the closure reads only the extensions
    static ChordAst ParseChord(string s)
    {
        var (accLength, acc) = Accidental(s, 1);
        var i = 1 + accLength;
        string? quality = null;
        foreach (var (token, q) in QualityTokens)
        {
            if (!At(s, i, token)) continue;
            if (token is "maj" or "MAJ" or "Maj" && i + 3 < s.Length && char.IsDigit(s[i + 3])) continue;
            if (token == "m" && At(s, i + 1, "a")) continue;
            quality = q;
            i += token.Length;
            break;
        }
        var extensions = new List<string>();
        while (i < s.Length)
        {
            var extension = ExtensionTokens.FirstOrDefault(e => At(s, i, e.Token));
            if (extension.Token is not null)
            {
                extensions.Add(extension.Extension);
                i += extension.Token.Length;
                continue;
            }
            if ("796245".Contains(s[i]))
            {
                extensions.Add(s[i].ToString());
                i++;
                continue;
            }
            // pAlteration (lines 69-74): "alt", or an optional accidental and 13, 11, 9 or 5
            if (At(s, i, "alt") || At(s, i, "ALT"))
            {
                i += 3;
                continue;
            }
            var (altLength, _) = Accidental(s, i);
            var degree = new[] { "13", "11", "9", "5" }.FirstOrDefault(d => At(s, i + altLength, d));
            if (degree is null) break;
            i += altLength + degree.Length;
        }
        return new ChordAst(s[..1].ToUpperInvariant(), acc, quality, [.. extensions]);
    }

    static readonly string[] SharpNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
    static readonly string[] FlatNames = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];

    static int NoteToSemitone(string note) => note switch { "C" => 0, "D" => 2, "E" => 4, "F" => 5, "G" => 7, "A" => 9, "B" => 11, _ => 0 };

    static string AccStr(int acc) => acc switch { 1 => "#", -1 => "b", 2 => "##", -2 => "bb", _ => "" };

    static string IntervalName(int n) => n switch
    {
        0 => "P1", 1 => "m2", 2 => "M2", 3 => "m3", 4 => "M3", 5 => "P4", 6 => "TT", 7 => "P5",
        8 => "m6", 9 => "M6", 10 => "m7", 11 => "M7", 14 => "M9", 15 => "m10", 17 => "P11", 21 => "M13",
        _ => $"+{n}",
    };

    static int[] QualityBaseIntervals(string? quality) => quality switch
    {
        "Minor" => [0, 3, 7],
        "Diminished" => [0, 3, 6],
        "Augmented" => [0, 4, 8],
        "Dominant" => [0, 4, 7, 10],
        "Suspended" => [0, 5, 7],
        _ => [0, 4, 7],
    };

    static int? ExtensionSemitone(string extension) => extension switch
    {
        "7" => 10, "maj7" => 11, "9" => 14, "maj9" => 14, "11" => 17, "13" => 21, _ => null,
    };

    static readonly (int Offset, string? Quality)[] MajorPattern =
        [(0, null), (2, "Minor"), (4, "Minor"), (5, null), (7, null), (9, "Minor"), (11, "Diminished")];

    static readonly (int Offset, string? Quality)[] MinorPattern =
        [(0, "Minor"), (2, "Diminished"), (3, null), (5, "Minor"), (7, "Minor"), (8, null), (10, null)];

    static string QualSuffix(string? quality) => quality switch
    {
        "Minor" => "m", "Diminished" => "dim", "Augmented" => "aug", "Suspended" => "sus", "Dominant" => "7", _ => "",
    };

    static string ConventionalKeyName(int pc) => pc is 1 or 3 or 8 or 10 ? FlatNames[pc] : SharpNames[pc];

    static bool PreferFlat(string note, int acc) => acc < 0 || (acc == 0 && note == "F");

    static (string Note, int Acc) SplitNoteAcc(string s) =>
        s.EndsWith("##") ? (s[..^2], 2)
        : s.EndsWith('#') ? (s[..^1], 1)
        : s.EndsWith("bb") ? (s[..^2], -2)
        : s.Length > 1 && s.EndsWith('b') && "CDEFGAB".Contains(s[0]) ? (s[..^1], -1)
        : (s, 0);

    static string NormalizeRoot(string s) => s.Length == 0 ? s : s[..1].ToUpperInvariant() + s[1..];

    static int RootPc(ChordAst a) => (NoteToSemitone(a.Root) + a.RootAccidental + 120) % 12;

    static int[] Ivals(ChordAst a) => [.. QualityBaseIntervals(a.Quality), .. a.Extensions.Select(ExtensionSemitone).OfType<int>()];

    static int[] ChordPitchClasses(ChordAst a) => [.. Ivals(a).Distinct().Select(i => (RootPc(a) + i) % 12)];

    static string Role(int[] ivals, int rootPc, int pc) => ivals.Where(i => (rootPc + i) % 12 == pc).Select(IntervalName).FirstOrDefault() ?? "?";

    // The closure: the key defaults to the chord's root letter and the scale to major; the key's triads are scored by
    // the notes they share with the chord, the chord itself skipped (same root and quality); List.sortByDescending is stable
    static (string Key, List<(string Chord, int Shared)> Subs, string? Tritone, string[] Text) GaSubstitutions(string symbol, string? key = null, string? scale = null)
    {
        var target = ParseChord(symbol);
        var targetRootPc = RootPc(target);
        var targetPcs = ChordPitchClasses(target);
        var keyStr = key ?? target.Root;
        var scaleStr = scale ?? "major";
        var (keyNote, keyAcc) = SplitNoteAcc(NormalizeRoot(keyStr));
        var keyPc = (NoteToSemitone(keyNote) + keyAcc + 120) % 12;
        var pattern = scaleStr.ToLowerInvariant() is "minor" or "aeolian" ? MinorPattern : MajorPattern;
        var naming = PreferFlat(keyNote, keyAcc) ? FlatNames : SharpNames;
        var tIvals = Ivals(target);
        var subs = new List<(string Chord, int Shared, string Desc)>();
        foreach (var (offset, quality) in pattern)
        {
            var (note, acc) = SplitNoteAcc(naming[(keyPc + offset) % 12]);
            var candidate = note + AccStr(acc) + QualSuffix(quality);
            var c = ParseChord(candidate);
            var cRootPc = RootPc(c);
            if (cRootPc == targetRootPc && c.Quality == target.Quality) continue;
            var cIvals = Ivals(c);
            var cPcs = ChordPitchClasses(c);
            var shared = targetPcs.Where(cPcs.Contains).ToList();
            if (shared.Count == 0) continue;
            var desc = string.Join(" ", shared.Select(pc => $"{ConventionalKeyName(pc)}({Role(tIvals, targetRootPc, pc)}/{Role(cIvals, cRootPc, pc)})"));
            subs.Add((candidate, shared.Count, desc));
        }
        subs = [.. subs.OrderByDescending(s => s.Shared)];
        // the tritone line: a chord with a major third and a minor seventh above its root
        var tritone = tIvals.Contains(4) && tIvals.Contains(10) ? $"{FlatNames[(targetRootPc + 6) % 12]}7" : null;
        var lines = subs.Select(s => $"  {(s.Shared >= 3 ? "★★★" : s.Shared == 2 ? "★★ " : "★  ")} {s.Chord,-6} — {s.Shared} shared: {s.Desc}").ToList();
        string[] text =
        [
            $"Substitutions for {symbol} in key of {keyStr} {scaleStr}:",
            .. lines.Count == 0 ? ["  (no diatonic substitutions found)"] : lines,
            .. tritone is null ? Array.Empty<string>() : [$"  ◈  {tritone,-6} — tritone sub (shares guide tones enharmonically)"],
        ];
        return ($"{keyStr} {scaleStr}", [.. subs.Select(s => (s.Chord, s.Shared))], tritone, text);
    }

    // ---- GA's chatbot skill ChordSubstitutionSkill (GA.Business.ML, ChordSubstitutionSkill.cs at a826864), copied as it is,
    // without its logger and its reply text; the GrothendieckService it calls is GA's, compiled as it is

    // The chord pattern (lines 69-71), case-sensitive
    [GeneratedRegex(@"\b(?<root>[A-G])(?<acc>[b#]?)(?<qual>m7b5|dim7|maj7|m7|7|min|m|dim|aug|\+)?(?!\w)")]
    private static partial Regex ExtendedChordSymbol();

    // Its twelve example prompts (lines 35-55)
    static readonly string[] SkillExamples =
    [
        "Tritone substitution for G7",
        "What can I substitute for Cmaj7 in a ii-V-I?",
        "Reharmonize Dm7 in a jazz context",
        "Alternative chord for F major in C",
        "What's the secondary dominant of Am?",
        "Show me a backdoor dominant for C major",
        "Alternative chord for Cmaj7",
        "What can replace Dm7?",
        "Swap chord for G7",
        "Modal interchange substitutes for C major",
        "Borrow a chord from parallel minor",
        "Modal interchange options in F major",
    ];

    // Lines 79-123
    static readonly Dictionary<string, int> RootPcMap = new(StringComparer.OrdinalIgnoreCase)
    {
        ["C"] = 0, ["C#"] = 1, ["Db"] = 1, ["D"] = 2, ["D#"] = 3, ["Eb"] = 3,
        ["E"] = 4, ["F"] = 5, ["F#"] = 6, ["Gb"] = 6, ["G"] = 7, ["G#"] = 8,
        ["Ab"] = 8, ["A"] = 9, ["A#"] = 10, ["Bb"] = 10, ["B"] = 11,
    };

    static readonly string[] RootNames = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];

    static readonly Dictionary<string, int[]> QualityIntervals = new(StringComparer.OrdinalIgnoreCase)
    {
        [""] = [0, 4, 7], ["m"] = [0, 3, 7], ["min"] = [0, 3, 7], ["dim"] = [0, 3, 6], ["aug"] = [0, 4, 8], ["+"] = [0, 4, 8],
        ["7"] = [0, 4, 7, 10], ["maj7"] = [0, 4, 7, 11], ["m7"] = [0, 3, 7, 10], ["m7b5"] = [0, 3, 6, 10], ["dim7"] = [0, 3, 6, 9],
    };

    static readonly int[] Dom7 = [0, 4, 7, 10];

    static readonly (int[] Intervals, string Suffix)[] ChordTemplates =
    [
        ([0, 4, 7], ""), ([0, 3, 7], "m"), ([0, 3, 6], "dim"), ([0, 4, 8], "aug"),
        ([0, 4, 7, 10], "7"), ([0, 4, 7, 11], "maj7"), ([0, 3, 7, 10], "m7"), ([0, 3, 6, 10], "m7b5"), ([0, 3, 6, 9], "dim7"),
    ];

    // Lines 126-140: the first name written for a set wins
    static readonly Dictionary<int, string> MaskToChord = BuildMaskToChord();

    static Dictionary<int, string> BuildMaskToChord()
    {
        var map = new Dictionary<int, string>();
        for (var root = 0; root < 12; root++)
        {
            foreach (var (intervals, suffix) in ChordTemplates)
            {
                var mask = intervals.Aggregate(0, (acc, i) => acc | (1 << ((root + i) % 12)));
                map.TryAdd(mask, $"{RootNames[root]}{suffix}");
            }
        }
        return map;
    }

    // Lines 305-328
    static (string Name, int Root, int[] Intervals)? TryParseChordMatch(Match m)
    {
        var rootStr = m.Groups["root"].Value + m.Groups["acc"].Value;
        if (!RootPcMap.TryGetValue(rootStr, out var rootPc)) return null;
        var qualStr = m.Groups["qual"].Value;
        if (!QualityIntervals.TryGetValue(qualStr, out var intervals)) intervals = QualityIntervals[""];
        var suffix = qualStr switch
        {
            "m" or "min" => "m",
            "dim" => "dim",
            "aug" or "+" => "aug",
            "7" => "7",
            "maj7" => "maj7",
            "m7" => "m7",
            "m7b5" => "m7b5",
            "dim7" => "dim7",
            _ => "",
        };
        return ($"{rootStr}{suffix}", rootPc, intervals);
    }

    // Lines 330-340
    static (string Name, PitchClassSet Set)? SkillParseChord(string message)
    {
        var match = ExtendedChordSymbol().Match(message);
        if (!match.Success) return null;
        var parsed = TryParseChordMatch(match);
        if (parsed is null) return null;
        var pcs = parsed.Value.Intervals.Select(offset => PitchClass.FromValue((parsed.Value.Root + offset) % 12));
        return (parsed.Value.Name, new PitchClassSet(pcs));
    }

    // Lines 342-346
    static string SetName(PitchClassSet set)
    {
        var mask = set.Aggregate(0, (acc, pc) => acc | (1 << pc.Value));
        return MaskToChord.TryGetValue(mask, out var name) ? name : set.Name;
    }

    static readonly GrothendieckService Grothendieck = new();

    // Lines 164-174 without the Take(5): GA's FindNearby, the source and the other sizes left out, ordered by cost
    static List<(PitchClassSet Set, GrothendieckDelta Delta, double Cost)> SkillCandidates(PitchClassSet sourceSet) =>
    [
        .. Grothendieck.FindNearby(sourceSet, maxDistance: 3)
            .Where(r => r.Set.PitchClassMask != sourceSet.PitchClassMask && r.Set.Cardinality == sourceSet.Cardinality)
            .OrderBy(r => r.Cost),
    ];

    // ClassifySubstitution (lines 246-298), the labels without their explanations
    static List<string> SkillRelations((string Name, int Root, int[] Intervals) a, (string Name, int Root, int[] Intervals) b)
    {
        var results = new List<string>();
        var ab = (b.Root - a.Root + 12) % 12;
        var ba = (a.Root - b.Root + 12) % 12;
        if (ab == 6 && a.Intervals.SequenceEqual(Dom7) && b.Intervals.SequenceEqual(Dom7)) results.Add("Tritone Substitution");
        if (ba == 7) results.Add("Secondary Dominant");
        if (ba == 10 && a.Intervals.SequenceEqual(Dom7)) results.Add("Backdoor Dominant");
        var setA = new PitchClassSet(a.Intervals.Select(i => PitchClass.FromValue((a.Root + i) % 12)));
        var setB = new PitchClassSet(b.Intervals.Select(i => PitchClass.FromValue((b.Root + i) % 12)));
        var pfA = setA.PrimeForm?.PitchClassMask;
        var pfB = setB.PrimeForm?.PitchClassMask;
        if (pfA.HasValue && pfA == pfB) results.Add("Set-Class Equivalent");
        var delta = Grothendieck.ComputeDelta(setA.IntervalClassVector, setB.IntervalClassVector);
        if (delta.L1Norm <= 2) results.Add($"ICV Neighbor (L1 = {delta.L1Norm})");
        if (results.Count == 0) results.Add("Harmonic Distance");
        return results;
    }

    static (string Name, int Root, int[] Intervals) SkillChord(string symbol) => TryParseChordMatch(ExtendedChordSymbol().Match(symbol))!.Value;

    // ---- The course's reading of two chords, with the skill's names for the relations

    static List<string> CourseRelations(string a, string b)
    {
        var (ra, sa) = (Theory.PitchClassOf(Split(a).Root), Split(a).Suffix);
        var (rb, sb) = (Theory.PitchClassOf(Split(b).Root), Split(b).Suffix);
        var labels = new List<string>();
        // two dominant sevenths a tritone apart
        if (sa == "7" && sb == "7" && Theory.Mod12(rb - ra) == 6) labels.Add("Tritone Substitution");
        // a major triad or a dominant seventh a fifth above a chord that can be tonicized: major or minor, not diminished or augmented
        if (sa is "" or "7" && sb is "" or "m" or "7" or "maj7" or "m7" && Theory.Mod12(ra - rb) == 7) labels.Add("Secondary Dominant");
        // a dominant seventh a whole step below its resolution
        if (sa == "7" && Theory.Mod12(ra - rb) == 10) labels.Add("Backdoor Dominant");
        var (ida, idb) = (Theory.SetId(Pcs(a)), Theory.SetId(Pcs(b)));
        if (Theory.PrimeForm(ida).SequenceEqual(Theory.PrimeForm(idb))) labels.Add("Set-Class Equivalent");
        var l1 = Theory.Icv(ida).Zip(Theory.Icv(idb), (x, y) => Math.Abs(x - y)).Sum();
        if (l1 <= 2) labels.Add($"ICV Neighbor (L1 = {l1})");
        if (labels.Count == 0) labels.Add("Harmonic Distance");
        return labels;
    }

    // ---- GA's ModalInterchange.yaml: the few fields this lesson reads, with a line reader

    static List<(string Entry, string Source, string Target, string Numeral, string Key, string Chord)> ReadMixtureChords(string path)
    {
        var chords = new List<(string, string, string, string, string, string)>();
        string entry = "", source = "", target = "", numeral = "";
        foreach (var line in File.ReadLines(path))
        {
            if (line.StartsWith("  - Name: ")) entry = line["  - Name: ".Length..];
            else if (line.StartsWith("    SourceMode: ")) source = line["    SourceMode: ".Length..];
            else if (line.StartsWith("    TargetMode: ")) target = line["    TargetMode: ".Length..];
            else if (line.StartsWith("        RomanNumeral: ")) numeral = line["        RomanNumeral: ".Length..];
            else if (line.StartsWith("        InKeyOf"))
            {
                var colon = line.IndexOf(':');
                chords.Add((entry, source, target, numeral, line["        InKeyOf".Length..colon], line[(colon + 2)..]));
            }
        }
        return chords;
    }

    // The numerals listed under "Chromatic Modal Interchange", mode by mode
    static List<(string Mode, string Numeral)> ReadChromaticNumerals(string path)
    {
        var numerals = new List<(string, string)>();
        string entry = "", mode = "";
        var inList = false;
        foreach (var line in File.ReadLines(path))
        {
            if (line.StartsWith("  - Name: ")) entry = line["  - Name: ".Length..];
            if (entry != "Chromatic Modal Interchange") continue;
            if (line.StartsWith("      - Mode: ")) mode = line["      - Mode: ".Length..];
            if (line.StartsWith("          - ") && inList) numerals.Add((mode, line["          - ".Length..]));
            else inList = line.StartsWith("        BorrowedChords:");
        }
        return numerals;
    }

    static int[] StepsOf(string mode) => mode switch
    {
        "Major" => Theory.MajorSteps,
        "Natural Minor" => Theory.NaturalMinorSteps,
        "Harmonic Minor" => Theory.HarmonicMinorSteps,
        "Melodic Minor" => MelodicMinorSteps,
        _ => ModeSteps(Array.IndexOf(ModeNames, mode) + 1),
    };

    // "bVII", "ii°", "vii°7" -> the degree, 0 to 6
    static int DegreeOf(string numeral)
    {
        var start = 0;
        while (start < numeral.Length && numeral[start] is 'b' or '#') start++;
        var end = start;
        while (end < numeral.Length && "IViv".Contains(numeral[end])) end++;
        string[] romans = ["I", "II", "III", "IV", "V", "VI", "VII"];
        return Array.IndexOf(romans, numeral[start..end].ToUpperInvariant());
    }

    // ---- Borrowed chords: the course lists, mode by mode, the triads of the parallel mode that the home key lacks

    static List<(int Degree, string[] Triad)> CourseBorrowed(string tonic, int mode, int homeMode)
    {
        var home = Theory.SpellScale(tonic, ModeSteps(homeMode));
        var parallel = Theory.SpellScale(tonic, ModeSteps(mode));
        var homeTriads = Enumerable.Range(0, 7).Select(d => Stack(home, d, 3)).ToList();
        return [.. Enumerable.Range(0, 7).Select(d => (d, Stack(parallel, d, 3))).Where(t => !homeTriads.Any(h => SameNotes(h, t.Item2)))];
    }

    static string Name(string[] triad) => triad[0] + Quality(triad).Suffix;

    // GA writes its sharps and flats ♯ and ♭; the comparisons read them as # and b, so only the spelling counts
    static string Ascii(string s) => s.Replace('♯', '#').Replace('♭', 'b');

    static string Join(IEnumerable<string> items) => string.Join(" ", items);

    // A comparison too wide for one row: the check on the first line, then each side on its own
    static void Pair(string label, string course, string ga)
    {
        Line($"{label,-10} {(course == ga ? "ok" : "DIFF")}");
        if (ga == course)
        {
            Line($"  course and GA: {course}");
            return;
        }
        Line($"  course: {course}");
        Line($"  GA:     {ga}");
    }

    public static void Run()
    {
        Title("Diatonic substitutes in C major, by the notes they share (GA: ga_chord_substitutions, the closure rewritten)");
        Columns("chord", 10, 36);
        foreach (var chord in new[] { "Am", "Em", "F", "C", "G7", "Cmaj7", "Bm7b5" })
        {
            Row(chord, Ranked(CourseSubstitutes(chord, "C", false)), Ranked(GaSubstitutions(chord, "C").Subs));
            var gaPcs = ChordPitchClasses(ParseChord(chord));
            if (Theory.SetId(Pcs(chord)) != Theory.SetId(gaPcs))
                Line($"  the course's {chord}: {Spelled(chord)}; the closure's: {Join(gaPcs.Select(ConventionalKeyName))}");
        }

        Title("The closure's answer for Am in C major, and the example in the tool's description (GaDslTool.cs line 212)");
        foreach (var line in GaSubstitutions("Am", "C").Text) Line($"  {line}");
        Line("  description: Am in key of C major → C (★★★, relative major), Em (★★, shared E/B), F (★, shared A)");

        Title("Without a key, the closure uses the chord's root letter as a major key (line 558)");
        Headings("chord", "GA's key", "GA's ranking", 10, 12);
        foreach (var chord in new[] { "Am", "Bb7", "F#m", "Eb" })
        {
            var ga = GaSubstitutions(chord);
            Plain(chord, ga.Key, Ranked(ga.Subs) + (ga.Tritone is null ? "" : $"; tritone {ga.Tritone}"));
        }

        Title("The tritone substitute: the course's dominant chords, and the closure's test for M3 and m7 (lines 603-609)");
        Columns("chord", 10, 12);
        foreach (var chord in new[] { "G7", "D7", "E7", "C7", "G9", "G13", "Gm7", "Cmaj7" })
        {
            var tones = Tones(chord).Select(t => t.Semitones % 12).ToArray();
            var course = tones.Contains(4) && tones.Contains(10) ? Theory.Spell(Split(chord).Root, 5, 6) + "7" : null;
            Row(chord, course, GaSubstitutions(chord, "C").Tritone);
        }

        Title("GA's chatbot skill: what its own twelve example prompts parse to (ChordSubstitutionSkill.cs lines 146-160)");
        foreach (var prompt in SkillExamples)
        {
            var chords = ExtendedChordSymbol().Matches(prompt).Select(TryParseChordMatch).Where(c => c.HasValue).Select(c => c!.Value).Take(2).ToList();
            var path = chords.Count == 2 ? $"compares {chords[0].Name} with {chords[1].Name}"
                : SkillParseChord(prompt) is { } one ? $"lists substitutes for {one.Name}"
                : "no chord: \"Could not identify a chord symbol in your message.\"";
            Line($"  {prompt,-46} {path}");
        }

        Title("The skill's list for one chord: GA's FindNearby, then the first five of the same size, by cost");
        Line("course: the other chords of the same size with the same ICV; GA: the chords at the lowest cost it lists");
        Columns("chord", 10, 10);
        foreach (var (chord, textbook) in new[]
                 {
                     ("G7", new[] { "Db7" }), ("Am", new[] { "C", "F" }), ("C", new[] { "Am", "Em" }),
                     ("Cmaj7", new[] { "Em7", "Am7" }), ("Dm7", new[] { "Fmaj7" }),
                 })
        {
            var (name, source) = SkillParseChord(chord)!.Value;
            var candidates = SkillCandidates(source);
            var id = Theory.SetId(Pcs(chord));
            var size = BitOperations.PopCount((uint)id);
            var sameIcv = Enumerable.Range(0, 4096).Count(x => x != id && BitOperations.PopCount((uint)x) == size && Theory.Icv(x).SequenceEqual(Theory.Icv(id)));
            Row(name, sameIcv, candidates.Count(r => r.Cost == candidates[0].Cost));
            foreach (var (set, delta, cost) in candidates.Take(5))
            {
                var shared = BitOperations.PopCount((uint)(set.PitchClassMask & id));
                Line($"  - **{SetName(set)}** — harmonic cost {cost:F2} (Δ L1={delta.L1Norm})".PadRight(46) + $"id {set.PitchClassMask,4}, {shared} {(shared == 1 ? "note" : "notes")} in common with {name}");
            }
            foreach (var sub in textbook)
            {
                var mask = Theory.SetId(Pcs(sub));
                var index = candidates.FindIndex(r => r.Set.PitchClassMask == mask);
                var subSet = new PitchClassSet(Pcs(sub).Select(PitchClass.FromValue));
                Line(index >= 0
                    ? $"  textbook {sub}: number {index + 1} of the {candidates.Count} it lists, cost {candidates[index].Cost:F2}"
                    : $"  textbook {sub}: not listed (Δ L1={Grothendieck.ComputeDelta(source.IntervalClassVector, subSet.IntervalClassVector).L1Norm}, beyond 3)");
            }
        }

        Title("Over the twelve roots of each chord type, the skill's lists of five");
        Headings("type", "different chords", "first suggestion, and for how many roots", 8, 18);
        foreach (var (intervals, suffix) in ChordTemplates)
        {
            var lists = Enumerable.Range(0, 12)
                .Select(root => SkillCandidates(new PitchClassSet(intervals.Select(i => PitchClass.FromValue((root + i) % 12)))).Take(5).Select(r => SetName(r.Set)).ToList())
                .ToList();
            var first = lists.GroupBy(l => l[0]).Select(g => $"{g.Key} {g.Count()}");
            Plain(suffix.Length == 0 ? "major" : suffix, lists.SelectMany(l => l).Distinct().Count(), string.Join(", ", first));
        }

        Title("Two chords: the course's reading and the skill's labels (ClassifySubstitution, lines 246-298)");
        foreach (var (a, b) in new[] { ("G7", "Db7"), ("G7", "C"), ("D7", "G"), ("Dm", "G"), ("F#", "Bdim"), ("C", "C"), ("C", "Am"), ("Bb7", "C") })
        {
            Pair($"{a} {b}", string.Join(", ", CourseRelations(a, b)), string.Join(", ", SkillRelations(SkillChord(a), SkillChord(b))));
        }

        var borrowed = new ContextualChordService().GetBorrowedChordsAsync("C major").GetAwaiter().GetResult().GetValueOrThrow().ToList();

        Title("Borrowed chords for C major: GA's get_borrowed_chords (ContextualChordService, compiled as it is), chord by chord");
        Columns("GA's mode", 12, 18);
        foreach (var chord in borrowed)
        {
            var mode = Array.IndexOf(ModeNames, chord.SourceMode) + 1;
            var degree = chord.ScaleDegree!.Value - 1;
            var triad = Stack(Theory.SpellScale("C", ModeSteps(mode)), degree, 3);
            Row(chord.SourceMode, $"{Numeral("C", degree, triad)} {Name(triad)}", $"{chord.RomanNumeral} {Ascii(chord.ContextualName)}");
            if (Join(triad) != Ascii(Join(chord.Notes))) Line($"  notes: course {Join(triad)}, GA {Join(chord.Notes)}");
        }

        Title("The course's borrowed chords, mode by mode: every triad of the parallel mode that C major lacks");
        Headings("mode", "chords", "", 12, 0);
        var distinct = new HashSet<int>();
        for (var mode = 2; mode <= 7; mode++)
        {
            var list = CourseBorrowed("C", mode, 1);
            foreach (var (_, triad) in list) distinct.Add(Theory.SetId(triad.Select(Theory.PitchClassOf)));
            Plain(ModeNames[mode - 1], string.Join(", ", list.Select(t => $"{Numeral("C", t.Degree, t.Triad)} {Name(t.Triad)}")));
        }
        Columns("count", 18, 8);
        Row("distinct chords", distinct.Count, borrowed.Count);

        var yaml = Path.Combine(AppContext.BaseDirectory, "ModalInterchange.yaml");

        Title("GA's ModalInterchange.yaml: each chord spelled from its numeral in its source mode");
        Columns("entry, numeral", 24, 16);
        foreach (var (entry, source, target, numeral, key, chord) in ReadMixtureChords(yaml))
        {
            var tonic = key.TrimEnd('m');
            var degree = DegreeOf(numeral);
            var triad = Stack(Theory.SpellScale(tonic, StepsOf(source)), degree, 3);
            var label = entry.Replace("Borrowed Chords from ", "").Replace(" Interchange", "");
            Row($"{label} {numeral}", $"{triad[0]} {Quality(triad).Word}", chord);
            var targetScale = Theory.SpellScale(tonic, StepsOf(target));
            var gaRoot = chord.Split(' ')[0];
            if (Enumerable.Range(0, 7).Select(d => Stack(targetScale, d, 3)).Any(t => Theory.PitchClassOf(t[0]) == Theory.PitchClassOf(gaRoot) && Quality(t).Word == chord.Split(' ')[1]))
                Line($"  {chord} is already a chord of {tonic} {target.ToLowerInvariant()}: nothing is borrowed");
        }

        Title("Its chromatic numerals, read in C: the chord on that degree of the mode");
        Columns("mode, numeral", 24, 10);
        foreach (var (mode, numeral) in ReadChromaticNumerals(yaml))
        {
            var degree = DegreeOf(numeral);
            var chord = Stack(Theory.SpellScale("C", StepsOf(mode)), degree, numeral.Contains('7') ? 4 : 3);
            Row($"{mode} {numeral}", Numeral("C", degree, chord), numeral);
            Line($"  {Join(chord)}");
        }

        Title("Who reads the file: GA's YamlKnowledgeLoader (GA.Business.Config, compiled), which flattens every content YAML");
        var entries = GA.Business.Config.YamlKnowledgeLoader.LoadAllKnowledgeEntries().Where(e => e.SourceFile == "ModalInterchange").ToList();
        Line($"  {entries.Count} entries from ModalInterchange.yaml:");
        foreach (var entry in entries) Line($"    {entry.Name}");
        foreach (var claim in new[] { "InKeyOfAm: F major", "InKeyOfAm: Bb diminished", "bVI+", "iv+" })
            Line($"  \"{claim}\" in their text: {(entries.Any(e => e.Content.Contains(claim)) ? "yes" : "no")}");

        Title("Exercise solutions");
        Columns("question", 22, 24);
        Row("1. Dm in F major", Ranked(CourseSubstitutes("Dm", "F", false)), Ranked(GaSubstitutions("Dm", "F").Subs));
        Row("2. A7, tritone", Theory.Spell("A", 5, 6) + "7", GaSubstitutions("A7", "C").Tritone);
        Line($"  A7: {Spelled("A7")}; Eb7: {Spelled("Eb7")}");
        var a7 = SkillCandidates(SkillParseChord("A7")!.Value.Set);
        Row("3. chatbot, A7", Theory.Spell("A", 5, 6) + "7", SetName(a7[0].Set));
        var gMajor = new ContextualChordService().GetBorrowedChordsAsync("G major").GetAwaiter().GetResult().GetValueOrThrow().ToList();
        var gMinor = Theory.SpellScale("G", Theory.NaturalMinorSteps);
        var gMajorScale = Theory.SpellScale("G", Theory.MajorSteps);
        var course4 = Enumerable.Range(0, 7).Select(d => Stack(gMinor, d, 3)).Where(t => !Enumerable.Range(0, 7).Any(d => SameNotes(Stack(gMajorScale, d, 3), t)));
        var minorPcs = Theory.SetId(gMinor.Select(Theory.PitchClassOf));
        var ga4 = gMajor.Where(c => (Theory.SetId(c.Notes.Select(n => Theory.PitchClassOf(Ascii(n)))) & ~minorPcs) == 0)
            .OrderBy(c => Theory.Mod12(Theory.PitchClassOf(Ascii(c.Notes[0])) - 7)).Select(c => Ascii(c.ContextualName));
        Row("4. G minor in G", Join(course4.Select(Name)), Join(ga4));
    }
}
