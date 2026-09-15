namespace Snippets;

// Lesson 1: methods whose IL shows boxing, constrained calls and defensive copies
public static class Boxing
{
    public static int ToObjectAndBack(int value)
    {
        object boxed = value;
        return (int)boxed;
    }

    public static bool ThroughInterface<T>(T left, T right) where T : struct, IEquatable<T>
    {
        IEquatable<T> equatable = left;
        return equatable.Equals(right);
    }

    public static bool ThroughConstraint<T>(T left, T right) where T : IEquatable<T> =>
        left.Equals(right);

    public static string Format(int value) => string.Format("{0}", value);

    public static string Interpolate(int value) => $"{value}";
}

public struct Counter
{
    public int Value;

    public void Increment() => Value++;
}

public static class DefensiveCopy
{
    public static int ByIn(in Counter counter)
    {
        counter.Increment();
        return counter.Value;
    }

    public static int ByRef(ref Counter counter)
    {
        counter.Increment();
        return counter.Value;
    }
}

public static class Escape
{
    public static int BoxAndHash(int value)
    {
        object boxed = value;
        return boxed.GetHashCode();
    }
}
