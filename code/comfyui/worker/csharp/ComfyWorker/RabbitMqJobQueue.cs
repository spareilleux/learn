using System.Text;
using System.Text.Json.Nodes;
using System.Threading.Channels;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace Learn.Comfy.Worker;

/// <summary>
/// The same <see cref="IJobQueue"/> over RabbitMQ: a durable quorum queue of jobs, manual acknowledgements, a prefetch
/// equal to the number of GPUs, and a second queue for dead letters. The message is the job as JSON:
/// {"id": "…", "workflow": {…}}, with the job id as message id.
/// </summary>
public sealed class RabbitMqJobQueue : IJobQueue, IAsyncDisposable
{
    readonly IConnection connection;
    readonly IChannel channel;
    readonly string deadLetterQueue;
    readonly Channel<IDelivery> deliveries = Channel.CreateUnbounded<IDelivery>();

    RabbitMqJobQueue(IConnection connection, IChannel channel, string deadLetterQueue)
    {
        this.connection = connection;
        this.channel = channel;
        this.deadLetterQueue = deadLetterQueue;
    }

    public static async Task<RabbitMqJobQueue> ConnectAsync(Uri broker, string queue, ushort prefetch, CancellationToken cancel)
    {
        var factory = new ConnectionFactory { Uri = broker, ClientProvidedName = $"comfy-worker {Environment.MachineName}" };
        var connection = await factory.CreateConnectionAsync(cancel);
        var channel = await connection.CreateChannelAsync(cancellationToken: cancel);
        var quorum = new Dictionary<string, object?> { ["x-queue-type"] = "quorum" };
        await channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false, arguments: quorum, cancellationToken: cancel);
        await channel.QueueDeclareAsync($"{queue}.dead", durable: true, exclusive: false, autoDelete: false, arguments: quorum, cancellationToken: cancel);
        // Prefetch = GPUs: the broker never hands this worker more jobs than it can run, the rest stay for other workers.
        await channel.BasicQosAsync(0, prefetch, global: false, cancel);

        var result = new RabbitMqJobQueue(connection, channel, $"{queue}.dead");
        var consumer = new AsyncEventingBasicConsumer(channel);
        consumer.ReceivedAsync += async (_, message) =>
        {
            var json = JsonNode.Parse(Encoding.UTF8.GetString(message.Body.Span))!;
            var job = Job.Create(json["id"]!.GetValue<string>(), json["workflow"]!.AsObject());
            await result.deliveries.Writer.WriteAsync(new Delivery(result, job, message.DeliveryTag, message.Body.ToArray()));
        };
        await channel.BasicConsumeAsync(queue, autoAck: false, consumer, cancel);
        return result;
    }

    public static async Task PublishAsync(Uri broker, string queue, Job job)
    {
        var factory = new ConnectionFactory { Uri = broker };
        await using var connection = await factory.CreateConnectionAsync();
        await using var channel = await connection.CreateChannelAsync(new CreateChannelOptions(publisherConfirmationsEnabled: true, publisherConfirmationTrackingEnabled: true));
        await channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false, arguments: new Dictionary<string, object?> { ["x-queue-type"] = "quorum" });
        var body = new JsonObject { ["id"] = job.Id, ["workflow"] = job.Workflow.DeepClone() };
        var properties = new BasicProperties { MessageId = job.Id, Persistent = true, ContentType = "application/json" };
        await channel.BasicPublishAsync("", queue, mandatory: true, properties, Encoding.UTF8.GetBytes(body.ToJsonString()));
    }

    public async ValueTask<IDelivery?> ReceiveAsync(CancellationToken cancel) => await deliveries.Reader.ReadAsync(cancel);

    public async ValueTask DisposeAsync()
    {
        await channel.CloseAsync();
        await connection.CloseAsync();
    }

    sealed class Delivery(RabbitMqJobQueue queue, Job job, ulong tag, byte[] body) : IDelivery
    {
        public Job Job => job;

        public ValueTask AckAsync() => queue.channel.BasicAckAsync(tag, multiple: false);

        public ValueTask RequeueAsync() => queue.channel.BasicNackAsync(tag, multiple: false, requeue: true);

        // Published to the dead-letter queue with the reason in a header, then acked. A crash between the two
        // leaves the job in both queues: a duplicate dead letter, never a lost one.
        public async ValueTask DeadLetterAsync(string reason)
        {
            var properties = new BasicProperties
            {
                MessageId = job.Id,
                Persistent = true,
                ContentType = "application/json",
                Headers = new Dictionary<string, object?> { ["x-worker-reason"] = reason },
            };
            await queue.channel.BasicPublishAsync("", queue.deadLetterQueue, mandatory: false, properties, body);
            await queue.channel.BasicAckAsync(tag, multiple: false);
        }
    }
}
