using Examples;
using PetriNets;
using Xunit;

namespace Tests;

public class FiringRuleTests
{
    [Fact]
    public void A_transition_is_enabled_when_every_input_place_holds_the_arc_weight()
    {
        var net = Nets.ProducerConsumer();
        Assert.Equal(["produce"], Enabled(net, net.InitialMarking));

        var produced = net.Fire(net.InitialMarking, net.TransitionIndex("produce"));
        Assert.Equal(["deposit"], Enabled(net, produced));
    }

    [Fact]
    public void Firing_takes_and_gives_at_the_same_time()
    {
        var net = Nets.ProducerConsumer();
        var after = net.FireSequence(net.InitialMarking, "produce", "deposit")[^1];
        Assert.Equal(1, after[net.PlaceIndex("ready")]);
        Assert.Equal(1, after[net.PlaceIndex("full")]);
        Assert.Equal(1, after[net.PlaceIndex("free")]);
    }

    [Fact]
    public void A_disabled_transition_cannot_fire()
    {
        var net = Nets.ProducerConsumer();
        Assert.Throws<InvalidOperationException>(() => net.Fire(net.InitialMarking, net.TransitionIndex("take")));
    }

    [Fact]
    public void The_place_free_is_what_bounds_the_buffer()
    {
        var net = Nets.ProducerConsumer();
        var full = net.FireSequence(net.InitialMarking, "produce", "deposit", "produce", "deposit", "produce")[^1];
        Assert.Equal(0, full[net.PlaceIndex("free")]);
        Assert.False(net.IsEnabled(full, net.TransitionIndex("deposit")));
    }

    [Fact]
    public void Concurrent_firings_commute()
    {
        var net = Nets.ProducerConsumer();
        var start = net.FireSequence(net.InitialMarking, "produce", "deposit")[^1];
        Assert.Equal(
            net.FireSequence(start, "produce", "take")[^1],
            net.FireSequence(start, "take", "produce")[^1]);
    }

    private static string[] Enabled(PetriNet net, Marking marking) =>
        [.. net.EnabledTransitions(marking).Select(t => net.Transitions[t].Name)];
}

public class ReachabilityTests
{
    [Fact]
    public void The_bounded_producer_and_consumer_has_twelve_markings()
    {
        var graph = ReachabilityGraph.Build(Nets.ProducerConsumer());
        Assert.True(graph.IsComplete);
        Assert.Equal(12, graph.States.Count);
        Assert.Empty(graph.DeadStates);
    }

    [Fact]
    public void The_graph_is_built_in_the_same_order_every_time()
    {
        var first = ReachabilityGraph.Build(Nets.ProducerConsumer());
        var second = ReachabilityGraph.Build(Nets.ProducerConsumer());
        Assert.Equal(first.States, second.States);
        Assert.Equal(first.Steps, second.Steps);
    }

    [Fact]
    public void The_unbounded_net_never_finishes_and_says_so()
    {
        var graph = ReachabilityGraph.Build(Nets.UnboundedProducer(), limit: 40);
        Assert.False(graph.IsComplete);
        Assert.Equal(40, graph.States.Count);
    }

    [Fact]
    public void The_coverability_tree_marks_the_growing_place_with_omega()
    {
        var net = Nets.UnboundedProducer();
        var tree = CoverabilityTree.Build(net);
        Assert.False(tree.IsBounded);
        var bounds = tree.PlaceBounds();
        Assert.Null(bounds[net.PlaceIndex("full")]);
        Assert.Equal(1, bounds[net.PlaceIndex("ready")]);
    }

    [Fact]
    public void A_self_loop_that_also_produces_makes_two_places_unbounded()
    {
        var net = Nets.EmitLoop();
        var tree = CoverabilityTree.Build(net);
        Assert.False(tree.IsBounded);
        var bounds = tree.PlaceBounds();
        Assert.Equal(1, bounds[net.PlaceIndex("ready")]);
        Assert.Null(bounds[net.PlaceIndex("log")]);
        Assert.Null(bounds[net.PlaceIndex("queue")]);
        // The self-loop leaves no trace in the incidence matrix, though the firing rule still needs the token.
        Assert.Equal(0, net.Incidence()[net.PlaceIndex("ready"), 0]);
        Assert.Equal(1, net.Pre[net.PlaceIndex("ready"), 0]);
    }

    [Fact]
    public void The_unbounded_tree_holds_six_distinct_markings()
    {
        var tree = CoverabilityTree.Build(Nets.UnboundedProducer());
        Assert.Equal(17, tree.Nodes.Count);
        Assert.Equal(6, tree.Nodes.Select(n => n.Marking).Distinct().Count());
    }

    [Fact]
    public void The_farthest_marking_of_the_producer_and_consumer_is_eight_firings_away()
    {
        var net = Nets.ProducerConsumer();
        var graph = ReachabilityGraph.Build(net);
        var path = graph.PathTo(11);
        Assert.NotNull(path);
        Assert.Equal(
            ["produce", "deposit", "produce", "deposit", "produce", "take", "deposit", "produce"],
            path.Select(t => net.Transitions[t].Name));
    }

    [Fact]
    public void A_bounded_net_gets_a_tree_without_omega()
    {
        var tree = CoverabilityTree.Build(Nets.ProducerConsumer());
        Assert.True(tree.IsBounded);
        Assert.Empty(tree.DeadTransitions());
    }

    [Fact]
    public void The_shortest_path_to_the_deadlock_takes_two_firings()
    {
        var net = Nets.TwoLocks();
        var graph = ReachabilityGraph.Build(net);
        var dead = Assert.Single(graph.DeadStates);
        var path = graph.PathTo(dead);
        Assert.NotNull(path);
        Assert.Equal(2, path.Count);
    }
}

public class PropertyTests
{
    [Fact]
    public void The_producer_and_consumer_is_bounded_live_and_reversible()
    {
        var net = Nets.ProducerConsumer();
        var properties = Behaviour.Analyse(net);
        Assert.True(properties.IsBounded);
        Assert.Equal(2, properties.Bound);
        Assert.False(properties.IsSafe);
        Assert.True(properties.IsLive);
        Assert.True(properties.IsReversible);
        Assert.True(properties.IsDeadlockFree);
    }

    [Fact]
    public void Mutual_exclusion_is_safe_live_reversible_and_not_persistent()
    {
        var properties = Behaviour.Analyse(Nets.MutualExclusion());
        Assert.True(properties.IsSafe);
        Assert.True(properties.IsLive);
        Assert.True(properties.IsReversible);
        Assert.False(properties.IsPersistent);
    }

    [Fact]
    public void Two_locks_taken_in_opposite_orders_deadlock()
    {
        var properties = Behaviour.Analyse(Nets.TwoLocks());
        Assert.False(properties.IsDeadlockFree);
        var dead = Assert.Single(properties.DeadMarkings);
        var net = Nets.TwoLocks();
        Assert.Equal(0, dead[net.PlaceIndex("x")]);
        Assert.Equal(0, dead[net.PlaceIndex("y")]);
    }

    [Fact]
    public void Taking_both_locks_in_the_same_order_removes_the_deadlock()
    {
        var properties = Behaviour.Analyse(Nets.TwoLocksOrdered());
        Assert.True(properties.IsDeadlockFree);
        Assert.True(properties.IsLive);
        Assert.True(properties.IsReversible);
    }

    [Fact]
    public void A_buffer_of_one_slot_makes_the_net_safe()
    {
        var properties = Behaviour.Analyse(Nets.ProducerConsumer(1));
        Assert.True(properties.IsSafe);
        Assert.True(properties.IsLive);
    }

    [Fact]
    public void Deadlock_free_does_not_mean_live()
    {
        var net = Nets.StartOnce();
        var properties = Behaviour.Analyse(net);
        Assert.True(properties.IsDeadlockFree);
        Assert.False(properties.IsLive);
        Assert.Equal(Liveness.L1, properties.TransitionLiveness[net.TransitionIndex("start")]);
        Assert.Equal(Liveness.Live, properties.TransitionLiveness[net.TransitionIndex("accept")]);
        Assert.False(properties.IsReversible);
        Assert.NotEmpty(properties.HomeStates);
    }

    [Fact]
    public void A_net_that_can_do_nothing_has_a_dead_marking_and_dead_transitions()
    {
        var net = Nets.Handshake();
        var properties = Behaviour.Analyse(net);
        Assert.False(properties.IsDeadlockFree);
        Assert.All(properties.TransitionLiveness, level => Assert.Equal(Liveness.Dead, level));
    }
}

public class InvariantTests
{
    [Fact]
    public void The_producer_and_consumer_conserves_three_quantities()
    {
        var net = Nets.ProducerConsumer();
        var invariants = Invariants.Places(net);
        Assert.Equal(3, invariants.Count);
        foreach (var invariant in invariants)
        {
            var atStart = Invariants.WeightedTokens(invariant, net.InitialMarking);
            foreach (var marking in ReachabilityGraph.Build(net).States)
                Assert.Equal(atStart, Invariants.WeightedTokens(invariant, marking));
        }
    }

    [Fact]
    public void Mutual_exclusion_is_proved_by_a_place_invariant()
    {
        var net = Nets.MutualExclusion();
        var invariants = Invariants.Places(net);
        var mutex = invariants.Single(i => i.Support.Contains(net.PlaceIndex("mutex")));
        Assert.Equal(
            [net.PlaceIndex("critical1"), net.PlaceIndex("critical2"), net.PlaceIndex("mutex")],
            mutex.Support.Order());
        Assert.Equal(1, Invariants.WeightedTokens(mutex, net.InitialMarking));
    }

    [Fact]
    public void The_round_trip_is_a_transition_invariant()
    {
        var net = Nets.ProducerConsumer();
        var invariant = Assert.Single(Invariants.Transitions(net));
        Assert.Equal([1, 1, 1, 1], invariant.Weights);
        var after = net.FireSequence(net.InitialMarking, "produce", "deposit", "take", "consume")[^1];
        Assert.Equal(net.InitialMarking, after);
    }
}

public class StateEquationTests
{
    [Fact]
    public void A_real_sequence_satisfies_the_equation()
    {
        var net = Nets.ProducerConsumer();
        string[] sequence = ["produce", "deposit", "produce", "take"];
        var counts = new int[net.Transitions.Count];
        foreach (var name in sequence) counts[net.TransitionIndex(name)]++;
        Assert.Equal(
            net.FireSequence(net.InitialMarking, sequence)[^1].ToArray(),
            StateEquation.Apply(net, net.InitialMarking, counts));
    }

    [Fact]
    public void The_producer_and_consumer_has_no_spurious_marking()
    {
        // Its three place invariants leave exactly 2 * 2 * 3 = 12 markings, and all twelve are reachable,
        // so nothing can satisfy the equation without being reachable. The net always holds four tokens.
        Assert.Empty(StateEquation.SpuriousMarkings(Nets.ProducerConsumer(), maxTokens: 4));
    }

    [Fact]
    public void The_equation_accepts_a_marking_the_handshake_cannot_reach()
    {
        var net = Nets.Handshake();
        var target = new Marking(0, 0, 1);
        Assert.NotNull(StateEquation.Solve(net, target));
        Assert.DoesNotContain(target, ReachabilityGraph.Build(net).States);
        Assert.Contains(target, StateEquation.SpuriousMarkings(net, 2));
    }
}

public class PnmlTests
{
    [Fact]
    public void Every_net_survives_a_round_trip_through_pnml()
    {
        foreach (var net in Nets.All)
        {
            var parsed = Pnml.Parse(Pnml.Write(net));
            Assert.Equal(net.Name, parsed.Name);
            Assert.Equal(net.Places.Select(p => p.Id), parsed.Places.Select(p => p.Id));
            Assert.Equal(net.Transitions.Select(t => t.Id), parsed.Transitions.Select(t => t.Id));
            Assert.Equal(net.InitialMarking, parsed.InitialMarking);
            Assert.Equal(Report.Matrices(net), Report.Matrices(parsed));
        }
    }

    [Fact]
    public void An_arc_weight_survives_the_round_trip()
    {
        var net = new PetriNet("weighted",
            [new Place("p", "p"), new Place("q", "q")],
            [new Transition("t", "t")],
            [new Arc("p", "t", 3), new Arc("t", "q", 2)],
            new Marking(3, 0));
        var parsed = Pnml.Parse(Pnml.Write(net));
        Assert.Equal(3, parsed.Pre[parsed.PlaceIndex("p"), 0]);
        Assert.Equal(2, parsed.Post[parsed.PlaceIndex("q"), 0]);
    }

    [Fact]
    public void A_net_of_another_type_is_refused()
    {
        var xml = Pnml.Write(Nets.Handshake()).Replace(Pnml.PtNetType, "http://www.pnml.org/version-2009/grammar/symmetricnet");
        Assert.Throws<NotSupportedException>(() => Pnml.Parse(xml));
    }
}
