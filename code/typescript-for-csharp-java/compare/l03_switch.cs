// compare/l03_switch.cs
MusicEvent[] bar = [new Chord([48, 52, 55], 2), new Note(60, 1), new Tie(1)];
foreach (var e in bar)
{
    try { Console.WriteLine(Describe(e)); }
    catch (Exception ex) { Console.WriteLine(ex.GetType().Name); }
}

// CS8509: a warning, the program builds and fails at run time on the missing case
static string Describe(MusicEvent e) => e switch
{
    Note n => $"note {n.Pitch}",
    Chord c => $"chord of {c.Pitches.Length}",
    Rest => "rest",
};

abstract record MusicEvent(int Beats);
record Note(int Pitch, int Beats) : MusicEvent(Beats);
record Chord(int[] Pitches, int Beats) : MusicEvent(Beats);
record Rest(int Beats) : MusicEvent(Beats);
record Tie(int Beats) : MusicEvent(Beats);
