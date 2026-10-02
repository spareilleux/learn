GuitarString lowE = new GuitarString(82.41);
Console.WriteLine(lowE._openHz);

sealed class GuitarString
{
    private readonly double _openHz;

    public GuitarString(double openHz) => _openHz = openHz;
}
