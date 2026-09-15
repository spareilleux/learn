using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using RabbitMQ.Client.Exceptions;
using static Learn.Rabbit.Broker;

namespace Learn.Rabbit;

// Lesson 2: the four exchange types, and what happens to a message no binding matches.
// Each example declares its topology, publishes, then empties every queue with basic.get to show where the messages went.
static class L02
{
    // Direct: a binding matches when its key equals the routing key.
    public static async Task Direct()
    {
        await using IConnection connection = await ConnectAsync("l02-direct");
        await using IChannel channel = await connection.CreateChannelAsync();
        string[] queues = ["logs.errors", "logs.all"];
        await DeleteAsync(channel, ["logs.direct"], queues);

        await channel.ExchangeDeclareAsync("logs.direct", ExchangeType.Direct, durable: true);
        foreach (var queue in queues)
        {
            await channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false);
        }
        // One queue can have several bindings, and one key can be bound to several queues.
        await channel.QueueBindAsync("logs.errors", "logs.direct", routingKey: "error");
        await channel.QueueBindAsync("logs.all", "logs.direct", routingKey: "error");
        await channel.QueueBindAsync("logs.all", "logs.direct", routingKey: "warning");
        await channel.QueueBindAsync("logs.all", "logs.direct", routingKey: "info");

        foreach (var severity in new[] { "info", "error", "debug", "warning" })
        {
            await channel.BasicPublishAsync("logs.direct", severity, Bytes($"{severity} message"));
        }

        foreach (var queue in queues)
        {
            await PrintQueueAsync(channel, queue);
        }
    }

    // Fanout: every bound queue gets a copy; the routing key is ignored.
    public static async Task Fanout()
    {
        await using IConnection connection = await ConnectAsync("l02-fanout");
        await using IChannel channel = await connection.CreateChannelAsync();
        string[] queues = ["prices.web", "prices.mobile", "prices.audit"];
        await DeleteAsync(channel, ["prices.fanout"], queues);

        await channel.ExchangeDeclareAsync("prices.fanout", ExchangeType.Fanout, durable: true);
        foreach (var queue in queues)
        {
            await channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false);
            await channel.QueueBindAsync(queue, "prices.fanout", routingKey: "");
        }

        // The routing key is ignored.
        await channel.BasicPublishAsync("prices.fanout", "anything", Bytes("EURUSD 1.17"));

        foreach (var queue in queues)
        {
            await PrintQueueAsync(channel, queue);
        }
    }

    // Topic: keys are words separated by dots; * matches exactly one word, # matches zero or more.
    public static Task Topic() =>
        TopicAsync("l02-topic", ["order.created.eu", "order.shipped.us", "invoice.created.eu", "order", "order.cancelled", "eu"]);

    // Exercise 1: the same bindings, with keys chosen to test the edges of * and #.
    public static Task ExerciseTopic() =>
        TopicAsync("l02-exercise-topic", ["order.created.us.west", "created.eu", "order..eu", "Order.created.eu", "eu.order"]);

    static async Task TopicAsync(string name, string[] keys)
    {
        await using IConnection connection = await ConnectAsync(name);
        await using IChannel channel = await connection.CreateChannelAsync();
        (string Queue, string Pattern)[] bindings =
        [
            ("orders.all", "order.#"),
            ("created.anywhere", "*.created.*"),
            ("europe", "#.eu"),
            ("orders.two-words", "order.*"),
        ];
        await DeleteAsync(channel, ["events.topic"], bindings.Select(b => b.Queue).ToArray());

        await channel.ExchangeDeclareAsync("events.topic", ExchangeType.Topic, durable: true);
        foreach (var (queue, pattern) in bindings)
        {
            await channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false);
            await channel.QueueBindAsync(queue, "events.topic", pattern);
            Console.WriteLine($"bind {queue} to {pattern}");
        }

        foreach (var key in keys)
        {
            await channel.BasicPublishAsync("events.topic", key, Bytes(key));
        }

        foreach (var (queue, _) in bindings)
        {
            await PrintQueueAsync(channel, queue);
        }
    }

    // Headers: bindings match message headers instead of the routing key.
    public static async Task Headers()
    {
        await using IConnection connection = await ConnectAsync("l02-headers");
        await using IChannel channel = await connection.CreateChannelAsync();
        string[] queues = ["reports.pdf", "reports.any"];
        await DeleteAsync(channel, ["documents.headers"], queues);

        await channel.ExchangeDeclareAsync("documents.headers", ExchangeType.Headers, durable: true);
        foreach (var queue in queues)
        {
            await channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false);
        }
        // x-match all: every listed header must match. x-match any: one is enough.
        await channel.QueueBindAsync("reports.pdf", "documents.headers", "", new Dictionary<string, object?>
        {
            ["x-match"] = "all", ["type"] = "report", ["format"] = "pdf",
        });
        await channel.QueueBindAsync("reports.any", "documents.headers", "", new Dictionary<string, object?>
        {
            ["x-match"] = "any", ["type"] = "report", ["format"] = "pdf",
        });

        (string Type, string Format)[] documents = [("report", "pdf"), ("report", "csv"), ("invoice", "pdf"), ("invoice", "csv")];
        foreach (var (type, format) in documents)
        {
            var properties = new BasicProperties
            {
                Headers = new Dictionary<string, object?> { ["type"] = type, ["format"] = format },
            };
            await channel.BasicPublishAsync("documents.headers", "", mandatory: false, properties, Bytes($"{type}/{format}"));
        }

        foreach (var queue in queues)
        {
            await PrintQueueAsync(channel, queue);
        }
    }

    // A message that matches no binding is dropped silently, unless the publisher asks for it back or the exchange has a fallback.
    public static async Task Unroutable()
    {
        await using IConnection connection = await ConnectAsync("l02-unroutable");
        await using IChannel channel = await connection.CreateChannelAsync();
        await DeleteAsync(channel, ["billing.direct", "billing.unrouted"], ["billing.invoices", "billing.unrouted"]);

        await channel.ExchangeDeclareAsync("billing.direct", ExchangeType.Direct, durable: true);
        await channel.QueueDeclareAsync("billing.invoices", durable: true, exclusive: false, autoDelete: false);
        await channel.QueueBindAsync("billing.invoices", "billing.direct", "invoice");

        // 1. mandatory: false (the default): the broker drops the message and says nothing.
        await channel.BasicPublishAsync("billing.direct", "refund", Bytes("refund #1"));
        var ready = await channel.MessageCountAsync("billing.invoices");
        Console.WriteLine($"mandatory=false: published refund #1, billing.invoices holds {ready} message(s)");

        // 2. mandatory: true: the broker sends the message back with basic.return.
        var returned = new TaskCompletionSource<BasicReturnEventArgs>();
        channel.BasicReturnAsync += (_, args) =>
        {
            returned.TrySetResult(args);
            return Task.CompletedTask;
        };
        await channel.BasicPublishAsync("billing.direct", "refund", mandatory: true, new BasicProperties(), Bytes("refund #2"));
        await WaitAsync(returned.Task, "basic.return");
        var r = returned.Task.Result;
        Console.WriteLine($"mandatory=true: returned {r.ReplyCode} {r.ReplyText}, exchange={r.Exchange} key={r.RoutingKey} body={Text(r.Body)}");

        // 3. An alternate exchange receives whatever the main exchange can't route. It is an argument, so it is set at declaration.
        await channel.ExchangeDeleteAsync("billing.direct");
        await channel.ExchangeDeclareAsync("billing.unrouted", ExchangeType.Fanout, durable: true);
        await channel.QueueDeclareAsync("billing.unrouted", durable: true, exclusive: false, autoDelete: false);
        await channel.QueueBindAsync("billing.unrouted", "billing.unrouted", "");
        await channel.ExchangeDeclareAsync("billing.direct", ExchangeType.Direct, durable: true, autoDelete: false,
            arguments: new Dictionary<string, object?> { ["alternate-exchange"] = "billing.unrouted" });
        await channel.QueueBindAsync("billing.invoices", "billing.direct", "invoice");

        await channel.BasicPublishAsync("billing.direct", "invoice", Bytes("invoice #3"));
        await channel.BasicPublishAsync("billing.direct", "refund", Bytes("refund #3"));
        Console.WriteLine("alternate-exchange:");
        await PrintQueueAsync(channel, "billing.invoices");
        await PrintQueueAsync(channel, "billing.unrouted");
    }

    // Redeclaring an existing queue with different settings is a protocol error: the broker closes the channel.
    public static async Task Inequivalent()
    {
        await using IConnection connection = await ConnectAsync("l02-inequivalent");
        IChannel channel = await connection.CreateChannelAsync();
        await channel.QueueDeclareAsync("hello", durable: true, exclusive: false, autoDelete: false);
        try
        {
            await channel.QueueDeclareAsync("hello", durable: false, exclusive: false, autoDelete: false);
        }
        catch (OperationInterruptedException e)
        {
            Console.WriteLine($"{e.GetType().Name}: {e.Message}");
        }
        Console.WriteLine($"channel open: {channel.IsOpen}, connection open: {connection.IsOpen}");

        // The connection survives: open another channel and carry on.
        await using IChannel next = await connection.CreateChannelAsync();
        var declared = await next.QueueDeclarePassiveAsync("hello");
        Console.WriteLine($"new channel: queue {declared.QueueName} exists");
    }

    // Exercise 3: bind an exchange to an exchange, so that audit gets a copy of every event without touching the producers.
    public static async Task ExerciseExchangeToExchange()
    {
        await using IConnection connection = await ConnectAsync("l02-exercise-e2e");
        await using IChannel channel = await connection.CreateChannelAsync();
        await DeleteAsync(channel, ["shop.topic", "audit.fanout"], ["shop.orders", "audit.log"]);

        await channel.ExchangeDeclareAsync("shop.topic", ExchangeType.Topic, durable: true);
        await channel.ExchangeDeclareAsync("audit.fanout", ExchangeType.Fanout, durable: true);
        await channel.QueueDeclareAsync("shop.orders", durable: true, exclusive: false, autoDelete: false);
        await channel.QueueDeclareAsync("audit.log", durable: true, exclusive: false, autoDelete: false);
        await channel.QueueBindAsync("shop.orders", "shop.topic", "order.*");
        await channel.QueueBindAsync("audit.log", "audit.fanout", "");
        // destination, source, pattern: messages flow from shop.topic to audit.fanout when the pattern matches.
        await channel.ExchangeBindAsync(destination: "audit.fanout", source: "shop.topic", routingKey: "#");

        foreach (var key in new[] { "order.created", "user.signed-up" })
        {
            await channel.BasicPublishAsync("shop.topic", key, Bytes(key));
        }
        await PrintQueueAsync(channel, "shop.orders");
        await PrintQueueAsync(channel, "audit.log");
    }
}
