namespace GaAi;

using System.Numerics;
using System.Reflection;
using GA.Business.DSL.Parsers;
using GA.Business.DSL.Types;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Intents;
using GA.Business.ML.Agents.Skills;
using GA.Domain.Core.Theory.Atonal;
using Microsoft.Extensions.Logging.Abstractions;
using static Report;

// Lesson 24: SetTheoryEquivalenceSkill and GrothendieckParseSkill, asked directly. The first compares
// two pitch-class sets under transposition, inversion or both; the second sends an expression to GA's
// F# Grothendieck parser and names the case of the operation it gets back
public static class SetEquivalenceParseProbe
{
    public static (SetTheoryEquivalenceSkill Sets, GrothendieckParseSkill Parse) Skills() =>
        (new(), new(NullLogger<GrothendieckParseSkill>.Instance));

    static string Say(IOrchestratorSkill skill, string prompt) =>
        skill.ExecuteAsync(prompt).GetAwaiter().GetResult().Result;

    // ---- Reading the answers ----

    // The relation an equivalence answer applies and its verdict, from the verdict's first words
    // (SetTheoryEquivalenceSkill.cs lines 116-175): T for transposition, I for inversion, TI for
    // the set class
    static readonly (string Head, string Relation, bool Yes)[] Verdicts =
    [
        ("**Yes — equivalent under transposition.**", "T", true),
        ("**No — not equivalent under transposition alone.**", "T", false),
        ("**No — not transpositionally equivalent.**", "T", false),
        ("**Yes — equivalent under inversion", "I", true),
        ("**No — not equivalent under inversion.**", "I", false),
        ("**Yes — they belong to the same set class**", "TI", true),
        ("**No — they are Z-related.**", "TI", false),
        ("**No — they are not equivalent.**", "TI", false),
    ];

    sealed record Verdict(string Kind, string Relation, bool Yes, string Text)
    {
        public string Says => Kind == "answer" ? $"{(Yes ? "yes" : "no")}, {Relation}" : Kind;

        // "- **Set A** `0146` → ICV `<1 1 1 1 1 1>`, prime form `{0,1,4,6}`" gives ("0146", "{0,1,4,6}")
        public (string Text, string Prime) Set(string label)
        {
            var line = Text.Split('\n').First(l => l.StartsWith($"- **{label}**"));
            var parts = line.Split('`');
            return (parts[1], parts[5]);
        }
    }

    static Verdict Judge(string text)
    {
        if (text.StartsWith("I couldn't parse")) return new("can't parse", "", false, text);
        foreach (var (head, relation, yes) in Verdicts)
            if (text.Contains("\n" + head)) return new("answer", relation, yes, text);
        return new("declined", "", false, text);
    }

    // The case the parse skill names, or why it names none (GrothendieckParseSkill.cs lines 84-205)
    static string Case(string text) =>
        text.StartsWith("**Parsed**") ? text.Split("**AST category**: `")[1].Split('`')[0]
        : text.StartsWith("Couldn't parse") || text.StartsWith("The parser couldn't") ? "can't parse"
        : text.StartsWith("Expression") ? "rejected"
        : "declined";

    static string Says(IOrchestratorSkill skill, string prompt) =>
        skill is SetTheoryEquivalenceSkill ? Judge(Say(skill, prompt)).Says : Case(Say(skill, prompt));

    // ---- The example prompts ----

    public static void ExamplesTable(SetTheoryEquivalenceSkill sets, GrothendieckParseSkill parse, string where)
    {
        Title($"SetTheoryEquivalenceSkill's and GrothendieckParseSkill's example prompts, {where}");
        var hints = new DefaultRoutingHintProvider();
        int[] w = [72, 6, 18, 14];
        Row(w, "prompt", "skill", "its answer", "the other's", "routing hints, +0.06 each");
        // The doc comments and the refusals repeat the anchors; the parse failure also suggests
        // Transpose(Cmaj7) (GrothendieckParseSkill.cs line 177)
        var prompts = sets.ExamplePrompts.Select(p => (Prompt: p, Skill: "sets"))
            .Concat(parse.ExamplePrompts.Select(p => (Prompt: p, Skill: "parse")))
            .Append(("parse Transpose(Cmaj7)", "parse")).ToList();
        foreach (var (prompt, skill) in prompts)
        {
            var (own, other) = skill == "sets" ? ((IOrchestratorSkill)sets, (IOrchestratorSkill)parse) : (parse, sets);
            var hint = hints.GetDeltas(prompt).Keys.Order(StringComparer.Ordinal).ToList();
            Row(w, prompt, skill, Says(own, prompt), Says(other, prompt), hint.Count == 0 ? "none" : string.Join(", ", hint));
        }
        foreach (var (name, own, other, intent) in new (string, IOrchestratorSkill, IOrchestratorSkill, string)[]
                 {
                     ("SetTheoryEquivalenceSkill", sets, parse, "skill.settheoryequivalence"),
                     ("GrothendieckParseSkill", parse, sets, "skill.grothendieckparse"),
                 })
        {
            var anchors = own.ExamplePrompts;
            bool Answered(IOrchestratorSkill s, string p) => Says(s, p) is not ("declined" or "can't parse");
            Line($"{name}: anchors {anchors.Count}, answered {anchors.Count(p => Answered(own, p))}, " +
                 $"hinted toward {intent} {anchors.Count(p => hints.GetDeltas(p).ContainsKey(intent))}; " +
                 $"the other skill answers {anchors.Count(p => Answered(other, p))} of them; " +
                 $"CanHandle accepts {anchors.Count(own.CanHandle)}");
        }
    }

    // ---- The relation the equivalence skill reads ----

    static int Mask(string pcs) => pcs.Split(',').Aggregate(0, (m, p) => m | 1 << int.Parse(p));

    static string Text(int mask) => string.Join(",", Enumerable.Range(0, 12).Where(p => (mask >> p & 1) == 1));

    static int Rotate(int mask, int t) => ((mask << t) | (mask >> (12 - t))) & 0xFFF;

    static int Invert(int mask) =>
        Enumerable.Range(0, 12).Where(p => (mask >> p & 1) == 1).Aggregate(0, (m, p) => m | 1 << (12 - p) % 12);

    // Some transposition maps a onto b; some inversion followed by a transposition does
    static bool ByT(int a, int b) => Enumerable.Range(0, 12).Any(t => Rotate(a, t) == b);

    static bool ByTI(int a, int b) => ByT(Invert(a), b);

    // The right verdict for the relation a question names, as the skill defines them: "under
    // inversion" means transposition or inversion (lines 137-141)
    static bool Right(string relation, int a, int b) => relation == "T" ? ByT(a, b) : ByT(a, b) || ByTI(a, b);

    static readonly (string Name, string A, string B)[] Pairs =
    [
        ("inversion only", "0,1,3", "0,2,3"),
        ("transposition", "0,1,4", "1,2,5"),
        ("Z-related", "0,1,4,6", "0,1,3,7"),
        ("different", "0,1,4", "0,1,6"),
    ];

    // The relation each question names, in the words of the skill's anchors and its comments
    static readonly (string Template, string Relation)[] Phrasings =
    [
        ("are pitch classes {a} and {b} equivalent under transposition", "T"),
        ("are pitch classes {a} and {b} equivalent under inversion", "I"),
        ("are pitch classes {a} and {b} equivalent", "TI"),
        ("are {a} and {b} equivalent under transposition or inversion", "TI"),
        ("are {a} and {b} the same set class under transposition", "T"),
        ("are {a} and {b} the same set class under inversion", "I"),
        ("are {a} and {b} the same set class", "TI"),
        ("are {a} and {b} related by inversion", "I"),
        ("are {a} and {b} transpositionally equivalent", "T"),
        ("is {a} a transposition of {b}", "T"),
    ];

    static string Ask(string template, string a, string b) => template.Replace("{a}", a).Replace("{b}", b);

    public static void RelationTable(SetTheoryEquivalenceSkill sets, string where)
    {
        Title($"The relation SetTheoryEquivalenceSkill reads, {where}");
        Line("a pair's cell: the verdict, the relation it applies (T, I or TI), and \"wrong\" when the verdict");
        Line("is wrong for the relation the question names");
        int[] w = [62, 4, 20, 20, 20];
        Row(w, ["question", "asks", .. Pairs.Select(p => $"{p.A} | {p.B}")]);
        Row(w, ["", "", .. Pairs.Select(p => p.Name)]);
        foreach (var (template, relation) in Phrasings)
        {
            var cells = Pairs.Select(p =>
            {
                var v = Judge(Say(sets, Ask(template, p.A, p.B)));
                return v.Kind != "answer" ? v.Kind
                    : v.Says + (v.Yes == Right(relation, Mask(p.A), Mask(p.B)) ? "" : ", wrong");
            });
            Row(w, [Ask(template, "{a}", "{b}"), relation, .. cells]);
        }
    }

    // ---- Every pair of three-note and of four-note sets ----

    static readonly (string Template, string Relation)[] AllPairsPhrasings =
    [
        ("are pitch classes {a} and {b} equivalent under transposition", "T"),
        ("are {a} and {b} the same set class under transposition", "T"),
        ("are {a} and {b} the same set class under inversion", "I"),
        ("are {a} and {b} the same set class", "TI"),
    ];

    static IntervalClassVector Icv(int mask) => new PitchClassSet(Enumerable.Range(0, 12)
        .Where(p => (mask >> p & 1) == 1).Select(PitchClass.FromValue)).IntervalClassVector;

    public static void AllPairsTable(SetTheoryEquivalenceSkill sets, string where)
    {
        Title($"Every ordered pair of three-note and of four-note sets, asked of SetTheoryEquivalenceSkill, {where}");
        int[] w = [60, 5, 7, 7, 6];
        Row(w, "question", "size", "pairs", "right", "wrong", "what the wrong ones are");
        foreach (var size in new[] { 3, 4 })
        {
            var masks = Enumerable.Range(0, 4096).Where(m => BitOperations.PopCount((uint)m) == size).ToArray();
            var icv = masks.ToDictionary(m => m, Icv);
            foreach (var (template, relation) in AllPairsPhrasings)
            {
                int right = 0, wrong = 0, zSaid = 0, zTrue = 0, eitherSaid = 0, eitherNoInversion = 0;
                var kinds = new SortedDictionary<string, int>(StringComparer.Ordinal);
                foreach (var a in masks)
                foreach (var b in masks)
                {
                    var v = Judge(Say(sets, Ask(template, Text(a), Text(b))));
                    var truth = Right(relation, a, b);
                    if (v.Kind == "answer" && v.Yes == truth) right++;
                    else
                    {
                        wrong++;
                        var kind = v.Kind != "answer" ? v.Kind
                            : $"{(v.Yes ? "yes" : "no")} for {(ByT(a, b) ? "a transposition" : ByTI(a, b) ? "an inversion only" : "different classes")}";
                        kinds[kind] = kinds.GetValueOrDefault(kind) + 1;
                    }
                    if (v.Text.Contains("they are Z-related")) zSaid++;
                    if (icv[a].Equals(icv[b]) && !ByT(a, b) && !ByTI(a, b)) zTrue++;
                    if (v.Text.Contains("via either operation"))
                    {
                        eitherSaid++;
                        if (!ByTI(a, b)) eitherNoInversion++;
                    }
                }
                Row(w, Ask(template, "{a}", "{b}"), size, masks.Length * masks.Length, right, wrong,
                    kinds.Count == 0 ? "none" : string.Join("; ", kinds.Select(k => $"{k.Key} {k.Value}")));
                if (relation == "TI")
                    Line($"  Z-related pairs: the answer says so for {zSaid}, the vectors give {zTrue}");
                if (eitherSaid > 0)
                    Line($"  \"via either operation\": said for {eitherSaid} pairs, of which no inversion maps the first set onto the second for {eitherNoInversion}");
            }
        }
    }

    // ---- The sets the equivalence skill reads ----

    static readonly string[] Notations =
    [
        "0,1,4", "0, 1, 4", "0 1 4", "014", "[0,1,4]", "{0,1,4}", "(0,1,4)", "<0,1,4>", "0-1-4",
        "0,1,10", "0,10,11", "0,1,t", "0,1,T", "0,1,A", "0te", "01t", "0,1,12", "0,4,7,4", "3-3", "C,E,G",
    ];

    public static void NotationTable(SetTheoryEquivalenceSkill sets, string where)
    {
        Title($"The sets SetTheoryEquivalenceSkill reads, {where}");
        var tryParse = typeof(SetTheoryEquivalenceSkill).GetMethod("TryParseSet", BindingFlags.NonPublic | BindingFlags.Static)!;
        int[] w = [10, 18, 22];
        Row(w, "written", "TryParseSet", "in a question", "the answer's set A and its prime form");
        foreach (var written in Notations)
        {
            var built = (PitchClassSet?)tryParse.Invoke(null, [written]);
            var v = Judge(Say(sets, $"are pitch classes {written} and 0,1,6 equivalent"));
            var (text, prime) = v.Kind == "answer" ? v.Set("Set A") : ("", "");
            Row(w, written, built is null ? "(none)" : "{" + string.Join(",", built.Select(p => p.Value)) + "}",
                v.Kind == "answer" ? "answered" : v.Kind, v.Kind == "answer" ? $"`{text}` {prime}" : "");
        }
    }

    // ---- The prime forms the equivalence skill prints ----

    public static void PrimeFormTable(string where)
    {
        Title($"The prime forms SetTheoryEquivalenceSkill prints, {where}");
        var all = PitchClassSet.Items.ToList();
        var primes = all.Select(s => s.PrimeForm!).ToList();
        var stable = all.Count(s => Enumerable.Range(0, 12).All(t =>
            Equals(s.PrimeForm, new PitchClassSet(s.Select(p => PitchClass.FromValue((p.Value + t) % 12))).PrimeForm) &&
            Equals(s.PrimeForm, new PitchClassSet(s.Select(p => PitchClass.FromValue((12 - p.Value + t) % 12))).PrimeForm)));
        Line($"sets {all.Count}, distinct prime forms {primes.Distinct().Count()}, sets whose 24 transpositions and inversions all give the same prime form {stable}");
        var labels = Enumerable.Range(0, 13)
            .SelectMany(n => Enumerable.Range(1, 60).SelectMany(k => new[] { $"{n}-{k}", $"{n}-Z{k}" }))
            .Where(l => CanonicalForteCatalog.TryGetPrimeForm(l, out _)).ToList();
        var differ = labels.Where(l => CanonicalForteCatalog.TryGetPrimeForm(l, out var stored) && !stored.Equals(stored.PrimeForm)).ToList();
        var given = new HashSet<PitchClassSet>();
        foreach (var l in labels)
            if (CanonicalForteCatalog.TryGetPrimeForm(l, out var stored)) given.Add(stored);
        var missing = primes.Distinct().Count(p => !given.Contains(p));
        Line($"Forte labels CanonicalForteCatalog resolves {labels.Count}; whose stored set differs from its PrimeForm {differ.Count}" +
             (differ.Count == 0 ? "" : ": " + string.Join(", ", differ)) + $"; prime forms no label gives {missing}");
        var zIcvs = primes.Distinct().GroupBy(p => (p.Cardinality.Value, p.IntervalClassVector.ToString())).Count(g => g.Count() == 2);
        Line($"interval-class vectors shared by two prime forms of the same size (Z pairs) {zIcvs}");
    }

    // ---- The expressions the parse skill reads ----

    // One expression for each form the parser's comments name (GrothendieckOperationsParser.fs
    // lines 286-535 and 545-610), with the case each comment promises
    static readonly (string Expression, string Promised)[] Forms =
    [
        ("C ⊗ G", "TensorProduct"), ("C tensor G", "TensorProduct"), ("tensor(C, G)", "TensorProduct"),
        ("C ⊕ G", "DirectSum"), ("C direct_sum G", "DirectSum"), ("direct_sum(C, G)", "DirectSum"),
        ("C × G", "Product"), ("C product G", "Product"), ("product(C, G, F)", "Product"),
        ("C + G", "Coproduct"), ("C coproduct G", "Coproduct"), ("coproduct(C, G, F)", "Coproduct"),
        ("C ^ G", "Exponential"), ("exp(C, G)", "Exponential"),
        ("functor Transpose: Chords -> Chords", "DefineFunctor"), ("define functor Transpose { a -> invert }", "DefineFunctor"),
        ("Invert(C)", "ApplyFunctor"), ("apply Invert to C", "ApplyFunctor"),
        ("Transpose ∘ Invert", "ComposeFunctors"), ("Transpose compose Invert", "ComposeFunctors"), ("compose(Transpose, Invert)", "ComposeFunctors"),
        ("natural transformation eta: Transpose => Invert", "DefineNatTrans"), ("define nat_trans eta { C -> invert }", "DefineNatTrans"),
        ("eta(C)", "ApplyNatTrans"),
        ("limit of {C, G}", "Limit"), ("lim {C, G}", "Limit"),
        ("pullback(C, invert, G)", "Pullback"), ("pullback(C, transpose 7, G)", "Pullback"), ("C pullback invert", "Pullback"),
        ("equalizer(invert, reflect)", "Equalizer"), ("eq(invert, reflect)", "Equalizer"),
        ("colimit of {C, G}", "Colimit"), ("colim {C, G}", "Colimit"),
        ("pushout(C, invert, G)", "Pushout"), ("C pushout invert", "Pushout"),
        ("coequalizer(invert, reflect)", "Coequalizer"), ("coeq(invert, reflect)", "Coequalizer"),
        ("Ω", "SubobjectClassifier"), ("Ω(C)", "SubobjectClassifier"), ("truth_value of C", "SubobjectClassifier"),
        ("P(C)", "PowerObject"), ("power(C)", "PowerObject"), ("subobjects of C", "PowerObject"),
        ("Hom(C, G)", "InternalHom"), ("C => G", "InternalHom"),
        ("sheaf S on fretboard", "DefineSheaf"), ("define sheaf S { U -> C }", "DefineSheaf"),
        ("S | U", "SheafRestriction"), ("restrict S to U", "SheafRestriction"),
        ("glue { C, G }", "SheafGluing"),
    ];

    static string Parsed(string expression)
    {
        var result = GrothendieckOperationsParser.parse(expression);
        return result.IsOk ? result.ResultValue.GetType().Name : "fails";
    }

    public static void FormsTable(GrothendieckParseSkill parse, string where)
    {
        Title($"The expressions GrothendieckParseSkill reads, {where}");
        int[] w = [48, 20, 20];
        Row(w, "expression", "the comment's case", "the parser gives", "\"parse <expression>\" gets");
        foreach (var (expression, promised) in Forms)
            Row(w, expression, promised, Parsed(expression), Case(Say(parse, "parse " + expression)));
        var cases = typeof(GrammarTypes.GrothendieckOperation).GetNestedTypes()
            .Where(t => t.IsSubclassOf(typeof(GrammarTypes.GrothendieckOperation))).Select(t => t.Name).Order(StringComparer.Ordinal).ToList();
        var byParser = Forms.Select(f => Parsed(f.Expression)).Where(c => c != "fails").ToHashSet();
        var bySkill = Forms.Select(f => Case(Say(parse, "parse " + f.Expression))).ToHashSet();
        Line($"the operation's cases {cases.Count}; forms {Forms.Length}, parsed {Forms.Count(f => Parsed(f.Expression) != "fails")}, " +
             $"of which as their comment says {Forms.Count(f => Parsed(f.Expression) == f.Promised)}; " +
             $"\"parse <expression>\" answered for {Forms.Count(f => cases.Contains(Case(Say(parse, "parse " + f.Expression))))}");
        Line($"cases no form reaches through the parser: {string.Join(", ", cases.Where(c => !byParser.Contains(c)))}");
        Line($"cases no form reaches through the skill: {string.Join(", ", cases.Where(c => !bySkill.Contains(c)))}");
        // Some of the same forms without the spaces the parser doesn't skip
        Line("written without spaces: " + string.Join(", ", Respaced.Select(e => $"{e} {Parsed(e)}")));
        Line("two operators in a row: " + string.Join(", ", Chained.Select(e => $"{e} {Parsed(e)}")));
    }

    static readonly string[] Respaced = ["S|U", "eq(invert,reflect)", "equalizer((invert,reflect)", "coeq(invert,reflect)"];

    static readonly string[] Chained = ["C + G + F", "C ⊗ G ⊗ F", "Cmaj7 ⊕ Gmaj7 ⊕ Fmaj7"];

    // ---- The chords the parser reads, and the questions the skill reads ----

    static string Describe(GrammarTypes.MusicalObject obj) => obj switch
    {
        GrammarTypes.MusicalObject.ChordObject c => $"chord {Root(c.Item.Root)} {c.Item.Quality}",
        GrammarTypes.MusicalObject.NoteObject n => $"note {Root(n.Item)}",
        GrammarTypes.MusicalObject.ScaleObject s => $"scale {Root(s.Item.Root)} {s.Item.Name?.Value}",
        GrammarTypes.MusicalObject.SetClassObject s => $"set class [{string.Join(",", s.pitchClasses)}]",
        _ => obj.GetType().Name,
    };

    static string Root(GrammarTypes.Note note) => note.Letter + (note.Accidental?.Value.ToString() switch
    {
        null => "",
        "Sharp" => "#",
        "Flat" => "b",
        var other => " " + other,
    });

    static readonly string[] ChordTokens =
    [
        "C", "Bb", "F#", "Am", "Cm", "G7", "C7", "Dm7", "Cmaj7", "CM7", "Cmin7", "Cdom7", "Cmaj", "Cmin",
        "Cdim", "Cdim7", "C°", "Caug", "C+", "Csus4", "Cadd9", "C6/9", "Cm7b5", "Gmaj9", "C major", "PC{0,4,7}",
    ];

    static readonly string[] Questions =
    [
        "parse C ⊗ G", "Parse: C ⊗ G", "please parse C ⊗ G", "can you parse C ⊗ G", "parse C ⊗ G please",
        "what does C ⊗ G mean?", "explain C ⊗ G", "interpret Cmaj7 ⊕ Gmaj7", "meaning of C ⊗ G",
        "parse Am ⊗ G7", "parse Dm7 ⊕ G7", "parse C + G", "parse C × G", "parse C ^ G", "parse Ω",
        "explain the tensor product", "explain natural transformation", "what is a pullback", "what is the tensor product of C and G",
    ];

    public static void ChordsTable(GrothendieckParseSkill parse, string where)
    {
        Title($"The chords GA's Grothendieck parser reads, {where}");
        int[] w = [12];
        Row(w, "written", "what \"<written> ⊗ G\" parses into, on the left of ⊗");
        foreach (var token in ChordTokens)
        {
            var result = GrothendieckOperationsParser.parse(token + " ⊗ G");
            Row(w, token, result.IsOk && result.ResultValue is GrammarTypes.GrothendieckOperation.TensorProduct t ? Describe(t.Item1) : "fails");
        }
        var cg = Say(parse, "parse C ⊗ G").Replace("C ⊗ G", "<e>");
        var other = Say(parse, "parse F# ⊗ Bb").Replace("F# ⊗ Bb", "<e>");
        Line($"\"parse C ⊗ G\" and \"parse F# ⊗ Bb\" give the same answer apart from the expression they repeat: {(cg == other ? "yes" : "no")}");

        Title($"The questions GrothendieckParseSkill reads, {where}");
        int[] q = [40, 20];
        Row(q, "question", "the skill says", "the expression it parses");
        foreach (var question in Questions)
        {
            var text = Say(parse, question);
            var expression = text.StartsWith("**Parsed**: `") || text.StartsWith("Couldn't parse `")
                ? text.Split('`')[1] : "";
            Row(q, question, Case(text), expression);
        }
    }
}
