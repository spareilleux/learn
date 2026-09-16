// Lesson 13: dotnet run -- migrate | validate. MSSQL_CONNECTION and PG_CONNECTION override the connection strings.
using System.Globalization;
using Learn.Pg;

// The outputs must not depend on the machine's culture
CultureInfo.CurrentCulture = CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;

var examples = new Dictionary<string, Func<Task>>
{
    ["l13-migrate"] = L13.Migrate,
    ["l13-validate"] = L13.Validate,
};

if (args.Length != 1 || !examples.TryGetValue(args[0], out var example))
{
    Console.Error.WriteLine($"usage: migrate <{string.Join('|', examples.Keys)}>");
    return 2;
}

await example();
return 0;
