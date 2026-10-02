namespace GaAi;

using GaMcpServer.Tools;

// Lesson 19: ga_voice_leading_pair, the MCP tool that pairs real voicings of two chords. It asks the
// OPTIC-K index for 15 voicings of each chord, weighs the 225 pairs with a distance in semitones,
// and returns the five smallest. The program builds the tool from GaMcpServer's source, points it
// at the course's index, and asks it VoiceLeadingSkill's ten example prompts.
public static class Lesson19
{
    public static void Run()
    {
        Lesson4.EnsureIndex();
        VoicingSearchTool.IndexPath = Lesson3.IndexPath;
        var corpus = Lesson16.Corpus();
        VoiceLeadingPairProbe.CandidatesTable(corpus, "at the pin");
        VoiceLeadingPairProbe.PairsTable(corpus, "at the pin");
        VoiceLeadingPairProbe.MoreCandidates("at the pin");
        VoiceLeadingPairProbe.DistanceCheck("at the pin");
    }
}
