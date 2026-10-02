// The course's stand-in for GaMcpServer's VoicingSearchTool. CompositionTools reads the OPTIC-K
// search strategy from that class's private static field Strategy, by reflection
// (CompositionTools.cs lines 300-310); here the strategy reads the course's own index
namespace GaMcpServer.Tools;

using GA.Business.ML.Search;

public static class VoicingSearchTool
{
    public static string IndexPath { get; set; } = "";

    private static readonly Lazy<OptickSearchStrategy> Strategy = new(() => new OptickSearchStrategy(IndexPath));
}
