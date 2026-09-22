using Examples;
using PetriNets;
using Xunit;

namespace Tests;

/// <summary>
/// Lesson 12. The Kanban net is the only net of this course whose answer someone else computed:
/// the Model Checking Contest publishes 2 546 432 markings and 24 460 016 arcs for five cards, on
/// a model this class rebuilds from its published description. The five-card run takes about
/// fifteen seconds and a few gigabytes, so it is not a test; what is tested here is everything the
/// five-card run depends on, so that a change which would break it fails in a second instead.
/// </summary>
public class KanbanTests
{
    [Theory]
    [InlineData(1, 160, 616)]
    [InlineData(2, 4600, 28120)]
    [InlineData(3, 58400, 446400)]
    public void The_graph_has_the_size_it_had_when_five_cards_agreed_with_the_contest(int cards, int markings, int arcs)
    {
        var graph = ReachabilityGraph.Build(Nets.Kanban(cards), 1_000_000);

        Assert.True(graph.IsComplete);
        Assert.Equal(markings, graph.States.Count);
        Assert.Equal(arcs, graph.Steps.Count);
    }

    [Fact]
    public void The_shape_is_the_one_the_contest_distributes()
    {
        var net = Nets.Kanban(5);

        Assert.Equal(16, net.Places.Count);
        Assert.Equal(16, net.Transitions.Count);
        Assert.Equal(40, net.Arcs.Count);
        Assert.All(net.Arcs, a => Assert.Equal(1, a.Weight));
        // Four cells, each starting with all its cards free and nothing in progress.
        Assert.Equal(20, Enumerable.Range(0, net.Places.Count).Sum(p => net.InitialMarking[p]));
    }

    [Fact]
    public void Every_place_is_bounded_by_an_invariant_whatever_the_number_of_cards()
    {
        // The point of lesson 5, on an industrial net: this holds for every marking of a graph
        // with two and a half million of them, and costs one matrix.
        var bounds = Invariants.PlaceBounds(Nets.Kanban(7));

        Assert.All(bounds, b => Assert.Equal(7, b));
    }

    [Fact]
    public void A_factory_turns_out_to_be_a_free_choice_net()
    {
        // Which is what lets lesson 6's theorems say anything about it at all.
        var classes = Structure.Classify(Nets.Kanban(1));

        Assert.True(classes.IsFreeChoice);
        Assert.True(classes.IsStronglyConnected);
        Assert.False(classes.IsStateMachine);
        Assert.False(classes.IsMarkedGraph);
    }

    [Fact]
    public void One_card_is_live_reversible_and_safe()
    {
        var properties = Behaviour.Analyse(Nets.Kanban(1));

        Assert.True(properties.IsLive);
        Assert.True(properties.IsReversible);
        Assert.True(properties.IsSafe);
    }
}
