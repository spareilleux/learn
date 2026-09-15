// The first five frets of a guitar in standard tuning (E2 A2 D3 G3 B3 E4, Tuning.Default in GA).
// Each note is a number of semitones: C is 0, C# is 1, ... B is 11, and the next C is 12 again.
for (int stringNumber = 6; stringNumber >= 1; stringNumber--)
{
    // Semitones of the open string above C
    int open = stringNumber switch
    {
        6 => 4,    // E
        5 => 9,    // A
        4 => 2,    // D
        3 => 7,    // G
        2 => 11,   // B
        _ => 4,    // E (string 1)
    };

    Console.Write($"String {stringNumber}:");
    for (int fret = 0; fret <= 5; fret++)
    {
        int semitone = (open + fret) % 12;     // % 12 folds 12 back to 0: the octave
        string name = semitone switch
        {
            0 => "C", 1 => "C#", 2 => "D", 3 => "D#", 4 => "E", 5 => "F",
            6 => "F#", 7 => "G", 8 => "G#", 9 => "A", 10 => "A#", _ => "B",
        };
        Console.Write($" {name,-2}");
    }
    Console.WriteLine();
}
