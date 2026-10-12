namespace GaAi;

using System.Reflection;
using System.Text.RegularExpressions;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Skills;
using Microsoft.Extensions.Logging.Abstractions;
using static Report;

// Lesson 28: comparisons. TheoryComparisonSkill answers "what is the difference between major and
// minor" with one fixed text, when one of four regexes finds the pair major/minor in the question;
// its CanHandle is always false, so only the embedding router reaches it. The skill only marks its
// refusal Declined on GA's main. The program asks it the course's phrasings, checks its text against
// a textbook's scales, asks the question its same-pair answer suggests, and asks RelativeKeySkill the
// parallel-key comparison the skill leaves to it; GaMain asks main's chatbot host.
public static class Lesson28
{
    // The skill's regexes, in the order MatchPair tries them
    static readonly string[] PatternNames = ["DifferencePattern", "ComparePattern", "VsPattern", "HowDifferPattern"];

    static Regex Pattern(string name) =>
        (Regex)typeof(TheoryComparisonSkill).GetField(name, BindingFlags.NonPublic | BindingFlags.Static)!.GetValue(null)!;

    static AgentResponse Ask(IOrchestratorSkill skill, string prompt) => skill.ExecuteAsync(prompt).GetAwaiter().GetResult();

    // "answer", "same pair" or "refused", from the skill's last evidence line
    static string Outcome(AgentResponse response) => response.Evidence.Last() switch
    {
        var e when e.Contains("matched pair", StringComparison.Ordinal) => "answer",
        var e when e.Contains("same-token pair", StringComparison.Ordinal) => "same pair",
        _ => "refused",
    };

    static string Text(AgentResponse response) => response.Result.ReplaceLineEndings("\n");

    public static void Run()
    {
        var skill = new TheoryComparisonSkill(NullLogger<TheoryComparisonSkill>.Instance);
        Phrasings(skill);
        Answer(skill);
        SamePair(skill);
        Parallel();
    }

    // ---- The phrasings the skill answers ----

    static void Phrasings(TheoryComparisonSkill skill)
    {
        var phrasings = ComparisonProbe.Phrasings(skill.ExamplePrompts);
        Title("TheoryComparisonSkill: the regex that finds the pair in each phrasing, and the answer");
        int[] w = [8, 58, 18];
        Row(w, "source", "phrasing", "regex", "answer");
        var outcomes = new List<(string Source, string Outcome)>();
        foreach (var (source, prompt) in phrasings)
        {
            var regex = PatternNames.FirstOrDefault(n => Pattern(n).IsMatch(prompt)) ?? "none";
            var outcome = Outcome(Ask(skill, prompt));
            outcomes.Add((source, outcome));
            Row(w, source, prompt, regex, outcome);
        }

        string Count(string source, string outcome) => $"{outcomes.Count(o => o.Source == source && o.Outcome == outcome)}";
        Line($"example prompts {skill.ExamplePrompts.Count}: answer {Count("example", "answer")}; " +
             $"the course's {ComparisonProbe.Course.Length}: answer {Count("course", "answer")}, same pair {Count("course", "same pair")}, " +
             $"refused {Count("course", "refused")}; CanHandle accepts {phrasings.Count(x => skill.CanHandle(x.Prompt))}");
    }

    // ---- The answer against a textbook ----

    // Semitones from the root of each degree, 1 to 7
    static readonly (string Name, int[] Offsets)[] Textbook =
    [
        ("major", [0, 2, 4, 5, 7, 9, 11]),
        ("natural minor", [0, 2, 3, 5, 7, 8, 10]),
        ("harmonic minor", [0, 2, 3, 5, 7, 8, 11]),
        ("melodic minor", [0, 2, 3, 5, 7, 9, 11]),
    ];

    static readonly int[] MajorOffsets = Textbook[0].Offsets;

    // "1 2 b3 4 5 b6 b7": each degree's number, with b or # for its distance from the major scale's
    static string Degrees(int[] offsets) =>
        string.Join(" ", offsets.Select((o, k) => (o - MajorOffsets[k]) switch { -1 => "b", 1 => "#", _ => "" } + (k + 1)));

    static int[] FromSteps(string steps)
    {
        var offsets = new List<int> { 0 };
        foreach (var s in steps.Split(' ', StringSplitOptions.RemoveEmptyEntries).Select(int.Parse).SkipLast(1))
            offsets.Add(offsets[^1] + s);
        return [.. offsets];
    }

    static string Differing(int[] offsets) =>
        string.Join(" ", offsets.Select((o, k) => (o, k)).Where(x => x.o != MajorOffsets[x.k]).Select(x => $"{x.k + 1}"));

    static void Answer(TheoryComparisonSkill skill)
    {
        const string prompt = "What is the difference between major and minor";
        var text = Text(Ask(skill, prompt));
        Title($"TheoryComparisonSkill's answer to \"{prompt}\"");
        foreach (var line in text.Split('\n')) Line($"  | {line}");

        // "- Major:   2 2 1 2 2 2 1 — degrees `1 2 3 4 5 6 7`" and "- Natural minor: `1 2 b3 4 5 b6 b7`"
        var withSteps = Regex.Matches(text, @"^- (?<name>Major|Minor):\s+(?<steps>[\d ]+?) — degrees `(?<deg>[^`]+)`", RegexOptions.Multiline);
        var variants = Regex.Matches(text, @"^- (?<name>Natural minor|Harmonic minor|Melodic minor): `(?<deg>[^`]+)`", RegexOptions.Multiline);
        Title("The scales in the answer, against a textbook: the degrees it writes, the degrees its steps give, and a textbook's");
        int[] w = [16, 18, 18, 18, 9];
        Row(w, "scale", "the answer writes", "its steps give", "a textbook", "the same", "degrees not major's");
        void Check(string label, string textbookName, string written, string? steps)
        {
            var offsets = Textbook.Single(t => t.Name == textbookName).Offsets;
            var fromSteps = steps is null ? "-" : Degrees(FromSteps(steps));
            var same = written == Degrees(offsets) && (steps is null || fromSteps == written) ? "yes" : "no";
            Row(w, label, written, fromSteps, Degrees(offsets), same, Differing(offsets) is "" ? "none" : Differing(offsets));
        }

        foreach (Match m in withSteps)
            Check(m.Groups["name"].Value, m.Groups["name"].Value == "Major" ? "major" : "natural minor", m.Groups["deg"].Value, m.Groups["steps"].Value);
        foreach (Match m in variants)
            Check(m.Groups["name"].Value, m.Groups["name"].Value.ToLowerInvariant(), m.Groups["deg"].Value, null);

        // "Relative pairs share a key signature (C major ↔ A minor, …)": the major scale and the natural
        // minor scale on the two roots
        int Pc(string letter) => "C D EF G A B".IndexOf(letter, StringComparison.Ordinal);
        var relativeLine = text.Split('\n').Single(l => l.StartsWith("- Relative pairs", StringComparison.Ordinal));
        var pairs = Regex.Matches(relativeLine, @"(?<a>[A-G]) major ↔ (?<b>[A-G]) minor");
        var pairText = pairs.Select(m =>
        {
            var major = Textbook[0].Offsets.Select(o => (o + Pc(m.Groups["a"].Value)) % 12).ToHashSet();
            var minor = Textbook[1].Offsets.Select(o => (o + Pc(m.Groups["b"].Value)) % 12).ToHashSet();
            return $"{m.Value}: the same notes {(major.SetEquals(minor) ? "yes" : "no")}";
        });
        Line($"relative pairs: {string.Join("; ", pairText)}");

        // "I IV V (major-quality) vs i iv V": the triads on degrees 1, 4 and 5
        string Triads(int[] offsets) => string.Join(", ", new[] { 0, 3, 4 }.Select(k =>
        {
            var third = (offsets[(k + 2) % 7] - offsets[k] + 12) % 12;
            var fifth = (offsets[(k + 4) % 7] - offsets[k] + 12) % 12;
            return (third, fifth) switch { (4, 7) => "major", (3, 7) => "minor", _ => $"{third}/{fifth}" };
        }));
        Line($"triads on degrees 1, 4 and 5: {string.Join("; ", Textbook.Take(3).Select(t => $"{t.Name}: {Triads(t.Offsets)}"))}");
    }

    // ---- The question the same-pair answer suggests ----

    static void SamePair(TheoryComparisonSkill skill)
    {
        Title("The same pair twice: the answer, the comparison it suggests, and the skill's answer to that");
        int[] w = [16, 20];
        Row(w, "question", "suggests", "answer to the suggestion");
        foreach (var prompt in new[] { "Major vs major", "Minor vs minor" })
        {
            var text = Text(Ask(skill, prompt));
            var suggestion = Regex.Match(text, "e\\.g\\. \"(?<s>[^\"]+)\"").Groups["s"].Value;
            Row(w, prompt, suggestion, Outcome(Ask(skill, suggestion)));
        }

        Line($"  | {Text(Ask(skill, "Major vs major"))}");
    }

    // ---- The parallel keys the skill leaves to RelativeKeySkill ----

    static void Parallel()
    {
        var relative = new RelativeKeySkill(NullLogger<RelativeKeySkill>.Instance);
        Title("RelativeKeySkill, which VsPattern's comment says handles \"C major vs C minor\": confidence and the first line of the answer");
        int[] w = [52, 12];
        Row(w, "question", "confidence", "answer");
        foreach (var prompt in new[] { "C major vs C minor", "What's the difference between C major and C minor", "Parallel minor of C major" })
        {
            var response = Ask(relative, prompt);
            Row(w, prompt, response.Confidence, Text(response).Split('\n')[0]);
        }
    }
}
