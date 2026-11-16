// A relative path starts from the current directory: the folder dotnet run was started from
string relative = Path.Combine("data", "ga-projects.csv");
Console.WriteLine($"From the current directory: {File.Exists(relative)}");

// A file-based app can ask for the folder of its .cs file, whatever the current directory
string folder = (string)AppContext.GetData("EntryPointFileDirectoryPath")!;
string fromProgram = Path.Combine(folder, "..", "data", "ga-projects.csv");
Console.WriteLine($"From the program's folder: {File.Exists(fromProgram)}");
