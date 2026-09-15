// expect: CS8414
public static class Progressions
{
    public static async IAsyncEnumerable<string> ChordsAsync()
    {
        await Task.Yield();
        yield return "Dm7";
    }

    public static void Print()
    {
        foreach (var chord in ChordsAsync())
        {
            Console.WriteLine(chord);
        }
    }
}
