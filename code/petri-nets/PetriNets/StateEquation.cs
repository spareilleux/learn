namespace PetriNets;

/// <summary>
/// The state equation M = M0 + C x of Murata 1989, section V-A. It says what the accounting
/// allows; it says nothing about the order in which transitions could fire, which is why a
/// solution is a necessary condition for reachability and not a sufficient one.
/// </summary>
public static class StateEquation
{
    /// <summary>
    /// Applies the equation: the marking obtained from <paramref name="start"/> by firing each
    /// transition <paramref name="firingCount"/> times, in any order that works. Entries may come
    /// out negative, and a negative entry is the equation's way of saying "no order works".
    /// </summary>
    public static int[] Apply(PetriNet net, Marking start, int[] firingCount)
    {
        ArgumentNullException.ThrowIfNull(net);
        ArgumentNullException.ThrowIfNull(start);
        ArgumentNullException.ThrowIfNull(firingCount);
        var c = net.Incidence();
        var result = start.ToArray();
        for (var p = 0; p < net.Places.Count; p++)
            for (var t = 0; t < net.Transitions.Count; t++)
                result[p] += c[p, t] * firingCount[t];
        return result;
    }

    /// <summary>
    /// Searches for a non-negative integer firing count vector x with M = M0 + C x, trying each
    /// transition at most <paramref name="maxPerTransition"/> times. Exhaustive within that bound,
    /// and deterministic: the first solution in lexicographic order is returned.
    /// </summary>
    public static int[]? Solve(PetriNet net, Marking target, int maxPerTransition = 8)
    {
        ArgumentNullException.ThrowIfNull(net);
        ArgumentNullException.ThrowIfNull(target);
        var x = new int[net.Transitions.Count];
        return Search(net, target, x, 0, maxPerTransition) ? x : null;
    }

    private static bool Search(PetriNet net, Marking target, int[] x, int t, int max)
    {
        if (t == net.Transitions.Count)
        {
            var reached = Apply(net, net.InitialMarking, x);
            for (var p = 0; p < net.Places.Count; p++)
            {
                if (reached[p] != target[p]) return false;
            }
            return true;
        }
        for (var n = 0; n <= max; n++)
        {
            x[t] = n;
            if (Search(net, target, x, t + 1, max)) return true;
        }
        x[t] = 0;
        return false;
    }

    /// <summary>
    /// The markings the state equation accepts but the net cannot reach, up to
    /// <paramref name="maxTokens"/> tokens in total. These are the spurious solutions:
    /// the accounting balances, the schedule does not exist.
    /// </summary>
    public static IReadOnlyList<Marking> SpuriousMarkings(PetriNet net, int maxTokens, int maxPerTransition = 8)
    {
        ArgumentNullException.ThrowIfNull(net);
        var graph = ReachabilityGraph.Build(net);
        if (!graph.IsComplete) throw new ArgumentException("The net is not bounded here.", nameof(net));
        var reachable = graph.States.ToHashSet();
        var spurious = new List<Marking>();
        foreach (var candidate in Markings(net.Places.Count, maxTokens))
        {
            if (reachable.Contains(candidate)) continue;
            if (Solve(net, candidate, maxPerTransition) is not null) spurious.Add(candidate);
        }
        return spurious;
    }

    /// <summary>Every marking of <paramref name="places"/> places holding at most <paramref name="maxTokens"/> tokens in total, in lexicographic order.</summary>
    private static IEnumerable<Marking> Markings(int places, int maxTokens)
    {
        var tokens = new int[places];
        return Enumerate(0, maxTokens);

        IEnumerable<Marking> Enumerate(int place, int budget)
        {
            if (place == places)
            {
                yield return new Marking(tokens);
                yield break;
            }
            for (var n = 0; n <= budget; n++)
            {
                tokens[place] = n;
                foreach (var marking in Enumerate(place + 1, budget - n)) yield return marking;
            }
            tokens[place] = 0;
        }
    }
}
