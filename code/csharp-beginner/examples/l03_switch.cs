int semitone = 7;

// The switch statement: one case per value, each case ends with break
switch (semitone)
{
    case 0:
        Console.WriteLine("Unison");
        break;
    case 7:
        Console.WriteLine("Perfect fifth");
        break;
    case 12:
        Console.WriteLine("Octave");
        break;
    default:
        Console.WriteLine("Another interval");
        break;
}

// The switch expression computes a value: one arm per pattern, _ matches everything else
string name = semitone switch
{
    0 => "C",
    1 => "C#",
    2 => "D",
    3 => "D#",
    4 => "E",
    5 => "F",
    6 => "F#",
    7 => "G",
    8 => "G#",
    9 => "A",
    10 => "A#",
    11 => "B",
    _ => "not a semitone between 0 and 11",
};
Console.WriteLine($"Semitone {semitone} above C is {name}");

// Patterns can compare: the first arm that matches wins
foreach (int fret in new[] { 0, 3, 7, 12, 17, 30 })
{
    string zone = fret switch
    {
        0 => "open string",
        < 5 => "first position",
        < 12 => "middle of the neck",
        12 => "octave",
        <= 24 => "high on the neck",
        _ => "no such fret",
    };
    Console.WriteLine($"Fret {fret}: {zone}");
}
