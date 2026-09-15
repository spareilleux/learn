using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using RabbitMQ.Client.Exceptions;
using static Learn.Rabbit.Broker;

namespace Learn.Rabbit;

// Lesson 4: who is responsible for a message at each moment, and what happens when a consumer, a publisher or the broker stops.
static class L04
{
    static async Task<IChannel> WorkQueueAsync(IConnection connection, string queue, int tasks)
    {
        IChannel channel = await connection.CreateChannelAsync();
        await channel.QueueDeleteAsync(queue, ifUnused: false, ifEmpty: false);
        await channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false);
        for (var i = 1; i <= tasks; i++)
        {
            await channel.BasicPublishAsync("", queue, Bytes($"task {i}"));
        }
        return channel;
    }

    // A consumer that handles messages until it "crashes" on one of them. After the crash it handles nothing more,
    // like a process that died, and the caller closes its channel as the broker would see a lost connection.
    sealed class CrashingConsumer(IChannel channel, bool autoAck, string crashOn) : AsyncEventingBasicConsumer(channel)
    {
        public readonly TaskCompletionSource Crashed = new();

        public async Task StartAsync(string queue)
        {
            ReceivedAsync += async (_, delivery) =>
            {
                if (Crashed.Task.IsCompleted)
                {
                    return;
                }
                var body = Text(delivery.Body);
                if (body == crashOn)
                {
                    Console.WriteLine($"  consumer 1 crashes while handling {body}");
                    Crashed.TrySetResult();
                    return;
                }
                Console.WriteLine($"  consumer 1 handled {body}");
                if (!autoAck)
                {
                    await Channel.BasicAckAsync(delivery.DeliveryTag, multiple: false);
                }
            };
            await Channel.BasicConsumeAsync(queue, autoAck, this);
            await WaitAsync(Crashed.Task, "the crash");
            // Leaves time for the broker to push whatever the prefetch window allows, then drops the channel.
            await Task.Delay(300);
            await Channel.CloseAsync();
        }
    }

    // Reads what is left in a queue with a fresh consumer and prints each message's redelivered flag.
    static async Task DrainAsync(IConnection connection, string queue)
    {
        await using IChannel channel = await connection.CreateChannelAsync();
        var remaining = (int)await channel.MessageCountAsync(queue);
        Console.WriteLine($"  {queue} holds {remaining} message(s)");
        if (remaining == 0)
        {
            return;
        }
        var done = new TaskCompletionSource();
        var consumer = new AsyncEventingBasicConsumer(channel);
        consumer.ReceivedAsync += async (_, delivery) =>
        {
            Console.WriteLine($"  consumer 2 handled {Text(delivery.Body)} redelivered={delivery.Redelivered}");
            await channel.BasicAckAsync(delivery.DeliveryTag, multiple: false);
            if (--remaining == 0)
            {
                done.TrySetResult();
            }
        };
        await channel.BasicConsumeAsync(queue, autoAck: false, consumer);
        await WaitAsync(done.Task, "the remaining messages");
    }

    public static async Task AutoAck()
    {
        await using IConnection connection = await ConnectAsync("l04-autoack");
        Console.WriteLine("autoAck: true, 5 tasks");
        IChannel channel = await WorkQueueAsync(connection, "work.autoack", 5);
        await new CrashingConsumer(channel, autoAck: true, crashOn: "task 2").StartAsync("work.autoack");
        await DrainAsync(connection, "work.autoack");
    }

    public static Task ManualAck() => ManualAckAsync("l04-manual-ack", [1, 0]);

    // Exercise 1: the same crash with a prefetch window of 2.
    public static Task ExercisePrefetch() => ManualAckAsync("l04-exercise-prefetch", [2]);

    static async Task ManualAckAsync(string name, ushort[] prefetches)
    {
        await using IConnection connection = await ConnectAsync(name);
        foreach (var prefetch in prefetches)
        {
            Console.WriteLine($"autoAck: false, prefetch {(prefetch == 0 ? "unlimited" : prefetch)}, 4 tasks");
            IChannel channel = await WorkQueueAsync(connection, "work.manual", 4);
            // prefetchCount 0 means no limit: the broker pushes every ready message at once.
            await channel.BasicQosAsync(0, prefetch, global: false);
            await new CrashingConsumer(channel, autoAck: false, crashOn: "task 2").StartAsync("work.manual");
            await DrainAsync(connection, "work.manual");
        }
    }

    // Negative acknowledgements with basic.get, one step at a time.
    public static async Task Nack()
    {
        await using IConnection connection = await ConnectAsync("l04-nack");
        await using IChannel channel = await WorkQueueAsync(connection, "work.nack", 2);

        async Task<BasicGetResult> GetAsync()
        {
            var message = await channel.BasicGetAsync("work.nack", autoAck: false) ?? throw new InvalidOperationException("queue empty");
            Console.WriteLine($"get {Text(message.Body)} delivery-tag={message.DeliveryTag} redelivered={message.Redelivered} (then {message.MessageCount} ready)");
            return message;
        }

        var first = await GetAsync();
        await channel.BasicNackAsync(first.DeliveryTag, multiple: false, requeue: true);
        Console.WriteLine("  nack requeue=true: back in the queue, at its original position");

        var again = await GetAsync();
        await channel.BasicRejectAsync(again.DeliveryTag, requeue: false);
        Console.WriteLine("  reject requeue=false: discarded (or dead-lettered, lesson 6)");

        var second = await GetAsync();
        await channel.BasicAckAsync(second.DeliveryTag, multiple: false);
        Console.WriteLine("  ack: removed");
        Console.WriteLine($"work.nack holds {await channel.MessageCountAsync("work.nack")} message(s)");
    }

    // The prefetch window: a consumer that never acknowledges receives prefetchCount messages, then nothing.
    public static async Task Prefetch()
    {
        await using IConnection connection = await ConnectAsync("l04-prefetch");
        IChannel channel = await WorkQueueAsync(connection, "work.prefetch", 10);
        await channel.BasicQosAsync(0, prefetchCount: 3, global: false);

        var received = 0;
        var three = new TaskCompletionSource();
        var consumer = new AsyncEventingBasicConsumer(channel);
        consumer.ReceivedAsync += (_, _) =>
        {
            if (Interlocked.Increment(ref received) == 3)
            {
                three.TrySetResult();
            }
            return Task.CompletedTask;
        };
        await channel.BasicConsumeAsync("work.prefetch", autoAck: false, consumer);
        await WaitAsync(three.Task, "three deliveries");
        await Task.Delay(500);

        await using IChannel observer = await connection.CreateChannelAsync();
        Console.WriteLine($"received {received}, still ready in the queue: {await observer.MessageCountAsync("work.prefetch")}");
        await channel.CloseAsync();
        Console.WriteLine($"channel closed, ready again: {await observer.MessageCountAsync("work.prefetch")}");
    }

    // Publisher confirms: with tracking on, BasicPublishAsync completes when the broker has taken responsibility for the message.
    public static async Task Confirms()
    {
        await using IConnection connection = await ConnectAsync("l04-confirms");
        var options = new CreateChannelOptions(publisherConfirmationsEnabled: true, publisherConfirmationTrackingEnabled: true);
        await using IChannel channel = await connection.CreateChannelAsync(options);
        await DeleteAsync(channel, [], ["orders.confirmed", "orders.limited"]);
        await channel.QueueDeclareAsync("orders.confirmed", durable: true, exclusive: false, autoDelete: false);
        // A queue that holds one message and refuses the next ones: the broker nacks what it refuses.
        await channel.QueueDeclareAsync("orders.limited", durable: true, exclusive: false, autoDelete: false,
            arguments: new Dictionary<string, object?> { ["x-max-length"] = 1, ["x-overflow"] = "reject-publish" });

        async Task PublishAsync(string routingKey, bool mandatory, string body)
        {
            var sequence = await channel.GetNextPublishSequenceNumberAsync();
            var properties = new BasicProperties { DeliveryMode = DeliveryModes.Persistent };
            try
            {
                await channel.BasicPublishAsync("", routingKey, mandatory, properties, Bytes(body));
                Console.WriteLine($"#{sequence} {body} to {routingKey}: confirmed");
            }
            catch (PublishReturnException e)
            {
                Console.WriteLine($"#{sequence} {body} to {routingKey}: {e.GetType().Name} {e.ReplyCode} {e.ReplyText}");
            }
            catch (PublishException e)
            {
                Console.WriteLine($"#{sequence} {body} to {routingKey}: {e.GetType().Name} IsReturn={e.IsReturn} \"{e.Message}\"");
            }
        }

        await PublishAsync("orders.confirmed", mandatory: false, "order 1");
        await PublishAsync("no-such-queue", mandatory: false, "order 2");
        await PublishAsync("no-such-queue", mandatory: true, "order 3");
        await PublishAsync("orders.limited", mandatory: false, "order 4");
        await PublishAsync("orders.limited", mandatory: false, "order 5");
    }

    // Durability, part 1: what gets published before the broker restarts.
    public static async Task DurablePublish()
    {
        await using IConnection connection = await ConnectAsync("l04-durable-publish");
        await using IChannel channel = await connection.CreateChannelAsync(new CreateChannelOptions(true, true));
        await DeleteAsync(channel, [], ["orders.durable"]);
        await channel.QueueDeclareAsync("orders.durable", durable: true, exclusive: false, autoDelete: false);

        await channel.BasicPublishAsync("", "orders.durable", mandatory: true,
            new BasicProperties { DeliveryMode = DeliveryModes.Persistent }, Bytes("persistent order"));
        await channel.BasicPublishAsync("", "orders.durable", mandatory: true,
            new BasicProperties { DeliveryMode = DeliveryModes.Transient }, Bytes("transient order"));
        Console.WriteLine($"orders.durable holds {await channel.MessageCountAsync("orders.durable")} message(s), both confirmed");

        try
        {
            await channel.QueueDeleteAsync("orders.transient", ifUnused: false, ifEmpty: false);
            await channel.QueueDeclareAsync("orders.transient", durable: false, exclusive: false, autoDelete: false);
            Console.WriteLine("declared the non-durable queue orders.transient");
        }
        catch (OperationInterruptedException e)
        {
            Console.WriteLine($"non-durable queue refused: {e.ShutdownReason?.ReplyCode} {e.ShutdownReason?.ReplyText}");
            Console.WriteLine($"channel open: {channel.IsOpen}, connection open: {connection.IsOpen}");
        }
    }

    // Durability, part 2: run after the broker has restarted.
    public static async Task DurableCheck()
    {
        await using IConnection connection = await ConnectAsync("l04-durable-check");
        await using IChannel channel = await connection.CreateChannelAsync();
        await PrintQueueAsync(channel, "orders.durable");
        try
        {
            await channel.QueueDeclarePassiveAsync("orders.transient");
            Console.WriteLine("orders.transient still exists");
        }
        catch (OperationInterruptedException e)
        {
            Console.WriteLine($"orders.transient: {e.ShutdownReason?.ReplyCode} {e.ShutdownReason?.ReplyText}");
        }
    }

    // At-least-once delivery means duplicates: a consumer that records what it has processed turns them into no-ops.
    public static async Task Idempotent()
    {
        await using IConnection connection = await ConnectAsync("l04-idempotent");
        IChannel publisher = await connection.CreateChannelAsync(new CreateChannelOptions(true, true));
        await DeleteAsync(publisher, [], ["payments"]);
        await publisher.QueueDeclareAsync("payments", durable: true, exclusive: false, autoDelete: false);

        // P-1 is published twice, as a publisher does when a confirm doesn't arrive and it retries.
        foreach (var (id, amount) in new[] { ("P-1", 30), ("P-1", 30), ("P-2", 45) })
        {
            var properties = new BasicProperties { MessageId = id, DeliveryMode = DeliveryModes.Persistent };
            await publisher.BasicPublishAsync("", "payments", mandatory: true, properties, Bytes($"{amount}"));
        }
        await publisher.CloseAsync();

        // Stands for a table with a unique key on the message ID, updated in the same transaction as the balance.
        var processed = new HashSet<string>();
        var balance = 0;

        async Task ConsumeAsync(string name, bool crashAfterP2)
        {
            IChannel channel = await connection.CreateChannelAsync();
            await channel.BasicQosAsync(0, 1, false);
            var remaining = (int)await channel.MessageCountAsync("payments");
            var stop = new TaskCompletionSource();
            var consumer = new AsyncEventingBasicConsumer(channel);
            consumer.ReceivedAsync += async (_, delivery) =>
            {
                if (stop.Task.IsCompleted)
                {
                    return;
                }
                var id = delivery.BasicProperties.MessageId!;
                if (processed.Add(id))
                {
                    balance += int.Parse(Text(delivery.Body));
                    Console.WriteLine($"{name}: {id} redelivered={delivery.Redelivered} charged, balance {balance}");
                }
                else
                {
                    Console.WriteLine($"{name}: {id} redelivered={delivery.Redelivered} already processed, acknowledged without charging");
                }
                if (crashAfterP2 && id == "P-2")
                {
                    Console.WriteLine($"{name}: crashes before acknowledging {id}");
                    stop.TrySetResult();
                    return;
                }
                await channel.BasicAckAsync(delivery.DeliveryTag, false);
                if (--remaining == 0)
                {
                    stop.TrySetResult();
                }
            };
            await channel.BasicConsumeAsync("payments", autoAck: false, consumer);
            await WaitAsync(stop.Task, name);
            await channel.CloseAsync();
        }

        await ConsumeAsync("consumer 1", crashAfterP2: true);
        await ConsumeAsync("consumer 2", crashAfterP2: false);
        Console.WriteLine($"final balance {balance}");
    }
}
