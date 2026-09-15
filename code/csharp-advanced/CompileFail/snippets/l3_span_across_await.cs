// expect: CS4007
public static class Frets
{
    public static async Task<int> SumAsync(int[] frets)
    {
        Span<int> window = frets.AsSpan(0, 3);
        await Task.Yield();
        return window[0] + window[1] + window[2]; // the span would outlive the stack frame
    }
}
