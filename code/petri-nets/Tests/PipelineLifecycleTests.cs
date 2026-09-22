using Examples;
using PetriNets;
using Xunit;

namespace Tests;

public class PipelineLifecycleTests
{
    [Fact]
    public void Every_dead_marking_is_an_explicit_terminal_outcome()
    {
        var net = Nets.PipelineLifecycle();
        var graph = ReachabilityGraph.Build(net);
        var terminals = new[] { "succeeded", "failed", "cancelled" }
            .Select(net.PlaceIndex)
            .ToArray();

        Assert.True(graph.IsComplete);
        Assert.NotEmpty(graph.DeadStates);
        Assert.All(graph.DeadStates, state =>
            Assert.Equal(1, terminals.Sum(place => graph.States[state][place])));
        Assert.Equal(
            ["cancelled", "failed", "succeeded"],
            graph.DeadStates
                .SelectMany(state => terminals
                    .Where(place => graph.States[state][place] == 1)
                    .Select(place => net.Places[place].Name))
                .Distinct()
                .Order()
                .ToArray());
    }

    [Fact]
    public void Queue_capacity_is_conserved_across_every_reachable_marking()
    {
        var net = Nets.PipelineLifecycle();
        var graph = ReachabilityGraph.Build(net);
        var free = net.PlaceIndex("free");
        var queued = net.PlaceIndex("queued");

        Assert.All(graph.States, marking => Assert.Equal(1, marking[free] + marking[queued]));
    }

    [Theory]
    [InlineData("write", "read", "consume", "settle_success", "succeeded")]
    [InlineData("producer_fail", "settle_producer_failure", null, null, "failed")]
    [InlineData("cancel", null, null, null, "cancelled")]
    public void Each_lifecycle_branch_reaches_the_named_terminal(
        string first,
        string? second,
        string? third,
        string? fourth,
        string terminal)
    {
        var net = Nets.PipelineLifecycle();
        var transitions = new[] { first, second, third, fourth }.OfType<string>().ToArray();
        var last = net.FireSequence(net.InitialMarking, transitions)[^1];

        Assert.Equal(1, last[net.PlaceIndex(terminal)]);
        Assert.Empty(net.EnabledTransitions(last));
    }
}
