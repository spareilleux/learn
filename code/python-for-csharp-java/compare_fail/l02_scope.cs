// compare_fail/l02_scope.cs
foreach (var text in new[] { "E", "A", "D" })
{
    var last = text.ToLowerInvariant();
}
Console.WriteLine(text + last);
