GuitarString lowE = new GuitarString(82.41);
lowE.OpenHz = 110.0;

sealed class GuitarString
{
    public double OpenHz { get; }

    public GuitarString(double openHz) => OpenHz = openHz;
}
