using System.Globalization;

// One row of Guitar Alchemist's naturalness CSV, written as its generator writes it:
// the label, then $"{deltaAvg:F2},{deltaAvg:F2},{changedStrings},{deltaStretch},{sharedStrings}"
double deltaAvg = 2.5;
int changedStrings = 2;
double deltaStretch = 1;
int sharedStrings = 4;

string[] cultures = ["en-CA", "fr-FR"];
foreach (string name in cultures)
{
    CultureInfo.CurrentCulture = new CultureInfo(name);   // as on a Canadian, then a French machine
    string row = $"1,{deltaAvg:F2},{deltaAvg:F2},{changedStrings},{deltaStretch},{sharedStrings}";
    Console.WriteLine($"{name}: {row} -> {row.Split(',').Length} fields");
}

// string.Create with the invariant culture writes a dot on every machine
string invariant = string.Create(CultureInfo.InvariantCulture,
    $"1,{deltaAvg:F2},{deltaAvg:F2},{changedStrings},{deltaStretch},{sharedStrings}");
Console.WriteLine($"Invariant: {invariant} -> {invariant.Split(',').Length} fields");

// Reading it back: parse with the same culture as the one that wrote it
double read = double.Parse(invariant.Split(',')[1], CultureInfo.InvariantCulture);
Console.WriteLine(read == deltaAvg);
