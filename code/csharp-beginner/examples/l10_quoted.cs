using Microsoft.VisualBasic.FileIO;

// A value that contains a comma is put between quotes, and a plain Split cuts it anyway
string line = "\"Crosby, Stills & Nash\",Suite: Judy Blue Eyes,1969";
string[] split = line.Split(',');
Console.WriteLine($"Split: {split.Length} fields: {string.Join(" | ", split)}");

// TextFieldParser, which comes with .NET, knows about the quotes
using TextFieldParser parser = new TextFieldParser(new StringReader(line));
parser.SetDelimiters(",");
parser.HasFieldsEnclosedInQuotes = true;
string[] fields = parser.ReadFields()!;
Console.WriteLine($"TextFieldParser: {fields.Length} fields: {string.Join(" | ", fields)}");
