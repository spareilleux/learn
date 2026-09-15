// expect: CS8168
public static class Counters
{
    public static ref int Next()
    {
        var count = 0;
        return ref count;
    }
}
