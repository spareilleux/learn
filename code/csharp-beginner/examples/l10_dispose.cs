// A StreamWriter keeps the text in memory and writes it to the disk later
StreamWriter writer = new StreamWriter("notes.txt");
writer.Write("E2 A2 D3");
Console.WriteLine($"Before Dispose: {new FileInfo("notes.txt").Length} bytes");

writer.Dispose();                                         // writes what is left, then closes the file
Console.WriteLine($"After Dispose: {new FileInfo("notes.txt").Length} bytes");
File.Delete("notes.txt");
