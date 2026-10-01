// An interface is a contract: a class and a record sign it, with no common base class
List<IHasRange> performers =
[
    new FrettedInstrument("Guitar", 40, 64, 22),    // open strings E2 to E4, 22 frets
    new FrettedInstrument("Ukulele", 60, 69, 12),   // open strings C4 to A4, 12 frets
    new Voice("Alto", 53, 77),                      // F3 to F5
];

foreach (IHasRange performer in performers)
{
    Console.WriteLine($"{performer.Name}: MIDI {performer.LowestMidi} to {performer.HighestMidi}");
}

foreach (int midi in new[] { 40, 55, 69, 84 })
{
    List<string> names = [];
    foreach (IHasRange performer in performers)
    {
        if (CanPlay(performer, midi))
        {
            names.Add(performer.Name);
        }
    }
    Console.WriteLine($"MIDI {midi}: {string.Join(", ", names)}");
}

bool CanPlay(IHasRange performer, int midi) => midi >= performer.LowestMidi && midi <= performer.HighestMidi;

interface IHasRange
{
    string Name { get; }
    int LowestMidi { get; }
    int HighestMidi { get; }
}

sealed class FrettedInstrument : IHasRange
{
    public string Name { get; }
    public int LowestMidi { get; }
    public int HighestMidi { get; }

    public FrettedInstrument(string name, int lowestOpen, int highestOpen, int frets)
    {
        Name = name;
        LowestMidi = lowestOpen;
        HighestMidi = highestOpen + frets;
    }
}

record Voice(string Name, int LowestMidi, int HighestMidi) : IHasRange;
