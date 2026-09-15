// expect: CS9108
public static class Frets
{
    public static Func<int> Sum(Span<int> frets) => () => frets[0] + frets[1];
}
