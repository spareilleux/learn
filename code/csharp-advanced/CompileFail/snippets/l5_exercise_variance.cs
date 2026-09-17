// expect: CS0266
public static class Quiz
{
    public static IReadOnlyList<object> A = new List<string>();
    public static IList<object> B = new List<string>();
    public static IEnumerable<object> C = new List<int>();
    public static Func<string, object> D = (Func<object, string>)(o => o.ToString()!);
    public static Action<object> E = (Action<string>)(s => { });
}
