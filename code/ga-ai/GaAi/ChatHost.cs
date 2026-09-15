namespace GaAi;

using System.Collections.Concurrent;
using GA.Business.ML.Agents.Memory;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

// GaChatbot.Api, the chatbot's canonical host, started in this process by WebApplicationFactory.
// No Ollama, no API key: the Ollama URL points to a closed local port, so every model call fails
// fast, as on a CI runner. The voicing index is the small one lesson 3 writes. The chat memory
// goes to fresh files next to the program instead of ~/.ga, so a run never reads or changes it.
public sealed class ChatHost : WebApplicationFactory<Program>
{
    // Port 9 (discard) is closed on the CI runners and on the author's machine
    public const string DeadOllama = "http://127.0.0.1:9";

    // Warnings and errors the host logs, kept to explain failed requests
    public ConcurrentQueue<(LogLevel Level, string Category, string Message, Exception? Exception)> Logs { get; } = new();

    // IntentEmbeddingWarmupService embeds the intents' examples in the background when the host
    // starts, and logs once when it is done. Its warnings would otherwise land in whichever request
    // runs at that moment, which differs between operating systems.
    const string WarmupCategory = "GA.Business.Core.Orchestration.Services.IntentEmbeddingWarmupService";
    readonly TaskCompletionSource _warmedUp = new(TaskCreationOptions.RunContinuationsAsynchronously);

    public void WaitForWarmup()
    {
        if (!_warmedUp.Task.Wait(TimeSpan.FromMinutes(2)))
            throw new TimeoutException("IntentEmbeddingWarmupService did not finish");
        while (Logs.TryDequeue(out _)) { }
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseSetting("Chatbot:Mode", "full");
        builder.UseSetting("Chatbot:PathBase", "");
        builder.UseSetting("Ollama:BaseUrl", DeadOllama);
        builder.UseSetting("Ollama:Endpoint", DeadOllama);
        builder.UseSetting("VoicingSearch:OpticIndexPath", Lesson3.IndexPath);
        builder.UseSetting("IX:External:Enabled", "false");
        var memoryDir = Path.Combine(AppContext.BaseDirectory, "out", "memory");
        if (Directory.Exists(memoryDir)) Directory.Delete(memoryDir, recursive: true);
        Directory.CreateDirectory(memoryDir);
        builder.ConfigureTestServices(services =>
        {
            services.AddSingleton(new MemoryStore(Path.Combine(memoryDir, "memory.json")));
            services.AddSingleton(new ChatTranscriptStore(Path.Combine(memoryDir, "transcripts.json")));
        });
        builder.ConfigureLogging(logging =>
        {
            logging.ClearProviders();
            logging.SetMinimumLevel(LogLevel.Warning);
            logging.AddFilter(WarmupCategory, LogLevel.Information);
            logging.AddProvider(new QueueLoggerProvider(Logs, _warmedUp));
        });
    }

    sealed class QueueLoggerProvider(ConcurrentQueue<(LogLevel, string, string, Exception?)> queue, TaskCompletionSource warmedUp) : ILoggerProvider
    {
        public ILogger CreateLogger(string categoryName) => new QueueLogger(categoryName, queue, warmedUp);
        public void Dispose() { }
    }

    sealed class QueueLogger(string category, ConcurrentQueue<(LogLevel, string, string, Exception?)> queue, TaskCompletionSource warmedUp) : ILogger
    {
        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;
        public bool IsEnabled(LogLevel logLevel) => logLevel >= LogLevel.Warning || category == WarmupCategory;

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception,
            Func<TState, Exception?, string> formatter)
        {
            // "cache warmed in …ms" or "warmup failed": either way the warm-up is over
            if (category == WarmupCategory) warmedUp.TrySetResult();
            else if (logLevel >= LogLevel.Warning) queue.Enqueue((logLevel, category, formatter(state, exception), exception));
        }
    }
}
