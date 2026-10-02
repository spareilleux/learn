ChordQuality quality = (ChordQuality)7;

// Every name has an arm, and still the compiler warns: an enum can hold other numbers
string suffix = quality switch
{
    ChordQuality.Other => "?",
    ChordQuality.Major => "",
    ChordQuality.Minor => "m",
    ChordQuality.Diminished => "dim",
    ChordQuality.Augmented => "aug",
};
Console.WriteLine(suffix);

enum ChordQuality
{
    Other,
    Major,
    Minor,
    Diminished,
    Augmented,
}
