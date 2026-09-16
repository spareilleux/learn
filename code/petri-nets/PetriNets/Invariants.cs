namespace PetriNets;

/// <summary>A non-negative integer invariant: its weights, and the indices it actually uses.</summary>
public sealed record Invariant(int[] Weights)
{
    public IReadOnlyList<int> Support => [.. Enumerable.Range(0, Weights.Length).Where(i => Weights[i] != 0)];

    public override string ToString() => "(" + string.Join(", ", Weights) + ")";
}

/// <summary>
/// Place and transition invariants, computed by the Farkas elimination described in
/// Murata 1989, section V-B: no marking is ever enumerated, so an invariant says something
/// about every reachable marking at once, including the markings of an unbounded net.
/// </summary>
public static class Invariants
{
    /// <summary>
    /// Place invariants (P-semiflows): the vectors y with non-negative integer weights such that
    /// y times C is zero. For every such y the weighted token count y times M stays equal to
    /// y times M0 in every reachable marking M.
    /// </summary>
    public static IReadOnlyList<Invariant> Places(PetriNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        return Farkas(net.Incidence(), net.Places.Count, net.Transitions.Count);
    }

    /// <summary>
    /// Transition invariants (T-semiflows): the vectors x with non-negative integer weights such
    /// that C times x is zero. A firing sequence that fires each transition x[t] times, if it can
    /// run at all, brings the net back to the marking it started from.
    /// </summary>
    public static IReadOnlyList<Invariant> Transitions(PetriNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        var c = net.Incidence();
        var transposed = new int[net.Transitions.Count, net.Places.Count];
        for (var p = 0; p < net.Places.Count; p++)
            for (var t = 0; t < net.Transitions.Count; t++)
                transposed[t, p] = c[p, t];
        return Farkas(transposed, net.Transitions.Count, net.Places.Count);
    }

    /// <summary>
    /// The weighted token count of an invariant at a marking. It is the same for every reachable
    /// marking, which is what makes a place invariant a proof rather than a search.
    /// </summary>
    public static int WeightedTokens(Invariant invariant, Marking marking)
    {
        ArgumentNullException.ThrowIfNull(invariant);
        ArgumentNullException.ThrowIfNull(marking);
        var total = 0;
        for (var i = 0; i < invariant.Weights.Length; i++)
        {
            if (invariant.Weights[i] == 0) continue;
            if (marking[i] == Marking.Omega) throw new ArgumentException("The marking holds omega.", nameof(marking));
            total += invariant.Weights[i] * marking[i];
        }
        return total;
    }

    /// <summary>
    /// Farkas' elimination: start from the rows of the matrix, each tagged with the unit vector that
    /// produced it, then remove one column at a time by adding together pairs of rows of opposite sign.
    /// What is left are the non-negative generators; only those of minimal support are kept.
    /// </summary>
    private static IReadOnlyList<Invariant> Farkas(int[,] matrix, int rows, int columns)
    {
        // Each row is [matrix row | tag], the tag starting as a unit vector.
        var work = new List<int[]>();
        for (var r = 0; r < rows; r++)
        {
            var row = new int[columns + rows];
            for (var c = 0; c < columns; c++) row[c] = matrix[r, c];
            row[columns + r] = 1;
            work.Add(row);
        }

        for (var c = 0; c < columns; c++)
        {
            var positive = work.Where(r => r[c] > 0).ToList();
            var negative = work.Where(r => r[c] < 0).ToList();
            var kept = work.Where(r => r[c] == 0).ToList();

            foreach (var p in positive)
            {
                foreach (var n in negative)
                {
                    var a = -n[c];
                    var b = p[c];
                    var combined = new int[p.Length];
                    for (var i = 0; i < combined.Length; i++) combined[i] = checked(a * p[i] + b * n[i]);
                    kept.Add(Normalise(combined));
                }
            }

            work = Deduplicate(kept);
        }

        var invariants = work
            .Select(row => row[columns..])
            .Where(tag => tag.Any(w => w != 0))
            .Select(Normalise)
            .ToList();

        return [.. MinimalSupport(invariants).Select(w => new Invariant(w))];
    }

    /// <summary>Divides a vector by the greatest common divisor of its entries, so (2, 4) and (1, 2) are one vector.</summary>
    private static int[] Normalise(int[] row)
    {
        var divisor = 0;
        foreach (var value in row) divisor = Gcd(divisor, Math.Abs(value));
        if (divisor <= 1) return row;
        var result = new int[row.Length];
        for (var i = 0; i < row.Length; i++) result[i] = row[i] / divisor;
        return result;
    }

    private static int Gcd(int a, int b)
    {
        while (b != 0) (a, b) = (b, a % b);
        return a;
    }

    private static List<int[]> Deduplicate(List<int[]> rows)
    {
        var seen = new List<int[]>();
        foreach (var row in rows)
        {
            if (!seen.Any(other => other.AsSpan().SequenceEqual(row))) seen.Add(row);
        }
        return seen;
    }

    /// <summary>Drops every vector whose support strictly contains the support of another one.</summary>
    private static List<int[]> MinimalSupport(List<int[]> vectors)
    {
        var supports = vectors.Select(v => Enumerable.Range(0, v.Length).Where(i => v[i] != 0).ToHashSet()).ToList();
        var kept = new List<int[]>();
        for (var i = 0; i < vectors.Count; i++)
        {
            var redundant = false;
            for (var j = 0; j < vectors.Count && !redundant; j++)
            {
                if (i == j) continue;
                if (supports[j].IsProperSubsetOf(supports[i])) redundant = true;
                // Two vectors with the same support: keep the first one only.
                else if (j < i && supports[j].SetEquals(supports[i])) redundant = true;
            }
            if (!redundant) kept.Add(vectors[i]);
        }

        kept.Sort(Compare);
        return kept;
    }

    private static int Compare(int[] a, int[] b)
    {
        for (var i = 0; i < a.Length; i++)
        {
            if (a[i] != b[i]) return b[i].CompareTo(a[i]);
        }
        return 0;
    }
}
