namespace PetriNets;

/// <summary>A place: a condition, a buffer slot, a resource pool. It holds tokens.</summary>
public sealed record Place(string Id, string Name);

/// <summary>A transition: an event. It consumes tokens from its input places and produces tokens in its output places.</summary>
public sealed record Transition(string Id, string Name);

/// <summary>An arc from a place to a transition, or from a transition to a place, carrying a weight (default 1).</summary>
public sealed record Arc(string Source, string Target, int Weight = 1);

/// <summary>
/// A place/transition net, the ordinary Petri net of Murata 1989, section II:
/// a finite set of places, a finite set of transitions, weighted arcs between the two,
/// and an initial marking.
/// </summary>
public sealed class PetriNet
{
    private readonly Dictionary<string, int> _placeIndex;
    private readonly Dictionary<string, int> _transitionIndex;

    public PetriNet(string name, IReadOnlyList<Place> places, IReadOnlyList<Transition> transitions,
                    IReadOnlyList<Arc> arcs, Marking initialMarking)
    {
        ArgumentNullException.ThrowIfNull(places);
        ArgumentNullException.ThrowIfNull(transitions);
        ArgumentNullException.ThrowIfNull(arcs);
        ArgumentNullException.ThrowIfNull(initialMarking);

        Name = name;
        Places = [.. places];
        Transitions = [.. transitions];
        Arcs = [.. arcs];
        InitialMarking = initialMarking;

        _placeIndex = Places.Select((p, i) => (p.Id, i)).ToDictionary(x => x.Id, x => x.i);
        _transitionIndex = Transitions.Select((t, i) => (t.Id, i)).ToDictionary(x => x.Id, x => x.i);

        if (initialMarking.Count != Places.Count)
            throw new ArgumentException($"The initial marking has {initialMarking.Count} entries for {Places.Count} places.", nameof(initialMarking));

        Pre = new int[Places.Count, Transitions.Count];
        Post = new int[Places.Count, Transitions.Count];
        foreach (var arc in Arcs)
        {
            if (arc.Weight <= 0)
                throw new ArgumentException($"Arc {arc.Source} -> {arc.Target} has weight {arc.Weight}; weights are positive.", nameof(arcs));
            if (_placeIndex.TryGetValue(arc.Source, out var p) && _transitionIndex.TryGetValue(arc.Target, out var t))
                Pre[p, t] += arc.Weight;
            else if (_transitionIndex.TryGetValue(arc.Source, out var t2) && _placeIndex.TryGetValue(arc.Target, out var p2))
                Post[p2, t2] += arc.Weight;
            else
                throw new ArgumentException($"Arc {arc.Source} -> {arc.Target} does not join a place and a transition.", nameof(arcs));
        }
    }

    public string Name { get; }
    public IReadOnlyList<Place> Places { get; }
    public IReadOnlyList<Transition> Transitions { get; }
    public IReadOnlyList<Arc> Arcs { get; }
    public Marking InitialMarking { get; }

    /// <summary>Pre[p, t]: tokens transition t takes from place p when it fires. The matrix written W(p, t) in Murata 1989.</summary>
    public int[,] Pre { get; }

    /// <summary>Post[p, t]: tokens transition t puts into place p when it fires.</summary>
    public int[,] Post { get; }

    public int PlaceIndex(string idOrName) =>
        _placeIndex.TryGetValue(idOrName, out var i) ? i : IndexByName(Places.Select(p => p.Name), idOrName, "place");

    public int TransitionIndex(string idOrName) =>
        _transitionIndex.TryGetValue(idOrName, out var i) ? i : IndexByName(Transitions.Select(t => t.Name), idOrName, "transition");

    private static int IndexByName(IEnumerable<string> names, string name, string kind)
    {
        var matches = names.Select((n, i) => (n, i)).Where(x => x.n == name).Select(x => x.i).ToList();
        return matches.Count switch
        {
            1 => matches[0],
            0 => throw new KeyNotFoundException($"No {kind} called '{name}'."),
            _ => throw new ArgumentException($"Several {kind}s are called '{name}'; use their ids.", nameof(name)),
        };
    }

    /// <summary>The incidence matrix C = Post - Pre, the net's change of marking per firing.</summary>
    public int[,] Incidence()
    {
        var c = new int[Places.Count, Transitions.Count];
        for (var p = 0; p < Places.Count; p++)
            for (var t = 0; t < Transitions.Count; t++)
                c[p, t] = Post[p, t] - Pre[p, t];
        return c;
    }

    /// <summary>True when every input place of <paramref name="transition"/> holds at least the arc weight.</summary>
    public bool IsEnabled(Marking marking, int transition)
    {
        ArgumentNullException.ThrowIfNull(marking);
        for (var p = 0; p < Places.Count; p++)
        {
            if (marking[p] != Marking.Omega && marking[p] < Pre[p, transition]) return false;
        }
        return true;
    }

    /// <summary>The transitions enabled at <paramref name="marking"/>, in the order they were declared.</summary>
    public IEnumerable<int> EnabledTransitions(Marking marking) =>
        Enumerable.Range(0, Transitions.Count).Where(t => IsEnabled(marking, t));

    /// <summary>
    /// Fires <paramref name="transition"/>: takes Pre tokens from every input place and adds Post tokens
    /// to every output place. Both happen at once, which is why a self-loop leaves the place unchanged.
    /// </summary>
    public Marking Fire(Marking marking, int transition)
    {
        if (!IsEnabled(marking, transition))
            throw new InvalidOperationException($"Transition {Transitions[transition].Name} is not enabled at {marking}.");
        var next = marking.ToArray();
        for (var p = 0; p < Places.Count; p++)
            next[p] = Marking.Add(next[p], Post[p, transition] - Pre[p, transition]);
        return new Marking(next);
    }

    /// <summary>Fires a sequence of transitions, each given by its id or its name, and returns every marking along the way.</summary>
    public IReadOnlyList<Marking> FireSequence(Marking start, params string[] transitions)
    {
        ArgumentNullException.ThrowIfNull(transitions);
        var markings = new List<Marking> { start };
        var current = start;
        foreach (var name in transitions)
        {
            current = Fire(current, TransitionIndex(name));
            markings.Add(current);
        }
        return markings;
    }
}
