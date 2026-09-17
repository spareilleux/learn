// expect: CS0453
public static class Options
{
    public static T? Find<T>(T[] items) where T : struct => items.Length > 0 ? items[0] : null;

    public static int? First(int?[] items) => Find(items);
}
