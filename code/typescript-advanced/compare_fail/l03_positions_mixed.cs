// compare_fail/l03_positions_mixed.cs
var index = new StringIndex(1);
Console.WriteLine(OpenStringOf(index));
Console.WriteLine(OpenStringOf(2));

static string OpenStringOf(StringNumber number) => number.Value.ToString();

readonly record struct StringIndex(int Value);
readonly record struct StringNumber(int Value);
