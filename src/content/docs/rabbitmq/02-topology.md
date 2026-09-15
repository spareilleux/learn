---
title: 2. Topology — exchanges, bindings and queues
description: Direct, fanout, topic and headers exchanges with their exact matching rules, the default and predeclared exchanges, messages that nothing routes (mandatory, basic.return, alternate exchanges), exchange-to-exchange bindings, and the PRECONDITION_FAILED error of an inequivalent declaration.
sidebar:
  order: 2
---

Full example: [`L02.cs`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/csharp/L02.cs), and the topic example with the Java client in [`L02.java`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/java/client/src/main/java/dev/learn/rabbitmq/L02.java). Each program deletes and declares its topology, publishes a few messages, then empties every queue with `basic.get` and prints the bodies in queue order, so that its output shows exactly where each message went.

## A topology is a routing table

In lesson 1, the publisher chose a queue by name. In most systems it shouldn't: the service that emits "order created" doesn't know, and shouldn't know, that billing, shipping and analytics all want a copy. The **topology**, the set of exchanges, queues and bindings, moves that knowledge into the broker. The publisher names an exchange and describes the message with a routing key; each consumer's queue is bound to the exchange with the keys it cares about.

The [exchange type](https://www.rabbitmq.com/docs/exchanges) decides how a binding matches:

| Type | A binding matches when | Typical use |
|---|---|---|
| `direct` | its key equals the routing key | work sorted by category: severity, tenant, region |
| `fanout` | always; keys are ignored | broadcast: cache invalidation, price updates |
| `topic` | its pattern matches the routing key, word by word | events: `order.created.eu` |
| `headers` | the message's headers match the binding's arguments | routing on several attributes at once |

An exchange also has a **durability** (a durable exchange survives a restart), an **auto-delete** flag (deleted when its last binding goes), an **internal** flag (publishers can't publish to it, only other exchanges) and **arguments**, such as `alternate-exchange` below. Queues have their own: durable, **exclusive** (used by one connection and deleted with it), auto-delete, and arguments such as the length limit of lesson 4 or the queue type of lesson 5.

## Direct: equal keys

```csharp
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
```

```text
logs.errors: error message
logs.all: info message | error message | warning message
```

`error message` is in both queues: an exchange puts one copy in every queue with a matching binding, and each queue then delivers its copy independently. `debug message` is nowhere. No binding has the key `debug`, and the broker dropped the message without telling the publisher; the last sections of this lesson deal with that.

## Fanout: every queue

```csharp
await channel.ExchangeDeclareAsync("prices.fanout", ExchangeType.Fanout, durable: true);
foreach (var queue in queues)
{
    await channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false);
    await channel.QueueBindAsync(queue, "prices.fanout", routingKey: "");
}

// The routing key is ignored.
await channel.BasicPublishAsync("prices.fanout", "anything", Bytes("EURUSD 1.17"));
```

```text
prices.web: EURUSD 1.17
prices.mobile: EURUSD 1.17
prices.audit: EURUSD 1.17
```

A fanout exchange is the cheapest to route, since it compares nothing. It is publish/subscribe in its plainest form: adding a subscriber means declaring a queue and binding it, without touching the publisher.

## Topic: patterns over words

A topic exchange splits the routing key and the binding pattern into **words** at each dot. In the pattern, `*` matches exactly one word and `#` matches zero or more words. Four bindings and six keys:

```csharp
(string Queue, string Pattern)[] bindings =
[
    ("orders.all", "order.#"),
    ("created.anywhere", "*.created.*"),
    ("europe", "#.eu"),
    ("orders.two-words", "order.*"),
];
```

```text
bind orders.all to order.#
bind created.anywhere to *.created.*
bind europe to #.eu
bind orders.two-words to order.*
orders.all: order.created.eu | order.shipped.us | order | order.cancelled
created.anywhere: order.created.eu | invoice.created.eu
europe: order.created.eu | invoice.created.eu | eu
orders.two-words: order.cancelled
```

Each message's body is its routing key, so the output reads as a routing table:

- `order` alone matches `order.#`, because `#` can match zero words, but not `order.*`, which needs exactly one more.
- `eu` alone matches `#.eu` for the same reason.
- `order.created.eu` matches three patterns and lands in three queues, once each.
- `order.shipped.us` matches only `order.#`: `*.created.*` wants `created` as the second word.

Topic keys are the usual design for events. A shape such as `<entity>.<event>.<region>` lets each consumer choose how much it wants, from `order.created.eu` to `#`. The words are compared as they are, case included, and a key is limited to 255 bytes.

The same example with the Java client prints the same lines, and `check.sh` compares its output with the same expected file. The methods map one to one:

| C# (`IChannel`) | Java (`Channel`) |
|---|---|
| `ExchangeDeclareAsync("events.topic", ExchangeType.Topic, durable: true)` | `exchangeDeclare("events.topic", BuiltinExchangeType.TOPIC, true)` |
| `QueueDeclareAsync(name, durable: true, exclusive: false, autoDelete: false)` | `queueDeclare(name, true, false, false, null)` |
| `QueueBindAsync(queue, exchange, pattern)` | `queueBind(queue, exchange, pattern)` |
| `BasicPublishAsync(exchange, key, body)` | `basicPublish(exchange, key, null, body)` |
| `BasicGetAsync(queue, autoAck: true)` | `basicGet(queue, true)` |

## Headers: several attributes

A headers exchange ignores the routing key. Its bindings carry arguments, and the special argument `x-match` says how to compare them with the message's headers: `all` requires every other argument to be present with the same value, `any` requires at least one.

```csharp
// x-match all: every listed header must match. x-match any: one is enough.
await channel.QueueBindAsync("reports.pdf", "documents.headers", "", new Dictionary<string, object?>
{
    ["x-match"] = "all", ["type"] = "report", ["format"] = "pdf",
});
await channel.QueueBindAsync("reports.any", "documents.headers", "", new Dictionary<string, object?>
{
    ["x-match"] = "any", ["type"] = "report", ["format"] = "pdf",
});
```

Four documents, published with the headers `type` and `format`:

```text
reports.pdf: report/pdf
reports.any: report/pdf | report/csv | invoice/pdf
```

Headers exchanges are rarely needed: a topic key such as `report.pdf` often does the same job faster. They help when attributes are optional or unordered. The server's [`rabbit_exchange_type_headers.erl`](https://github.com/rabbitmq/rabbitmq-server/blob/0dde27bfdd1984ff7e157226fd97656854a7f359/deps/rabbit/src/rabbit_exchange_type_headers.erl#L36-L66) shows two details the table can't: a binding without `x-match` behaves as `all`, and plain `all` and `any` skip every binding argument whose name starts with `x-`, so they can't match on such headers. The two other accepted values, `all-with-x` and `any-with-x`, compare those too.

## What a broker already has

A new virtual host is not empty. `rabbitmqctl list_exchanges` shows the default exchange (the empty name) and the predeclared `amq.*` exchanges, one per type, which an application may use but not delete. After running this lesson's programs:

```text
$ docker exec rabbitmq rabbitmqctl list_exchanges name type
Listing exchanges for vhost / ...
name	type
	direct
amq.direct	direct
amq.fanout	fanout
amq.headers	headers
amq.match	headers
amq.rabbitmq.log	topic
amq.rabbitmq.trace	topic
amq.topic	topic
audit.fanout	fanout
billing.direct	direct
billing.unrouted	fanout
documents.headers	headers
events.topic	topic
logs.direct	direct
orders.topic	topic
prices.fanout	fanout
shop.topic	topic
```

`rabbitmqctl list_bindings` shows how the default exchange works: one binding per queue, from the exchange with the empty name, with the queue's name as its key. An excerpt, in the order the command printed it, which is not a stable order:

```text
$ docker exec rabbitmq rabbitmqctl list_bindings source_name destination_name destination_kind routing_key
Listing bindings for vhost /...
source_name	destination_name	destination_kind	routing_key
	orders.all	queue	orders.all
	hello	queue	hello
...
events.topic	europe	queue	#.eu
events.topic	orders.all	queue	order.#
logs.direct	logs.all	queue	info
logs.direct	logs.errors	queue	error
shop.topic	audit.fanout	exchange	#
```

The management UI shows the same thing on each exchange's page, with a diagram of its bindings.

## When nothing matches

A message that matches no binding is dropped. The publisher has three ways to notice or avoid that, and [`Unroutable`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/csharp/L02.cs) shows each one on a direct exchange bound only to `invoice`:

```csharp
// 1. mandatory: false (the default): the broker drops the message and says nothing.
await channel.BasicPublishAsync("billing.direct", "refund", Bytes("refund #1"));

// 2. mandatory: true: the broker sends the message back with basic.return.
var returned = new TaskCompletionSource<BasicReturnEventArgs>();
channel.BasicReturnAsync += (_, args) =>
{
    returned.TrySetResult(args);
    return Task.CompletedTask;
};
await channel.BasicPublishAsync("billing.direct", "refund", mandatory: true, new BasicProperties(), Bytes("refund #2"));

// 3. An alternate exchange receives whatever the main exchange can't route. It is an argument, so it is set at declaration.
await channel.ExchangeDeclareAsync("billing.direct", ExchangeType.Direct, durable: true, autoDelete: false,
    arguments: new Dictionary<string, object?> { ["alternate-exchange"] = "billing.unrouted" });
```

```text
mandatory=false: published refund #1, billing.invoices holds 0 message(s)
mandatory=true: returned 312 NO_ROUTE, exchange=billing.direct key=refund body=refund #2
alternate-exchange:
billing.invoices: invoice #3
billing.unrouted: refund #3
```

- **`mandatory`** is a flag on each publish. When it is set and no queue matches, the broker sends the whole message back with [`basic.return`](https://www.rabbitmq.com/amqp-0-9-1-reference) and the reply code 312 `NO_ROUTE`. The publisher learns it asynchronously, through the `BasicReturnAsync` event in C# or a `ReturnListener` in Java, so it must correlate the returned message with what it sent; lesson 4 shows how publisher confirms make that simpler.
- An **[alternate exchange](https://www.rabbitmq.com/docs/ae)** is declared on the exchange itself. What it can't route goes to the alternate exchange, here a fanout bound to a `billing.unrouted` queue, where someone can inspect it. Arguments are part of an exchange's identity, so adding one meant deleting and redeclaring `billing.direct`; a [policy](https://www.rabbitmq.com/docs/policies) can set `alternate-exchange` on existing exchanges without that, and the documentation recommends policies for this reason.

## When declarations disagree

Declaring is idempotent only if the settings are the same. The program declares `hello` as lesson 1 did, then again with `durable: false`:

```text
OperationInterruptedException: The AMQP operation was interrupted: AMQP close-reason, initiated by Peer, code=406, text='PRECONDITION_FAILED - inequivalent arg 'durable' for queue 'hello' in vhost '/': received 'false' but current is 'true'', classId=50, methodId=10
channel open: False, connection open: True
new channel: queue hello exists
```

The broker compared the new declaration with the existing queue, in [`rabbit_misc:equivalence_fail`](https://github.com/rabbitmq/rabbitmq-server/blob/0dde27bfdd1984ff7e157226fd97656854a7f359/deps/rabbit_common/src/rabbit_misc.erl#L340-L343), and answered with the error 406 `PRECONDITION_FAILED`. AMQP 0-9-1 has two kinds of errors. A **channel error** such as 406, or 404 `NOT_FOUND`, closes the channel it happened on and nothing else; a **connection error** such as 541 `INTERNAL_ERROR` closes the whole connection. The class and method IDs, 50 and 10, are `queue.declare` in the [protocol reference](https://www.rabbitmq.com/amqp-0-9-1-reference). The practical consequences:

- A closed channel can't be reused. After catching the exception, open a new channel on the same connection, as the program does.
- The error names the property that differs, which is how you find two services that declare the same queue differently, a common source of this error after a deployment. One way out is to let only one party, or a [definitions file](https://www.rabbitmq.com/docs/definitions) deployed by operations, declare the shared topology, and have the others declare passively (`QueueDeclarePassiveAsync`), which only checks that the queue exists.

## Exchange-to-exchange bindings

RabbitMQ extends AMQP 0-9-1 with [bindings from an exchange to another exchange](https://www.rabbitmq.com/docs/e2e). A message routed to the destination exchange is then routed again by that exchange's own bindings. Exercise 3 uses one.

## Key takeaways

- Publishers name an exchange and a routing key; bindings decide which queues get a copy, one copy per matching queue.
- Direct compares keys, fanout ignores them, topic matches word patterns where `*` is one word and `#` is zero or more, and headers matches header values with `x-match` set to `all` or `any`.
- A message nothing routes is dropped silently unless it is published with `mandatory` (it comes back with `basic.return` 312 `NO_ROUTE`) or the exchange has an alternate exchange, preferably set by a policy.
- Redeclaring with different settings closes the channel with 406 `PRECONDITION_FAILED`; the connection stays open. Decide who owns shared declarations.
- Every virtual host has the default exchange, bound to every queue by name, and the predeclared `amq.*` exchanges.

## Exercises

1. With the four topic bindings of this lesson, predict which queues receive the keys `order.created.us.west`, `created.eu`, `order..eu`, `Order.created.eu` and `eu.order`.

<details>
<summary>Solution</summary>

`l02-exercise-topic` publishes them to the same bindings:

```text
bind orders.all to order.#
bind created.anywhere to *.created.*
bind europe to #.eu
bind orders.two-words to order.*
orders.all: order.created.us.west | order..eu
created.anywhere: Order.created.eu
europe: created.eu | order..eu | Order.created.eu
orders.two-words: (empty)
```

- `order.created.us.west` has four words: `order.#` takes any number after `order`, while `*.created.*` wants exactly three words.
- `created.eu` has two words, so `*.created.*` doesn't match; `#.eu` does, with `#` matching `created`.
- `order..eu` has three words, the middle one empty. An empty word is still a word: `order.#` and `#.eu` match, and `order.*` doesn't, because it wants two words.
- `Order.created.eu` doesn't match `order.#`: matching is case-sensitive. It matches the two patterns that don't name `order`.
- `eu.order` matches nothing, since `#.eu` wants `eu` at the end. It was dropped.

</details>

2. The direct example bound `logs.all` three times, once per severity. A colleague proposes a fanout exchange for `logs.all` and a direct exchange for `logs.errors`, both fed by the publisher. What does the publisher have to change, and what does the exchange-to-exchange binding of exercise 3 offer instead?

<details>
<summary>Solution</summary>

With two exchanges, the publisher must publish every error twice, once to each exchange, and a new consumer with a different need means another exchange and another change in the publisher: the routing decision has moved back into the application. Keeping one exchange per kind of message, and expressing each consumer's interest as bindings, lets consumers be added without touching publishers. If a group of queues needs everything, bind a fanout exchange to the main exchange with `#` (for a topic exchange) and bind those queues to the fanout: the publisher still publishes once.

</details>

3. Without changing the publishers of a `shop.topic` exchange, give an `audit.log` queue a copy of every message published to it, including those no other queue wants. Declare the audit side as a fanout exchange bound to `shop.topic`.

<details>
<summary>Solution</summary>

```csharp
await channel.ExchangeDeclareAsync("shop.topic", ExchangeType.Topic, durable: true);
await channel.ExchangeDeclareAsync("audit.fanout", ExchangeType.Fanout, durable: true);
await channel.QueueDeclareAsync("shop.orders", durable: true, exclusive: false, autoDelete: false);
await channel.QueueDeclareAsync("audit.log", durable: true, exclusive: false, autoDelete: false);
await channel.QueueBindAsync("shop.orders", "shop.topic", "order.*");
await channel.QueueBindAsync("audit.log", "audit.fanout", "");
// destination, source, pattern: messages flow from shop.topic to audit.fanout when the pattern matches.
await channel.ExchangeBindAsync(destination: "audit.fanout", source: "shop.topic", routingKey: "#");
```

```text
shop.orders: order.created
audit.log: order.created | user.signed-up
```

`user.signed-up` matched no queue binding, but it matched the exchange binding `#`, so the audit queue has it. `ExchangeBindAsync` takes the destination first, like `QueueBindAsync` takes the queue first; in Java it is `exchangeBind(destination, source, routingKey)`. An alternate exchange would have caught only the unroutable message, not the copies of routed ones.

</details>

## Sources

- RabbitMQ: [exchanges](https://www.rabbitmq.com/docs/exchanges), [queues](https://www.rabbitmq.com/docs/queues), [alternate exchanges](https://www.rabbitmq.com/docs/ae), [exchange-to-exchange bindings](https://www.rabbitmq.com/docs/e2e), [policies](https://www.rabbitmq.com/docs/policies), [definitions](https://www.rabbitmq.com/docs/definitions), [publishers and unroutable messages](https://www.rabbitmq.com/docs/publishers#unroutable), [tutorial four (routing)](https://www.rabbitmq.com/tutorials/tutorial-four-dotnet) and [tutorial five (topics)](https://www.rabbitmq.com/tutorials/tutorial-five-dotnet)
- [AMQP 0-9-1 complete reference](https://www.rabbitmq.com/amqp-0-9-1-reference): `queue.declare`, `basic.return`, reply codes
- Server source at v4.3.5: [`rabbit_exchange_type_headers.erl`](https://github.com/rabbitmq/rabbitmq-server/blob/0dde27bfdd1984ff7e157226fd97656854a7f359/deps/rabbit/src/rabbit_exchange_type_headers.erl), [`rabbit_misc.erl`](https://github.com/rabbitmq/rabbitmq-server/blob/0dde27bfdd1984ff7e157226fd97656854a7f359/deps/rabbit_common/src/rabbit_misc.erl#L340-L343)
