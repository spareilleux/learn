using System.Text.Json;
using Examples;
using PetriNets;
using Xunit;

namespace Tests;

public class JevEvidenceGateTests
{
    private sealed record Fixture(
        string kind,
        string case_id,
        string expected,
        string jev_choice,
        double jev_confidence,
        bool verified_evidence,
        bool implementation_authority);

    private static Fixture LoadFixture() =>
        JsonSerializer.Deserialize<Fixture>(File.ReadAllText(
            Path.Combine(AppContext.BaseDirectory, "jev-petri-fixture.json")))!;

    [Fact]
    public void Wrong_high_confidence_advisory_reaches_effect_in_unsafe_net()
    {
        var fixture = LoadFixture();
        Assert.Equal("synthetic-not-live", fixture.kind);
        Assert.Equal("gaia_design_authority", fixture.case_id);
        Assert.Equal("supported", fixture.jev_choice);
        Assert.NotEqual("supported", fixture.expected);
        Assert.True(fixture.jev_confidence >= 0.95);

        var net = JevEvidenceGate.Unsafe();
        var graph = ReachabilityGraph.Build(net);
        Assert.True(graph.IsComplete);
        var effectState = Enumerable.Range(0, graph.States.Count)
            .Single(state => graph.States[state][net.PlaceIndex("effect")] == 1);
        var witness = graph.PathTo(effectState)!
            .Select(transition => net.Transitions[transition].Id)
            .ToArray();
        Assert.Equal(["classify", "authorize_from_advisory"], witness);
    }

    [Fact]
    public void Advisory_cannot_grant_effect_without_independent_proof_and_authority()
    {
        var fixture = LoadFixture();
        Assert.False(fixture.verified_evidence);
        Assert.False(fixture.implementation_authority);

        foreach (var (verified, authority) in new[] { (false, false), (true, false), (false, true) })
        {
            var net = JevEvidenceGate.Guarded(verified, authority);
            var graph = ReachabilityGraph.Build(net);
            Assert.True(graph.IsComplete);
            Assert.All(graph.States, marking =>
                Assert.Equal(0, marking[net.PlaceIndex("effect")]));
        }
    }

    [Fact]
    public void Both_independent_facts_enable_a_separate_authorized_path()
    {
        var net = JevEvidenceGate.Guarded(true, true);
        var last = net.FireSequence(net.InitialMarking,
            "classify", "route_review", "confirm", "authorize")[^1];
        Assert.Equal(1, last[net.PlaceIndex("effect")]);
    }
}
