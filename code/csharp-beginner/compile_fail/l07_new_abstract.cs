Instrument kazoo = new Instrument("Kazoo");
Console.WriteLine(kazoo.Name);

abstract class Instrument
{
    public string Name { get; }

    protected Instrument(string name) => Name = name;

    public abstract string Play(string note);
}
