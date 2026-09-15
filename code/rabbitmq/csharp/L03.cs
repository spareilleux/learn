using System.Text.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using static Learn.Rabbit.Broker;

namespace Learn.Rabbit;

public record Order(string Id, string Sku, int Quantity);

// Lesson 3: a producer and a consumer that agree on a topology and a message format, not on a language.
// The Java client and the Spring AMQP application in ../java read and write the same messages.
static class L03
{
    static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    // Every client declares the same topology with the same settings, so it doesn't matter which one starts first.
    public static async Task DeclareAsync(IChannel channel)
    {
        await channel.ExchangeDeclareAsync("orders.topic", ExchangeType.Topic, durable: true);
        await channel.QueueDeclareAsync("orders.billing", durable: true, exclusive: false, autoDelete: false);
        await channel.QueueBindAsync("orders.billing", "orders.topic", "order.#");
    }

    public static async Task Publish()
    {
        await using IConnection connection = await ConnectAsync("l03-csharp-publisher");
        await using IChannel channel = await connection.CreateChannelAsync();
        await DeclareAsync(channel);

        Order[] orders = [new("A-1", "GUITAR-STRINGS", 2), new("A-2", "CAPO", 1), new("A-3", "PICKS", 12)];
        foreach (var order in orders)
        {
            // BasicProperties is the envelope: metadata the broker and the consumer can read without parsing the body.
            var properties = new BasicProperties
            {
                ContentType = "application/json",
                MessageId = order.Id,
                Type = "order.created",
                AppId = "csharp",
                DeliveryMode = DeliveryModes.Persistent,
                Headers = new Dictionary<string, object?> { ["region"] = "eu" },
            };
            byte[] body = JsonSerializer.SerializeToUtf8Bytes(order, Json);
            await channel.BasicPublishAsync("orders.topic", "order.created.eu", mandatory: false, properties, body);
            Console.WriteLine($"published {order.Id} {Text(body.AsMemory())}");
        }
    }

    public static async Task Consume()
    {
        await using IConnection connection = await ConnectAsync("l03-csharp-consumer");
        await using IChannel channel = await connection.CreateChannelAsync();
        await DeclareAsync(channel);
        // At most 10 unacknowledged messages on this channel at a time (lesson 4).
        await channel.BasicQosAsync(prefetchSize: 0, prefetchCount: 10, global: false);

        var remaining = (int)await channel.MessageCountAsync("orders.billing");
        var done = new TaskCompletionSource();
        if (remaining == 0)
        {
            done.SetResult();
        }

        var consumer = new AsyncEventingBasicConsumer(channel);
        consumer.ReceivedAsync += async (_, delivery) =>
        {
            // The body is only valid during the callback: the client reuses its buffer. Deserialize or copy it here.
            IReadOnlyBasicProperties p = delivery.BasicProperties;
            var order = JsonSerializer.Deserialize<Order>(delivery.Body.Span, Json);
            var headers = p.Headers is null ? "" : string.Join(", ", p.Headers.OrderBy(h => h.Key, StringComparer.Ordinal).Select(h => $"{h.Key}={Text(h.Value)}"));
            Console.WriteLine($"#{delivery.DeliveryTag} {delivery.RoutingKey} content-type={p.ContentType} message-id={p.MessageId} type={p.Type} app-id={p.AppId} headers=[{headers}]");
            Console.WriteLine($"   {order}");

            await channel.BasicAckAsync(delivery.DeliveryTag, multiple: false);
            if (--remaining == 0)
            {
                done.TrySetResult();
            }
        };

        await channel.BasicConsumeAsync("orders.billing", autoAck: false, consumer);
        await WaitAsync(done.Task, "the waiting orders");
    }
}
