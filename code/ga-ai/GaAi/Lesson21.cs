namespace GaAi;

// Lesson 21: ga_search_voicings, the MCP tool that reads a chord, a mode and tags out of a query and
// returns the nearest voicings of the OPTIC-K index, and ga_voicing_vocabulary, which lists what it
// reads. The program builds both from GaMcpServer's source, points the search at the course's index,
// and asks it the vocabulary's own entries and examples, then GA's example queries.
public static class Lesson21
{
    public static void Run()
    {
        Lesson4.EnsureIndex();
        SearchIndex.Use(Lesson3.IndexPath);
        var corpus = Lesson16.Corpus();
        SearchVoicingsProbe.VocabularyTable("at the pin");
        SearchVoicingsProbe.ExamplesTable("at the pin");
        SearchVoicingsProbe.ModesTable(corpus, "at the pin");
        SearchVoicingsProbe.TagsTable("at the pin");
        SearchVoicingsProbe.RootlessTable(corpus, "at the pin");
        SearchVoicingsProbe.WordsTable("at the pin");
        SearchVoicingsProbe.ScoresTable("at the pin");
        SearchVoicingsProbe.DraftTable("at the pin");
    }
}
