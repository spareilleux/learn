// Runs one example of the course: dotnet run -- <name>. RABBITMQ_HOST names the broker (default localhost).
using Learn.Rabbit;

var examples = new Dictionary<string, Func<Task>>
{
    ["l01-send"] = L01.Send,
    ["l01-receive"] = L01.Receive,
    ["l02-direct"] = L02.Direct,
    ["l02-fanout"] = L02.Fanout,
    ["l02-topic"] = L02.Topic,
    ["l02-exercise-topic"] = L02.ExerciseTopic,
    ["l02-headers"] = L02.Headers,
    ["l02-unroutable"] = L02.Unroutable,
    ["l02-inequivalent"] = L02.Inequivalent,
    ["l02-exercise-e2e"] = L02.ExerciseExchangeToExchange,
    ["l03-publish"] = L03.Publish,
    ["l03-consume"] = L03.Consume,
    ["l04-autoack"] = L04.AutoAck,
    ["l04-manual-ack"] = L04.ManualAck,
    ["l04-exercise-prefetch"] = L04.ExercisePrefetch,
    ["l04-nack"] = L04.Nack,
    ["l04-prefetch"] = L04.Prefetch,
    ["l04-confirms"] = L04.Confirms,
    ["l04-durable-publish"] = L04.DurablePublish,
    ["l04-durable-check"] = L04.DurableCheck,
    ["l04-idempotent"] = L04.Idempotent,
};

if (args.Length != 1 || !examples.TryGetValue(args[0], out var example))
{
    Console.Error.WriteLine($"usage: rabbit <{string.Join('|', examples.Keys)}>");
    return 2;
}

await example();
return 0;
