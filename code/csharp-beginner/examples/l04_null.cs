// string? : a string, or null (no string at all)
string? capo = null;
Console.WriteLine(capo == null);
Console.WriteLine(capo is null);

// ?. gives null instead of reading a member of null; ?? gives a value to use instead of null
Console.WriteLine(capo?.Length);
Console.WriteLine(capo ?? "no capo");
Console.WriteLine(capo?.Length ?? 0);

capo ??= "fret 2";                       // assigns only if capo is null
Console.WriteLine(capo);
Console.WriteLine(capo.Length);          // the compiler knows capo isn't null here

// Console.ReadLine returns null when there is nothing left to read
List<string> lines = [];
string? line;
while ((line = Console.ReadLine()) != null)
{
    if (!string.IsNullOrWhiteSpace(line))
    {
        lines.Add(line.Trim());
    }
}
Console.WriteLine($"{lines.Count} non-empty lines: {string.Join(" | ", lines)}");
