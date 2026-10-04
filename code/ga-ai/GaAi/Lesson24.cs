namespace GaAi;

// Lesson 24: SetTheoryEquivalenceSkill and GrothendieckParseSkill, the chatbot's two skills that read
// set theory and category theory in a question. The program asks them GA's own phrasings, the
// relations and sets the first reads, every pair of three-note and four-note sets, and the
// expressions and chords the second sends to GA's F# parser.
public static class Lesson24
{
    public static void Run()
    {
        var (sets, parse) = SetEquivalenceParseProbe.Skills();
        SetEquivalenceParseProbe.ExamplesTable(sets, parse, "at the pin");
        SetEquivalenceParseProbe.RelationTable(sets, "at the pin");
        SetEquivalenceParseProbe.AllPairsTable(sets, "at the pin");
        SetEquivalenceParseProbe.NotationTable(sets, "at the pin");
        SetEquivalenceParseProbe.PrimeFormTable("at the pin");
        SetEquivalenceParseProbe.FormsTable(parse, "at the pin");
        SetEquivalenceParseProbe.ChordsTable(parse, "at the pin");
    }
}
