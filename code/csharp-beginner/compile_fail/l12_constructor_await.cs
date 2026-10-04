var index = new VoicingIndex();

class VoicingIndex
{
    public VoicingIndex()
    {
        await Task.Delay(100);   // a constructor can't be async
    }
}
