List<FretPosition> shape = [new FretPosition(6, 3), new FretPosition(5, 5)];
shape[0].Fret = 5;

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
