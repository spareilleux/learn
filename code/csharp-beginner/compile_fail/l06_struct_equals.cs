FretPosition first = new FretPosition(6, 3);
Console.WriteLine(first == new FretPosition(6, 3));

struct FretPosition
{
    public int StringNumber { get; set; }
    public int Fret { get; set; }

    public FretPosition(int stringNumber, int fret)
    {
        StringNumber = stringNumber;
        Fret = fret;
    }
}
