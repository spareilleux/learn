---
title: 2. Topologie — exchanges, bindings et files
description: Les exchanges direct, fanout, topic et headers avec leurs règles de correspondance exactes, l'exchange par défaut et les exchanges prédéclarés, les messages que rien ne route (mandatory, basic.return, exchanges alternatifs), les bindings d'exchange à exchange, et l'erreur PRECONDITION_FAILED d'une déclaration non équivalente.
sidebar:
  order: 2
---

Exemple complet : [`L02.cs`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/csharp/L02.cs), et l'exemple topic avec le client Java dans [`L02.java`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/java/client/src/main/java/dev/learn/rabbitmq/L02.java). Chaque programme supprime et déclare sa topologie, publie quelques messages, puis vide chaque file avec `basic.get` et affiche les corps dans l'ordre de la file, pour que sa sortie montre exactement où chaque message est allé.

## Une topologie est une table de routage

Dans la leçon 1, le producteur choisissait une file par son nom. Dans la plupart des systèmes, il ne le devrait pas : le service qui émet « commande créée » ne sait pas, et ne devrait pas savoir, que la facturation, l'expédition et l'analytique veulent toutes une copie. La **topologie**, l'ensemble des exchanges, des files et des bindings, déplace ce savoir dans le broker. Le producteur nomme un exchange et décrit le message par une clé de routage ; la file de chaque consommateur est liée à l'exchange avec les clés qui l'intéressent.

Le [type d'exchange](https://www.rabbitmq.com/docs/exchanges) décide comment un binding correspond :

| Type | Un binding correspond quand | Usage typique |
|---|---|---|
| `direct` | sa clé est égale à la clé de routage | travail trié par catégorie : sévérité, client, région |
| `fanout` | toujours ; les clés sont ignorées | diffusion : invalidation de cache, mises à jour de prix |
| `topic` | son motif correspond à la clé de routage, mot par mot | événements : `order.created.eu` |
| `headers` | les en-têtes du message correspondent aux arguments du binding | routage sur plusieurs attributs à la fois |

Un exchange a aussi une **durabilité** (un exchange durable survit à un redémarrage), un indicateur **auto-delete** (supprimé quand son dernier binding disparaît), un indicateur **internal** (les producteurs ne peuvent pas y publier, seuls d'autres exchanges le peuvent) et des **arguments**, comme `alternate-exchange` plus bas. Les files ont les leurs : durable, **exclusive** (utilisée par une seule connexion et supprimée avec elle), auto-delete, et des arguments comme la limite de longueur de la leçon 4 ou le type de file de la leçon 5.

## Direct : des clés égales

```csharp
await channel.ExchangeDeclareAsync("logs.direct", ExchangeType.Direct, durable: true);
foreach (var queue in queues)
{
    await channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false);
}
// Une file peut avoir plusieurs bindings, et une clé peut être liée à plusieurs files.
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

`error message` est dans les deux files : un exchange dépose une copie dans chaque file ayant un binding qui correspond, et chaque file livre ensuite sa copie indépendamment. `debug message` n'est nulle part. Aucun binding n'a la clé `debug`, et le broker a jeté le message sans prévenir le producteur ; les dernières sections de cette leçon traitent ce cas.

## Fanout : toutes les files

```csharp
await channel.ExchangeDeclareAsync("prices.fanout", ExchangeType.Fanout, durable: true);
foreach (var queue in queues)
{
    await channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false);
    await channel.QueueBindAsync(queue, "prices.fanout", routingKey: "");
}

// La clé de routage est ignorée.
await channel.BasicPublishAsync("prices.fanout", "anything", Bytes("EURUSD 1.17"));
```

```text
prices.web: EURUSD 1.17
prices.mobile: EURUSD 1.17
prices.audit: EURUSD 1.17
```

Un exchange fanout est le moins coûteux à router, puisqu'il ne compare rien. C'est le publish/subscribe sous sa forme la plus simple : ajouter un abonné revient à déclarer une file et à la lier, sans toucher au producteur.

## Topic : des motifs sur des mots

Un exchange topic découpe la clé de routage et le motif du binding en **mots** à chaque point. Dans le motif, `*` correspond à exactement un mot et `#` à zéro mot ou plus. Quatre bindings et six clés :

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

Le corps de chaque message est sa clé de routage, donc la sortie se lit comme une table de routage :

- `order` seul correspond à `order.#`, car `#` peut correspondre à zéro mot, mais pas à `order.*`, qui exige exactement un mot de plus.
- `eu` seul correspond à `#.eu` pour la même raison.
- `order.created.eu` correspond à trois motifs et arrive dans trois files, une fois dans chacune.
- `order.shipped.us` ne correspond qu'à `order.#` : `*.created.*` veut `created` comme deuxième mot.

Les clés topic sont la conception habituelle pour des événements. Une forme comme `<entité>.<événement>.<région>` laisse chaque consommateur choisir ce qu'il veut, de `order.created.eu` à `#`. Les mots sont comparés tels quels, casse comprise, et une clé est limitée à 255 octets.

Le même exemple avec le client Java affiche les mêmes lignes, et `check.sh` compare sa sortie avec le même fichier attendu. Les méthodes se correspondent une à une :

| C# (`IChannel`) | Java (`Channel`) |
|---|---|
| `ExchangeDeclareAsync("events.topic", ExchangeType.Topic, durable: true)` | `exchangeDeclare("events.topic", BuiltinExchangeType.TOPIC, true)` |
| `QueueDeclareAsync(name, durable: true, exclusive: false, autoDelete: false)` | `queueDeclare(name, true, false, false, null)` |
| `QueueBindAsync(queue, exchange, pattern)` | `queueBind(queue, exchange, pattern)` |
| `BasicPublishAsync(exchange, key, body)` | `basicPublish(exchange, key, null, body)` |
| `BasicGetAsync(queue, autoAck: true)` | `basicGet(queue, true)` |

## Headers : plusieurs attributs

Un exchange headers ignore la clé de routage. Ses bindings portent des arguments, et l'argument spécial `x-match` dit comment les comparer aux en-têtes du message : `all` exige que chaque autre argument soit présent avec la même valeur, `any` en exige au moins un.

```csharp
// x-match all : chaque en-tête listé doit correspondre. x-match any : un seul suffit.
await channel.QueueBindAsync("reports.pdf", "documents.headers", "", new Dictionary<string, object?>
{
    ["x-match"] = "all", ["type"] = "report", ["format"] = "pdf",
});
await channel.QueueBindAsync("reports.any", "documents.headers", "", new Dictionary<string, object?>
{
    ["x-match"] = "any", ["type"] = "report", ["format"] = "pdf",
});
```

Quatre documents, publiés avec les en-têtes `type` et `format` :

```text
reports.pdf: report/pdf
reports.any: report/pdf | report/csv | invoice/pdf
```

Les exchanges headers sont rarement nécessaires : une clé topic comme `report.pdf` fait souvent le même travail plus vite. Ils servent quand les attributs sont optionnels ou sans ordre. Le fichier [`rabbit_exchange_type_headers.erl`](https://github.com/rabbitmq/rabbitmq-server/blob/0dde27bfdd1984ff7e157226fd97656854a7f359/deps/rabbit/src/rabbit_exchange_type_headers.erl#L36-L66) du serveur montre deux détails que le tableau ne peut pas montrer : un binding sans `x-match` se comporte comme `all`, et `all` et `any` tout court ignorent chaque argument de binding dont le nom commence par `x-`, donc ils ne peuvent pas filtrer sur de tels en-têtes. Les deux autres valeurs acceptées, `all-with-x` et `any-with-x`, les comparent aussi.

## Ce qu'un broker contient déjà

Un nouveau virtual host n'est pas vide. `rabbitmqctl list_exchanges` montre l'exchange par défaut (le nom vide) et les exchanges prédéclarés `amq.*`, un par type, qu'une application peut utiliser mais pas supprimer. Après avoir exécuté les programmes de cette leçon :

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

`rabbitmqctl list_bindings` montre comment fonctionne l'exchange par défaut : un binding par file, depuis l'exchange au nom vide, avec le nom de la file comme clé. Un extrait, dans l'ordre où la commande l'a affiché, qui n'est pas un ordre stable :

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

L'interface de gestion montre la même chose sur la page de chaque exchange, avec un diagramme de ses bindings.

## Quand rien ne correspond

Un message qui ne correspond à aucun binding est jeté. Le producteur a trois façons de s'en apercevoir ou de l'éviter, et [`Unroutable`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/csharp/L02.cs) montre chacune sur un exchange direct lié seulement à `invoice` :

```csharp
// 1. mandatory: false (par défaut) : le broker jette le message sans rien dire.
await channel.BasicPublishAsync("billing.direct", "refund", Bytes("refund #1"));

// 2. mandatory: true : le broker renvoie le message avec basic.return.
var returned = new TaskCompletionSource<BasicReturnEventArgs>();
channel.BasicReturnAsync += (_, args) =>
{
    returned.TrySetResult(args);
    return Task.CompletedTask;
};
await channel.BasicPublishAsync("billing.direct", "refund", mandatory: true, new BasicProperties(), Bytes("refund #2"));

// 3. Un exchange alternatif reçoit tout ce que l'exchange principal ne peut pas router. C'est un argument, fixé à la déclaration.
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

- **`mandatory`** est un indicateur de chaque publication. Quand il est positionné et qu'aucune file ne correspond, le broker renvoie le message entier avec [`basic.return`](https://www.rabbitmq.com/amqp-0-9-1-reference) et le code de réponse 312 `NO_ROUTE`. Le producteur l'apprend de façon asynchrone, par l'événement `BasicReturnAsync` en C# ou un `ReturnListener` en Java, et doit donc rapprocher le message renvoyé de ce qu'il a envoyé ; la leçon 4 montre comment les confirmations de publication simplifient cela.
- Un **[exchange alternatif](https://www.rabbitmq.com/docs/ae)** se déclare sur l'exchange lui-même. Ce que celui-ci ne peut pas router part vers l'exchange alternatif, ici un fanout lié à une file `billing.unrouted`, où quelqu'un peut l'examiner. Les arguments font partie de l'identité d'un exchange, donc en ajouter un a obligé à supprimer et redéclarer `billing.direct` ; une [politique](https://www.rabbitmq.com/docs/policies) peut fixer `alternate-exchange` sur des exchanges existants sans cela, et la documentation recommande les politiques pour cette raison.

## Quand les déclarations divergent

Déclarer n'est idempotent que si les paramètres sont les mêmes. Le programme déclare `hello` comme la leçon 1, puis de nouveau avec `durable: false` :

```text
OperationInterruptedException: The AMQP operation was interrupted: AMQP close-reason, initiated by Peer, code=406, text='PRECONDITION_FAILED - inequivalent arg 'durable' for queue 'hello' in vhost '/': received 'false' but current is 'true'', classId=50, methodId=10
channel open: False, connection open: True
new channel: queue hello exists
```

Le broker a comparé la nouvelle déclaration à la file existante, dans [`rabbit_misc:equivalence_fail`](https://github.com/rabbitmq/rabbitmq-server/blob/0dde27bfdd1984ff7e157226fd97656854a7f359/deps/rabbit_common/src/rabbit_misc.erl#L340-L343), et a répondu par l'erreur 406 `PRECONDITION_FAILED`. AMQP 0-9-1 a deux sortes d'erreurs. Une **erreur de canal** comme 406, ou 404 `NOT_FOUND`, ferme le canal où elle s'est produite et rien d'autre ; une **erreur de connexion** comme 541 `INTERNAL_ERROR` ferme toute la connexion. Les identifiants de classe et de méthode, 50 et 10, désignent `queue.declare` dans la [référence du protocole](https://www.rabbitmq.com/amqp-0-9-1-reference). Les conséquences pratiques :

- Un canal fermé ne peut pas être réutilisé. Après avoir intercepté l'exception, ouvrez un nouveau canal sur la même connexion, comme le fait le programme.
- L'erreur nomme la propriété qui diffère, ce qui permet de trouver deux services qui déclarent la même file différemment, une source courante de cette erreur après un déploiement. Une issue consiste à ne laisser qu'une seule partie, ou un [fichier de définitions](https://www.rabbitmq.com/docs/definitions) déployé par l'exploitation, déclarer la topologie partagée, et à faire déclarer les autres en mode passif (`QueueDeclarePassiveAsync`), qui vérifie seulement que la file existe.

## Bindings d'exchange à exchange

RabbitMQ étend AMQP 0-9-1 avec des [bindings d'un exchange vers un autre exchange](https://www.rabbitmq.com/docs/e2e). Un message routé vers l'exchange de destination est alors routé de nouveau par les bindings propres à cet exchange. L'exercice 3 en utilise un.

## À retenir

- Les producteurs nomment un exchange et une clé de routage ; les bindings décident quelles files reçoivent une copie, une copie par file qui correspond.
- Direct compare les clés, fanout les ignore, topic applique des motifs de mots où `*` vaut un mot et `#` zéro mot ou plus, et headers compare les valeurs d'en-têtes avec `x-match` à `all` ou `any`.
- Un message que rien ne route est jeté en silence, sauf s'il est publié avec `mandatory` (il revient avec `basic.return` 312 `NO_ROUTE`) ou si l'exchange a un exchange alternatif, fixé de préférence par une politique.
- Redéclarer avec d'autres paramètres ferme le canal avec 406 `PRECONDITION_FAILED` ; la connexion reste ouverte. Décidez à qui appartiennent les déclarations partagées.
- Chaque virtual host a l'exchange par défaut, lié à chaque file par son nom, et les exchanges prédéclarés `amq.*`.

## Exercices

1. Avec les quatre bindings topic de cette leçon, prédisez quelles files reçoivent les clés `order.created.us.west`, `created.eu`, `order..eu`, `Order.created.eu` et `eu.order`.

<details>
<summary>Solution</summary>

`l02-exercise-topic` les publie vers les mêmes bindings :

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

- `order.created.us.west` a quatre mots : `order.#` en accepte un nombre quelconque après `order`, tandis que `*.created.*` veut exactement trois mots.
- `created.eu` a deux mots, donc `*.created.*` ne correspond pas ; `#.eu` correspond, `#` valant `created`.
- `order..eu` a trois mots, celui du milieu vide. Un mot vide reste un mot : `order.#` et `#.eu` correspondent, et `order.*` non, car il veut deux mots.
- `Order.created.eu` ne correspond pas à `order.#` : la correspondance est sensible à la casse. Il correspond aux deux motifs qui ne nomment pas `order`.
- `eu.order` ne correspond à rien, puisque `#.eu` veut `eu` à la fin. Il a été jeté.

</details>

2. L'exemple direct liait `logs.all` trois fois, une par sévérité. Un collègue propose un exchange fanout pour `logs.all` et un exchange direct pour `logs.errors`, tous deux alimentés par le producteur. Que doit changer le producteur, et qu'offre à la place le binding d'exchange à exchange de l'exercice 3 ?

<details>
<summary>Solution</summary>

Avec deux exchanges, le producteur doit publier chaque erreur deux fois, une vers chaque exchange, et un nouveau consommateur avec un autre besoin signifie un exchange de plus et une modification de plus du producteur : la décision de routage est revenue dans l'application. Garder un exchange par sorte de message, et exprimer l'intérêt de chaque consommateur par des bindings, permet d'ajouter des consommateurs sans toucher aux producteurs. Si un groupe de files a besoin de tout, liez un exchange fanout à l'exchange principal avec `#` (pour un exchange topic) et liez ces files au fanout : le producteur publie toujours une seule fois.

</details>

3. Sans changer les producteurs d'un exchange `shop.topic`, donnez à une file `audit.log` une copie de chaque message qui y est publié, y compris ceux dont aucune autre file ne veut. Déclarez le côté audit comme un exchange fanout lié à `shop.topic`.

<details>
<summary>Solution</summary>

```csharp
await channel.ExchangeDeclareAsync("shop.topic", ExchangeType.Topic, durable: true);
await channel.ExchangeDeclareAsync("audit.fanout", ExchangeType.Fanout, durable: true);
await channel.QueueDeclareAsync("shop.orders", durable: true, exclusive: false, autoDelete: false);
await channel.QueueDeclareAsync("audit.log", durable: true, exclusive: false, autoDelete: false);
await channel.QueueBindAsync("shop.orders", "shop.topic", "order.*");
await channel.QueueBindAsync("audit.log", "audit.fanout", "");
// destination, source, motif : les messages passent de shop.topic à audit.fanout quand le motif correspond.
await channel.ExchangeBindAsync(destination: "audit.fanout", source: "shop.topic", routingKey: "#");
```

```text
shop.orders: order.created
audit.log: order.created | user.signed-up
```

`user.signed-up` ne correspondait à aucun binding de file, mais il correspondait au binding d'exchange `#`, donc la file d'audit l'a reçu. `ExchangeBindAsync` prend la destination en premier, comme `QueueBindAsync` prend la file en premier ; en Java, c'est `exchangeBind(destination, source, routingKey)`. Un exchange alternatif n'aurait attrapé que le message non routable, pas les copies des messages routés.

</details>

## Sources

- RabbitMQ : [exchanges](https://www.rabbitmq.com/docs/exchanges), [files](https://www.rabbitmq.com/docs/queues), [exchanges alternatifs](https://www.rabbitmq.com/docs/ae), [bindings d'exchange à exchange](https://www.rabbitmq.com/docs/e2e), [politiques](https://www.rabbitmq.com/docs/policies), [définitions](https://www.rabbitmq.com/docs/definitions), [producteurs et messages non routables](https://www.rabbitmq.com/docs/publishers#unroutable), [tutoriel quatre (routage)](https://www.rabbitmq.com/tutorials/tutorial-four-dotnet) et [tutoriel cinq (topics)](https://www.rabbitmq.com/tutorials/tutorial-five-dotnet)
- [Référence complète d'AMQP 0-9-1](https://www.rabbitmq.com/amqp-0-9-1-reference) : `queue.declare`, `basic.return`, codes de réponse
- Source du serveur en v4.3.5 : [`rabbit_exchange_type_headers.erl`](https://github.com/rabbitmq/rabbitmq-server/blob/0dde27bfdd1984ff7e157226fd97656854a7f359/deps/rabbit/src/rabbit_exchange_type_headers.erl), [`rabbit_misc.erl`](https://github.com/rabbitmq/rabbitmq-server/blob/0dde27bfdd1984ff7e157226fd97656854a7f359/deps/rabbit_common/src/rabbit_misc.erl#L340-L343)
