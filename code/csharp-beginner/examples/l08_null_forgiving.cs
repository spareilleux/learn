string? FindTuning(string name) => name == "standard" ? "E A D G B E" : null;

string tuning = FindTuning("drop D")!;   // ! silences the warning, not the null
Console.WriteLine(tuning.Length);
