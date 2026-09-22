using Examples;
using PetriNets;
using Xunit;

namespace Tests;

/// <summary>
/// Lesson 10. The interesting test is the last one: soundness is decided twice, once on the three
/// conditions and once through van der Aalst's short circuit, and the two must agree on every net
/// of the course. If they ever stop agreeing, one of the two is wrong and the lesson is lying.
/// </summary>
public class WorkflowTests
{
    [Fact]
    public void A_workflow_net_has_one_source_and_one_sink()
    {
        var net = Nets.OrderSound();
        var endpoints = Workflow.Endpoints(net, out var whyNot);

        Assert.Null(whyNot);
        Assert.NotNull(endpoints);
        Assert.Equal("in", net.Places[endpoints.Value.Source].Name);
        Assert.Equal("out", net.Places[endpoints.Value.Sink].Name);
    }

    [Fact]
    public void A_net_with_no_source_is_not_a_workflow_net()
    {
        // The producer and consumer runs for ever: every place has an incoming arc, so nothing
        // starts a case and nothing ends one. It is a perfectly good net and not a workflow.
        var endpoints = Workflow.Endpoints(Nets.ProducerConsumer(), out var whyNot);

        Assert.Null(endpoints);
        Assert.Contains("no place is a source", whyNot);
    }

    [Fact]
    public void An_and_split_joined_by_an_xor_finishes_with_a_branch_still_running()
    {
        var check = Workflow.Check(Nets.OrderAndXor());

        Assert.True(check.IsWorkflowNet);
        Assert.False(check.ProperCompletion);
        Assert.NotEmpty(check.Improper);
        Assert.Empty(check.DeadTransitions);   // every task can run; the error is in the joining
        Assert.False(check.IsSound);
    }

    [Fact]
    public void An_xor_split_joined_by_an_and_leaves_the_join_dead()
    {
        var check = Workflow.Check(Nets.OrderXorAnd());

        Assert.True(check.ProperCompletion);   // nothing is left behind, because nothing finishes
        Assert.False(check.OptionToComplete);
        Assert.Equal(["ship"], check.DeadTransitions);
        Assert.False(check.IsSound);
    }

    [Fact]
    public void A_rework_loop_is_sound_and_can_still_run_for_ever()
    {
        var net = Nets.OrderRework();
        Assert.True(Workflow.Check(net).IsSound);

        // Sound means the case can always finish, never that it must: there is a cycle that
        // never fires approve, exactly as a live transition can still starve in lesson 4.
        var cycle = ReachabilityGraph.Build(net).CycleAvoiding(net.TransitionIndex("approve"));
        Assert.NotNull(cycle);
    }

    [Theory]
    [InlineData("order-sound", true)]
    [InlineData("order-and-xor", false)]
    [InlineData("order-xor-and", false)]
    [InlineData("order-rework", true)]
    public void Soundness_agrees_with_the_short_circuit_being_live_and_bounded(string name, bool expected)
    {
        var net = name switch
        {
            "order-sound" => Nets.OrderSound(),
            "order-and-xor" => Nets.OrderAndXor(),
            "order-xor-and" => Nets.OrderXorAnd(),
            "order-rework" => Nets.OrderRework(),
            _ => throw new ArgumentOutOfRangeException(nameof(name)),
        };

        var direct = Workflow.Check(net).IsSound;
        var (live, bounded) = Workflow.ShortCircuitVerdict(net);

        Assert.Equal(expected, direct);
        Assert.Equal(direct, live && bounded);
    }
}
