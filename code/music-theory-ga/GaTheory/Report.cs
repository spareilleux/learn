namespace GaTheory;

// Prints the lesson tables: the course's value next to Guitar Alchemist's, and whether they agree
public static class Report
{
    static int _width = 20;

    public static void Title(string title)
    {
        Console.WriteLine();
        Console.WriteLine($"== {title}");
    }

    // Header of a comparison table; `width` is the width of the course and GA columns
    public static void Columns(string label, int labelWidth = 14, int width = 20)
    {
        _width = width;
        _labelWidth = labelWidth;
        Console.WriteLine($"{label.PadRight(labelWidth)} {"course".PadRight(width)} {"GA".PadRight(width)} check");
    }

    static int _labelWidth = 14;

    public static void Row(string label, object? course, object? ga)
    {
        var c = course?.ToString() ?? "(none)";
        var g = ga?.ToString() ?? "(none)";
        var check = c == g ? "ok" : "DIFF";
        Console.WriteLine($"{label.PadRight(_labelWidth)} {c.PadRight(_width)} {g.PadRight(_width)} {check}");
    }

    // Runs a GA call and turns an exception into a short, stable description
    public static string Try(Func<object?> call)
    {
        try
        {
            return call()?.ToString() ?? "(null)";
        }
        catch (Exception e)
        {
            return $"throws {e.GetType().Name}";
        }
    }

    // A plain aligned row, for tables that show data instead of comparing the course with GA
    public static void Plain(string label, object? first, object? second = null) =>
        Console.WriteLine($"{label.PadRight(_labelWidth)} {(first?.ToString() ?? string.Empty).PadRight(_width)} {second}".TrimEnd());

    // Header of a plain table
    public static void Headings(string label, string first, string second, int labelWidth = 14, int width = 20)
    {
        _width = width;
        _labelWidth = labelWidth;
        Plain(label, first, second);
    }

    public static void Line(string text = "") => Console.WriteLine(text);
}
