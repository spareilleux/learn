---
title: 3. Clients in C#, Java and Spring AMQP
description: RabbitMQ.Client 7 and its async API, the Java client, and Spring AMQP's RabbitTemplate and @RabbitListener exchanging the same JSON orders — connection and channel rules, message properties, consumer threads and body lifetime, and Spring's __TypeId__ header.
sidebar:
  order: 3
---

Full example: [`L03.cs`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/csharp/L03.cs), [`L03.java`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/java/client/src/main/java/dev/learn/rabbitmq/L03.java), and the Spring Boot application in [`java/spring`](https://github.com/spareilleux/learn/tree/main/code/rabbitmq/java/spring). [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/check.sh) runs them in pairs: each producer's messages are read by a consumer in another language.

## One topology, three clients

The three programs share a topic exchange `orders.topic` and a queue `orders.billing` bound to it with `order.#`. Each one declares that topology itself, with the same settings, so that none depends on another having started first. The C# version:

```csharp
// Every client declares the same topology with the same settings, so it doesn't matter which one starts first.
public static async Task DeclareAsync(IChannel channel)
{
    await channel.ExchangeDeclareAsync("orders.topic", ExchangeType.Topic, durable: true);
    await channel.QueueDeclareAsync("orders.billing", durable: true, exclusive: false, autoDelete: false);
    await channel.QueueBindAsync("orders.billing", "orders.topic", "order.#");
}
```

What they must agree on besides the topology is the **message**: its body format and its properties.

## Message properties

An AMQP 0-9-1 message has a body, which the broker never reads, and a set of [properties](https://www.rabbitmq.com/docs/publishers#message-properties) that consumers, and in some cases the broker, do read:

| Property | Meaning | Read by the broker? |
|---|---|---|
| `content_type`, `content_encoding` | the body's format, such as `application/json` | no |
| `delivery_mode` | 2 for persistent, 1 for transient (lesson 4) | yes |
| `message_id` | an ID chosen by the publisher | no; consumers use it for deduplication |
| `correlation_id`, `reply_to` | request/reply (lesson 7) | no |
| `type`, `app_id` | the kind of message and the sending application | no |
| `timestamp` | a publisher-chosen time, in seconds | no |
| `expiration` | a per-message TTL (lesson 6) | yes |
| `priority` | for priority queues | yes |
| `headers` | a table of your own keys, also used by headers exchanges | by headers exchanges |

The C# publisher sets most of them on a [`BasicProperties`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/BasicProperties.cs) object:

```csharp
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
```

```text
published A-1 {"id":"A-1","sku":"GUITAR-STRINGS","quantity":2}
published A-2 {"id":"A-2","sku":"CAPO","quantity":1}
published A-3 {"id":"A-3","sku":"PICKS","quantity":12}
```

`Json` is `new JsonSerializerOptions(JsonSerializerDefaults.Web)`, which writes camelCase names, the convention Jackson follows in Java.

## The Java client reads them

```java
channel.basicQos(10);
CountDownLatch waiting = new CountDownLatch((int) channel.messageCount("orders.billing"));

channel.basicConsume("orders.billing", false,
        (consumerTag, delivery) -> {
            AMQP.BasicProperties p = delivery.getProperties();
            Order order = JSON.readValue(delivery.getBody(), Order.class);
            String headers = p.getHeaders() == null ? "" : new TreeMap<>(p.getHeaders()).entrySet().stream()
                    .map(h -> h.getKey() + "=" + h.getValue())
                    .collect(Collectors.joining(", "));
            long tag = delivery.getEnvelope().getDeliveryTag();
            System.out.println("#" + tag + " " + delivery.getEnvelope().getRoutingKey()
                    + " content-type=" + p.getContentType() + " message-id=" + p.getMessageId()
                    + " type=" + p.getType() + " app-id=" + p.getAppId() + " headers=[" + headers + "]");
            System.out.println("   " + order);
            channel.basicAck(tag, false);
            waiting.countDown();
        },
        consumerTag -> { });
```

```text
#1 order.created.eu content-type=application/json message-id=A-1 type=order.created app-id=csharp headers=[region=eu]
   Order[id=A-1, sku=GUITAR-STRINGS, quantity=2]
#2 order.created.eu content-type=application/json message-id=A-2 type=order.created app-id=csharp headers=[region=eu]
   Order[id=A-2, sku=CAPO, quantity=1]
#3 order.created.eu content-type=application/json message-id=A-3 type=order.created app-id=csharp headers=[region=eu]
   Order[id=A-3, sku=PICKS, quantity=12]
```

The record `Order(String id, String sku, int quantity)` is read with Jackson 3's `JsonMapper`. Two lines introduce lesson 4: `basicAck` tells the broker the message is handled, because this consumer passed `false` for automatic acknowledgement, and `basicQos(10)` lets at most ten unacknowledged messages reach it at a time. The **delivery tag**, `#1` to `#3`, numbers the deliveries on this channel; it is what an acknowledgement refers to.

The reverse direction works the same way. The Java publisher builds its properties with `AMQP.BasicProperties.Builder`, and the C# consumer prints them:

```java
AMQP.BasicProperties properties = new AMQP.BasicProperties.Builder()
        .contentType("application/json")
        .messageId(order.id())
        .type("order.created")
        .appId("java")
        .deliveryMode(2)
        .headers(Map.of("region", "us"))
        .build();
```

```text
#1 order.created.us content-type=application/json message-id=B-1 type=order.created app-id=java headers=[region=us]
   Order { Id = B-1, Sku = TUNER, Quantity = 1 }
#2 order.created.us content-type=application/json message-id=B-2 type=order.created app-id=java headers=[region=us]
   Order { Id = B-2, Sku = STRAP, Quantity = 2 }
```

## RabbitMQ.Client 7 in practice

Version 7 of the .NET client rewrote the API around `async`/`await`. The [migration guide](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/main/v7-MIGRATION.md) lists the changes that break code written for version 6 or copied from older answers: `IModel` became `IChannel`, every method gained an `Async` form and lost its synchronous one, `CreateBasicProperties()` gave way to `new BasicProperties()`, and message bodies became `ReadOnlyMemory<byte>`. The C# consumer:

```csharp
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
```

Four rules come with it, and each has bitten someone:

- **The body doesn't outlive the callback.** `delivery.Body` points into a buffer the client rents and reuses. The [`BasicDeliverEventArgs`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/Events/BasicDeliverEventArgs.cs#L63-L81) documentation says that using it outside `ReceivedAsync` "requires that it be copied", with `Body.ToArray()`. Deserialising inside the callback, as here, is the usual answer; putting `delivery.Body` in a list or a channel for later is a bug that shows up as corrupted messages under load.
- **Callbacks run one at a time by default.** [`ConsumerDispatchConcurrency`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/Constants.cs#L95) defaults to 1, so the client awaits each handler before calling the next, and messages are handled in delivery order. A higher value on the `ConnectionFactory` or in `CreateChannelOptions` handles messages concurrently and gives up that order; the handler must then be thread-safe. That is why `--remaining` above needs no lock.
- **Don't publish concurrently on one channel.** The [.NET client guide](https://www.rabbitmq.com/client-libraries/dotnet-api-guide#concurrency-channel-sharing) is explicit that sharing a channel between concurrent publishers "will lead to incorrect frame interleaving at the protocol level". Use a channel per publishing task, or a small pool.
- **Connections recover, but not your in-flight work.** `AutomaticRecoveryEnabled` and `TopologyRecoveryEnabled` are both `true` in [`ConnectionFactory`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/ConnectionFactory.cs#L168): after a network failure the client reconnects, reopens channels, redeclares what it declared and restarts consumers. Unacknowledged deliveries of the lost channel go back to the queue, and their delivery tags mean nothing on the new channel. Automatic recovery is also *to verify* in this course's CI: lesson 4 restarts the broker, but its programs reconnect by starting again.

The Java client has the same rules with blocking calls. Its [API guide](https://www.rabbitmq.com/client-libraries/java-api-guide#concurrency) says to avoid sharing a `Channel` between threads, and that concurrent publishing on one "can result in incorrect frame interleaving on the wire"; consumer callbacks run on a thread pool separate from the caller, and "each Channel will dispatch all deliveries to its Consumer handler methods on it in order". Automatic recovery has been on by default since version 4.0 of the Java client.

## Spring AMQP

[Spring AMQP](https://docs.spring.io/spring-amqp/reference/) wraps the Java client in the Spring way: a template to send, annotated methods to receive, beans to declare. With `spring-boot-starter-amqp`, Spring Boot [auto-configures](https://docs.spring.io/spring-boot/reference/messaging/amqp.html) a `CachingConnectionFactory` from the `spring.rabbitmq.*` properties, a `RabbitTemplate`, a `RabbitAdmin` and a listener container factory. [Lesson 1 of the Spring course](../spring-cloud-reactor/01-spring-boot-from-aspnet-core/) explains beans, auto-configuration and profiles, which this application uses without further comment.

The topology is three beans. `RabbitAdmin` declares every `Exchange`, `Queue` and `Binding` bean when the application first opens a connection:

```java
// The same topology as the C# and Java client examples, declared by RabbitAdmin when the first connection opens.
@Bean
TopicExchange ordersExchange() {
    return new TopicExchange("orders.topic");
}

@Bean
Queue billingQueue() {
    return new Queue("orders.billing");
}

@Bean
Binding billingBinding(Queue billingQueue, TopicExchange ordersExchange) {
    return BindingBuilder.bind(billingQueue).to(ordersExchange).with("order.#");
}

// Replaces the default converter (byte[], String and Java serialization) for RabbitTemplate and @RabbitListener.
@Bean
MessageConverter jsonMessageConverter() {
    return new JacksonJsonMessageConverter();
}
```

`new Queue("orders.billing")` and `new TopicExchange("orders.topic")` are durable and not auto-delete by default, the same settings as the other clients; with any difference, the declaration would fail with the `PRECONDITION_FAILED` of lesson 2. Without the converter bean, `RabbitTemplate` would use the `SimpleMessageConverter`, which sends a `Serializable` Java object with Java serialization: unreadable from C# and a known security risk. [`JacksonJsonMessageConverter`](https://docs.spring.io/spring-amqp/reference/amqp/message-converters.html) is the Jackson 3 converter of Spring AMQP 4; the Jackson 2 one, `Jackson2JsonMessageConverter`, is deprecated.

### The listener receives the C# orders

```java
@RabbitListener(queues = "orders.billing")
void onOrder(Order order, MessageProperties properties) {
    System.out.println("#" + properties.getDeliveryTag() + " " + properties.getReceivedRoutingKey()
            + " message-id=" + properties.getMessageId() + " app-id=" + properties.getAppId()
            + " __TypeId__=" + properties.getHeader("__TypeId__"));
    System.out.println("   " + order);
    expected.countDown();
}
```

```text
#1 order.created.eu message-id=A-1 app-id=csharp __TypeId__=null
   Order[id=A-1, sku=GUITAR-STRINGS, quantity=2]
#2 order.created.eu message-id=A-2 app-id=csharp __TypeId__=null
   Order[id=A-2, sku=CAPO, quantity=1]
#3 order.created.eu message-id=A-3 app-id=csharp __TypeId__=null
   Order[id=A-3, sku=PICKS, quantity=12]
```

There is no `basicAck` in the method. The listener container consumes with manual acknowledgements and acknowledges for you: in the default [acknowledge mode](https://docs.spring.io/spring-amqp/reference/amqp/containerAttributes.html) `AUTO`, it acks when the method returns and rejects when it throws, with `defaultRequeueRejected` set to `true`, so a message that always fails comes back forever. Lesson 6 breaks that loop with dead lettering. The container's default prefetch is 250.

### The C# consumer receives the Spring orders

`RabbitTemplate.convertAndSend` converts the object, and a message post-processor sets the other properties:

```java
rabbit.convertAndSend("orders.topic", "order.created.ca", order, message -> {
    message.getMessageProperties().setMessageId(order.id());
    message.getMessageProperties().setType("order.created");
    message.getMessageProperties().setAppId("spring");
    message.getMessageProperties().setHeader("region", "ca");
    message.getMessageProperties().setDeliveryMode(MessageDeliveryMode.PERSISTENT);
    return message;
});
```

```text
#1 order.created.ca content-type=application/json message-id=C-1 type=order.created app-id=spring headers=[__TypeId__=dev.learn.rabbitmq.spring.OrdersApplication$Order, region=ca]
   Order { Id = C-1, Sku = AMP, Quantity = 1 }
#2 order.created.ca content-type=application/json message-id=C-2 type=order.created app-id=spring headers=[__TypeId__=dev.learn.rabbitmq.spring.OrdersApplication$Order, region=ca]
   Order { Id = C-2, Sku = CABLE, Quantity = 3 }
```

The Jackson converter added a `__TypeId__` header with the Java class name, `$` included for a nested record. A C# consumer can ignore it; a Spring consumer uses it only when the listener's parameter type doesn't say what to create (exercise 1). A Java class name in a message is a coupling between services, and the [message converters documentation](https://docs.spring.io/spring-amqp/reference/amqp/message-converters.html) shows how to map class names to neutral IDs with the converter's type mapper when that matters.

## The contract between languages

What made these six exchanges work is a short list, worth writing down for any queue shared across teams:

- the exchange, its type, the routing keys and the queue settings, identical wherever they are declared;
- a body format with a `content_type`, here JSON with camelCase names;
- a `message_id` on every message, which lesson 4 needs for idempotence;
- a `type` that names the message independently of any language's class names.

## Key takeaways

- One long-lived connection per application, a channel per thread or task, and never two concurrent publishers on one channel.
- RabbitMQ.Client 7 is async: `IChannel`, `BasicPublishAsync`, `AsyncEventingBasicConsumer`. The body is valid only inside the callback, and callbacks run one at a time unless you raise `ConsumerDispatchConcurrency`.
- Message properties carry what a consumer needs without parsing the body: content type, message ID, type, headers. The broker reads only a few of them, such as the delivery mode and the expiration.
- Spring AMQP declares `Exchange`, `Queue` and `Binding` beans through `RabbitAdmin`, converts bodies with a `MessageConverter` (configure a JSON one) and acknowledges `@RabbitListener` messages automatically when the method returns.
- Interoperability is a contract on topology and message format, not on client libraries.

## Exercises

1. The listener printed `__TypeId__=null` for the C# messages, yet it created `Order` records. Where did the type come from, and when would the same listener fail to convert a message without that header?

<details>
<summary>Solution</summary>

From the method's parameter. The converter's `TypePrecedence` defaults to `INFERRED`: the [message converters documentation](https://docs.spring.io/spring-amqp/reference/amqp/message-converters.html) says the inferred type "will override the inbound `__TypeId__` and related headers created by the sending system", which "applies only if the parameter type is concrete (not abstract or an interface), or it is from the `java.util` package. In all other cases, the `__TypeId__` and related headers is used." A listener that takes an interface, say `void onEvent(OrderEvent event)`, would need the header, and a message from C# would fail to convert. The fix is either a concrete parameter type, a type mapper that maps a neutral `type` to a class, or having the C# publisher send `__TypeId__`, which couples it to Java class names. I haven't run the failing case; the conversion error it produces is *to verify*.

</details>

2. A colleague stores `delivery.Body` from `ReceivedAsync` in a `Channel<ReadOnlyMemory<byte>>` for a background worker to parse. Tests with one message pass. What goes wrong in production, and what is the smallest fix?

<details>
<summary>Solution</summary>

The memory behind `delivery.Body` belongs to the client, which the [migration guide](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/main/v7-MIGRATION.md) says is "only valid for application use within the context of the executing ReceivedAsync event". Once the handler returns, the buffer can be reused for the next frame, so the worker may parse the bytes of a later message, or a mix. A single message in a test hides it because nothing overwrites the buffer. The smallest fix is to queue `delivery.Body.ToArray()`, a copy. The worker must also acknowledge through the channel with the delivery tag, not from another channel, and preferably only after parsing succeeded. I didn't write a program that shows the corruption: its output would not be deterministic.

</details>

3. Spring's listener container acknowledges when the method returns. The C# consumer above acknowledges after printing. For each, say what happens to a message if the process is killed in the middle of handling it, and if the handler throws.

<details>
<summary>Solution</summary>

Killed mid-handling: in both cases the message was delivered but not acknowledged, so the broker requeues it when the connection closes and delivers it again, with `redelivered` set to `true`. Lesson 4 shows it happen.

Handler throws: Spring's container catches the exception and rejects the message, requeueing it because `defaultRequeueRejected` is `true`, so the same message is redelivered, possibly in a tight loop. In the C# client, an exception from `ReceivedAsync` is reported through the channel's `CallbackExceptionAsync` event and the message is neither acknowledged nor rejected: it stays unacknowledged, and with a prefetch of 10 the consumer slows down and then stops receiving once ten such messages are stuck, until the channel closes and they are requeued. That second behaviour is from the client's source and documentation and is *to verify* with a program in lesson 6, which handles failures on purpose.

</details>

## Sources

- RabbitMQ: [.NET client API guide](https://www.rabbitmq.com/client-libraries/dotnet-api-guide), [.NET client 7 migration guide](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/main/v7-MIGRATION.md), [Java client API guide](https://www.rabbitmq.com/client-libraries/java-api-guide), [publishers and message properties](https://www.rabbitmq.com/docs/publishers), [consumers](https://www.rabbitmq.com/docs/consumers)
- .NET client source at v7.2.2: [`BasicDeliverEventArgs.cs`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/Events/BasicDeliverEventArgs.cs#L63-L81), [`Constants.cs`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/Constants.cs#L95), [`ConnectionFactory.cs`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/ConnectionFactory.cs#L168)
- Spring: [Spring AMQP reference](https://docs.spring.io/spring-amqp/reference/), [message converters](https://docs.spring.io/spring-amqp/reference/amqp/message-converters.html), [listener container attributes](https://docs.spring.io/spring-amqp/reference/amqp/containerAttributes.html), [Spring Boot AMQP support](https://docs.spring.io/spring-boot/reference/messaging/amqp.html)
