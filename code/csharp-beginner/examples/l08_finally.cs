// finally runs in every case: after a return, after a catch, and before an exception leaves the method
Console.WriteLine(Tune("440"));
Console.WriteLine(Tune("A4"));

try
{
    Console.WriteLine(Tune("99999999999"));
}
catch (OverflowException)
{
    Console.WriteLine("caught by the caller: too large");
}

string Tune(string frequency)
{
    Console.WriteLine("tuner on");
    try
    {
        int hertz = int.Parse(frequency);
        return $"tuned to {hertz} Hz";
    }
    catch (FormatException)
    {
        return $"'{frequency}' is not a frequency";
    }
    finally
    {
        Console.WriteLine("tuner off");
    }
}
