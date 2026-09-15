// compare_fail/l02_variant_setter.cs
// A property with a setter consumes T: out T is refused, where TypeScript measures the property covariant
Console.WriteLine("unreachable");

interface ISlot<out T>
{
    T Value { get; set; }
}
