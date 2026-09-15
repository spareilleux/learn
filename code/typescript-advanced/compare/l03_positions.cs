// compare/l03_positions.cs
// In C#, a nominal wrapper is a real type: a readonly record struct costs no allocation and carries its checks
var clicked = new FretboardPosition(new StringIndex(1), new Fret(3));
Console.WriteLine(OpenStringOf(clicked.String.ToStringNumber()));
Console.WriteLine(clicked);
try
{
    _ = new Fret(25);
}
catch (ArgumentOutOfRangeException e)
{
    Console.WriteLine(e.Message);
}

static string OpenStringOf(StringNumber number) => new[] { "E/5", "B/4", "G/4", "D/4", "A/3", "E/3" }[number.Value - 1];

readonly record struct StringIndex
{
    public int Value { get; }
    public StringIndex(int value)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(value);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(value, 5);
        Value = value;
    }
    public StringNumber ToStringNumber() => new(Value + 1);
}

readonly record struct StringNumber
{
    public int Value { get; }
    public StringNumber(int value)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(value, 1);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(value, 6);
        Value = value;
    }
}

readonly record struct Fret
{
    public int Value { get; }
    public Fret(int value)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(value);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(value, 24);
        Value = value;
    }
}

record FretboardPosition(StringIndex String, Fret Fret);
