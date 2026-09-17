namespace Snippets;

// Lesson 5: what the compiler emits for new T(), default(T), a static abstract member and a generic operator
public interface IFromValue<TSelf> where TSelf : IFromValue<TSelf>
{
    static abstract TSelf FromValue(int value);
}

public static class Generics
{
    public static T Create<T>() where T : new() => new T();

    public static T DefaultOf<T>() => default;

    public static T FromValue<T>(int value) where T : IFromValue<T> => T.FromValue(value);

    public static T Add<T>(T left, T right) where T : System.Numerics.IAdditionOperators<T, T, T> => left + right;
}
