// Path builds and takes apart file paths without caring about the operating system
string path = Path.Combine("data", "ga-projects.csv");   // data\ga-projects.csv on Windows, data/ga-projects.csv elsewhere

Console.WriteLine(Path.GetFileName(path));
Console.WriteLine(Path.GetFileNameWithoutExtension(path));
Console.WriteLine(Path.GetExtension(path));
Console.WriteLine(Path.GetFileName(Path.ChangeExtension(path, ".json")));
Console.WriteLine(Path.GetFileName(Path.GetDirectoryName(path)));
Console.WriteLine(Path.IsPathRooted(path));               // False: a relative path

// The separator is the only difference between the systems
Console.WriteLine(path == "data" + Path.DirectorySeparatorChar + "ga-projects.csv");
