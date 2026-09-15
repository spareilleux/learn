// Exercise 3: read every line until the end of the input, then print the count and the longest line
List<string> lines = [];
string? line;
while ((line = Console.ReadLine()) != null)
{
    lines.Add(line);
}

string? longest = Longest(lines);
Console.WriteLine($"{lines.Count} lines");
Console.WriteLine($"Longest: {longest ?? "(no lines)"}");

string? Longest(List<string> values)
{
    string? best = null;
    foreach (string value in values)
    {
        if (best == null || value.Length > best.Length)
        {
            best = value;
        }
    }
    return best;
}
