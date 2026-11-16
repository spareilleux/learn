namespace GaAi;

// Lesson 23: GrothendieckDeltaSkill and IcvShortestPathSkill, the chatbot's two skills that take a
// pair of chords. The first gives the difference of their interval-class vectors, the second a
// chain of pitch-class sets from one to the other. The program asks them GA's own phrasings, the
// pairs they read, the deltas they give and the paths they find.
public static class Lesson23
{
    public static void Run()
    {
        var (delta, path) = IcvDeltaPathProbe.Skills();
        IcvDeltaPathProbe.ExamplesTable(delta, path, "at the pin");
        IcvDeltaPathProbe.ReadingTable(delta, path, "at the pin");
        IcvDeltaPathProbe.DeltaTable(delta, "at the pin");
        IcvDeltaPathProbe.PathTable(path, "at the pin");
    }
}
