namespace PetriNets;

/// <summary>One step of the reachability graph: firing <paramref name="Transition"/> leads from <paramref name="From"/> to <paramref name="To"/>.</summary>
public sealed record Step(int From, int Transition, int To);

/// <summary>
/// The reachability graph of a net: every marking reachable from the initial one, and the
/// firings that join them. Built breadth first, so the states come out in a deterministic order
/// that does not depend on a hash table's layout.
/// </summary>
public sealed class ReachabilityGraph
{
    private ReachabilityGraph(PetriNet net, IReadOnlyList<Marking> states, IReadOnlyList<Step> steps, bool complete, int limit)
    {
        Net = net;
        States = states;
        Steps = steps;
        IsComplete = complete;
        Limit = limit;
    }

    public PetriNet Net { get; }

    /// <summary>The reachable markings, state 0 being the initial marking.</summary>
    public IReadOnlyList<Marking> States { get; }

    /// <summary>The firings, sorted by source state then by transition.</summary>
    public IReadOnlyList<Step> Steps { get; }

    /// <summary>False when the construction stopped at <see cref="Limit"/> states: the graph shown is a prefix.</summary>
    public bool IsComplete { get; }

    public int Limit { get; }

    /// <summary>States with no enabled transition: the dead markings of the net.</summary>
    public IReadOnlyList<int> DeadStates
    {
        get
        {
            var withSuccessor = Steps.Select(s => s.From).ToHashSet();
            return [.. Enumerable.Range(0, States.Count).Where(s => !withSuccessor.Contains(s))];
        }
    }

    /// <summary>
    /// Builds the graph, stopping after <paramref name="limit"/> states. The limit matters:
    /// a net whose reachability set is infinite would otherwise never finish (lesson 3).
    /// </summary>
    public static ReachabilityGraph Build(PetriNet net, int limit = 100_000)
    {
        ArgumentNullException.ThrowIfNull(net);
        if (net.InitialMarking.HasOmega)
            throw new ArgumentException("The reachability graph starts from a marking without omega.", nameof(net));

        var states = new List<Marking> { net.InitialMarking };
        var index = new Dictionary<Marking, int> { [net.InitialMarking] = 0 };
        var steps = new List<Step>();
        var queue = new Queue<int>();
        queue.Enqueue(0);
        var complete = true;

        while (queue.Count > 0)
        {
            var from = queue.Dequeue();
            foreach (var t in net.EnabledTransitions(states[from]))
            {
                var next = net.Fire(states[from], t);
                if (!index.TryGetValue(next, out var to))
                {
                    if (states.Count >= limit) { complete = false; continue; }
                    to = states.Count;
                    states.Add(next);
                    index[next] = to;
                    queue.Enqueue(to);
                }
                steps.Add(new Step(from, t, to));
            }
        }

        steps.Sort((a, b) => a.From != b.From ? a.From.CompareTo(b.From) : a.Transition.CompareTo(b.Transition));
        return new ReachabilityGraph(net, states, steps, complete, limit);
    }

    /// <summary>
    /// The shortest firing sequence from the initial marking to <paramref name="state"/>, as transition
    /// indices, or null when there is none. Ties are broken by the breadth-first order, so the answer
    /// is the same on every run.
    /// </summary>
    public IReadOnlyList<int>? PathTo(int state)
    {
        var previous = new (int State, int Transition)[States.Count];
        Array.Fill(previous, (-1, -1));
        previous[0] = (0, -1);
        var queue = new Queue<int>();
        queue.Enqueue(0);
        while (queue.Count > 0)
        {
            var from = queue.Dequeue();
            if (from == state) break;
            foreach (var step in Steps.Where(s => s.From == from))
            {
                if (previous[step.To].State >= 0) continue;
                previous[step.To] = (from, step.Transition);
                queue.Enqueue(step.To);
            }
        }
        if (previous[state].State < 0) return null;

        var path = new List<int>();
        for (var current = state; current != 0; current = previous[current].State)
            path.Add(previous[current].Transition);
        path.Reverse();
        return path;
    }

    /// <summary>The largest number of tokens seen in each place, or null when the graph is only a prefix.</summary>
    public int?[] PlaceBounds()
    {
        var bounds = new int?[Net.Places.Count];
        for (var p = 0; p < Net.Places.Count; p++)
            bounds[p] = IsComplete ? States.Max(m => m[p]) : null;
        return bounds;
    }
}
