// Lesson 3, the C# side: dotnet run l03_closures.cs (.NET 10)
var withFor = new List<Func<int>>();
for (int i = 0; i < 3; i++)
{
    withFor.Add(() => i); // one variable i for the whole loop
}
var withForeach = new List<Func<int>>();
foreach (int j in new[] { 0, 1, 2 })
{
    withForeach.Add(() => j); // one variable j per iteration, since C# 5
}
Console.WriteLine($"for:     {string.Join(", ", withFor.Select(f => f()))}");
Console.WriteLine($"foreach: {string.Join(", ", withForeach.Select(f => f()))}");

// A method group keeps its object: no equivalent of losing this
var player = new Player();
Func<string> play = player.Play;
Console.WriteLine($"method group: {play()}");

class Player
{
    public string Name { get; } = "GA";
    public string Play() => $"{Name} plays";
}
