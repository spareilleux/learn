using System.Text;

// "Ré" is two characters; how many bytes does the file get?
File.WriteAllText("note.txt", "Ré");
byte[] bytes = File.ReadAllBytes("note.txt");
Console.WriteLine($"Default:       {bytes.Length} bytes: {Convert.ToHexString(bytes)}");

// Encoding.UTF8 adds a byte order mark (BOM), EF BB BF, at the start of the file
File.WriteAllText("note.txt", "Ré", Encoding.UTF8);
bytes = File.ReadAllBytes("note.txt");
Console.WriteLine($"Encoding.UTF8: {bytes.Length} bytes: {Convert.ToHexString(bytes)}");

// ReadAllText recognizes the mark and removes it
string text = File.ReadAllText("note.txt");
Console.WriteLine($"Read back: {text}, {text.Length} characters");
File.Delete("note.txt");
