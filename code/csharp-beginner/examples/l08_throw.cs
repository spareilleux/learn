// A method that cannot do its job throws an exception instead of returning a wrong answer
string[] standard = ["E2", "A2", "D3", "G3", "B3", "E4"];

Console.WriteLine(NoteOfString(standard, 6));
Console.WriteLine(NoteOfString(standard, 1));

try
{
    Console.WriteLine(NoteOfString(standard, 7));
}
catch (ArgumentOutOfRangeException ex)
{
    Console.WriteLine(ex.Message);
}

// Strings are numbered from 1, the highest, to 6, the lowest
string NoteOfString(string[] tuning, int stringNumber)
{
    if (stringNumber < 1 || stringNumber > tuning.Length)
    {
        throw new ArgumentOutOfRangeException(nameof(stringNumber), stringNumber, $"This tuning has strings 1 to {tuning.Length}.");
    }
    return tuning[tuning.Length - stringNumber];
}
