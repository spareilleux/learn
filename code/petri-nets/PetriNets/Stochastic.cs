using System.Globalization;

namespace PetriNets;

/// <summary>
/// The timing of a net: an exponential firing rate for each timed transition, and a weight for
/// each immediate one. A transition named in <see cref="Weights"/> fires in zero time; every
/// other transition must have a rate. This is the data a generalised stochastic Petri net
/// (GSPN) adds to an ordinary net — the structure is unchanged, so every result of lessons 3
/// to 6 still holds.
/// </summary>
public sealed class Timing
{
    private readonly Dictionary<string, double> _rates;
    private readonly Dictionary<string, double> _weights;

    public Timing(IReadOnlyDictionary<string, double>? rates = null, IReadOnlyDictionary<string, double>? weights = null)
    {
        _rates = rates is null ? [] : new Dictionary<string, double>(rates);
        _weights = weights is null ? [] : new Dictionary<string, double>(weights);

        foreach (var (name, rate) in _rates)
            if (rate <= 0 || double.IsNaN(rate) || double.IsInfinity(rate))
                throw new ArgumentException($"The rate of {name} is {rate}; a rate is finite and positive.", nameof(rates));
        foreach (var (name, weight) in _weights)
            if (weight <= 0 || double.IsNaN(weight) || double.IsInfinity(weight))
                throw new ArgumentException($"The weight of {name} is {weight}; a weight is finite and positive.", nameof(weights));
        foreach (var name in _rates.Keys)
            if (_weights.ContainsKey(name))
                throw new ArgumentException($"{name} has both a rate and a weight; a transition is timed or immediate, not both.", nameof(weights));
    }

    /// <summary>Rate of the exponential delay of a timed transition, by transition name.</summary>
    public IReadOnlyDictionary<string, double> Rates => _rates;

    /// <summary>Weight of an immediate transition, by transition name. Immediate transitions fire in zero time.</summary>
    public IReadOnlyDictionary<string, double> Weights => _weights;

    public bool IsImmediate(string transition) => _weights.ContainsKey(transition);

    public double Rate(string transition) =>
        _rates.TryGetValue(transition, out var r)
            ? r
            : throw new KeyNotFoundException($"{transition} has no rate and no weight; every transition needs one.");

    public double Weight(string transition) =>
        _weights.TryGetValue(transition, out var w)
            ? w
            : throw new KeyNotFoundException($"{transition} is not immediate.");
}

/// <summary>
/// The stationary distribution of a stochastic net, state by state, plus what it is worth
/// asking: how many tokens sit in a place on average, and how often a transition fires.
/// </summary>
public sealed record SteadyState(
    ReachabilityGraph Graph,
    Timing Timing,
    IReadOnlyList<int> Tangible,
    IReadOnlyList<double> Probability)
{
    /// <summary>Mean number of tokens in a place, the sum over tangible states of probability times tokens.</summary>
    public double MeanTokens(string place)
    {
        var p = Graph.Net.PlaceIndex(place);
        var total = 0.0;
        for (var i = 0; i < Tangible.Count; i++)
            total += Probability[i] * Graph.States[Tangible[i]][p];
        return total;
    }

    /// <summary>
    /// Mean firings per unit of time of a timed transition: the probability of being in a state
    /// where it is enabled, weighted by its rate. This is the throughput a load test measures.
    /// </summary>
    public double Throughput(string transition)
    {
        var t = Graph.Net.TransitionIndex(transition);
        var rate = Timing.Rate(transition);
        var total = 0.0;
        for (var i = 0; i < Tangible.Count; i++)
            if (Graph.Net.IsEnabled(Graph.States[Tangible[i]], t))
                total += Probability[i] * rate;
        return total;
    }

    /// <summary>Probability that a place holds exactly <paramref name="tokens"/> tokens.</summary>
    public double ProbabilityOf(string place, int tokens)
    {
        var p = Graph.Net.PlaceIndex(place);
        var total = 0.0;
        for (var i = 0; i < Tangible.Count; i++)
            if (Graph.States[Tangible[i]][p] == tokens)
                total += Probability[i];
        return total;
    }
}

/// <summary>
/// Turns a reachability graph and a <see cref="Timing"/> into a continuous-time Markov chain and
/// solves it. Nothing here changes the net: the states are the ones lesson 3 already built, and
/// a rate only says how long a token waits before a transition takes it.
/// </summary>
public static class Stochastic
{
    /// <summary>
    /// The stationary distribution. Immediate transitions make a state *vanishing*: time does not
    /// pass there, so its probability is zero and it is removed before the chain is solved.
    /// </summary>
    public static SteadyState Solve(ReachabilityGraph graph, Timing timing)
    {
        ArgumentNullException.ThrowIfNull(graph);
        ArgumentNullException.ThrowIfNull(timing);
        if (!graph.IsComplete)
            throw new ArgumentException("The chain needs every reachable state; this graph stopped at its limit.", nameof(graph));
        if (graph.DeadStates.Count > 0)
            throw new ArgumentException(
                $"State {graph.DeadStates[0]} is dead: the net stops there, so it has no stationary distribution. "
                + "Lesson 4 decides deadlock; this lesson assumes there is none.", nameof(graph));

        var net = graph.Net;
        var n = graph.States.Count;

        // A state is vanishing when an immediate transition is enabled in it.
        var vanishing = new bool[n];
        for (var s = 0; s < n; s++)
            for (var t = 0; t < net.Transitions.Count; t++)
                if (timing.IsImmediate(net.Transitions[t].Id) && net.IsEnabled(graph.States[s], t))
                    vanishing[s] = true;

        var tangible = Enumerable.Range(0, n).Where(s => !vanishing[s]).ToArray();
        if (tangible.Length == 0)
            throw new ArgumentException("Every state is vanishing: the net never lets time pass.", nameof(timing));

        // Step from a state: an immediate transition wins over every timed one, and among
        // immediate transitions the weights split the choice.
        var rate = new double[n, n];
        for (var s = 0; s < n; s++)
        {
            var steps = graph.Steps.Where(x => x.From == s).ToArray();
            if (vanishing[s])
            {
                var immediate = steps.Where(x => timing.IsImmediate(net.Transitions[x.Transition].Id)).ToArray();
                var total = immediate.Sum(x => timing.Weight(net.Transitions[x.Transition].Id));
                foreach (var step in immediate)
                    rate[s, step.To] += timing.Weight(net.Transitions[step.Transition].Id) / total;
            }
            else
            {
                foreach (var step in steps)
                    rate[s, step.To] += timing.Rate(net.Transitions[step.Transition].Id);
            }
        }

        // Fold the vanishing states away: from a tangible state, follow zero-time steps until
        // time starts again. The probability of each landing state is the sum over all paths.
        var reduced = Absorb(rate, tangible, vanishing, n);

        // Solve pi Q = 0 with the probabilities summing to one.
        var m = tangible.Length;
        var a = new double[m, m + 1];
        for (var j = 0; j < m; j++)
        {
            for (var i = 0; i < m; i++)
                a[j, i] = i == j ? -RowSum(reduced, i, m) : reduced[i, j];
        }
        for (var i = 0; i < m; i++)
            a[m - 1, i] = 1.0;           // replace the last, redundant balance equation
        a[m - 1, m] = 1.0;

        var pi = SolveLinear(a, m);
        var sum = pi.Sum();
        for (var i = 0; i < m; i++)
            pi[i] /= sum;

        return new SteadyState(graph, timing, tangible, pi);
    }

    private static double RowSum(double[,] q, int i, int m)
    {
        var total = 0.0;
        for (var j = 0; j < m; j++)
            if (j != i)
                total += q[i, j];
        return total;
    }

    /// <summary>
    /// Rates between tangible states only. A step into a vanishing state is followed through the
    /// zero-time steps that leave it, which may themselves pass through other vanishing states;
    /// the landing probabilities are the solution of a small linear system per source state.
    /// </summary>
    private static double[,] Absorb(double[,] rate, int[] tangible, bool[] vanishing, int n)
    {
        var index = new int[n];
        for (var i = 0; i < tangible.Length; i++)
            index[tangible[i]] = i;

        var m = tangible.Length;
        var reduced = new double[m, m];
        var landing = new Dictionary<int, double[]>();   // vanishing state -> probability over tangible states

        for (var i = 0; i < m; i++)
        {
            var s = tangible[i];
            for (var to = 0; to < n; to++)
            {
                if (rate[s, to] == 0) continue;
                if (!vanishing[to])
                {
                    reduced[i, index[to]] += rate[s, to];
                    continue;
                }
                if (!landing.TryGetValue(to, out var spread))
                    landing[to] = spread = Landing(rate, to, tangible, vanishing, index, n);
                for (var j = 0; j < m; j++)
                    if (spread[j] != 0)
                        reduced[i, j] += rate[s, to] * spread[j];
            }
        }
        return reduced;
    }

    /// <summary>Where a walk that starts in a vanishing state lands, by iterating the zero-time steps.</summary>
    private static double[] Landing(double[,] rate, int start, int[] tangible, bool[] vanishing, int[] index, int n)
    {
        var landing = new double[tangible.Length];
        var current = new Dictionary<int, double> { [start] = 1.0 };

        // Zero-time steps form a sub-chain over vanishing states; a net whose immediate
        // transitions loop for ever has no semantics, so the walk is bounded.
        for (var depth = 0; depth < n + 1 && current.Count > 0; depth++)
        {
            var next = new Dictionary<int, double>();
            foreach (var (s, weight) in current)
            {
                for (var to = 0; to < n; to++)
                {
                    if (rate[s, to] == 0) continue;
                    if (vanishing[to])
                        next[to] = next.GetValueOrDefault(to) + weight * rate[s, to];
                    else
                        landing[index[to]] += weight * rate[s, to];
                }
            }
            current = next;
        }
        if (current.Count > 0)
            throw new ArgumentException($"The immediate transitions from state {start} never stop firing.");
        return landing;
    }

    /// <summary>Gaussian elimination with partial pivoting on an m by (m+1) augmented matrix.</summary>
    private static double[] SolveLinear(double[,] a, int m)
    {
        for (var col = 0; col < m; col++)
        {
            var pivot = col;
            for (var row = col + 1; row < m; row++)
                if (Math.Abs(a[row, col]) > Math.Abs(a[pivot, col]))
                    pivot = row;
            if (Math.Abs(a[pivot, col]) < 1e-14)
                throw new InvalidOperationException(
                    "The chain does not have one stationary distribution: it splits into parts that cannot reach each other.");
            if (pivot != col)
                for (var k = col; k <= m; k++)
                    (a[col, k], a[pivot, k]) = (a[pivot, k], a[col, k]);

            for (var row = 0; row < m; row++)
            {
                if (row == col) continue;
                var factor = a[row, col] / a[col, col];
                if (factor == 0) continue;
                for (var k = col; k <= m; k++)
                    a[row, k] -= factor * a[col, k];
            }
        }

        var x = new double[m];
        for (var i = 0; i < m; i++)
            x[i] = a[i, m] / a[i, i];
        return x;
    }

    /// <summary>
    /// The stationary distribution of an M/M/1/K queue, computed from the textbook formula
    /// rather than from the net, so the two can be compared.
    /// </summary>
    public static double[] QueueFormula(double arrival, double service, int capacity)
    {
        var rho = arrival / service;
        var p = new double[capacity + 1];
        if (Math.Abs(rho - 1.0) < 1e-12)
        {
            for (var k = 0; k <= capacity; k++)
                p[k] = 1.0 / (capacity + 1);
            return p;
        }
        var p0 = (1 - rho) / (1 - Math.Pow(rho, capacity + 1));
        for (var k = 0; k <= capacity; k++)
            p[k] = p0 * Math.Pow(rho, k);
        return p;
    }

    /// <summary>Formats a probability the same way on every machine: four decimals, invariant culture.</summary>
    public static string Format(double value) => value.ToString("F4", CultureInfo.InvariantCulture);
}
