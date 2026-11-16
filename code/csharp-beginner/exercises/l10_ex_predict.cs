// Exercise 1: predict each line before running the program
File.WriteAllText("chords.txt", "C\nG\nAm\nF\n");
Console.WriteLine(File.ReadAllLines("chords.txt").Length);
Console.WriteLine(File.ReadAllText("chords.txt").Split('\n').Length);

File.AppendAllText("chords.txt", "C");
Console.WriteLine(File.ReadAllLines("chords.txt").Length);
Console.WriteLine(File.ReadAllLines("chords.txt")[^1]);

File.WriteAllText("chords.txt", "");
Console.WriteLine(File.ReadAllLines("chords.txt").Length);

File.Delete("chords.txt");
Console.WriteLine(File.Exists("chords.txt"));
