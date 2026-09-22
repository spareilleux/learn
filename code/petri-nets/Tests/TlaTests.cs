using System.Text.RegularExpressions;
using Examples;
using PetriNets;
using Xunit;

namespace Tests;

/// <summary>
/// Lesson 13. TLC reads the generated modules, this project does not, so a mistake in
/// <see cref="Tla"/> would only show up as a module that fails to parse an hour later. These tests
/// hold the shape TLC needs, and the two decisions the lesson measured: the cap comes from the
/// place invariants, and the deadlock check is off because a dead marking is a result here rather
/// than an error.
/// </summary>
public class TlaTests
{
    [Fact]
    public void A_module_opens_and_closes_the_way_the_parser_expects()
    {
        var text = Tla.Module(Nets.MutualExclusion());
        Assert.Matches(new Regex(@"^-{4,} MODULE mutual_exclusion -{4,}\r?\n"), text);
        Assert.EndsWith("=============================================================================\n", text, StringComparison.Ordinal);
        Assert.Contains("VARIABLE marking\nINSTANCE PetriNet\n", text.Replace("\r\n", "\n"), StringComparison.Ordinal);
    }

    [Fact]
    public void Every_place_and_every_transition_reaches_the_module()
    {
        foreach (var net in Nets.All)
        {
            var text = Tla.Module(net);
            foreach (var place in net.Places)
                Assert.Contains($"\"{place.Id}\"", text, StringComparison.Ordinal);
            foreach (var transition in net.Transitions)
                Assert.Contains($"\"{transition.Id}\"", text, StringComparison.Ordinal);
        }
    }

    [Fact]
    public void Every_arc_of_every_net_is_written_once_with_its_weight()
    {
        foreach (var net in Nets.All)
        {
            var text = Tla.Module(net);
            var pre = 0;
            var post = 0;
            for (var p = 0; p < net.Places.Count; p++)
                for (var t = 0; t < net.Transitions.Count; t++)
                {
                    if (net.Pre[p, t] > 0) pre++;
                    if (net.Post[p, t] > 0) post++;
                    if (net.Pre[p, t] > 1 || net.Post[p, t] > 1)
                        Assert.Contains($"w |-> {Math.Max(net.Pre[p, t], net.Post[p, t])}]", text, StringComparison.Ordinal);
                }
            var sections = text.Split("PostArcs ==", StringSplitOptions.None);
            Assert.Equal(2, sections.Length);
            Assert.Equal(pre, Count(sections[0], "[p |->"));
            Assert.Equal(post, Count(sections[1], "[p |->"));
        }
    }

    [Fact]
    public void Module_names_are_identifiers_and_stay_distinct()
    {
        var names = Nets.All.Select(Tla.ModuleName).ToList();
        Assert.Equal(names.Count, names.Distinct(StringComparer.Ordinal).Count());
        foreach (var name in names)
            Assert.Matches(new Regex("^[A-Za-z_][A-Za-z0-9_]*$"), name);
    }

    [Fact]
    public void The_cap_is_the_bound_the_invariants_prove_and_the_graph_confirms()
    {
        foreach (var net in Nets.All)
        {
            var (cap, fromInvariants) = Tla.Cap(net);
            if (!fromInvariants)
            {
                // A place invariant proves boundedness and never disproves it: handshake has no invariant
                // over every place and exactly one marking, so the only claim that holds here is the cap.
                Assert.Equal(Tla.UnboundedCap, cap);
                continue;
            }
            var graph = ReachabilityGraph.Build(net, limit: 5_000);
            Assert.True(graph.IsComplete);
            var reached = graph.PlaceBounds().Max(b => b ?? 0);
            Assert.True(reached <= cap, $"{net.Name}: a place reached {reached} tokens under a cap of {cap}.");
        }
    }

    [Fact]
    public void The_deadlock_check_stays_off()
    {
        // With it on, TLC stopped after three of retry's eight markings: a final marking is what a
        // workflow net is for, and TLA+ calls it an error.
        Assert.Contains("CHECK_DEADLOCK FALSE", Tla.Config(), StringComparison.Ordinal);
    }

    [Fact]
    public void Writing_a_net_leaves_a_module_and_its_configuration_side_by_side()
    {
        var dir = Path.Combine(Path.GetTempPath(), "tla-" + Guid.NewGuid().ToString("N"));
        try
        {
            var net = Nets.All.First(n => n.Name == "retry");
            var path = Tla.Write(net, dir);
            Assert.True(File.Exists(path));
            Assert.True(File.Exists(Path.ChangeExtension(path, ".cfg")));
            Assert.Equal(Tla.Module(net), File.ReadAllText(path));
        }
        finally
        {
            if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        }
    }

    private static int Count(string haystack, string needle)
    {
        var n = 0;
        for (var i = haystack.IndexOf(needle, StringComparison.Ordinal); i >= 0;
             i = haystack.IndexOf(needle, i + needle.Length, StringComparison.Ordinal))
            n++;
        return n;
    }
}
