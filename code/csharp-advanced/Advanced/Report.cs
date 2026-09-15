namespace Advanced;

// Output helpers shared by the lessons
public static class Report
{
    public static void Title(string title)
    {
        Console.WriteLine();
        Console.WriteLine($"== {title}");
    }

    public static void Line(string text = "") => Console.WriteLine(text);

    // A line that depends on the machine or on timing: printed, not compared by check.sh
    public static void Machine(string text) => Console.WriteLine($"# {text}");

    // Bytes allocated on this thread by one call, after a first call has run the JIT and the static constructors
    public static long Allocated(Action action)
    {
        action();
        var before = GC.GetAllocatedBytesForCurrentThread();
        action();
        return GC.GetAllocatedBytesForCurrentThread() - before;
    }
}
