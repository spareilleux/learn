using PetriNets;

namespace Examples;

/// <summary>
/// The two smallest nets that show what an inhibitor arc buys and what it costs (lesson 15).
///
/// Every other net in this course is an ordinary place/transition net, on purpose: the analyser's
/// verdicts are decidable there. These two are not part of <see cref="Nets.All"/> and nothing else
/// reads them — they exist to be run once, in lesson 15, against the tools that stop working.
/// </summary>
public static class InhibitorNets
{
    /// <summary>
    /// One place, one transition, one inhibitor arc: `grow` produces a token in `p` and is blocked
    /// by a token in `p`. As an ordinary net `p` is unbounded and Karp–Miller answers ω. With the
    /// inhibitor arc `p` never holds more than one.
    /// </summary>
    public static InhibitorNet SelfInhibited()
    {
        var net = new PetriNet(
            "self-inhibited",
            [new Place("p", "p")],
            [new Transition("grow", "grow")],
            [new Arc("grow", "p")],
            new Marking(0));
        return new InhibitorNet(net, [new InhibitorArc("p", "grow")]);
    }

    /// <summary>
    /// The test an ordinary net cannot make. `move` carries one token at a time from `a` to `b`;
    /// `finish` is blocked while `a` holds anything, so it fires exactly once, after the last token
    /// has moved. Drop the inhibitor arc and `finish` may fire at any point, which is the whole
    /// difference between "when the queue is empty" and "at some time".
    /// </summary>
    public static InhibitorNet Flush(int tokens)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(tokens);
        var net = new PetriNet(
            $"flush-{tokens}",
            [new Place("a", "a"), new Place("b", "b"), new Place("ready", "ready"), new Place("done", "done")],
            [new Transition("move", "move"), new Transition("finish", "finish")],
            [new Arc("a", "move"), new Arc("move", "b"), new Arc("ready", "finish"), new Arc("finish", "done")],
            new Marking(tokens, 0, 1, 0));
        return new InhibitorNet(net, [new InhibitorArc("a", "finish")]);
    }
}
