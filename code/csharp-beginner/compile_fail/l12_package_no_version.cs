#:package CsvHelper
using System.Globalization;
using CsvHelper;

// Without @version, the restore refuses the package
using var parser = new CsvParser(new StringReader("a,b"), CultureInfo.InvariantCulture);
