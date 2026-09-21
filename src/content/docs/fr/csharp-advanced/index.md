---
title: C# avancé — Mission
description: Ce qui se passe sous le capot de C# 14, .NET 10 et ASP.NET Core — mémoire, ramasse-miettes, async, performances mesurées, channels, TPL Dataflow, Rx.NET et flux asynchrones, puis la pile web et l'outillage — chaque affirmation vérifiée par un programme, par l'IL ou par un benchmark, sur du vrai code de Guitar Alchemist, avec les équivalents Spring et Reactor.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Chaque sortie des leçons vient de [`code/csharp-advanced`](https://github.com/spareilleux/learn/tree/main/code/csharp-advanced). [`check.sh`](https://github.com/spareilleux/learn/blob/b4d713f86711b770a75d7504f334c5871c95f820/code/csharp-advanced/check.sh) compile le programme du cours avec [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) cloné au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), exécute chaque leçon, désassemble les exemples avec [l'outil en ligne de commande d'ILSpy](https://github.com/icsharpcode/ILSpy/tree/72dbe6f41d480728ffa60bb68d1b95f9118d6b15/ICSharpCode.ILSpyCmd), compile chaque extrait rejeté avec [Roslyn](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/), et compare le tout aux fichiers attendus. [`.github/workflows/csharp-advanced-examples.yml`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/.github/workflows/csharp-advanced-examples.yml) fait de même sous Linux, Windows et macOS, et vérifie que chaque benchmark s'exécute. Les lignes qui dépendent de la machine commencent par `# ` et ne sont pas comparées ; les temps des benchmarks viennent de la machine de l'auteur, jamais de la CI. Sorties capturées en septembre 2026 avec le SDK .NET 10.0.112 et le runtime .NET 10.0.12.
:::

## Pourquoi j'apprends ça

J'écris du C# depuis des années, et l'essentiel de ce que je sais de ses performances relève du folklore : « les structs sont plus rapides », « évitez LINQ », « toujours `ConfigureAwait(false)` », « `FrozenDictionary`, c'est le rapide ». Une partie était vraie avec .NET Framework 4.5 et devient fausse sur .NET 10, où le JIT supprime des allocations que l'IL demande. Ce cours remplace chaque morceau de folklore par quelque chose que je peux examiner : la taille d'un objet, l'IL émis par le compilateur, la machine à états derrière `await`, la génération d'un tableau, un tableau de résultats BenchmarkDotNet.

Il en va de même pour le code qui fait passer des données entre tâches, et pour ASP.NET Core. J'utilise des channels et `BackgroundService` sans avoir vérifié ce qui se passe quand un consommateur s'arrête tôt ou qu'un producteur lève une exception, et je configure ASP.NET Core en recopiant ce qui a marché la dernière fois. Les parties suivantes du cours transforment aussi ces questions en programmes.

Les mesures portent sur du vrai code, pas sur des classes jouets : [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA), une grande base de code .NET 10 consacrée à la théorie musicale. Ses objets valeur, ses caches, son générateur de voicings et ses services hébergés sont exactement le genre de code où ces questions se posent, et les leçons ont trouvé plusieurs endroits où GA paie pour quelque chose qu'il ne voulait pas, ou se bloque là où il devrait échouer.

## À qui s'adresse ce cours

Vous écrivez du C# tous les jours et connaissez bien le langage : génériques, LINQ, `async`/`await`, records, pattern matching. Vous voulez savoir ce que le compilateur, le JIT, le ramasse-miettes et ASP.NET Core font de ce code, et mesurer avant d'optimiser. Si vous débutez en C#, commencez par le cours [C# pour débutants](../csharp-beginner/), qui s'arrête là où celui-ci commence.

Si vous travaillez aussi avec Java, les parties 2 et 3 terminent chaque leçon par un tableau « Si vous connaissez Spring et Reactor », de C# vers Java. Le [cours Spring Boot, Spring Cloud et Reactor](../spring-cloud-reactor/) fait le chemin inverse, d'ASP.NET Core vers Spring ; les deux cours renvoient l'un à l'autre au lieu d'expliquer deux fois la même chose.

## À la fin de ce cours, je saurai

- prédire la taille d'une valeur ou d'un objet, repérer le boxing dans l'IL, et savoir quand le JIT le supprime ;
- utiliser `ref`, `in`, `ref readonly`, `Span<T>` et `stackalloc` sans copies défensives ni références qui s'échappent ;
- expliquer les générations, le tas des grands objets et celui des objets épinglés, les modes du GC, et lire `GC.GetGCMemoryInfo` ;
- lire la machine à états que le compilateur génère pour une méthode `async`, choisir entre `Task` et `ValueTask`, et éviter les interblocages et les annulations perdues ;
- écrire un benchmark BenchmarkDotNet qui mesure bien ce que je crois qu'il mesure, et interpréter la compilation par niveaux et la PGO ;
- choisir entre `Dictionary`, `FrozenDictionary`, `SearchValues` et une simple arithmétique, et vectoriser une boucle avec `Vector<T>` ou `TensorPrimitives` ;
- relier producteurs et consommateurs avec des channels, TPL Dataflow, Rx.NET ou `IAsyncEnumerable`, et dire pour chacun ce qui se passe sous backpressure, sur une erreur et sur une annulation ;
- suivre une requête à travers ASP.NET Core, de Kestrel jusqu'à l'endpoint, et choisir en connaissance de cause durées de vie des services, options, filtres, services hébergés, résilience et mise en cache ;
- observer et tester un service ASP.NET Core, et le publier avec Native AOT ;
- et, dans la dernière partie : arbres d'expressions, générateurs de source, analyseurs Roslyn et interop.

## L'exemple fil rouge

Les parties 1 et 2 mesurent le propre code de GA. La partie 3 construit un petit service de gammes et d'accords sur les types du domaine de GA, le pendant ASP.NET Core du service de gammes du [cours Spring Boot, Spring Cloud et Reactor](../spring-cloud-reactor/#lexemple-fil-rouge) : les mêmes endpoints, pour que chaque leçon puisse comparer les deux implémentations ligne à ligne.

## Plan

### Partie 1 : runtime et performances

| # | Leçon | Sous le capot | Mesuré sur GA | Spring et Reactor |
|---|---|---|---|---|
| 1 | [Mémoire : valeurs, références et spans](01-memory-values-and-spans/) | disposition des objets, boxing dans l'IL, `ref`/`in`, `ref struct`, `Span<T>`, `stackalloc` | `PitchClass`, `PitchClassSetId.ItemsSpan` | pas de types valeur, génériques effacés, libérer un `DataBuffer` |
| 2 | [Le ramasse-miettes](02-garbage-collector/) | générations, LOH et POH, GC station de travail et serveur, DATAS, finaliseurs, `GC.GetGCMemoryInfo` | allocations d'`ItemsSpan` avec `[MemoryDiagnoser]` | G1 et ZGC, `Cleaner`, le `-prof gc` de JMH |
| 3 | [async et await sous le capot](03-async-under-the-hood/) | la machine à états générée, `ValueTask`, `SynchronizationContext`, `ConfigureAwait`, annulation, `IAsyncEnumerable` | `Try.OfAsync`, `LazyWithExpiration` | assemblage et souscription, `publishOn`, threads virtuels |
| 4 | [Performances mesurées](04-measured-performance/) | BenchmarkDotNet, JIT par niveaux et PGO, `SearchValues`, `FrozenDictionary`, `Vector<T>` | soustraction de `PitchClass`, `SimdOps.Dot` | JMH, C1 et C2, l'API Vector |
| 5 | [Les génériques en profondeur](05-generics-in-depth/) | contraintes, membres abstraits statiques, math générique, `allows ref struct`, comment le JIT partage le code générique | `IStaticValueObjectList<TSelf>` de GA | l'effacement, et des génériques sans primitifs |

### Partie 2 : concurrence et flux de données

| # | Leçon | Sous le capot | Spring et Reactor |
|---|---|---|---|
| 6 | [Les channels](06-channels/) | channels bornés et non bornés, modes de saturation, complétion et erreurs, plusieurs producteurs et consommateurs, annulation ; le générateur de voicings et la commande d'indexation de GA | `onBackpressureBuffer`, `onBackpressureDrop`, `BlockingQueue` |
| 7 | [TPL Dataflow](07-tpl-dataflow/) | blocs et liens, parallélisme et ordre, `BoundedCapacity`, échecs qui ne font que descendre, complétion ; la démo Dataflow de GA | `flatMap` avec concurrence, `buffer`, `publishOn` |
| 8 | [Rx.NET](08-rx-net/) | `IObservable<T>`, froid et chaud, opérateurs en temps virtuel, schedulers, pas de backpressure, nouvelles tentatives ; la démo réactive de GA | `Flux`, `Sinks`, `publishOn`, `StepVerifier.withVirtualTime` |
| 9 | [Choisir un flux](09-choosing-streams/) | `IAsyncEnumerable` et `System.Linq.AsyncEnumerable`, les quatre types de flux mesurés côte à côte, ponts, débit, un diagramme de décision | [Reactor : `Mono` et `Flux`](../spring-cloud-reactor/02-reactor-mono-and-flux/), [Reactor sous le capot](../spring-cloud-reactor/03-reactor-under-the-hood/) |
| 10 | [État partagé et pool de threads](10-shared-state-and-thread-pool/) | `System.Threading.Lock`, `Interlocked`, collections concurrentes, `Parallel.ForEachAsync`, famine du pool de threads | `synchronized`, `ReentrantLock`, threads virtuels |

### Partie 3 : ASP.NET Core en profondeur

| # | Leçon | Sous le capot | Spring et Reactor |
|---|---|---|---|
| 11 | [Hébergement, `WebApplication` et Kestrel](11-hosting-webapplication-kestrel/) | l'hôte générique, le builder, les limites de connexions et de requêtes de Kestrel, l'arrêt en douceur | [Spring Boot vu depuis ASP.NET Core](../spring-cloud-reactor/01-spring-boot-from-aspnet-core/), Tomcat et Netty embarqués |
| 12 | [Le pipeline de middlewares](12-middleware-pipeline/) | `Use`, `Map`, `Run`, ordre, courts-circuits, gestion des exceptions, routage des endpoints | filtres Servlet, `WebFilter` |
| 13 | [Injection de dépendances et options](13-dependency-injection-options/) | durées de vie, dépendances captives, validation des portées, services à clé, `IOptions`, `IOptionsSnapshot`, `IOptionsMonitor`, validation | le conteneur Spring, `@ConfigurationProperties` |
| 14 | [Minimal APIs et contrôleurs](14-minimal-apis-controllers/) | gestionnaires de routes et liaison des paramètres, filtres, validation, `TypedResults`, réponses `IAsyncEnumerable` en flux | `@RestController`, endpoints fonctionnels [WebFlux](../spring-cloud-reactor/04-webflux/) |
| 15 | [Services hébergés](15-hosted-services/) | `IHostedService`, `BackgroundService`, ordre de démarrage et d'arrêt, exceptions, files avec des channels ; les services hébergés de GA | `@Scheduled`, `SmartLifecycle` |
| 16 | [Authentification et autorisation](16-authentication-authorization/) | schémas, gestionnaires, JWT bearer, stratégies et exigences | Spring Security |
| 17 | [Oracles de spécification Petri pour les pipelines C#](17-petri-pipeline-oracles/) | modèles finis de cycle de vie, accessibilité complète, classification terminale, portes d'exécution déterministes ; hypothèses de Channel, Dataflow et Rx gardées distinctes | la même méthode s'applique à Reactor seulement après avoir modélisé explicitement sa capacité et ses schedulers |
| 18 | gRPC et SignalR | contrats protobuf, appels en flux, hubs, backpressure à travers le réseau | Spring gRPC, WebSocket, RSocket |
| 19 | Résilience, limitation de débit et cache de sortie | `Microsoft.Extensions.Http.Resilience`, pipelines Polly, limiteurs de débit, stratégies de cache de sortie | Resilience4j, Spring Cloud Circuit Breaker |
| 20 | OpenTelemetry et diagnostic en production | `System.Diagnostics.Metrics`, `ActivitySource`, exportateurs OpenTelemetry, `dotnet-counters`, `dotnet-trace`, `dotnet-dump` | Micrometer, Actuator |
| 21 | Tester avec `WebApplicationFactory` | l'hôte de test, remplacer des services, l'authentification dans les tests, Testcontainers | `@SpringBootTest`, `WebTestClient` |
| 22 | Native AOT et trimming | publier une API avec Native AOT, avertissements de trimming, le générateur de délégués de requête, démarrage et taille mesurés | images natives GraalVM |

### Partie 4 : métaprogrammation et outillage

| # | Leçon | Sous le capot | Spring et Reactor |
|---|---|---|---|
| 23 | Arbres d'expressions, réflexion et générateurs de source | ce que devient une lambda une fois compilée, `Expression<T>`, le coût de la réflexion, générateurs incrémentiels, `[GeneratedRegex]` | processeurs d'annotations, [le moteur AOT de Spring](https://docs.spring.io/spring-framework/reference/core/aot.html) |
| 24 | Analyseurs Roslyn et correctifs de code | modèles syntaxique et sémantique, écrire un analyseur et ses tests | [Error Prone](https://errorprone.info/), [SpotBugs](https://spotbugs.github.io/) |
| 25 | Interop et code unsafe | `[LibraryImport]`, pointeurs de fonction, `Unsafe`, `MemoryMarshal`, épinglage | JNI, et l'[API des fonctions et de la mémoire étrangères](https://openjdk.org/jeps/454) |

### Annexes

| # | Page | Sous le capot | Mesuré sur GA |
|---|---|---|---|
| 1 | [Cinq optimisations, prouvées puis mesurées](appendix-benchmarks/) | rotations et `PopCount` sur des ensembles de 12 bits, des tables de correspondance, une preuve d'équivalence sur tout le domaine d'entrée, les tris stables comme règle de départage, et un benchmark qui mesurait le JIT au lieu du code | `IsClusterFree`, `IntervalClassVector`, `ClosestDiatonicKey`, `ToNormalForm`, `PrimeForm` |
| 2 | [GA, profilé, puis prouvé et mesuré](appendix-2-ga-performance/) | `dotnet-trace` sur un vrai pipeline, des masques de 12 bits au lieu d'ensembles de hachage, des énumérateurs boxés, un cache de 4096 cases indexé par l'ensemble lui-même, une propriété LINQ dans une boucle critique, et une preuve qui compare deux builds de GA octet par octet | `CanonicalChordRecognizer`, `ChordIntervalPattern.TryMatch`, `IntervalClassVector`, `OptickIndexReader` |
| 3 | [Oracle de cycle de vie par réseau de Petri](../petri-nets/14-on-our-systems/) | un pipeline borné avec succès, panne et annulation explicites ; accessibilité complète et aucun marquage mort non terminal | les formes de panne Channel étudiées aux leçons 6 et 9 |
| — | [Journal](journal/) | | |

Les leçons 18 à 25 sont prévues et pas encore écrites. La leçon 17 est un laboratoire avancé de concurrence ajouté après les leçons ASP.NET Core ; les leçons 6 à 9 ont été écrites avant la leçon 5 et n'en dépendent pas.

## Prérequis

- Le [SDK .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) et [Git](https://git-scm.com/downloads). Sous Windows, lancez les scripts du cours depuis Git Bash.
- `check.sh` restaure [`ilspycmd`](https://www.nuget.org/packages/ilspycmd) comme outil .NET local (version 11.0.0.9375, épinglée dans [`.config/dotnet-tools.json`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/.config/dotnet-tools.json)), récupère les trois projets GA qu'utilise le programme, environ 11 Mo, et restaure [`System.Reactive`](https://www.nuget.org/packages/System.Reactive) 7.0.0 pour la leçon 8.
- Pour les benchmarks, une machine que vous pouvez laisser au calme quelques minutes : fermez le navigateur, branchez le portable sur secteur.

## Cours liés sur ce site

- [C# pour débutants](../csharp-beginner/) : le langage à partir de zéro, écrit en même temps que ce cours.
- [Spring Boot, Spring Cloud et Reactor pour développeurs C#](../spring-cloud-reactor/) : les mêmes questions côté Java, avec le même exemple fil rouge.
- [Théorie musicale pour Guitar Alchemist](../music-theory-ga/) lit les mêmes projets GA pour ce qu'ils calculent ; ce cours les lit pour la façon dont ils s'exécutent.
- [Rust pour développeurs C#/Java](../rust-for-csharp-java/) rend explicite ce que .NET décide pour vous : la possession au lieu d'un ramasse-miettes, l'emprunt au lieu des règles de sûreté de `ref`.

## Ressources

- [Notions fondamentales de .NET : gestion de la mémoire et ramasse-miettes](https://learn.microsoft.com/dotnet/standard/garbage-collection/), et les [paramètres de configuration du GC](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector).
- La [référence du langage C#](https://learn.microsoft.com/dotnet/csharp/language-reference/), en particulier [les ref structs](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct) et [la programmation asynchrone](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/).
- Stephen Toub, [Performance Improvements in .NET 10](https://devblogs.microsoft.com/dotnet/performance-improvements-in-net-10/) et [How async/await really works in C#](https://devblogs.microsoft.com/dotnet/how-async-await-really-works/), sur le blog .NET.
- Le dépôt [dotnet/runtime](https://github.com/dotnet/runtime) : les leçons renvoient aux lignes du runtime sur lesquelles elles s'appuient, au tag `v10.0.12` (commit `4271d88`).
- [BenchmarkDotNet](https://benchmarkdotnet.org/) et ses [bonnes pratiques](https://benchmarkdotnet.org/articles/guides/good-practices.html).
- Microsoft Learn : [channels](https://learn.microsoft.com/dotnet/core/extensions/channels), [TPL Dataflow](https://learn.microsoft.com/dotnet/standard/parallel-programming/dataflow-task-parallel-library), [notions fondamentales d'ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/).
- Ian Griffiths et Lee Campbell, [Introduction to Rx.NET, 2nd edition](https://introtorx.com/), gratuit en ligne.
- Konrad Kokosa, *Pro .NET Memory Management* (Apress, 2018) : antérieur à .NET 10, c'est toujours le livre le plus approfondi sur le GC.
