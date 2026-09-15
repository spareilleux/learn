// compare/l02_nullable.cs
using System.Collections.Generic;

string Initial(string? name) => name.Substring(0, 1); // CS8602, a warning: the program still builds

var tunings = new Dictionary<string, string> { ["standard"] = "EADGBE" };
tunings.TryGetValue("drop D", out var dropD);
string certain = dropD!; // the same ! as TypeScript, with the same meaning: trust me

try { Console.WriteLine(Initial(null)); }
catch (NullReferenceException e) { Console.WriteLine($"Initial(null): {e.GetType().Name}"); }
try { Console.WriteLine(certain.Length); }
catch (NullReferenceException e) { Console.WriteLine($"certain.Length: {e.GetType().Name}"); }
