// Exercise 2: read a note name and print the 13 notes of the chromatic scale from it, up to its octave
Console.Write("Starting note? ");
string? input = Console.ReadLine();

int start = input switch
{
    "C" => 0, "C#" => 1, "D" => 2, "D#" => 3, "E" => 4, "F" => 5,
    "F#" => 6, "G" => 7, "G#" => 8, "A" => 9, "A#" => 10, "B" => 11,
    _ => -1,
};

if (start == -1)
{
    Console.WriteLine($"Unknown note: {input}");
}
else
{
    for (int step = 0; step <= 12; step++)
    {
        string name = ((start + step) % 12) switch
        {
            0 => "C", 1 => "C#", 2 => "D", 3 => "D#", 4 => "E", 5 => "F",
            6 => "F#", 7 => "G", 8 => "G#", 9 => "A", 10 => "A#", _ => "B",
        };
        Console.Write($"{name} ");
    }
    Console.WriteLine();
}
