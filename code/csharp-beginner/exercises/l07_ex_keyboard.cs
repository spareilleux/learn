List<IHasRange> performers =
[
    new Voice("Alto", 53, 77),
    new MidiKeyboard(25, 48),       // 25 keys from C3
];

foreach (IHasRange performer in performers)
{
    Console.WriteLine($"{performer.Name}: MIDI {performer.LowestMidi} to {performer.HighestMidi}");
}

foreach (int midi in new[] { 50, 60, 75 })
{
    List<string> names = [];
    foreach (IHasRange performer in performers)
    {
        if (midi >= performer.LowestMidi && midi <= performer.HighestMidi)
        {
            names.Add(performer.Name);
        }
    }
    Console.WriteLine($"MIDI {midi}: {string.Join(", ", names)}");
}

interface IHasRange
{
    string Name { get; }
    int LowestMidi { get; }
    int HighestMidi { get; }
}

record Voice(string Name, int LowestMidi, int HighestMidi) : IHasRange;

record MidiKeyboard(int Keys, int LowestMidi) : IHasRange
{
    public string Name => $"Keyboard ({Keys} keys)";
    public int HighestMidi => LowestMidi + Keys - 1;
}
