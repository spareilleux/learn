StringInstrument a = new Ukulele();
Ukulele b = new Ukulele();
StringInstrument c = new StringInstrument();

Console.WriteLine(a.Describe());
Console.WriteLine(b.Describe());
Console.WriteLine(c.Describe());
Console.WriteLine(a.Family());

class StringInstrument
{
    public virtual string Describe() => "strings";

    public string Family() => "chordophone";
}

sealed class Ukulele : StringInstrument
{
    public override string Describe() => "ukulele, " + base.Describe();
}
