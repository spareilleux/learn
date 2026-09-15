namespace GaAi;

using System.Globalization;

// Prints the lesson tables in a stable, culture-independent format
public static class Report
{
    public static void Title(string title)
    {
        Console.WriteLine();
        Console.WriteLine($"== {title}");
    }

    public static void Line(string text = "") => Console.WriteLine(text);

    // One row of left-aligned columns; `widths` gives the width of every column but the last
    public static void Row(int[] widths, params object?[] cells)
    {
        var parts = cells.Select((c, i) =>
        {
            var s = Str(c);
            return i < widths.Length ? s.PadRight(widths[i]) : s;
        });
        Console.WriteLine(string.Join(" ", parts).TrimEnd());
    }

    public static string Str(object? value) => value switch
    {
        null => "(none)",
        double d => F(d),
        float f => F(f),
        _ => Convert.ToString(value, CultureInfo.InvariantCulture) ?? "",
    };

    // Three decimals, and never "-0.000"
    public static string F(double value)
    {
        var s = value.ToString("0.000", CultureInfo.InvariantCulture);
        return s == "-0.000" ? "0.000" : s;
    }

    // A vector slice with up to two decimals per value: "1 0 0.5 0.83"
    public static string Vec(IEnumerable<float> values) =>
        string.Join(" ", values.Select(v =>
        {
            var s = v.ToString("0.##", CultureInfo.InvariantCulture);
            return s == "-0" ? "0" : s;
        }));

    public static string Ints(IEnumerable<int> values) => string.Join(" ", values);
}
