// A test calls the library from outside: it sees only what the library makes public
Console.WriteLine(Guitar.Chromatic.Length);

static class Guitar
{
    static readonly string[] Chromatic = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
}
