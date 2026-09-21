---
title: 10. État partagé et thread pool
description: Choisir Lock, Interlocked, les collections concurrentes et Parallel.ForEachAsync selon l'invariant, puis diagnostiquer la starvation sans transformer chaque attente asynchrone en thread bloqué.
sidebar:
  order: 10
---

Un bug concurrent ne demande pas un matériel malchanceux. Deux workers peuvent lire la même valeur, calculer le même successeur puis l'écrire. L'exemple exécutable force ce scheduling avec une barrière : deux incréments laissent `1`.

## Protéger l'invariant, pas la ligne

[`System.Threading.Lock`](https://learn.microsoft.com/dotnet/api/system.threading.lock) est la primitive moderne de .NET. On l'utilise quand plusieurs lectures et écritures forment un invariant. [`Interlocked`](https://learn.microsoft.com/dotnet/api/system.threading.interlocked) convient mieux à un compteur atomique ou à une boucle compare-and-swap. Une collection concurrente sécurise sa propre opération, pas une séquence « vérifier, appeler un service, mettre à jour ».

```text
two increments without synchronization: 1
Lock count: 10000
Interlocked count: 10000
AddOrUpdate count: 1000
```

`ConcurrentDictionary.AddOrUpdate` peut appeler une factory plusieurs fois sous contention. Les factories doivent rester pures ; les effets deviennent une opération séparée et idempotente.

## Le parallélisme est un budget

[`Parallel.ForEachAsync`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.parallel.foreachasync) borne les corps actifs avec `MaxDegreeOfParallelism`. Le programme observe deux corps pour une limite de deux. C'est un budget local, pas une backpressure end-to-end : le pool de connexions, les sockets et les files du broker ont leurs propres limites.

La starvation apparaît quand des threads bloquent pendant que le travail qui les débloquerait attend dans le thread pool. Préférer les attentes asynchrones pour l'I/O, borner le CPU et mesurer avec `dotnet-counters` avant d'augmenter les minimums.

## Exécuter la preuve

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l10
```

La sortie portable est dans [`expected/l10.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l10.txt).

## Exercices

1. Remplacer le compteur par un invariant à deux champs : total et checksum. Montrer pourquoi deux appels `Interlocked` ne rendent pas la paire atomique.
2. Mettre un appel HTTP dans `GetOrAdd`, compter les appels sous contention, puis supprimer cet effet.
3. Comparer des degrés 2, 8 et 64 devant une dépendance limitée à quatre appels.

<details>
<summary>Solutions</summary>

1. Protéger les deux champs avec un seul `Lock`, ou remplacer atomiquement une valeur immuable. Deux écritures atomiques indépendantes exposent un état intermédiaire.
2. La factory peut s'exécuter plusieurs fois même si une seule valeur gagne. L'effet doit être idempotent et indépendant du primitive de collection.
3. Le bon degré vient du débit et de la latence de queue mesurés. Le nombre de CPU ne définit pas la capacité de la dépendance.

</details>
