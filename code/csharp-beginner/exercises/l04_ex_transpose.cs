// Exercise 2: transpose a chord, a list of note names, by a number of semitones
string[] chromatic = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

List<string> cMajor = ["C", "E", "G"];
Console.WriteLine(string.Join(" ", Transpose(cMajor, 2)));
Console.WriteLine(string.Join(" ", Transpose(cMajor, 7)));
Console.WriteLine(string.Join(" ", Transpose(["A", "C", "E"], -3)));
Console.WriteLine(string.Join(" ", cMajor));        // unchanged: Transpose returns a new list

List<string> Transpose(List<string> notes, int semitones)
{
    List<string> result = [];
    foreach (string note in notes)
    {
        int index = Array.IndexOf(chromatic, note);
        int moved = ((index + semitones) % 12 + 12) % 12;   // + 12 keeps negative steps in 0..11
        result.Add(chromatic[moved]);
    }
    return result;
}
