// expect: CS0029
public static class Boxes
{
    public static object Box<T>(T value) where T : allows ref struct => value;
}
