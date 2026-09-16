using System.Text;

namespace PetriNets;

/// <summary>
/// Draws a net as a Mermaid flowchart, the form the lessons embed. Places are circles,
/// transitions are rectangles, and the tokens of the initial marking are shown inside the place.
/// The diagrams in the lessons are produced by this code, so a net and its picture cannot drift apart.
/// </summary>
public static class Mermaid
{
    public static string Draw(PetriNet net, string direction = "LR")
    {
        ArgumentNullException.ThrowIfNull(net);
        var text = new StringBuilder();
        text.AppendLine($"flowchart {direction}");

        for (var p = 0; p < net.Places.Count; p++)
        {
            var tokens = net.InitialMarking[p];
            var label = tokens == 0 ? net.Places[p].Name : $"{net.Places[p].Name}<br/>{Tokens(tokens)}";
            text.AppendLine($"    {Node(net.Places[p].Id)}((\"{label}\"))");
        }

        foreach (var transition in net.Transitions)
            text.AppendLine($"    {Node(transition.Id)}[\"{transition.Name}\"]");

        foreach (var arc in net.Arcs)
        {
            var arrow = arc.Weight == 1 ? "-->" : $"-- {arc.Weight} -->";
            text.AppendLine($"    {Node(arc.Source)} {arrow} {Node(arc.Target)}");
        }

        return text.ToString();
    }

    /// <summary>
    /// Draws a reachability graph: one node per marking, one arrow per firing. Only worth looking at
    /// for the small nets of the early lessons; past a few dozen markings, read the text instead.
    /// </summary>
    public static string DrawGraph(ReachabilityGraph graph, string direction = "LR")
    {
        ArgumentNullException.ThrowIfNull(graph);
        var net = graph.Net;
        var text = new StringBuilder();
        text.AppendLine($"flowchart {direction}");
        for (var s = 0; s < graph.States.Count; s++)
            text.AppendLine($"    M{s}[\"M{s}<br/>{graph.States[s]}\"]");
        foreach (var step in graph.Steps)
            text.AppendLine($"    M{step.From} -- {net.Transitions[step.Transition].Name} --> M{step.To}");
        return text.ToString();
    }

    /// <summary>Up to three tokens are drawn as dots, more as a number: a picture of ten dots says nothing.</summary>
    private static string Tokens(int count) => count switch
    {
        Marking.Omega => "ω",
        <= 3 => string.Join(" ", Enumerable.Repeat("●", count)),
        _ => count.ToString(),
    };

    /// <summary>Mermaid node ids are bare words, so anything else becomes an underscore.</summary>
    private static string Node(string id) =>
        new([.. id.Select(c => char.IsLetterOrDigit(c) ? c : '_')]);
}
