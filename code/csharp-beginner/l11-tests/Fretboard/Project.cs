namespace Fretboard;

// Lesson 10: one line of data/ga-projects.csv, Name,Language,CsFiles,FsFiles
public record Project(string Name, string Language, int CsFiles, int FsFiles)
{
    public static Project Parse(string line)
    {
        string[] fields = line.Split(',');
        return new Project(fields[0], fields[1], int.Parse(fields[2]), int.Parse(fields[3]));
    }

    public int SourceFiles => CsFiles + FsFiles;
}
