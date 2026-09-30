extern alias keysmain;

namespace GaAi;

using System.Reflection;
using System.Text.RegularExpressions;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Intents;
using GA.Business.ML.Agents.Skills;
using Microsoft.Extensions.DependencyInjection;
using static Report;
using static Lesson9;
using Main = keysmain::GA.Domain.Services.Tonal.KeyIdentificationService;
using Pinned = GA.Business.ML.Agents.KeyIdentificationService;

// Lesson 12: the two skills that take a chord progression. ProgressionMoodSkill answers without a
// model, with one of two fixed texts; ProgressionCompletionSkill runs KeyIdentificationService
// first and tells the model which chords it may suggest. The program asks both skills their own
// example prompts, then asks for the next chord of two textbook progressions in the 30 keys.
public static class Lesson12
{
    public static void Run()
    {
        Lesson4.EnsureIndex();
        using var host = new ChatHost();
        using var client = host.CreateClient();
        host.WaitForWarmup();
        using var scope = host.Services.CreateScope();
        var intents = scope.ServiceProvider.GetServices<IIntent>().ToList();

        Title("The intents that take a chord progression");
        foreach (var intent in intents.Where(i => i.Id.Contains("progression")))
            Line($"{intent.Id,-30} {SkillOf(intent).GetType().Name,-28} {intent.ExamplePrompts.Count} example prompts");

        var mood = intents.Single(i => i.Id == "skill.progressionmood");
        var completion = intents.Single(i => i.Id == "skill.progressioncompletion");
        Mood(mood);
        MoodChords(mood);
        Keywords(mood, completion);
        Examples(completion);
        Prompt();
        Textbook();
        Minor();

        Title("The pinned prompts, checked against ProgressionCompletionSkill.BuildPrompt");
        Line($"{promptChecks} questions: the prompt names the same keys and the same chords");
    }

    static IOrchestratorSkill SkillOf(IIntent intent) =>
        (IOrchestratorSkill)intent.GetType().GetFields(BindingFlags.NonPublic | BindingFlags.Instance)
            .Select(f => f.GetValue(intent)).First(o => o is IOrchestratorSkill)!;

    // ---- ProgressionMoodSkill ----

    // ProgressionMoodSkill.ExamplePrompts, lines 26-54, and what each one asks for
    static readonly (string Prompt, string Asks)[] MoodExamples =
    [
        ("How do I make this progression sound darker?", "darken"),
        ("Make this progression sound moodier", "darken"),
        ("How can I make my chords sound sadder?", "darken"),
        ("What can I do to make a song sound more melancholy?", "darken"),
        ("How to add a darker feel to a chord progression", "darken"),
        ("Techniques to make a major progression minor-sounding", "darken"),
        ("Make my song sound brighter", "brighten"),
        ("How to make a progression more uplifting", "brighten"),
        ("Brighten up a minor key tune", "brighten"),
        ("Brighten this minor song", "brighten"),
        ("How do I lift the mood of a minor progression?", "brighten"),
        ("How does Mixolydian flavor brighten rock progressions?", "brighten"),
        ("Use Lydian color to brighten a major progression", "brighten"),
        ("Phrygian flavor to darken a progression", "darken"),
        ("What mode adds the most brightness to a major key tune?", "brighten"),
    ];

    static string Answer(IIntent intent, string prompt) =>
        intent.ExecuteAsync(prompt).GetAwaiter().GetResult().Answer.ReplaceLineEndings("\n");

    static string Branch(string answer) =>
        answer.StartsWith("Here are four reliable ways to brighten") ? "brighten"
        : answer.StartsWith("Here are five reliable ways to darken") ? "darken"
        : "other";

    static void Mood(IIntent mood)
    {
        if (!mood.ExamplePrompts.SequenceEqual(MoodExamples.Select(e => e.Prompt)))
            throw new InvalidOperationException("ProgressionMoodSkill's example prompts changed");
        Title("ProgressionMoodSkill's example prompts: what each asks for, and the answer it gets");
        Row([58, 10], "prompt", "asks", "gets");
        foreach (var (prompt, asks) in MoodExamples)
            Row([58, 10], prompt, asks, Branch(Answer(mood, prompt)));
        foreach (var asks in new[] { "darken", "brighten" })
        {
            var asked = MoodExamples.Where(e => e.Asks == asks).ToList();
            var got = asked.Count(e => Branch(Answer(mood, e.Prompt)) == asks);
            Line($"{asked.Count} prompts ask to {asks}: {got} get the {asks} answer");
        }
    }

    static readonly Regex CodeSpan = new("`([^`]+)`");
    static readonly Regex ChordSymbol = new(@"^[A-G][b#]?(m|dim)?$");
    static readonly Regex Numeral = new(@"^[b#]?(VII|VI|V|IV|III|II|I|vii|vi|v|iv|iii|ii|i)°?$");

    // The progressions a text writes between backticks, with the tokens that are neither a chord
    // symbol nor a Roman numeral
    static IEnumerable<string> Progressions(string text) =>
        CodeSpan.Matches(text).Select(m => m.Groups[1].Value)
            .Where(s => s.Split(' ').Length >= 3 && s.Split(' ').All(t => t == "→" || ChordSymbol.IsMatch(t) || Numeral.IsMatch(t) || t.Length <= 3))
            .Select(s =>
            {
                var odd = s.Split(' ').Where(t => t != "→" && !ChordSymbol.IsMatch(t) && !Numeral.IsMatch(t)).ToList();
                return odd.Count == 0 ? s : $"{s}   <- {string.Join(", ", odd)}: neither a chord symbol nor a Roman numeral";
            });

    static void MoodChords(IIntent mood)
    {
        Title("The progressions each text writes out");
        Line("ProgressionMoodSkill, darken answer:");
        foreach (var p in Progressions(Answer(mood, "How do I make this progression sound darker?"))) Line($"  {p}");
        Line("ProgressionMoodSkill, brighten answer:");
        foreach (var p in Progressions(Answer(mood, "Make my song sound brighter"))) Line($"  {p}");
        var skillMd = File.ReadAllText(Path.Combine(Environment.GetEnvironmentVariable("SKILLMD_SKILLS_PATH")!,
            "progression-mood", "SKILL.md")).ReplaceLineEndings("\n");
        Line("skills/progression-mood/SKILL.md, the progressions written with chord names:");
        foreach (var p in Progressions(skillMd).Distinct().Where(p => p.Split(' ').Any(ChordSymbol.IsMatch))) Line($"  {p}");
    }

    // ---- The keyword path ----

    static void Keywords(IIntent mood, IIntent completion)
    {
        Title("CanHandle, the keyword test main's router falls back on when it has no embeddings");
        foreach (var intent in new[] { mood, completion })
        {
            var skill = SkillOf(intent);
            var accepted = intent.ExamplePrompts.Where(skill.CanHandle).ToList();
            Line($"{skill.GetType().Name}: {accepted.Count} of {intent.ExamplePrompts.Count} example prompts accepted");
            foreach (var prompt in intent.ExamplePrompts.Except(accepted).Where(_ => accepted.Count > 0))
                Line($"  rejected: {prompt}");
        }
    }

    // ---- ProgressionCompletionSkill: what the model is told ----

    record Cand(string Key, int Count, int Total, string[] Set);

    record Version(string Name, Func<string, IReadOnlyList<string>> Extract,
        Func<IEnumerable<string>, IReadOnlyList<Cand>> Identify);

    static readonly Version Pin = new("a826864", Pinned.ExtractChords,
        chords => [.. Pinned.Identify(chords).Select(c => new Cand(c.Key, c.MatchCount, c.TotalChords, c.DiatonicSet))]);

    static readonly Version OnMain = new("6baf32e", Main.ExtractChords,
        chords => [.. Main.Identify(chords).Select(c => new Cand(c.Key, c.MatchCount, c.TotalChords, c.DiatonicSet))]);

    static readonly Version[] Versions = [Pin, OnMain];

    // What BuildPrompt writes on its "Detected key" line and under "AVAILABLE DIATONIC CHORDS"
    record Told(IReadOnlyList<string> Chords, string Keys, string Count, string[] Set, IReadOnlyList<Cand> All);

    static readonly MethodInfo BuildPrompt = typeof(ProgressionCompletionSkill)
        .GetMethod("BuildPrompt", BindingFlags.NonPublic | BindingFlags.Static)!;

    static int promptChecks;

    static string PinnedPrompt(string question)
    {
        var chords = Pinned.ExtractChords(question);
        var all = Pinned.Identify(chords);
        return ((string)BuildPrompt.Invoke(null, [question, chords, all[0], all])!).ReplaceLineEndings("\n");
    }

    // ProgressionCompletionSkill.ExecuteAsync, lines 49-67, and BuildPrompt, lines 93-107.
    // Neither changed on main.
    static Told? Tell(Version v, string question)
    {
        var chords = v.Extract(question);
        var all = v.Identify(chords);
        if (all.Count == 0) return null;
        var top = all[0];
        var tied = all.Where(c => c.Count == top.Count).ToList();
        var keys = tied.Count == 1 ? top.Key : string.Join(" / ", tied.Select(c => c.Key));
        var told = new Told(chords, keys, $"{top.Count}/{top.Total}", top.Set, all);

        // For the pinned service, the skill's own prompt must say the same
        if (v == Pin)
        {
            var lines = PinnedPrompt(question).Split('\n');
            var detected = lines.First(l => l.StartsWith("Detected key: "));
            var set = lines[Array.FindIndex(lines, l => l.StartsWith("AVAILABLE DIATONIC CHORDS")) + 1];
            if (detected != $"Detected key: {told.Keys}  ({told.Count} chords diatonic)" || set != string.Join(", ", told.Set))
                throw new InvalidOperationException($"BuildPrompt disagrees on '{question}'");
            promptChecks++;
        }

        return told;
    }

    static void Show(string question)
    {
        Line($"\"{question}\"");
        foreach (var v in Versions)
        {
            var t = Tell(v, question);
            if (t is null)
            {
                Line($"  {v.Name,-8} no chord read");
                continue;
            }
            Line($"  {v.Name,-8} reads {string.Join(" ", t.Chords)}; key: {t.Keys} ({t.Count})");
            Line($"  {"",-8} may suggest: {string.Join(", ", t.Set)}");
        }
    }

    static void Examples(IIntent completion)
    {
        Title("ProgressionCompletionSkill's example prompts: the key and the chords the model may suggest");
        foreach (var prompt in completion.ExamplePrompts) Show(prompt);
        // The progression of the progression-completion SKILL.md's example, line 86
        Show("C G Am");
    }

    static void Prompt()
    {
        const string question = "What chord comes next after C G Am?";
        Title($"What the model reads for \"{question}\", pinned");
        var lines = PinnedPrompt(question).Split('\n');
        var from = Array.FindIndex(lines, l => l.StartsWith("The input progression"));
        var to = Array.FindIndex(lines, l => l.StartsWith("Respond as valid JSON"));
        foreach (var line in lines[from..to]) Line($"  | {line}".TrimEnd());
        var example = Array.FindIndex(lines, l => l.Contains("\"suggestions\""));
        foreach (var line in lines[(example + 1)..(example + 3)]) Line($"  | {line.Trim()}");
    }

    // ---- The next chord of two textbook progressions ----

    static readonly string[] MajorQualities = ["", "m", "m", "", "", "m", "dim"];
    static readonly string[] MinorQualities = ["m", "dim", "", "m", "m", "", ""];

    static string[] Diatonic(string tonic, bool minor)
    {
        var scale = Scale(tonic, minor);
        var qualities = minor ? MinorQualities : MajorQualities;
        return [.. scale.Select((n, i) => n + qualities[i])];
    }

    // I vi IV and i VI VII, the two questions asked in every key
    static readonly (string Name, bool Minor, int[] Degrees)[] Questions =
    [
        ("I vi IV", false, [0, 5, 3]),
        ("i VI VII", true, [0, 5, 6]),
    ];

    static string Pc(string chord)
    {
        var root = chord.Length > 1 && chord[1] is '#' or 'b' ? chord[..2] : chord[..1];
        return $"{(Pitch(root) + 12) % 12}{chord[root.Length..]}";
    }

    static readonly (string Name, string Key)[] Shown =
    [
        ("I vi IV", "C major"), ("I vi IV", "G major"), ("I vi IV", "Db major"), ("I vi IV", "F# major"),
        ("i VI VII", "G# minor"),
    ];

    // A key tied at the top whose seven chords are not the first key's, even respelled
    static bool OtherScale(Told t) =>
        t.All.Where(c => c.Count == t.All[0].Count)
            .Any(c => !c.Set.Select(Pc).Order().SequenceEqual(t.Set.Select(Pc).Order()));

    static void Textbook()
    {
        Title("\"What chord comes next after ...?\" for two textbook progressions in the 30 keys");
        var tally = Versions.ToDictionary(v => v, _ => new Dictionary<string, int>());
        var other = Versions.ToDictionary(v => v, _ => 0);
        var read = Versions.ToDictionary(v => v, _ => 0);
        var shown = Shown.ToDictionary(s => s, _ => new List<string>());
        foreach (var (name, minor, degrees) in Questions)
        {
            var tonics = minor ? MinorKeys : MajorKeys;
            Line();
            Row([19], name, string.Join(" ", tonics.Select(t => t.PadRight(2))));
            foreach (var v in Versions)
            {
                var marks = tonics.Select(tonic =>
                {
                    var set = Diatonic(tonic, minor);
                    string[] chords = [.. degrees.Select(d => set[d])];
                    var key = $"{tonic} {(minor ? "minor" : "major")}";
                    var question = $"What chord comes next after {string.Join(" ", chords)}?";
                    var t = Tell(v, question)!;
                    var mark = !t.Chords.SequenceEqual(chords) ? "r"
                        : t.Set.Order().SequenceEqual(set.Order()) ? "="
                        : t.Set.Select(Pc).Order().SequenceEqual(set.Select(Pc).Order()) ? "e"
                        : "x";
                    tally[v][mark] = tally[v].GetValueOrDefault(mark) + 1;
                    if (mark != "r") read[v]++;
                    if (mark != "r" && OtherScale(t)) other[v]++;
                    if (shown.TryGetValue((name, key), out var lines))
                    {
                        if (v == Pin) lines.Add($"{key}, {name}: \"{question}\"");
                        lines.Add($"  {v.Name,-8} reads {string.Join(" ", t.Chords)}; key: {t.Keys} ({t.Count})");
                        lines.Add($"  {"",-8} may suggest: {string.Join(", ", t.Set)}");
                    }
                    return mark;
                });
                Row([10, 8], "", v.Name, string.Join(" ", marks.Select(m => m.PadRight(2))));
            }
        }

        Line();
        Line("= the chords read as written, and the model may suggest the key's chords as the textbook spells them;");
        Line("e the same chords, spelled from the enharmonic key; x other chords; r a chord dropped or read as another chord");
        foreach (var v in Versions)
            Line($"{v.Name}: 30 questions, = {tally[v].GetValueOrDefault("=")}, e {tally[v].GetValueOrDefault("e")}, " +
                 $"x {tally[v].GetValueOrDefault("x")}, r {tally[v].GetValueOrDefault("r")}; " +
                 $"a key of another scale tied at the top in {other[v]} of the {read[v]} read as written");
        Line();
        foreach (var line in shown.Values.SelectMany(l => l)) Line(line);
    }

    // ---- The dominant of a minor key ----

    static string YesNo(bool b) => b ? "yes" : "no";

    static void Minor()
    {
        Title("The dominant the list holds, in each key's own list");
        foreach (var minor in new[] { false, true })
        {
            var tonics = minor ? MinorKeys : MajorKeys;
            int major = 0, minorV = 0;
            foreach (var tonic in tonics)
            {
                var key = $"{tonic} {(minor ? "minor" : "major")}";
                var set = Pin.Identify([tonic + (minor ? "m" : "")]).Single(c => c.Key == key).Set;
                var fifth = Scale(tonic, minor)[4];
                if (set.Contains(fifth)) major++;
                if (set.Contains(fifth + "m")) minorV++;
            }
            Line($"{tonics.Length} {(minor ? "minor" : "major")} keys: the major triad on the fifth degree in {major}, the minor one in {minorV}");
        }

        var aMinor = Pin.Identify(["Am"]).Single(c => c.Key == "A minor").Set;
        Line($"A minor: {string.Join(", ", aMinor)}");
        Line($"  the prompt's example suggests E7 (\"V7-i\"): E7 in the list: {YesNo(aMinor.Contains("E7"))}; E: {YesNo(aMinor.Contains("E"))}");
        Line($"  and G as a half cadence (\"bVII-i\"): G is degree {Array.IndexOf(aMinor, "G") + 1} of the list; a half cadence ends on degree 5, {aMinor[4]}");
    }
}
