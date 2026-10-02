PracticeSession scales = new PracticeSession("Scales");
scales.AddMinutes(20);
scales.AddMinutes(15);

PracticeSession chords = new PracticeSession("Chords");
chords.AddMinutes(10);

Console.WriteLine(scales.Summary());
Console.WriteLine(chords.Summary());
Console.WriteLine(scales.Summary());

sealed class PracticeSession
{
    private int _minutes;

    public string Topic { get; }

    public PracticeSession(string topic)
    {
        Topic = topic;
    }

    public void AddMinutes(int minutes)
    {
        _minutes += minutes;
    }

    public string Summary() => $"{Topic}: {_minutes} min";
}
