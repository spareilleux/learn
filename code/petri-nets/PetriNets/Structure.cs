namespace PetriNets;

/// <summary>
/// The structural classes a net belongs to. Everything here is read off the arcs alone: no
/// marking takes part, so a class holds for the net whatever tokens you put on it (lesson 6).
/// </summary>
public sealed record StructuralClasses(
    bool IsOrdinary,
    bool IsPure,
    bool IsStateMachine,
    bool IsMarkedGraph,
    bool IsFreeChoice,
    bool IsExtendedFreeChoice,
    bool IsAsymmetricChoice,
    bool IsStronglyConnected);

/// <summary>An elementary circuit of the net: the places it passes through, and the transitions between them.</summary>
public sealed record Circuit(IReadOnlyList<int> Places, IReadOnlyList<int> Transitions)
{
    /// <summary>The tokens the marking puts on the circuit. Firing any transition leaves this number unchanged in a marked graph.</summary>
    public int Tokens(Marking marking)
    {
        ArgumentNullException.ThrowIfNull(marking);
        return Places.Sum(p => marking[p]);
    }
}

/// <summary>A siphon, with the largest trap it contains and whether that trap holds a token at M0.</summary>
public sealed record SiphonReport(IReadOnlyList<int> Siphon, IReadOnlyList<int> MaximalTrap, bool TrapIsMarked);

/// <summary>
/// Structure: the classes of Murata 1989 section II-B, the siphons and traps of section IV-C,
/// and the circuits a marked graph is judged by. None of these builds a reachability graph,
/// which is the point: the answers survive nets whose graph does not fit in memory.
/// </summary>
public static class Structure
{
    /// <summary>The transitions that put tokens into <paramref name="place"/>, written •p.</summary>
    public static IReadOnlyList<int> InputTransitions(PetriNet net, int place)
    {
        ArgumentNullException.ThrowIfNull(net);
        return [.. Enumerable.Range(0, net.Transitions.Count).Where(t => net.Post[place, t] > 0)];
    }

    /// <summary>The transitions that take tokens from <paramref name="place"/>, written p•.</summary>
    public static IReadOnlyList<int> OutputTransitions(PetriNet net, int place)
    {
        ArgumentNullException.ThrowIfNull(net);
        return [.. Enumerable.Range(0, net.Transitions.Count).Where(t => net.Pre[place, t] > 0)];
    }

    /// <summary>The places <paramref name="transition"/> takes tokens from, written •t.</summary>
    public static IReadOnlyList<int> InputPlaces(PetriNet net, int transition)
    {
        ArgumentNullException.ThrowIfNull(net);
        return [.. Enumerable.Range(0, net.Places.Count).Where(p => net.Pre[p, transition] > 0)];
    }

    /// <summary>The places <paramref name="transition"/> puts tokens into, written t•.</summary>
    public static IReadOnlyList<int> OutputPlaces(PetriNet net, int transition)
    {
        ArgumentNullException.ThrowIfNull(net);
        return [.. Enumerable.Range(0, net.Places.Count).Where(p => net.Post[p, transition] > 0)];
    }

    /// <summary>
    /// Decides the classes of <paramref name="net"/>. A state machine has one input and one output
    /// place per transition; a marked graph has one input and one output transition per place;
    /// a free-choice net never lets two transitions share an input place unless that place feeds
    /// only them and they read only it.
    /// </summary>
    public static StructuralClasses Classify(PetriNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        var places = net.Places.Count;
        var transitions = net.Transitions.Count;

        var ordinary = true;
        var pure = true;
        for (var p = 0; p < places; p++)
        {
            for (var t = 0; t < transitions; t++)
            {
                if (net.Pre[p, t] > 1 || net.Post[p, t] > 1) ordinary = false;
                if (net.Pre[p, t] > 0 && net.Post[p, t] > 0) pure = false;
            }
        }

        var stateMachine = ordinary && Enumerable.Range(0, transitions)
            .All(t => InputPlaces(net, t).Count == 1 && OutputPlaces(net, t).Count == 1);
        var markedGraph = ordinary && Enumerable.Range(0, places)
            .All(p => InputTransitions(net, p).Count == 1 && OutputTransitions(net, p).Count == 1);

        var outputs = Enumerable.Range(0, places).Select(p => OutputTransitions(net, p).ToHashSet()).ToList();
        var freeChoice = ordinary;
        var extended = ordinary;
        var asymmetric = ordinary;
        for (var a = 0; a < places && asymmetric; a++)
        {
            for (var b = a + 1; b < places; b++)
            {
                if (!outputs[a].Overlaps(outputs[b])) continue;
                if (outputs[a].Count != 1 || outputs[b].Count != 1) freeChoice = false;
                if (!outputs[a].SetEquals(outputs[b])) extended = false;
                if (!outputs[a].IsSubsetOf(outputs[b]) && !outputs[b].IsSubsetOf(outputs[a])) { asymmetric = false; break; }
            }
        }

        return new StructuralClasses(
            IsOrdinary: ordinary,
            IsPure: pure,
            IsStateMachine: stateMachine,
            IsMarkedGraph: markedGraph,
            IsFreeChoice: freeChoice,
            IsExtendedFreeChoice: extended,
            IsAsymmetricChoice: asymmetric,
            IsStronglyConnected: IsStronglyConnected(net));
    }

    /// <summary>True when every node of the net can be reached from every other one along the arcs.</summary>
    public static bool IsStronglyConnected(PetriNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        var count = net.Places.Count + net.Transitions.Count;
        if (count == 0) return true;
        var forward = new List<int>[count];
        var backward = new List<int>[count];
        for (var n = 0; n < count; n++) { forward[n] = []; backward[n] = []; }
        for (var p = 0; p < net.Places.Count; p++)
        {
            for (var t = 0; t < net.Transitions.Count; t++)
            {
                if (net.Pre[p, t] > 0) { forward[p].Add(net.Places.Count + t); backward[net.Places.Count + t].Add(p); }
                if (net.Post[p, t] > 0) { forward[net.Places.Count + t].Add(p); backward[p].Add(net.Places.Count + t); }
            }
        }
        return Reaches(forward, count) && Reaches(backward, count);

        static bool Reaches(List<int>[] edges, int count)
        {
            var seen = new bool[count];
            var queue = new Queue<int>();
            seen[0] = true;
            queue.Enqueue(0);
            var reached = 1;
            while (queue.Count > 0)
            {
                foreach (var next in edges[queue.Dequeue()])
                {
                    if (seen[next]) continue;
                    seen[next] = true;
                    reached++;
                    queue.Enqueue(next);
                }
            }
            return reached == count;
        }
    }

    /// <summary>
    /// A siphon (Murata's "deadlock", renamed since to avoid the confusion with the behaviour):
    /// a set S of places with •S ⊆ S•. Every transition that fills S also empties it, so once S
    /// holds no token it never holds one again.
    /// </summary>
    public static bool IsSiphon(PetriNet net, IReadOnlyCollection<int> places)
    {
        ArgumentNullException.ThrowIfNull(net);
        ArgumentNullException.ThrowIfNull(places);
        if (places.Count == 0) return false;
        var set = places.ToHashSet();
        var input = set.SelectMany(p => InputTransitions(net, p)).ToHashSet();
        var output = set.SelectMany(p => OutputTransitions(net, p)).ToHashSet();
        return input.IsSubsetOf(output);
    }

    /// <summary>
    /// A trap: a set S of places with S• ⊆ •S. Every transition that empties S also fills it,
    /// so once S holds a token it holds one for ever — which is the only reason a proof of
    /// liveness can ever come out of a structure.
    /// </summary>
    public static bool IsTrap(PetriNet net, IReadOnlyCollection<int> places)
    {
        ArgumentNullException.ThrowIfNull(net);
        ArgumentNullException.ThrowIfNull(places);
        if (places.Count == 0) return false;
        var set = places.ToHashSet();
        var input = set.SelectMany(p => InputTransitions(net, p)).ToHashSet();
        var output = set.SelectMany(p => OutputTransitions(net, p)).ToHashSet();
        return output.IsSubsetOf(input);
    }

    /// <summary>
    /// The minimal siphons, by brute force over the subsets of places: exact, and only usable on
    /// the small nets of this course. Finding them is NP-hard in general, which lesson 6 says out loud.
    /// </summary>
    public static IReadOnlyList<IReadOnlyList<int>> MinimalSiphons(PetriNet net, int maxPlaces = 20) =>
        MinimalSets(net, maxPlaces, IsSiphon);

    /// <summary>The minimal traps, by the same brute force.</summary>
    public static IReadOnlyList<IReadOnlyList<int>> MinimalTraps(PetriNet net, int maxPlaces = 20) =>
        MinimalSets(net, maxPlaces, IsTrap);

    private static IReadOnlyList<IReadOnlyList<int>> MinimalSets(
        PetriNet net, int maxPlaces, Func<PetriNet, IReadOnlyCollection<int>, bool> holds)
    {
        ArgumentNullException.ThrowIfNull(net);
        var count = net.Places.Count;
        if (count > maxPlaces)
            throw new ArgumentOutOfRangeException(nameof(net), $"{count} places is past the brute-force limit of {maxPlaces}.");

        var found = new List<int>();
        for (var mask = 1; mask < 1 << count; mask++)
        {
            var places = Members(mask, count);
            if (!holds(net, places)) continue;
            if (found.Any(other => (other & mask) == other)) continue; // a smaller one is already inside
            found.Add(mask);
        }
        found.Sort(BySizeThenPlaces);
        return [.. found.Select(mask => (IReadOnlyList<int>)Members(mask, count))];
    }

    private static List<int> Members(int mask, int count) =>
        [.. Enumerable.Range(0, count).Where(i => (mask & (1 << i)) != 0)];

    /// <summary>Smallest sets first, then in the order of the places, so the report never depends on the search.</summary>
    private static int BySizeThenPlaces(int a, int b)
    {
        var sizeA = System.Numerics.BitOperations.PopCount((uint)a);
        var sizeB = System.Numerics.BitOperations.PopCount((uint)b);
        return sizeA != sizeB ? sizeA.CompareTo(sizeB) : a.CompareTo(b);
    }

    /// <summary>
    /// The largest trap contained in <paramref name="places"/>, found by repeatedly dropping every
    /// place whose output transition does not give back into the set. The empty list means there is none.
    /// </summary>
    public static IReadOnlyList<int> MaximalTrapIn(PetriNet net, IReadOnlyCollection<int> places)
    {
        ArgumentNullException.ThrowIfNull(net);
        ArgumentNullException.ThrowIfNull(places);
        var set = places.ToHashSet();
        while (set.Count > 0)
        {
            var input = set.SelectMany(p => InputTransitions(net, p)).ToHashSet();
            var offending = set.SelectMany(p => OutputTransitions(net, p)).Where(t => !input.Contains(t)).ToHashSet();
            if (offending.Count == 0) break;
            set.RemoveWhere(p => OutputTransitions(net, p).Any(offending.Contains));
        }
        return [.. set.Order()];
    }

    /// <summary>
    /// Commoner's condition: every minimal siphon, with the largest trap inside it and whether that
    /// trap holds a token at the initial marking. When all of them do, no siphon can ever empty.
    /// </summary>
    public static IReadOnlyList<SiphonReport> SiphonsAndTraps(PetriNet net, int maxPlaces = 20)
    {
        ArgumentNullException.ThrowIfNull(net);
        return
        [
            .. MinimalSiphons(net, maxPlaces).Select(siphon =>
            {
                var trap = MaximalTrapIn(net, siphon);
                var marked = trap.Any(p => net.InitialMarking[p] > 0);
                return new SiphonReport(siphon, trap, marked);
            })
        ];
    }

    /// <summary>True when every minimal siphon contains a trap that holds a token at M0.</summary>
    public static bool EverySiphonHasAMarkedTrap(PetriNet net, int maxPlaces = 20) =>
        SiphonsAndTraps(net, maxPlaces).All(s => s.TrapIsMarked);

    /// <summary>The places holding no token at <paramref name="marking"/>. At a dead marking they always form a siphon.</summary>
    public static IReadOnlyList<int> EmptyPlaces(Marking marking)
    {
        ArgumentNullException.ThrowIfNull(marking);
        return [.. Enumerable.Range(0, marking.Count).Where(p => marking[p] == 0)];
    }

    /// <summary>
    /// The elementary circuits of the net, each one listed by the places it passes through.
    /// Depth-first from each node, keeping only the circuits whose smallest node is the one we
    /// started from, so every circuit comes out exactly once.
    /// </summary>
    public static IReadOnlyList<Circuit> Circuits(PetriNet net, int limit = 10_000)
    {
        ArgumentNullException.ThrowIfNull(net);
        var places = net.Places.Count;
        var nodes = places + net.Transitions.Count;
        var edges = new List<int>[nodes];
        for (var n = 0; n < nodes; n++) edges[n] = [];
        for (var p = 0; p < places; p++)
        {
            for (var t = 0; t < net.Transitions.Count; t++)
            {
                if (net.Pre[p, t] > 0) edges[p].Add(places + t);
                if (net.Post[p, t] > 0) edges[places + t].Add(p);
            }
        }

        var circuits = new List<Circuit>();
        var path = new List<int>();
        var onPath = new bool[nodes];
        for (var start = 0; start < nodes && circuits.Count < limit; start++) Walk(start, start);
        circuits.Sort(Compare);
        return circuits;

        void Walk(int start, int node)
        {
            path.Add(node);
            onPath[node] = true;
            foreach (var next in edges[node])
            {
                if (next == start)
                {
                    circuits.Add(new Circuit(
                        [.. path.Where(n => n < places).Order()],
                        [.. path.Where(n => n >= places).Select(n => n - places).Order()]));
                    if (circuits.Count >= limit) break;
                }
                else if (next > start && !onPath[next])
                {
                    Walk(start, next);
                }
            }
            onPath[node] = false;
            path.RemoveAt(path.Count - 1);
        }

        static int Compare(Circuit a, Circuit b)
        {
            if (a.Places.Count != b.Places.Count) return a.Places.Count.CompareTo(b.Places.Count);
            for (var i = 0; i < a.Places.Count; i++)
            {
                if (a.Places[i] != b.Places[i]) return a.Places[i].CompareTo(b.Places[i]);
            }
            return 0;
        }
    }
}
