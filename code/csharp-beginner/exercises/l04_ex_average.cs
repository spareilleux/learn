// Exercise 1: the average of an array, or null when the array is empty
int[] week = [30, 45, 0, 60, 20, 0, 90];
int[] nothing = [];

Console.WriteLine(Average(week));
Console.WriteLine(Average(nothing) ?? -1);
Console.WriteLine(Average(nothing) is null ? "no practice recorded" : "some practice");

double? Average(int[] values)
{
    if (values.Length == 0)
    {
        return null;
    }
    int total = 0;
    foreach (int value in values)
    {
        total += value;
    }
    return (double)total / values.Length;
}
