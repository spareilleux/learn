StringInstrument uke = new Ukulele();
Console.WriteLine(uke.Describe());   // the base version runs: Ukulele's method only hides it

Ukulele sameKind = new Ukulele();
Console.WriteLine(sameKind.Describe());   // a Ukulele variable finds the hiding method

class StringInstrument
{
    public virtual string Describe() => "a string instrument";
}

sealed class Ukulele : StringInstrument
{
    public string Describe() => "a ukulele";   // override is missing
}
