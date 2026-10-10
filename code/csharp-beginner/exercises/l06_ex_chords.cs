List<Chord> cMajor =
[
    new Chord("C", ChordQuality.Major),
    new Chord("D", ChordQuality.Minor),
    new Chord("E", ChordQuality.Minor),
    new Chord("F", ChordQuality.Major),
    new Chord("G", ChordQuality.Major),
    new Chord("A", ChordQuality.Minor),
    new Chord("B", ChordQuality.Diminished),
];

List<string> symbols = [];
foreach (Chord chord in cMajor)
{
    symbols.Add(chord.Symbol());
}
Console.WriteLine(string.Join(" ", symbols));

Chord am = new Chord("A", ChordQuality.Minor);
Chord aMajor = am with { Quality = ChordQuality.Major };
Console.WriteLine($"Contains {am.Symbol()}: {cMajor.Contains(am)}");
Console.WriteLine($"Contains {aMajor.Symbol()}: {cMajor.Contains(aMajor)}");

record Chord(string Root, ChordQuality Quality)
{
    public string Symbol() => Quality switch
    {
        ChordQuality.Major => Root,
        ChordQuality.Minor => $"{Root}m",
        ChordQuality.Diminished => $"{Root}dim",
        _ => $"{Root}?",
    };
}

enum ChordQuality
{
    Other,
    Major,
    Minor,
    Diminished,
}
