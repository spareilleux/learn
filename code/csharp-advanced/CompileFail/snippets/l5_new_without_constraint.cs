// expect: CS0304
public static class Factory
{
    public static T Create<T>() => new T();
}
