// Lesson 4, the C# side: dotnet run l04_equality.cs (.NET 10)
var a = new Point(1, 2);
var b = new Point(1, 2);
Console.WriteLine($"a == b (record):        {a == b}");
Console.WriteLine($"ReferenceEquals(a, b):  {ReferenceEquals(a, b)}");

var visits = new Dictionary<Point, string> { [a] = "first" };
visits[b] = "second"; // same key: Equals and GetHashCode come from the record
Console.WriteLine($"visits.Count:           {visits.Count}");

var c = new PlainPoint(1, 2);
var d = new PlainPoint(1, 2);
Console.WriteLine($"c == d (class):         {c == d}");

var moved = a with { Y = 5 }; // a shallow copy with one change
Console.WriteLine($"a with {{ Y = 5 }}:       {moved}");

record Point(int X, int Y);

class PlainPoint(int x, int y)
{
    public int X { get; } = x;
    public int Y { get; } = y;
}
