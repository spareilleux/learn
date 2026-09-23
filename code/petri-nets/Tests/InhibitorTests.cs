using Examples;
using PetriNets;
using Xunit;

namespace Tests;

/// <summary>
/// Lesson 15. An inhibitor arc is the one extension this course adds and immediately puts away
/// again: it buys the test for zero and costs every decidability result the analyser relies on.
/// The first test below is the measurement the lesson is built on — Karp and Miller's tree gives
/// the wrong answer, not a slow one — and it is a test rather than a paragraph so that nobody
/// later runs <see cref="CoverabilityTree"/> on one of these and believes it.
/// </summary>
public class InhibitorTests
{
    [Fact]
    public void The_coverability_tree_of_the_ordinary_net_contradicts_the_inhibitor_net()
    {
        var net = InhibitorNets.SelfInhibited();

        // Ignore the inhibitor arc and `grow` is a source transition: the tree accelerates to omega.
        var tree = CoverabilityTree.Build(net.Net);
        Assert.False(tree.IsBounded);
        Assert.Null(tree.PlaceBounds()[0]);

        // Honour it and the place never holds two tokens.
        var (states, _, complete) = net.Reachable();
        Assert.True(complete);
        Assert.Equal(2, states.Count);
        Assert.Equal(1, net.PlaceBounds()[0]);
    }

    [Theory]
    [InlineData(1)]
    [InlineData(2)]
    [InlineData(4)]
    [InlineData(8)]
    public void The_zero_test_costs_the_markings_where_finish_fired_early(int tokens)
    {
        var net = InhibitorNets.Flush(tokens);
        var (states, _, complete) = net.Reachable();
        Assert.True(complete);
        Assert.Equal(tokens + 2, states.Count);
        Assert.Equal(2 * (tokens + 1), ReachabilityGraph.Build(net.Net).States.Count);
    }

    [Fact]
    public void Finish_waits_for_the_last_move()
    {
        var net = InhibitorNets.Flush(2);
        var finish = net.Net.TransitionIndex("finish");
        var move = net.Net.TransitionIndex("move");

        var marking = net.Net.InitialMarking;
        Assert.False(net.IsEnabled(marking, finish));
        marking = net.Net.Fire(marking, move);
        Assert.False(net.IsEnabled(marking, finish));
        marking = net.Net.Fire(marking, move);
        Assert.True(net.IsEnabled(marking, finish));

        // The ordinary net has no such patience.
        Assert.True(net.Net.IsEnabled(net.Net.InitialMarking, finish));
    }

    [Fact]
    public void An_incomplete_search_says_so_and_never_says_unbounded()
    {
        // `tick` is a source transition with nothing inhibiting it, so the set really is infinite.
        var growing = new InhibitorNet(
            new PetriNet("tick", [new Place("n", "n")], [new Transition("tick", "tick")],
                         [new Arc("tick", "n")], new Marking(0)),
            []);
        var (states, _, complete) = growing.Reachable(limit: 10);
        Assert.False(complete);
        Assert.Equal(10, states.Count);
    }
}
