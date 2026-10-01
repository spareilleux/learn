Instrument flute = new Flute();
Console.WriteLine(flute.Play("A4"));

abstract class Instrument
{
    public abstract string Play(string note);
}

sealed class Flute : Instrument
{
}
