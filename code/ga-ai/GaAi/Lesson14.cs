extern alias dslmain;

namespace GaAi;

using System.Reflection;
using System.Text.RegularExpressions;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Intents;
using GA.Business.ML.Agents.Mcp;
using GA.Domain.Core.Theory.Atonal;
using GA.Domain.Services.Atonal.Grothendieck;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.FSharp.Collections;
using Microsoft.FSharp.Control;
using Microsoft.FSharp.Core;
using static Report;
using OnMain = dslmain::GA.Business.DSL.Closures.BuiltinClosures.DomainClosures;

// Lesson 14: chord substitution. ChordSubstitutionSkill answers without a model: for one chord it
// lists the nearest chords by Grothendieck ICV distance, for two chords it names their
// relationship. ga_chord_substitutions and ga_chord_compare, the MCP tools of the SKILL.md path,
// run the same code. The DSL closure domain.chordSubstitutions ranks a key's chords by common
// tones instead. The program asks the skill its own example prompts, one chord of each quality on
// the 12 roots and pairs of chords a textbook names, then calls the tools and the closure.
public static class Lesson14
{
    public static void Run()
    {
        Lesson4.EnsureIndex();
        using var host = new ChatHost();
        using var client = host.CreateClient();
        host.WaitForWarmup();
        using var scope = host.Services.CreateScope();
        var intent = scope.ServiceProvider.GetServices<IIntent>().Single(i => i.Id == "skill.chordsubstitution");
        var grothendieck = scope.ServiceProvider.GetRequiredService<IGrothendieckService>();
        var tools = new ChordSubstitutionMcpTools(grothendieck);

        Examples(intent);
        Lists(intent, tools, grothendieck);
        Pairs(intent, tools);
        Reading(intent, tools);
        // What the chatbot's startup does before ga_dsl_eval runs a closure
        GA.Business.DSL.GaClosureBootstrap.init();
        Closure();
    }

    static IOrchestratorSkill SkillOf(IIntent intent) =>
        (IOrchestratorSkill)intent.GetType().GetFields(BindingFlags.NonPublic | BindingFlags.Instance)
            .Select(f => f.GetValue(intent)).First(o => o is IOrchestratorSkill)!;

    static string Answer(IIntent intent, string prompt) =>
        intent.ExecuteAsync(prompt).GetAwaiter().GetResult().Answer.ReplaceLineEndings("\n");

    // ---- Reading the skill's two kinds of answer ----

    static readonly Regex ListHead = new(@"^Harmonic substitutions for \*\*(?<chord>[^*]+)\*\*");
    static readonly Regex ListItem = new(@"^- \*\*(?<name>[^*]+)\*\* — harmonic cost (?<cost>[\d.]+) \(Δ L1=(?<l1>\d+)\)");
    static readonly Regex PairHead = new(@"^\*\*(?<a>[^*]+)\*\* → \*\*(?<b>[^*]+)\*\* relationship analysis:");
    static readonly Regex Label = new(@"^★+ \*\*(?<type>[^*]+)\*\*");

    record Listed(string Source, string[] Names, string[] Costs);

    static Listed? AsList(string answer)
    {
        var lines = answer.Split('\n');
        var head = ListHead.Match(lines[0]);
        if (!head.Success) return null;
        var items = lines.Select(l => ListItem.Match(l)).Where(m => m.Success).ToArray();
        return new(head.Groups["chord"].Value, [.. items.Select(m => m.Groups["name"].Value)],
            [.. items.Select(m => $"cost {m.Groups["cost"].Value}, L1 {m.Groups["l1"].Value}")]);
    }

    static (string A, string B, string[] Labels)? AsPair(string answer)
    {
        var lines = answer.Split('\n');
        var head = PairHead.Match(lines[0]);
        if (!head.Success) return null;
        return (head.Groups["a"].Value, head.Groups["b"].Value,
            [.. lines.Select(l => Label.Match(l)).Where(m => m.Success).Select(m => m.Groups["type"].Value)]);
    }

    static string Describe(string answer) =>
        AsList(answer) is { } list ? $"list for {list.Source}: {string.Join(" ", list.Names)}"
        : AsPair(answer) is { } pair ? $"compares {pair.A} with {pair.B}: {string.Join(", ", pair.Labels)}"
        : answer.Split('\n')[0];

    // ---- The example prompts ----

    // The chord a textbook gives for the relation three of the prompts name
    static readonly Dictionary<string, string> Named = new()
    {
        ["Tritone substitution for G7"] = "Db7",
        ["What's the secondary dominant of Am?"] = "E7",
        ["Show me a backdoor dominant for C major"] = "Bb7",
    };

    static void Examples(IIntent intent)
    {
        Title("The skill's own example prompts");
        var skill = SkillOf(intent);
        Line($"{intent.Id}: {skill.GetType().Name}, {intent.ExamplePrompts.Count} example prompts");
        foreach (var prompt in intent.ExamplePrompts)
        {
            Line($"\"{prompt}\"  CanHandle {(skill.CanHandle(prompt) ? "yes" : "no")}");
            Line($"  {Describe(Answer(intent, prompt))}");
            if (Named.TryGetValue(prompt, out var chord)) Line($"  the textbook answer: {chord}");
        }
        Line($"CanHandle accepts {intent.ExamplePrompts.Count(skill.CanHandle)} of {intent.ExamplePrompts.Count}");
    }

    // ---- One chord ----

    // The skill's spelling of the 12 roots, ChordSubstitutionSkill.RootNames
    static readonly string[] Roots = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];

    // Each suffix with its pitch classes above the root, and the chords a textbook substitutes for it:
    // semitones from the root to the substitute's root, and the substitute's suffix
    static readonly (string Quality, string Suffix, int[] Tones, (int Up, string Suffix)[] Textbook)[] Qualities =
    [
        ("major", "", [0, 4, 7], [(9, "m"), (4, "m")]),                // vi and iii: C, Am and Em
        ("minor", "m", [0, 3, 7], [(3, ""), (8, "")]),                 // relative major and bVI: Am, C and F
        ("dominant 7th", "7", [0, 4, 7, 10], [(6, "7"), (4, "m7b5")]), // tritone sub and viiø7: G7, Db7 and Bm7b5
        ("major 7th", "maj7", [0, 4, 7, 11], [(4, "m7"), (9, "m7")]),  // iii7 and vi7: Cmaj7, Em7 and Am7
        ("minor 7th", "m7", [0, 3, 7, 10], [(3, "maj7"), (8, "maj7")]), // Dm7, Fmaj7 and Bbmaj7
        ("half-diminished", "m7b5", [0, 3, 6, 10], [(8, "7"), (3, "m7")]), // Bm7b5, G7 and Dm7
        ("diminished", "dim", [0, 3, 6], []),
        ("augmented", "aug", [0, 4, 8], []),
        ("diminished 7th", "dim7", [0, 3, 6, 9], []),
    ];

    static readonly Dictionary<string, int> Suffixes = Qualities.ToDictionary(q => q.Suffix, q => Array.IndexOf(Qualities, q));

    // The pitch classes of a chord the skill names: a root of Roots and a suffix of Qualities
    static int[] Tones(string chord)
    {
        var root = Array.FindLastIndex(Roots, r => chord.StartsWith(r, StringComparison.Ordinal) &&
            Suffixes.ContainsKey(chord[r.Length..]));
        return [.. Qualities[Suffixes[chord[Roots[root].Length..]]].Tones.Select(t => (root + t) % 12)];
    }

    static int Shared(string a, string b) => Tones(a).Intersect(Tones(b)).Count();

    static void Lists(IIntent intent, ChordSubstitutionMcpTools tools, IGrothendieckService grothendieck)
    {
        Title("One chord: \"Substitute for <chord>\" on the 12 roots");
        var costs = new SortedSet<string>(StringComparer.Ordinal);
        var (same, asked) = (0, 0);
        foreach (var (quality, suffix, tones, textbook) in Qualities)
        {
            var named = new List<string>();
            var shared = new SortedDictionary<int, int>();
            var found = 0;
            for (var root = 0; root < 12; root++)
            {
                var chord = Roots[root] + suffix;
                var list = AsList(Answer(intent, $"Substitute for {chord}"))!;
                named.AddRange(list.Names.Where(n => !named.Contains(n)));
                foreach (var name in list.Names) shared[Shared(chord, name)] = shared.GetValueOrDefault(Shared(chord, name)) + 1;
                costs.UnionWith(list.Costs);
                if (textbook.Any(t => list.Names.Contains(Roots[(root + t.Up) % 12] + t.Suffix))) found++;

                // ga_chord_substitutions, the SKILL.md path's tool, on the same chord
                var fromTool = tools.GetSubstitutions(chord).Substitutions;
                asked++;
                if (fromTool.Select(s => s.Name).SequenceEqual(list.Names) &&
                    fromTool.Select(s => $"cost {s.Cost:0.00}, L1 {s.L1Delta}").SequenceEqual(list.Costs)) same++;
            }
            Line($"{quality} (C{suffix} ... B{suffix}): the 12 lists name {named.Count} chords, {string.Join(" ", named)}");
            Line($"  {(textbook.Length == 0 ? "no textbook substitute of the same size" : $"a textbook substitute listed for {found} of 12 roots, e.g. for C{suffix}: {string.Join(", ", textbook.Select(t => Roots[t.Up] + t.Suffix))}")}");
            Line($"  notes each listed chord shares with its source: {string.Join(", ", shared.Select(kv => $"{kv.Key} for {kv.Value}"))}");
        }
        Line($"Cost and L1 of every listed chord: {string.Join("; ", costs)}");
        Line($"ga_chord_substitutions returns the same chords, costs and L1 for {same} of {asked} chords");

        // Why every cost is the same: chords of one set class share an interval-class vector
        (string A, string B)[] icvs = [("C", "Am"), ("C", "F#"), ("G7", "Db7"), ("C", "C")];
        foreach (var (a, b) in icvs)
        {
            var (va, vb) = (Icv(a), Icv(b));
            Line($"ICV {a} {Show(va)}, {b} {Show(vb)}: ComputeDelta(...).L1Norm = {grothendieck.ComputeDelta(va, vb).L1Norm}");
        }
    }

    static IntervalClassVector Icv(string chord) =>
        new PitchClassSet(Tones(chord).Select(PitchClass.FromValue)).IntervalClassVector;

    static string Show(IntervalClassVector v) =>
        "<" + string.Concat(Enumerable.Range(1, 6).Select(i => v[IntervalClass.FromValue(i)])) + ">";

    // ---- Two chords ----

    // A relation a textbook names, as two chords above a root: semitones up and suffix of each
    static readonly (string Relation, (int Up, string Suffix) A, (int Up, string Suffix) B, string Textbook)[] Relations =
    [
        ("the same chord twice", (0, ""), (0, ""), "the same chord"),
        ("V7 and I", (7, "7"), (0, ""), "V7 of I"),
        ("v and i", (7, "m"), (0, "m"), "a minor v is not a dominant"),
        ("bVII7 and I", (10, "7"), (0, ""), "backdoor dominant"),
        ("dominant 7ths a tritone apart", (6, "7"), (0, "7"), "tritone substitution"),
        ("relative minor and major", (9, "m"), (0, ""), "relative chords"),
        ("triads a tritone apart", (6, "m"), (0, ""), "no common note"),
        ("viiø7 and V7", (4, "m7b5"), (0, "7"), "viiø7 is V9 without its root"),
    ];

    static void Pairs(IIntent intent, ChordSubstitutionMcpTools tools)
    {
        Title("Two chords: \"How are <A> and <B> related?\" on the 12 roots");
        foreach (var (relation, a, b, textbook) in Relations)
        {
            var labels = new Dictionary<string, int>();
            var toolAgrees = 0;
            for (var root = 0; root < 12; root++)
            {
                var (chordA, chordB) = (Roots[(root + a.Up) % 12] + a.Suffix, Roots[(root + b.Up) % 12] + b.Suffix);
                var pair = AsPair(Answer(intent, $"How are {chordA} and {chordB} related?"))!.Value;
                var key = string.Join(", ", pair.Labels);
                labels[key] = labels.GetValueOrDefault(key) + 1;
                if (tools.CompareChords(chordA, chordB).Relationships.Select(r => r.Type).SequenceEqual(pair.Labels)) toolAgrees++;
            }
            var (exampleA, exampleB) = (Roots[a.Up] + a.Suffix, Roots[b.Up] + b.Suffix);
            Line($"{relation}, e.g. {exampleA} and {exampleB}: common notes {Shared(exampleA, exampleB)}; textbook: {textbook}");
            foreach (var (key, count) in labels) Line($"  {count} of 12 roots: {key}");
            Line($"  ga_chord_compare gives the same labels for {toolAgrees} of 12");
        }
    }

    // ---- Chords the skill reads, or does not ----

    static void Reading(IIntent intent, ChordSubstitutionMcpTools tools)
    {
        Title("What the skill reads as a chord");
        var skill = SkillOf(intent);
        foreach (var prompt in new[]
                 {
                     "A substitute for G7?",
                     "Substitute for B♭7",
                     "Substitute for Cmin7",
                     // GA's prompt corpus, prompts.yaml line 206: it asks only for 100 characters or more
                     "Suggest substitutions for G7 in a ii-V-I",
                 })
        {
            var answer = Answer(intent, prompt);
            Line($"\"{prompt}\"  CanHandle {(skill.CanHandle(prompt) ? "yes" : "no")}, {answer.Length} characters");
            Line($"  {Describe(answer)}");
        }

        var skillMd = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".ga", "skills",
            "chord-substitution", "SKILL.md"));
        Line($"SKILL.md: {File.ReadLines(skillMd).Single(l => l.Contains("min7"))}");
        Line($"ga_chord_substitutions(\"Cmin7\"): {tools.GetSubstitutions("Cmin7").Error}");
    }

    // ---- The DSL closure ----

    const string ClosureName = "domain.chordSubstitutions";

    static string Pin(Dictionary<string, string> inputs)
    {
        var r = DslEvalMcpTools.EvalClosure(ClosureName, inputs);
        return r.Error is { } e ? $"{e.Code}: {e.Message}" : (r.Result ?? r.ResultJson ?? "").ReplaceLineEndings("\n");
    }

    // Main's closure, run the way ga_dsl_eval runs a closure once its arguments pass
    static string Main(Dictionary<string, string> inputs)
    {
        var map = MapModule.OfSeq(inputs.Select(kv => Tuple.Create(kv.Key, (object)kv.Value)));
        var result = FSharpAsync.RunSynchronously(OnMain.chordSubstitutions.Exec.Invoke(map),
            FSharpOption<int>.None, FSharpOption<CancellationToken>.None);
        return result.IsOk ? result.ResultValue.ToString()!.ReplaceLineEndings("\n") : $"error: {result.ErrorValue}";
    }

    static void Show(string version, string output)
    {
        var lines = output.Split('\n');
        Line($"  {version,-8} {lines[0]}");
        foreach (var line in lines.Skip(1)) Line($"  {"",-8} {line.TrimEnd()}");
    }

    static string Args(Dictionary<string, string> inputs) => string.Join(", ", inputs.Select(kv => $"{kv.Key}={kv.Value}"));

    static void Closure()
    {
        Title("domain.chordSubstitutions, through ga_dsl_eval at a826864 and as it is on main");
        var schema = DslEvalMcpTools.GetClosureSchema(ClosureName);
        foreach (var (name, type) in schema.InputSchema!) Line($"input  {name}: {type}");

        // Every closure with an input its schema calls optional
        var optional = DslEvalMcpTools.ListClosures().Closures
            .SelectMany(c => DslEvalMcpTools.GetClosureSchema(c.Name).InputSchema!
                .Where(kv => kv.Value.Contains('?') || kv.Value.Contains("optional", StringComparison.OrdinalIgnoreCase))
                .Select(kv => $"{c.Name}.{kv.Key}"))
            .ToList();
        Line($"{optional.Count} inputs of {DslEvalMcpTools.ListClosures().Closures.Length} closures are marked optional: {string.Join(", ", optional)}");

        Dictionary<string, string>[] partial = [new() { ["symbol"] = "Am" }, new() { ["symbol"] = "Am", ["key"] = "C" }];
        foreach (var inputs in partial)
        {
            Line(Args(inputs));
            Show("a826864", Pin(inputs));
            Show("6baf32e", Main(inputs));
        }

        Dictionary<string, string>[] full =
        [
            new() { ["symbol"] = "Am", ["key"] = "C", ["scale"] = "major" },
            new() { ["symbol"] = "G7", ["key"] = "C", ["scale"] = "major" },
            new() { ["symbol"] = "F#7", ["key"] = "B", ["scale"] = "major" },
        ];
        foreach (var inputs in full)
        {
            Line(Args(inputs));
            var (pin, main) = (Pin(inputs), Main(inputs));
            Show("a826864", pin);
            if (main == pin) Line($"  {"6baf32e",-8} the same");
            else Show("6baf32e", main);
        }
    }
}
