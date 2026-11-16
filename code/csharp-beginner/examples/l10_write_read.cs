// Write a text file, add to it, read it back, then delete it
string path = "practice.txt";

File.WriteAllText(path, "Monday: 30 minutes\n");       // creates the file, or replaces its content
File.AppendAllText(path, "Tuesday: 45 minutes\n");     // adds at the end
Console.WriteLine(File.Exists(path));

string text = File.ReadAllText(path);                   // the whole file in one string
Console.Write(text);

string[] lines = File.ReadAllLines(path);               // one string per line, without the line breaks
Console.WriteLine($"{lines.Length} lines, the last one: {lines[^1]}");

File.WriteAllLines(path, ["E2", "A2", "D3", "G3", "B3", "E4"]);   // replaces the content, one item per line
Console.WriteLine(string.Join(" ", File.ReadAllLines(path)));

File.Delete(path);
Console.WriteLine(File.Exists(path));
