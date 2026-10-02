StringInstrument uke = new Ukulele();
Console.WriteLine(uke.Describe());

class StringInstrument
{
    public string Describe() => "a string instrument";
}

sealed class Ukulele : StringInstrument
{
    public override string Describe() => "a ukulele";
}
