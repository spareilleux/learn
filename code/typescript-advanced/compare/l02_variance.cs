// compare/l02_variance.cs
// C# declares variance on interfaces, and checks it against every member
List<Guitar> guitars = [new("guitar", 6)];
IReadOnlyList<Instrument> instruments = guitars; // IReadOnlyList<out T>: covariant, and read-only
IReadOnlySlot<Instrument> slot = new Slot<Guitar>(guitars[0]);
Console.WriteLine($"{instruments[0].Name}, {slot.Value.Name}");

// Inference uses the arguments only: a type parameter that appears only in the return type must be written
List<string> chords = EmptyList<string>();
Console.WriteLine(chords.Count);

static List<T> EmptyList<T>() => [];

record Instrument(string Name);
record Guitar(string Name, int Strings) : Instrument(Name);

interface IReadOnlySlot<out T>
{
    T Value { get; }
}

class Slot<T>(T value) : IReadOnlySlot<T>
{
    public T Value { get; set; } = value;
}
