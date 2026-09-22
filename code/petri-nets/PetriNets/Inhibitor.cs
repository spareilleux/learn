namespace PetriNets;

/// <summary>An inhibitor arc: <paramref name="Transition"/> fires only while <paramref name="Place"/> holds no token.</summary>
public sealed record InhibitorArc(string Place, string Transition);

/// <summary>
/// A place/transition net plus inhibitor arcs — the extension that lets a transition test a place
/// for zero, which an ordinary net cannot do.
///
/// That one addition makes the formalism Turing complete: two places behave as the counters of a
/// two-counter machine, and inhibitor arcs give the conditional jump on zero. Everything this
/// course decides structurally therefore stops being decidable here — boundedness, reachability,
/// liveness — which is why the rest of the analyser has no inhibitor arcs and this class is
/// deliberately the smallest thing that can demonstrate the loss.
///
/// Concretely, <see cref="CoverabilityTree"/> must not be run on one of these. Karp and Miller's
/// acceleration rests on an argument an inhibitor arc breaks: if a marking strictly covers an
/// ancestor, the firing sequence in between can be repeated for ever. With an inhibitor arc it
/// cannot — the tokens that appeared may be exactly what now blocks the transition that produced
/// them. Lesson 15 measures a net where the tree answers ω and the reachable set holds one token.
/// </summary>
public sealed class InhibitorNet
{
    private readonly bool[,] _inhibits; // [place, transition]

    public InhibitorNet(PetriNet net, IReadOnlyList<InhibitorArc> inhibitors)
    {
        ArgumentNullException.ThrowIfNull(net);
        ArgumentNullException.ThrowIfNull(inhibitors);
        Net = net;
        Inhibitors = [.. inhibitors];
        _inhibits = new bool[net.Places.Count, net.Transitions.Count];
        foreach (var arc in Inhibitors)
            _inhibits[net.PlaceIndex(arc.Place), net.TransitionIndex(arc.Transition)] = true;
    }

    /// <summary>The underlying ordinary net: the same places, transitions and arcs, without the zero tests.</summary>
    public PetriNet Net { get; }

    public IReadOnlyList<InhibitorArc> Inhibitors { get; }

    /// <summary>Enabled in the ordinary net, and every inhibiting place empty.</summary>
    public bool IsEnabled(Marking marking, int transition)
    {
        ArgumentNullException.ThrowIfNull(marking);
        if (!Net.IsEnabled(marking, transition)) return false;
        for (var p = 0; p < Net.Places.Count; p++)
            if (_inhibits[p, transition] && marking[p] != 0) return false;
        return true;
    }

    public IEnumerable<int> EnabledTransitions(Marking marking) =>
        Enumerable.Range(0, Net.Transitions.Count).Where(t => IsEnabled(marking, t));

    /// <summary>
    /// The reachable markings and the steps between them, breadth first.
    ///
    /// There is no coverability counterpart and there cannot be one: boundedness is undecidable for
    /// these nets, so <paramref name="limit"/> is the only termination this method has. When
    /// <c>IsComplete</c> comes back false the answer is "not within the limit", never "unbounded".
    /// </summary>
    public (IReadOnlyList<Marking> States, IReadOnlyList<Step> Steps, bool IsComplete) Reachable(int limit = 100_000)
    {
        var states = new List<Marking> { Net.InitialMarking };
        var index = new Dictionary<Marking, int> { [Net.InitialMarking] = 0 };
        var steps = new List<Step>();
        var queue = new Queue<int>();
        queue.Enqueue(0);
        while (queue.Count > 0)
        {
            var from = queue.Dequeue();
            foreach (var t in EnabledTransitions(states[from]))
            {
                var next = Net.Fire(states[from], t);
                if (!index.TryGetValue(next, out var to))
                {
                    if (states.Count >= limit) return (states, steps, false);
                    to = states.Count;
                    index[next] = to;
                    states.Add(next);
                    queue.Enqueue(to);
                }
                steps.Add(new Step(from, t, to));
            }
        }
        return (states, steps, true);
    }

    /// <summary>The greatest number of tokens each place holds over the reachable markings found.</summary>
    public int[] PlaceBounds(int limit = 100_000)
    {
        var (states, _, _) = Reachable(limit);
        var bounds = new int[Net.Places.Count];
        foreach (var marking in states)
            for (var p = 0; p < Net.Places.Count; p++)
                bounds[p] = Math.Max(bounds[p], marking[p]);
        return bounds;
    }
}
