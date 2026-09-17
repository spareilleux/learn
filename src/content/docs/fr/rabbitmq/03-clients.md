---
title: 3. Clients en C#, en Java et avec Spring AMQP
description: RabbitMQ.Client 7 et son API asynchrone, le client Java, et le RabbitTemplate et le @RabbitListener de Spring AMQP qui échangent les mêmes commandes JSON — règles des connexions et des canaux, propriétés des messages, threads des consommateurs et durée de vie du corps, et l'en-tête __TypeId__ de Spring.
sidebar:
  order: 3
---

Exemple complet : [`L03.cs`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/csharp/L03.cs), [`L03.java`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/java/client/src/main/java/dev/learn/rabbitmq/L03.java), et l'application Spring Boot dans [`java/spring`](https://github.com/spareilleux/learn/tree/main/code/rabbitmq/java/spring). [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/check.sh) les exécute par paires : les messages de chaque producteur sont lus par un consommateur écrit dans un autre langage.

## Une topologie, trois clients

Les trois programmes partagent un exchange topic `orders.topic` et une file `orders.billing` qui lui est liée avec `order.#`. Chacun déclare cette topologie lui-même, avec les mêmes paramètres, pour qu'aucun ne dépende du démarrage préalable d'un autre. La version C# :

```csharp
// Chaque client déclare la même topologie avec les mêmes paramètres : peu importe lequel démarre en premier.
public static async Task DeclareAsync(IChannel channel)
{
    await channel.ExchangeDeclareAsync("orders.topic", ExchangeType.Topic, durable: true);
    await channel.QueueDeclareAsync("orders.billing", durable: true, exclusive: false, autoDelete: false);
    await channel.QueueBindAsync("orders.billing", "orders.topic", "order.#");
}
```

Ce sur quoi ils doivent s'accorder en plus de la topologie, c'est le **message** : le format de son corps et ses propriétés.

## Propriétés des messages

Un message AMQP 0-9-1 a un corps, que le broker ne lit jamais, et un ensemble de [propriétés](https://www.rabbitmq.com/docs/publishers#message-properties) que lisent les consommateurs, et dans certains cas le broker :

| Propriété | Signification | Lue par le broker ? |
|---|---|---|
| `content_type`, `content_encoding` | le format du corps, par exemple `application/json` | non |
| `delivery_mode` | 2 pour persistant, 1 pour transitoire (leçon 4) | oui |
| `message_id` | un identifiant choisi par le producteur | non ; les consommateurs s'en servent pour dédoublonner |
| `correlation_id`, `reply_to` | requête/réponse (leçon 7) | non |
| `type`, `app_id` | la sorte de message et l'application émettrice | non |
| `timestamp` | une heure choisie par le producteur, en secondes | non |
| `expiration` | un TTL par message (leçon 6) | oui |
| `priority` | pour les files à priorité | oui |
| `headers` | une table de clés à vous, utilisée aussi par les exchanges headers | par les exchanges headers |

Le producteur C# en fixe la plupart sur un objet [`BasicProperties`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/BasicProperties.cs) :

```csharp
Order[] orders = [new("A-1", "GUITAR-STRINGS", 2), new("A-2", "CAPO", 1), new("A-3", "PICKS", 12)];
foreach (var order in orders)
{
    // BasicProperties est l'enveloppe : des métadonnées que le broker et le consommateur lisent sans analyser le corps.
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

`Json` vaut `new JsonSerializerOptions(JsonSerializerDefaults.Web)`, qui écrit les noms en camelCase, la convention que suit Jackson en Java.

## Le client Java les lit

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

Le record `Order(String id, String sku, int quantity)` est lu avec le `JsonMapper` de Jackson 3. Deux lignes annoncent la leçon 4 : `basicAck` indique au broker que le message est traité, parce que ce consommateur a passé `false` pour l'acquittement automatique, et `basicQos(10)` ne laisse arriver au plus que dix messages non acquittés à la fois. Le **delivery tag**, de `#1` à `#3`, numérote les livraisons sur ce canal ; c'est à lui que se réfère un acquittement.

Le sens inverse fonctionne de la même façon. Le producteur Java construit ses propriétés avec `AMQP.BasicProperties.Builder`, et le consommateur C# les affiche :

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

## RabbitMQ.Client 7 en pratique

La version 7 du client .NET a réécrit l'API autour d'`async`/`await`. Le [guide de migration](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/81622758098163d764ce13f13dce454310038948/v7-MIGRATION.md) liste les changements qui cassent le code écrit pour la version 6 ou copié de réponses plus anciennes : `IModel` est devenu `IChannel`, chaque méthode a gagné une forme `Async` et perdu sa forme synchrone, `CreateBasicProperties()` a laissé place à `new BasicProperties()`, et les corps de message sont devenus des `ReadOnlyMemory<byte>`. Le consommateur C# :

```csharp
var consumer = new AsyncEventingBasicConsumer(channel);
consumer.ReceivedAsync += async (_, delivery) =>
{
    // Le corps n'est valide que pendant le callback : le client réutilise son buffer. Le désérialiser ou le copier ici.
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

Quatre règles viennent avec, et chacune a déjà piégé quelqu'un :

- **Le corps ne survit pas au callback.** `delivery.Body` pointe dans un buffer que le client loue et réutilise. La documentation de [`BasicDeliverEventArgs`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/Events/BasicDeliverEventArgs.cs#L63-L81) dit que l'utiliser hors de `ReceivedAsync` « requires that it be copied », avec `Body.ToArray()`. Désérialiser dans le callback, comme ici, est la réponse habituelle ; mettre `delivery.Body` dans une liste ou un canal pour plus tard est un bug qui se manifeste par des messages corrompus sous charge.
- **Les callbacks s'exécutent un par un par défaut.** [`ConsumerDispatchConcurrency`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/Constants.cs#L95) vaut 1 par défaut : le client attend chaque handler avant d'appeler le suivant, et les messages sont traités dans l'ordre de livraison. Une valeur plus élevée sur la `ConnectionFactory` ou dans `CreateChannelOptions` traite les messages en parallèle et renonce à cet ordre ; le handler doit alors être thread-safe. C'est pourquoi `--remaining` ci-dessus n'a besoin d'aucun verrou.
- **Ne publiez pas en parallèle sur un même canal.** Le [guide du client .NET](https://www.rabbitmq.com/client-libraries/dotnet-api-guide#concurrency-channel-sharing) dit explicitement que partager un canal entre producteurs concurrents « will lead to incorrect frame interleaving at the protocol level ». Utilisez un canal par tâche de publication, ou un petit pool.
- **Les connexions se rétablissent, pas votre travail en cours.** `AutomaticRecoveryEnabled` et `TopologyRecoveryEnabled` valent tous deux `true` dans [`ConnectionFactory`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/ConnectionFactory.cs#L168) : après une panne réseau, le client se reconnecte, rouvre les canaux, redéclare ce qu'il avait déclaré et relance les consommateurs. Les livraisons non acquittées du canal perdu retournent dans la file, et leurs delivery tags ne veulent rien dire sur le nouveau canal. La reprise automatique est aussi *à vérifier* dans la CI de ce cours : la leçon 4 redémarre le broker, mais ses programmes se reconnectent en redémarrant.

Le client Java a les mêmes règles avec des appels bloquants. Son [guide de l'API](https://www.rabbitmq.com/client-libraries/java-api-guide#concurrency) dit d'éviter de partager un `Channel` entre threads, et que publier en parallèle sur un même canal « can result in incorrect frame interleaving on the wire » ; les callbacks des consommateurs s'exécutent sur un pool de threads distinct de l'appelant, et « each Channel will dispatch all deliveries to its Consumer handler methods on it in order ». La reprise automatique est activée par défaut depuis la version 4.0 du client Java.

## Spring AMQP

[Spring AMQP](https://docs.spring.io/spring-amqp/reference/) enveloppe le client Java à la manière de Spring : un template pour envoyer, des méthodes annotées pour recevoir, des beans pour déclarer. Avec `spring-boot-starter-amqp`, Spring Boot [configure automatiquement](https://docs.spring.io/spring-boot/reference/messaging/amqp.html) une `CachingConnectionFactory` à partir des propriétés `spring.rabbitmq.*`, un `RabbitTemplate`, un `RabbitAdmin` et une fabrique de conteneurs de listeners. La [leçon 1 du cours Spring](../../spring-cloud-reactor/01-spring-boot-from-aspnet-core/) explique les beans, l'auto-configuration et les profils, que cette application utilise sans autre commentaire.

La topologie tient en trois beans. `RabbitAdmin` déclare chaque bean `Exchange`, `Queue` et `Binding` quand l'application ouvre sa première connexion :

```java
// La même topologie que les exemples C# et client Java, déclarée par RabbitAdmin à l'ouverture de la première connexion.
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

// Remplace le convertisseur par défaut (byte[], String et sérialisation Java) pour RabbitTemplate et @RabbitListener.
@Bean
MessageConverter jsonMessageConverter() {
    return new JacksonJsonMessageConverter();
}
```

`new Queue("orders.billing")` et `new TopicExchange("orders.topic")` sont durables et non auto-delete par défaut, les mêmes paramètres que les autres clients ; à la moindre différence, la déclaration échouerait avec le `PRECONDITION_FAILED` de la leçon 2. Sans le bean de conversion, `RabbitTemplate` utiliserait le `SimpleMessageConverter`, qui envoie un objet Java `Serializable` avec la sérialisation Java : illisible depuis C# et un risque de sécurité connu. [`JacksonJsonMessageConverter`](https://docs.spring.io/spring-amqp/reference/amqp/message-converters.html) est le convertisseur Jackson 3 de Spring AMQP 4 ; celui de Jackson 2, `Jackson2JsonMessageConverter`, est déprécié.

### Le listener reçoit les commandes C#

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

Il n'y a pas de `basicAck` dans la méthode. Le conteneur de listeners consomme avec des acquittements manuels et acquitte à votre place : dans le [mode d'acquittement](https://docs.spring.io/spring-amqp/reference/amqp/containerAttributes.html) par défaut, `AUTO`, il acquitte quand la méthode se termine et rejette quand elle lève une exception, avec `defaultRequeueRejected` à `true`, donc un message qui échoue toujours revient indéfiniment. La leçon 6 casse cette boucle avec le dead lettering. Le prefetch par défaut du conteneur est de 250.

### Le consommateur C# reçoit les commandes Spring

`RabbitTemplate.convertAndSend` convertit l'objet, et un post-processeur de message fixe les autres propriétés :

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

Le convertisseur Jackson a ajouté un en-tête `__TypeId__` avec le nom de la classe Java, `$` compris pour un record imbriqué. Un consommateur C# peut l'ignorer ; un consommateur Spring ne s'en sert que quand le type du paramètre du listener ne dit pas quoi créer (exercice 1). Un nom de classe Java dans un message est un couplage entre services, et la [documentation des convertisseurs de messages](https://docs.spring.io/spring-amqp/reference/amqp/message-converters.html) montre comment associer les noms de classes à des identifiants neutres avec le type mapper du convertisseur quand cela compte.

## Le contrat entre langages

Ce qui a fait fonctionner ces six échanges tient en une courte liste, qui vaut d'être écrite pour toute file partagée entre équipes :

- l'exchange, son type, les clés de routage et les paramètres de la file, identiques partout où ils sont déclarés ;
- un format de corps avec un `content_type`, ici du JSON avec des noms en camelCase ;
- un `message_id` sur chaque message, dont la leçon 4 a besoin pour l'idempotence ;
- un `type` qui nomme le message indépendamment des noms de classes de tout langage.

## À retenir

- Une connexion de longue durée par application, un canal par thread ou par tâche, et jamais deux producteurs concurrents sur un même canal.
- RabbitMQ.Client 7 est asynchrone : `IChannel`, `BasicPublishAsync`, `AsyncEventingBasicConsumer`. Le corps n'est valide que dans le callback, et les callbacks s'exécutent un par un sauf si vous augmentez `ConsumerDispatchConcurrency`.
- Les propriétés d'un message portent ce dont un consommateur a besoin sans analyser le corps : type de contenu, identifiant, type, en-têtes. Le broker n'en lit que quelques-unes, comme le mode de livraison et l'expiration.
- Spring AMQP déclare les beans `Exchange`, `Queue` et `Binding` par `RabbitAdmin`, convertit les corps avec un `MessageConverter` (configurez-en un pour JSON) et acquitte automatiquement les messages d'un `@RabbitListener` quand la méthode se termine.
- L'interopérabilité est un contrat sur la topologie et le format des messages, pas sur les bibliothèques clientes.

## Exercices

1. Le listener a affiché `__TypeId__=null` pour les messages C#, et pourtant il a créé des records `Order`. D'où venait le type, et quand ce même listener échouerait-il à convertir un message sans cet en-tête ?

<details>
<summary>Solution</summary>

Du paramètre de la méthode. Le `TypePrecedence` du convertisseur vaut `INFERRED` par défaut : la [documentation des convertisseurs de messages](https://docs.spring.io/spring-amqp/reference/amqp/message-converters.html) dit que le type inféré « will override the inbound `__TypeId__` and related headers created by the sending system », ce qui « applies only if the parameter type is concrete (not abstract or an interface), or it is from the `java.util` package. In all other cases, the `__TypeId__` and related headers is used. » Un listener qui prend une interface, disons `void onEvent(OrderEvent event)`, aurait besoin de l'en-tête, et un message venu de C# ne pourrait pas être converti. La solution est soit un type de paramètre concret, soit un type mapper qui associe un `type` neutre à une classe, soit un producteur C# qui envoie `__TypeId__`, ce qui le couple aux noms de classes Java. Je n'ai pas exécuté le cas en échec ; l'erreur de conversion qu'il produit est *à vérifier*.

</details>

2. Un collègue range `delivery.Body` reçu dans `ReceivedAsync` dans un `Channel<ReadOnlyMemory<byte>>` pour qu'un worker en arrière-plan l'analyse. Les tests avec un seul message passent. Qu'est-ce qui casse en production, et quel est le plus petit correctif ?

<details>
<summary>Solution</summary>

La mémoire derrière `delivery.Body` appartient au client, et le [guide de migration](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/81622758098163d764ce13f13dce454310038948/v7-MIGRATION.md) dit qu'elle n'est « only valid for application use within the context of the executing ReceivedAsync event ». Une fois le handler terminé, le buffer peut être réutilisé pour la trame suivante, donc le worker risque d'analyser les octets d'un message ultérieur, ou un mélange. Un seul message dans un test le masque, car rien n'écrase le buffer. Le plus petit correctif est de mettre en file `delivery.Body.ToArray()`, une copie. Le worker doit aussi acquitter par le canal avec le delivery tag, pas depuis un autre canal, et de préférence seulement après une analyse réussie. Je n'ai pas écrit de programme qui montre la corruption : sa sortie ne serait pas déterministe.

</details>

3. Le conteneur de listeners de Spring acquitte quand la méthode se termine. Le consommateur C# ci-dessus acquitte après l'affichage. Pour chacun, dites ce qui arrive à un message si le processus est tué au milieu de son traitement, et si le handler lève une exception.

<details>
<summary>Solution</summary>

Tué en plein traitement : dans les deux cas, le message a été livré mais pas acquitté, donc le broker le remet dans la file quand la connexion se ferme et le livre de nouveau, avec `redelivered` à `true`. La leçon 4 le montre.

Le handler lève une exception : le conteneur de Spring intercepte l'exception et rejette le message en le remettant dans la file, parce que `defaultRequeueRejected` vaut `true`, donc le même message est relivré, éventuellement en boucle serrée. Dans le client C#, une exception de `ReceivedAsync` est signalée par l'événement `CallbackExceptionAsync` du canal et le message n'est ni acquitté ni rejeté : il reste non acquitté, et avec un prefetch de 10 le consommateur ralentit puis cesse de recevoir une fois dix messages bloqués ainsi, jusqu'à ce que le canal se ferme et qu'ils soient remis dans la file. Ce second comportement vient du code source et de la documentation du client et est *à vérifier* avec un programme dans la leçon 6, qui traite les échecs à dessein.

</details>

## Sources

- RabbitMQ : [guide de l'API du client .NET](https://www.rabbitmq.com/client-libraries/dotnet-api-guide), [guide de migration du client .NET 7](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/81622758098163d764ce13f13dce454310038948/v7-MIGRATION.md), [guide de l'API du client Java](https://www.rabbitmq.com/client-libraries/java-api-guide), [producteurs et propriétés des messages](https://www.rabbitmq.com/docs/publishers), [consommateurs](https://www.rabbitmq.com/docs/consumers)
- Source du client .NET en v7.2.2 : [`BasicDeliverEventArgs.cs`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/Events/BasicDeliverEventArgs.cs#L63-L81), [`Constants.cs`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/Constants.cs#L95), [`ConnectionFactory.cs`](https://github.com/rabbitmq/rabbitmq-dotnet-client/blob/740faf07f04ade7d35d3539e20613c6ac6b9b46f/projects/RabbitMQ.Client/ConnectionFactory.cs#L168)
- Spring : [référence de Spring AMQP](https://docs.spring.io/spring-amqp/reference/), [convertisseurs de messages](https://docs.spring.io/spring-amqp/reference/amqp/message-converters.html), [attributs des conteneurs de listeners](https://docs.spring.io/spring-amqp/reference/amqp/containerAttributes.html), [prise en charge d'AMQP dans Spring Boot](https://docs.spring.io/spring-boot/reference/messaging/amqp.html)
