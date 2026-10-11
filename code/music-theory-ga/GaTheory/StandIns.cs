// Lesson 16 compiles ImprovisationSkill.cs and OutsideNotesSkill.cs of GA.Business.ML as they are. They name four types
// that come from code the course does not build: the logger and the LLM query extractor need packages, and the response
// record sits in a file that needs them. These are the course's stand-ins for those four types, nothing more.

namespace GA.Business.ML.Agents
{
    // For Microsoft.Extensions.Logging's ILogger<T>, reduced to the one call the two skills make; it writes nothing
    public interface ILogger<T>
    {
        void LogDebug(string? message, params object?[] args) { }
    }

    public sealed class SilentLogger<T> : ILogger<T>;

    // For GA's AgentResponse (GuitarAlchemistAgentBase.cs), with its six properties and their types
    public record AgentResponse
    {
        public required string Result { get; init; }
        public required float Confidence { get; init; }
        public IReadOnlyList<string> Evidence { get; init; } = [];
        public IReadOnlyList<string> Assumptions { get; init; } = [];
        public required string AgentId { get; init; }
        public object? Data { get; init; }
    }
}

namespace GA.Business.ML.Search
{
    // For GA's IMusicalQueryExtractor (MusicalQueryExtractor.cs), whose implementation asks an LLM; the course never calls
    // it, since a request that names two chords or more is answered before ImprovisationSkill reaches its extractor
    public interface IMusicalQueryExtractor
    {
        Task<StructuredQuery> ExtractAsync(string query, CancellationToken cancellationToken = default);
    }

    public sealed class NoExtractor : IMusicalQueryExtractor
    {
        public Task<StructuredQuery> ExtractAsync(string query, CancellationToken cancellationToken = default) =>
            throw new NotSupportedException("the course does not call the LLM extractor");
    }

    // For GA's StructuredQuery (MusicalQueryEncoder.cs), with its five positional fields
    public sealed record StructuredQuery(
        string? ChordSymbol,
        int? RootPitchClass,
        int[]? PitchClasses,
        string? ModeName,
        IReadOnlyList<string>? Tags);
}
