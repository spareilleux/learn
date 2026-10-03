namespace GaAi;

using System.Globalization;
using System.Reflection;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Intents;
using GA.Business.ML.Agents.Skills;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Services.Atonal.Grothendieck;
using Microsoft.Extensions.Logging.Abstractions;
using static IcvNeighborsProbe;
using static Report;

// Lesson 23: GrothendieckDeltaSkill and IcvShortestPathSkill, asked directly. Both read two chords
// out of a question: the first gives the difference of their interval-class vectors, the second a
// chain of pitch-class sets from one to the other, from GrothendieckService.FindShortestPath
public static class IcvDeltaPathProbe
{
    public static (GrothendieckDeltaSkill Delta, IcvShortestPathSkill Path) Skills()
    {
        // The delta skill formats its norms and costs with the current culture; the course prints
        // them as GA's tests read them
        CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
        return (new(new GrothendieckService(), NullLogger<GrothendieckDeltaSkill>.Instance),
                new(new GrothendieckService(), NullLogger<IcvShortestPathSkill>.Instance));
    }

    // ---- Reading the skills' answers ----

    sealed record Answer(string Kind, string? A, string? B, List<string> Lines, string Text)
    {
        public string Says => Kind switch
        {
            "answer" => $"{A} → {B}",
            "unparsed" => "can't parse",
            _ => "declined",
        };

        // The value after a line's label, as "- **L1 norm** (Manhattan): **2**" gives "2"
        public string Value(string label) =>
            Lines.First(l => l.StartsWith(label)).Split("**").Where(p => p.Trim().Length > 0).Last().Trim('`', ' ', ':');
    }

    // A question that finds no path costs the path skill a search of every set it can reach, so each
    // question is asked once per skill and its answer kept
    static readonly Dictionary<(IOrchestratorSkill, string), Answer> Asked = [];

    static Answer Ask(IOrchestratorSkill skill, string prompt)
    {
        if (Asked.TryGetValue((skill, prompt), out var known)) return known;
        return Asked[(skill, prompt)] = Read(skill.ExecuteAsync(prompt).GetAwaiter().GetResult().Result);
    }

    static Answer Read(string text)
    {
        var lines = text.Split('\n').Select(l => l.TrimEnd('\r')).ToList();
        if (text.StartsWith("I couldn't parse")) return new("unparsed", null, null, lines, text);
        if (!text.StartsWith("**Grothendieck delta ") && !text.StartsWith("**Shortest harmonic path "))
            return new("declined", null, null, lines, text);
        var head = text[2..text.IndexOf("**", 2)];
        var pair = head[(head.StartsWith("Grothendieck") ? "Grothendieck delta ".Length : "Shortest harmonic path ".Length)..].Split(" → ");
        return new("answer", pair[0], pair[1], lines, text);
    }

    static string Pcs(PitchClassSet set) => "{" + string.Join(",", set.Select(p => p.Value)) + "}";

    // ---- The example prompts ----

    // The phrasings GA gives each skill besides its routing anchors (ExamplePrompts): the surface
    // forms of its doc comment and the two its refusal suggests
    static readonly (string Prompt, string Skill, string From)[] Others =
    [
        ("Harmonic distance from Cmaj7 to G7", "delta", "doc comment"),
        ("Grothendieck delta C to F", "delta", "doc comment"),
        ("How harmonically far is Am from D7", "delta", "doc comment"),
        ("Compare the ICVs of Cmaj7 and Dm7", "delta", "doc comment"),
        ("harmonic distance from Cmaj7 to G7", "delta", "refusal"),
        ("delta C to F", "delta", "refusal"),
        ("Shortest harmonic path from Cmaj7 to G7", "path", "doc comment"),
        ("Path from C major to F major", "path", "doc comment"),
        ("How do I get from Am to D7 harmonically", "path", "doc comment"),
        ("shortest path from Cmaj7 to G7", "path", "refusal"),
        ("how do I get from C to F harmonically", "path", "refusal"),
    ];

    public static void ExamplesTable(GrothendieckDeltaSkill delta, IcvShortestPathSkill path, string where)
    {
        Title($"GrothendieckDeltaSkill's and IcvShortestPathSkill's example prompts and GA's other phrasings for them, {where}");
        var hints = new DefaultRoutingHintProvider();
        int[] w = [48, 7, 13, 16, 16];
        Row(w, "prompt", "skill", "from", "its answer", "the other's", "routing hints, +0.06 each");
        var prompts = delta.ExamplePrompts.Select(p => (Prompt: p, Skill: "delta", From: "anchor"))
            .Concat(path.ExamplePrompts.Select(p => (Prompt: p, Skill: "path", From: "anchor")))
            .Concat(Others).ToList();
        foreach (var (prompt, skill, from) in prompts)
        {
            var (own, other) = skill == "delta" ? ((IOrchestratorSkill)delta, (IOrchestratorSkill)path) : ((IOrchestratorSkill)path, (IOrchestratorSkill)delta);
            var hint = hints.GetDeltas(prompt).Keys.Order(StringComparer.Ordinal).ToList();
            Row(w, prompt, skill, from, Ask(own, prompt).Says, Ask(other, prompt).Says, hint.Count == 0 ? "none" : string.Join(", ", hint));
        }
        foreach (var (name, own, other, intent) in new (string, IOrchestratorSkill, IOrchestratorSkill, string)[]
                 {
                     ("GrothendieckDeltaSkill", delta, path, "skill.grothendieckdelta"),
                     ("IcvShortestPathSkill", path, delta, "skill.icvshortestpath"),
                 })
        {
            var anchors = own.ExamplePrompts;
            Line($"{name}: anchors {anchors.Count}, answered {anchors.Count(p => Ask(own, p).Kind == "answer")}, " +
                 $"hinted toward {intent} {anchors.Count(p => hints.GetDeltas(p).ContainsKey(intent))}; " +
                 $"the other skill answers {anchors.Count(p => Ask(other, p).Kind == "answer")} of them; " +
                 $"CanHandle accepts {anchors.Count(own.CanHandle)}");
        }
    }

    // ---- The chords they read ----

    static MethodInfo Private(Type skill, string name) => skill.GetMethod(name, BindingFlags.NonPublic | BindingFlags.Static)!;

    // The set a skill builds for a chord token (its private TryBuildPcSet)
    static PitchClassSet? Built(Type skill, string token) => (PitchClassSet?)Private(skill, "TryBuildPcSet").Invoke(null, [token]);

    // Each pair, in a question for one skill, with the notes a textbook gives its two chords
    static readonly (string Prompt, int[] A, int[] B)[] Pairs =
    [
        ("harmonic distance from C major to F major", [0, 4, 7], [5, 9, 0]),
        ("harmonic distance from C to A minor", [0, 4, 7], [9, 0, 4]),
        ("harmonic distance from Cmaj7 to a G7", [0, 4, 7, 11], [7, 11, 2, 5]),
        ("harmonic distance between CM7 and G7", [0, 4, 7, 11], [7, 11, 2, 5]),
        ("harmonic distance from C° to C+", [0, 3, 6], [0, 4, 8]),
        ("shortest path from C major to F major", [0, 4, 7], [5, 9, 0]),
        ("shortest route from C to A minor", [0, 4, 7], [9, 0, 4]),
        ("shortest path from C to a G", [0, 4, 7], [7, 11, 2]),
        ("shortest path from CM7 to G7", [0, 4, 7, 11], [7, 11, 2, 5]),
    ];

    public static void ReadingTable(GrothendieckDeltaSkill delta, IcvShortestPathSkill path, string where)
    {
        Title($"The chords the two skills read, {where}");
        // The three skills' quality tables, compared on lesson 22's chords and on the 16 qualities
        var tokens = Chords.Select(c => c.Token).Concat(Qualities.Select(q => "C" + q)).Distinct().ToList();
        string Of(Type t, string token) => Built(t, token) is { } s ? Pcs(s) : "-";
        var same = tokens.Count(t => Of(typeof(IcvNeighborsSkill), t) == Of(typeof(GrothendieckDeltaSkill), t)
                                  && Of(typeof(IcvNeighborsSkill), t) == Of(typeof(IcvShortestPathSkill), t));
        Line($"chord tokens {tokens.Count}: built alike by IcvNeighborsSkill, GrothendieckDeltaSkill and IcvShortestPathSkill {same}");
        int[] w = [42, 7, 12, 14, 14];
        Row(w, "prompt", "skill", "read as", "first built", "second built", "right");
        foreach (var (prompt, a, b) in Pairs)
        {
            var isPath = prompt.StartsWith("shortest");
            IOrchestratorSkill skill = isPath ? path : delta;
            var type = isPath ? typeof(IcvShortestPathSkill) : typeof(GrothendieckDeltaSkill);
            var ans = Ask(skill, prompt);
            var setA = ans.A is null ? null : Built(type, ans.A);
            var setB = ans.B is null ? null : Built(type, ans.B);
            bool Same(PitchClassSet? s, int[] pcs) => s is not null && s.Select(p => p.Value).Order().SequenceEqual(pcs.Order());
            Row(w, prompt, isPath ? "path" : "delta", ans.Says,
                setA is null ? "-" : Notes(setA.Select(p => p.Value)), setB is null ? "-" : Notes(setB.Select(p => p.Value)),
                Same(setA, a) && Same(setB, b) ? "yes" : "no");
        }
    }

    // ---- The deltas ----

    public static void DeltaTable(GrothendieckDeltaSkill delta, string where)
    {
        Title($"The deltas GrothendieckDeltaSkill gives, {where}");
        // The pairs of its anchors it answers, both ways, and two chords asked against themselves
        var pairs = delta.ExamplePrompts.Select(p => Ask(delta, p)).Where(a => a.Kind == "answer")
            .SelectMany(a => new[] { (a.A!, a.B!), (a.B!, a.A!) })
            .Append(("C", "C")).Append(("Cmaj7", "Cmaj7")).ToList();
        int[] w = [16, 15, 15, 6, 22, 4, 7, 6];
        Row(w, "pair", "first vector", "second vector", "L1", "the skill's delta", "L1", "L2", "cost", "its interpretation");
        foreach (var (a, b) in pairs)
        {
            var ans = Ask(delta, $"harmonic distance from {a} to {b}");
            var va = Built(typeof(GrothendieckDeltaSkill), a)!.IntervalClassVector;
            var vb = Built(typeof(GrothendieckDeltaSkill), b)!.IntervalClassVector;
            Row(w, $"{a} → {b}", va, vb, L1(va, vb), ans.Value("- **Δ (signed)**"), ans.Value("- **L1 norm**"),
                ans.Value("- **L2 norm**"), ans.Value("- **Harmonic cost**"), ans.Value("**Interpretation**"));
        }

        // Every ordered pair of the 192 chords of 12 roots and 16 qualities
        var chords = Qualities.SelectMany(q => Names.Select(n => n + q)).ToList();
        var vectors = chords.ToDictionary(c => c, c => Built(typeof(GrothendieckDeltaSkill), c)!.IntervalClassVector);
        int samePairs = 0, sameOne = 0, samePlusIc1 = 0, otherPairs = 0, otherRight = 0;
        var chromatic = new Dictionary<(string, string), bool>();
        foreach (var a in chords)
        foreach (var b in chords)
        {
            var ans = Read(delta.ExecuteAsync($"harmonic distance from {a} to {b}").GetAwaiter().GetResult().Result);
            var l1 = int.Parse(ans.Value("- **L1 norm**"));
            var real = L1(vectors[a], vectors[b]);
            if (real == 0)
            {
                samePairs++;
                sameOne += l1 == 1 ? 1 : 0;
                samePlusIc1 += ans.Value("- **Δ (signed)**") == "[+1, 0, 0, 0, 0, 0]" ? 1 : 0;
            }
            else
            {
                otherPairs++;
                otherRight += l1 == real ? 1 : 0;
                chromatic[(a, b)] = ans.Value("**Interpretation**").EndsWith("more chromatic color");
            }
        }
        var unordered = chromatic.Keys.Where(k => string.CompareOrdinal(k.Item1, k.Item2) < 0).ToList();
        Line($"ordered pairs {chords.Count * chords.Count}: with the same vector {samePairs}, answered L1 1 {sameOne}, " +
             $"delta [+1, 0, 0, 0, 0, 0] {samePlusIc1}; with different vectors {otherPairs}, L1 right {otherRight}");
        Line($"pairs with different vectors {unordered.Count}: \"more chromatic color\" both ways " +
             $"{unordered.Count(k => chromatic[k] && chromatic[(k.Item2, k.Item1)])}");
    }

    // ---- The paths ----

    static List<PitchClassSet> PathOf(Answer ans) =>
        ans.Lines.Where(l => l.StartsWith("| ") && l.Contains("`{"))
            .Select(l => Set(l.Split('`')[1].Trim('{', '}').Split(',').Select(int.Parse))).ToList();

    // The sets the search expands before it answers "No path": every set of the source's size within
    // four moves of it, a move joining two sets of one size whose vectors are at most 2 apart, as
    // FindShortestPath's BFS with FindNearby(current, 2) and maxSteps 5 does
    static int Expanded(PitchClassSet source)
    {
        var sets = PitchClassSet.Items.Where(s => s.Count == source.Count).ToList();
        var vector = sets.ToDictionary(s => s, s => s.IntervalClassVector);
        var depth = new Dictionary<PitchClassSet, int> { [source] = 0 };
        var queue = new Queue<PitchClassSet>([source]);
        while (queue.Count > 0)
        {
            var s = queue.Dequeue();
            if (depth[s] == 4) continue;
            foreach (var next in sets.Where(n => !depth.ContainsKey(n) && L1(vector[s], vector[n]) <= 2))
            {
                depth[next] = depth[s] + 1;
                queue.Enqueue(next);
            }
        }
        return depth.Count;
    }

    public static void PathTable(IcvShortestPathSkill path, string where)
    {
        Title($"The paths IcvShortestPathSkill finds, {where}");
        // The anchors it answers, and a few more pairs
        var prompts = path.ExamplePrompts.Where(p => Ask(path, p).Kind == "answer")
            .Concat(new[] { ("C", "C"), ("C", "Cm"), ("Cdim7", "Cmaj7"), ("Caug", "C") }.Select(p => $"shortest path from {p.Item1} to {p.Item2}"))
            .ToList();
        int[] w = [16, 7, 38, 6, 12, 14];
        Row(w, "pair", "notes", "the answer says", "moves", "L1 per move", "common notes", "same vector");
        var none = new List<(string Pair, PitchClassSet Source)>();
        foreach (var prompt in prompts)
        {
            var ans = Ask(path, prompt);
            var (a, b) = (ans.A!, ans.B!);
            var sets = PathOf(ans);
            var says = ans.Lines.FirstOrDefault(l => l.StartsWith("- **") && l.Contains("total")) is { } t
                ? t.Replace("- **", "").Replace("**", "").TrimEnd('.')
                : ans.Lines.First(l => l.StartsWith("No path")).Split('.')[0];
            var moves = sets.Zip(sets.Skip(1)).ToList();
            var sizes = $"{Built(typeof(IcvShortestPathSkill), a)!.Count}, {Built(typeof(IcvShortestPathSkill), b)!.Count}";
            Row(w, $"{a} → {b}", sizes, says, moves.Count,
                moves.Count == 0 ? "-" : string.Join(",", moves.Select(m => L1(m.First.IntervalClassVector, m.Second.IntervalClassVector))),
                moves.Count == 0 ? "-" : string.Join(",", moves.Select(m => m.First.Select(p => p.Value).Intersect(m.Second.Select(p => p.Value)).Count())),
                moves.Count(m => L1(m.First.IntervalClassVector, m.Second.IntervalClassVector) == 0));
            if (sets.Count == 0) none.Add(($"{a} → {b}", Built(typeof(IcvShortestPathSkill), a)!));
        }
        foreach (var (pair, source) in none)
            Line($"before \"No path\" for {pair}: sets expanded {Expanded(source)} of the {PitchClassSet.Items.Count(s => s.Count == source.Count)} of {source.Count} notes, each a scan of the {PitchClassSet.Items.Count} sets");

        var first = Ask(path, path.ExamplePrompts[0]);
        Line($"the path for \"{path.ExamplePrompts[0]}\":");
        PitchClassSet? prev = null;
        foreach (var s in PathOf(first))
        {
            var pcs = s.Select(p => p.Value).ToList();
            Line($"  {Pcs(s),-12} {Notes(pcs),-14} {Forte(s),-6} {s.IntervalClassVector}" +
                 (prev is null ? "" : $"  L1 {L1(prev.IntervalClassVector, s.IntervalClassVector)}, common notes {prev.Select(p => p.Value).Intersect(pcs).Count()}"));
            prev = s;
        }
    }
}
