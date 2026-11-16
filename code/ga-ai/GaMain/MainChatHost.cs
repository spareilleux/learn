namespace GaAi;

using System.Collections.Concurrent;
using GA.Business.ML.Agents.Memory;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

// GaChatbot.Api as it is on GA's main, started like GaAi's ChatHost starts the pinned one: the
// Ollama URL points to a closed local port, the Anthropic key is empty, the SKILL.md files are the
// second clone's, and the chat memory goes to fresh files next to the program
public sealed class MainChatHost : WebApplicationFactory<Program>
{
    const string DeadOllama = "http://127.0.0.1:9";
    const string WarmupCategory = "GA.Business.Core.Orchestration.Services.IntentEmbeddingWarmupService";
    readonly TaskCompletionSource _warmedUp = new(TaskCreationOptions.RunContinuationsAsynchronously);

    // Warnings and errors the host logs
    public ConcurrentQueue<(LogLevel Level, string Category, string Message, Exception? Exception)> Logs { get; } = new();

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
        builder.UseSetting("VoicingSearch:OpticIndexPath", Path.Combine(AppContext.BaseDirectory, "out", "optick-mini-main.index"));
        builder.UseSetting("IX:External:Enabled", "false");
        builder.UseSetting("Anthropic:ApiKey", "");
        Environment.SetEnvironmentVariable("SKILLMD_SKILLS_PATH",
            Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".ga-main", "skills")));
        var memoryDir = Path.Combine(AppContext.BaseDirectory, "out", "memory-main");
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
            if (category == WarmupCategory) warmedUp.TrySetResult();
            else if (logLevel >= LogLevel.Warning) queue.Enqueue((logLevel, category, formatter(state, exception), exception));
        }
    }
}
