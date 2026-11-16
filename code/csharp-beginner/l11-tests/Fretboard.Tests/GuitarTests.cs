using Fretboard;

namespace Fretboard.Tests;

public class GuitarTests
{
    // A fact: one case, with no parameter
    [Fact]
    public void FretFrequency_TwelfthFret_DoublesTheFrequency()
    {
        // Arrange: the open A string
        double openA = 110.0;

        // Act
        double result = Guitar.FretFrequency(openA, 12);

        // Assert: the expected value comes first, the actual value second
        Assert.Equal(220.0, result);
    }

    // A theory: the same test with several rows of data, each row a separate test
    [Theory]
    [InlineData(110.0, 0, 110.0)]
    [InlineData(110.0, 7, 164.81)]
    [InlineData(82.41, 5, 110.0)]
    [InlineData(110.0, 12, 220.0)]
    public void FretFrequency_RoundsToTwoDecimals(double openString, int fret, double expected)
    {
        Assert.Equal(expected, Guitar.FretFrequency(openString, fret));
    }

    [Fact]
    public void Transpose_MovesEachNoteUp()
    {
        List<string> result = Guitar.Transpose(["C", "E", "G"], 2);

        Assert.Equal(["D", "F#", "A"], result);
    }

    [Fact]
    public void Transpose_LeavesTheOriginalListUnchanged()
    {
        List<string> chord = ["C", "E", "G"];

        Guitar.Transpose(chord, 7);

        Assert.Equal(["C", "E", "G"], chord);
    }

    [Fact]
    public void ParseFret_ReadsANumber()
    {
        Assert.Equal(7, Guitar.ParseFret("7"));
    }

    // Assert.Throws passes only if the code throws that exact exception type
    [Fact]
    public void ParseFret_RefusesAFretAbove24()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Guitar.ParseFret("25"));
    }

    // Assert.ThrowsAny also accepts a type derived from it: ArgumentOutOfRangeException is an ArgumentException
    [Fact]
    public void ParseFret_RefusesANegativeFret()
    {
        Assert.ThrowsAny<ArgumentException>(() => Guitar.ParseFret("-1"));
    }

    // Two doubles are compared here to 10 decimal places, not bit for bit
    [Fact]
    public void Doubles_CompareWithAPrecision()
    {
        Assert.Equal(0.3, 0.1 + 0.2, 10);
    }
}
