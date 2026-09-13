// Lesson 4: reified generics and declaration-site variance on the C# side.
static class L04
{
    static T Create<T>() where T : new() => new T();

    static string Describe<T>() => typeof(T).Name;

    public static void Run()
    {
        Console.WriteLine(typeof(List<string>) == typeof(List<int>));
        Console.WriteLine(new List<int>().GetType());
        Console.WriteLine(Create<System.Text.StringBuilder>().Length);
        Console.WriteLine(Describe<DateTime>());

        object value = new List<string> { "Ada" };
        Console.WriteLine(value is List<string>);
        Console.WriteLine(value is List<int>);

        IEnumerable<object> objects = new List<string> { "Ada" };  // IEnumerable<out T> is covariant
        Console.WriteLine(objects.First());

        object[] slots = new string[2];
        try
        {
            slots[0] = 42;
        }
        catch (ArrayTypeMismatchException e)
        {
            Console.WriteLine($"ArrayTypeMismatchException: {e.Message}");
        }
    }
}
