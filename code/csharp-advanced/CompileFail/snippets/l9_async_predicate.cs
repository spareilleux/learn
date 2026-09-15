// expect: CS4010
public static class Filters
{
    private static async Task<bool> IsSeventhAsync(string chord)
    {
        await Task.Yield();
        return chord.EndsWith('7');
    }

    public static IAsyncEnumerable<string> Sevenths(IAsyncEnumerable<string> chords) =>
        chords.Where(async chord => await IsSeventhAsync(chord));
}
