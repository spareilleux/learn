// Seven nullable mistakes, for experiment 1 of README.md: copied into GA.Domain.Core, it shows whether
// a build of GA reports nullable warnings. With GA's NoWarn lists: none. Without them: these seven.

namespace GA.Domain.Core.ZzCanary;

public class ZzNullableCanary
{
    public string Name;                                   // CS8618 expected

    public static int Probe(string? maybe)
    {
        string s = null;                                  // CS8600 expected
        string t = maybe;                                 // CS8600 expected
        Take(null);                                       // CS8625 expected
        return maybe.Length + s.Length + t.Length;        // CS8602 expected
    }

    private static void Take(string value) { }
}
