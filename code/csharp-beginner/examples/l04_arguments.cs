int fret = 5;
AddOctave(fret);
Console.WriteLine($"After AddOctave: {fret}");       // unchanged: the method got a copy

int[] frets = [0, 2, 2, 1, 0, 0];                    // an E major chord
AddOctaveToAll(frets);
Console.WriteLine($"After AddOctaveToAll: {string.Join(" ", frets)}");  // changed: the method got the same array

void AddOctave(int value)
{
    value += 12;
    Console.WriteLine($"Inside AddOctave: {value}");
}

void AddOctaveToAll(int[] values)
{
    for (int i = 0; i < values.Length; i++)
    {
        values[i] += 12;
    }
}
