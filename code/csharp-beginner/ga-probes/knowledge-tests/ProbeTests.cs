// The probe's own test, in the namespace of GA's MusicalKnowledgeServiceTests: it prints what GA's [SetUpFixture]
// TestEnvironment would have changed if it had run before these tests (GA_TEST_MODE and the current directory),
// and how many items each knowledge service holds.
namespace GA.Business.Core.Tests.Configuration;

using GA.Domain.Services;

[TestFixture]
public class ProbeTests
{
    [Test]
    public void Probe_PrintsTheTestEnvironment()
    {
        string cwd = Directory.GetCurrentDirectory();
        string testDirectory = TestContext.CurrentContext.TestDirectory;
        Console.WriteLine($"GA_TEST_MODE: {Environment.GetEnvironmentVariable("GA_TEST_MODE") ?? "(not set)"}");
        Console.WriteLine($"Current directory is the test's bin folder: {Path.GetFullPath(cwd) == Path.GetFullPath(testDirectory)}");
        Console.WriteLine($"Iconic chords: {IconicChordsService.GetAllChords().Count()}");
        Console.WriteLine($"Chord progressions: {ChordProgressionsService.GetAllProgressions().Count()}");
        Console.WriteLine($"Guitar techniques: {GuitarTechniquesService.GetAllTechniques().Count()}");
        Console.WriteLine($"Specialized tunings: {SpecializedTuningsService.GetAllTunings().Count()}");
    }
}
