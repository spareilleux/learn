---
title: 2. Topología — exchanges, bindings y colas
description: Los exchanges direct, fanout, topic y headers con sus reglas exactas de coincidencia, el exchange por defecto y los predeclarados, los mensajes que nada enruta (mandatory, basic.return, exchanges alternativos), los bindings de exchange a exchange, y el error PRECONDITION_FAILED de una declaración no equivalente.
sidebar:
  order: 2
---

Ejemplo completo: [`L02.cs`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/csharp/L02.cs), y el ejemplo topic con el cliente Java en [`L02.java`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/java/client/src/main/java/dev/learn/rabbitmq/L02.java). Cada programa borra y declara su topología, publica unos cuantos mensajes, luego vacía cada cola con `basic.get` e imprime los cuerpos en el orden de la cola, para que su salida muestre exactamente adónde fue cada mensaje.

## Una topología es una tabla de enrutamiento

En la lección 1, el productor elegía una cola por su nombre. En la mayoría de los sistemas no debería: el servicio que emite «pedido creado» no sabe, ni debería saber, que facturación, envíos y analítica quieren una copia. La **topología**, el conjunto de exchanges, colas y bindings, traslada ese conocimiento al broker. El productor nombra un exchange y describe el mensaje con una clave de enrutamiento; la cola de cada consumidor se enlaza al exchange con las claves que le interesan.

El [tipo de exchange](https://www.rabbitmq.com/docs/exchanges) decide cómo coincide un binding:

| Tipo | Un binding coincide cuando | Uso típico |
|---|---|---|
| `direct` | su clave es igual a la clave de enrutamiento | trabajo clasificado por categoría: gravedad, cliente, región |
| `fanout` | siempre; las claves se ignoran | difusión: invalidación de caché, actualizaciones de precios |
| `topic` | su patrón coincide con la clave de enrutamiento, palabra por palabra | eventos: `order.created.eu` |
| `headers` | las cabeceras del mensaje coinciden con los argumentos del binding | enrutar por varios atributos a la vez |

Un exchange tiene además una **durabilidad** (un exchange durable sobrevive a un reinicio), un indicador **auto-delete** (se borra cuando desaparece su último binding), un indicador **internal** (los productores no pueden publicar en él, solo otros exchanges) y **argumentos**, como `alternate-exchange` más abajo. Las colas tienen los suyos: durable, **exclusive** (usada por una sola conexión y borrada con ella), auto-delete, y argumentos como el límite de longitud de la lección 4 o el tipo de cola de la lección 5.

## Direct: claves iguales

```csharp
await channel.ExchangeDeclareAsync("logs.direct", ExchangeType.Direct, durable: true);
foreach (var queue in queues)
{
    await channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false);
}
// Una cola puede tener varios bindings, y una clave puede estar enlazada a varias colas.
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

`error message` está en las dos colas: un exchange deja una copia en cada cola con un binding que coincide, y cada cola entrega luego su copia de forma independiente. `debug message` no está en ninguna. Ningún binding tiene la clave `debug`, y el broker descartó el mensaje sin avisar al productor; las últimas secciones de esta lección tratan ese caso.

## Fanout: todas las colas

```csharp
await channel.ExchangeDeclareAsync("prices.fanout", ExchangeType.Fanout, durable: true);
foreach (var queue in queues)
{
    await channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false);
    await channel.QueueBindAsync(queue, "prices.fanout", routingKey: "");
}

// La clave de enrutamiento se ignora.
await channel.BasicPublishAsync("prices.fanout", "anything", Bytes("EURUSD 1.17"));
```

```text
prices.web: EURUSD 1.17
prices.mobile: EURUSD 1.17
prices.audit: EURUSD 1.17
```

Un exchange fanout es el más barato de enrutar, porque no compara nada. Es publish/subscribe en su forma más simple: añadir un suscriptor consiste en declarar una cola y enlazarla, sin tocar el productor.

## Topic: patrones sobre palabras

Un exchange topic divide la clave de enrutamiento y el patrón del binding en **palabras** en cada punto. En el patrón, `*` coincide con exactamente una palabra y `#` con cero o más palabras. Cuatro bindings y seis claves:

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

El cuerpo de cada mensaje es su clave de enrutamiento, así que la salida se lee como una tabla de enrutamiento:

- `order` sola coincide con `order.#`, porque `#` puede coincidir con cero palabras, pero no con `order.*`, que necesita exactamente una palabra más.
- `eu` sola coincide con `#.eu` por la misma razón.
- `order.created.eu` coincide con tres patrones y llega a tres colas, una vez a cada una.
- `order.shipped.us` solo coincide con `order.#`: `*.created.*` quiere `created` como segunda palabra.

Las claves topic son el diseño habitual para eventos. Una forma como `<entidad>.<evento>.<región>` deja que cada consumidor elija cuánto quiere, de `order.created.eu` a `#`. Las palabras se comparan tal cual, mayúsculas incluidas, y una clave está limitada a 255 bytes.

El mismo ejemplo con el cliente Java imprime las mismas líneas, y `check.sh` compara su salida con el mismo archivo esperado. Los métodos se corresponden uno a uno:

| C# (`IChannel`) | Java (`Channel`) |
|---|---|
| `ExchangeDeclareAsync("events.topic", ExchangeType.Topic, durable: true)` | `exchangeDeclare("events.topic", BuiltinExchangeType.TOPIC, true)` |
| `QueueDeclareAsync(name, durable: true, exclusive: false, autoDelete: false)` | `queueDeclare(name, true, false, false, null)` |
| `QueueBindAsync(queue, exchange, pattern)` | `queueBind(queue, exchange, pattern)` |
| `BasicPublishAsync(exchange, key, body)` | `basicPublish(exchange, key, null, body)` |
| `BasicGetAsync(queue, autoAck: true)` | `basicGet(queue, true)` |

## Headers: varios atributos

Un exchange headers ignora la clave de enrutamiento. Sus bindings llevan argumentos, y el argumento especial `x-match` dice cómo compararlos con las cabeceras del mensaje: `all` exige que cada uno de los demás argumentos esté presente con el mismo valor, `any` exige al menos uno.

```csharp
// x-match all: cada cabecera listada debe coincidir. x-match any: basta con una.
await channel.QueueBindAsync("reports.pdf", "documents.headers", "", new Dictionary<string, object?>
{
    ["x-match"] = "all", ["type"] = "report", ["format"] = "pdf",
});
await channel.QueueBindAsync("reports.any", "documents.headers", "", new Dictionary<string, object?>
{
    ["x-match"] = "any", ["type"] = "report", ["format"] = "pdf",
});
```

Cuatro documentos, publicados con las cabeceras `type` y `format`:

```text
reports.pdf: report/pdf
reports.any: report/pdf | report/csv | invoice/pdf
```

Los exchanges headers rara vez hacen falta: una clave topic como `report.pdf` suele hacer el mismo trabajo más rápido. Ayudan cuando los atributos son opcionales o no tienen orden. El archivo [`rabbit_exchange_type_headers.erl`](https://github.com/rabbitmq/rabbitmq-server/blob/0dde27bfdd1984ff7e157226fd97656854a7f359/deps/rabbit/src/rabbit_exchange_type_headers.erl#L36-L66) del servidor muestra dos detalles que la tabla no puede mostrar: un binding sin `x-match` se comporta como `all`, y `all` y `any` a secas omiten cada argumento del binding cuyo nombre empieza por `x-`, así que no pueden filtrar por esas cabeceras. Los otros dos valores aceptados, `all-with-x` y `any-with-x`, también las comparan.

## Lo que un broker ya tiene

Un virtual host nuevo no está vacío. `rabbitmqctl list_exchanges` muestra el exchange por defecto (el nombre vacío) y los exchanges predeclarados `amq.*`, uno por tipo, que una aplicación puede usar pero no borrar. Tras ejecutar los programas de esta lección:

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

`rabbitmqctl list_bindings` muestra cómo funciona el exchange por defecto: un binding por cola, desde el exchange de nombre vacío, con el nombre de la cola como clave. Un extracto, en el orden en que lo imprimió el comando, que no es un orden estable:

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

La interfaz de gestión muestra lo mismo en la página de cada exchange, con un diagrama de sus bindings.

## Cuando nada coincide

Un mensaje que no coincide con ningún binding se descarta. El productor tiene tres maneras de notarlo o evitarlo, y [`Unroutable`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/csharp/L02.cs) muestra cada una sobre un exchange direct enlazado solo a `invoice`:

```csharp
// 1. mandatory: false (por defecto): el broker descarta el mensaje sin decir nada.
await channel.BasicPublishAsync("billing.direct", "refund", Bytes("refund #1"));

// 2. mandatory: true: el broker devuelve el mensaje con basic.return.
var returned = new TaskCompletionSource<BasicReturnEventArgs>();
channel.BasicReturnAsync += (_, args) =>
{
    returned.TrySetResult(args);
    return Task.CompletedTask;
};
await channel.BasicPublishAsync("billing.direct", "refund", mandatory: true, new BasicProperties(), Bytes("refund #2"));

// 3. Un exchange alternativo recibe todo lo que el exchange principal no puede enrutar. Es un argumento, así que se fija al declarar.
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

- **`mandatory`** es un indicador de cada publicación. Cuando está activado y ninguna cola coincide, el broker devuelve el mensaje entero con [`basic.return`](https://www.rabbitmq.com/amqp-0-9-1-reference) y el código de respuesta 312 `NO_ROUTE`. El productor se entera de forma asíncrona, por el evento `BasicReturnAsync` en C# o un `ReturnListener` en Java, así que debe relacionar el mensaje devuelto con lo que envió; la lección 4 muestra cómo las confirmaciones de publicación lo simplifican.
- Un **[exchange alternativo](https://www.rabbitmq.com/docs/ae)** se declara en el propio exchange. Lo que este no puede enrutar va al exchange alternativo, aquí un fanout enlazado a una cola `billing.unrouted`, donde alguien puede examinarlo. Los argumentos forman parte de la identidad de un exchange, así que añadir uno obligó a borrar y volver a declarar `billing.direct`; una [política](https://www.rabbitmq.com/docs/policies) puede fijar `alternate-exchange` en exchanges existentes sin eso, y la documentación recomienda las políticas por esa razón.

## Cuando las declaraciones no coinciden

Declarar solo es idempotente si los parámetros son los mismos. El programa declara `hello` como en la lección 1, y luego otra vez con `durable: false`:

```text
OperationInterruptedException: The AMQP operation was interrupted: AMQP close-reason, initiated by Peer, code=406, text='PRECONDITION_FAILED - inequivalent arg 'durable' for queue 'hello' in vhost '/': received 'false' but current is 'true'', classId=50, methodId=10
channel open: False, connection open: True
new channel: queue hello exists
```

El broker comparó la nueva declaración con la cola existente, en [`rabbit_misc:equivalence_fail`](https://github.com/rabbitmq/rabbitmq-server/blob/0dde27bfdd1984ff7e157226fd97656854a7f359/deps/rabbit_common/src/rabbit_misc.erl#L340-L343), y respondió con el error 406 `PRECONDITION_FAILED`. AMQP 0-9-1 tiene dos tipos de errores. Un **error de canal** como 406, o 404 `NOT_FOUND`, cierra el canal donde ocurrió y nada más; un **error de conexión** como 541 `INTERNAL_ERROR` cierra toda la conexión. Los ID de clase y de método, 50 y 10, corresponden a `queue.declare` en la [referencia del protocolo](https://www.rabbitmq.com/amqp-0-9-1-reference). Las consecuencias prácticas:

- Un canal cerrado no se puede reutilizar. Tras capturar la excepción, abre un canal nuevo sobre la misma conexión, como hace el programa.
- El error nombra la propiedad que difiere, y así se encuentran dos servicios que declaran la misma cola de forma distinta, una causa frecuente de este error tras un despliegue. Una salida es dejar que solo una parte, o un [archivo de definiciones](https://www.rabbitmq.com/docs/definitions) desplegado por operaciones, declare la topología compartida, y que las demás declaren en modo pasivo (`QueueDeclarePassiveAsync`), que solo comprueba que la cola existe.

## Bindings de exchange a exchange

RabbitMQ amplía AMQP 0-9-1 con [bindings de un exchange a otro exchange](https://www.rabbitmq.com/docs/e2e). Un mensaje enrutado al exchange de destino se enruta de nuevo con los bindings propios de ese exchange. El ejercicio 3 usa uno.

## Puntos clave

- Los productores nombran un exchange y una clave de enrutamiento; los bindings deciden qué colas reciben una copia, una copia por cola que coincide.
- Direct compara claves, fanout las ignora, topic aplica patrones de palabras donde `*` es una palabra y `#` cero o más, y headers compara valores de cabeceras con `x-match` a `all` o `any`.
- Un mensaje que nada enruta se descarta en silencio, salvo que se publique con `mandatory` (vuelve con `basic.return` 312 `NO_ROUTE`) o que el exchange tenga un exchange alternativo, preferiblemente fijado por una política.
- Volver a declarar con otros parámetros cierra el canal con 406 `PRECONDITION_FAILED`; la conexión sigue abierta. Decide quién es dueño de las declaraciones compartidas.
- Cada virtual host tiene el exchange por defecto, enlazado a cada cola por su nombre, y los exchanges predeclarados `amq.*`.

## Ejercicios

1. Con los cuatro bindings topic de esta lección, predice qué colas reciben las claves `order.created.us.west`, `created.eu`, `order..eu`, `Order.created.eu` y `eu.order`.

<details>
<summary>Solución</summary>

`l02-exercise-topic` las publica con los mismos bindings:

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

- `order.created.us.west` tiene cuatro palabras: `order.#` acepta cualquier número después de `order`, mientras que `*.created.*` quiere exactamente tres palabras.
- `created.eu` tiene dos palabras, así que `*.created.*` no coincide; `#.eu` sí, con `#` valiendo `created`.
- `order..eu` tiene tres palabras, la del medio vacía. Una palabra vacía sigue siendo una palabra: `order.#` y `#.eu` coinciden, y `order.*` no, porque quiere dos palabras.
- `Order.created.eu` no coincide con `order.#`: la coincidencia distingue mayúsculas de minúsculas. Coincide con los dos patrones que no nombran `order`.
- `eu.order` no coincide con nada, ya que `#.eu` quiere `eu` al final. Se descartó.

</details>

2. El ejemplo direct enlazaba `logs.all` tres veces, una por gravedad. Un colega propone un exchange fanout para `logs.all` y un exchange direct para `logs.errors`, ambos alimentados por el productor. ¿Qué tiene que cambiar el productor, y qué ofrece en cambio el binding de exchange a exchange del ejercicio 3?

<details>
<summary>Solución</summary>

Con dos exchanges, el productor debe publicar cada error dos veces, una en cada exchange, y un consumidor nuevo con otra necesidad significa otro exchange y otro cambio en el productor: la decisión de enrutamiento ha vuelto a la aplicación. Mantener un exchange por tipo de mensaje, y expresar el interés de cada consumidor como bindings, permite añadir consumidores sin tocar a los productores. Si un grupo de colas lo necesita todo, enlaza un exchange fanout al exchange principal con `#` (para un exchange topic) y enlaza esas colas al fanout: el productor sigue publicando una sola vez.

</details>

3. Sin cambiar los productores de un exchange `shop.topic`, da a una cola `audit.log` una copia de cada mensaje publicado en él, incluidos los que ninguna otra cola quiere. Declara el lado de auditoría como un exchange fanout enlazado a `shop.topic`.

<details>
<summary>Solución</summary>

```csharp
await channel.ExchangeDeclareAsync("shop.topic", ExchangeType.Topic, durable: true);
await channel.ExchangeDeclareAsync("audit.fanout", ExchangeType.Fanout, durable: true);
await channel.QueueDeclareAsync("shop.orders", durable: true, exclusive: false, autoDelete: false);
await channel.QueueDeclareAsync("audit.log", durable: true, exclusive: false, autoDelete: false);
await channel.QueueBindAsync("shop.orders", "shop.topic", "order.*");
await channel.QueueBindAsync("audit.log", "audit.fanout", "");
// destino, origen, patrón: los mensajes pasan de shop.topic a audit.fanout cuando el patrón coincide.
await channel.ExchangeBindAsync(destination: "audit.fanout", source: "shop.topic", routingKey: "#");
```

```text
shop.orders: order.created
audit.log: order.created | user.signed-up
```

`user.signed-up` no coincidía con ningún binding de cola, pero sí con el binding de exchange `#`, así que la cola de auditoría lo tiene. `ExchangeBindAsync` recibe primero el destino, igual que `QueueBindAsync` recibe primero la cola; en Java es `exchangeBind(destination, source, routingKey)`. Un exchange alternativo solo habría atrapado el mensaje no enrutable, no las copias de los enrutados.

</details>

## Fuentes

- RabbitMQ: [exchanges](https://www.rabbitmq.com/docs/exchanges), [colas](https://www.rabbitmq.com/docs/queues), [exchanges alternativos](https://www.rabbitmq.com/docs/ae), [bindings de exchange a exchange](https://www.rabbitmq.com/docs/e2e), [políticas](https://www.rabbitmq.com/docs/policies), [definiciones](https://www.rabbitmq.com/docs/definitions), [productores y mensajes no enrutables](https://www.rabbitmq.com/docs/publishers#unroutable), [tutorial cuatro (enrutamiento)](https://www.rabbitmq.com/tutorials/tutorial-four-dotnet) y [tutorial cinco (topics)](https://www.rabbitmq.com/tutorials/tutorial-five-dotnet)
- [Referencia completa de AMQP 0-9-1](https://www.rabbitmq.com/amqp-0-9-1-reference): `queue.declare`, `basic.return`, códigos de respuesta
- Código fuente del servidor en v4.3.5: [`rabbit_exchange_type_headers.erl`](https://github.com/rabbitmq/rabbitmq-server/blob/0dde27bfdd1984ff7e157226fd97656854a7f359/deps/rabbit/src/rabbit_exchange_type_headers.erl), [`rabbit_misc.erl`](https://github.com/rabbitmq/rabbitmq-server/blob/0dde27bfdd1984ff7e157226fd97656854a7f359/deps/rabbit_common/src/rabbit_misc.erl#L340-L343)
