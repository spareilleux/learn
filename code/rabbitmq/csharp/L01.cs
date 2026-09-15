using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using static Learn.Rabbit.Broker;

namespace Learn.Rabbit;

// Lesson 1: a producer and a consumer that never meet. The broker keeps the messages in between.
static class L01
{
    public static async Task Send()
    {
        await using IConnection connection = await ConnectAsync("l01-send");
        Console.WriteLine($"connected to {Text(connection.ServerProperties?["product"])} {Text(connection.ServerProperties?["version"])}");

        // A channel is a lightweight session multiplexed on the connection; almost every AMQP operation happens on one.
        await using IChannel channel = await connection.CreateChannelAsync();

        // Declaring is idempotent: it creates the queue, or checks that the existing one has the same settings.
        QueueDeclareOk queue = await channel.QueueDeclareAsync("hello", durable: true, exclusive: false, autoDelete: false);
        Console.WriteLine($"queue {queue.QueueName}: {queue.MessageCount} message(s) waiting");

        for (var i = 1; i <= 3; i++)
        {
            // The default exchange "" delivers to the queue named by the routing key.
            await channel.BasicPublishAsync(exchange: "", routingKey: "hello", body: Bytes($"Hello {i}"));
            Console.WriteLine($"sent Hello {i}");
        }
    }

    public static async Task Receive()
    {
        await using IConnection connection = await ConnectAsync("l01-receive");
        await using IChannel channel = await connection.CreateChannelAsync();
        QueueDeclareOk queue = await channel.QueueDeclareAsync("hello", durable: true, exclusive: false, autoDelete: false);
        Console.WriteLine($"queue {queue.QueueName}: {queue.MessageCount} message(s) waiting");

        // The example stops once it has read what was waiting; a real consumer runs until the application stops.
        var remaining = (int)queue.MessageCount;
        var done = new TaskCompletionSource();
        if (remaining == 0)
        {
            done.SetResult();
        }

        var consumer = new AsyncEventingBasicConsumer(channel);
        consumer.ReceivedAsync += (_, delivery) =>
        {
            Console.WriteLine($"received {Text(delivery.Body)}");
            if (--remaining == 0)
            {
                done.TrySetResult();
            }
            return Task.CompletedTask;
        };

        // autoAck: true means the broker forgets a message as soon as it sends it. Lesson 4 shows what that costs.
        await channel.BasicConsumeAsync("hello", autoAck: true, consumer);
        await WaitAsync(done.Task, "the waiting messages");
    }
}
