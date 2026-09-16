namespace PetriNets;

/// <summary>A node of the coverability tree: its marking, how it was reached, and how it ended.</summary>
public sealed record CoverabilityNode(int Id, int Parent, int Transition, Marking Marking, NodeKind Kind)
{
    /// <summary>Distance from the root, filled in by the builder.</summary>
    public int Depth { get; init; }
}

public enum NodeKind
{
    /// <summary>The node has children.</summary>
    Interior,

    /// <summary>No transition is enabled: a dead end of the tree, and a dead marking of the net.</summary>
    Terminal,

    /// <summary>Its marking already appears on the path from the root: nothing new grows below it.</summary>
    Duplicate,
}

/// <summary>
/// The coverability tree of Karp and Miller (1969), as presented in Murata 1989, section IV-A.
/// When a new marking strictly covers one of its own ancestors, the places that grew are set to
/// omega, which stands for "any number of tokens". That makes the tree finite even when the
/// reachability set is not, at the price of forgetting how many tokens those places really hold.
/// </summary>
public sealed class CoverabilityTree
{
    private CoverabilityTree(PetriNet net, IReadOnlyList<CoverabilityNode> nodes)
    {
        Net = net;
        Nodes = nodes;
    }

    public PetriNet Net { get; }

    public IReadOnlyList<CoverabilityNode> Nodes { get; }

    /// <summary>True when no node holds omega: the net is bounded.</summary>
    public bool IsBounded => !Nodes.Any(n => n.Marking.HasOmega);

    /// <summary>The greatest number of tokens a place can hold, or null when that place is unbounded.</summary>
    public int?[] PlaceBounds()
    {
        var bounds = new int?[Net.Places.Count];
        for (var p = 0; p < Net.Places.Count; p++)
            bounds[p] = Nodes.Any(n => n.Marking[p] == Marking.Omega) ? null : Nodes.Max(n => n.Marking[p]);
        return bounds;
    }

    /// <summary>The transitions that label no arc of the tree: they can never fire (Murata 1989, section IV-A).</summary>
    public IReadOnlyList<int> DeadTransitions()
    {
        var fired = Nodes.Where(n => n.Transition >= 0).Select(n => n.Transition).ToHashSet();
        return [.. Enumerable.Range(0, Net.Transitions.Count).Where(t => !fired.Contains(t))];
    }

    public static CoverabilityTree Build(PetriNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        var nodes = new List<CoverabilityNode>
        {
            new(0, -1, -1, net.InitialMarking, NodeKind.Interior) { Depth = 0 },
        };
        var queue = new Queue<int>();
        queue.Enqueue(0);

        while (queue.Count > 0)
        {
            var id = queue.Dequeue();
            var node = nodes[id];
            var enabled = net.EnabledTransitions(node.Marking).ToList();
            if (enabled.Count == 0)
            {
                nodes[id] = node with { Kind = NodeKind.Terminal };
                continue;
            }

            foreach (var t in enabled)
            {
                var marking = WithOmegas(net, nodes, id, net.Fire(node.Marking, t));
                var onPath = Ancestors(nodes, id).Append(node).Any(a => a.Marking.Equals(marking));
                var child = new CoverabilityNode(nodes.Count, id, t, marking,
                    onPath ? NodeKind.Duplicate : NodeKind.Interior)
                { Depth = node.Depth + 1 };
                nodes.Add(child);
                if (!onPath) queue.Enqueue(child.Id);
            }
        }

        return new CoverabilityTree(net, nodes);
    }

    /// <summary>Replaces by omega every place that grew since an ancestor this marking strictly covers.</summary>
    private static Marking WithOmegas(PetriNet net, List<CoverabilityNode> nodes, int parent, Marking marking)
    {
        var tokens = marking.ToArray();
        foreach (var ancestor in Ancestors(nodes, parent).Append(nodes[parent]))
        {
            if (!marking.StrictlyCovers(ancestor.Marking)) continue;
            for (var p = 0; p < net.Places.Count; p++)
            {
                if (tokens[p] != Marking.Omega && tokens[p] > ancestor.Marking[p]) tokens[p] = Marking.Omega;
            }
        }
        return new Marking(tokens);
    }

    private static IEnumerable<CoverabilityNode> Ancestors(List<CoverabilityNode> nodes, int id)
    {
        for (var parent = nodes[id].Parent; parent >= 0; parent = nodes[parent].Parent)
            yield return nodes[parent];
    }
}
