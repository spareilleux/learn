#:package CsvHelper@33.1.0
using System.Globalization;
using CsvHelper;

// Lesson 10's line, read this time by the CsvHelper package from NuGet
string line = "\"Crosby, Stills & Nash\",Suite: Judy Blue Eyes,1969";
using var parser = new CsvParser(new StringReader(line), CultureInfo.InvariantCulture);
parser.Read();
string[] fields = parser.Record!;
Console.WriteLine($"CsvHelper: {fields.Length} fields: {string.Join(" | ", fields)}");
