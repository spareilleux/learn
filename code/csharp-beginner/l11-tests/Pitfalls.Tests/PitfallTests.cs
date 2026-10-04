using Fretboard;

namespace Pitfalls.Tests;

// Every test in this project fails on purpose: lesson 11 shows and explains each message
public class PitfallTests
{
    // 0.1 + 0.2 is not exactly 0.3 in a double
    [Fact]
    public void Doubles_ComparedBitForBit()
    {
        Assert.Equal(0.3, 0.1 + 0.2);
    }

    // ParseFret throws ArgumentOutOfRangeException, a type derived from ArgumentException
    [Fact]
    public void Throws_WithTheBaseType()
    {
        Assert.Throws<ArgumentException>(() => Guitar.ParseFret("25"));
    }

    // The arguments are swapped: the message calls the method's result "Expected"
    [Fact]
    public void Equal_WithTheArgumentsSwapped()
    {
        Assert.Equal(Guitar.FretFrequency(110.0, 7), 164.8);
    }

    // One row of the theory is wrong: E moved up one semitone is F
    [Theory]
    [InlineData("C", 2, "D")]
    [InlineData("B", 1, "C")]
    [InlineData("E", 1, "F#")]
    public void Transpose_OneNote(string note, int semitones, string expected)
    {
        Assert.Equal([expected], Guitar.Transpose([note], semitones));
    }
}
