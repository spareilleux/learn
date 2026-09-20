using PetriNets;

namespace Examples;

/// <summary>
/// The coloured nets of lesson 8. A coloured token carries a value, the way a message carries a
/// payload; the same model without colour needs one place per value, which is exactly what
/// <see cref="ColouredNet.Unfold"/> produces.
/// </summary>
public static class ColouredNets
{
    /// <summary>
    /// A delivery that is retried up to <paramref name="maxAttempts"/> times before it goes to the
    /// dead-letter place. The token is the message and its colour is the attempt it is on, so the
    /// whole retry policy is four places and four transitions whatever the number of attempts.
    /// </summary>
    public static ColouredNet Retry(int maxAttempts = 2)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(maxAttempts);
        var attempt = new ColourSet("Attempt", [.. Enumerable.Range(0, maxAttempts + 1).Select(n => n.ToString())]);
        var last = maxAttempts.ToString();

        return new ColouredNet(
            maxAttempts == 2 ? "retry" : $"retry-{maxAttempts}",
            [
                new ColouredPlace("pending", "pending", attempt),
                new ColouredPlace("failed", "failed", attempt),
                new ColouredPlace("done", "done", ColourSet.Unit),
                new ColouredPlace("dead", "dead", ColourSet.Unit),
            ],
            [
                new ColouredTransition("succeed", "succeed", "n", attempt, Guard.None),
                new ColouredTransition("fail", "fail", "n", attempt, Guard.None),
                new ColouredTransition("retry", "retry", "n", attempt, new Guard($"n < {last}", n => n != last)),
                new ColouredTransition("giveup", "giveup", "n", attempt, new Guard($"n = {last}", n => n == last)),
            ],
            [
                new ColouredArc("pending", "succeed", ArcExpression.Variable("n")),
                new ColouredArc("succeed", "done", ArcExpression.Constant("()")),
                new ColouredArc("pending", "fail", ArcExpression.Variable("n")),
                new ColouredArc("fail", "failed", ArcExpression.Variable("n")),
                new ColouredArc("failed", "retry", ArcExpression.Variable("n")),
                new ColouredArc("retry", "pending", ArcExpression.Successor(attempt, "n")),
                new ColouredArc("failed", "giveup", ArcExpression.Variable("n")),
                new ColouredArc("giveup", "dead", ArcExpression.Constant("()")),
            ],
            [("pending", "0", 1)]);
    }
}
