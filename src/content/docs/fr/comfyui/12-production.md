---
title: '12. ComfyUI en production : un service, une file d''attente, plusieurs GPU'
description: 'Faire de ComfyUI un service de rendu — ce que son serveur fournit (un prompt à la fois, /prompt, /queue, /history, /interrupt, des identifiants de prompt jamais dédoublonnés) et ce qu''il ne fournit pas, puis un worker en C# et en Java qui prend des jobs dans une file, les exécute sur un pool de GPU choisis selon la longueur de leur file, réessaie avec backoff, envoie aux lettres mortes ce qui ne marchera jamais, interrompt à l''expiration du délai, rattrape une connexion WebSocket perdue et n''exécute chaque job qu''une fois ; testé contre un faux ComfyUI construit à partir de réponses enregistrées, sur trois OS et contre un vrai ComfyUI sur CPU, avec des notes de déploiement et l''expérience du labo GA sous forme de lot de jobs.'
sidebar:
  order: 12
---

Code : le worker en C# dans [`worker/csharp/ComfyWorker/`](https://github.com/spareilleux/learn/tree/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker) et en Java dans [`worker/java/`](https://github.com/spareilleux/learn/tree/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/java/src/main/java/dev/learn/comfy/worker), le faux serveur dans [`worker/csharp/FakeComfy/`](https://github.com/spareilleux/learn/tree/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/FakeComfy) avec les réponses qu'il rejoue dans [`worker/data/recorded/`](https://github.com/spareilleux/learn/tree/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/data/recorded), les tests, les fichiers de jobs et les transcriptions attendues, le tout lancé par [`worker/check.sh`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/check.sh) et le workflow [`comfyui-worker-examples.yml`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/.github/workflows/comfyui-worker-examples.yml).

La leçon 4 envoyait un prompt et l'attendait. Un service reçoit des prompts de nombreux clients, à tout moment, et doit tenir ses promesses quand un serveur répond 500, qu'un WebSocket se coupe, qu'un GPU manque de mémoire, qu'un prompt ne se termine jamais ou qu'un worker est arrêté au milieu d'un job. Le serveur de ComfyUI ne gère rien de tout cela à votre place : il exécute un prompt à la fois et ne vérifie rien pour vous. Cette leçon lit ce que le serveur fournit vraiment, construit un worker autour en C# et en Java, et teste chaque panne sans GPU.

## L'architecture

```mermaid
flowchart LR
  C1[Client] --> API[API du service]
  C2[Client] --> API
  API -->|job : id + workflow| Q[(File de jobs)]
  Q --> W1[Worker 1]
  Q --> W2[Worker 2]
  W1 --> G0[ComfyUI sur le GPU 0]
  W1 --> G1[ComfyUI sur le GPU 1]
  W2 --> G2[ComfyUI sur le GPU 2]
  W1 --> S[(Stockage des résultats)]
  W2 --> S
  Q -.->|échec définitif| D[(Lettres mortes)]
  API -.->|lit statuts et fichiers| S
```

- Les **clients** ne parlent jamais à ComfyUI. Ils envoient un job à l'**API du service** et lisent son résultat plus tard. ComfyUI n'a pas d'authentification, et sa file est commune à tout le serveur.
- La **file de jobs** garde les jobs jusqu'à ce qu'un worker en prenne un, et rend un job si le worker meurt avant d'en accuser réception. Dans cette leçon, c'est une file en mémoire pour les tests et une seule machine, puis [RabbitMQ](../../rabbitmq/).
- Un **worker** prend autant de jobs qu'il a de GPU, envoie chacun à **un processus ComfyUI par GPU**, le suit, et télécharge les sorties.
- Le **stockage des résultats** garde les fichiers et un enregistrement de chaque job terminé. C'est aussi lui qui garantit qu'un job ne s'exécute qu'une fois.
- Les **lettres mortes** sont les jobs en échec définitif, avec leur raison, pour qu'une personne ou un programme les examine.

## Ce que ComfyUI fournit lui-même

Tout ce qui suit est lu dans ComfyUI v0.36.0, commit [`ee71d5c`](https://github.com/Comfy-Org/ComfyUI/tree/ee71d5c4993f29086b27fde1629a945ae48425bf).

### Un prompt à la fois

`main.py` démarre un seul thread [`prompt_worker`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L319-L397) ([ligne 529](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L529)). Il prend l'élément suivant dans la [`PromptQueue`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L1286-L1341), un tas trié par numéro de prompt, l'exécute avec [`e.execute`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L362), écrit l'historique avec [`task_done`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L367-L372), et envoie `executing` avec `node: null` ([lignes 373 et 374](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L373-L374)). Un serveur, un prompt en cours : pour utiliser deux GPU en parallèle, on démarre deux serveurs. Un second prompt envoyé à un serveur occupé attend dans sa file, et un client ne peut pas savoir combien de temps d'après la réponse de `POST /prompt`.

### Les routes qu'utilise un worker

| Route | Ce que le worker en fait | `server.py` |
|---|---|---|
| `GET /ws?clientId=…` | reçoit les événements des prompts qu'il a mis en file avec cet identifiant de client | [269-327](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L269-L327) |
| `POST /prompt` | met un prompt en file avec son propre `prompt_id` ; 200 avec `number`, ou 400 avec `error` et `node_errors` | [1075-1147](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1075-L1147) |
| `GET /queue` | ce prompt est-il en cours ou en attente, et combien de prompts le précèdent | [1067-1073](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1067-L1073) |
| `POST /queue` avec `delete` | retire un prompt en attente | [1149-1161](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1149-L1161) |
| `GET /history/{prompt_id}` | les sorties et le statut d'un prompt terminé | [1048-1065](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1048-L1065) |
| `POST /interrupt` avec `prompt_id` | arrête ce prompt s'il est celui en cours | [1163-1193](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1163-L1193) |
| `POST /free` | décharge les modèles et libère la mémoire au prochain moment libre | [1195-1204](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1195-L1204) |
| `GET /system_stats` | le serveur répond-il, quel périphérique, combien de VRAM libre | [689-740](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L689-L740) |

`client_id` n'est qu'une clé de routage. Le gestionnaire WebSocket garde une socket par `clientId`, et une nouvelle connexion avec le même identifiant remplace l'ancienne. Les événements d'un prompt vont à l'identifiant de client avec lequel il a été mis en file, sauf `status`, que [`queue_updated`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1399-L1400) diffuse à tout le monde à chaque changement de la file. Quand le worker a enregistré la mise en file d'un prompt, il a reçu deux messages `status`.

### Ce que le serveur ne fait pas pour vous

Ces faits déterminent la forme du worker. Ils sont lus dans le code source, et le [script d'enregistrement](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/record/record.py) du cours a aussi provoqué les cas d'identifiant de prompt, les erreurs et l'interruption sur un serveur CPU, et sauvegardé les réponses et les messages dans `data/recorded/`.

- **Un client peut choisir l'identifiant du prompt**, et ce doit être un UUID en minuscules avec tirets : [`validate_job_id`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_execution/jobs.py#L34-L50) refuse toute autre écriture avec un 400 `invalid_prompt_id`.
- **Le même identifiant de prompt n'est pas dédoublonné.** Envoyé deux fois, il est mis en file deux fois, s'exécute deux fois, et la seconde exécution écrase l'entrée d'historique de la première. L'idempotence est l'affaire de l'appelant.
- **`execution_success` arrive avant l'historique.** Il est envoyé à la fin de l'exécution, [ligne 824](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L824), et `task_done` écrit l'historique ensuite. Un client qui appelle `/history` juste après le message peut ne rien y trouver encore.
- **`execution_interrupted` est diffusé** à tous les clients ([`handle_execution_error`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L686-L712)), alors qu'`execution_error` ne va qu'au client du prompt.
- **Une reconnexion ne rejoue pas** ce que le client a manqué : la nouvelle socket reçoit un `status`, et `executing` pour le nœud en cours si c'est le client en cours d'exécution. Un prompt terminé pendant votre absence n'est que dans `/history`.
- **L'entrée d'historique porte le numéro du prompt** dans `prompt[0]`. Quand le même identifiant de prompt a tourné deux fois, c'est le seul moyen de savoir à quelle exécution appartient une entrée.
- **Un manque de mémoire est une `execution_error` ordinaire.** ComfyUI ajoute des conseils au message, puis décharge tous les modèles ([lignes 640 à 644](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L640-L644)), si bien qu'un second essai peut réussir.
- **Les erreurs de validation sont un 400** avec des `node_errors` par nœud ([`validate_prompt`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L1227-L1238)) ; un corps qui n'est pas du JSON fait répondre à aiohttp un 500 en texte brut, `500 Internal Server Error` puis `Server got itself in trouble`.
- **`/interrupt` avec un `prompt_id`** n'interrompt que si ce prompt est en cours, et répond 200 avec un corps vide dans les deux cas ; un prompt en attente reste en file jusqu'à ce que `POST /queue` le supprime.
- **L'historique est borné** : [`MAXIMUM_HISTORY_SIZE`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L1284) vaut 10 000 entrées, et un redémarrage le vide.

ComfyUI v0.36.0 a aussi des routes `/api/jobs` pour lister et annuler des jobs. Le worker ne s'en sert pas, pour fonctionner de la même façon avec les routes de la leçon 4.

### Adresses, ports et périphériques

Dans [`comfy/cli_args.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py) :

- `--listen` ([ligne 63](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L63)) vaut `127.0.0.1` par défaut ; sans valeur, il écoute sur `0.0.0.0,::`. `--port` ([ligne 64](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L64)) vaut 8188 par défaut.
- `--cuda-device` ([ligne 77](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L77)) règle `CUDA_VISIBLE_DEVICES` avant le chargement de PyTorch ([`main.py`, lignes 97 à 102](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L97-L102)) : `--cuda-device 1 --port 8189` est le serveur du second GPU. Sous Windows, sans `--cuda-device`, ComfyUI impose le GPU 0 ([lignes 46 à 53](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L46-L53)).
- `--base-directory` ([ligne 70](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L70)) et `--extra-model-paths-config` ([ligne 71](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L71)) séparent les entrées et sorties de chaque serveur d'un dossier de modèles partagé.
- Il n'y a pas d'authentification. Le serveur a `--tls-keyfile` et `--tls-certfile` ([lignes 65 et 66](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L65-L66)), et [`origin_only_middleware`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L159-L197), qui refuse les requêtes de navigateur cross-site ; il empêche une page web de mettre des prompts en file sur votre machine, pas un programme sur le réseau. `--multi-user` ([ligne 218](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L218)) sépare les réglages des utilisateurs, pas les droits. Gardez ComfyUI sur la boucle locale ou un réseau privé, et laissez l'API du service faire l'authentification ; la leçon 11 donne les autres raisons.

## Le worker

Le worker C# et le worker Java ont les mêmes classes, la même ligne de commande et les mêmes lignes de log, si bien que les transcriptions ci-dessous sont comparées aux mêmes fichiers attendus. Le code C# cible .NET 10, le code Java Java 25 avec Jackson 3, comme dans la leçon 4.

| Partie | C# | Java |
|---|---|---|
| un job, l'interface de file, la file en mémoire | `Jobs.cs` | `Jobs.java` |
| un serveur ComfyUI : santé, file, historique, envoi, annulation, WebSocket | `ComfyInstance.cs` | `ComfyInstance.java` |
| le pool de serveurs et l'ordonnanceur | `GpuPool.cs` | `GpuPool.java` |
| fichiers et enregistrements de jobs, réservations | `ResultStore.cs` | `ResultStore.java` |
| une tentative d'un job | `JobRunner.cs` | `JobRunner.java` |
| boucles de consommation, nouvelles tentatives, lettres mortes, arrêt | `Worker.cs` | `Worker.java` |
| RabbitMQ | `RabbitMqJobQueue.cs` | `RabbitMqJobQueue.java` |
| ligne de commande | `Program.cs` | `Main.java` |

### Un job et sa file

Un job, c'est un identifiant et un workflow au format API. L'identifiant est choisi par celui qui met le job en file, et c'est un UUID, parce que le worker s'en sert comme `prompt_id` de ComfyUI : une nouvelle tentative sur le même serveur peut alors retrouver le prompt dans `/queue` ou `/history`.

```csharp
public sealed record Job(string Id, JsonObject Workflow)
{
    public static Job Create(string id, JsonObject workflow)
    {
        // ComfyUI 0.36.0 refuses any other spelling of a UUID (comfy_execution/jobs.py, validate_job_id).
        if (!Guid.TryParse(id, out var guid) || guid.ToString() != id)
            throw new ArgumentException($"job id {id} is not a lowercase hyphenated UUID");
        return new Job(id, workflow);
    }

    public string Short => Id[..8];
}
```

Le worker voit la file à travers deux interfaces. Une livraison est acquittée quand le job est terminé, remise en file à l'arrêt, ou envoyée aux lettres mortes avec une raison :

```csharp
public interface IDelivery
{
    Job Job { get; }
    ValueTask AckAsync();
    /// <summary>Gives the job back, for another worker: used at shutdown.</summary>
    ValueTask RequeueAsync();
    ValueTask DeadLetterAsync(string reason);
}

public interface IJobQueue
{
    /// <summary>The next job, or null once the queue is completed and empty.</summary>
    ValueTask<IDelivery?> ReceiveAsync(CancellationToken cancel);
}
```

La file en mémoire est en C# un [`Channel<T>`](https://learn.microsoft.com/dotnet/core/extensions/channels) non borné avec plusieurs lecteurs, un par GPU, comme dans la [leçon sur les channels](../../csharp-advanced/06-channels/#plusieurs-producteurs-plusieurs-consommateurs). En Java, c'est une [`LinkedBlockingQueue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/LinkedBlockingQueue.html) interrogée par un [thread virtuel](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html) par GPU. Les attentes bloquantes dans des threads virtuels coûtent peu, c'est pourquoi le worker Java n'a pas besoin de Reactor ici ; la [leçon sur Reactor](../../spring-cloud-reactor/03-reactor-under-the-hood/#threads-virtuels-ou-réactif-) compare les deux approches.

Chaque boucle de consommation ne prend un job que quand elle peut l'exécuter : un worker à deux GPU a deux boucles, et ne garde jamais un troisième job qu'un autre worker pourrait exécuter.

### Une tentative, étape par étape

[`JobRunner`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker/JobRunner.cs) exécute une tentative d'un job sur un serveur, et ne lève jamais d'exception pour ce que fait un serveur. Il renvoie un résultat : réussite, échec transitoire ou échec définitif.

1. **Rattraper.** Si `/history/{id}` contient déjà une entrée réussie, une tentative précédente ou un autre worker a terminé le prompt : on télécharge ses sorties. Si `/queue` contient l'identifiant, on le suit au lieu de l'envoyer à nouveau.
2. **Se connecter, puis envoyer.** Le WebSocket s'ouvre avec un nouvel identifiant de client avant `POST /prompt`, pour qu'aucun événement ne parte avant que quelqu'un écoute. Le `number` de la réponse identifie cette exécution.
3. **Suivre** jusqu'à `execution_success`, `execution_error` ou `execution_interrupted` pour cet identifiant de prompt, et seulement après l'`execution_start` de cette exécution : un `execution_interrupted` d'une exécution précédente avec le même identifiant, diffusé à tous, ne doit pas terminer celle-ci. Toutes les cinq secondes, et après chaque reconnexion, il lit aussi `/history`, et n'accepte que l'entrée dont `prompt[0]` est le numéro de cette exécution.
4. **Télécharger** chaque sortie avec `/view`, l'écrire sous un nom temporaire, puis la renommer.

Le résultat décide de la suite :

```csharp
var (status, body) = await gpu.SubmitAsync(job, clientId, deadline.Token);
if (status == HttpStatusCode.BadRequest)
    return Outcome.Permanent($"POST /prompt 400, {DescribeErrors(body)}");
if ((int)status >= 500)
    return Outcome.Transient($"POST /prompt {(int)status}, {body.Split('\n')[0]}");
```

```csharp
case "execution_error":
    string type = data?["exception_type"]?.GetValue<string>() ?? "";
    string message = (data?["exception_message"]?.GetValue<string>() ?? "").Split('\n')[0];
    string where = $"node {data?["node_id"]} ({data?["node_type"]}): {type}: {message}";
    // An out-of-memory error depends on what else the GPU held (execution.py unloads all models
    // after one): worth another try. Anything else will fail the same way again.
    return IsOutOfMemory(type, data)
        ? Outcome.Transient($"execution_error, {where}")
        : Outcome.Permanent($"execution_error, {where}");
default:
    return Outcome.Transient($"execution_interrupted at node {data?["node_id"]}, by someone else");
```

| Ce qui s'est passé | Résultat | Pourquoi |
|---|---|---|
| `POST /prompt` 400 | définitif | le workflow est invalide : le même corps sera refusé à nouveau |
| `POST /prompt` 5xx, connexion refusée, réinitialisée ou expirée | transitoire | le serveur redémarre peut-être |
| `execution_error` avec un type ou un message de manque de mémoire | transitoire | la mémoire dépend de ce que le GPU contenait d'autre |
| toute autre `execution_error` | définitif | un bug dans le workflow ou un nœud |
| `execution_interrupted` sans expiration du délai | transitoire | quelqu'un d'autre a cliqué sur Cancel dans l'interface |
| pas de fin avant le délai du job | transitoire | le prompt est d'abord interrompu |

### Nouvelles tentatives avec backoff

Un échec transitoire est retenté après un délai qui double à chaque fois, plafonné à une minute. Avec la gigue activée, le réglage par défaut, le délai est une valeur aléatoire entre zéro et ce plafond, la « full jitter » de [l'article de Marc Brooker](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/), pour que cent jobs qui échouent ensemble ne réessaient pas ensemble.

```csharp
public TimeSpan Backoff(int attempt)
{
    double capped = Math.Min(options.MaxDelay.TotalMilliseconds, options.BaseDelay.TotalMilliseconds * Math.Pow(2, attempt - 1));
    return TimeSpan.FromMilliseconds(options.Jitter ? Random.Shared.NextDouble() * capped : capped);
}
```

```java
public Duration backoff(int attempt) {
    double capped = Math.min(options.maxDelay().toMillis(), options.baseDelay().toMillis() * Math.pow(2, attempt - 1));
    return Duration.ofMillis(Math.round(options.jitter() ? ThreadLocalRandom.current().nextDouble() * capped : capped));
}
```

Une nouvelle tentative préfère le serveur de la tentative précédente quand les files sont égales : ce serveur a peut-être encore le prompt dans sa file ou son historique. Après la dernière tentative, le job va aux lettres mortes avec la dernière raison : `gave up after 4 attempts, last: …`. Les valeurs par défaut sont 4 tentatives, 2 s de délai de base, un plafond d'une minute et 10 minutes de délai par job.

### Idempotence : chaque job s'exécute une fois

Une file avec accusés de réception livre **au moins une fois** : un worker qui meurt après avoir terminé un job mais avant d'en accuser réception se voit relivrer ce job, à lui-même ou à un autre worker. La [leçon sur la fiabilité de RabbitMQ](../../rabbitmq/04-reliability/#les-doublons-sont-normaux--consommateurs-idempotents) fait la même remarque. Comme ComfyUI ne dédoublonne pas non plus, le worker s'en charge avec trois vérifications :

1. **`done.json`** dans le dossier du job, dans le stockage des résultats : le job est terminé, on acquitte sans l'exécuter.
2. **Un fichier de réservation**, créé avec `FileMode.CreateNew` en C# et `StandardOpenOption.CREATE_NEW` en Java, qui échoue de façon atomique si le fichier existe : un autre worker exécute le job. La réservation a un bail, une heure par défaut ; une réservation plus vieille que son bail appartient à un worker mort, et elle est reprise.
3. **L'identifiant du prompt** sur le serveur : l'étape de rattrapage retrouve un prompt qu'une tentative précédente a mis en file ou terminé.

```csharp
// CreateNew fails if the file exists, atomically, on every OS and on most network file systems.
using var file = new FileStream(path, FileMode.CreateNew, FileAccess.Write);
JsonSerializer.Serialize(file, new JsonObject { ["owner"] = owner, ["expires"] = DateTimeOffset.UtcNow.Add(lease) });
return true;
```

Un dossier avec un fichier de réservation tient lieu de ce qu'utiliserait un vrai déploiement : un stockage objet pour les fichiers, et une ligne de base de données avec une clé unique pour la réservation et l'enregistrement. La règle est la même : réserver avant d'exécuter, enregistrer avant d'acquitter.

### Délais, `/interrupt` et lettres mortes

Chaque tentative s'exécute sous une échéance liée au jeton d'abandon du worker. Quand l'échéance tombe, [`CancelPromptAsync`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker/ComfyInstance.cs) envoie `/interrupt` avec l'identifiant du prompt, supprime l'identifiant de la file au cas où il n'aurait pas démarré, puis attend qu'il ait quitté `/queue`. Sans cette attente, la nouvelle tentative, qui utilise le même identifiant de prompt, pourrait recevoir les derniers messages de l'exécution interrompue.

Les échecs définitifs et les tentatives épuisées vont aux lettres mortes avec une raison lisible par une personne. La raison est aussi écrite dans `failed.txt` dans le dossier du job, et la réservation est libérée, pour que quelqu'un puisse corriger le workflow et remettre le job en file.

### Un pool de GPU

On donne à un worker ses serveurs sur la ligne de commande, un par GPU : `--gpu gpu0=http://127.0.0.1:8188 --gpu gpu1=http://127.0.0.1:8189`. Un sémaphore compte ceux qui sont libres. Pour choisir un serveur, [`GpuPool`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker/GpuPool.cs) demande `/system_stats` et `/queue` à chaque serveur libre, chaque sonde étant limitée à 3 secondes, et trie ceux qui sont en bonne santé :

```csharp
var healthy = health.Where(h => h.Health.Healthy)
    .OrderBy(h => h.Health.QueueLength)
    .ThenBy(h => h.Slot.Instance == prefer ? 0 : 1)
    .ThenBy(h => slots.IndexOf(h.Slot))
    .ToList();
```

La longueur de la file compte parce qu'un worker est rarement le seul client d'un serveur : un autre worker, ou une personne dans l'interface web, a pu y mettre des prompts. « Le moins chargé » veut dire « le moins de prompts devant », ce que ComfyUI sait dire ; la VRAM libre serait un moins bon signal, puisque ComfyUI garde exprès les modèles chargés. Quand aucun serveur n'est en bonne santé, le pool les affiche et attend 5 secondes.

### Vérification de santé et arrêt propre

`comfy-worker health` sonde chaque serveur et sort avec 0 si au moins un est en bonne santé, ce dont a besoin une sonde de disponibilité :

```
gpu0: healthy, device cpu, 23238 MiB free, 0 prompt(s) in its queue
gpu1: unreachable (HttpRequestException)
exit code 0
```

Le worker Java affiche `ConnectException` sur la deuxième ligne. Le reste est identique.

Un conteneur est arrêté par SIGTERM, puis tué après un délai de grâce. Le worker utilise deux jetons : `stopReceiving` empêche les boucles de prendre de nouveaux jobs, et `abort`, déclenché après `--grace-s` secondes, interrompt les jobs encore en cours et les rend à la file. En C#, [`PosixSignalRegistration`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.posixsignalregistration) intercepte le signal :

```csharp
void Stop(PosixSignalContext context)
{
    context.Cancel = true;
    if (stopReceiving.IsCancellationRequested) return;
    log($"{context.Signal}: no new jobs, {grace.TotalSeconds:0} s for the running ones");
    stopReceiving.Cancel();
    abort.CancelAfter(grace);
}
using var sigint = PosixSignalRegistration.Create(PosixSignal.SIGINT, Stop);
using var sigterm = PosixSignalRegistration.Create(PosixSignal.SIGTERM, Stop);
```

En Java, un [shutdown hook](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Runtime.html#addShutdownHook(java.lang.Thread)) s'exécute sur SIGTERM ou Ctrl+C, et la JVM se termine quand le hook rend la main, donc le hook attend le thread principal :

```java
Runtime.getRuntime().addShutdownHook(new Thread(() -> {
    if (!main.isAlive()) {
        return;
    }
    log.accept("shutdown: no new jobs, " + grace.toSeconds() + " s for the running ones");
    stopReceiving.cancel();
    abort.cancelAfter(grace);
    try {
        main.join();
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
    }
}));
```

Java n'a pas de `CancellationToken`, alors [`Cancellation.java`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/java/src/main/java/dev/learn/comfy/worker/Cancellation.java) en est un petit équivalent : un drapeau, un parent, une échéance, et des attentes découpées en tranches courtes qui le vérifient. Gardez le délai de grâce en dessous du `terminationGracePeriodSeconds` de Kubernetes, 30 s par défaut, sinon le pod est tué avant que le worker ait rendu ses jobs.

### Avec RabbitMQ

[`RabbitMqJobQueue`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker/RabbitMqJobQueue.cs) implémente la même interface avec le [client .NET de RabbitMQ](https://www.rabbitmq.com/client-libraries/dotnet) 7.2.2, et son jumeau Java avec le [client Java](https://www.rabbitmq.com/client-libraries/java-client) 5.35.0 :

- une [quorum queue](https://www.rabbitmq.com/docs/quorum-queues) durable pour les jobs, et une seconde, `<queue>.dead`, pour les lettres mortes ;
- des accusés de réception manuels, et un [prefetch](https://www.rabbitmq.com/docs/consumer-prefetch) égal au nombre de GPU, pour que le broker ne donne jamais à un worker plus de jobs qu'il ne peut en exécuter ;
- une lettre morte est publiée dans `<queue>.dead` avec la raison dans un en-tête `x-worker-reason`, puis l'original est acquitté ;
- une remise en file à l'arrêt est un `basicNack` avec `requeue` activé ;
- `enqueue` publie un fichier de jobs en messages persistants, avec l'identifiant du job comme identifiant de message, et des confirmations de publication.

```java
/** Published to the dead-letter queue with the reason in a header, then acked. */
@Override
public void deadLetter(String reason) throws IOException {
    AMQP.BasicProperties properties = MessageProperties.PERSISTENT_BASIC.builder()
            .messageId(job.id()).contentType("application/json").headers(Map.of("x-worker-reason", reason)).build();
    synchronized (channel) {
        channel.basicPublish("", deadLetterQueue, properties, body);
        channel.basicAck(tag, false);
    }
}
```

Le worker publie lui-même la lettre morte plutôt que d'utiliser les [dead letter exchanges](https://www.rabbitmq.com/docs/dlx) de RabbitMQ, parce qu'un `basicReject` ne peut pas porter de raison. Si le worker meurt entre la publication et l'acquittement, le job est relivré, et `failed.txt` ne l'arrête pas : la lettre morte peut apparaître deux fois. Les deux adaptateurs compilent et sont construits par la CI, mais **le cours ne les a pas encore fait tourner contre un broker** : l'exécution avec RabbitMQ est *à vérifier*. Les commandes seraient :

```bash
java -jar java/target/comfy-worker.jar enqueue --rabbitmq amqp://guest:guest@localhost --queue renders --jobs jobs/happy.jsonl
dotnet csharp/ComfyWorker/bin/Release/net10.0/comfy-worker.dll run --rabbitmq amqp://guest:guest@localhost --queue renders \
  --gpu gpu0=http://127.0.0.1:8188 --store out/store-rabbit
```

## Tester sans ComfyUI

### Un faux serveur à partir de réponses enregistrées

Un test qui a besoin d'un GPU tourne rarement. Les pannes du worker portent sur des codes HTTP, des messages WebSocket et du timing, et tout cela peut se rejouer. [`record.py`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/record/record.py) démarre un vrai ComfyUI v0.36.0 avec `--cpu` dans un dossier de base temporaire, provoque chaque cas avec des workflows qui n'ont besoin d'aucun modèle, et sauvegarde les requêtes, les réponses et les messages WebSocket dans `data/recorded/` : une réussite, le même identifiant de prompt envoyé deux fois, trois prompts à la suite, une erreur de validation, un identifiant de prompt invalide, une `IndexError` dans `ImageToMask`, une interruption, un 500 et les autres routes.

[`FakeComfyServer`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/FakeComfy/FakeComfyServer.cs) est une [API minimale](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis) sur [Kestrel](https://learn.microsoft.com/aspnet/core/fundamentals/servers/kestrel) qui sert les mêmes routes avec ces réponses, exécute un prompt à la fois, écrit de vrais fichiers PNG pour les nœuds `SaveImage`, et suit un script, un mot par prompt dans l'ordre d'arrivée :

| Mot | Ce que fait le faux serveur |
|---|---|
| `ok` | exécute chaque nœud, puis `execution_success` |
| `500` | répond 500 comme aiohttp quand un gestionnaire lève une exception |
| `invalid` | 400 avec `prompt_outputs_failed_validation` et `node_errors` |
| `error` | `execution_error` au deuxième nœud, l'`IndexError` enregistrée |
| `oom` | `execution_error` avec le type et les conseils d'un manque de mémoire |
| `drop` | coupe le WebSocket du client au premier nœud, puis termine |
| `hang` | s'arrête au deuxième nœud jusqu'à `POST /interrupt` |
| `slow` | comme `ok`, dix fois plus lent |

`--busy N` ajoute à sa file N prompts d'un autre client, pour tester l'ordonnanceur. Le faux serveur note ce qu'il a reçu, par identifiant de prompt, pour que les tests puissent vérifier combien de fois un prompt a été envoyé et exécuté. Les tests C# l'utilisent dans le même processus ; les tests Java et les transcriptions le lancent comme un programme.

### Les tests

[`WorkerTests.cs`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker.Tests/WorkerTests.cs) utilise [xUnit v3](https://xunit.net/docs/getting-started/v3/getting-started), et [`WorkerTest.java`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/java/src/test/java/dev/learn/comfy/worker/WorkerTest.java) [JUnit 6](https://docs.junit.org/). Leurs noms disent ce qu'ils vérifient :

- `Success_stores_the_files_and_a_duplicate_delivery_does_not_run_again` : le même job mis en file deux fois s'exécute une fois et est acquitté deux fois.
- `Server_error_500_is_retried_with_backoff` : envoyé deux fois, exécuté une fois.
- `WebSocket_dropping_mid_job_is_followed_again_without_posting_twice`
- `Validation_error_goes_to_the_dead_letter_queue_without_retry`
- `Timeout_interrupts_the_prompt_and_gives_up_after_the_last_attempt` : deux interruptions, puis la réservation est libre pour un opérateur.
- `Out_of_memory_is_retried_and_other_execution_errors_are_not`
- `Two_workers_competing_for_the_same_jobs_run_each_job_once` : 8 jobs, chacun livré deux fois, 2 workers sur 2 serveurs ; chaque job s'exécute exactement une fois, les deux serveurs travaillent, 16 acquittements.
- `Scheduler_picks_the_instance_with_the_shortest_queue`
- `Shutdown_after_the_grace_period_interrupts_and_requeues`

C# en a deux de plus, `Unreachable_instance_is_reported_and_skipped` et `Graceful_shutdown_lets_the_running_job_finish_and_takes_no_new_one`. Sur la machine Windows de l'auteur :

```bash
bash code/comfyui/worker/check.sh build
bash code/comfyui/worker/check.sh test
```

```
   ComfyWorker.Tests  Total: 11, Errors: 0, Failed: 0, Skipped: 0, Not Run: 0, Time: 11.909s
[INFO] Tests run: 9, Failures: 0, Errors: 0, Skipped: 0
```

Les projets de test xUnit v3 sont des programmes : `check.sh` lance l'assembly de test avec `dotnet`. `dotnet test` sur .NET 10 a besoin de `"test": {"runner": "Microsoft.Testing.Platform"}` dans `global.json`, ce que celui du worker contient.

### Les pannes, en ligne de commande

`check.sh transcripts` lance les deux workers contre de faux serveurs et compare leur sortie avec `expected/`. Les jobs de [`jobs/failures.jsonl`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/jobs/failures.jsonl) rencontrent le script `500,ok,drop,invalid,oom,ok,error,hang,hang`, avec 2 tentatives, un délai d'1 s et un délai de base de 100 ms sans gigue :

```bash
dotnet csharp/ComfyWorker/bin/Release/net10.0/comfy-worker.dll run --gpu gpu0=http://127.0.0.1:52100/ \
  --store out/store-failures-cs --jobs jobs/failures.jsonl \
  --name worker-1 --no-jitter --base-delay-ms 100 --poll-ms 200 --attempts 2 --timeout-s 1
```

```
worker worker-1: 1 GPU(s), up to 2 attempts, job timeout 1 s
job 00000003: attempt 1 failed, POST /prompt 500, 500 Internal Server Error; retry in 100 ms
job 00000003 attempt 2 on gpu0: POST /prompt 200
job 00000003: done on gpu0 after 2 attempt(s), 2 file(s): 3-solid_00001_.png 12f8083634dd0a19, 4-inverted_00001_.png 12f8083634dd0a19
job 00000004 attempt 1 on gpu0: POST /prompt 200
job 00000004 attempt 1 on gpu0: WebSocket lost, reconnecting with the same client id
job 00000004: done on gpu0 after 1 attempt(s), 2 file(s): 3-solid_00002_.png 12f8083634dd0a19, 4-inverted_00002_.png 12f8083634dd0a19
job 00000005: dead-lettered, POST /prompt 400, prompt_outputs_failed_validation: node 3 (KSampler): exception_during_inner_validation
job 00000006 attempt 1 on gpu0: POST /prompt 200
job 00000006: attempt 1 failed, execution_error, node 2 (ImageInvert): torch.OutOfMemoryError: Allocation on device ; retry in 100 ms
job 00000006 attempt 2 on gpu0: POST /prompt 200
job 00000006: done on gpu0 after 2 attempt(s), 2 file(s): 3-solid_00003_.png 12f8083634dd0a19, 4-inverted_00003_.png 12f8083634dd0a19
job 00000007 attempt 1 on gpu0: POST /prompt 200
job 00000007: dead-lettered, execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
job 00000008 attempt 1 on gpu0: POST /prompt 200
job 00000008 attempt 1 on gpu0: no result after 1 s, POST /interrupt and remove it from the queue
job 00000008: attempt 1 failed, timed out after 1 s; retry in 100 ms
job 00000008 attempt 2 on gpu0: POST /prompt 200
job 00000008 attempt 2 on gpu0: no result after 1 s, POST /interrupt and remove it from the queue
job 00000008: dead-lettered, gave up after 2 attempts, last: timed out after 1 s
job 00000009 attempt 1 on gpu0: POST /prompt 200
job 00000009: done on gpu0 after 1 attempt(s), 2 file(s): 3-solid_00004_.png 12f8083634dd0a19, 4-inverted_00004_.png 12f8083634dd0a19
worker worker-1: stopped
summary: 4 acknowledged, 3 dead-lettered
  dead letter 00000005: POST /prompt 400, prompt_outputs_failed_validation: node 3 (KSampler): exception_during_inner_validation
  dead letter 00000007: execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
  dead letter 00000008: gave up after 2 attempts, last: timed out after 1 s
```

Le port change d'une exécution à l'autre. Le worker Java, `java -jar java/target/comfy-worker.jar` avec les mêmes arguments, affiche exactement les mêmes lignes. La première ligne du job 3 n'a pas de « POST /prompt 200 » parce que la tentative a échoué à l'envoi. Le WebSocket coupé ne coûte pas de second envoi : le worker se reconnecte avec le même identifiant de client et trouve la fin dans `/history`. Le manque de mémoire est retenté, l'`IndexError` ne l'est pas.

Avec deux faux serveurs, le premier contenant deux prompts de quelqu'un d'autre, l'ordonnanceur envoie le premier job au serveur libre. Extrait de l'exécution Java :

```
scheduler: gpu1 chosen, queue lengths gpu0 2, gpu1 0
scheduler: gpu0 chosen, queue lengths gpu0 2, gpu1 0
```

La deuxième ligne est correcte : `gpu1` est maintenant occupé par le propre job du worker, et seuls les serveurs libres sont candidats. Quel job atterrit où dépend du timing, alors `check.sh` ne compare que la ligne de résumé, `summary: 4 acknowledged, 0 dead-lettered`.

### Contre un vrai ComfyUI sur CPU

`check.sh integration` démarre ComfyUI v0.36.0 avec `--cpu` grâce au `server.sh` de la leçon 4, et exécute [`jobs/real.jsonl`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/jobs/real.jsonl) : le workflow de couleur unie de la leçon 4, le même job une seconde fois, un workflow qui échoue avec une `IndexError`, et un workflow lent, trois grands flous d'une image de 1024 × 1024. Le worker C# d'abord :

```
worker worker-1: 1 GPU(s), up to 2 attempts, job timeout 120 s
job 00000021 attempt 1 on gpu0: POST /prompt 200
job 00000021: done on gpu0 after 1 attempt(s), 2 file(s): 3-solid_00001_.png 413ca196d3253a3a, 4-inverted_00001_.png 6ae2ff48c6792970
job 00000021: already done, acknowledged without running
job 00000022 attempt 1 on gpu0: POST /prompt 200
job 00000022: dead-lettered, execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
job 00000023 attempt 1 on gpu0: POST /prompt 200
job 00000023: done on gpu0 after 1 attempt(s), 1 file(s): 5-slow_00001_.png f4a8fceb7d74373b
worker worker-1: stopped
summary: 3 acknowledged, 1 dead-lettered
  dead letter 00000022: execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
```

Puis le worker Java, avec un autre stockage de résultats, sur le même serveur et avec les mêmes identifiants de jobs. Il trouve les prompts terminés dans `/history` et les télécharge sans les exécuter à nouveau ; celui qui a échoué n'est pas une réussite dans l'historique, donc il est envoyé et échoue à nouveau :

```
job 00000021 attempt 1 on gpu0: already in /history, downloading its outputs
job 00000021: done on gpu0 after 1 attempt(s), 2 file(s): 3-solid_00001_.png <sha256>, 4-inverted_00001_.png <sha256>
job 00000021: already done, acknowledged without running
job 00000022 attempt 1 on gpu0: POST /prompt 200
job 00000022: dead-lettered, execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
job 00000023 attempt 1 on gpu0: already in /history, downloading its outputs
```

`check.sh` remplace les empreintes par `<sha256>` avant de comparer, parce que les octets PNG dépendent de la version de zlib.

### CI

Le workflow a deux jobs :

- **`fake`**, sur Ubuntu, Windows et macOS : .NET 10, Java 25, puis `bash code/comfyui/worker/check.sh`, qui compile, lance les deux suites de tests et compare les transcriptions. Pas de GPU, pas de modèle, pas de ComfyUI.
- **`real`**, sur Ubuntu : clone ComfyUI au tag `v0.36.0`, vérifie que le tag est bien le commit `ee71d5c`, installe PyTorch 2.13.0 pour CPU et les dépendances de ComfyUI, puis `check.sh build` et `check.sh integration`.

La première exécution de la CI a trouvé un bug que Windows masquait. `check.sh` arrête les faux serveurs avec `kill`, et sur le runner Linux ils restaient en vie, si bien que le script les a attendus jusqu'à l'annulation du job ; sous Windows, le `kill` de Git Bash les avait bien terminés. Le faux serveur attend maintenant SIGTERM ou SIGINT avec `PosixSignalRegistration`, et chaque job a un `timeout-minutes`. L'exécution [35178934958](https://github.com/spareilleux/learn/actions/runs/35178934958) est ensuite passée sur les quatre jobs.

## Le déployer

Rien dans cette section n'a été exécuté par le cours : c'est *à vérifier*, d'après la documentation citée.

- **Un conteneur.** ComfyUI v0.36.0 ne fournit pas de Dockerfile. Une image a besoin de Python, d'une version de PyTorch pour sa version de CUDA, du `requirements.txt` de ComfyUI, des nœuds personnalisés que vous avez vérifiés (leçon 11), et d'une commande comme `python main.py --listen 0.0.0.0 --port 8188 --base-directory /data --extra-model-paths-config /config/extra_model_paths.yaml`. Le GPU atteint le conteneur grâce au [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html). Construisez le worker comme une seconde image ; il n'a pas besoin de GPU.
- **Kubernetes et les GPU.** Avec le device plugin NVIDIA, un conteneur demande un GPU avec `resources.limits: nvidia.com/gpu: 1` ([Schedule GPUs](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/)). Les GPU ne s'indiquent qu'en limites, et entiers : deux conteneurs n'en partagent pas un sans time-slicing ou MIG. Un pod par GPU avec ComfyUI et le worker comme deux conteneurs garde « un serveur par GPU » simple ; le worker n'a alors qu'un seul `--gpu` sur `127.0.0.1`. La [leçon sur les pods](../../kubernetes/02-pods/#trois-sondes) couvre les sondes : `comfy-worker health` convient à une sonde de disponibilité, et une [sonde startup](../../kubernetes/02-pods/#une-sonde-startup-pour-la-jvm) laisse à ComfyUI le temps de démarrer. Sa section sur les [requests et limits](../../kubernetes/02-pods/#requests-limits-et-qos) s'applique à la RAM que prennent les modèles une fois déchargés du GPU.
- **Des modèles partagés en lecture seule.** Un checkpoint de plusieurs gigaoctets ne devrait pas être copié dans chaque pod. Montez un volume en lecture seule, et faites-le pointer par chaque serveur avec `extra_model_paths.yaml` ; le fichier [`extra_model_paths.yaml.example`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/extra_model_paths.yaml.example) du dépôt montre le format. Gardez `output`, `input`, `temp` et `user` propres à chaque serveur, sous son propre `--base-directory`.
- **Démarrage à froid.** Un nouveau serveur doit lancer Python, importer PyTorch et les nœuds personnalisés, puis charger chaque modèle du disque vers la RAM et la VRAM la première fois qu'un prompt en a besoin. Dans la leçon 8, le premier rendu sur un serveur neuf était surtout du chargement depuis un SSD externe ; depuis un volume réseau, cela peut prendre bien plus longtemps. Préchauffez un nouveau serveur avec un petit prompt avant que sa sonde de disponibilité ne passe, et gardez ses modèles chargés plutôt que de descendre à zéro si la latence compte.
- **`--highvram` et `--lowvram`.** Sur un serveur qui fait des rendus toute la journée, [`--highvram`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L168-L172) garde les modèles en mémoire GPU au lieu de les renvoyer en mémoire CPU après usage. `--lowvram` exécute les encodeurs de texte sur le CPU, mais son texte d'aide dit qu'il ne fait rien quand la VRAM dynamique est active, et [`enables_dynamic_vram`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L317-L320) l'active par défaut sauf avec `--highvram`, `--gpu-only`, `--novram` ou `--cpu`. Mesurez les deux sur vos workflows.
- **Coût.** Un GPU coûte le même prix à l'heure qu'il fasse des rendus ou qu'il attende. Le coût d'une image est à peu près le prix horaire divisé par le nombre d'images par heure au taux d'utilisation réel, plus le stockage et le transfert. Regrouper les jobs d'un même modèle sur un même serveur évite les changements de modèle ; l'ordonnanceur d'ici ne le fait pas, et c'est l'un des exercices.

## Expérience GA

La première expérience du labo GA, [`01-chord-neck.yaml`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/ga-lab/experiments/01-chord-neck.yaml), génère un manche de guitare pour chacun de dix accords, de C à Bm7b5, avec la carte de manche GA passée dans le ControlNet, pour les seeds 42 et 43 : vingt images. La leçon 14, le labo Guitar Alchemist, la fera tourner avec le runner du labo, sur un GPU, en vérifiant la mémoire avant chaque prompt et en mesurant où tombent les points. Le worker est l'autre face du même travail : le lot sous forme de jobs dans une file, répartis sur les GPU disponibles, avec nouvelles tentatives et fichier de résultats.

[`jobs/ga-chord-neck.jsonl`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/jobs/ga-chord-neck.jsonl) contient un job par image. L'identifiant code le rang de l'accord et la seed, `00050043-…` pour le cinquième accord, D, et la seed 43, si bien que mettre le fichier en file deux fois n'exécute rien deux fois. Chaque ligne règle les mêmes entrées que l'expérience :

```json
{"id": "00010042-0000-4000-8000-000000000000", "workflow": "../../ga-lab/workflows/ga-chord-neck.api.json", "set": {"3.seed": 42, "18.chord": "C", "18.note_style": "filled", "18.inlays": "hide", "18.fret_start": 0, "18.fret_end": 5, "22.strength": 0.8}}
```

[`jobs/results.py`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/jobs/results.py) transforme le stockage des résultats en une ligne CSV par job : ses paramètres, son statut (`done`, `dead-lettered` ou `pending`), son serveur, ses tentatives et ses fichiers. `check.sh` exécute les vingt jobs contre un faux serveur qui manque de mémoire une fois, ce qui vérifie le fichier de jobs par rapport au workflow, pas les images :

```
job 00020042 attempt 1 on gpu0: POST /prompt 200
job 00020042: attempt 1 failed, execution_error, node 4 (CheckpointLoaderSimple): torch.OutOfMemoryError: Allocation on device ; retry in 100 ms
job 00020042 attempt 2 on gpu0: POST /prompt 200
job 00020042: done on gpu0 after 2 attempt(s), 2 file(s): 9-neck_00003_.png 12f8083634dd0a19, 19-neck-map_00003_.png 12f8083634dd0a19
```

```
summary: 20 acknowledged, 0 dead-lettered
```

Les premières lignes du CSV :

```bash
python jobs/results.py jobs/ga-chord-neck.jsonl out/store-ga-cs
```

```
job,18.chord,18.fret_end,18.fret_start,18.inlays,18.note_style,22.strength,3.seed,status,gpu,attempts,files,reason
00010042,C,5,0,hide,filled,0.8,42,done,gpu0,1,9-neck_00001_.png:12f8083634dd0a19 19-neck-map_00001_.png:12f8083634dd0a19,
00010043,C,5,0,hide,filled,0.8,43,done,gpu0,1,9-neck_00002_.png:12f8083634dd0a19 19-neck-map_00002_.png:12f8083634dd0a19,
00020042,G,5,0,hide,filled,0.8,42,done,gpu0,2,9-neck_00003_.png:12f8083634dd0a19 19-neck-map_00003_.png:12f8083634dd0a19,
```

Sur le GPU, avec SDXL et le ControlNet chargés, la commande serait la même avec l'adresse du vrai serveur, et un second `--gpu` pour une seconde carte. Cette exécution est *à vérifier* : le cours ne démarre jamais ComfyUI sur le GPU depuis ses vérifications automatiques, et c'est le runner du labo qui fait cette mesure.

## Points clés

- Un serveur ComfyUI exécute un prompt à la fois. Plusieurs GPU veulent dire plusieurs serveurs, chacun avec `--cuda-device` et son propre port, et quelque chose devant qui choisit.
- ComfyUI ne dédoublonne pas les identifiants de prompt, ne rejoue pas les événements WebSocket manqués, envoie `execution_success` avant d'écrire l'historique et diffuse `execution_interrupted`. Un worker doit consulter `/queue` et `/history` lui-même, et faire correspondre les entrées d'historique au numéro de son exécution.
- Utilisez l'identifiant du job comme `prompt_id`, réservez le job avant de l'exécuter, enregistrez-le avant de l'acquitter : une livraison au moins une fois exécute alors chaque job une fois.
- Classez les échecs : un 400 ou une `execution_error` ordinaire est définitif et va aux lettres mortes ; un 5xx, une connexion perdue, un manque de mémoire ou un délai dépassé est transitoire et retenté avec un backoff exponentiel et de la gigue.
- Un délai dépassé n'est réglé que quand le prompt est interrompu et a quitté la file du serveur.
- Choisissez le serveur qui a le moins de prompts devant, et arrêtez de prendre des jobs sur SIGTERM avant la fin du délai de grâce.
- Un faux serveur qui rejoue des réponses enregistrées teste chaque panne sur trois OS en quelques minutes ; un serveur CPU avec des workflows sans modèle confronte le faux au vrai.

## Exercices

1. Calculez les délais entre les tentatives avec les valeurs par défaut (4 tentatives, base de 2 s, plafond d'une minute) sans gigue. Avec la full jitter, quelle est l'attente totale moyenne d'un job qui échoue à chaque fois ?
2. Inversez les étapes 2 et 3 d'une tentative : envoyer d'abord, puis ouvrir le WebSocket. Qu'est-ce qui peut mal tourner avec un prompt qui dure 50 ms, et qu'est-ce qui, dans le worker, sauve quand même le job ?
3. Un worker tourne avec `--timeout-s 7200`, et un job dure 90 minutes. Le bail de réservation est d'une heure, la valeur par défaut. Une seconde livraison du job arrive à la minute 70 sur un autre worker. Que se passe-t-il, et comment le corrigeriez-vous ?
4. Avec RabbitMQ, un worker écrit `done.json`, puis son conteneur est tué avant `basicAck`. Suivez le job jusqu'au bout. Répondez ensuite à la même question pour un arrêt entre la publication de la lettre morte et son acquittement.
5. Modifiez l'ordonnanceur pour qu'un serveur dont la file contient déjà `--max-queue` prompts ou plus ne soit pas candidat, et que le job attende. Écrivez d'abord le test C#, avec deux faux serveurs et `Busy`.
6. Ajoutez à `results.py` une colonne avec la durée réelle de chaque job, et dites où le worker devrait l'enregistrer.
7. Un pod exécute ComfyUI et le worker. Écrivez sa sonde de disponibilité et son `terminationGracePeriodSeconds` pour un worker lancé avec `--grace-s 60`.

<details>
<summary>Solution 1</summary>

Sans gigue, le délai après la tentative n est de 2 s × 2^(n−1) : 2 s après la première tentative, 4 s après la deuxième, 8 s après la troisième. Il n'y a pas de délai après la quatrième : le job va aux lettres mortes. Au total, 14 s d'attente, plus jusqu'à quatre délais de 10 minutes si chaque tentative se bloque. Avec la full jitter, chaque délai est uniforme entre 0 et son plafond, donc sa valeur moyenne est la moitié : 1 + 2 + 4 = 7 s en moyenne. Le plafond d'une minute ne compte qu'à partir du délai après la sixième tentative, 2 × 2^5 = 64 s.

</details>

<details>
<summary>Solution 2</summary>

Le prompt peut se terminer avant que la socket soit ouverte, et ses `execution_start` et `execution_success` sont envoyés à un identifiant de client qui n'a pas encore de socket. Ils sont perdus : ComfyUI ne rejoue pas les événements. Le worker attendrait alors des messages qui ne viennent jamais. Ce qui le sauve, c'est la lecture périodique de `/history`, toutes les `--poll-ms` (5 s par défaut) : l'entrée d'historique avec le numéro de cette exécution est trouvée, et le job se termine normalement, avec quelques secondes de retard. Sans cette lecture, il attendrait jusqu'au délai du job, interromprait un prompt déjà terminé, et le réessaierait.

</details>

<details>
<summary>Solution 3</summary>

À la minute 60, la réservation expire. À la minute 70, le second worker vérifie `done.json` (absent), puis `TryClaim` : la réservation a expiré, il la supprime et la prend. S'il choisit le même serveur, le rattrapage trouve le prompt dans `/queue` et le suit au lieu de l'envoyer à nouveau. Sur un autre serveur, il envoie le job : le prompt s'exécute deux fois, et les deux workers écrivent les mêmes sorties. Corrections : rendre le bail plus long que le nombre de tentatives fois le délai du job, plus les attentes. Les valeurs par défaut respectent cela, 4 × 10 min + 14 s font moins d'une heure, mais un délai de deux heures demande un bail de plus de 8 heures, ce qui bloque aussi longtemps le job d'un worker mort. La meilleure correction est de renouveler le bail pendant que le job tourne, avec un battement de cœur qui réécrit `expires` toutes les quelques minutes. Une réservation en base de données ferait la même chose avec un `UPDATE … WHERE owner = @me`.

</details>

<details>
<summary>Solution 4</summary>

Premier cas : la connexion se ferme sans acquittement, donc RabbitMQ remet le message en file et le livre à un autre consommateur, ou au même worker après son redémarrage. Cette livraison trouve `done.json`, affiche `already done, acknowledged without running`, et acquitte. Le job s'est exécuté une fois et est acquitté une fois. Second cas : la lettre morte est dans `renders.dead`, mais l'original est livré à nouveau. Le worker n'a pas enregistré la lettre morte comme terminée : il trouve `failed.txt` mais ne le vérifie pas, réserve le job, et l'exécute à nouveau. Un échec définitif échoue à nouveau et part une seconde fois aux lettres mortes, donc `renders.dead` en a deux copies. Un consommateur des lettres mortes devrait les dédoublonner par identifiant de message, ou le worker pourrait traiter `failed.txt` comme `done.json`, au prix de ne jamais réessayer un job que quelqu'un a corrigé sans vider son dossier.

</details>

<details>
<summary>Solution 5</summary>

Le test, dans `WorkerTests.cs` :

```csharp
[Fact]
public async Task Server_with_a_full_queue_is_not_a_candidate()
{
    await using var h = await Harness.StartAsync(output, new FakeOptions { Busy = 5 }, new FakeOptions());
    var job = Harness.NewJob(40);
    await h.Queue.EnqueueAsync(job);

    await h.RunAsync(h.NewWorker("w1"));

    Assert.Empty(h.Fakes[0].Stats.Executed);
    Assert.Equal(1, h.Fakes[1].Stats.Executed[job.Id]);
}
```

Il passe déjà, parce que le serveur libre a la file la plus courte. Faites-le d'abord échouer : donnez aussi `Busy = 5` au second serveur, et vérifiez que le job n'est pas envoyé en moins d'une seconde. Ensuite, dans `GpuPool.AcquireAsync`, filtrez `h.Health.QueueLength < maxQueue` avant de trier, et traitez « aucun candidat » comme « aucun serveur en bonne santé » : afficher et attendre. Les prompts de `--busy` ne s'exécutent jamais, donc le job attend alors indéfiniment ; arrêtez le worker dans le test avec `stopReceiving` et vérifiez que `Posted` est vide. Le code de cette solution n'a pas été compilé par le cours : *à vérifier*.

</details>

<details>
<summary>Solution 6</summary>

Le worker ne l'enregistre pas, donc `results.py` ne peut pas la calculer. Dans `Worker.HandleAsync`, mesurez de la réservation jusqu'à `store.Complete` avec un `Stopwatch` (C#) ou `System.nanoTime()` (Java), et passez la valeur à `Complete`, qui l'écrit dans `done.json`, par exemple `"seconds": 12.4`. Puis `results.py` lit `done.get("seconds", "")`. Pour le labo, la durée par tentative est plus utile que la durée par job, puisque les attentes du backoff font partie de la seconde : enregistrez les deux.

</details>

<details>
<summary>Solution 7</summary>

```yaml
spec:
  terminationGracePeriodSeconds: 90
  containers:
    - name: worker
      readinessProbe:
        exec:
          command: ["dotnet", "/app/comfy-worker.dll", "health", "--gpu", "gpu0=http://127.0.0.1:8188"]
        periodSeconds: 10
        timeoutSeconds: 8
```

`health` sort avec 1 quand aucun serveur ne répond, donc le pod n'est pas disponible pendant que ComfyUI démarre. Le délai de grâce doit couvrir `--grace-s 60`, plus l'interruption et la remise en file, plus l'arrêt de ComfyUI lui-même : 90 s laissent 30 s. Kubernetes envoie SIGTERM aux deux conteneurs en même temps, donc ComfyUI peut mourir avant que les jobs du worker se terminent ; un hook `preStop` sur le conteneur ComfyUI qui dort pendant le délai de grâce le garde en vie. Ce manifeste n'a pas été appliqué par le cours : *à vérifier*.

</details>

## Sources

- ComfyUI en v0.36.0, commit `ee71d5c` : [`server.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py), [`main.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py), [`execution.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py), [`comfy/cli_args.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py), [`comfy_execution/jobs.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_execution/jobs.py), [`extra_model_paths.yaml.example`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/extra_model_paths.yaml.example).
- Documentation de ComfyUI : [routes du serveur](https://docs.comfy.org/development/comfyui-server/comms_routes), [messages](https://docs.comfy.org/development/comfyui-server/comms_messages).
- .NET : [channels](https://learn.microsoft.com/dotnet/core/extensions/channels), [`PosixSignalRegistration`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.posixsignalregistration), [`ClientWebSocket`](https://learn.microsoft.com/dotnet/api/system.net.websockets.clientwebsocket), [API minimales](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis), [Kestrel](https://learn.microsoft.com/aspnet/core/fundamentals/servers/kestrel), [xUnit v3](https://xunit.net/docs/getting-started/v3/getting-started).
- Java : [`LinkedBlockingQueue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/LinkedBlockingQueue.html), [threads virtuels](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html), [`Runtime.addShutdownHook`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Runtime.html#addShutdownHook(java.lang.Thread)), [`java.net.http.WebSocket`](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/WebSocket.html), [JUnit](https://docs.junit.org/).
- RabbitMQ : [quorum queues](https://www.rabbitmq.com/docs/quorum-queues), [consumer prefetch](https://www.rabbitmq.com/docs/consumer-prefetch), [dead letter exchanges](https://www.rabbitmq.com/docs/dlx), [client .NET](https://www.rabbitmq.com/client-libraries/dotnet), [client Java](https://www.rabbitmq.com/client-libraries/java-client).
- M. Brooker, [Exponential Backoff And Jitter](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/), AWS Architecture Blog, 2015.
- Kubernetes : [Schedule GPUs](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/), [arrêt des pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination) ; NVIDIA [Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html).
