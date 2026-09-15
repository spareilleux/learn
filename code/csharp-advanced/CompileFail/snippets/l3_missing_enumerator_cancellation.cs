// expect: CS8425
public static class Frets
{
    public static async IAsyncEnumerable<int> AllAsync(CancellationToken token = default)
    {
        for (var fret = 0; fret < 12; fret++)
        {
            await Task.Delay(1, token);
            yield return fret;
        }
    }
}
