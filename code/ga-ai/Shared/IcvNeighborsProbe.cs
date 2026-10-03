namespace GaAi;

using System.Globalization;
using System.Reflection;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Intents;
using GA.Business.ML.Agents.Skills;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Services.Atonal.Grothendieck;
using Microsoft.Extensions.Logging.Abstractions;
using static Report;

// Lesson 22: IcvNeighborsSkill, asked directly. The skill reads one chord out of a question,
// builds its pitch-class set, and lists the sets whose interval-class vectors are 1 or 2 away
// (L1), from GrothendieckService.FindNearby
public static class IcvNeighborsProbe
{
    public static IcvNeighborsSkill Skill()
    {
        // The skill formats its costs with the current culture; the course prints them as GA's
        // tests read them
        CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
        return new(new GrothendieckService(), NullLogger<IcvNeighborsSkill>.Instance);
    }

    internal static readonly string[] Names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

    // ---- Reading the skill's answer ----

    sealed record Neighbor(int[] Pcs, string Icv, int L1, string Cost);

    sealed record Answer(string Kind, string? Chord, string? SourceIcv, List<Neighbor> Rows, string Text)
    {
        public string Says => Kind switch
        {
            "answer" => $"neighbors of {Chord}",
            "unparsed" => "can't parse",
            _ => "declined",
        };

        // The table, without the line that names the chord
        public string Table => string.Join("\n", Rows.Select(r => $"{string.Join(",", r.Pcs)}|{r.Icv}|{r.L1}|{r.Cost}"));
    }

    static Answer Ask(IOrchestratorSkill skill, string prompt)
    {
        var text = skill.ExecuteAsync(prompt).GetAwaiter().GetResult().Result;
        if (text.StartsWith("I couldn't parse")) return new("unparsed", null, null, [], text);
        if (!text.StartsWith("**ICV neighbors of ")) return new("declined", null, null, [], text);
        var chord = text["**ICV neighbors of ".Length..text.IndexOf("**", 2)];
        var lines = text.Split('\n').Select(l => l.TrimEnd('\r')).ToList();
        var icv = lines.First(l => l.StartsWith("- Source ICV:")).Split('`')[1];
        var rows = lines.Where(l => l.StartsWith("| `{")).Select(l =>
        {
            var cells = l.Trim('|', ' ').Split(" | ");
            var pcs = cells[0].Trim('`', '{', '}').Split(',').Select(int.Parse).ToArray();
            return new Neighbor(pcs, cells[1].Trim('`'), int.Parse(cells[2]), cells[3]);
        }).ToList();
        return new("answer", chord, icv, rows, text);
    }

    static readonly MethodInfo BuildPcSet =
        typeof(IcvNeighborsSkill).GetMethod("TryBuildPcSet", BindingFlags.NonPublic | BindingFlags.Static)!;

    // The set the skill builds for a chord token (IcvNeighborsSkill.TryBuildPcSet, private)
    static PitchClassSet? Built(string token) => (PitchClassSet?)BuildPcSet.Invoke(null, [token]);

    internal static string Notes(IEnumerable<int> pcs) => string.Join(" ", pcs.Select(p => Names[p]));

    internal static PitchClassSet Set(IEnumerable<int> pcs) => new(pcs.Select(p => PitchClass.FromValue(p % 12)));

    internal static string Forte(PitchClassSet set) =>
        set.PrimeForm is { } prime && ForteCatalog.TryGetForteNumber(prime, out var forte) ? forte.ToString() : "?";

    static string Sizes(IEnumerable<int> sizes) => string.Join(", ", sizes.Distinct().Order());

    internal static int L1(IntervalClassVector a, IntervalClassVector b) =>
        Enumerable.Range(1, 6).Sum(ic => Math.Abs(a[IntervalClass.FromValue(ic)] - b[IntervalClass.FromValue(ic)]));

    // ---- The example prompts ----

    // The phrasings GA gives the skill: its routing anchors (ExamplePrompts), the surface forms of
    // its doc comment (IcvNeighborsSkill.cs lines 19-22), the two its refusal suggests (line 257),
    // and the parked draft's (skills-dev/_pending-tools/icv-neighbors/DRAFT.md lines 45-47)
    static readonly (string Prompt, string From)[] Others =
    [
        ("What chords are harmonically close to Cmaj7", "doc comment"),
        ("Nearby pitch-class sets to C major", "doc comment"),
        ("Find ICV neighbors of Dm7", "doc comment"),
        ("Closest chord to G7 in ICV space", "doc comment"),
        ("ICV neighbors of Cmaj7", "refusal"),
        ("what chords are harmonically close to Dm7", "refusal"),
        ("Harmonically similar chords to Cmaj7", "parked draft"),
        ("ICV neighbours of [0,3,6,9]", "parked draft"),
        ("What's close to a half-diminished chord?", "parked draft"),
    ];

    public static void ExamplesTable(IOrchestratorSkill skill, string where)
    {
        Title($"IcvNeighborsSkill's example prompts and GA's other phrasings for it, {where}");
        var hints = new DefaultRoutingHintProvider();
        int[] w = [50, 14, 24];
        Row(w, "prompt", "from", "the skill's answer", "routing hints, +0.06 each");
        var prompts = skill.ExamplePrompts.Select(p => (Prompt: p, From: "anchor")).Concat(Others).ToList();
        foreach (var (prompt, from) in prompts)
        {
            var hint = hints.GetDeltas(prompt).Keys.Order(StringComparer.Ordinal).ToList();
            Row(w, prompt, from, Ask(skill, prompt).Says, hint.Count == 0 ? "none" : string.Join(", ", hint));
        }
        var anchors = skill.ExamplePrompts.Select(p => Ask(skill, p)).ToList();
        Line($"anchors {anchors.Count}: answered {anchors.Count(a => a.Kind == "answer")}, " +
             $"declined {anchors.Count(a => a.Kind == "declined")}, " +
             $"hinted toward skill.icvneighbors {skill.ExamplePrompts.Count(p => hints.GetDeltas(p).ContainsKey("skill.icvneighbors"))}");
        Line($"CanHandle accepts {skill.ExamplePrompts.Count(skill.CanHandle)} of them");
    }

    // IntervalClassVectorSkill, whose anchors were curated in the same pass (its lines 43-47): what
    // it answers to them
    public static void SisterTable(string where)
    {
        Title($"IntervalClassVectorSkill's example prompts, {where}");
        var icv = new IntervalClassVectorSkill(new GrothendieckService(), NullLogger<IntervalClassVectorSkill>.Instance);
        int[] w = [50];
        Row(w, "prompt", "the skill's answer");
        foreach (var p in icv.ExamplePrompts)
        {
            var text = icv.ExecuteAsync(p).GetAwaiter().GetResult().Result;
            Row(w, p, text.StartsWith("**ICV of ") ? text[2..text.IndexOf("**", 2)] : text.StartsWith("Ask for") ? "declined" : "can't parse");
        }
        Line($"anchors {icv.ExamplePrompts.Count}: answered " +
             $"{icv.ExamplePrompts.Count(p => icv.ExecuteAsync(p).GetAwaiter().GetResult().Result.StartsWith("**ICV of "))}");
    }

    // ---- The chords it reads ----

    // Each chord, after "ICV neighbors of", with the notes a textbook gives it, root C unless named
    internal static readonly (string Token, int[] Pcs)[] Chords =
    [
        ("C", [0, 4, 7]), ("Cm", [0, 3, 7]), ("Cmaj7", [0, 4, 7, 11]), ("CM7", [0, 4, 7, 11]),
        ("Cmin7", [0, 3, 7, 10]), ("Cdom7", [0, 4, 7, 10]), ("Cm7b5", [0, 3, 6, 10]), ("Cø7", [0, 3, 6, 10]),
        ("Cdim", [0, 3, 6]), ("C°", [0, 3, 6]), ("Cdim7", [0, 3, 6, 9]), ("C°7", [0, 3, 6, 9]),
        ("Caug", [0, 4, 8]), ("C+", [0, 4, 8]), ("Cadd9", [0, 2, 4, 7]), ("C7sus4", [0, 5, 7, 10]),
        ("C7b9", [0, 1, 4, 7, 10]), ("C7#9", [0, 3, 4, 7, 10]), ("Cm11", [0, 2, 3, 5, 7, 10]),
        ("C13", [0, 2, 4, 7, 9, 10]), ("CmMaj7", [0, 3, 7, 11]), ("C5", [0, 7]),
        ("F#m7b5", [0, 4, 6, 9]), ("B♭7", [2, 5, 8, 10]), ("C minor", [0, 3, 7]), ("A minor", [0, 4, 9]),
        ("a Cmaj7", [0, 4, 7, 11]),
    ];

    public static void ReadingTable(IOrchestratorSkill skill, string where)
    {
        Title($"The chords the skill reads, after \"ICV neighbors of\", {where}");
        int[] w = [10, 18, 16, 18];
        Row(w, "chord", "its notes", "read as", "notes built", "right");
        var right = 0;
        foreach (var (token, pcs) in Chords)
        {
            var a = Ask(skill, $"ICV neighbors of {token}");
            var built = a.Chord is null ? null : Built(a.Chord);
            var ok = built is not null && built.Select(p => p.Value).Order().SequenceEqual(pcs.Order());
            right += ok ? 1 : 0;
            Row(w, token, Notes(pcs), a.Kind == "answer" ? a.Chord : a.Says,
                built is null ? "-" : Notes(built.Select(p => p.Value)), ok ? "yes" : "no");
        }
        Line($"chords {Chords.Length}: built right {right}");
    }

    // ---- The neighbors it lists ----

    internal static readonly string[] Qualities =
        ["", "m", "dim", "aug", "7", "m7", "maj7", "m7b5", "dim7", "sus2", "sus4", "6", "m6", "9", "maj9", "m9"];

    public static void RowsTable(IOrchestratorSkill skill, string where)
    {
        Title($"The neighbors the skill lists for a chord, {where}");
        int[] w = [7, 15, 13, 12, 9, 6, 9, 10, 13, 10];
        Row(w, "chord", "its vector", "sets 1-2 off", "set classes", "of notes", "rows", "of notes", "L1, cost", "set classes", "with a C", "the first by id");
        foreach (var q in Qualities)
        {
            var chord = "C" + q;
            var a = Ask(skill, $"ICV neighbors of {chord}");
            var source = Built(chord)!;
            var icv = source.IntervalClassVector;
            var near = PitchClassSet.Items.Where(s => L1(icv, s.IntervalClassVector) is 1 or 2).ToList();
            var firstById = near.OrderBy(s => s.Id.Value).Take(8).Select(s => string.Join(",", s.Select(p => p.Value)));
            var rows = a.Rows.Select(r => string.Join(",", r.Pcs));
            Row(w, chord, a.SourceIcv, near.Count, near.Select(Forte).Distinct().Count(), Sizes(near.Select(s => s.Count)), a.Rows.Count,
                a.Rows.Count == 0 ? "-" : Sizes(a.Rows.Select(r => r.Pcs.Length)),
                a.Rows.Count == 0 ? "-" : string.Join("; ", a.Rows.Select(r => $"{r.L1}, {r.Cost}").Distinct()),
                a.Rows.Select(r => Forte(Set(r.Pcs))).Distinct().Count(), a.Rows.Count(r => r.Pcs.Contains(0)),
                a.Rows.Count == 0 ? "-" : firstById.SequenceEqual(rows) ? "yes" : "no");
        }

        var c = Ask(skill, "ICV neighbors of C");
        Line("the rows for C:");
        foreach (var r in c.Rows)
            Line($"  {"{" + string.Join(",", r.Pcs) + "}",-9} {Notes(r.Pcs),-10} {Forte(Set(r.Pcs)),-6} {r.Icv}");
        var empty = Ask(skill, "ICV neighbors of Cdim7");
        Line($"Cdim7: {empty.Text.Split('\n').Select(l => l.TrimEnd('\r')).First(l => l.StartsWith("No pitch-class sets"))}");

        // The same question for every root: the rows depend on the vector only
        var answers = Qualities.SelectMany(q => Names.Select(n => (q, a: Ask(skill, $"ICV neighbors of {n}{q}")))).ToList();
        var sameForRoots = Qualities.Count(q => answers.Where(x => x.q == q).Select(x => x.a.Table).Distinct().Count() == 1);
        Line($"chords {answers.Count}: qualities whose 12 roots get the same rows {sameForRoots} of {Qualities.Length}; " +
             $"different answers {answers.Select(x => x.a.Table).Distinct().Count()}, " +
             $"different vectors {answers.Select(x => x.a.SourceIcv).Distinct().Count()}");
    }

    // ---- The parked draft's example ----

    // skills-dev/_pending-tools/icv-neighbors/DRAFT.md lines 53-58: Cmaj7's vector, then three
    // neighbors with a distance each
    public static void DraftTable(string where)
    {
        Title($"The parked draft's example for Cmaj7, {where}");
        var cmaj7 = Set([0, 4, 7, 11]);
        int[] w = [22, 14, 16, 6, 6];
        Row(w, "chord", "notes", "vector", "Forte", "L1", "the draft");
        foreach (var (name, pcs, draft) in new (string, int[], string)[]
                 {
                     ("Cmaj7", [0, 4, 7, 11], "[1, 0, 1, 2, 2, 0], 4-20"),
                     ("Am7", [9, 0, 4, 7], "[1,0,1,2,2,0], distance 0.0, same set class"),
                     ("Cm9 without its root", [3, 7, 10, 2], "distance 0.6"),
                     ("Fmaj7", [5, 9, 0, 4], "distance 0.0, same set class"),
                 })
        {
            var set = Set(pcs);
            Row(w, name, Notes(pcs), set.IntervalClassVector, Forte(set), L1(cmaj7.IntervalClassVector, set.IntervalClassVector), draft);
        }
    }
}
