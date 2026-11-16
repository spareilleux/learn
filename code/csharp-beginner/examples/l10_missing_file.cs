// Reading a file that isn't there throws an exception: which one depends on what is missing
try
{
    string text = File.ReadAllText("missing.txt");
}
catch (FileNotFoundException ex)
{
    Console.WriteLine($"{ex.GetType().Name}: {Path.GetFileName(ex.FileName)}");
}

try
{
    string text = File.ReadAllText(Path.Combine("nowhere", "missing.txt"));
}
catch (DirectoryNotFoundException ex)
{
    Console.WriteLine(ex.GetType().Name);
}

// Asking first avoids the exception, but the file can still disappear between the two lines
if (File.Exists("missing.txt"))
{
    Console.WriteLine(File.ReadAllText("missing.txt"));
}
else
{
    Console.WriteLine("No missing.txt here");
}
