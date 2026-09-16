---
title: "Leçon 2 : le ramasse-miettes"
description: Générations et promotion, le seuil exact du tas des grands objets, les tas épinglé et figé, références faibles et finaliseurs, GC station de travail, serveur et concurrent, ce que rapporte GC.GetGCMemoryInfo, et les allocations mesurées avec le MemoryDiagnoser de BenchmarkDotNet sur Guitar Alchemist.
sidebar:
  label: 2. Le ramasse-miettes
  order: 2
---

La leçon 1 a compté les octets de chaque allocation. Cette leçon suit ces octets une fois alloués : quel tas les reçoit, quand le ramasse-miettes (GC) les examine de nouveau, ce qu'il fait des objets qui survivent, et comment sa configuration change tout cela. Chaque comportement est observé depuis l'intérieur du programme avec la classe [`GC`](https://learn.microsoft.com/dotnet/api/system.gc), puis les allocations de vrai code GA sont mesurées avec [BenchmarkDotNet](https://benchmarkdotnet.org/).

Les liens vers GA pointent vers le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) ; les liens vers le runtime pointent vers le commit [`4271d88`](https://github.com/dotnet/runtime/tree/4271d88e0aebf3d04f188f1334c2220d80555ef6) de `dotnet/runtime`, qui porte le tag `v10.0.12`.

## Exécuter le programme de la leçon

```bash
bash code/csharp-advanced/check.sh                                   # chaque leçon, comparée avec expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- l2  # cette leçon seulement, après check.sh
```

Le code est dans [`Advanced/Lesson2.cs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson2.cs). Les lignes qui commencent par `# ` dépendent de la machine (tailles des tas, temps de pause, nombre de processeurs) : la leçon les cite telles qu'obtenues sur la machine de l'auteur, un Intel Core Ultra 9 285K avec 24 cœurs et 64 Go de mémoire, et sur les runners de la CI quand ils diffèrent de façon intéressante.

## Les générations

Le GC de .NET est *générationnel* : il suppose que la plupart des objets meurent jeunes, et collecte les objets jeunes bien plus souvent que les anciens ([Notions fondamentales du ramasse-miettes](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals#generations)). Les nouveaux objets vont en génération 0. Un objet encore référencé quand sa génération est collectée est *promu* dans la suivante, jusqu'à la génération 2. Une collection gen0 n'examine que gen0 (plus les références que les objets anciens détiennent vers les jeunes, suivies par la barrière d'écriture) ; une collection gen2, aussi appelée collection *complète*, examine tout.

Le programme alloue un accord de trois notes et appelle [`GC.Collect()`](https://learn.microsoft.com/dotnet/api/system.gc.collect), qui force une collection complète et bloquante ([`Lesson2.cs#L58-L73`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson2.cs#L58-L73)) :

```text
== Generations: an object that survives a collection is promoted
new int[3]           generation 0
after GC.Collect()   generation 1
after a second one   generation 2
after a third one    generation 2
GC.Collect(0) then new int[3]: generation 0
```

Deux collections ont suffi à rendre l'accord ancien. C'est le piège d'un appel à `GC.Collect()` dans le code d'une application : il ne libère pas la mémoire plus tôt de façon utile, mais il promeut chaque objet vivant, qui attend alors, pour être récupéré, la prochaine collection complète, la plus coûteuse de toutes. Le programme du cours ne l'appelle que pour rendre visible le comportement du GC.

## Le tas des grands objets, à l'octet près

Les objets de 85 000 octets ou plus vont dans le tas des grands objets (LOH), qui n'est collecté qu'avec la génération 2 et n'est pas compacté par défaut ([Le tas des grands objets](https://learn.microsoft.com/dotnet/standard/garbage-collection/large-object-heap)). La documentation dit « 85 000 octets » ; le programme trouve la limite exacte.

```text
== Large object heap: 85,000 bytes and more, counted with the object header
new byte[   84,975]  object size    85,000  generation 0
new byte[   84,976]  object size    85,000  generation 2
new byte[1,000,000]  object size 1,000,024  generation 2
new double[10,622]   object size    85,000  generation 2
```

`GC.GetGeneration` indique la génération 2 pour les objets du LOH. Les deux premiers tableaux coûtent chacun 85 000 octets, et pourtant seul le second est un grand objet. Le runtime décide avant l'arrondi : dans [`gchelpers.cpp#L644-L659`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/vm/gchelpers.cpp#L644-L659), le `totalSize` d'un tableau est son nombre d'éléments multiplié par la taille d'un élément, plus la taille de base de 24 octets, et le tableau va dans le LOH quand `totalSize >= LARGE_OBJECT_SIZE`, constante définie à 85 000 dans [`gc.h#L105`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/gc/gc.h#L105). Avec 24 + 84 975 = 84 999 octets, le tableau reste petit, et n'est arrondi à 85 000 qu'ensuite. Avec 24 + 84 976 = 85 000, il est grand. Un tableau de 10 622 `double` atteint exactement 85 000.

Le seuil se configure avec `GCLOHThreshold` ([`gcconfig.h#L82`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/gc/gcconfig.h#L82), [paramètres du GC](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector#large-object-heap-threshold)), et le programme lit sa valeur actuelle dans la section suivante. De grands tampons alloués puis abandonnés dans une boucle sont une cause classique de collections gen2 ; [`ArrayPool<T>.Shared`](https://learn.microsoft.com/dotnet/api/system.buffers.arraypool-1.shared) existe pour les réutiliser à la place.

## Le tas des objets épinglés

Le code natif, ou une opération d'entrée-sortie en cours, peut avoir besoin d'un tableau que le GC ne doit pas déplacer pendant qu'il compacte le tas. Épingler un tableau ordinaire avec `fixed` ou un `GCHandle` bloque le compactage autour de lui et fragmente la génération 0. Depuis .NET 5, [`GC.AllocateArray<T>(length, pinned: true)`](https://learn.microsoft.com/dotnet/api/system.gc.allocatearray) alloue plutôt sur un tas séparé, le tas des objets épinglés (POH), qui, comme le LOH, est collecté avec la génération 2.

```text
== Pinned object heap: GC.AllocateArray(pinned: true)
pinned byte[1024]    generation 2
ordinary byte[1024]  generation 0
heaps in GCGenerationInfo: 5 (gen0, gen1, gen2, LOH, POH)
```

[`GCMemoryInfo.GenerationInfo`](https://learn.microsoft.com/dotnet/api/system.gcmemoryinfo.generationinfo) décrit cinq tas : les trois générations, le LOH et le POH. Sur la machine de l'auteur, après la collection, le POH contenait 9 232 octets : le runtime lui-même y avait déjà placé 8 184 octets avant le kilo-octet du programme.

## Accessibilité : références faibles et finaliseurs

Le GC libère un objet quand plus rien d'*accessible* n'y fait référence : aucune variable locale d'une méthode en cours d'exécution, aucun champ statique, aucun champ d'un autre objet accessible. Une [`WeakReference`](https://learn.microsoft.com/dotnet/standard/garbage-collection/weak-references) pointe vers un objet sans le maintenir en vie ([`Lesson2.cs#L99-L135`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson2.cs#L99-L135)). Les objets sont créés dans une méthode séparée, non intégrée dans l'appelant : dans la méthode qui exécute `GC.Collect()`, une variable locale pourrait encore les retenir, surtout dans du code non optimisé.

```text
== Reachability: a weak reference does not keep an object alive
only weakly reachable:  IsAlive False
still referenced:       IsAlive True (4 notes)
```

Une classe dotée d'un [finaliseur](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/finalizers) (`~Finalizable()`) suit un chemin plus long. Quand le GC trouve un tel objet inaccessible, il ne peut pas encore le libérer : il le place dans une file, et un thread de finalisation dédié exécute son finaliseur. L'objet, de nouveau accessible depuis cette file, est libéré par une collection ultérieure. Une référence faible *courte* cesse de suivre l'objet dès qu'il est inaccessible ; une référence faible *longue*, créée avec `trackResurrection: true`, le suit jusqu'à ce qu'il ait vraiment disparu.

```text
== Finalizers: a finalizable object is freed one collection later
after 1 collection:  finalized 1, short weak IsAlive False, long weak IsAlive True
after 2 collections: finalized 1, short weak IsAlive False, long weak IsAlive False
bytes of new Finalizable(): 24, of new object(): 24
```

L'objet finalisable ne coûte pas plus d'octets, mais il survit à une collection de plus, en étant peut-être promu au passage, et son inscription dans la file de finalisation ralentit l'allocation. C'est pourquoi les classes [`IDisposable`](https://learn.microsoft.com/dotnet/standard/garbage-collection/implementing-dispose) qui ont un finaliseur appellent `GC.SuppressFinalize(this)` dans `Dispose()`, et pourquoi la plupart des classes ne devraient pas avoir de finaliseur du tout : enveloppez les handles natifs dans un [`SafeHandle`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.safehandle), qui en possède déjà un.

## GC station de travail, serveur et concurrent

Le runtime fournit un seul GC doté de plusieurs modes ([GC de station de travail et GC de serveur](https://learn.microsoft.com/dotnet/standard/garbage-collection/workstation-server-gc)) :

- Le GC **station de travail**, par défaut pour les applications console et de bureau, utilise un seul tas et collecte sur le thread qui a déclenché la collection.
- Le GC **serveur**, par défaut pour ASP.NET Core, utilise un tas et un thread de GC par processeur logique, avec des budgets gen0 bien plus grands : plus de débit, plus de mémoire. Depuis .NET 9, [DATAS](https://learn.microsoft.com/dotnet/standard/garbage-collection/datas) (adaptation dynamique à la taille des applications) est activé par défaut pour le GC serveur et ajuste le nombre de tas à la charge.
- Le GC **concurrent** (en arrière-plan), activé par défaut dans les deux modes, exécute l'essentiel d'une collection gen2 pendant que l'application continue de tourner.

Vous les choisissez dans le fichier projet (`<ServerGarbageCollection>`, `<ConcurrentGarbageCollection>`), dans `runtimeconfig.json` (`System.GC.Server`, `System.GC.Concurrent`), ou avec des variables d'environnement ([paramètres du GC](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector)). `check.sh` exécute le programme trois fois : avec les valeurs par défaut, avec `DOTNET_gcServer=1`, et avec `DOTNET_gcConcurrent=0`. [`GC.GetConfigurationVariables()`](https://learn.microsoft.com/dotnet/api/system.gc.getconfigurationvariables) renvoie les paramètres que le GC utilise réellement.

```text
== GC mode
GCSettings.IsServerGC: False
GCSettings.LatencyMode: Interactive
GC.MaxGeneration: 2
GC.GetConfigurationVariables()["ServerGC"]: False
GC.GetConfigurationVariables()["ConcurrentGC"]: True
GC.GetConfigurationVariables()["LOHThreshold"]: 85000
GC.GetConfigurationVariables()["GCDynamicAdaptationMode"]: 1
```

```text
== GC mode
GCSettings.IsServerGC: True
GCSettings.LatencyMode: Interactive
GC.MaxGeneration: 2
GC.GetConfigurationVariables()["ServerGC"]: True
GC.GetConfigurationVariables()["ConcurrentGC"]: True
GC.GetConfigurationVariables()["LOHThreshold"]: 85000
GC.GetConfigurationVariables()["GCDynamicAdaptationMode"]: 1
```

```text
== GC mode
GCSettings.IsServerGC: False
GCSettings.LatencyMode: Batch
GC.MaxGeneration: 2
GC.GetConfigurationVariables()["ServerGC"]: False
GC.GetConfigurationVariables()["ConcurrentGC"]: False
GC.GetConfigurationVariables()["LOHThreshold"]: 85000
GC.GetConfigurationVariables()["GCDynamicAdaptationMode"]: 1
```

[`GCSettings.LatencyMode`](https://learn.microsoft.com/dotnet/api/system.runtime.gcsettings.latencymode) reflète la concurrence : `Interactive` avec le GC en arrière-plan, `Batch` sans lui. `GCDynamicAdaptationMode` vaut 1 dans les trois exécutions : le paramètre est activé, mais il ne s'applique que lorsque le GC serveur l'est aussi. Les lignes qui dépendent de la machine montrent ce que coûte le GC serveur en mémoire :

| Machine | Processeurs | Tas en station de travail | `GCGen0MaxBudget` en station de travail | Tas en serveur | `GCGen0MaxBudget` en serveur |
|---|---:|---:|---:|---:|---:|
| Auteur (Windows, x64) | 24 | 1 | 18,874,368 | 24 | 209,715,200 |
| CI Linux (x64) | 4 | 1 | 16,777,216 | 4 | 209,715,200 |
| CI Windows (x64) | 4 | 1 | 25,165,824 | 4 | 209,715,200 |
| CI macOS (Arm64) | 3 | 1 | 6,291,456 | 3 | 209,715,200 |

Le budget gen0 est la quantité d'allocations au-delà de laquelle une collection gen0 démarre ; pour le GC station de travail, le runtime le déduit de la taille du cache du processeur, il change donc d'une machine à l'autre. Le GC station de travail non concurrent a indiqué 134 217 728 octets sur les quatre machines.

## Ce que rapporte `GC.GetGCMemoryInfo`

[`GC.GetGCMemoryInfo()`](https://learn.microsoft.com/dotnet/api/system.gc.getgcmemoryinfo) décrit la dernière collection : sa génération, si elle a compacté le tas, ses temps de pause, et la taille de chaque tas avant et après. Le programme force une collection gen2 bloquante et compactante avec `GC.Collect(2, GCCollectionMode.Forced, blocking: true, compacting: true)`, puis la lit :

```text
== GC.GetGCMemoryInfo after an induced, blocking, compacting collection
Generation 2, Compacted True, Concurrent False
# Index 11, PauseDurations[0] 0.156 ms, PauseTimePercentage 4.3%
# HeapSizeBytes 275,648, FragmentedBytes 528, TotalCommittedBytes 1,495,040
# TotalAvailableMemoryBytes 68,403,589,120, HighMemoryLoadThresholdBytes 61,563,230,208
#   gen0: before 4,200, after 560
#   gen1: before 416, after 0
#   gen2: before 277,504, after 266,904
#   LOH: before 0, after 0
#   POH: before 8,184, after 8,184
```

C'était la onzième collection du programme (`Index`) ; elle a mis le processus en pause pendant 0,16 milliseconde et a laissé un tas de 276 Ko : un petit programme, même avec les tables statiques de GA chargées. `TotalAvailableMemoryBytes` est la mémoire physique que le GC pense pouvoir utiliser, ou la limite du conteneur quand il y en a une ; au-delà de `HighMemoryLoadThresholdBytes` (90 % par défaut), il collecte plus agressivement. Les mêmes valeurs sont exportées comme [métriques du runtime](https://learn.microsoft.com/dotnet/core/diagnostics/built-in-metrics-runtime), par exemple `dotnet.gc.last_collection.heap.size`, qu'un tableau de bord de supervision peut suivre en production ; la leçon 19 les utilise.

## Les objets à courte durée de vie sont bon marché, jusqu'à un certain point

L'hypothèse générationnelle rend les objets à courte durée de vie bon marché : une collection gen0 ne regarde que les objets vivants, et ignorer les objets morts ne coûte rien. Le programme alloue un million de petits tableaux, chacun conservé seulement jusqu'à ce que les seize suivants le remplacent ([`Lesson2.cs#L160-L177`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson2.cs#L160-L177)) :

```text
== Allocation budget: many short-lived objects, few collections
allocated 32,000,152 bytes for 1,000,000 arrays of 2 ints, 16 still referenced
```

32 Mo de déchets ont provoqué une seule collection gen0 sur la machine de l'auteur, sur la CI Linux et sur la CI Windows, et cinq sur la CI macOS, dont le budget gen0 est de 6 Mo. Aucun objet n'a été promu. Le coût revient quand les objets à courte durée de vie deviennent grands (le LOH), ou vivent juste assez longtemps pour être promus en gen1 ou en gen2 : un cache propre à une requête, un tampon qui survit à un `await`. Le GC doit alors les copier, et finir par exécuter une collection complète pour les libérer.

## Mesurer les allocations avec BenchmarkDotNet

`GC.GetAllocatedBytesForCurrentThread()` convient pour un appel. Pour du code qui s'exécute des millions de fois, l'attribut [`[MemoryDiagnoser]`](https://benchmarkdotnet.org/articles/configs/diagnosers.html) de BenchmarkDotNet indique, par opération, les octets alloués, ainsi que le nombre de collections gen0, gen1 et gen2 pour 1 000 opérations. [`Benchmarks/AllocationBenchmarks.cs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Benchmarks/AllocationBenchmarks.cs) mesure les allocations de la leçon 1, dont `PitchClassSetId.ItemsSpan` de GA face à un tableau mis en cache :

```csharp
[MemoryDiagnoser]
public class AllocationBenchmarks
{
    private static readonly PitchClassSetId[] CachedIds = [.. PitchClassSetId.Items];

    [Benchmark(Baseline = true)]
    public int GaPitchClassSetIdItemsSpan() => PitchClassSetId.ItemsSpan.Length;

    [Benchmark]
    public int CachedArraySpan() => new ReadOnlySpan<PitchClassSetId>(CachedIds).Length;
```

```bash
cd code/csharp-advanced
dotnet run -c Release --project Benchmarks -- --filter "*AllocationBenchmarks*"
```

Sur la machine de l'auteur, sans rien d'autre en cours d'exécution :

```text
BenchmarkDotNet v0.15.8, Windows 11 (10.0.26200.9445/25H2/2025Update/HudsonValley2)
Intel Core Ultra 9 285K 3.70GHz, 1 CPU, 24 logical and 24 physical cores
.NET SDK 10.0.112
  [Host]     : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
  DefaultJob : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
```

| Method                     | Mean          | Error      | StdDev      | Median        | Ratio | RatioSD | Gen0   | Allocated | Alloc Ratio |
|--------------------------- |--------------:|-----------:|------------:|--------------:|------:|--------:|-------:|----------:|------------:|
| GaPitchClassSetIdItemsSpan | 1,158.0046 ns | 70.7784 ns | 208.6918 ns | 1,173.2269 ns | 1.035 |    0.28 | 0.8698 |   16408 B |       1.000 |
| CachedArraySpan            |     0.0899 ns |  0.0292 ns |   0.0860 ns |     0.0770 ns | 0.000 |    0.00 |      - |         - |       0.000 |
| GaPitchClassItemsSpan      |     0.0543 ns |  0.0258 ns |   0.0761 ns |     0.0130 ns | 0.000 |    0.00 |      - |         - |       0.000 |
| VoicingWithSplit           |    60.0266 ns |  1.2168 ns |   2.3151 ns |    60.1405 ns | 0.054 |    0.01 | 0.0114 |     216 B |       0.013 |
| VoicingWithSpans           |    46.0624 ns |  0.9406 ns |   2.2536 ns |    46.1613 ns | 0.041 |    0.01 |      - |         - |       0.000 |
| Format                     |    19.1902 ns |  0.4152 ns |   0.8759 ns |    19.1456 ns | 0.017 |    0.00 | 0.0030 |      56 B |       0.003 |
| Interpolate                |    12.4961 ns |  0.3073 ns |   0.7479 ns |    12.6991 ns | 0.011 |    0.00 | 0.0017 |      32 B |       0.002 |

Les temps viennent d'une seule machine et d'une seule exécution, et la CI ne les compare jamais. Les allocations, elles, ne dépendent pas de la machine :

- `GaPitchClassSetIdItemsSpan` alloue **16 408 octets à chaque appel**, la copie des 4 096 identifiants qu'a trouvée la leçon 1, et déclenche 0,87 collection gen0 pour mille appels : une boucle qui lit `ItemsSpan` mille fois provoque presque une collection. Elle prend aussi environ une microseconde, et ses temps sont dispersés (BenchmarkDotNet avertit que la distribution est *multimodale*), parce que certains appels paient une collection et d'autres non.
- `CachedArraySpan` et le propre `PitchClass.ItemsSpan` de GA, qui renvoie un tableau mis en cache, n'allouent rien. Leurs moyennes, un dixième de nanoseconde, sont en dessous de ce que BenchmarkDotNet peut mesurer : il affiche *ZeroMeasurement*, « indistinguishable from the empty method », c'est-à-dire impossible à distinguer de la méthode vide. Le JIT les a réduits à la lecture d'une longueur.
- Analyser le voicing `"x 3 2 0 1 0"` avec `string.Split` alloue 216 octets (le tableau et six chaînes) ; la version à base de spans n'alloue rien et est environ un quart plus rapide.
- `Format` alloue 56 octets, la boîte et la chaîne, et `Interpolate` 32, la chaîne seule, comme mesuré dans la leçon 1. La colonne `Gen0` traduit ces octets en collections : 3 par million d'appels pour `Format`.

Lisez `Allocated` en premier : cette valeur est exacte et reproductible. Lisez `Mean` avec ses colonnes `Error` et `StdDev`, et avec les avertissements que BenchmarkDotNet affiche sous le tableau. La leçon 4 explique comment obtenir des temps dignes de confiance.

## Si vous connaissez Spring et Reactor

Les deux plateformes sont générationnelles, toutes deux ont remplacé la plupart de leurs options de réglage par de l'ergonomie, et elles ne partagent presque aucun vocabulaire. Le tableau relie ce que cette leçon a mesuré à ce que vous liriez dans un [guide de réglage du GC](https://docs.oracle.com/en/java/javase/25/gctuning/).

| .NET | HotSpot |
|---|---|
| générations 0, 1 et 2 | une génération jeune (eden et survivants) et une génération ancienne ; [G1](https://docs.oracle.com/en/java/javase/25/gctuning/garbage-first-g1-garbage-collector1.html) donne à chaque région l'un de ces rôles |
| le tas des grands objets, à partir de 85 000 octets | les objets *humongous* de G1, « larger or equal the size of half a region », alloués en régions contiguës de la génération ancienne. La taille de région est ergonomique : environ 2 048 régions, jusqu'à 32 Mo chacune |
| le tas des objets épinglés, un tas à part | rien d'équivalent. L'épinglage est transitoire, limité à une région critique JNI ; depuis la [JEP 423](https://openjdk.org/jeps/423) (JDK 22), G1 épingle la *région* au lieu de désactiver la collecte, et journalise un échec d'évacuation avec le motif `Pinned` |
| GC station de travail ou serveur, choisi par configuration | un ramasse-miettes parmi [G1](https://openjdk.org/jeps/248) — celui par défaut, et depuis la [JEP 523](https://openjdk.org/jeps/523) dans tous les environnements, plus seulement sur les machines de type serveur —, Parallel, Serial et [ZGC](https://docs.oracle.com/en/java/javase/25/gctuning/z-garbage-collector.html) |
| DATAS dimensionne le tas selon la charge | l'ergonomie de chaque ramasse-miettes, plus le `-XX:SoftMaxHeapSize` de ZGC : une limite souple qu'il s'efforce de respecter, « but is still allowed to grow beyond this limit up to the maximum heap size » |
| les durées de pause lues dans `GC.GetGCMemoryInfo()` | un objectif annoncé par ramasse-miettes : celui de ZGC est « Pause times should not exceed 1 millisecond » ([JEP 439](https://openjdk.org/jeps/439)), resserré depuis les 10 ms de sa première JEP |
| les finaliseurs, et le thread de finalisation | [`finalize()`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Object.html), déprécié pour suppression depuis le JDK 18 ([JEP 421](https://openjdk.org/jeps/421)) et toujours actif par défaut ; [`Cleaner`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ref/Cleaner.html) et `PhantomReference` à sa place |
| `WeakReference<T>`, `ConditionalWeakTable` | [`WeakReference`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ref/package-summary.html), `PhantomReference`, et `SoftReference`, « cleared at the discretion of the garbage collector in response to memory demand » — .NET n'a pas de référence souple |
| `GC.GetGCMemoryInfo()` et `GC.GetConfigurationVariables()`, depuis l'intérieur du processus | [`GarbageCollectorMXBean`](https://docs.oracle.com/en/java/javase/25/docs/api/java.management/java/lang/management/GarbageCollectorMXBean.html) avec `getCollectionCount()` et `getCollectionTime()`, `-Xlog:gc`, et JDK Flight Recorder |
| `[MemoryDiagnoser]` : octets et collectes gen0 par opération | le `-prof gc` de JMH, dont `gc.alloc.rate.norm` donne les octets par opération |

Une ligne mérite de la prudence, parce que la leçon 1 l'a mesurée ici. .NET 9 et 10 allouent sur la pile les boxes et les petits objets qui ne s'échappent pas. L'[analyse d'échappement](https://docs.oracle.com/en/java/javase/25/vm/java-hotspot-virtual-machine-performance-enhancements.html) de HotSpot est documentée plus étroitement : pour un objet qui « does not escape », le compilateur serveur « eliminates the scalar replaceable object allocations and the associated locks from generated code » — l'objet est décomposé en ses champs plutôt que déplacé sur la pile. Le résultat mesuré est le même, zéro octet alloué ; la formulation de la garantie, non.

Pour un service réactif, le nombre sur lequel cette leçon insiste — les octets par opération — compte encore plus qu'ici. Un pipeline Reactor alloue un objet abonné par opérateur à *chaque* souscription, et un serveur WebFlux souscrit une fois par requête : les allocations croissent donc avec le trafic, ce qu'un benchmark isolé ne montre pas. Reactor ne publie aucun chiffre d'allocation ; `-prof gc` sur votre propre pipeline est la façon de l'obtenir.

## Exercices

1. Quel est le plus petit `char[]` qui va dans le tas des grands objets ?
2. [`GC.TryStartNoGCRegion`](https://learn.microsoft.com/dotnet/api/system.gc.trystartnogcregion) demande au GC de ne pas collecter tant qu'une section critique alloue moins d'une quantité donnée. Démarrez une région de 1 Mo, allouez mille tableaux de 100 octets, et indiquez le mode de latence et le nombre de collections gen0 à l'intérieur de la région.
3. `GC.GetGeneration("C major")` ne renvoie ni 0, ni 1, ni 2. Que renvoie-t-il, et pourquoi ? Essayez aussi `typeof(PitchClass)`.

<details>
<summary>Solutions</summary>

1. Un `char` occupe 2 octets, et la taille de base du tableau est de 24 octets : 24 + 2 × *n* ≥ 85 000 donne *n* = **42 488**. Avec un élément de moins, le tableau reste en génération 0.

    ```text
    1. new char[42,487] generation 0, new char[42,488] generation 2
    ```

2. La région démarre, le mode de latence devient `NoGCRegion`, et mille tableaux de 128 octets chacun (24 + 100, arrondi au multiple supérieur) tiennent dans le mégaoctet réservé : aucune collection. `EndNoGCRegion` restaure le mode précédent. Allouer plus que la quantité demandée met fin à la région en silence, et `EndNoGCRegion` lève alors `InvalidOperationException`.

    ```text
    2. TryStartNoGCRegion(1 MB) True, LatencyMode NoGCRegion, gen0 collections for 1,000 arrays 0
       after EndNoGCRegion: LatencyMode Interactive, 16 arrays kept
    ```

3. Il renvoie `int.MaxValue`. Depuis .NET 8, les littéraux de chaîne, les objets `RuntimeType` et certains autres objets dont le runtime sait qu'ils vivront indéfiniment sont alloués sur un tas *figé*, hors du GC, que le GC n'examine jamais ([note sur ce changement cassant](https://learn.microsoft.com/dotnet/core/compatibility/core-libraries/8.0/getgeneration-return-value)). Une chaîne construite à l'exécution avec les mêmes caractères est un objet gen0 ordinaire. Le code qui utilisait la génération comme index de tableau ne fonctionne plus sur ces objets.

    ```text
    3. GC.GetGeneration("C major") 2147483647, of new string('C', 7) 0, of typeof(PitchClass) 2147483647
    ```

</details>

## À retenir

- Les nouveaux objets commencent en génération 0 ; chaque collection à laquelle ils survivent les promeut, jusqu'à la génération 2. Dans le code d'une application, `GC.Collect()` sert surtout à promouvoir les objets vivants.
- Un tableau va dans le tas des grands objets quand sa taille non arrondie, 24 octets plus ses éléments, atteint 85 000 octets : `byte[84,976]`, `char[42,488]`, `double[10,622]`. Le LOH et le tas des objets épinglés sont collectés avec la génération 2.
- Un finaliseur retarde la libération d'au moins une collection. Préférez `IDisposable` et `SafeHandle`.
- Le GC serveur échange de la mémoire contre du débit : un tas par processeur et un budget gen0 de 200 Mo, ajusté par DATAS depuis .NET 9. Les budgets du GC station de travail dépendent de la machine.
- `GC.GetGCMemoryInfo()` et `GC.GetConfigurationVariables()` montrent, depuis l'intérieur du processus, ce qu'a fait le GC et comment il est configuré.
- `[MemoryDiagnoser]` transforme « ceci alloue » en octets et en collections par opération. `PitchClassSetId.ItemsSpan` de GA y apparaît avec 16 408 octets par appel et presque une collection gen0 pour mille appels.

## Sources

- Microsoft Learn : [Notions fondamentales du ramasse-miettes](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals), [Le tas des grands objets](https://learn.microsoft.com/dotnet/standard/garbage-collection/large-object-heap), [GC de station de travail et GC de serveur](https://learn.microsoft.com/dotnet/standard/garbage-collection/workstation-server-gc), [DATAS](https://learn.microsoft.com/dotnet/standard/garbage-collection/datas), [Paramètres de configuration du GC](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector), [Références faibles](https://learn.microsoft.com/dotnet/standard/garbage-collection/weak-references), [Finaliseurs](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/finalizers), [`GC.GetGeneration` peut renvoyer `Int32.MaxValue`](https://learn.microsoft.com/dotnet/core/compatibility/core-libraries/8.0/getgeneration-return-value), [Métriques du runtime .NET](https://learn.microsoft.com/dotnet/core/diagnostics/built-in-metrics-runtime).
- dotnet/runtime au tag `v10.0.12` (commit `4271d88`) : [`gchelpers.cpp`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/vm/gchelpers.cpp#L644-L659), [`gc.h`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/gc/gc.h#L105), [`gcconfig.h`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/gc/gcconfig.h#L82).
- BenchmarkDotNet : [Diagnostiqueurs](https://benchmarkdotnet.org/articles/configs/diagnosers.html).
