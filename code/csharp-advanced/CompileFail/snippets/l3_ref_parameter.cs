// expect: CS1988
public static class Frets
{
    public static async Task NextAsync(ref int fret)
    {
        await Task.Yield();
        fret++;
    }
}
