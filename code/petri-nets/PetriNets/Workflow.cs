namespace PetriNets;

/// <summary>
/// What the soundness check found, condition by condition. The three conditions are van der
/// Aalst's: from every reachable marking the case can still finish, finishing leaves nothing
/// behind, and no task is unreachable. A net that fails one of them is unsound, and the report
/// says which one and with which marking, because "unsound" on its own is not actionable.
/// </summary>
public sealed record WorkflowCheck(
    string Net,
    bool IsWorkflowNet,
    string? WhyNotAWorkflowNet,
    string? Source,
    string? Sink,
    bool GraphIsComplete,
    int States,
    bool FinalReachable,
    bool OptionToComplete,
    IReadOnlyList<Marking> Stuck,
    bool ProperCompletion,
    IReadOnlyList<Marking> Improper,
    IReadOnlyList<string> DeadTransitions)
{
    /// <summary>Sound: the three conditions hold, on a net that is a workflow net with a finite state space.</summary>
    public bool IsSound =>
        IsWorkflowNet && GraphIsComplete && OptionToComplete && ProperCompletion && DeadTransitions.Count == 0;
}

/// <summary>
/// Workflow nets and their soundness, in the sense of van der Aalst 1997. A workflow net is an
/// ordinary Petri net with one source place, one sink place, and nothing that is not on a path
/// between the two; soundness is the property a business process is supposed to have and that
/// the nets of lessons 1 to 9 never had to.
/// </summary>
public static class Workflow
{
    /// <summary>
    /// The source and the sink, or null with a reason. A workflow net has exactly one place with
    /// no incoming arc, exactly one with no outgoing arc, and every node on a path from one to the
    /// other — which is the same as saying the short-circuited net is strongly connected.
    /// </summary>
    public static (int Source, int Sink)? Endpoints(PetriNet net, out string? whyNot)
    {
        ArgumentNullException.ThrowIfNull(net);
        whyNot = null;

        var sources = Enumerable.Range(0, net.Places.Count)
            .Where(p => Structure.InputTransitions(net, p).Count == 0).ToList();
        var sinks = Enumerable.Range(0, net.Places.Count)
            .Where(p => Structure.OutputTransitions(net, p).Count == 0).ToList();

        if (sources.Count != 1)
        {
            whyNot = sources.Count == 0
                ? "no place is a source: every place has an incoming arc, so nothing starts the case"
                : $"{sources.Count} places are sources ({Names(net, sources)}); a workflow net has one";
            return null;
        }
        if (sinks.Count != 1)
        {
            whyNot = sinks.Count == 0
                ? "no place is a sink: every place has an outgoing arc, so the case never ends"
                : $"{sinks.Count} places are sinks ({Names(net, sinks)}); a workflow net has one";
            return null;
        }
        if (sources[0] == sinks[0])
        {
            whyNot = $"{net.Places[sources[0]].Name} is both the source and the sink; the net has no path to take";
            return null;
        }

        if (!Structure.IsStronglyConnected(ShortCircuit(net)))
        {
            whyNot = "the short-circuited net is not strongly connected: some node is not on a path from the source to the sink";
            return null;
        }

        return (sources[0], sinks[0]);
    }

    /// <summary>
    /// The short-circuited net: the same net plus one transition from the sink back to the source.
    /// Van der Aalst's theorem says the workflow is sound exactly when this net is live and
    /// bounded, which turns a question about a process into the two questions of lesson 4.
    /// </summary>
    public static PetriNet ShortCircuit(PetriNet net, string transition = "t-star")
    {
        ArgumentNullException.ThrowIfNull(net);
        var sources = Enumerable.Range(0, net.Places.Count)
            .Where(p => Structure.InputTransitions(net, p).Count == 0).ToList();
        var sinks = Enumerable.Range(0, net.Places.Count)
            .Where(p => Structure.OutputTransitions(net, p).Count == 0).ToList();
        if (sources.Count != 1 || sinks.Count != 1 || sources[0] == sinks[0])
            throw new ArgumentException($"{net.Name} has {sources.Count} source(s) and {sinks.Count} sink(s); it cannot be short-circuited.", nameof(net));

        var source = net.Places[sources[0]].Id;
        var sink = net.Places[sinks[0]].Id;
        return new PetriNet(
            net.Name + "-short-circuited",
            net.Places,
            [.. net.Transitions, new Transition(transition, transition)],
            [.. net.Arcs, new Arc(sink, transition), new Arc(transition, source)],
            net.InitialMarking);
    }

    /// <summary>The marking with one token in the given place and nothing anywhere else.</summary>
    public static Marking OneToken(PetriNet net, int place)
    {
        ArgumentNullException.ThrowIfNull(net);
        var tokens = new int[net.Places.Count];
        tokens[place] = 1;
        return new Marking(tokens);
    }

    /// <summary>
    /// Decides the three soundness conditions on the reachability graph of the net started with
    /// one token in its source. The answers are marked with the marking that breaks them, since
    /// a process owner needs the counter-example rather than the verdict.
    /// </summary>
    public static WorkflowCheck Check(PetriNet net, int limit = 100_000)
    {
        ArgumentNullException.ThrowIfNull(net);
        var endpoints = Endpoints(net, out var whyNot);
        if (endpoints is null)
            return new WorkflowCheck(net.Name, false, whyNot, null, null, false, 0, false, false, [], false, [], []);

        var (source, sink) = endpoints.Value;
        var start = OneToken(net, source);
        if (!net.InitialMarking.Equals(start))
            throw new ArgumentException(
                $"{net.Name} starts at {net.InitialMarking.ToString(net)}; a workflow net starts with one token in {net.Places[source].Name}.", nameof(net));

        var graph = ReachabilityGraph.Build(net, limit);
        var final = OneToken(net, sink);

        // Option to complete: the final marking is reachable from every reachable marking.
        var predecessors = new List<int>[graph.States.Count];
        for (var s = 0; s < graph.States.Count; s++) predecessors[s] = [];
        foreach (var step in graph.Steps) predecessors[step.To].Add(step.From);

        var finalState = -1;
        for (var s = 0; s < graph.States.Count; s++)
            if (graph.States[s].Equals(final)) { finalState = s; break; }

        var reachesFinal = new bool[graph.States.Count];
        if (finalState >= 0)
        {
            var queue = new Queue<int>();
            reachesFinal[finalState] = true;
            queue.Enqueue(finalState);
            while (queue.Count > 0)
                foreach (var p in predecessors[queue.Dequeue()])
                    if (!reachesFinal[p]) { reachesFinal[p] = true; queue.Enqueue(p); }
        }
        var stuck = Enumerable.Range(0, graph.States.Count)
            .Where(s => !reachesFinal[s]).Select(s => graph.States[s]).ToList();

        // Proper completion: no reachable marking puts a token in the sink and leaves something else behind.
        var improper = graph.States
            .Where(m => m[sink] > 0 && !m.Equals(final))
            .ToList();

        // No dead transitions: every transition is enabled somewhere.
        var deadTransitions = Enumerable.Range(0, net.Transitions.Count)
            .Where(t => !graph.States.Any(m => net.IsEnabled(m, t)))
            .Select(t => net.Transitions[t].Name)
            .ToList();

        return new WorkflowCheck(
            Net: net.Name,
            IsWorkflowNet: true,
            WhyNotAWorkflowNet: null,
            Source: net.Places[source].Name,
            Sink: net.Places[sink].Name,
            GraphIsComplete: graph.IsComplete,
            States: graph.States.Count,
            FinalReachable: finalState >= 0,
            OptionToComplete: graph.IsComplete && stuck.Count == 0,
            Stuck: stuck,
            ProperCompletion: improper.Count == 0,
            Improper: improper,
            DeadTransitions: deadTransitions);
    }

    /// <summary>
    /// The other route to the same verdict: van der Aalst's theorem says a workflow net is sound
    /// exactly when its short-circuit is live and bounded. Returns the two properties so a lesson
    /// can compare them with <see cref="Check"/> rather than trust either alone.
    /// </summary>
    public static (bool Live, bool Bounded) ShortCircuitVerdict(PetriNet net, int limit = 100_000)
    {
        var properties = Behaviour.Analyse(ShortCircuit(net), limit);
        return (properties.IsLive, properties.IsBounded);
    }

    private static string Names(PetriNet net, IEnumerable<int> places) =>
        string.Join(", ", places.Select(p => net.Places[p].Name));
}
