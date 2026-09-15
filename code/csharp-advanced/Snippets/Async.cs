namespace Snippets;

// Lesson 3: an async method small enough to read once the compiler has rewritten it
public static class AsyncMachine
{
    public static async Task<int> AddLaterAsync(int left, int right)
    {
        await Task.Yield();
        var sum = left + right;
        await Task.Delay(1);
        return sum;
    }
}
