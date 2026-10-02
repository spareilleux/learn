// Instrument is abstract: an object is a Guitar, a Piano or a Violin, never just an Instrument
Instrument[] band = [new Guitar(), new Piano(), new Violin()];

foreach (Instrument instrument in band)
{
    Console.WriteLine(instrument.Play("A4"));
}

abstract class Instrument
{
    public string Name { get; }

    protected Instrument(string name) => Name = name;

    // Each derived class must say how it plays a note
    public abstract string Play(string note);
}

sealed class Guitar : Instrument
{
    public Guitar() : base("Guitar")
    {
    }

    public override string Play(string note) => $"{Name}: pluck {note}";
}

sealed class Piano : Instrument
{
    public Piano() : base("Piano")
    {
    }

    public override string Play(string note) => $"{Name}: strike the {note} key";
}

sealed class Violin : Instrument
{
    public Violin() : base("Violin")
    {
    }

    public override string Play(string note) => $"{Name}: bow {note}";
}
