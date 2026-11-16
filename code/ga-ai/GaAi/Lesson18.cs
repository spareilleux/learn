namespace GaAi;

using System.Text.RegularExpressions;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Intents;
using Microsoft.Extensions.DependencyInjection;
using static Report;

// Lesson 18: voice leading. VoiceLeadingSkill answers "voice leading from C to F" with the
// pairing of the two chords' notes that moves the voices least, found by trying every
// permutation. Neither the pin nor GA's main changed it. The program asks which skill takes these
// questions when the router can't embed them, which chords the skill reads, whether its motion is
// the least a textbook finds, and how it spells the notes.
public static class Lesson18
{
    public static void Run()
    {
        Lesson4.EnsureIndex();
        using var host = new ChatHost();
        using var client = host.CreateClient();
        host.WaitForWarmup();
        using var scope = host.Services.CreateScope();
        var intents = scope.ServiceProvider.GetServices<IIntent>().ToList();
        var skill = Lesson17.SkillOf(intents.Single(i => i.Id == "skill.voiceleading"))!;

        Fallback(intents, skill);
        Examples(skill);
        Symbols(skill);
        Accidentals(skill);
        Grid(skill);
        Spelling(skill);
        Phrasings(skill);
    }

    // ---- A textbook's chords ----

    // Each tone: semitones above the root, and its degree (1, 3, 5, 7, 9...)
    sealed record Quality(string Suffix, (int Semis, int Degree)[] Tones);

    // The qualities VoiceLeadingSkill builds, as a textbook writes them
    static readonly Quality[] Built =
    [
        new("", [(0, 1), (4, 3), (7, 5)]),
        new("m", [(0, 1), (3, 3), (7, 5)]),
        new("dim", [(0, 1), (3, 3), (6, 5)]),
        new("aug", [(0, 1), (4, 3), (8, 5)]),
        new("sus2", [(0, 1), (2, 2), (7, 5)]),
        new("sus4", [(0, 1), (5, 4), (7, 5)]),
        new("7", [(0, 1), (4, 3), (7, 5), (10, 7)]),
        new("m7", [(0, 1), (3, 3), (7, 5), (10, 7)]),
        new("maj7", [(0, 1), (4, 3), (7, 5), (11, 7)]),
        new("m7b5", [(0, 1), (3, 3), (6, 5), (10, 7)]),
        new("dim7", [(0, 1), (3, 3), (6, 5), (9, 7)]),
        new("6", [(0, 1), (4, 3), (7, 5), (9, 6)]),
        new("m6", [(0, 1), (3, 3), (7, 5), (9, 6)]),
        new("9", [(0, 1), (4, 3), (7, 5), (10, 7), (2, 9)]),
        new("maj9", [(0, 1), (4, 3), (7, 5), (11, 7), (2, 9)]),
        new("m9", [(0, 1), (3, 3), (7, 5), (10, 7), (2, 9)]),
    ];

    // Other common chords, which the skill doesn't build
    static readonly Quality[] Others =
    [
        new("add9", [(0, 1), (4, 3), (7, 5), (2, 9)]),
        new("7sus4", [(0, 1), (5, 4), (7, 5), (10, 7)]),
        new("7b9", [(0, 1), (4, 3), (7, 5), (10, 7), (1, 9)]),
        new("7#9", [(0, 1), (4, 3), (7, 5), (10, 7), (3, 9)]),
        new("mMaj7", [(0, 1), (3, 3), (7, 5), (11, 7)]),
        new("11", [(0, 1), (4, 3), (7, 5), (10, 7), (2, 9), (5, 11)]),
        new("13", [(0, 1), (4, 3), (7, 5), (10, 7), (2, 9), (9, 13)]),
    ];

    static readonly Quality[] All = [.. Built, .. Others];

    static Quality Q(string suffix) => All.Single(q => q.Suffix == suffix);

    static readonly string[] Sharp = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
    const string Letters = "CDEFGAB";
    static readonly int[] Natural = [0, 2, 4, 5, 7, 9, 11];

    // "Bb", "F#m7b5", "Cmaj7": the root as written, and the quality from the textbook table
    static (string Root, Quality Quality) Chord(string symbol)
    {
        var n = symbol.Length > 1 && symbol[1] is '#' or 'b' ? 2 : 1;
        return (symbol[..n], Q(symbol[n..]));
    }

    static int[] Pcs(string symbol)
    {
        var (root, q) = Chord(symbol);
        return [.. q.Tones.Select(t => (TuningsProbe.Pc(root) + t.Semis) % 12)];
    }

    // A tone spelled from the root's letter: a third is two letters up, whatever its accidental
    static string Spell(string root, int semis, int degree)
    {
        var letter = (Letters.IndexOf(char.ToUpperInvariant(root[0])) + degree - 1) % 7;
        var acc = ((TuningsProbe.Pc(root) + semis - Natural[letter]) % 12 + 12) % 12;
        return Letters[letter] + acc switch
        {
            0 => "", 1 => "#", 2 => "##", 11 => "b", 10 => "bb",
            _ => throw new ArgumentException($"{root} +{semis}"),
        };
    }

    static string[] Spelled(string symbol)
    {
        var (root, q) = Chord(symbol);
        return [.. q.Tones.Select(t => Spell(root, t.Semis, t.Degree))];
    }

    // The name of a set of pitch classes: on the root asked, spelled as asked, if a chord on it fits
    static string Name(IEnumerable<int> pcs, string root)
    {
        var set = pcs.ToHashSet();
        var r0 = TuningsProbe.Pc(root);
        foreach (var r in Enumerable.Range(0, 12).Select(i => (r0 + i) % 12))
            foreach (var q in All)
                if (q.Tones.Select(t => (r + t.Semis) % 12).ToHashSet().SetEquals(set))
                    return (r == r0 ? root : Sharp[r]) + q.Suffix;
        return string.Join(" ", set.Order().Select(p => Sharp[p]));
    }

    // ---- The skill's answer ----

    static readonly Regex Total = new(@"total motion = \*\*(?<cost>\d+) semitones\*\*");
    static readonly Regex Voice = new(@"^\| (?<voice>\d+) \| (?<from>[^|]+?) \| (?<to>[^|]+?) \| [^|]+? \|$");

    // The total the skill gives, and each voice's notes as it spells them
    sealed record Answer(int Cost, List<(string From, string To)> Voices, bool Claims)
    {
        public int[] From => [.. Voices.Select(v => TuningsProbe.Pc(v.From)).Distinct()];
        public int[] To => [.. Voices.Select(v => TuningsProbe.Pc(v.To)).Distinct()];
    }

    static Answer? Ask(IOrchestratorSkill skill, string prompt)
    {
        var text = skill.ExecuteAsync(prompt).GetAwaiter().GetResult().Result.ReplaceLineEndings("\n");
        if (Total.Match(text) is not { Success: true } total) return null;
        var voices = text.Split('\n').Select(l => Voice.Match(l)).Where(m => m.Success)
            .Select(m => (m.Groups["from"].Value, m.Groups["to"].Value)).ToList();
        return new(int.Parse(total.Groups["cost"].Value), voices, text.Contains("requires more total semitone movement"));
    }

    static bool Reads(Answer? a, string from, string to) =>
        a is not null && a.From.ToHashSet().SetEquals(Pcs(from)) && a.To.ToHashSet().SetEquals(Pcs(to));

    static string ReadAs(Answer? a, string from, string to) =>
        a is null ? "declined" : $"{Name(a.From, Chord(from).Root)} → {Name(a.To, Chord(to).Root)}";

    // ---- Least motion ----

    static int Move(int from, int to)
    {
        var d = ((to - from) % 12 + 12) % 12;
        return d <= 6 ? d : d - 12;
    }

    static IEnumerable<int[]> Permutations(int n)
    {
        if (n == 0) { yield return []; yield break; }
        foreach (var p in Permutations(n - 1))
            for (var i = 0; i <= p.Length; i++)
                yield return [.. p[..i], n - 1, .. p[i..]];
    }

    static int Cost(int[] a, int[] b, int[] p) => Enumerable.Range(0, a.Length).Sum(i => Math.Abs(Move(a[i], b[p[i]])));

    // The chord's notes, plus every choice of doubled notes up to n voices
    static IEnumerable<int[]> Fill(int[] chord, int n)
    {
        IEnumerable<int[]> Extra(int k, int start)
        {
            if (k == 0) { yield return []; yield break; }
            for (var i = start; i < chord.Length; i++)
                foreach (var rest in Extra(k - 1, i))
                    yield return [chord[i], .. rest];
        }
        return Extra(n - chord.Length, 0).Select(e => (int[])[.. chord, .. e]);
    }

    // A textbook's least motion: as many voices as the larger chord, every note of both chords
    // sounded, and any note of the smaller one doubled
    static int Least(int[] a, int[] b)
    {
        var n = Math.Max(a.Length, b.Length);
        var perms = Permutations(n).ToList();
        return Fill(a, n).SelectMany(va => Fill(b, n).Select(vb => perms.Min(p => Cost(va, vb, p)))).Min();
    }

    // The skill's own search pads the smaller chord with its root (VoiceLeadingSkill.cs lines
    // 185-194). The number of different pairings of notes that reach its total
    static int BestPairings(int[] a, int[] b, int cost)
    {
        var n = Math.Max(a.Length, b.Length);
        int[] Pad(int[] c) => [.. c, .. Enumerable.Repeat(c[0], n - c.Length)];
        var (pa, pb) = (Pad(a), Pad(b));
        return Permutations(n).Where(p => Cost(pa, pb, p) == cost)
            .Select(p => string.Join(",", Enumerable.Range(0, n).Select(i => (pa[i], pb[p[i]])).Order()))
            .Distinct().Count();
    }

    // ---- Which skill takes the question without embeddings ----

    // On GA's main, when the router can't embed a question, the first intent in registration order
    // whose skill's CanHandle accepts it answers (SemanticIntentRouter.KeywordFallback)
    static void Fallback(List<IIntent> intents, IOrchestratorSkill skill)
    {
        Title("Without embeddings: the first skill, in registration order, whose CanHandle accepts each example prompt");
        var skills = intents.Select(i => (i.Id, Skill: Lesson17.SkillOf(i))).Where(x => x.Skill is not null).ToList();
        int[] w = [44];
        Row(w, "prompt", "first skill that accepts it");
        foreach (var p in skill.ExamplePrompts)
            Row(w, p, skills.FirstOrDefault(x => x.Skill!.CanHandle(p)).Id ?? "none");
        Line($"skill intents {skills.Count}; CanHandle of skill.voiceleading accepts " +
             $"{skill.ExamplePrompts.Count(skill.CanHandle)} of its {skill.ExamplePrompts.Count} example prompts");
    }

    // ---- The example prompts ----

    // VoiceLeadingSkill.ExamplePrompts (lines 35-47 at the pin), with the two chords each one names
    static readonly (string Prompt, string From, string To)[] ExampleChords =
    [
        ("voice leading from C to F", "C", "F"),
        ("smooth voice leading C to Am", "C", "Am"),
        ("best voicing from G7 to Cmaj7", "G7", "Cmaj7"),
        ("how do I voice lead Dm7 to G7", "Dm7", "G7"),
        ("voice leading C major to G major", "C", "G"),
        ("smoothest voicing from Em to A7", "Em", "A7"),
        ("voice leading Fmaj7 to Bm7b5", "Fmaj7", "Bm7b5"),
        ("what's the smoothest voicing from D to A", "D", "A"),
        ("voice lead C7 to F", "C7", "F"),
        ("best way to move from G7 to C", "G7", "C"),
    ];

    static void Examples(IOrchestratorSkill skill)
    {
        Title("VoiceLeadingSkill's example prompts: the chords read, the total motion, and the least motion");
        int[] w = [42, 14, 14, 7, 6, 14];
        Row(w, "prompt", "asks", "reads", "total", "least", "best pairings");
        foreach (var (prompt, from, to) in ExampleChords)
        {
            var a = Ask(skill, prompt);
            var read = Reads(a, from, to);
            Row(w, prompt, $"{from} → {to}", ReadAs(a, from, to),
                a?.Cost.ToString() ?? "-", read ? Least(Pcs(from), Pcs(to)) : "-",
                read ? BestPairings(Pcs(from), Pcs(to), a!.Cost) : "-");
        }
    }

    // ---- The chord symbols ----

    // How the symbols are written, and the chord a textbook reads
    static readonly (string Written, string Means)[] SymbolList =
    [
        ("", ""), ("maj", ""), (" major", ""), ("m", "m"), ("min", "m"), (" minor", "m"), ("-", "m"),
        ("dim", "dim"), ("°", "dim"), ("o", "dim"), ("aug", "aug"), ("+", "aug"),
        ("sus2", "sus2"), ("sus4", "sus4"), ("sus", "sus4"),
        ("7", "7"), ("dom7", "7"), ("m7", "m7"), ("min7", "m7"), ("-7", "m7"),
        ("maj7", "maj7"), ("M7", "maj7"), ("Δ7", "maj7"), ("Δ", "maj7"), ("major7", "maj7"),
        ("m7b5", "m7b5"), ("min7b5", "m7b5"), ("ø", "m7b5"), ("ø7", "m7b5"),
        ("dim7", "dim7"), ("°7", "dim7"), ("o7", "dim7"),
        ("6", "6"), ("m6", "m6"), ("min6", "m6"), ("9", "9"), ("maj9", "maj9"), ("m9", "m9"), ("min9", "m9"),
        ("add9", "add9"), ("7sus4", "7sus4"), ("7b9", "7b9"), ("7#9", "7#9"), ("mMaj7", "mMaj7"), ("11", "11"), ("13", "13"),
    ];

    static void Symbols(IOrchestratorSkill skill)
    {
        Title("Each chord symbol on C, as the first chord (\"voice leading C<symbol> to F\") and as the last (\"voice leading F to C<symbol>\")");
        int[] w = [10, 10, 22];
        Row(w, "written", "means", "first", "last");
        var right = new int[2];
        foreach (var (written, means) in SymbolList)
        {
            var c = "C" + means;
            var first = Ask(skill, $"voice leading C{written} to F");
            var last = Ask(skill, $"voice leading F to C{written}");
            string Cell(Answer? a, bool isFirst, int k)
            {
                var ok = isFirst ? Reads(a, c, "F") : Reads(a, "F", c);
                if (ok) { right[k]++; return "right"; }
                if (a is null) return "declined";
                return "reads " + (isFirst ? Name(a.From, "C") : Name(a.To, "C"));
            }
            Row(w, $"C{written}", c, Cell(first, true, 0), Cell(last, false, 1));
        }

        Line($"symbols {SymbolList.Length}: read right as the first chord {right[0]}, as the last {right[1]}");
    }

    // ---- A root with an accidental ----

    static readonly (string Label, string[] Roots)[] Notations =
    [
        ("ASCII #", ["C#", "D#", "F#", "G#", "A#"]),
        ("♯", ["C♯", "D♯", "F♯", "G♯", "A♯"]),
        ("ASCII b", ["Db", "Eb", "Gb", "Ab", "Bb"]),
        ("♭", ["D♭", "E♭", "G♭", "A♭", "B♭"]),
    ];

    static void Accidentals(IOrchestratorSkill skill)
    {
        Title("A root with an accidental, first (\"voice leading <root> to C\") and last (\"voice leading C to <root>\", \"… to <root>m\")");
        int[] w = [10, 8, 8, 9, 25];
        Row(w, "notation", "first", "last", "last, m", "the root first, spelled", "the last, misread as");
        foreach (var (label, roots) in Notations)
        {
            var ascii = roots.Select(r => r.Replace("♯", "#").Replace("♭", "b")).ToArray();
            var firstAnswers = roots.Zip(ascii).Select(x => (Root: x.Second, Answer: Ask(skill, $"voice leading {x.First} to C"))).ToList();
            var lastAnswers = roots.Zip(ascii).Select(x => (Root: x.Second, Answer: Ask(skill, $"voice leading C to {x.First}"))).ToList();
            var first = firstAnswers.Count(x => Reads(x.Answer, x.Root, "C"));
            var last = lastAnswers.Count(x => Reads(x.Answer, "C", x.Root));
            var minor = roots.Zip(ascii).Count(x => Reads(Ask(skill, $"voice leading C to {x.First}m"), "C", x.Second + "m"));
            // Voice 1 starts on the first chord's root (VoiceLeadingSkill.cs lines 117-128)
            var spelled = string.Join(", ", firstAnswers.Select(x => x.Answer?.Voices[0].From ?? "declined"));
            var misread = lastAnswers.Where(x => !Reads(x.Answer, "C", x.Root))
                .Select(x => x.Answer is null ? "declined" : Name(x.Answer.To, x.Root)).ToList();
            Row(w, label, $"{first} of 5", $"{last} of 5", $"{minor} of 5", spelled, misread.Count == 0 ? "-" : string.Join(", ", misread));
        }
    }

    // ---- Least motion over a grid ----

    static readonly string[] GridRoots = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];

    static void Grid(IOrchestratorSkill skill)
    {
        Title("\"voice leading C<quality> to <root><quality>\": the 16 qualities the skill builds, on C and on each of the 12 roots");
        int[] w = [8, 9, 12, 14, 21, 12];
        Row(w, "voices", "prompts", "read right", "least motion", "more than the least", "most extra", "several best pairings");
        var extra = new List<(int Excess, string Prompt, int Cost, int Least)>();
        var ties = new List<(int Count, string Prompt)>();
        var claims = 0;
        var all = Built.SelectMany(qa => GridRoots.SelectMany(r => Built.Select(qb => (From: "C" + qa.Suffix, To: r + qb.Suffix)))).ToList();
        foreach (var g in all.GroupBy(x => (Pcs(x.From).Length, Pcs(x.To).Length)).OrderBy(g => g.Key))
        {
            int read = 0, least = 0, more = 0, most = 0, several = 0;
            foreach (var (from, to) in g)
            {
                var prompt = $"voice leading {from} to {to}";
                var a = Ask(skill, prompt);
                if (!Reads(a, from, to)) continue;
                read++;
                if (a!.Claims) claims++;
                var l = Least(Pcs(from), Pcs(to));
                if (a!.Cost == l) least++;
                else
                {
                    more++;
                    most = Math.Max(most, a.Cost - l);
                    extra.Add((a.Cost - l, $"{from} to {to}", a.Cost, l));
                }
                var b = BestPairings(Pcs(from), Pcs(to), a.Cost);
                if (b > 1) { several++; ties.Add((b, $"{from} to {to}")); }
            }
            Row(w, $"{g.Key.Item1} → {g.Key.Item2}", g.Count(), read, least, more, most, several);
        }

        Line($"prompts {all.Count}: closing on \"every other voicing … requires more total semitone movement\" {claims}, " +
             $"more motion than the least {extra.Count}, several best pairings {ties.Count}");
        Line("by how much more: " + string.Join(", ", extra.GroupBy(x => x.Excess).OrderBy(x => x.Key).Select(x => $"{x.Key} semitone{(x.Key == 1 ? "" : "s")} {x.Count()}")));
        Line("the first answers with the most extra motion:");
        foreach (var x in extra.OrderByDescending(x => x.Excess).Take(5))
            Line($"  {x.Prompt}: {x.Cost} semitones, least {x.Least}");
        Line("the first answers with the most best pairings:");
        foreach (var x in ties.OrderByDescending(x => x.Count).Take(3))
            Line($"  {x.Prompt}: {x.Count} pairings");
    }

    // ---- Spelling ----

    static readonly string[] MajorKeys = ["C", "G", "D", "A", "E", "B", "F#", "F", "Bb", "Eb", "Ab", "Db"];
    static readonly string[] MinorKeys = ["C", "G", "D", "A", "E", "B", "F#", "C#", "G#", "F", "Bb", "Eb"];

    // The notes the skill spells otherwise than the chord's own spelling, as "A# for Bb"
    static string Misspelled(Answer? a, string from, string to)
    {
        if (a is null) return "declined";
        string Textbook(string chord, string note) =>
            Spelled(chord).Single(s => TuningsProbe.Pc(s) == TuningsProbe.Pc(note));
        var wrong = a.Voices.SelectMany(v => new[] { (v.From, Textbook(from, v.From)), (v.To, Textbook(to, v.To)) })
            .Where(x => x.Item1 != x.Item2).Distinct().Select(x => $"{x.Item1} for {x.Item2}").ToList();
        return wrong.Count == 0 ? "as spelled" : string.Join(", ", wrong);
    }

    static void Spelling(IOrchestratorSkill skill)
    {
        Title("Spelling: ii7 to V7 and V7 to Imaj7 in the 12 major keys, the notes spelled otherwise than in their chord");
        int[] w = [5, 34];
        Row(w, "key", "ii7 to V7", "V7 to Imaj7");
        var total = 0; var spelled = 0;
        void Count(string cell) { total++; if (cell == "as spelled") spelled++; }
        foreach (var key in MajorKeys)
        {
            var (ii, v) = (Spell(key, 2, 2), Spell(key, 7, 5));
            var c1 = Misspelled(Ask(skill, $"voice leading {ii}m7 to {v}7"), ii + "m7", v + "7");
            var c2 = Misspelled(Ask(skill, $"voice leading {v}7 to {key}maj7"), v + "7", key + "maj7");
            Count(c1); Count(c2);
            Row(w, key, c1, c2);
        }

        Title("Spelling: V7 to i in the 12 minor keys");
        Row(w, "key", "V7 to i");
        foreach (var key in MinorKeys)
        {
            var v = Spell(key, 7, 5);
            var c = Misspelled(Ask(skill, $"voice leading {v}7 to {key}m"), v + "7", key + "m");
            Count(c);
            Row(w, key + "m", c);
        }

        Line($"prompts {total}: every note spelled as in its chord {spelled}");
    }

    // ---- Other phrasings ----

    static readonly (string Prompt, string[] Asks)[] OtherPhrasings =
    [
        ("how do I get from G7 to a C chord", ["G7", "C"]),
        ("voice leading Dm7 to G7 to Cmaj7", ["Dm7", "G7", "Cmaj7"]),
        ("voice leading CM7 to FM7", ["Cmaj7", "Fmaj7"]),
        ("voice leading G7 → C", ["G7", "C"]),
        ("voice leading G7 - C", ["G7", "C"]),
        ("voice leading from G7 into C", ["G7", "C"]),
        ("voice leading from C to F#", ["C", "F#"]),
        ("voice leading from G to B°", ["G", "Bdim"]),
        ("smooth voice leading from C major to A minor", ["C", "Am"]),
        ("how do I voice lead Bb to Eb", ["Bb", "Eb"]),
    ];

    static void Phrasings(IOrchestratorSkill skill)
    {
        Title("Other phrasings");
        int[] w = [46, 22, 16];
        Row(w, "prompt", "asks", "reads", "verdict");
        foreach (var (prompt, asks) in OtherPhrasings)
        {
            var a = Ask(skill, prompt);
            var (from, to) = (asks[0], asks[1]);
            var verdict = a is null ? "declined"
                : !Reads(a, from, to) ? "wrong chord"
                : asks.Length > 2 ? $"reads 2 of {asks.Length} chords"
                : "right";
            Row(w, prompt, string.Join(" → ", asks), ReadAs(a, from, to), verdict);
        }
    }
}
