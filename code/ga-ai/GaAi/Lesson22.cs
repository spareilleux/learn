namespace GaAi;

// Lesson 22: IcvNeighborsSkill, the chatbot's "similar chords" skill. It reads one chord out of a
// question and lists the pitch-class sets whose interval-class vectors are within 2 of the
// chord's, without the embedding. The program asks it GA's own phrasings, the chords it reads, and
// the neighbors it lists, then checks the parked draft's example.
public static class Lesson22
{
    public static void Run()
    {
        var skill = IcvNeighborsProbe.Skill();
        IcvNeighborsProbe.ExamplesTable(skill, "at the pin");
        IcvNeighborsProbe.SisterTable("at the pin");
        IcvNeighborsProbe.ReadingTable(skill, "at the pin");
        IcvNeighborsProbe.RowsTable(skill, "at the pin");
        IcvNeighborsProbe.DraftTable("at the pin");
    }
}
