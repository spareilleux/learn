// expect: CS1604
public struct Counter
{
    public int Value;

    public readonly void Increment() => Value++;
}
