// The same three lines, ended by \n (Linux, macOS) or by \r\n (Windows)
string[] endings = ["\n", "\r\n"];
foreach (string ending in endings)
{
    string name = ending == "\n" ? "LF" : "CRLF";
    File.WriteAllText("tuning.txt", "E2" + ending + "A2" + ending + "D3" + ending);

    string[] split = File.ReadAllText("tuning.txt").Split('\n');
    string[] lines = File.ReadAllLines("tuning.txt");

    Console.WriteLine($"{name}, Split('\\n'): {split.Length} items, lengths {string.Join(" ", split.Select(s => s.Length))}");
    Console.WriteLine($"{name}, ReadAllLines: {lines.Length} lines, lengths {string.Join(" ", lines.Select(s => s.Length))}");
    Console.WriteLine($"{name}, first line is \"E2\": {split[0] == "E2"} with Split, {lines[0] == "E2"} with ReadAllLines");
}
File.Delete("tuning.txt");
