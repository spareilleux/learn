using System.Text;

namespace PetriNets;

/// <summary>
/// Turns a net and its analyses into plain text. Everything printed here is sorted or indexed,
/// never taken from the order of a dictionary, so the same net gives the same text on every
/// machine and check.sh can compare it with a file.
/// </summary>
public static class Report
{
    /// <summary>The net itself: places with their initial tokens, transitions, and weighted arcs.</summary>
    public static string Net(PetriNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        var text = new StringBuilder();
        text.AppendLine($"net {net.Name}");
        text.AppendLine($"places      {string.Join(" ", net.Places.Select(p => p.Name))}");
        text.AppendLine($"transitions {string.Join(" ", net.Transitions.Select(t => t.Name))}");
        text.AppendLine($"M0          {net.InitialMarking} = {net.InitialMarking.ToString(net)}");
        foreach (var arc in net.Arcs)
        {
            var source = Label(net, arc.Source);
            var target = Label(net, arc.Target);
            text.AppendLine($"arc         {source} -> {target}" + (arc.Weight == 1 ? "" : $" (weight {arc.Weight})"));
        }
        return text.ToString();
    }

    /// <summary>The matrices Pre, Post and C = Post - Pre, one row per place and one column per transition.</summary>
    public static string Matrices(PetriNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        var text = new StringBuilder();
        text.Append(Matrix(net, net.Pre, "Pre (tokens a firing takes from the place)"));
        text.Append(Matrix(net, net.Post, "Post (tokens a firing puts into the place)"));
        text.Append(Matrix(net, net.Incidence(), "C = Post - Pre (change of marking per firing)"));
        return text.ToString();
    }

    public static string Matrix(PetriNet net, int[,] matrix, string title)
    {
        ArgumentNullException.ThrowIfNull(net);
        ArgumentNullException.ThrowIfNull(matrix);
        var width = Math.Max(net.Transitions.Max(t => t.Name.Length), 2) + 1;
        var labelWidth = net.Places.Max(p => p.Name.Length) + 1;
        var text = new StringBuilder();
        text.AppendLine(title);
        text.Append(new string(' ', labelWidth));
        foreach (var transition in net.Transitions) text.Append(transition.Name.PadLeft(width));
        text.AppendLine();
        for (var p = 0; p < net.Places.Count; p++)
        {
            text.Append(net.Places[p].Name.PadRight(labelWidth));
            for (var t = 0; t < net.Transitions.Count; t++) text.Append(matrix[p, t].ToString().PadLeft(width));
            text.AppendLine();
        }
        return text.ToString();
    }

    /// <summary>A firing sequence, one line per marking, with the transition that produced it.</summary>
    public static string Sequence(PetriNet net, Marking start, params string[] transitions)
    {
        ArgumentNullException.ThrowIfNull(net);
        var markings = net.FireSequence(start, transitions);
        var text = new StringBuilder();
        text.AppendLine($"          {markings[0]}  {markings[0].ToString(net)}");
        for (var i = 0; i < transitions.Length; i++)
        {
            var name = net.Transitions[net.TransitionIndex(transitions[i])].Name;
            text.AppendLine($"{name,-10}{markings[i + 1]}  {markings[i + 1].ToString(net)}");
        }
        return text.ToString();
    }

    /// <summary>The reachability graph: its states, then its firings.</summary>
    public static string Graph(ReachabilityGraph graph)
    {
        ArgumentNullException.ThrowIfNull(graph);
        var net = graph.Net;
        var text = new StringBuilder();
        text.AppendLine($"reachability graph of {net.Name}: {Plural(graph.States.Count, "state")}, {Plural(graph.Steps.Count, "firing")}"
                        + (graph.IsComplete ? "" : $" (stopped at the limit of {graph.Limit} states)"));
        text.AppendLine($"places {string.Join(" ", net.Places.Select(p => p.Name))}");
        for (var s = 0; s < graph.States.Count; s++)
            text.AppendLine($"  M{s} = {graph.States[s]}  {graph.States[s].ToString(net)}");
        foreach (var step in graph.Steps)
            text.AppendLine($"  M{step.From} --{net.Transitions[step.Transition].Name}--> M{step.To}");
        foreach (var s in graph.DeadStates)
            text.AppendLine($"  dead marking M{s} = {graph.States[s]}  {graph.States[s].ToString(net)}");
        return text.ToString();
    }

    /// <summary>The coverability tree, indented by depth.</summary>
    public static string Tree(CoverabilityTree tree)
    {
        ArgumentNullException.ThrowIfNull(tree);
        var net = tree.Net;
        var text = new StringBuilder();
        text.AppendLine($"coverability tree of {net.Name}: {Plural(tree.Nodes.Count, "node")}");
        text.AppendLine($"places {string.Join(" ", net.Places.Select(p => p.Name))}");
        var children = tree.Nodes.GroupBy(n => n.Parent).ToDictionary(g => g.Key, g => g.ToList());
        Walk(tree.Nodes[0]);

        void Walk(CoverabilityNode node)
        {
            var arrow = node.Transition < 0 ? "root" : $"{net.Transitions[node.Transition].Name} ->";
            var kind = node.Kind switch
            {
                NodeKind.Terminal => "  [dead end]",
                NodeKind.Duplicate => "  [already on this path]",
                _ => "",
            };
            text.AppendLine($"  {new string(' ', node.Depth * 2)}{arrow} {node.Marking}{kind}");
            if (!children.TryGetValue(node.Id, out var below)) return;
            foreach (var child in below) Walk(child);
        }
        var bounds = tree.PlaceBounds();
        for (var p = 0; p < net.Places.Count; p++)
            text.AppendLine($"  bound of {net.Places[p].Name}: {(bounds[p] is { } b ? b.ToString() : "unbounded")}");
        var deadTransitions = tree.DeadTransitions();
        text.AppendLine("  dead transitions: " + (deadTransitions.Count == 0
            ? "none"
            : string.Join(" ", deadTransitions.Select(t => net.Transitions[t].Name))));
        return text.ToString();
    }

    /// <summary>The behavioural properties of lesson 4, one per line.</summary>
    public static string Properties(PetriNet net, NetProperties properties)
    {
        ArgumentNullException.ThrowIfNull(net);
        ArgumentNullException.ThrowIfNull(properties);
        var text = new StringBuilder();
        text.AppendLine($"properties of {net.Name}");
        for (var p = 0; p < net.Places.Count; p++)
        {
            var bound = properties.PlaceBounds[p];
            text.AppendLine($"  bound of {net.Places[p].Name}: {(bound is { } b ? b.ToString() : "unbounded")}");
        }
        text.AppendLine($"  bounded:       {YesNo(properties.IsBounded)}"
                        + (properties.Bound is { } k ? $" ({k}-bounded)" : ""));
        text.AppendLine($"  safe:          {YesNo(properties.IsSafe)}");
        text.AppendLine($"  deadlock-free: {YesNo(properties.IsDeadlockFree)}");
        foreach (var marking in properties.DeadMarkings)
            text.AppendLine($"    dead marking {marking}  {marking.ToString(net)}");
        text.AppendLine($"  live:          {YesNo(properties.IsLive)}");
        for (var t = 0; t < net.Transitions.Count; t++)
        {
            var level = properties.TransitionLiveness[t] switch
            {
                Liveness.Dead => "L0, dead",
                Liveness.L1 => "L1, can fire once",
                Liveness.L2L3 => "L2/L3, can fire for ever but not from everywhere",
                _ => "L4, live",
            };
            text.AppendLine($"    {net.Transitions[t].Name,-10} {level}");
        }
        text.AppendLine($"  reversible:    {YesNo(properties.IsReversible)}");
        text.AppendLine("  home states:   " + HomeStates(properties));
        text.AppendLine($"  persistent:    {YesNo(properties.IsPersistent)}");
        return text.ToString();
    }

    /// <summary>The place and transition invariants, with what each one conserves at M0.</summary>
    public static string InvariantReport(PetriNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        var text = new StringBuilder();
        text.AppendLine($"invariants of {net.Name}");
        var places = Invariants.Places(net);
        text.AppendLine($"  place invariants ({places.Count}):");
        foreach (var invariant in places)
        {
            var terms = invariant.Support.Select(i =>
                (invariant.Weights[i] == 1 ? "" : invariant.Weights[i] + "*") + net.Places[i].Name);
            text.AppendLine($"    {string.Join(" + ", terms)} = {Invariants.WeightedTokens(invariant, net.InitialMarking)}");
        }
        var transitions = Invariants.Transitions(net);
        text.AppendLine($"  transition invariants ({transitions.Count}):");
        foreach (var invariant in transitions)
        {
            var terms = invariant.Support.Select(i =>
                (invariant.Weights[i] == 1 ? "" : invariant.Weights[i] + "*") + net.Transitions[i].Name);
            text.AppendLine($"    {string.Join(" + ", terms)}");
        }
        return text.ToString();
    }

    /// <summary>Lists the home states, or just counts them when there are too many to read.</summary>
    private static string HomeStates(NetProperties properties) => properties.HomeStates.Count switch
    {
        0 => "none",
        > 6 => Plural(properties.HomeStates.Count, "marking"),
        _ => string.Join(" ", properties.HomeStates.Select(m => m.ToString())),
    };

    private static string YesNo(bool value) => value ? "yes" : "no";

    private static string Plural(int count, string noun) => $"{count} {noun}" + (count == 1 ? "" : "s");

    private static string Label(PetriNet net, string id)
    {
        foreach (var place in net.Places)
        {
            if (place.Id == id) return place.Name;
        }
        foreach (var transition in net.Transitions)
        {
            if (transition.Id == id) return transition.Name;
        }
        return id;
    }
}
