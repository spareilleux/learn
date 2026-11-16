namespace Fretboard.Tests;

// xUnit creates a new object of the test class for each test, so a field starts from 0 in every test
public class InstanceTests
{
    int _count;

    [Fact]
    public void FirstTest()
    {
        _count++;
        Assert.Equal(1, _count);
    }

    [Fact]
    public void SecondTest()
    {
        _count++;
        Assert.Equal(1, _count);
    }
}
