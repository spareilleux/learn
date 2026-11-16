namespace Fretboard;

// Lesson 10: one line of data/ga-projects.csv, Name,Language,CsFiles,FsFiles
public record Project(string Name, string Language, int CsFiles, int FsFiles)
{
    public int SourceFiles => CsFiles + FsFiles;
}
