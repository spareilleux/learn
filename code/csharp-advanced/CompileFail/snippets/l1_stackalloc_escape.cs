// expect: CS8352
public static class Frets
{
    public static Span<int> Empty()
    {
        Span<int> frets = stackalloc int[6];
        return frets; // the memory disappears when the method returns
    }
}
