// An array: a fixed number of values of the same type
string[] strings = ["E2", "A2", "D3", "G3", "B3", "E4"];

Console.WriteLine(strings.Length);
Console.WriteLine(strings[0]);          // indexes start at 0
Console.WriteLine(strings[5]);          // the last index is Length - 1
Console.WriteLine(strings[^1]);         // ^1: the first from the end
Console.WriteLine(string.Join(", ", strings[1..3]));   // a range: indexes 1 and 2

strings[0] = "D2";                      // drop D tuning: the values can change
Console.WriteLine(string.Join(" ", strings));

// new int[4]: four ints, all 0 to start with
int[] minutes = new int[4];
minutes[1] = 30;
Console.WriteLine(string.Join(" ", minutes));

// Loop over the values
int[] practice = [30, 45, 0, 60, 20];
int total = 0;
foreach (int m in practice)
{
    total += m;
}
Console.WriteLine($"Total: {total} minutes over {practice.Length} days");

// Sort changes the array itself
Array.Sort(practice);
Console.WriteLine(string.Join(" ", practice));
