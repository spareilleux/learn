// expect: CS8332
public struct Counter
{
    public int Value;
}

public static class Counters
{
    public static void Reset(in Counter counter) => counter.Value = 0;
}
