// compare_fail/l04_defaults.cs
Console.WriteLine(string.Join(" ", AddNote("C")));

static List<string> AddNote(string note, List<string> chord = new List<string>())
{
    chord.Add(note);
    return chord;
}
