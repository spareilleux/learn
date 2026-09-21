---
title: 15. Services hébergés et travail en arrière-plan
description: Maîtriser démarrage, arrêt, fautes, files bornées et scopes d'injection avec IHostedService et BackgroundService.
sidebar:
  order: 15
---

Un [`IHostedService`](https://learn.microsoft.com/dotnet/core/extensions/scoped-service) participe au cycle de vie de l'hôte. [`BackgroundService`](https://learn.microsoft.com/dotnet/core/extensions/workers) fournit la boucle `ExecuteAsync`, mais l'hôte reste propriétaire du démarrage, de la cancellation et de l'arrêt.

## Prérequis

Suivez d'abord [l'injection de dépendances et les options](13-dependency-injection-options/) ainsi que [les channels](06-channels/). Vous devez déjà comprendre les durées de vie des services, les cancellation tokens et les flux asynchrones.

## L'hôte possède le cycle de vie

L'expérience démarre un hôte, attend des gates de terminaison explicites, traite deux éléments, puis demande l'arrêt. Aucun `Thread.Sleep` : chaque attente est bornée à cinq secondes.

Dans .NET 10, [tout `BackgroundService.ExecuteAsync` s'exécute sur un thread d'arrière-plan](https://learn.microsoft.com/dotnet/core/compatibility/extensions/10.0/backgroundservice-executeasync-task). Le travail qui doit finir avant le démarrage des autres services appartient au constructeur, à [`StartAsync`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.hosting.ihostedservice.startasync) ou à [`IHostedLifecycleService`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.hosting.ihostedlifecycleservice), pas avant le premier `await` d'`ExecuteAsync`.

## Une file bornée est un contrat applicatif

Le worker consomme un [`Channel<T>`](https://learn.microsoft.com/dotnet/core/extensions/channels) borné. `BoundedChannelFullMode.Wait` applique la backpressure quand la file est pleine. Une vraie API de soumission devrait attendre `WriteAsync` ; cette preuve utilise `TryWrite`, car sa capacité et ses deux écritures sont fixes.

[`AddHostedService`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.dependencyinjection.servicecollectionhostedserviceextensions.addhostedservice) enregistre le worker comme singleton. Une dépendance scoped doit donc être résolue dans un nouvel [`IServiceScope`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.dependencyinjection.iservicescope) pour chaque élément. L'injecter dans le constructeur du worker créerait une dépendance captive.

```text
== The host starts one singleton worker and the queue owns the work
startup observed: True
queued results: C major@scope-1 | G major@scope-2
fresh scope per item: True
shutdown cancellation observed: True
```

## Les fautes relèvent d'une stratégie

La stratégie par défaut de l'hôte .NET 10 arrête l'application quand un `BackgroundService` lève une exception. La preuve fixe explicitement `BackgroundServiceExceptionBehavior.StopHost`, libère une gate de faute et observe `ApplicationStopping` :

```text
== A BackgroundService fault stops its host
fault requested host stop: True
```

Arrêter l'hôte n'est pas une reprise. En production, il faut encore définir retry, dead-letter ou intervention opérateur pour le travail répétable sans danger.

## Exécuter la preuve

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l15
```

La sortie vérifiée est [`expected/l15.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l15.txt).

## Exercices

1. Remplacer `TryWrite` par une API asynchrone et prouver qu'un troisième élément attend quand les deux places sont occupées.
2. Ajouter un résultat d'échec par élément sans arrêter le worker singleton.
3. Introduire un second consommateur et préciser quelle garantie d'ordre disparaît.

<details>
<summary>Solutions</summary>

1. Renvoyer `ValueTask`, attendre `Writer.WriteAsync` et retenir les deux premiers éléments avec des gates. Libérer une gate puis vérifier que la troisième écriture termine, sans déduire un blocage d'un délai.
2. Capturer l'exception autour d'un seul élément, terminer son `TaskCompletionSource` avec un échec typé et continuer la boucle. Ne pas traiter la cancellation de l'hôte comme un échec métier.
3. Mettre `SingleReader = false` et lancer deux workers. Les lectures restent FIFO, mais l'ordre de fin dépend du traitement ; ajouter des numéros de séquence si l'aval doit réordonner.

</details>
