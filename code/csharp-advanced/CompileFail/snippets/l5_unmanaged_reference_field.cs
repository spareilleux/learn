// expect: CS8377
public struct Voicing
{
    public int Root;
    public string Name;
}

public static class Buffers
{
    public static unsafe int SizeOf<T>() where T : unmanaged => sizeof(T);

    public static int VoicingSize() => SizeOf<Voicing>();
}
