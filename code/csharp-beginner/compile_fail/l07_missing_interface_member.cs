IHasRange alto = new Voice("Alto", 53);
Console.WriteLine(alto.Name);

interface IHasRange
{
    string Name { get; }
    int LowestMidi { get; }
    int HighestMidi { get; }
}

record Voice(string Name, int LowestMidi) : IHasRange;
