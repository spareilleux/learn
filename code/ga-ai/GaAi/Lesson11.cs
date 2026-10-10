extern alias keysmain;

namespace GaAi;

using System.Reflection;
using GA.Business.ML.Agents.Mcp;
using GA.Business.ML.Agents.Skills;
using static Report;
using static Lesson9;
using Main = keysmain::GA.Domain.Services.Tonal.KeyIdentificationService;
using Pinned = GA.Business.ML.Agents.KeyIdentificationService;

// Lesson 11: the key skill. Both chatbot surfaces for "what key is ...", KeyIdentificationSkill
// and the key-identification SKILL.md through the ga_key_identify tool, read the chord symbols
// out of the question with one regular expression, score the 30 keys with KeyIdentificationService
// and hand the model the keys tied at the top, then three more. The program asks for the key of
// textbook progressions in every key, with the pinned service and with the one of GA's main.
public static class Lesson11
{
    record Candidate(string Key, string RelativeKey, int MatchCount, int TotalChords);

    record Version(string Name, Type Service, Func<string, IReadOnlyList<string>> Extract,
        Func<IEnumerable<string>, IReadOnlyList<Candidate>> Identify);

    static readonly Version Pin = new("a826864", typeof(Pinned), Pinned.ExtractChords,
        chords => [.. Pinned.Identify(chords).Select(c => new Candidate(c.Key, c.RelativeKey, c.MatchCount, c.TotalChords))]);

    static readonly Version OnMain = new("6baf32e", typeof(Main), Main.ExtractChords,
        chords => [.. Main.Identify(chords).Select(c => new Candidate(c.Key, c.RelativeKey, c.MatchCount, c.TotalChords))]);

    static readonly Version[] Versions = [Pin, OnMain];

    public static void Run()
    {
        Examples();
        Reading();
        Textbook();
        Relatives();
        Prompt();

        Title("The pinned answers, checked against ga_key_identify");
        Line($"{toolChecks} questions: KeyIdentificationMcpTools.IdentifyKey read the same chords and returned the same keys");
    }

    // ---- What the model is given ----

    record Answer(IReadOnlyList<string> Chords, Candidate[] Top, Candidate[] Partial);

    static int toolChecks;

    // KeyIdentificationMcpTools.IdentifyKey keeps the keys whose count equals the first key's, then
    // the next three; KeyIdentificationSkill builds its prompt the same way. Neither changed on main.
    static Answer Select(IReadOnlyList<string> chords, IReadOnlyList<Candidate> candidates)
    {
        if (candidates.Count == 0) return new(chords, [], []);
        var topScore = candidates[0].MatchCount;
        var top = candidates.Where(c => c.MatchCount == topScore).ToArray();
        return new(chords, top, [.. candidates.Skip(top.Length).Take(3)]);
    }

    static Answer Ask(Version v, string query)
    {
        var chords = v.Extract(query);
        var answer = Select(chords, v.Identify(chords));

        // For the pinned service, the tool itself must give the same answer
        if (v == Pin)
        {
            var tool = KeyIdentificationMcpTools.IdentifyKey(query);
            var same = tool.Error is null
                ? tool.RecognizedChords.SequenceEqual(chords)
                  && tool.TopCandidates.Select(c => c.Key).SequenceEqual(answer.Top.Select(c => c.Key))
                  && tool.PartialMatches.Select(c => c.Key).SequenceEqual(answer.Partial.Select(c => c.Key))
                : answer.Top.Length == 0;
            if (!same) throw new InvalidOperationException($"ga_key_identify disagrees on '{query}'");
            toolChecks++;
        }

        return answer;
    }

    static string Top(Answer a) =>
        a.Top.Length == 0 ? "no key" : $"{a.Top[0].MatchCount}/{a.Top[0].TotalChords}: {string.Join(", ", a.Top.Select(c => c.Key))}";

    static string Partial(Answer a) =>
        a.Partial.Length == 0 ? "" : "; then " + string.Join(", ", a.Partial.Select(c => $"{c.Key} {c.MatchCount}/{c.TotalChords}"));

    // ---- The skill's example prompts ----

    static readonly string[] ExamplePrompts =
    [
        // KeyIdentificationSkill.ExamplePrompts, lines 26-37
        "What key is C Am F G in?",
        "Identify the key of Dm G C",
        "What key does Am F G E sound like?",
        "Tell me the key of these chords: G D Em C",
        "Find the tonic of A E F#m D",
        "What's the tonic of these chords: C F G C",
        "Identify the tonic of this progression: D A Bm G",
        // The progressions of the SKILL.md's two examples, lines 60 and 66
        "Dm G C",
        "C Am F G",
    ];

    static void Examples()
    {
        Title("The key skill's example prompts: the chords read, and the keys tied at the top");
        foreach (var prompt in ExamplePrompts)
        {
            Line($"\"{prompt}\"");
            foreach (var v in Versions)
            {
                var a = Ask(v, prompt);
                Row([10, 20], $"  {v.Name}", $"reads {string.Join(" ", a.Chords)}", Top(a));
            }
        }
    }

    // ---- Reading the chords ----

    static readonly string[] Symbols =
    [
        "C", "Cm", "Cdim", "Caug", "C+", "C°", "Cmin", "C#", "C#m", "Db", "F#", "F#7", "B♭", "F♯",
        "C7", "Cm7", "Cmaj7", "CM7", "CΔ7", "Cm7b5", "Cø7", "Cdim7", "C6", "C9", "Csus4", "Cadd9", "C7#9", "C/E",
    ];

    static void Reading()
    {
        Title("What each version reads in \"What key is X in?\", and what each chord counts as");
        Row([8, 14, 14, 14], "X", $"{Pin.Name} reads", "counts as", $"{OnMain.Name} reads", "counts as");
        foreach (var symbol in Symbols)
        {
            var cells = new List<object> { symbol };
            foreach (var v in Versions)
            {
                var read = v.Extract($"What key is {symbol} in?");
                cells.Add(read.Count == 0 ? "nothing" : string.Join(" ", read));
                cells.Add(read.Count == 0 ? "-" : string.Join(" ", read.Select(r => CountsAs(v.Service, r))));
            }
            Row([8, 14, 14, 14], [.. cells]);
        }
    }

    // The service's parser is private: the program calls it by reflection. It returns the root's
    // pitch class and a quality, Major, Minor or Diminished, and on main also Dominant
    static string CountsAs(Type service, string chord)
    {
        var parse = service.GetMethod("ParseChordRootAndQuality", BindingFlags.NonPublic | BindingFlags.Static)!;
        var result = parse.Invoke(null, [chord]);
        return result is null ? "-" : result.GetType().GetField("Item2")!.GetValue(result)!.ToString()!.ToLowerInvariant();
    }

    // ---- Textbook progressions in the 30 keys ----

    static readonly (string Name, bool Minor, (int Degree, string Suffix)[] Chords)[] Progressions =
    [
        ("I IV V I", false, [(0, ""), (3, ""), (4, ""), (0, "")]),
        // II is a major triad, the dominant of the dominant
        ("I II V I", false, [(0, ""), (1, ""), (4, ""), (0, "")]),
        ("ii7 V7 Imaj7", false, [(1, "m7"), (4, "7"), (0, "maj7")]),
        // V is a major triad, from the harmonic minor
        ("i iv V i", true, [(0, "m"), (3, "m"), (4, ""), (0, "m")]),
        ("iiø7 V7 i", true, [(1, "m7b5"), (4, "7"), (0, "m")]),
        ("i VI III VII", true, [(0, "m"), (5, ""), (2, ""), (6, "")]),
    ];

    // The questions printed in full after the grid
    static readonly (string Progression, string Key)[] Shown =
    [
        ("I IV V I", "Db major"),
        ("I II V I", "C major"),
        ("ii7 V7 Imaj7", "E major"),
        ("i iv V i", "F# minor"),
        ("iiø7 V7 i", "B minor"),
    ];

    static void Textbook()
    {
        Title("\"What key is ... in?\" for six textbook progressions in the 30 keys");
        var tally = Versions.ToDictionary(v => v, _ => new Dictionary<string, int>());
        var above = Versions.ToDictionary(v => v, _ => 0);
        var shown = new List<string>();
        foreach (var minor in new[] { false, true })
        {
            var tonics = minor ? MinorKeys : MajorKeys;
            Line();
            Row([22], minor ? "minor keys" : "major keys", string.Join(" ", tonics.Select(t => t.PadRight(2))));
            foreach (var (name, _, degrees) in Progressions.Where(p => p.Minor == minor))
                foreach (var v in Versions)
                {
                    var marks = tonics.Select(tonic =>
                    {
                        var scale = Scale(tonic, minor);
                        string[] chords = [.. degrees.Select(d => scale[d.Degree] + d.Suffix)];
                        var key = $"{tonic} {(minor ? "minor" : "major")}";
                        var query = $"What key is {string.Join(" ", chords)} in?";
                        var a = Ask(v, query);
                        var mark = !a.Chords.SequenceEqual(chords.Distinct()) ? "r"
                            : a.Top.Length > 0 && a.Top[0].Key == key ? "="
                            : a.Top.Any(c => c.Key == key) ? "~"
                            : "x";
                        tally[v][mark] = tally[v].GetValueOrDefault(mark) + 1;
                        if (a.Top.Length > 0 && a.Partial.Any(p => p.MatchCount > a.Top[0].MatchCount))
                            above[v]++;
                        if (Shown.Contains((name, key)))
                        {
                            if (v == Pin) shown.Add($"{key}, {name}: \"{query}\"");
                            shown.Add($"  {v.Name.PadRight(8)} reads {string.Join(" ", a.Chords)}; top {Top(a)}{Partial(a)}");
                            // ExtractChords drops a repeated chord, so main's cadence weight never sees
                            // the return to I; the list as written shows what it would do
                            if (v == OnMain && chords.Length != chords.Distinct().Count())
                            {
                                var given = Select(chords, v.Identify(chords));
                                shown.Add($"  {"",-8} given {string.Join(" ", chords)} as a list, Identify puts {v.Identify(chords)[0].Key} first; " +
                                          $"top {Top(given)}{Partial(given)}");
                            }
                        }
                        return mark;
                    });
                    Row([13, 8], name, v.Name, string.Join(" ", marks.Select(m => m.PadRight(2))));
                }
        }

        Line();
        Line("= every chord read as written, the textbook key first; ~ read, the key tied at the top but not first;");
        Line("x read, the key not among the top; r a chord dropped or read as another chord");
        foreach (var v in Versions)
            Line($"{v.Name}: 90 questions, = {tally[v].GetValueOrDefault("=")}, ~ {tally[v].GetValueOrDefault("~")}, " +
                 $"x {tally[v].GetValueOrDefault("x")}, r {tally[v].GetValueOrDefault("r")}; " +
                 $"a key after the top with a higher count: {above[v]}");
        Line();
        foreach (var line in shown) Line(line);
    }

    // ---- The relative key the model is shown ----

    static void Relatives()
    {
        Title("The relative key each candidate carries, against the textbook");
        foreach (var v in Versions)
        {
            // A major triad on each of the 21 names: each of the 30 keys holds three
            var all = v.Identify(Names);
            var wrong = all.Where(c =>
            {
                var tonic = c.Key.Split(' ')[0];
                var textbook = c.Key.EndsWith("minor") ? $"{Scale(tonic, true)[2]} major" : $"{Scale(tonic, false)[5]} minor";
                return c.RelativeKey != textbook;
            }).OrderBy(c => c.Key, StringComparer.Ordinal).ToList();
            Line($"{v.Name}: {all.Count} keys, {wrong.Count} with another relative key: " +
                 string.Join("; ", wrong.Select(c => $"{c.Key} → {c.RelativeKey}")));
        }
    }

    // ---- The prompt ----

    static void Prompt()
    {
        const string question = "What key is Db Gb Ab Db in?";
        Title($"The data KeyIdentificationSkill puts in the model's prompt for \"{question}\", at {Pin.Name}");
        var chords = Pinned.ExtractChords(question);
        var all = Pinned.Identify(chords);
        var top = all.Where(c => c.MatchCount == all[0].MatchCount).ToList();
        // BuildPrompt is private: the program calls it by reflection, with what ExecuteAsync passes it
        var build = typeof(KeyIdentificationSkill).GetMethod("BuildPrompt", BindingFlags.NonPublic | BindingFlags.Static)!;
        var prompt = ((string)build.Invoke(null, [question, chords, top, all])!).ReplaceLineEndings("\n");
        var data = prompt[prompt.IndexOf("── TOP MATCHES", StringComparison.Ordinal)..prompt.IndexOf("Instructions:", StringComparison.Ordinal)];
        foreach (var line in data.TrimEnd().Split('\n')) Line(line.TrimEnd());
    }
}
