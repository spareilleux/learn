Console.WriteLine(FretFrequency(110.0));

double FretFrequency(double openString, int fret)
{
    return openString * Math.Pow(2, fret / 12.0);
}
