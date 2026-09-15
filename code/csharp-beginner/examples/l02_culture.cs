using System.Globalization;

// The format of numbers depends on the culture: the language and region of the user
double frequency = 1234.5;
foreach (string name in new[] { "en-US", "fr-FR", "es-ES" })
{
    CultureInfo.CurrentCulture = new CultureInfo(name);
    bool ok = double.TryParse("1.5", out double parsed);
    Console.WriteLine($"{name}: {frequency:F1}  \"1.5\" read as {parsed} ({ok})");
}

// The invariant culture gives the same result everywhere: use it for files and data
CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
Console.WriteLine(double.Parse("1.5"));
