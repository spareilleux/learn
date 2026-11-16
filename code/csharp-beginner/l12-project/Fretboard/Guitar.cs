namespace Fretboard;

// Lesson 11's library, unchanged
public static class Guitar
{
    static readonly string[] Chromatic = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

    // Lesson 4: the frequency of a fret, rounded to two decimals
    public static double FretFrequency(double openString, int fret)
    {
        double frequency = openString * Math.Pow(2, fret / 12.0);
        return Math.Round(frequency, 2);
    }

    // Lesson 4, exercise 2: a new list with each note moved by a number of semitones
    public static List<string> Transpose(List<string> notes, int semitones)
    {
        List<string> result = [];
        foreach (string note in notes)
        {
            int index = Array.IndexOf(Chromatic, note);
            int moved = ((index + semitones) % 12 + 12) % 12;   // + 12 keeps negative steps in 0..11
            result.Add(Chromatic[moved]);
        }
        return result;
    }

    // Lesson 8, exercise 2: a fret number read from text, from 0 to 24
    public static int ParseFret(string text)
    {
        int fret = int.Parse(text);
        ArgumentOutOfRangeException.ThrowIfNegative(fret);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(fret, 24);
        return fret;
    }
}
