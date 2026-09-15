// compare/l04_closures.cs
var fromFor = new List<Func<int, int>>();
for (int i = 0; i < 3; i++)
{
    fromFor.Add(note => note + i); // one i for the whole loop, as in Python
}
Console.WriteLine(string.Join(", ", fromFor.Select(transpose => transpose(10))));

var fromForeach = new List<Func<int, int>>();
foreach (var i in Enumerable.Range(0, 3))
{
    fromForeach.Add(note => note + i); // since C# 5, a new i for each iteration
}
Console.WriteLine(string.Join(", ", fromForeach.Select(transpose => transpose(10))));
