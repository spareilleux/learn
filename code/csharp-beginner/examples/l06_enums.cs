// An enum names a fixed set of choices; each name stands for a number
ChordQuality quality = ChordQuality.Minor;
Console.WriteLine(quality);
Console.WriteLine((int)quality);
Console.WriteLine($"A{Suffix(quality)}");

foreach (ChordQuality q in Enum.GetValues<ChordQuality>())
{
    Console.WriteLine($"{(int)q} {q}: C{Suffix(q)}");
}

ChordQuality unset = default;               // the value 0
ChordQuality zero = 0;                      // the literal 0 converts without a cast
Console.WriteLine($"default: {unset}, 0: {zero}");

ChordQuality strange = (ChordQuality)7;     // a cast accepts any int
Console.WriteLine($"cast from 7: {strange}, defined: {Enum.IsDefined(strange)}");

ChordQuality parsed = Enum.Parse<ChordQuality>("Diminished");
Console.WriteLine($"parsed: {parsed} = {(int)parsed}");

string Suffix(ChordQuality q) => q switch
{
    ChordQuality.Major => "",
    ChordQuality.Minor => "m",
    ChordQuality.Diminished => "dim",
    ChordQuality.Augmented => "aug",
    _ => "?",
};

enum ChordQuality
{
    Other,
    Major,
    Minor,
    Diminished,
    Augmented,
}
