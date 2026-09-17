// expect: CS8920
public interface IFromValue<TSelf> where TSelf : IFromValue<TSelf>
{
    static abstract TSelf FromValue(int value);
}

public readonly record struct PitchClass(int Value) : IFromValue<PitchClass>
{
    public static PitchClass FromValue(int value) => new(value % 12);
}

public static class Registry
{
    public static List<IFromValue<PitchClass>> Factories = [];
}
