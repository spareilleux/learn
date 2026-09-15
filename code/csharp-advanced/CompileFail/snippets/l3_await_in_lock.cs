// expect: CS1996
public class Tuner
{
    private readonly object _gate = new();

    public async Task TuneAsync()
    {
        lock (_gate)
        {
            await Task.Delay(10); // the continuation may run on another thread
        }
    }
}
