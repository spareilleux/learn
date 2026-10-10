namespace GaAi;

using System.Reflection;
using System.Text.RegularExpressions;
using GA.Business.Config;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Skills;
using Microsoft.Extensions.Logging.Abstractions;
using static Report;

// Lesson 26: modes. ModesSkill answers "what is Lydian dominant?" or "modes of harmonic minor" from
// Modes.yaml, through ModesConfig.GetModalFamilies, and works out each mode's formula from its notes.
// Neither the skill nor the catalog changed on GA's main. The program checks each mode against its
// family's first mode, the formulas against a textbook's, the names ModesConfig reads against the
// ones Modes.yaml writes, and asks the skill for each mode by its own name.
public static class Lesson26
{
    static readonly MethodInfo TonalFamilies =
        typeof(ModesSkill).GetMethod("GetTonalModalFamilies", BindingFlags.NonPublic | BindingFlags.Static)!;
    static readonly MethodInfo FormulaOf =
        typeof(ModesSkill).GetMethod("ComputeFormulaFromNotes", BindingFlags.NonPublic | BindingFlags.Static)!;

    // The families the skill answers from: Modes.yaml's, without those whose name contains
    // "Chord Family" or "Triad Family"
    static IReadOnlyList<ModesConfig.ModalFamilyInfo> Families() =>
        (IReadOnlyList<ModesConfig.ModalFamilyInfo>)TonalFamilies.Invoke(null, null)!;

    static string SkillFormula(string notes) => (string)FormulaOf.Invoke(null, [notes])!;

    static string Label(ModesConfig.ModalFamilyInfo f) => f.Name.Replace(" Family", "");

    public static void Run()
    {
        var skill = new ModesSkill(NullLogger<ModesSkill>.Instance);
        var families = Families();
        Catalog(families);
        Formulas(families);
        Answers(skill);
        Written();
        Names(skill, families);
        Examples(skill);
    }

    // ---- Notes ----

    const string Letters = "CDEFGAB";
    static readonly int[] Natural = [0, 2, 4, 5, 7, 9, 11];

    // "Bbb" -> letter B, two flats; null for anything else
    static (int Letter, int Acc)? Parse(string token)
    {
        var letter = token.Length > 0 ? Letters.IndexOf(token[0]) : -1;
        int? acc = token[1..] switch { "" => 0, "#" => 1, "##" => 2, "b" => -1, "bb" => -2, _ => null };
        return letter < 0 || acc is null ? null : (letter, acc.Value);
    }

    static string[] Tokens(string notes) => notes.Split(' ', StringSplitOptions.RemoveEmptyEntries);

    static int Pc((int Letter, int Acc) n) => ((Natural[n.Letter] + n.Acc) % 12 + 12) % 12;

    static int[] Pcs(string notes) => [.. Tokens(notes).Select(t => Pc(Parse(t)!.Value))];

    static string Acc(int acc) => acc switch { -2 => "bb", -1 => "b", 0 => "", 1 => "#", 2 => "##", _ => "?" };

    // A formula read from the letters: on C, a note on the letter E is a third, whatever its
    // accidental, so C D E G A is 1 2 3 5 6
    static string LetterFormula(string notes) =>
        string.Join(" ", Tokens(notes).Select(t => Parse(t)!.Value).Select(n => Acc(n.Acc) + (n.Letter + 1)));

    // A seven-note scale's formula has each degree once: the notes in ascending order are 1 to 7
    static string DegreeFormula(int[] pcs) =>
        string.Join(" ", pcs.Order().Select((p, i) => Acc(((p - Natural[i] + 6) % 12 + 12) % 12 - 6) + (i + 1)));

    // A textbook's formula: by degree for seven notes, from the note names for any other number
    static string Textbook(string notes) => Pcs(notes).Length == 7 ? DegreeFormula(Pcs(notes)) : LetterFormula(notes);

    // ---- A textbook's parent scales, in semitones above C ----

    static readonly Dictionary<string, int[]> Parents = new()
    {
        ["Major Scale"] = [0, 2, 4, 5, 7, 9, 11],
        ["Harmonic Minor"] = [0, 2, 3, 5, 7, 8, 11],
        ["Melodic Minor"] = [0, 2, 3, 5, 7, 9, 11],
        ["Major Pentatonic"] = [0, 2, 4, 7, 9],
        ["Whole Tone"] = [0, 2, 4, 6, 8, 10],
        ["Diminished"] = [0, 1, 3, 4, 6, 7, 9, 10],
        ["Blues Scale"] = [0, 3, 5, 6, 7, 10],
        ["Chromatic"] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
        ["Perfect Fourth"] = [0, 5],
        ["Major Third"] = [0, 4],
        ["Minor Third"] = [0, 3],
        ["Major Second"] = [0, 2],
        ["Minor Second"] = [0, 1],
        ["All Interval Tetrachord"] = [0, 1, 4, 6],
        ["Harmonic Major"] = [0, 2, 4, 5, 7, 8, 11],
        ["Double Harmonic"] = [0, 1, 4, 5, 7, 8, 11],
        ["Neapolitan Minor"] = [0, 1, 3, 5, 7, 8, 11],
        ["Neapolitan Major"] = [0, 1, 3, 5, 7, 9, 11],
        ["Dominant Bebop"] = [0, 2, 4, 5, 7, 9, 10, 11],
        ["Major Bebop"] = [0, 2, 4, 5, 7, 8, 9, 11],
        ["Prometheus"] = [0, 2, 4, 6, 9, 10],
        ["Enigmatic"] = [0, 1, 4, 6, 8, 10, 11],
        ["Hungarian Major"] = [0, 3, 4, 6, 7, 9, 10],
        ["Hirajoshi"] = [0, 2, 3, 7, 8],
        ["In Sen"] = [0, 1, 5, 7, 10],
        ["Diminished (Octatonic)"] = [0, 2, 3, 5, 6, 8, 9, 11],
        ["Augmented (Hexatonic)"] = [0, 3, 4, 7, 8, 11],
    };

    // The scale that starts on degree k (1-based) of `scale`, in semitones above its new first note
    static int[] Rotation(int[] scale, int k) =>
        [.. scale.Select(p => ((p - scale[k - 1]) % 12 + 12) % 12).Order()];

    // The degree of `scale` that `mode` starts on, or 0 when it starts on none
    static int DegreeOf(int[] scale, int[] mode) =>
        Enumerable.Range(1, scale.Length).FirstOrDefault(k => Rotation(scale, k).SequenceEqual(mode.Order()));

    // A seven-note scale spelled one letter per degree, the way a textbook writes it on C
    static string Spell(int[] scale) => scale.Length == 7
        ? string.Join(" ", scale.Select((p, i) => Letters[i] + Acc(((p - Natural[i] + 6) % 12 + 12) % 12 - 6)))
        : "semitones " + Ints(scale);

    // ---- The catalog ----

    static void Catalog(IReadOnlyList<ModesConfig.ModalFamilyInfo> families)
    {
        Title("The families ModesSkill answers from, and whether mode k is the parent scale from its degree k");
        int[] w = [24, 6, 6, 10, 19];
        Row(w, "family", "modes", "notes", "mode 1", "mode k on degree k", "the modes that aren't");
        var off = new List<string>();
        int modes = 0, fromDegree = 0, otherDegree = 0, none = 0, unordered = 0;
        foreach (var f in families)
        {
            var label = Label(f);
            var first = Pcs(f.Modes[0].Notes);
            var problems = new List<string>();
            var own = 0;
            for (var k = 1; k <= f.Modes.Count; k++)
            {
                var m = f.Modes[k - 1];
                var pcs = Pcs(m.Notes);
                modes++;
                var issues = new List<string>();
                if (Rotation(first, k).SequenceEqual(pcs.Order())) { fromDegree++; own++; }
                else if (DegreeOf(first, pcs) is var d and > 0) { otherDegree++; issues.Add($"mode 1 from degree {d}"); }
                else { none++; issues.Add($"mode 1 from no degree; from degree {k}: {Spell(Rotation(first, k))}"); }
                if (!pcs.SequenceEqual(pcs.Order())) { unordered++; issues.Add("notes out of order"); }
                if (issues.Count > 0)
                {
                    problems.Add(k.ToString());
                    off.Add($"  {label} {k}, {m.Name}: {m.Notes}; {string.Join("; ", issues)}");
                }
            }
            var sizes = string.Join("/", f.Modes.Select(m => Pcs(m.Notes).Length).Distinct());
            Row(w, label, f.Modes.Count, sizes, first.SequenceEqual(Parents[label]) ? "textbook" : "other",
                $"{own} of {f.Modes.Count}", problems.Count == 0 ? "-" : string.Join(", ", problems));
        }

        var left = ModesConfig.GetModalFamilies().Where(a => families.All(f => f.Name != a.Name)).Select(a => a.Name).ToList();
        Line($"families {families.Count}; Modes.yaml's that the skill leaves out {left.Count}: {string.Join(", ", left)}");
        Line($"modes {modes}: mode 1 from their own degree {fromDegree}, from another degree {otherDegree}, " +
             $"from no degree {none}; notes out of order {unordered}");
        Line("the modes that aren't:");
        foreach (var o in off) Line(o);
    }

    // ---- Formulas ----

    static void Formulas(IReadOnlyList<ModesConfig.ModalFamilyInfo> families)
    {
        Title("Each mode's formula: the one ModesSkill computes from the notes by position, and a textbook's");
        int[] w = [6, 6, 13, 15];
        Row(w, "notes", "modes", "the skill's", "the letters'", "the first of the skill's that differs: notes, the skill's formula, a textbook's");
        var all = families.SelectMany(f => f.Modes.Select(m => (Family: f, Mode: m))).ToList();
        int same = 0, letters = 0;
        foreach (var g in all.GroupBy(x => Pcs(x.Mode.Notes).Length).OrderBy(g => g.Key))
        {
            var differ = g.Where(x => SkillFormula(x.Mode.Notes) != Textbook(x.Mode.Notes)).ToList();
            // Below or above seven notes, a textbook's formula is the letters' by definition
            var byLetters = g.Count(x => LetterFormula(x.Mode.Notes) == Textbook(x.Mode.Notes));
            same += g.Count() - differ.Count;
            if (g.Key == 7) letters = byLetters;
            var ex = differ.FirstOrDefault();
            Row(w, g.Key, g.Count(), $"{g.Count() - differ.Count} right", g.Key == 7 ? $"{byLetters} right" : "-",
                ex.Mode is null ? "-" : $"{ex.Mode.Name}: {ex.Mode.Notes}; `{SkillFormula(ex.Mode.Notes)}`, `{Textbook(ex.Mode.Notes)}`");
        }
        Line($"modes {all.Count}: the skill's formula is a textbook's {same}; " +
             $"of the {all.Count(x => Pcs(x.Mode.Notes).Length == 7)} seven-note modes, a formula read from the letters would be {letters}");
        Line("the seven-note modes whose letters give another formula than their degrees:");
        foreach (var x in all.Where(x => Pcs(x.Mode.Notes).Length == 7 && LetterFormula(x.Mode.Notes) != Textbook(x.Mode.Notes)))
            Line($"  {x.Mode.Name}: {x.Mode.Notes}; letters `{LetterFormula(x.Mode.Notes)}`, degrees `{Textbook(x.Mode.Notes)}`");
        Line("the seven-note modes whose formulas differ:");
        foreach (var x in all.Where(x => Pcs(x.Mode.Notes).Length == 7 && SkillFormula(x.Mode.Notes) != Textbook(x.Mode.Notes)))
            Line($"  {x.Mode.Name}: {x.Mode.Notes}; `{SkillFormula(x.Mode.Notes)}`, `{Textbook(x.Mode.Notes)}`");
        Line("the other differences, one per family:");
        foreach (var x in all.Where(x => Pcs(x.Mode.Notes).Length != 7 && SkillFormula(x.Mode.Notes) != Textbook(x.Mode.Notes))
                     .GroupBy(x => x.Family.Name).Select(g => g.First()))
            Line($"  {x.Mode.Name}: {x.Mode.Notes}; `{SkillFormula(x.Mode.Notes)}`, `{Textbook(x.Mode.Notes)}`");
    }

    // ---- A few answers in full ----

    static void Answers(IOrchestratorSkill skill)
    {
        Title("A few of ModesSkill's answers, first line");
        foreach (var p in (string[])["What is Ultralocrian?", "What is Altered?", "What is Major Locrian?",
                     "What is Major Pentatonic?", "What is Dominant Bebop?", "What is Perfect Fourth?"])
        {
            Line(p);
            Line("  | " + FirstLine(skill, p));
        }
    }

    // ---- Each mode by its name ----

    static readonly Regex SingleMode = new(@"^\*\*(?<mode>.+?)\*\* is mode (?<degree>\d+) of the \*\*(?<family>.+?)\*\* family");
    static readonly Regex OneFamily = new(@"^The \*\*(?<family>.+?)\*\* family has");

    static string FirstLine(IOrchestratorSkill skill, string prompt) =>
        skill.ExecuteAsync(prompt).GetAwaiter().GetResult().Result.ReplaceLineEndings("\n").Split('\n')[0];

    // What a first line answers: "mode Lydian (Major Scale 4)", "family Harmonic Minor", or the line
    static string Answered(string line) =>
        SingleMode.Match(line) is { Success: true } m ? $"{m.Groups["mode"].Value} ({m.Groups["family"].Value} {m.Groups["degree"].Value})"
        : OneFamily.Match(line) is { Success: true } f ? $"the {f.Groups["family"].Value} family"
        : line;

    // A mode's name as Modes.yaml writes it: "      - Name: Lydian #6", without its quotes
    static readonly Regex YamlModeName = new(@"^      - Name: (?<name>.+)$");

    static void Written()
    {
        Title("The mode names Modes.yaml writes, and the names ModesConfig reads: the ones that differ");
        var written = File.ReadLines(Path.Combine(AppContext.BaseDirectory, "Modes.yaml"))
            .Select(l => YamlModeName.Match(l)).Where(m => m.Success)
            .Select(m => m.Groups["name"].Value.Trim().Trim('\'', '"')).ToList();
        var read = ModesConfig.GetModalFamilies().SelectMany(f => f.Modes.Select(m => m.Name)).ToList();
        int[] w = [34];
        Row(w, "written", "read");
        foreach (var (a, b) in written.Zip(read).Where(x => x.First != x.Second))
            Row(w, a, b);
        Line($"mode names written {written.Count}, read {read.Count}, " +
             $"read otherwise than written {written.Zip(read).Count(x => x.First != x.Second)}");
    }

    static void Names(IOrchestratorSkill skill, IReadOnlyList<ModesConfig.ModalFamilyInfo> families)
    {
        Title("\"What is <name>?\" for each mode's name and alternate names: the modes ModesSkill answers with another");
        int[] w = [32, 49];
        Row(w, "asked", "the mode named", "answered");
        var counts = new int[4];
        var accepted = new int[2];
        foreach (var f in families)
            for (var k = 1; k <= f.Modes.Count; k++)
            {
                var m = f.Modes[k - 1];
                var own = $"{m.Name} ({Label(f)} {k})";
                foreach (var (name, isAlt) in m.AlternateNames.Select(a => (a, true)).Prepend((m.Name, false)))
                {
                    var prompt = $"What is {name}?";
                    if (skill.CanHandle(prompt)) accepted[isAlt ? 1 : 0]++;
                    var answer = Answered(FirstLine(skill, prompt));
                    var i = isAlt ? 2 : 0;
                    if (answer == own) { counts[i]++; continue; }
                    counts[i + 1]++;
                    Row(w, prompt, own, answer);
                }
            }

        Line($"mode names {counts[0] + counts[1]}: answered with their mode {counts[0]}, with another {counts[1]}, CanHandle accepts {accepted[0]}; " +
             $"alternate names {counts[2] + counts[3]}: answered with their mode {counts[2]}, with another {counts[3]}, CanHandle accepts {accepted[1]}");
    }

    // ---- The example prompts ----

    static void Examples(IOrchestratorSkill skill)
    {
        Title("ModesSkill's example prompts: what the first line of the answer is about");
        int[] w = [44, 10];
        Row(w, "prompt", "CanHandle", "answer");
        foreach (var p in skill.ExamplePrompts)
        {
            var a = Answered(FirstLine(skill, p));
            Row(w, p, skill.CanHandle(p) ? "yes" : "no", a.Length > 70 ? a[..69] + "…" : a);
        }
        Line($"example prompts {skill.ExamplePrompts.Count}: CanHandle accepts {skill.ExamplePrompts.Count(skill.CanHandle)}");
    }
}
