string? FindTuning(string name)
{
    if (name == "standard")
    {
        return "E A D G B E";
    }
    return null;
}

string? tuning = FindTuning("drop D");
Console.WriteLine(tuning.Length);   // warning CS8602, then a NullReferenceException at run time
