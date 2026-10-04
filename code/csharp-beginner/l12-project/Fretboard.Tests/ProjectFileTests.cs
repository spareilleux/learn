using Fretboard;

namespace Fretboard.Tests;

public class ProjectFileTests
{
    [Fact]
    public void Read_KeepsACommaInsideQuotes()
    {
        string text = """
            Name,Language,CsFiles,FsFiles
            "Demos, music theory",C#,3,0
            """;

        List<Project> projects = ProjectFile.Read(new StringReader(text));

        Assert.Equal([new Project("Demos, music theory", "C#", 3, 0)], projects);
    }

    // An async test: xUnit waits for the Task before it reads the result
    [Fact]
    public async Task ReadAsync_GivesTheSameProjectsAsRead()
    {
        string path = Path.Combine(AppContext.BaseDirectory, "data", "ga-projects.csv");

        List<Project> projects = await ProjectFile.ReadAsync(path);

        Assert.Equal(ProjectFile.Read(path), projects);
        Assert.Equal(12, projects.Count);
        Assert.Equal(632, projects.Sum(p => p.SourceFiles));
    }
}
