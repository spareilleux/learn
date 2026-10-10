// A derived record writes its own ToString, unless its base record seals ToString
ChordTemplate open = new Seventh("Major 7th");
SealedTemplate kept = new SealedSeventh("Major 7th");

Console.WriteLine(open);                    // Seventh's own ToString lists its properties
Console.WriteLine(kept);                    // the base's sealed ToString prints the name

abstract record ChordTemplate
{
    public abstract string Name { get; }

    public override string ToString() => Name;
}

record Seventh(string Quality) : ChordTemplate
{
    public override string Name => Quality;
}

abstract record SealedTemplate
{
    public abstract string Name { get; }

    public sealed override string ToString() => Name;
}

record SealedSeventh(string Quality) : SealedTemplate
{
    public override string Name => Quality;
}
