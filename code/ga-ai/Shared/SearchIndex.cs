namespace GaAi;

// GaMcpServer's VoicingSearchTool finds its index through GA_OPTICK_INDEX_PATH, read once, on the
// first search (VoicingSearchTool.cs lines 64-83); its telemetry log is switched off the same way,
// so the course writes no file under GA's state/
public static class SearchIndex
{
    public static void Use(string path)
    {
        Environment.SetEnvironmentVariable("GA_OPTICK_INDEX_PATH", path);
        Environment.SetEnvironmentVariable("GA_VOICING_NO_TELEMETRY", "1");
    }
}
