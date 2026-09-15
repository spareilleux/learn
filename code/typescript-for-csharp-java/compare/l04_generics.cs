// compare/l04_generics.cs
using System.Collections.Generic;

Console.WriteLine(Create<Tuner>().Reference);
Console.WriteLine(Describe<int>());
Console.WriteLine(new List<int>().GetType() == new List<string>().GetType());
Console.WriteLine(IsOf<DateTime>(DateTime.UnixEpoch));

// C# generics are reified: T exists at run time
static T Create<T>() where T : new() => new T();
static string Describe<T>() => $"{typeof(T).Name}, default {default(T)}";
static bool IsOf<T>(object value) => value is T;

class Tuner
{
    public int Reference { get; } = 440;
}
