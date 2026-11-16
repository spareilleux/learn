using Fretboard;

namespace Fretboard.Tests;

// Two tests of lesson 11, so that the solution has tests of each part of the library
public class GuitarTests
{
    [Fact]
    public void FretFrequency_TwelfthFret_DoublesTheFrequency()
    {
        Assert.Equal(220.0, Guitar.FretFrequency(110.0, 12));
    }

    [Theory]
    [InlineData("C", 2, "D")]
    [InlineData("B", 1, "C")]
    [InlineData("E", 1, "F")]
    public void Transpose_OneNote(string note, int semitones, string expected)
    {
        Assert.Equal([expected], Guitar.Transpose([note], semitones));
    }
}
