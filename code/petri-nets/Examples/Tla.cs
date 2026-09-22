using System.Globalization;
using System.Text;
using PetriNets;

namespace Examples;

/// <summary>
/// Writes a net as a TLA+ module, so TLC can enumerate the same state space the analyser does.
///
/// The firing rule itself is written once, by hand, in <c>tla/PetriNet.tla</c>. What is generated here is only the
/// net: its places, its transitions, its arcs as records, its initial marking, and the cap TLC needs. The generated
/// module instantiates the hand-written one, which keeps the semantics in a file a reader can check rather than in
/// string concatenation.
///
/// TLA+ has no notion of boundedness — a specification is a set of behaviours, not a graph — so a net whose places
/// can grow would send TLC enumerating for ever with no way to say so. The <c>Cap</c> constant, used by the
/// <c>Bounded</c> state constraint, comes from <see cref="Invariants.PlaceBounds"/>: the structure theory of
/// lesson 5 supplies the number that the model checker cannot derive.
/// </summary>
public static class Tla
{
    /// <summary>The cap written for a net whose places the invariants do not bound. TLC then explores a truncation.</summary>
    public const int UnboundedCap = 3;

    /// <summary>A TLA+ module name: the net's name with anything that is not a letter, a digit or an underscore replaced.</summary>
    public static string ModuleName(PetriNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        var chars = net.Name.Select(c => char.IsLetterOrDigit(c) ? c : '_').ToArray();
        return char.IsDigit(chars[0]) ? "n" + new string(chars) : new string(chars);
    }

    /// <summary>The cap the generated module carries, and whether the invariants produced it.</summary>
    public static (int Cap, bool FromInvariants) Cap(PetriNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        var bounds = Invariants.PlaceBounds(net);
        if (bounds.Any(b => b is null)) return (UnboundedCap, false);
        return (Math.Max(1, bounds.Max(b => b!.Value)), true);
    }

    /// <summary>The generated module for <paramref name="net"/>.</summary>
    public static string Module(PetriNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        var name = ModuleName(net);
        var (cap, fromInvariants) = Cap(net);
        var marked = net.Places.Select((p, i) => (p, i)).Where(x => net.InitialMarking[x.i] > 0).ToList();

        var sb = new StringBuilder();
        sb.Append(Header(name)).Append('\n');
        sb.Append("EXTENDS Naturals\n\n");
        sb.Append("Places == ").Append(Set(net.Places.Select(p => Quote(p.Id)))).Append("\n");
        sb.Append("Transitions == ").Append(Set(net.Transitions.Select(t => Quote(t.Id)))).Append("\n\n");
        sb.Append("PreArcs == ").Append(Arcs(net, pre: true)).Append("\n\n");
        sb.Append("PostArcs == ").Append(Arcs(net, pre: false)).Append("\n\n");
        sb.Append("M0 == [p \\in Places |-> ").Append(InitialMarking(net, marked)).Append("]\n");
        sb.Append(fromInvariants
            ? $"\\* Every place is bounded by {cap} (Invariants.PlaceBounds), so the constraint truncates nothing.\n"
            : $"\\* No invariant bounds every place: {cap} truncates the state space and TLC cannot tell you so.\n");
        sb.Append("Cap == ").Append(cap.ToString(CultureInfo.InvariantCulture)).Append("\n\n");
        sb.Append("VARIABLE marking\nINSTANCE PetriNet\n");
        sb.Append(new string('=', 77)).Append('\n');
        return sb.ToString();
    }

    /// <summary>
    /// The configuration TLC reads next to the module.
    ///
    /// <c>CHECK_DEADLOCK FALSE</c> is not a convenience. TLC calls a state with no successor a deadlock and stops
    /// there, because a TLA+ specification describes a system that runs for ever. A Petri net has no such
    /// assumption: the final marking of a workflow net is the point of the net, and a dead marking is something
    /// this course computes and reports rather than something that aborts the run. Left on, TLC stopped after
    /// three of `retry`'s eight markings.
    /// </summary>
    public static string Config() => "SPECIFICATION Spec\nCONSTRAINT Bounded\nINVARIANT TypeOK\nCHECK_DEADLOCK FALSE\n";

    /// <summary>Writes the module and its configuration into <paramref name="directory"/>, and returns the module's path.</summary>
    public static string Write(PetriNet net, string directory)
    {
        ArgumentNullException.ThrowIfNull(net);
        Directory.CreateDirectory(directory);
        var name = ModuleName(net);
        var path = Path.Combine(directory, name + ".tla");
        File.WriteAllText(path, Module(net));
        File.WriteAllText(Path.Combine(directory, name + ".cfg"), Config());
        return path;
    }

    private static string Header(string name)
    {
        // A TLA+ module header is dashes, the name, dashes, padded to a fixed width.
        var dashes = Math.Max(4, (77 - name.Length - 16) / 2);
        return new string('-', dashes) + " MODULE " + name + " " + new string('-', dashes);
    }

    private static string Quote(string s) => "\"" + s + "\"";

    private static string Set(IEnumerable<string> items)
    {
        var list = items.ToList();
        return list.Count == 0 ? "{}" : "{" + string.Join(", ", list) + "}";
    }

    private static string Arcs(PetriNet net, bool pre)
    {
        var rows = new List<string>();
        for (var t = 0; t < net.Transitions.Count; t++)
            for (var p = 0; p < net.Places.Count; p++)
            {
                var w = pre ? net.Pre[p, t] : net.Post[p, t];
                if (w > 0)
                    rows.Add($"    [p |-> {Quote(net.Places[p].Id)}, t |-> {Quote(net.Transitions[t].Id)}, w |-> {w.ToString(CultureInfo.InvariantCulture)}]");
            }
        return rows.Count == 0 ? "{}" : "{\n" + string.Join(",\n", rows) + "\n}";
    }

    private static string InitialMarking(PetriNet net, IReadOnlyList<(Place Place, int Index)> marked)
    {
        if (marked.Count == 0) return "0";
        // Places sharing a token count are grouped, so the literal reads like the marking rather than like a table.
        var groups = marked.GroupBy(x => net.InitialMarking[x.Index]).OrderByDescending(g => g.Key).ToList();
        var sb = new StringBuilder();
        foreach (var g in groups)
        {
            var set = Set(g.Select(x => Quote(x.Place.Id)));
            sb.Append("IF p \\in ").Append(set).Append(" THEN ").Append(g.Key.ToString(CultureInfo.InvariantCulture)).Append(" ELSE ");
        }
        sb.Append('0');
        return sb.ToString();
    }
}
