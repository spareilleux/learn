using System.Text;
using RabbitMQ.Client;

namespace Learn.Rabbit;

// What every example needs: a connection to the course broker, and text in and out of message bodies.
static class Broker
{
    public static readonly string Host = Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";

    // One connection per application, opened once and kept: it is a TCP connection with a handshake.
    // The name shows up in the management UI and in rabbitmqctl list_connections.
    public static Task<IConnection> ConnectAsync(string name) =>
        new ConnectionFactory { HostName = Host, ClientProvidedName = name }.CreateConnectionAsync();

    public static byte[] Bytes(string text) => Encoding.UTF8.GetBytes(text);

    public static string Text(ReadOnlyMemory<byte> body) => Encoding.UTF8.GetString(body.Span);

    // Server properties are AMQP tables: strings arrive as byte arrays.
    public static string Text(object? value) => value is byte[] bytes ? Encoding.UTF8.GetString(bytes) : $"{value}";

    // Starts each example from a clean slate, so that its output is the same on every run.
    public static async Task DeleteAsync(IChannel channel, string[] exchanges, string[] queues)
    {
        foreach (var exchange in exchanges)
        {
            await channel.ExchangeDeleteAsync(exchange);
        }
        foreach (var queue in queues)
        {
            await channel.QueueDeleteAsync(queue, ifUnused: false, ifEmpty: false);
        }
    }

    // Empties a queue with basic.get and prints the bodies it held, in queue order.
    public static async Task PrintQueueAsync(IChannel channel, string queue)
    {
        var lines = new List<string>();
        while (await channel.BasicGetAsync(queue, autoAck: true) is { } message)
        {
            lines.Add(Text(message.Body));
        }
        Console.WriteLine($"{queue}: {(lines.Count == 0 ? "(empty)" : string.Join(" | ", lines))}");
    }

    // Waits for a condition set by a consumer callback, and fails the example instead of hanging.
    public static async Task WaitAsync(Task task, string what)
    {
        if (await Task.WhenAny(task, Task.Delay(TimeSpan.FromSeconds(10))) != task)
        {
            throw new TimeoutException($"timed out waiting for {what}");
        }
        await task;
    }
}
