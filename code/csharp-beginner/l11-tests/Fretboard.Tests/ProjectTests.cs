using Fretboard;

namespace Fretboard.Tests;

public class ProjectTests
{
    [Fact]
    public void Parse_ReadsTheFourFields()
    {
        Project project = Project.Parse("GA.Core,C#,67,0");

        // Records compare by value: one Assert checks the four fields
        Assert.Equal(new Project("GA.Core", "C#", 67, 0), project);
    }

    [Fact]
    public void Parse_RefusesALineWithoutNumbers()
    {
        Assert.Throws<FormatException>(() => Project.Parse("GA.Core,C#,many,0"));
    }
}
