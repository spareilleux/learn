using System.Reflection;
using System.Runtime.ExceptionServices;
using System.Text.RegularExpressions;
using GA.Business.AI.Interpretation;
using GA.Business.Config;
using GA.Domain.Core.Theory.Atonal;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;
using static GaTheory.Report;

namespace GaTheory;

// Lesson 17 of the course, run as `l19`: the neo-Riemannian transformations P, L and R, the three GA's catalogue composes
// from them, its hexatonic and octatonic cycles, the Tonnetz and the graph of the 24 triads, the mediants, and GA's two
// other pieces on the subject, SemanticAnalysisService and the TonnetzDiagram component
public static class Lesson19
{
    // ---- The course's side

    // The usual spelling of the roots of the 12 major and of the 12 minor triads
    static readonly string[] MajorRoots = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];
    static readonly string[] MinorRoots = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "G#", "A", "Bb", "B"];
    static readonly string[] Members = ["root", "third", "fifth"];

    static string Pretty(string notes) => notes.Replace("#", "♯").Replace("b", "♭");

    // A consonant triad: a root and a quality
    public readonly record struct Triad(int Root, bool Major)
    {
        public int[] Notes => [Root, Theory.Mod12(Root + (Major ? 4 : 3)), Theory.Mod12(Root + 7)];

        public int Id => Theory.SetId(Notes);

        string RootName => (Major ? MajorRoots : MinorRoots)[Root];

        // root, third and fifth, on every other letter
        public string[] Spelled => [RootName, Theory.Spell(RootName, 3, Major ? 4 : 3), Theory.Spell(RootName, 5, 7)];

        public string Name => Pretty(RootName) + (Major ? "" : "m");

        // The triad's name in GA's NeoRiemannian.yaml, which writes every root with a sharp
        public string GaName => $"{Theory.PcName(Root)}_{(Major ? "maj" : "min")}";

        public string NoteOf(int pc) => Pretty(Spelled[Array.IndexOf(Notes, Theory.Mod12(pc))]);

        public string Member(int pc) => Members[Array.IndexOf(Notes, Theory.Mod12(pc))];
    }

    static readonly Triad[] Triads = [.. Enumerable.Range(0, 12).SelectMany(root => new[] { new Triad(root, true), new Triad(root, false) })];
    static readonly Dictionary<int, Triad> ById = Triads.ToDictionary(t => t.Id);
    static readonly Triad C = new(0, true);

    // P, L and R each keep two notes of the triad and move the third to the only other note that makes a major or minor
    // triad with them, its mirror image about the two kept notes. P keeps the perfect fifth (interval class 5), L the
    // minor third (3) and R the major third (4) (Wikipedia, "Neo-Riemannian theory")
    static Triad Flip(Triad t, int keptIntervalClass)
    {
        var n = t.Notes;
        for (var i = 0; i < 3; i++)
        {
            var (a, b) = (n[(i + 1) % 3], n[(i + 2) % 3]);
            if (Theory.IntervalClass(a - b) == keptIntervalClass) return ById[Theory.SetId([a, b, a + b - n[i]])];
        }
        throw new InvalidOperationException($"{t.Name} has no interval class {keptIntervalClass}");
    }

    static readonly (char Name, int Kept)[] Basic = [('P', 5), ('L', 3), ('R', 4)];

    static int Kept(char name) => Basic.First(b => b.Name == name).Kept;

    // A word is read from left to right: "LP" is L, then P
    static Triad Apply(Triad t, string word) => word.Aggregate(t, (x, name) => Flip(x, Kept(name)));

    static string Reversed(string word) => string.Concat(Enumerable.Reverse(word));

    // How many times the word must be applied to bring every triad back
    static int Order(string word) =>
        Enumerable.Range(1, 24).First(n => Triads.All(t => Enumerable.Range(0, n).Aggregate(t, (x, _) => Apply(x, word)) == t));

    static int CommonTones(Triad a, Triad b) => a.Notes.Intersect(b.Notes).Count();

    // The smallest total movement, in semitones, that takes the three notes of one triad to the three notes of the other
    static readonly int[][] Pairings = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]];

    static int Movement(Triad a, Triad b) =>
        Pairings.Min(p => Enumerable.Range(0, 3).Sum(i => Theory.IntervalClass(a.Notes[i] - b.Notes[p[i]])));

    // Breadth-first search over P, L and R: a shortest word from the start to each of the 24 triads
    static Dictionary<Triad, string> Words(Triad start)
    {
        var words = new Dictionary<Triad, string> { [start] = "" };
        var queue = new Queue<Triad>([start]);
        while (queue.Count > 0)
        {
            var t = queue.Dequeue();
            foreach (var (name, kept) in Basic)
            {
                var next = Flip(t, kept);
                if (words.TryAdd(next, words[t] + name)) queue.Enqueue(next);
            }
        }
        return words;
    }

    // Alternate the letters of a word from a triad until it comes back
    static List<Triad> Cycle(Triad start, string word)
    {
        var visited = new List<Triad> { start };
        for (var i = 0; ; i++)
        {
            var next = Flip(visited[^1], Kept(word[i % word.Length]));
            if (next == start) return visited;
            visited.Add(next);
        }
    }

    static string Spread(IEnumerable<int> values)
    {
        var list = values.ToList();
        return list.Min() == list.Max() ? $"{list.Min()}" : $"{list.Min()} to {list.Max()}";
    }

    static string PcNames(IEnumerable<int> pcs) => Pretty(string.Join(" ", pcs.Order().Select(Theory.PcName)));

    // ---- GA's side

    static readonly Dictionary<int, PitchClassSet> GaSets = PitchClassSet.Items.ToDictionary(set => set.Id.Value);
    static readonly Dictionary<string, Triad> ByGaName = Triads.ToDictionary(t => t.GaName);

    // NeoRiemannianConfig.Apply returns an F# option: None is null on this side
    static string? Loader(string transform, string triad) => NeoRiemannianConfig.Apply(transform, triad)?.Value;

    // Added after the first run, where GA's loader returned nothing: the shape of NeoRiemannian.yaml as NeoRiemannianConfig.fs
    // declares it (lines 42-57), with public types, read by the deserializer GA builds (lines 71-75)
    public sealed class TransformYaml
    {
        public string Description { get; set; } = "";
        public int VoiceLeadingCost { get; set; }
        public Dictionary<string, string> Mappings { get; set; } = [];
    }

    public sealed class CycleYaml
    {
        public string Name { get; set; } = "";
        public List<string> Triads { get; set; } = [];
    }

    public sealed class NeoRiemannianYaml
    {
        public Dictionary<string, TransformYaml> Transforms { get; set; } = [];
        public List<CycleYaml> HexatonicCycles { get; set; } = [];
        public List<CycleYaml> OctatonicCycles { get; set; } = [];
    }

    static readonly string YamlPath = Path.Combine(AppContext.BaseDirectory, "NeoRiemannian.yaml");

    static readonly NeoRiemannianYaml Yaml = new DeserializerBuilder()
        .WithNamingConvention(PascalCaseNamingConvention.Instance)
        .IgnoreUnmatchedProperties()
        .Build()
        .Deserialize<NeoRiemannianYaml>(File.ReadAllText(YamlPath));

    // The image of a triad under a transform of the file, as the course reads it
    static Triad? InFile(string transform, Triad t) =>
        Yaml.Transforms.TryGetValue(transform, out var entry) && entry.Mappings.TryGetValue(t.GaName, out var name) && ByGaName.TryGetValue(name, out var image)
            ? image
            : null;

    static string Access(MethodBase? method) => method switch
    {
        null => "none",
        { IsPublic: true } => "public",
        { IsAssembly: true } => "internal",
        { IsPrivate: true } => "private",
        _ => "other",
    };

    // SemanticAnalysisService names its triads "C major", "D# minor"
    static Triad? Named(string text)
    {
        var parts = text.Split(' ');
        if (parts.Length != 2 || parts[1] is not ("major" or "minor")) return null;
        return new Triad(Theory.PitchClassOf(parts[0].Replace("♯", "#")), parts[1] == "major");
    }

    static NeoRiemannianResult? Service(char name, PitchClassSet set, int root) => name switch
    {
        'P' => SemanticAnalysisService.ApplyParallel(set, PitchClass.FromValue(root)),
        'L' => SemanticAnalysisService.ApplyLeadingtone(set, PitchClass.FromValue(root)),
        _ => SemanticAnalysisService.ApplyRelative(set, PitchClass.FromValue(root)),
    };

    static NeoRiemannianResult? Service(char name, Triad t) => Service(name, GaSets[t.Id], t.Root);

    static string Explain(int[] source, int sourceRoot, int[] target, int targetRoot) =>
        SemanticAnalysisService.ExplainTriadRelationship(
            GaSets[Theory.SetId(source)], PitchClass.FromValue(sourceRoot), GaSets[Theory.SetId(target)], PitchClass.FromValue(targetRoot));

    // The centre of a cell of TonnetzDiagram.tsx, in cells (lines 27-30): four cells to a row, every other row pushed half
    // a cell to the right. `sheared` pushes each row half a cell further than the one above it, as a Tonnetz does
    static (double X, double Y) Centre(int index, bool sheared)
    {
        var (row, col) = (index / 4, index % 4);
        return (col + 0.5 + (sheared ? row : row % 2) * 0.5, row * 0.866 + 0.5);
    }

    // The pairs of cells whose centres lie one cell apart, by the interval class between their notes
    static string Neighbours(string[] cells, bool sheared)
    {
        var pairs = (
            from i in Enumerable.Range(0, cells.Length)
            from j in Enumerable.Range(i + 1, cells.Length - i - 1)
            let a = Centre(i, sheared)
            let b = Centre(j, sheared)
            where Math.Abs(Math.Sqrt((a.X - b.X) * (a.X - b.X) + (a.Y - b.Y) * (a.Y - b.Y)) - 1) < 0.01
            select (A: cells[i], B: cells[j], Class: Theory.IntervalClass(Theory.PitchClassOf(cells[i]) - Theory.PitchClassOf(cells[j])))).ToList();
        var counts = string.Join(", ", pairs.GroupBy(p => p.Class).OrderByDescending(g => g.Key).Select(g => $"interval class {g.Key}: {g.Count()}"));
        var outside = pairs.Where(p => p.Class is not (3 or 4 or 5)).Select(p => Pretty($"{p.A}-{p.B}")).ToList();
        return $"{pairs.Count} pairs of neighbours; {counts}; outside the Tonnetz's three: {(outside.Count == 0 ? "none" : string.Join(", ", outside))}";
    }

    public static void Run()
    {
        // Added after the first run. GA's loader catches every exception and returns three empty lists (NeoRiemannianConfig.fs,
        // lines 122-123), and it loads once: listen to the exceptions thrown during that first load, to see what it swallows
        _ = Yaml; // the course's own read of the file comes first, so that the listener hears GA's loader alone
        var swallowed = new List<Exception>();
        void Listen(object? sender, FirstChanceExceptionEventArgs e) => swallowed.Add(e.Exception);
        AppDomain.CurrentDomain.FirstChanceException += Listen;
        var loaded = NeoRiemannianConfig.GetAllTransforms().ToList();
        AppDomain.CurrentDomain.FirstChanceException -= Listen;

        // ---- 1. P, L and R

        Title("P, L and R keep two notes of a triad and move the third to its mirror image about them: the course's three, from C major and from C minor");
        Line($"{"triad",-6} {"op",-3} {"keeps",-7} {"moves",-13} {"gives",-6} notes");
        foreach (var t in new[] { C, new Triad(0, false) })
        {
            foreach (var (name, kept) in Basic)
            {
                var image = Flip(t, kept);
                var from = t.Notes.Except(image.Notes).Single();
                var to = image.Notes.Except(t.Notes).Single();
                var step = Theory.Mod12(to - from);
                if (step > 6) step -= 12;
                var keeps = string.Join(" ", t.Notes.Intersect(image.Notes).Select(t.NoteOf));
                Line($"{t.Name,-6} {name,-3} {keeps,-7} {$"{t.NoteOf(from)} to {image.NoteOf(to)} ({step:+0;-0})",-13} {image.Name,-6} {Pretty(string.Join(" ", image.Spelled))}");
            }
        }

        Title("The 24 triads through P, L and R: the course against NeoRiemannianConfig.Apply, against NeoRiemannian.yaml as the course reads it, and against SemanticAnalysisService (GA.Business.AI)");
        Line($"{"op",-3} {"= Apply",-9} {"= file",-9} {"= service",-10} {"undone by itself",-17} {"common tones",-13} movement");
        foreach (var (name, kept) in Basic)
        {
            var apply = Triads.Count(t => Loader(name.ToString(), t.GaName) == Flip(t, kept).GaName);
            var inFile = Triads.Count(t => InFile(name.ToString(), t) == Flip(t, kept));
            var service = Triads.Count(t => Service(name, t) is { } r && Named(r.TargetTriad) == Flip(t, kept));
            var undone = Triads.Count(t => Flip(Flip(t, kept), kept) == t);
            Line($"{name,-3} {$"{apply} of 24",-9} {$"{inFile} of 24",-9} {$"{service} of 24",-10} {$"{undone} of 24",-17} {Spread(Triads.Select(t => CommonTones(t, Flip(t, kept)))),-13} {Spread(Triads.Select(t => Movement(t, Flip(t, kept))))}");
        }

        Title("SemanticAnalysisService on C major: the record each of its three methods returns");
        foreach (var (name, _) in Basic)
        {
            var r = Service(name, C)!;
            Line($"{r.Operation}: {r.SourceTriad} -> {r.TargetTriad}, CommonTones {r.CommonTones}. {r.Explanation}");
        }

        Title("SemanticAnalysisService on a root that is not the triad's, and on sets that are not major or minor triads");
        foreach (var (label, pcs, root) in new (string, int[], int)[]
        {
            ("C E G with the root C", [0, 4, 7], 0), ("C E G with the root E", [0, 4, 7], 4), ("C E G# with the root C", [0, 4, 8], 0),
            ("C Eb Gb with the root C", [0, 3, 6], 0), ("C E G B with the root C", [0, 4, 7, 11], 0), ("C E with the root C", [0, 4], 0),
        })
        {
            var set = GaSets[Theory.SetId(pcs)];
            Line($"{Pretty(label),-26} {string.Join(", ", Basic.Select(b => $"{b.Name} {Service(b.Name, set, root)?.TargetTriad ?? "(null)"}"))}");
        }

        // ---- 2. GA's catalogue, through its loader

        Title($"NeoRiemannianConfig (GA.Business.Config), which loads NeoRiemannian.yaml: GetAllTransforms returns {loaded.Count} transforms, " +
            $"GetHexatonicCycles {NeoRiemannianConfig.GetHexatonicCycles().Count()} cycles, GetOctatonicCycles {NeoRiemannianConfig.GetOctatonicCycles().Count()}");
        foreach (var transform in loaded)
        {
            Line($"{transform.Name,-5} {transform.Mappings.Count,-9} {transform.VoiceLeadingCost,-5} {transform.Description}");
        }
        foreach (var (transform, triad) in new[] { ("P", "C_maj"), ("L", "G#_maj"), ("S", "C_maj"), ("P", "Db_maj"), ("p", "C_maj"), ("PL", "C_maj") })
        {
            Line($"Apply(\"{transform}\", \"{triad}\") -> {Loader(transform, triad) ?? "(none)"}");
        }
        Line(string.Join("; ", new[] { "H", "h", "PL" }.Select(name => $"TryGetTransform(\"{name}\") -> {NeoRiemannianConfig.TryGetTransform(name)?.Value.Name ?? "(none)"}")));

        Title($"Added after the first run: the exceptions thrown while NeoRiemannianConfig loaded its file, which its loader catches: {swallowed.Count}");
        foreach (var exception in swallowed)
        {
            for (var e = exception; e is not null; e = e.InnerException)
            {
                Line($"{(ReferenceEquals(e, exception) ? "" : "  inner: ")}{e.GetType().FullName}: {e.Message}");
            }
        }

        Title("Added after the first run: the [<CLIMutable>] records of GA.Business.Config, by module: how the assembly exposes them, and how many have a public constructor without parameters");
        Line($"{"module",-28} {"records",-8} {"exposed as",-11} public constructor");
        var records = typeof(NeoRiemannianConfig).Assembly.GetTypes()
            .Where(type => type.GetCustomAttributes(false).Any(attribute => attribute.GetType().Name == "CLIMutableAttribute")).ToList();
        foreach (var module in records.GroupBy(type => type.DeclaringType?.Name ?? "(none)").OrderBy(group => group.Key, StringComparer.Ordinal))
        {
            var exposed = module.Select(type => type.IsNestedPublic || type.IsPublic ? "public" : type.IsNestedAssembly ? "internal" : "private").Distinct();
            Line($"{module.Key,-28} {module.Count(),-8} {string.Join("/", exposed),-11} {module.Count(type => type.GetConstructor(Type.EmptyTypes) is not null)} of {module.Count()}");
        }
        const BindingFlags instance = BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic;
        foreach (var type in records.Where(type => type.DeclaringType == typeof(NeoRiemannianConfig)).OrderBy(type => type.Name, StringComparer.Ordinal))
        {
            Line($"{type.Name}: constructors {string.Join(", ", type.GetConstructors(instance).OrderBy(c => c.GetParameters().Length).Select(c => $"{Access(c)} with {c.GetParameters().Length} parameters"))}; " +
                $"setters {string.Join(", ", type.GetProperties(instance).Select(p => $"{p.Name} {Access(p.SetMethod)}"))}");
        }

        // ---- 3. The file itself

        var transforms = Yaml.Transforms.Select(pair => (Name: pair.Key, pair.Value.Description, pair.Value.VoiceLeadingCost, pair.Value.Mappings)).ToList();
        Title($"Added after the first run: NeoRiemannian.yaml through the deserializer GA builds, into public types of the same shape: {transforms.Count} transforms, " +
            $"{Yaml.HexatonicCycles.Count} hexatonic cycles, {Yaml.OctatonicCycles.Count} octatonic cycles");
        Line($"{"name",-5} {"mappings",-9} {"cost",-5} description");
        foreach (var transform in transforms)
        {
            Line($"{transform.Name,-5} {transform.Mappings.Count,-9} {transform.VoiceLeadingCost,-5} {transform.Description}");
        }

        Title("Each transform of the file over the course's 24 triads: the triads it maps, its distinct images, whether it undoes itself and swaps major and minor, and the minor root above the major root");
        Line($"{"name",-5} {"maps",-5} {"images",-7} {"undone by itself",-17} {"swaps",-6} semitones");
        foreach (var transform in transforms)
        {
            var images = Triads.Select(t => InFile(transform.Name, t)).ToList();
            var undone = Triads.Count(t => InFile(transform.Name, t) is { } image && InFile(transform.Name, image) == t);
            var swaps = Triads.Count(t => InFile(transform.Name, t) is { } image && image.Major != t.Major);
            var above = Triads.Where(t => t.Major).Select(t => InFile(transform.Name, t) is { } image ? Theory.Mod12(image.Root - t.Root) : -1).Distinct().Order();
            Line($"{transform.Name,-5} {images.Count(i => i is not null),-5} {images.Where(i => i is not null).Distinct().Count(),-7} {$"{undone} of 24",-17} {swaps,-6} {string.Join(" ", above)}");
        }
        Line($"names the file does not write: {string.Join(", ", new[] { "Db_maj", "Ab_maj", "c_maj", "C" }.Select(name => $"{name} {(transforms[0].Mappings.ContainsKey(name) ? "found" : "absent")}"))}; " +
            $"transforms: {string.Join(", ", new[] { "H", "h", "PL", "LPR" }.Select(name => $"{name} {(Yaml.Transforms.ContainsKey(name) ? "found" : "absent")}"))}");

        Title("S, N and H as the file's header writes them, read from left to right and from right to left, against the file's own mappings");
        Line($"{"name",-5} {"header",-10} {"left to right",-14} {"right to left",-14} {"order",-6} from C");
        foreach (var (name, word) in new[] { ("S", "LPR"), ("N", "RLP"), ("H", "LPL") })
        {
            int Matches(string w) => Triads.Count(t => InFile(name, t) == Apply(t, w));
            Line($"{name,-5} {string.Join(" o ", word.ToCharArray()),-10} {$"{Matches(word)} of 24",-14} {$"{Matches(Reversed(word))} of 24",-14} {Order(word),-6} {Apply(C, word).Name}");
        }

        Title("docs/methodology/invariants-catalog.md, invariant 15, \"PLR composites match: L∘P∘R = S, P∘L = N\": words of two and three letters against the file's N");
        foreach (var word in new[] { "PL", "LP", "PLR", "RLP" })
        {
            Line($"{word,-4} equals N on {Triads.Count(t => InFile("N", t) == Apply(t, word)),2} of 24 triads; order {Order(word)}; from C: {Apply(C, word).Name}");
        }

        Title("The three pairs of letters: the order of the word, and the triads met from C major by alternating its two letters");
        foreach (var word in new[] { "PL", "PR", "LR" })
        {
            var cycle = Cycle(C, word);
            Line($"{word}: order {Order(word)}, {cycle.Count} triads: {string.Join(" ", cycle.Select(t => t.Name))}");
        }

        Title("VoiceLeadingCost in the file against the smallest total movement between the two triads, with the notes they share");
        Line($"{"name",-5} {"file",-5} {"course",-7} {"shared",-7} the major triad's note = the minor triad's");
        foreach (var transform in transforms)
        {
            var pairs = Triads.Select(t => (From: t, To: InFile(transform.Name, t)!.Value)).ToList();
            var shared = pairs.Where(p => p.From.Major)
                .Select(p => string.Join(", ", p.From.Notes.Intersect(p.To.Notes).Select(pc => $"{p.From.Member(pc)} = {p.To.Member(pc)}")))
                .Distinct().Select(s => s.Length == 0 ? "none" : s);
            Line($"{transform.Name,-5} {transform.VoiceLeadingCost,-5} {Spread(pairs.Select(p => Movement(p.From, p.To))),-7} {Spread(pairs.Select(p => CommonTones(p.From, p.To))),-7} {string.Join(" | ", shared)}");
        }

        // ---- 4. The cycles

        var file = File.ReadAllLines(YamlPath);
        Title("NeoRiemannian.yaml, read as text: its top-level keys, and its remarks above the two lists of cycles");
        Line($"keys: {string.Join(", ", file.Where(line => Regex.IsMatch(line, "^[A-Za-z]+:")).Select(line => line.TrimEnd().TrimEnd(':')))}");
        foreach (var heading in new[] { "# Hexatonic cycles:", "# Octatonic cycles:" })
        {
            for (var i = Array.FindIndex(file, line => line.StartsWith(heading, StringComparison.Ordinal)); file[i].StartsWith('#'); i++)
            {
                Line($"{i + 1}: {file[i]}");
            }
        }

        string Steps(IReadOnlyList<Triad> cycle) => string.Concat(Enumerable.Range(0, cycle.Count).Select(i =>
            Basic.Where(b => Flip(cycle[i], b.Kept) == cycle[(i + 1) % cycle.Count]).Select(b => b.Name).DefaultIfEmpty('?').First()));

        var hexatonic = Yaml.HexatonicCycles.Select(cycle => (cycle.Name, Triads: cycle.Triads.Select(name => ByGaName[name]).ToList())).ToList();
        Title($"The file's {hexatonic.Count} hexatonic cycles: the step from each triad to the next and back to the first, the roots, and the notes of the six triads together");
        Line($"{"name",-14} {"steps",-7} {"roots",-12} {"notes",-20} prime form of the notes");
        foreach (var (name, cycle) in hexatonic)
        {
            var roots = cycle.Select(t => t.Root).Distinct().ToList();
            var notes = cycle.SelectMany(t => t.Notes).Distinct().ToList();
            Line($"{Pretty(name),-14} {Steps(cycle),-7} {$"{PcNames(roots)} ({roots.Count})",-12} {$"{PcNames(notes)} ({notes.Count})",-20} {Theory.Format(Theory.PrimeForm(Theory.SetId(notes)))}");
        }
        Line($"prime form of the roots: {string.Join(" | ", hexatonic.Select(h => Theory.Format(Theory.PrimeForm(Theory.SetId(h.Triads.Select(t => t.Root))))).Distinct())}; " +
            $"triads in the {hexatonic.Count} cycles: {hexatonic.Sum(h => h.Triads.Count)}, distinct: {hexatonic.SelectMany(h => h.Triads).Distinct().Count()}; " +
            $"the same triads in the same order as the course's P and L from the first: {hexatonic.Count(h => h.Triads.SequenceEqual(Cycle(h.Triads[0], "PL")))} of {hexatonic.Count}");

        var octatonic = Yaml.OctatonicCycles.Select(cycle => (cycle.Name, Triads: cycle.Triads.Select(name => ByGaName[name]).ToList())).ToList();
        Title($"The file's {octatonic.Count} octatonic cycles: the steps, the roots, the notes of the eight triads together, and the two numbers of each name");
        Line($"{"name",-9} {"steps",-9} {"roots",-14} {"notes",-26} {"holds both",-11} {"two lowest",-11} interval-class vector");
        foreach (var (name, cycle) in octatonic)
        {
            var roots = cycle.Select(t => t.Root).Distinct().ToList();
            var notes = cycle.SelectMany(t => t.Notes).Distinct().Order().ToList();
            var numbers = Regex.Matches(name, @"\d+").Select(m => int.Parse(m.Value)).ToList();
            Line($"{name,-9} {Steps(cycle),-9} {$"{PcNames(roots)} ({roots.Count})",-14} {$"{PcNames(notes)} ({notes.Count})",-26} {numbers.All(notes.Contains),-11} {string.Join(" ", notes.Take(2)),-11} {Theory.FormatIcv(Theory.Icv(Theory.SetId(notes)))}");
        }
        Line($"prime form of the roots: {string.Join(" | ", octatonic.Select(o => Theory.Format(Theory.PrimeForm(Theory.SetId(o.Triads.Select(t => t.Root))))).Distinct())}; " +
            $"prime form of the notes: {string.Join(" | ", octatonic.Select(o => Theory.Format(Theory.PrimeForm(Theory.SetId(o.Triads.SelectMany(t => t.Notes))))).Distinct())}; " +
            $"triads in the {octatonic.Count} cycles: {octatonic.Sum(o => o.Triads.Count)}, distinct: {octatonic.SelectMany(o => o.Triads).Distinct().Count()}; " +
            $"the same triads in the same order as the course's P and R from the first: {octatonic.Count(o => o.Triads.SequenceEqual(Cycle(o.Triads[0], "PR")))} of {octatonic.Count}");

        Title("invariants-catalog.md, invariant 8, \"Every NeoRiemannian.yaml triad name resolves to a valid SetClass\"");
        var names = transforms.SelectMany(transform => transform.Mappings.SelectMany(pair => new[] { pair.Key, pair.Value }))
            .Concat(Yaml.HexatonicCycles.SelectMany(cycle => cycle.Triads))
            .Concat(Yaml.OctatonicCycles.SelectMany(cycle => cycle.Triads))
            .Distinct().ToList();
        var classes = names.Where(ByGaName.ContainsKey).Select(name => new SetClass(GaSets[ByGaName[name].Id]).PrimeForm.Id.Value).Distinct().ToList();
        Line($"distinct names in the file: {names.Count}; among the course's 24: {names.Count(ByGaName.ContainsKey)}; GA's set classes for them: {classes.Count}, " +
            $"prime form {string.Join(" | ", classes.Select(id => Theory.Format(Theory.PitchClasses(id))))}; the course's prime form of C major: {Theory.Format(Theory.PrimeForm(C.Id))}");

        // ---- 5. The Tonnetz

        Title("The Tonnetz as a graph: the 12 pitch classes, joined when they lie a minor third, a major third or a fifth apart");
        var edges = (from a in Enumerable.Range(0, 12) from b in Enumerable.Range(a + 1, 11 - a) where Theory.IntervalClass(a - b) is 3 or 4 or 5 select (A: a, B: b)).ToList();
        bool Joined(int a, int b) => Theory.IntervalClass(a - b) is 3 or 4 or 5;
        var triangles = (
            from a in Enumerable.Range(0, 12)
            from b in Enumerable.Range(a + 1, 11 - a)
            from c in Enumerable.Range(b + 1, 11 - b)
            where Joined(a, b) && Joined(a, c) && Joined(b, c)
            select new[] { a, b, c }).ToList();
        string Kinds(int[] t) => string.Join(" ", new[] { Theory.IntervalClass(t[0] - t[1]), Theory.IntervalClass(t[0] - t[2]), Theory.IntervalClass(t[1] - t[2]) }.Order());
        var faces = triangles.Where(t => Kinds(t) == "3 4 5").ToList();
        var others = triangles.Where(t => Kinds(t) != "3 4 5").ToList();
        Line($"notes: 12; edges: {edges.Count}, {string.Join(", ", new[] { 3, 4, 5 }.Select(k => $"{edges.Count(e => Theory.IntervalClass(e.A - e.B) == k)} of interval class {k}"))}");
        Line($"triangles: {triangles.Count}; with one edge of each kind: {faces.Count}, all of them among the 24 triads: {faces.All(t => ById.ContainsKey(Theory.SetId(t)))}; " +
            $"the others: {others.Count}, with the edges {string.Join(" | ", others.Select(Kinds).Distinct())}: {string.Join(", ", others.Select(t => PcNames(t)))}");
        Line($"notes - edges + triads = {12 - edges.Count + faces.Count}");
        Line($"triads on each note: {Spread(Enumerable.Range(0, 12).Select(pc => Triads.Count(t => t.Notes.Contains(pc))))}; " +
            $"triads on each edge: {Spread(edges.Select(e => Triads.Count(t => t.Notes.Contains(e.A) && t.Notes.Contains(e.B))))}");
        foreach (var (name, kept) in Basic)
        {
            var kind = edges.Where(e => Theory.IntervalClass(e.A - e.B) == kept).ToList();
            var related = kind.Count(e =>
            {
                var on = Triads.Where(t => t.Notes.Contains(e.A) && t.Notes.Contains(e.B)).ToList();
                return on.Count == 2 && Flip(on[0], kept) == on[1];
            });
            Line($"the two triads on an edge of interval class {kept} are each other's {name}: {related} of {kind.Count}");
        }

        Title("The graph of the 24 triads joined by P, L and R: from C major, the triads at each distance with a shortest word, their common tones with C major and the movement to them");
        var words = Words(C);
        Line($"{"steps",-6} {"triads",-7} {"common",-7} {"movement",-9} triad and word");
        foreach (var group in words.GroupBy(pair => pair.Value.Length).OrderBy(group => group.Key))
        {
            Line($"{group.Key,-6} {group.Count(),-7} {Spread(group.Select(pair => CommonTones(C, pair.Key))),-7} {Spread(group.Select(pair => Movement(C, pair.Key))),-9} " +
                string.Join(", ", group.Select(pair => $"{pair.Key.Name} {pair.Value}".TrimEnd())));
        }
        string Profile(Triad start) => string.Join(" ", Words(start).Values.GroupBy(word => word.Length).OrderBy(group => group.Key).Select(group => group.Count()));
        string Farthest(Triad start) => string.Join(", ", Words(start).Where(pair => pair.Value.Length == 5).Select(pair => pair.Key.Name));
        Line($"edges: {Triads.Length * Basic.Length / 2}; triads at each distance, from each of the 24: {string.Join(" | ", Triads.Select(Profile).Distinct())}; " +
            $"five steps from C: {Farthest(C)}; from Cm: {Farthest(new Triad(0, false))}");

        Title("Wikipedia's three examples, from C major: steps on the graph against common tones and movement");
        Line($"{"triad",-6} {"steps",-6} {"word",-5} {"common",-7} movement");
        foreach (var t in new[] { new Triad(5, true), new Triad(5, false), new Triad(3, false) })
        {
            Line($"{t.Name,-6} {words[t].Length,-6} {words[t],-5} {CommonTones(C, t),-7} {Movement(C, t)}");
        }

        // ---- 6. The mediants

        Title("The eight triads whose root lies a third from C, from C major: common tones, a shortest word, the file's transform if it has one, and the name of the relation");
        Line($"{"triad",-6} {"root",-9} {"common",-7} {"word",-5} {"file",-5} relation");
        var thirds = new (int Semitones, string Label)[] { (4, "M3 above"), (9, "m3 below"), (3, "m3 above"), (8, "M3 below") };
        foreach (var t in thirds.SelectMany(third => new[] { new Triad(third.Semitones, false), new Triad(third.Semitones, true) }).OrderByDescending(triad => CommonTones(C, triad)))
        {
            var single = transforms.Where(transform => InFile(transform.Name, C) == t).Select(transform => transform.Name).DefaultIfEmpty("-").First();
            var relation = CommonTones(C, t) switch { 2 => "diatonic", 1 => "chromatic mediant", _ => "doubly chromatic mediant" };
            Line($"{t.Name,-6} {thirds.First(third => third.Semitones == t.Root).Label,-9} {CommonTones(C, t),-7} {words[t],-5} {single,-5} {relation}");
        }
        var (em, gm) = (new Triad(4, false), new Triad(7, false));
        Line($"GA's cadence \"Chromatic Mediant (Metal)\" of lesson 7, {em.Name} to {gm.Name}: common tones {CommonTones(em, gm)}, word {Words(em)[gm]}, movement {Movement(em, gm)}");

        // ---- 7. ExplainTriadRelationship

        Title("SemanticAnalysisService.ExplainTriadRelationship on the 576 ordered pairs of triads, then on sets that are not triads");
        var answers = (from a in Triads from b in Triads select Explain(a.Notes, a.Root, b.Notes, b.Root)).Distinct().ToList();
        Line($"distinct answers: {answers.Count}");
        foreach (var answer in answers)
        {
            Line($"\"{answer}\"");
        }
        Line($"C D E to F G A: the same answer {answers.Contains(Explain([0, 2, 4], 0, [5, 7, 9], 5))}");
        Line($"C E G B to C E G: \"{Explain([0, 4, 7, 11], 0, [0, 4, 7], 0)}\"");

        // ---- 8. GA's Tonnetz component

        var component = File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "TonnetzDiagram.tsx"));
        var cells = Regex.Match(component, @"notes: string\[\] = \[([^\]]+)\]").Groups[1].Value.Split(',').Select(cell => cell.Trim().Trim('\'')).ToArray();
        var scale = int.Parse(Regex.Match(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "App.tsx")), @"<TonnetzDiagram scale=\{(\d+)\}").Groups[1].Value);
        Title($"GA's TonnetzDiagram.tsx (Experiments/React, read as text): its {cells.Length} cells, four to a row, and the cells it fills for the scale {scale} of App.tsx");
        foreach (var row in Enumerable.Range(0, cells.Length / 4))
        {
            Line($"row {row}{(row % 2 == 1 ? ", half a cell to the right" : ""),-26}: {Pretty(string.Join(" ", cells.Skip(row * 4).Take(4)))}");
        }
        Line($"as the component places them: {Neighbours(cells, sheared: false)}");
        Line($"each row half a cell further: {Neighbours(cells, sheared: true)}");
        // line 10: the scale's bits from the lowest; line 36: a cell is filled when the bit at its position in the list is 1
        var bits = Enumerable.Reverse(Convert.ToString(scale, 2).PadLeft(12, '0')).ToArray();
        Line($"scale {scale} = {Theory.Binary(scale)}, bit n for pitch class n: {PcNames(Theory.PitchClasses(scale))}");
        Line($"cells filled, by position in the list: {Pretty(string.Join(" ", cells.Where((_, index) => bits[index] == '1')))}");
        Line($"cells whose note is in the scale:     {Pretty(string.Join(" ", cells.Where(cell => bits[Theory.PitchClassOf(cell)] == '1')))}");
    }
}
