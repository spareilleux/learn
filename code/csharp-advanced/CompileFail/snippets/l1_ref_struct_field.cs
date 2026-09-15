// expect: CS8345
public class FretBuffer
{
    private Span<int> _frets; // a Span can live only on the stack
}
