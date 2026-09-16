namespace PetriNets;

/// <summary>
/// A marking: how many tokens sit in each place, in the order of <see cref="PetriNet.Places"/>.
/// A count may be <see cref="Omega"/>, the symbol the coverability tree uses for
/// "as many as you like" (lesson 3). Markings are immutable and compare by value,
/// so they can be used as dictionary keys while a graph is being built.
/// </summary>
public sealed class Marking : IEquatable<Marking>
{
    /// <summary>The unbounded count, written ω. It absorbs addition and subtraction.</summary>
    public const int Omega = int.MaxValue;

    private readonly int[] _tokens;
    private readonly int _hash;

    public Marking(params int[] tokens)
    {
        ArgumentNullException.ThrowIfNull(tokens);
        _tokens = (int[])tokens.Clone();
        var hash = new HashCode();
        foreach (var n in _tokens)
        {
            ArgumentOutOfRangeException.ThrowIfNegative(n);
            hash.Add(n);
        }
        _hash = hash.ToHashCode();
    }

    public int this[int place] => _tokens[place];

    public int Count => _tokens.Length;

    public int[] ToArray() => (int[])_tokens.Clone();

    public bool HasOmega => _tokens.Contains(Omega);

    /// <summary>Total number of tokens, or null if any place holds ω.</summary>
    public int? TotalTokens => HasOmega ? null : _tokens.Sum();

    /// <summary>True when this marking is greater than or equal to <paramref name="other"/> place by place.</summary>
    public bool Covers(Marking other)
    {
        ArgumentNullException.ThrowIfNull(other);
        for (var i = 0; i < _tokens.Length; i++)
        {
            if (_tokens[i] < other._tokens[i]) return false;
        }
        return true;
    }

    /// <summary>True when this marking covers <paramref name="other"/> and differs from it.</summary>
    public bool StrictlyCovers(Marking other) => Covers(other) && !Equals(other);

    internal static int Add(int tokens, int delta) => tokens == Omega ? Omega : tokens + delta;

    public bool Equals(Marking? other) =>
        other is not null && (ReferenceEquals(this, other) || _tokens.AsSpan().SequenceEqual(other._tokens));

    public override bool Equals(object? obj) => Equals(obj as Marking);

    public override int GetHashCode() => _hash;

    /// <summary>The marking as "(1, 0, ω)", the form the lessons print.</summary>
    public override string ToString() =>
        "(" + string.Join(", ", _tokens.Select(n => n == Omega ? "\u03c9" : n.ToString())) + ")";

    /// <summary>The marking as "idle:1 buffer:2", listing only the places that hold tokens.</summary>
    public string ToString(PetriNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        var parts = Enumerable.Range(0, _tokens.Length)
            .Where(i => _tokens[i] != 0)
            .Select(i => $"{net.Places[i].Name}:{(_tokens[i] == Omega ? "\u03c9" : _tokens[i].ToString())}");
        return parts.Any() ? string.Join(" ", parts) : "(empty)";
    }
}
