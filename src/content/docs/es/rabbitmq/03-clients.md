---
title: 3. Clientes en C#, Java y Spring AMQP
description: RabbitMQ.Client 7 y su API asíncrona, el cliente Java, y el RabbitTemplate y el @RabbitListener de Spring AMQP intercambiando los mismos pedidos JSON — reglas de conexiones y canales, propiedades de los mensajes, hilos de los consumidores y vida del cuerpo, y la cabecera __TypeId__ de Spring.
sidebar:
  order: 3
---

Ejemplo completo: [`L03.cs`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/csharp/L03.cs), [`L03.java`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/java/client/src/main/java/dev/learn/rabbitmq/L03.java), y la aplicación Spring Boot en [`java/spring`](https://github.com/spareilleux/learn/tree/main/code/rabbitmq/java/spring). [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/check.sh) los ejecuta por parejas: los mensajes de cada productor los lee un consumidor escrito en otro lenguaje.

## Una topología, tres clientes

Los tres programas comparten un exchange topic `orders.topic` y una cola `orders.billing` enlazada a él con `order.#`. Cada uno declara esa topología por sí mismo, con los mismos parámetros, para que ninguno dependa de que otro haya arrancado antes. La versión en C#:

```csharp
// Cada cliente declara la misma topología con los mismos parámetros, así que da igual cuál arranque primero.
public static async Task DeclareAsync(IChannel channel)
{
    await channel.ExchangeDeclareAsync("orders.topic", ExchangeType.Topic, durable: true);
    await channel.QueueDeclareAsync("orders.billing", durable: true, exclusive: false, autoDelete: false);
    await channel.QueueBindAsync("orders.billing", "orders.topic", "order.#");
}
```

En lo que deben ponerse de acuerdo además de la topología es el **mensaje**: el formato de su cuerpo y sus propiedades.

## Propiedades de los mensajes

Un mensaje AMQP 0-9-1 tiene un cuerpo, que el broker nunca lee, y un conjunto de [propiedades](https://www.rabbitmq.com/docs/publishers#message-properties) que leen los consumidores, y en algunos casos el broker:

| Propiedad | Significado | ¿La lee el broker? |
|---|---|---|
| `content_type`, `content_encoding` | el formato del cuerpo, por ejemplo `application/json` | no |
| `delivery_mode` | 2 para persistente, 1 para transitorio (lección 4) | sí |
| `message_id` | un ID elegido por el productor | no; los consumidores lo usan para deduplicar |
| `correlation_id`, `reply_to` | petición/respuesta (lección 7) | no |
| `type`, `app_id` | el tipo de mensaje y la aplicación que lo envía | no |
| `timestamp` | una hora elegida por el productor, en segundos | no |
| `expiration` | un TTL por mensaje (lección 6) | sí |
| `priority` | para las colas con prioridad | sí |
| `headers` | una tabla de claves propias, que usan también los exchanges headers | los exchanges headers |

El productor en C# fija la mayoría en un objeto [`BasicProperties`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/BasicProperties.cs):

```csharp
Order[] orders = [new("A-1", "GUITAR-STRINGS", 2), new("A-2", "CAPO", 1), new("A-3", "PICKS", 12)];
foreach (var order in orders)
{
    // BasicProperties es el sobre: metadatos que el broker y el consumidor leen sin analizar el cuerpo.
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

`Json` es `new JsonSerializerOptions(JsonSerializerDefaults.Web)`, que escribe los nombres en camelCase, la convención que sigue Jackson en Java.

## El cliente Java los lee

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

El record `Order(String id, String sku, int quantity)` se lee con el `JsonMapper` de Jackson 3. Dos líneas anticipan la lección 4: `basicAck` le dice al broker que el mensaje está procesado, porque este consumidor pasó `false` para el acuse de recibo automático, y `basicQos(10)` deja que le lleguen como mucho diez mensajes sin confirmar a la vez. El **delivery tag**, de `#1` a `#3`, numera las entregas en este canal; es a lo que se refiere un acuse de recibo.

El sentido inverso funciona igual. El productor Java construye sus propiedades con `AMQP.BasicProperties.Builder`, y el consumidor en C# las imprime:

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

## RabbitMQ.Client 7 en la práctica

La versión 7 del cliente .NET reescribió la API en torno a `async`/`await`. La [guía de migración](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/81622758098163d764ce13f13dce454310038948/v7-MIGRATION.md) lista los cambios que rompen el código escrito para la versión 6 o copiado de respuestas antiguas: `IModel` pasó a ser `IChannel`, cada método ganó una forma `Async` y perdió la síncrona, `CreateBasicProperties()` dejó paso a `new BasicProperties()`, y los cuerpos de los mensajes pasaron a ser `ReadOnlyMemory<byte>`. El consumidor en C#:

```csharp
var consumer = new AsyncEventingBasicConsumer(channel);
consumer.ReceivedAsync += async (_, delivery) =>
{
    // El cuerpo solo es válido durante el callback: el cliente reutiliza su búfer. Deserializarlo o copiarlo aquí.
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

Con ella vienen cuatro reglas, y cada una ya ha mordido a alguien:

- **El cuerpo no sobrevive al callback.** `delivery.Body` apunta a un búfer que el cliente alquila y reutiliza. La documentación de [`BasicDeliverEventArgs`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/Events/BasicDeliverEventArgs.cs#L63-L81) dice que usarlo fuera de `ReceivedAsync` «requires that it be copied», con `Body.ToArray()`. Deserializar dentro del callback, como aquí, es la respuesta habitual; guardar `delivery.Body` en una lista o un canal para más tarde es un bug que aparece como mensajes corruptos bajo carga.
- **Los callbacks se ejecutan de uno en uno por defecto.** [`ConsumerDispatchConcurrency`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/Constants.cs#L95) vale 1 por defecto, así que el cliente espera cada handler antes de llamar al siguiente, y los mensajes se procesan en orden de entrega. Un valor mayor en la `ConnectionFactory` o en `CreateChannelOptions` procesa los mensajes en paralelo y renuncia a ese orden; el handler debe entonces ser thread-safe. Por eso `--remaining` arriba no necesita ningún lock.
- **No publiques en paralelo en un mismo canal.** La [guía del cliente .NET](https://www.rabbitmq.com/client-libraries/dotnet-api-guide#concurrency-channel-sharing) dice explícitamente que compartir un canal entre productores concurrentes «will lead to incorrect frame interleaving at the protocol level». Usa un canal por tarea de publicación, o un pequeño pool.
- **Las conexiones se recuperan, pero no tu trabajo en curso.** `AutomaticRecoveryEnabled` y `TopologyRecoveryEnabled` valen ambos `true` en [`ConnectionFactory`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/ConnectionFactory.cs#L168): tras un fallo de red, el cliente se reconecta, reabre los canales, vuelve a declarar lo que había declarado y reinicia los consumidores. Las entregas sin confirmar del canal perdido vuelven a la cola, y sus delivery tags no significan nada en el canal nuevo. La recuperación automática está además *por verificar* en la CI de este curso: la lección 4 reinicia el broker, pero sus programas se reconectan volviendo a arrancar.

El cliente Java tiene las mismas reglas con llamadas bloqueantes. Su [guía de la API](https://www.rabbitmq.com/client-libraries/java-api-guide#concurrency) dice que se evite compartir un `Channel` entre hilos, y que publicar en paralelo en uno «can result in incorrect frame interleaving on the wire»; los callbacks de los consumidores se ejecutan en un pool de hilos distinto del que llama, y «each Channel will dispatch all deliveries to its Consumer handler methods on it in order». La recuperación automática está activada por defecto desde la versión 4.0 del cliente Java.

## Spring AMQP

[Spring AMQP](https://docs.spring.io/spring-amqp/reference/) envuelve el cliente Java al estilo de Spring: un template para enviar, métodos anotados para recibir, beans para declarar. Con `spring-boot-starter-amqp`, Spring Boot [configura automáticamente](https://docs.spring.io/spring-boot/reference/messaging/amqp.html) una `CachingConnectionFactory` a partir de las propiedades `spring.rabbitmq.*`, un `RabbitTemplate`, un `RabbitAdmin` y una fábrica de contenedores de listeners. La [lección 1 del curso de Spring](../../spring-cloud-reactor/01-spring-boot-from-aspnet-core/) explica los beans, la autoconfiguración y los perfiles, que esta aplicación usa sin más comentario.

La topología son tres beans. `RabbitAdmin` declara cada bean `Exchange`, `Queue` y `Binding` cuando la aplicación abre su primera conexión:

```java
// La misma topología que los ejemplos en C# y con el cliente Java, declarada por RabbitAdmin al abrirse la primera conexión.
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

// Sustituye el convertidor por defecto (byte[], String y serialización Java) para RabbitTemplate y @RabbitListener.
@Bean
MessageConverter jsonMessageConverter() {
    return new JacksonJsonMessageConverter();
}
```

`new Queue("orders.billing")` y `new TopicExchange("orders.topic")` son durables y no auto-delete por defecto, los mismos parámetros que los otros clientes; con cualquier diferencia, la declaración fallaría con el `PRECONDITION_FAILED` de la lección 2. Sin el bean del convertidor, `RabbitTemplate` usaría el `SimpleMessageConverter`, que envía un objeto Java `Serializable` con la serialización de Java: ilegible desde C# y un riesgo de seguridad conocido. [`JacksonJsonMessageConverter`](https://docs.spring.io/spring-amqp/reference/amqp/message-converters.html) es el convertidor de Jackson 3 de Spring AMQP 4; el de Jackson 2, `Jackson2JsonMessageConverter`, está obsoleto.

### El listener recibe los pedidos de C#

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

No hay `basicAck` en el método. El contenedor de listeners consume con acuses de recibo manuales y confirma por ti: en el [modo de acuse](https://docs.spring.io/spring-amqp/reference/amqp/containerAttributes.html) por defecto, `AUTO`, confirma cuando el método termina y rechaza cuando lanza una excepción, con `defaultRequeueRejected` a `true`, así que un mensaje que siempre falla vuelve para siempre. La lección 6 rompe ese bucle con dead lettering. El prefetch por defecto del contenedor es 250.

### El consumidor en C# recibe los pedidos de Spring

`RabbitTemplate.convertAndSend` convierte el objeto, y un postprocesador de mensajes fija las demás propiedades:

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

El convertidor de Jackson añadió una cabecera `__TypeId__` con el nombre de la clase Java, `$` incluido para un record anidado. Un consumidor en C# puede ignorarla; un consumidor Spring solo la usa cuando el tipo del parámetro del listener no dice qué crear (ejercicio 1). Un nombre de clase Java en un mensaje es un acoplamiento entre servicios, y la [documentación de los convertidores de mensajes](https://docs.spring.io/spring-amqp/reference/amqp/message-converters.html) muestra cómo asociar nombres de clases a ID neutros con el type mapper del convertidor cuando eso importa.

## El contrato entre lenguajes

Lo que hizo funcionar estos seis intercambios es una lista corta, que conviene escribir para cualquier cola compartida entre equipos:

- el exchange, su tipo, las claves de enrutamiento y los parámetros de la cola, idénticos dondequiera que se declaren;
- un formato de cuerpo con un `content_type`, aquí JSON con nombres en camelCase;
- un `message_id` en cada mensaje, que la lección 4 necesita para la idempotencia;
- un `type` que nombra el mensaje con independencia de los nombres de clases de cualquier lenguaje.

## Puntos clave

- Una conexión de larga duración por aplicación, un canal por hilo o tarea, y nunca dos productores concurrentes en un mismo canal.
- RabbitMQ.Client 7 es asíncrono: `IChannel`, `BasicPublishAsync`, `AsyncEventingBasicConsumer`. El cuerpo solo es válido dentro del callback, y los callbacks se ejecutan de uno en uno salvo que subas `ConsumerDispatchConcurrency`.
- Las propiedades del mensaje llevan lo que un consumidor necesita sin analizar el cuerpo: tipo de contenido, ID de mensaje, tipo, cabeceras. El broker solo lee unas pocas, como el modo de entrega y la expiración.
- Spring AMQP declara los beans `Exchange`, `Queue` y `Binding` mediante `RabbitAdmin`, convierte los cuerpos con un `MessageConverter` (configura uno de JSON) y confirma automáticamente los mensajes de un `@RabbitListener` cuando el método termina.
- La interoperabilidad es un contrato sobre la topología y el formato de los mensajes, no sobre las bibliotecas cliente.

## Ejercicios

1. El listener imprimió `__TypeId__=null` para los mensajes de C#, y aun así creó records `Order`. ¿De dónde salió el tipo, y cuándo fallaría el mismo listener al convertir un mensaje sin esa cabecera?

<details>
<summary>Solución</summary>

Del parámetro del método. El `TypePrecedence` del convertidor vale `INFERRED` por defecto: la [documentación de los convertidores de mensajes](https://docs.spring.io/spring-amqp/reference/amqp/message-converters.html) dice que el tipo inferido «will override the inbound `__TypeId__` and related headers created by the sending system», lo que «applies only if the parameter type is concrete (not abstract or an interface), or it is from the `java.util` package. In all other cases, the `__TypeId__` and related headers is used.» Un listener que recibe una interfaz, por ejemplo `void onEvent(OrderEvent event)`, necesitaría la cabecera, y un mensaje de C# no se podría convertir. La solución es un tipo de parámetro concreto, un type mapper que asocie un `type` neutro a una clase, o que el productor en C# envíe `__TypeId__`, lo que lo acopla a los nombres de clases Java. No he ejecutado el caso que falla; el error de conversión que produce está *por verificar*.

</details>

2. Un colega guarda `delivery.Body` de `ReceivedAsync` en un `Channel<ReadOnlyMemory<byte>>` para que un worker en segundo plano lo analice. Las pruebas con un solo mensaje pasan. ¿Qué falla en producción, y cuál es la corrección más pequeña?

<details>
<summary>Solución</summary>

La memoria detrás de `delivery.Body` pertenece al cliente, y la [guía de migración](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/81622758098163d764ce13f13dce454310038948/v7-MIGRATION.md) dice que es «only valid for application use within the context of the executing ReceivedAsync event». En cuanto el handler termina, el búfer se puede reutilizar para la trama siguiente, así que el worker puede analizar los bytes de un mensaje posterior, o una mezcla. Un solo mensaje en una prueba lo oculta porque nada sobrescribe el búfer. La corrección más pequeña es encolar `delivery.Body.ToArray()`, una copia. El worker también debe confirmar a través del canal con el delivery tag, no desde otro canal, y preferiblemente solo después de un análisis correcto. No escribí un programa que muestre la corrupción: su salida no sería determinista.

</details>

3. El contenedor de listeners de Spring confirma cuando el método termina. El consumidor en C# de arriba confirma después de imprimir. Para cada uno, di qué le pasa a un mensaje si el proceso muere en mitad de su procesamiento, y si el handler lanza una excepción.

<details>
<summary>Solución</summary>

Muerto en mitad del procesamiento: en ambos casos el mensaje se entregó pero no se confirmó, así que el broker lo devuelve a la cola cuando se cierra la conexión y lo entrega de nuevo, con `redelivered` a `true`. La lección 4 lo muestra.

El handler lanza una excepción: el contenedor de Spring captura la excepción y rechaza el mensaje, devolviéndolo a la cola porque `defaultRequeueRejected` vale `true`, así que el mismo mensaje se vuelve a entregar, posiblemente en un bucle cerrado. En el cliente de C#, una excepción de `ReceivedAsync` se notifica mediante el evento `CallbackExceptionAsync` del canal y el mensaje no se confirma ni se rechaza: queda sin confirmar, y con un prefetch de 10 el consumidor se ralentiza y luego deja de recibir cuando hay diez mensajes atascados así, hasta que el canal se cierra y vuelven a la cola. Ese segundo comportamiento sale del código fuente y la documentación del cliente y está *por verificar* con un programa en la lección 6, que trata los fallos a propósito.

</details>

## Fuentes

- RabbitMQ: [guía de la API del cliente .NET](https://www.rabbitmq.com/client-libraries/dotnet-api-guide), [guía de migración del cliente .NET 7](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/81622758098163d764ce13f13dce454310038948/v7-MIGRATION.md), [guía de la API del cliente Java](https://www.rabbitmq.com/client-libraries/java-api-guide), [productores y propiedades de los mensajes](https://www.rabbitmq.com/docs/publishers), [consumidores](https://www.rabbitmq.com/docs/consumers)
- Código fuente del cliente .NET en v7.2.2: [`BasicDeliverEventArgs.cs`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/Events/BasicDeliverEventArgs.cs#L63-L81), [`Constants.cs`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/Constants.cs#L95), [`ConnectionFactory.cs`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/ConnectionFactory.cs#L168)
- Spring: [referencia de Spring AMQP](https://docs.spring.io/spring-amqp/reference/), [convertidores de mensajes](https://docs.spring.io/spring-amqp/reference/amqp/message-converters.html), [atributos de los contenedores de listeners](https://docs.spring.io/spring-amqp/reference/amqp/containerAttributes.html), [soporte de AMQP en Spring Boot](https://docs.spring.io/spring-boot/reference/messaging/amqp.html)
