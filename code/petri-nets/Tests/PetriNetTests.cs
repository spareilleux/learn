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
    public void The_invariants_give_the_same_bounds_as_the_reachability_graph()
    {
        var net = Nets.ProducerConsumer();
        var fromInvariants = Invariants.PlaceBounds(net);
        var fromGraph = ReachabilityGraph.Build(net).PlaceBounds();
        Assert.Equal(fromGraph, fromInvariants);
    }

    [Fact]
    public void No_invariant_covers_the_place_that_grows()
    {
        var net = Nets.UnboundedProducer();
        var bounds = Invariants.PlaceBounds(net);
        Assert.Null(bounds[net.PlaceIndex("full")]);
        Assert.Equal(1, bounds[net.PlaceIndex("ready")]);
    }

    [Fact]
    public void The_rank_of_the_incidence_matrix_says_how_many_invariants_to_expect()
    {
        var net = Nets.ProducerConsumer();
        Assert.Equal(3, Invariants.Rank(net));
        Assert.Equal(net.Places.Count - Invariants.Rank(net), Invariants.Places(net).Count);
    }

    [Fact]
    public void A_spurious_marking_satisfies_every_place_invariant()
    {
        // Place invariants follow from M = M0 + C x, so they can never rule out a marking the
        // state equation accepts. They are weaker than the equation, which is weaker than reachability.
        var net = Nets.Handshake();
        foreach (var spurious in StateEquation.SpuriousMarkings(net, 2))
        {
            foreach (var invariant in Invariants.Places(net))
                Assert.Equal(
                    Invariants.WeightedTokens(invariant, net.InitialMarking),
                    Invariants.WeightedTokens(invariant, spurious));
        }
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

public class StructureTests
{
    [Fact]
    public void The_producer_and_consumer_is_a_marked_graph_and_the_mutual_exclusion_is_not()
    {
        Assert.True(Structure.Classify(Nets.ProducerConsumer()).IsMarkedGraph);
        Assert.False(Structure.Classify(Nets.MutualExclusion()).IsMarkedGraph);
    }

    [Fact]
    public void A_state_machine_has_one_input_and_one_output_place_per_transition()
    {
        var classes = Structure.Classify(Nets.Connection());
        Assert.True(classes.IsStateMachine);
        Assert.True(classes.IsStronglyConnected);
        Assert.True(classes.IsFreeChoice);
        Assert.False(Structure.Classify(Nets.StartOnce()).IsStronglyConnected);
    }

    [Fact]
    public void Sharing_a_place_between_two_transitions_breaks_free_choice()
    {
        // enter1 reads idle1 and mutex, enter2 reads idle2 and mutex: they share one input place and not
        // the other. The lock still leaves the net in the asymmetric-choice class; the philosophers,
        // where three forks are shared in a ring, fall out of that one too.
        var classes = Structure.Classify(Nets.MutualExclusion());
        Assert.False(classes.IsFreeChoice);
        Assert.False(classes.IsExtendedFreeChoice);
        Assert.True(classes.IsAsymmetricChoice);
        Assert.False(Structure.Classify(Nets.Philosophers(3)).IsAsymmetricChoice);
    }

    [Fact]
    public void The_circuits_of_a_marked_graph_are_its_place_invariants()
    {
        var net = Nets.ProducerConsumer();
        var circuits = Structure.Circuits(net);
        Assert.Equal(3, circuits.Count);
        var supports = Invariants.Places(net).Select(i => i.Support.ToHashSet()).ToList();
        foreach (var circuit in circuits)
            Assert.Contains(supports, support => support.SetEquals(circuit.Places));
    }

    [Fact]
    public void A_trap_that_holds_a_token_never_loses_it()
    {
        var net = Nets.ProducerConsumer();
        foreach (var trap in Structure.MinimalTraps(net))
        {
            Assert.True(Structure.IsTrap(net, trap));
            foreach (var marking in ReachabilityGraph.Build(net).States)
                Assert.True(trap.Sum(p => marking[p]) > 0);
        }
    }

    [Fact]
    public void The_places_left_empty_by_a_dead_marking_form_a_siphon()
    {
        var net = Nets.TwoLocks();
        var graph = ReachabilityGraph.Build(net);
        foreach (var state in graph.DeadStates)
            Assert.True(Structure.IsSiphon(net, Structure.EmptyPlaces(graph.States[state])));
    }

    [Fact]
    public void Commoner_agrees_with_the_reachability_graph_on_every_free_choice_net()
    {
        foreach (var net in new[] { Nets.ProducerConsumer(), Nets.StartOnce(), Nets.Handshake(), Nets.Connection() })
        {
            Assert.True(Structure.Classify(net).IsFreeChoice, net.Name);
            Assert.Equal(Behaviour.Analyse(net).IsLive, Structure.EverySiphonHasAMarkedTrap(net));
        }
    }

    [Fact]
    public void A_marked_graph_is_live_when_every_circuit_carries_a_token()
    {
        var net = Nets.ProducerConsumer();
        var circuits = Structure.Circuits(net);
        Assert.All(circuits, c => Assert.True(c.Tokens(net.InitialMarking) >= 1));
        Assert.True(Behaviour.Analyse(net).IsLive);

        // Empty the circuit through free and full, and the same theorem says the net is dead.
        var starved = Nets.ProducerConsumer(0);
        Assert.Contains(Structure.Circuits(starved), c => c.Tokens(starved.InitialMarking) == 0);
        Assert.False(Behaviour.Analyse(starved).IsLive);
    }
}

public class ConcurrencyTests
{
    [Fact]
    public void The_readers_and_writers_never_lets_a_writer_in_beside_a_reader()
    {
        var net = Nets.ReadersWriters();
        var reading = net.PlaceIndex("reading");
        var writing = net.PlaceIndex("writing");
        foreach (var marking in ReachabilityGraph.Build(net).States)
        {
            Assert.True(marking[writing] <= 1);
            Assert.True(marking[writing] == 0 || marking[reading] == 0);
        }
    }

    [Fact]
    public void A_live_transition_can_still_be_starved()
    {
        var net = Nets.ReadersWriters();
        var graph = ReachabilityGraph.Build(net);
        var writer = net.TransitionIndex("start_write");
        Assert.Equal(Liveness.Live, Behaviour.Analyse(graph).TransitionLiveness[writer]);
        Assert.NotNull(graph.CycleAvoiding(writer));
    }

    [Fact]
    public void A_semaphore_lets_in_exactly_as_many_threads_as_it_has_permits()
    {
        foreach (var permits in new[] { 1, 2, 3 })
        {
            var net = Nets.CountingSemaphore(3, permits);
            var inside = Enumerable.Range(0, net.Places.Count).Where(p => net.Places[p].Name.StartsWith("inside")).ToList();
            var most = ReachabilityGraph.Build(net).States.Max(m => inside.Sum(p => m[p]));
            Assert.Equal(permits, most);
        }
    }

    [Fact]
    public void Taking_one_fork_at_a_time_deadlocks_and_reversing_one_philosopher_does_not()
    {
        for (var count = 2; count <= 5; count++)
        {
            Assert.NotEmpty(ReachabilityGraph.Build(Nets.PhilosophersOneFork(count)).DeadStates);
            Assert.Empty(ReachabilityGraph.Build(Nets.PhilosophersOneFork(count, ordered: true)).DeadStates);
        }
    }

    [Fact]
    public void Taking_both_forks_at_once_never_deadlocks()
    {
        for (var count = 2; count <= 6; count++)
            Assert.Empty(ReachabilityGraph.Build(Nets.Philosophers(count)).DeadStates);
    }
}

public class ColouredTests
{
    [Fact]
    public void The_unfolding_has_one_place_per_colour_and_one_transition_per_binding()
    {
        var net = ColouredNets.Retry();
        var unfolded = net.Unfold();
        // pending and failed carry three colours each, done and dead one; succeed and fail take
        // every colour, retry takes two of them and giveup one.
        Assert.Equal(8, unfolded.Places.Count);
        Assert.Equal(9, unfolded.Transitions.Count);
    }

    [Fact]
    public void A_guard_removes_the_bindings_it_rejects()
    {
        var net = ColouredNets.Retry();
        Assert.Equal(["0", "1"], net.Bindings(net.TransitionIndex("retry")));
        Assert.Equal(["2"], net.Bindings(net.TransitionIndex("giveup")));
        Assert.Equal(["0", "1", "2"], net.Bindings(net.TransitionIndex("fail")));
    }

    [Fact]
    public void Firing_a_coloured_transition_agrees_with_firing_its_unfolded_twin()
    {
        var net = ColouredNets.Retry();
        var unfolded = net.Unfold();
        var coloured = net.Fire(net.InitialMarking, net.TransitionIndex("fail"), "0");
        var plain = unfolded.Fire(unfolded.InitialMarking, unfolded.TransitionIndex("fail_0"));
        Assert.Equal("failed: 0", coloured.ToString(net));
        Assert.Equal("failed_0:1", plain.ToString(unfolded));
    }

    [Fact]
    public void A_retry_that_runs_out_of_attempts_ends_in_the_dead_letter_place()
    {
        var net = ColouredNets.Retry();
        var last = net.FireSequence(net.InitialMarking,
            ("fail", "0"), ("retry", "0"), ("fail", "1"), ("retry", "1"), ("fail", "2"), ("giveup", "2"))[^1];
        Assert.Equal("dead", last.ToString(net));
        Assert.Throws<InvalidOperationException>(() => net.Fire(last, net.TransitionIndex("retry"), "2"));
    }

    [Fact]
    public void Colour_folds_the_model_and_leaves_the_state_space_alone()
    {
        // Four places and four transitions whatever the number of attempts; the unfolding and the
        // number of reachable markings both grow with it.
        foreach (var attempts in new[] { 2, 5, 10 })
        {
            var net = ColouredNets.Retry(attempts);
            Assert.Equal(4, net.Places.Count);
            Assert.Equal(4, net.Transitions.Count);
            var unfolded = net.Unfold();
            Assert.Equal(2 * (attempts + 1) + 2, unfolded.Places.Count);
            Assert.Equal(3 * attempts + 3, unfolded.Transitions.Count);
            Assert.Equal(2 * attempts + 4, ReachabilityGraph.Build(unfolded).States.Count);
        }
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

    /// <summary>
    /// Lesson 11. The shape of the P/T net sample of ISO/IEC 15909-2 as ePNK writes it: the name is
    /// on the page and not on the net, the transition has no name at all, and the marking carries a
    /// toolspecific block before its text. Reading only the net element threw the name away.
    /// </summary>
    [Fact]
    public void A_name_on_the_page_is_read_when_the_net_has_none()
    {
        const string xml = """
            <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
              <net type="http://www.pnml.org/version-2009/grammar/ptnet" id="n1">
                <page id="top-level">
                  <name><text>An example P/T-net</text></name>
                  <place id="p1">
                    <name><graphics><offset y="-10.0"/></graphics><text>ready</text></name>
                    <initialMarking>
                      <toolspecific tool="org.pnml.tool" version="1.0"><tokengraphics/></toolspecific>
                      <text>3</text>
                    </initialMarking>
                  </place>
                  <transition id="t1"><graphics><position x="60.0" y="20.0"/></graphics></transition>
                  <arc id="a1" source="p1" target="t1">
                    <inscription><graphics><offset y="5.0"/></graphics><text>2</text></inscription>
                  </arc>
                </page>
              </net>
            </pnml>
            """;

        var net = Pnml.Parse(xml);

        Assert.Equal("An example P/T-net", net.Name);
        Assert.Equal("ready", net.Places[0].Name);
        Assert.Equal("t1", net.Transitions[0].Name);   // no name element: the id stands in
        Assert.Equal(3, net.InitialMarking[0]);        // the toolspecific block is not the marking
        Assert.Equal(2, net.Pre[0, 0]);                // nor is the inscription's graphics the weight
    }
}
