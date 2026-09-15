Console.WriteLine(Describe(3));

string Describe(int fret)
{
    if (fret == 0)
    {
        return "open string";
    }
    else if (fret > 0)
    {
        return $"fret {fret}";
    }
}
