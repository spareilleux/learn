int fret;
try
{
    fret = int.Parse("twelve");
}
catch (FormatException)
{
    Console.WriteLine("not a number");
}
Console.WriteLine(fret);
