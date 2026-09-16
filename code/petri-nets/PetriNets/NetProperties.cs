namespace PetriNets;

/// <summary>
/// The liveness levels of Murata 1989, section II-C. A transition is live at level L4 when,
/// whatever the net has done so far, it can still fire; the lower levels are weaker promises.
/// </summary>
public enum Liveness
{
    /// <summary>L0, dead: the transition can never fire.</summary>
    Dead,

    /// <summary>L1: the transition can fire at least once.</summary>
    L1,

    /// <summary>L2 and L3: the transition can fire as often as you like, and in an infinite run.</summary>
    L2L3,

    /// <summary>L4, live: from every reachable marking, the transition can fire again.</summary>
    Live,
}

/// <summary>What the reachability graph says about a net, place by place and transition by transition.</summary>
public sealed record NetProperties(
    bool GraphIsComplete,
    int?[] PlaceBounds,
    bool IsBounded,
    bool IsSafe,
    IReadOnlyList<Marking> DeadMarkings,
    bool IsDeadlockFree,
    bool IsReversible,
    IReadOnlyList<Marking> HomeStates,
    Liveness[] TransitionLiveness,
    bool IsLive,
    bool IsPersistent)
{
    /// <summary>The smallest k such that every place holds at most k tokens, or null when the net is unbounded.</summary>
    public int? Bound => PlaceBounds.Any(b => b is null) ? null : PlaceBounds.Max(b => b!.Value);
}

/// <summary>
/// Decides the behavioural properties of a net on its reachability graph. Everything here needs
/// the graph to be finite and complete; lesson 5 gets some of the same answers from invariants,
/// without building a graph at all.
/// </summary>
public static class Behaviour
{
    public static NetProperties Analyse(PetriNet net, int limit = 100_000) => Analyse(ReachabilityGraph.Build(net, limit));

    public static NetProperties Analyse(ReachabilityGraph graph)
    {
        ArgumentNullException.ThrowIfNull(graph);
        var net = graph.Net;
        var states = graph.States;
        var successors = new List<int>[states.Count];
        var predecessors = new List<int>[states.Count];
        for (var s = 0; s < states.Count; s++) { successors[s] = []; predecessors[s] = []; }
        foreach (var step in graph.Steps)
        {
            successors[step.From].Add(step.To);
            predecessors[step.To].Add(step.From);
        }

        var bounds = graph.PlaceBounds();
        var isBounded = graph.IsComplete;
        var dead = graph.DeadStates;

        // Reversible: the initial marking is reachable from every reachable marking.
        var toInitial = Backward(predecessors, [0], states.Count);
        var reversible = graph.IsComplete && toInitial.All(x => x);

        var components = StronglyConnectedComponents(successors);
        var homeStates = graph.IsComplete ? HomeStates(components, successors, states) : [];

        var liveness = new Liveness[net.Transitions.Count];
        for (var t = 0; t < net.Transitions.Count; t++)
        {
            var sources = Enumerable.Range(0, states.Count).Where(s => net.IsEnabled(states[s], t)).ToList();
            if (sources.Count == 0) { liveness[t] = Liveness.Dead; continue; }

            // L2/L3: some firing of t lies on a cycle, so it can be repeated for ever.
            var onCycle = graph.Steps.Any(step => step.Transition == t && components[step.From] == components[step.To]);
            if (!onCycle) { liveness[t] = Liveness.L1; continue; }

            // L4: every reachable marking can still reach a marking where t is enabled.
            var canReach = Backward(predecessors, sources, states.Count);
            liveness[t] = canReach.All(x => x) ? Liveness.Live : Liveness.L2L3;
        }

        var persistent = IsPersistent(graph);

        return new NetProperties(
            GraphIsComplete: graph.IsComplete,
            PlaceBounds: bounds,
            IsBounded: isBounded,
            IsSafe: isBounded && bounds.All(b => b <= 1),
            DeadMarkings: [.. dead.Select(s => states[s])],
            IsDeadlockFree: graph.IsComplete && dead.Count == 0,
            IsReversible: reversible,
            HomeStates: homeStates,
            TransitionLiveness: liveness,
            IsLive: graph.IsComplete && liveness.All(l => l == Liveness.Live),
            IsPersistent: persistent);
    }

    /// <summary>
    /// A net is persistent when no enabled transition can be disabled by firing another one:
    /// once a transition may fire, only firing it takes the possibility away (Murata 1989, section II-C).
    /// </summary>
    private static bool IsPersistent(ReachabilityGraph graph)
    {
        var net = graph.Net;
        foreach (var marking in graph.States)
        {
            var enabled = net.EnabledTransitions(marking).ToList();
            foreach (var fired in enabled)
            {
                var next = net.Fire(marking, fired);
                foreach (var other in enabled)
                {
                    if (other != fired && !net.IsEnabled(next, other)) return false;
                }
            }
        }
        return true;
    }

    /// <summary>The states from which at least one of <paramref name="targets"/> can be reached.</summary>
    private static bool[] Backward(List<int>[] predecessors, IEnumerable<int> targets, int count)
    {
        var reached = new bool[count];
        var queue = new Queue<int>();
        foreach (var target in targets)
        {
            if (reached[target]) continue;
            reached[target] = true;
            queue.Enqueue(target);
        }
        while (queue.Count > 0)
        {
            foreach (var previous in predecessors[queue.Dequeue()])
            {
                if (reached[previous]) continue;
                reached[previous] = true;
                queue.Enqueue(previous);
            }
        }
        return reached;
    }

    /// <summary>
    /// A home state is a marking reachable from every reachable marking. There is one exactly when
    /// the graph has a single bottom strongly connected component, and then its markings are the home states.
    /// </summary>
    private static IReadOnlyList<Marking> HomeStates(int[] components, List<int>[] successors, IReadOnlyList<Marking> states)
    {
        var bottom = new HashSet<int>(components);
        for (var s = 0; s < states.Count; s++)
        {
            foreach (var next in successors[s])
            {
                if (components[next] != components[s]) bottom.Remove(components[s]);
            }
        }
        if (bottom.Count != 1) return [];
        var component = bottom.Single();
        return [.. Enumerable.Range(0, states.Count).Where(s => components[s] == component).Select(s => states[s])];
    }

    /// <summary>Tarjan's algorithm, iterative so that a deep graph cannot overflow the stack.</summary>
    private static int[] StronglyConnectedComponents(List<int>[] successors)
    {
        var count = successors.Length;
        var index = new int[count];
        var low = new int[count];
        var onStack = new bool[count];
        var component = new int[count];
        Array.Fill(index, -1);
        Array.Fill(component, -1);
        var stack = new Stack<int>();
        var next = 0;
        var components = 0;

        for (var root = 0; root < count; root++)
        {
            if (index[root] >= 0) continue;
            var work = new Stack<(int Node, int Child)>();
            work.Push((root, 0));
            while (work.Count > 0)
            {
                var (node, child) = work.Pop();
                if (child == 0)
                {
                    index[node] = low[node] = next++;
                    stack.Push(node);
                    onStack[node] = true;
                }
                var recursed = false;
                for (var i = child; i < successors[node].Count; i++)
                {
                    var successor = successors[node][i];
                    if (index[successor] < 0)
                    {
                        work.Push((node, i + 1));
                        work.Push((successor, 0));
                        recursed = true;
                        break;
                    }
                    if (onStack[successor]) low[node] = Math.Min(low[node], index[successor]);
                }
                if (recursed) continue;

                if (low[node] == index[node])
                {
                    while (true)
                    {
                        var member = stack.Pop();
                        onStack[member] = false;
                        component[member] = components;
                        if (member == node) break;
                    }
                    components++;
                }
                if (work.Count > 0)
                {
                    var (parent, _) = work.Peek();
                    low[parent] = Math.Min(low[parent], low[node]);
                }
            }
        }

        return component;
    }
}
