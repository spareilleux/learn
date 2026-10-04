using Fretboard;

namespace Fretboard.Tests;

// The solutions of lesson 11's exercises
public class ExerciseTests
{
    // Exercise 1: transpose down
    [Fact]
    public void Transpose_MovesEachNoteDown()
    {
        List<string> result = Guitar.Transpose(["A", "C", "E"], -3);

        Assert.Equal(["F#", "A", "C#"], result);
    }

    // Exercise 2: the edges of ParseFret
    [Theory]
    [InlineData("0", 0)]
    [InlineData("24", 24)]
    public void ParseFret_AcceptsTheFirstAndLastFret(string text, int expected)
    {
        Assert.Equal(expected, Guitar.ParseFret(text));
    }

    [Theory]
    [InlineData("-1")]
    [InlineData("25")]
    public void ParseFret_RefusesTheFretsJustOutside(string text)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Guitar.ParseFret(text));
    }

    [Fact]
    public void ParseFret_RefusesAWord()
    {
        Assert.Throws<FormatException>(() => Guitar.ParseFret("seven"));
    }

    // Exercise 3: the two pitfalls whose expected value was wrong, fixed
    [Fact]
    public void Equal_WithTheExpectedValueFirst()
    {
        Assert.Equal(164.81, Guitar.FretFrequency(110.0, 7));
    }

    [Theory]
    [InlineData("C", 2, "D")]
    [InlineData("B", 1, "C")]
    [InlineData("E", 1, "F")]
    public void Transpose_OneNote(string note, int semitones, string expected)
    {
        Assert.Equal([expected], Guitar.Transpose([note], semitones));
    }

    // Exercise 4: a test that reads data/ga-projects.csv, copied next to the tests by Fretboard.Tests.csproj
    [Fact]
    public void GaProjects_HoldSixHundredThirtyTwoSourceFiles()
    {
        string path = Path.Combine(AppContext.BaseDirectory, "data", "ga-projects.csv");

        List<Project> projects = File.ReadLines(path).Skip(1).Select(Project.Parse).ToList();

        Assert.Equal(12, projects.Count);
        Assert.Equal(632, projects.Sum(p => p.SourceFiles));
    }
}
