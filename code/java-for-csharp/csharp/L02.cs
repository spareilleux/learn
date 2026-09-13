// Lesson 2: the C# behaviour each Java example is compared with.
static class L02
{
    public static void Run()
    {
        int max = int.MaxValue;
        Console.WriteLine(unchecked(max + 1));
        try
        {
            Console.WriteLine(checked(max + One()));
        }
        catch (OverflowException e)
        {
            Console.WriteLine($"OverflowException: {e.Message}");
        }

        byte b = 200;               // byte is unsigned in C#
        sbyte s = unchecked((sbyte)200);
        Console.WriteLine(b);
        Console.WriteLine(s);

        object boxedA = 127, boxedB = 127;
        Console.WriteLine(boxedA == boxedB);        // reference comparison on object
        Console.WriteLine(boxedA.Equals(boxedB));

        string literal = "hello";
        string built = new System.Text.StringBuilder("hel").Append("lo").ToString();
        Console.WriteLine(literal == built);         // string overloads == to compare values
        Console.WriteLine((object)literal == built); // reference comparison

        char c = 'a';
        Console.WriteLine(c + 1);
        Console.WriteLine((char)(c + 1));
    }

    static int One() => 1;
}
