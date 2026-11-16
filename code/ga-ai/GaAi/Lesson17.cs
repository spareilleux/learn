namespace GaAi;

using System.Reflection;
using System.Text.RegularExpressions;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Intents;
using Microsoft.Extensions.DependencyInjection;
using static Report;

// Lesson 17: the capo and the tunings. CapoSkill answers "what shape do I play in E with capo 4"
// and "what does a C shape sound like with capo 3" with semitone arithmetic; AlternateTuningsSkill
// answers "what is DADGAD tuning" from a table of nine tunings. Neither calls a model. The program
// asks which skill takes these questions when the router can't embed them, then checks each answer
// against a textbook: the arithmetic, and the spelling of the key or chord it names.
public static class Lesson17
{
    public static void Run()
    {
        Lesson4.EnsureIndex();
        using var host = new ChatHost();
        using var client = host.CreateClient();
        host.WaitForWarmup();
        using var scope = host.Services.CreateScope();
        var intents = scope.ServiceProvider.GetServices<IIntent>().ToList();
        var capo = SkillOf(intents.Single(i => i.Id == "skill.capo"))!;
        var tunings = SkillOf(intents.Single(i => i.Id == "skill.alternatetunings"))!;

        Fallback(intents, capo, tunings);
        CapoExamples(capo);
        SoundingToShape(capo);
        ShapeToSounding(capo);
        OpenShapes(capo);
        Phrasings(capo);
        TuningsProbe.ExampleAnswers(tunings);
        TuningsProbe.Table(tunings);
        TuningsProbe.ByNotes(tunings, "at the pin");
        TuningsProbe.Others(tunings, "at the pin");
    }

    internal static IOrchestratorSkill? SkillOf(IIntent intent) =>
        intent.GetType().GetFields(BindingFlags.NonPublic | BindingFlags.Instance)
            .Select(f => f.GetValue(intent)).OfType<IOrchestratorSkill>().FirstOrDefault();

    // ---- Which skill takes the question without embeddings ----

    // On GA's main, when the router can't embed a question, the first intent in registration order
    // whose skill's CanHandle accepts it answers (SemanticIntentRouter.KeywordFallback)
    static void Fallback(List<IIntent> intents, IOrchestratorSkill capo, IOrchestratorSkill tunings)
    {
        Title("Without embeddings: the first skill, in registration order, whose CanHandle accepts each example prompt");
        var skills = intents.Select(i => (i.Id, Skill: SkillOf(i))).Where(x => x.Skill is not null).ToList();
        int[] w = [64];
        Row(w, "prompt", "first skill that accepts it");
        foreach (var p in capo.ExamplePrompts.Concat(tunings.ExamplePrompts))
            Row(w, p, skills.FirstOrDefault(x => x.Skill!.CanHandle(p)).Id ?? "none");
        Line($"skill intents {skills.Count}; CanHandle of skill.capo and skill.alternatetunings accepts " +
             $"{capo.ExamplePrompts.Concat(tunings.ExamplePrompts).Count(p => capo.CanHandle(p) || tunings.CanHandle(p))} of their " +
             $"{capo.ExamplePrompts.Count + tunings.ExamplePrompts.Count} example prompts");
    }

    // ---- The capo ----

    // The keys a key signature can write: at most seven sharps or flats
    static readonly HashSet<string> MajorKeys = ["C", "G", "D", "A", "E", "B", "F#", "C#", "F", "Bb", "Eb", "Ab", "Db", "Gb", "Cb"];
    static readonly HashSet<string> MinorKeys = ["A", "E", "B", "F#", "C#", "G#", "D#", "A#", "D", "G", "C", "F", "Bb", "Eb", "Ab"];

    // What the prompt asks for: the shape to play, or the chord that sounds
    sealed record Want(string Kind, string Chord);

    static readonly Regex ShapeAnswer = new(@"play a \*\*(?<chord>.+?) shape\*\* to sound in \*\*(?<key>.+?)\*\*");
    static readonly Regex SoundAnswer = new(@"sounds as \*\*(?<chord>.+?)\*\*");
    static readonly Regex AmLine = new(@"an Am shape at capo \d+ would sound as (?<am>.+?)\.");
    static readonly Regex ChordParts = new(@"^(?<root>[A-G][#b]*)(?<quality>.*)$");

    sealed record Reply(string Kind, string? Chord, string? Am, string First);

    static Reply Ask(IOrchestratorSkill skill, string prompt)
    {
        var text = skill.ExecuteAsync(prompt).GetAwaiter().GetResult().Result.ReplaceLineEndings("\n");
        var first = text.Split('\n')[0];
        var am = AmLine.Match(text) is { Success: true } a ? a.Groups["am"].Value : null;
        if (ShapeAnswer.Match(text) is { Success: true } s) return new("shape", s.Groups["chord"].Value, am, first);
        if (SoundAnswer.Match(text) is { Success: true } o) return new("sounds", o.Groups["chord"].Value, am, first);
        return new("declined", null, am, first);
    }

    static (int Pc, string Quality) Parts(string chord)
    {
        var m = ChordParts.Match(chord);
        return (TuningsProbe.Pc(m.Groups["root"].Value), m.Groups["quality"].Value);
    }

    // A chord's root as a key signature writes it, for a major or minor chord
    static bool Spellable(string chord)
    {
        var m = ChordParts.Match(chord);
        return m.Groups["quality"].Value switch
        {
            "" => MajorKeys.Contains(m.Groups["root"].Value),
            "m" => MinorKeys.Contains(m.Groups["root"].Value),
            _ => true,
        };
    }

    static string Verdict(Reply r, Want want)
    {
        if (r.Kind == "declined") return "declined";
        if (r.Kind != want.Kind) return "wrong direction";
        if (Parts(r.Chord!) != Parts(want.Chord)) return "wrong chord";
        return Spellable(r.Chord!) ? "right" : "right, theoretical spelling";
    }

    static string Show(Reply r) => r.Kind == "declined" ? "declined" : $"{r.Kind} {r.Chord}";

    static readonly (string Prompt, Want Want)[] Examples =
    [
        ("What shape do I play in E with capo 4", new("shape", "C")),
        ("Song is in E, what chord shape with capo on 4", new("shape", "C")),
        ("Capo on 3, song in G, what shape", new("shape", "E")),
        ("I play a C shape with capo 3 — what does it sound like", new("sounds", "Eb")),
        ("What does a G shape sound like with capo 2", new("sounds", "A")),
        ("Capo on 5, song in A", new("shape", "E")),
        ("If I capo on 2 and play an Em shape, what's the sounding chord", new("sounds", "F#m")),
        ("What's the sounding key if I play in G with capo on 5", new("sounds", "C")),
        ("Capo 7, D shape — sounding chord", new("sounds", "A")),
        ("What chord shape for B major with capo 4", new("shape", "G")),
    ];

    static void CapoExamples(IOrchestratorSkill capo)
    {
        Title("CapoSkill's example prompts: what each asks, and the answer");
        int[] w = [64, 12, 14];
        Row(w, "prompt", "asks", "answer", "verdict");
        foreach (var (prompt, want) in Examples)
        {
            var r = Ask(capo, prompt);
            Row(w, prompt, $"{want.Kind} {want.Chord}", Show(r), Verdict(r, want));
        }
    }

    static string Spell(int pc, bool flats) =>
        (flats ? new[] { "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B" }
               : new[] { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" })[(pc % 12 + 12) % 12];

    // Every key a signature can write, major and minor, with the capo on frets 1 to 11
    static void SoundingToShape(IOrchestratorSkill capo)
    {
        Title("\"Song is in <key>, what shape with capo <fret>\": 30 keys, frets 1 to 11");
        int[] w = [8, 9, 7, 30, 7];
        Row(w, "key", "prompts", "right", "right, theoretical spelling", "wrong", "declined");
        var amWrong = 0; var amNoKey = 0; var amSeen = 0;
        foreach (var (quality, keys) in new[] { ("major", MajorKeys), ("minor", MinorKeys) })
        {
            var counts = new Dictionary<string, int>();
            var odd = new SortedSet<string>(StringComparer.Ordinal);
            var declined = new SortedSet<string>(StringComparer.Ordinal);
            foreach (var key in keys)
                for (var fret = 1; fret <= 11; fret++)
                {
                    var minor = quality == "minor";
                    var pc = TuningsProbe.Pc(key) - fret;
                    var want = new Want("shape", Spell(pc, false) + (minor ? "m" : ""));
                    var r = Ask(capo, $"Song is in {key} {quality}, what shape with capo {fret}");
                    var v = Verdict(r, want);
                    counts[v] = counts.GetValueOrDefault(v) + 1;
                    if (v == "right, theoretical spelling") odd.Add(r.Chord!);
                    if (v == "declined") declined.Add(key);
                    if (r.Am is { } am)
                    {
                        amSeen++;
                        if (Parts(am) != Parts(Spell(9 + fret, false) + "m")) amWrong++;
                        else if (!Spellable(am)) amNoKey++;
                    }
                }
            Row(w, quality, keys.Count * 11, counts.GetValueOrDefault("right"),
                $"{counts.GetValueOrDefault("right, theoretical spelling")} ({string.Join(" ", odd)})",
                counts.GetValueOrDefault("wrong chord") + counts.GetValueOrDefault("wrong direction"),
                declined.Count == 0 ? "0" : $"{counts.GetValueOrDefault("declined")} ({string.Join(" ", declined)})");
        }

        Line($"the answers' \"an Am shape at capo N would sound as …m\": {amSeen}, a wrong chord {amWrong}, a theoretical minor key {amNoKey}");
    }

    static readonly string[] OpenShapeNames = ["C", "A", "G", "E", "D", "Am", "Em", "Dm"];

    static void ShapeToSounding(IOrchestratorSkill capo)
    {
        Title("\"What does a <shape> shape sound like with capo <fret>\": the eight open shapes, frets 1 to 11");
        int[] w = [8, 9, 7, 7, 10];
        Row(w, "shape", "prompts", "right", "wrong", "declined", "right, theoretical spelling");
        foreach (var shape in OpenShapeNames)
        {
            var counts = new Dictionary<string, int>();
            var odd = new List<string>();
            for (var fret = 1; fret <= 11; fret++)
            {
                var (pc, quality) = Parts(shape);
                var want = new Want("sounds", Spell(pc + fret, false) + quality);
                var article = shape[0] is 'A' or 'E' ? "an" : "a";
                var r = Ask(capo, $"What does {article} {shape} shape sound like with capo {fret}");
                var v = Verdict(r, want);
                counts[v] = counts.GetValueOrDefault(v) + 1;
                if (v == "right, theoretical spelling") odd.Add($"{fret}: {r.Chord}");
            }
            Row(w, shape, 11, counts.GetValueOrDefault("right"), counts.GetValueOrDefault("wrong chord") + counts.GetValueOrDefault("wrong direction"),
                counts.GetValueOrDefault("declined"), odd.Count == 0 ? "0" : $"{odd.Count}, capo {string.Join(", ", odd)}");
        }
    }

    // The question a guitarist asks first: where to put the capo to play a key with open shapes
    static void OpenShapes(IOrchestratorSkill capo)
    {
        Title("\"Where should I put the capo to play in <key> with open chords?\"");
        int[] w = [5, 48];
        Row(w, "key", "frets 0 to 7 that give an open shape: C A G E D", "the skill's answer");
        foreach (var key in new[] { "C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B" })
        {
            var frets = Enumerable.Range(0, 8)
                .Select(f => (f, Shape: Spell(TuningsProbe.Pc(key) - f, false)))
                .Where(x => x.Shape is "C" or "A" or "G" or "E" or "D")
                .Select(x => $"{x.f} {x.Shape}");
            var r = Ask(capo, $"Where should I put the capo to play in {key} with open chords?");
            Row(w, key, string.Join(", ", frets), Show(r));
        }
    }

    static readonly (string Prompt, Want Want)[] OtherPhrasings =
    [
        ("song in Em, capo 2, what shape", new("shape", "Dm")),
        ("song in E minor, capo 2, what shape", new("shape", "Dm")),
        ("What shape do I play in e with capo 4", new("shape", "C")),
        ("what shape for F with capo 3", new("shape", "D")),
        ("capo on 3 in G, what shape", new("shape", "E")),
        ("Capo on 2, song in F#, what shape", new("shape", "E")),
        ("song in C#, capo 4, what shape", new("shape", "A")),
        ("song in B♭, capo 1, what shape", new("shape", "A")),
        ("I'm in a band, capo 2, song is in G", new("shape", "F")),
        ("Playing in D with capo 2, what key does it sound in?", new("sounds", "E")),
        ("I play a C7 shape with capo 3, what does it sound like", new("sounds", "Eb7")),
        ("what does a Cmaj7 shape sound like with capo 2", new("sounds", "Dmaj7")),
        ("capo 2, Dsus4 shape, what chord do I hear", new("sounds", "Esus4")),
    ];

    static void Phrasings(IOrchestratorSkill capo)
    {
        Title("Other phrasings");
        int[] w = [56, 14, 14];
        Row(w, "prompt", "asks", "answer", "verdict");
        foreach (var (prompt, want) in OtherPhrasings)
        {
            var r = Ask(capo, prompt);
            Row(w, prompt, $"{want.Kind} {want.Chord}", Show(r), Verdict(r, want));
        }
    }
}
