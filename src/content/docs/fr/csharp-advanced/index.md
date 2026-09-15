---
title: C# avancé — Mission
description: Ce qui se passe sous le capot de C# 14 et .NET 10 — disposition en mémoire, ramasse-miettes, machine à états d'async et performances mesurées — chaque affirmation vérifiée par un programme, par l'IL ou par un benchmark, sur du vrai code de Guitar Alchemist.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Chaque sortie des leçons vient de [`code/csharp-advanced`](https://github.com/spareilleux/learn/tree/main/code/csharp-advanced). [`check.sh`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/check.sh) compile le programme du cours avec [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) cloné au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), exécute chaque leçon, désassemble les exemples avec [l'outil en ligne de commande d'ILSpy](https://github.com/icsharpcode/ILSpy/tree/master/ICSharpCode.ILSpyCmd), compile chaque extrait rejeté avec [Roslyn](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/), et compare le tout aux fichiers attendus. [`.github/workflows/csharp-advanced-examples.yml`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/.github/workflows/csharp-advanced-examples.yml) fait de même sous Linux, Windows et macOS, et vérifie que chaque benchmark s'exécute. Les lignes qui dépendent de la machine commencent par `# ` et ne sont pas comparées ; les temps des benchmarks viennent de la machine de l'auteur, jamais de la CI. Sorties capturées en septembre 2026 avec le SDK .NET 10.0.112 et le runtime .NET 10.0.12.
:::

## Pourquoi j'apprends ça

J'écris du C# depuis des années, et l'essentiel de ce que je sais de ses performances relève du folklore : « les structs sont plus rapides », « évitez LINQ », « toujours `ConfigureAwait(false)` », « `FrozenDictionary`, c'est le rapide ». Une partie était vraie avec .NET Framework 4.5 et devient fausse sur .NET 10, où le JIT supprime des allocations que l'IL demande. Ce cours remplace chaque morceau de folklore par quelque chose que je peux examiner : la taille d'un objet, l'IL émis par le compilateur, la machine à états derrière `await`, la génération d'un tableau, un tableau de résultats BenchmarkDotNet.

Les mesures portent sur du vrai code, pas sur des classes jouets : [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA), une grande base de code .NET 10 consacrée à la théorie musicale. Ses objets valeur, ses caches et ses fonctions vectorielles sont exactement le genre de code où ces questions se posent, et les leçons ont trouvé plusieurs endroits où GA paie pour quelque chose qu'il ne voulait pas.

## À qui s'adresse ce cours

Vous écrivez du C# tous les jours et connaissez bien le langage : génériques, LINQ, `async`/`await`, records, pattern matching. Vous voulez savoir ce que le compilateur, le JIT et le ramasse-miettes font de ce code, et mesurer avant d'optimiser. Si vous débutez en C#, commencez par le cours [C# pour débutants](../csharp-beginner/), qui s'arrête là où celui-ci commence.

## À la fin de ce cours, je saurai

- prédire la taille d'une valeur ou d'un objet, repérer le boxing dans l'IL, et savoir quand le JIT le supprime ;
- utiliser `ref`, `in`, `ref readonly`, `Span<T>` et `stackalloc` sans copies défensives ni références qui s'échappent ;
- expliquer les générations, le tas des grands objets et celui des objets épinglés, les modes du GC, et lire `GC.GetGCMemoryInfo` ;
- lire la machine à états que le compilateur génère pour une méthode `async`, choisir entre `Task` et `ValueTask`, et éviter les interblocages et les annulations perdues ;
- écrire un benchmark BenchmarkDotNet qui mesure bien ce que je crois qu'il mesure, et interpréter la compilation par niveaux et la PGO ;
- choisir entre `Dictionary`, `FrozenDictionary`, `SearchValues` et une simple arithmétique, et vectoriser une boucle avec `Vector<T>` ou `TensorPrimitives` ;
- et, dans les leçons suivantes : math générique, générateurs de source, analyseurs Roslyn, interop, Native AOT et diagnostic en production.

## Plan

| # | Leçon | Sous le capot | Mesuré sur GA |
|---|---|---|---|
| 1 | [Mémoire : valeurs, références et spans](01-memory-values-and-spans/) | disposition des objets, boxing dans l'IL, `ref`/`in`, `ref struct`, `Span<T>`, `stackalloc` | `PitchClass`, `PitchClassSetId.ItemsSpan` |
| 2 | [Le ramasse-miettes](02-garbage-collector/) | générations, LOH et POH, GC station de travail et serveur, DATAS, finaliseurs, `GC.GetGCMemoryInfo` | allocations d'`ItemsSpan` avec `[MemoryDiagnoser]` |
| 3 | [async et await sous le capot](03-async-under-the-hood/) | la machine à états générée, `ValueTask`, `SynchronizationContext`, `ConfigureAwait`, annulation, `IAsyncEnumerable` | `Try.OfAsync`, `LazyWithExpiration` |
| 4 | [Performances mesurées](04-measured-performance/) | BenchmarkDotNet, JIT par niveaux et PGO, `SearchValues`, `FrozenDictionary`, `Vector<T>` | soustraction de `PitchClass`, `SimdOps.Dot` |
| 5 | Les génériques en profondeur | contraintes, membres abstraits statiques, math générique, `allows ref struct`, comment le JIT partage le code générique | `IStaticValueObjectList<TSelf>` de GA |
| 6 | Primitives de concurrence | `System.Threading.Lock`, `Interlocked`, `Channel<T>`, `Parallel.ForEachAsync`, le pool de threads | |
| 7 | Délégués, fermetures et arbres d'expressions | ce que devient une lambda une fois compilée, `Expression<T>`, compiler des expressions à l'exécution | |
| 8 | Réflexion et générateurs de source | le coût de la réflexion, générateurs incrémentiels, `[GeneratedRegex]` | |
| 9 | Analyseurs Roslyn et correctifs de code | modèles syntaxique et sémantique, écrire un analyseur et ses tests | |
| 10 | Interop et code unsafe | `[LibraryImport]`, pointeurs de fonction, `Unsafe`, `MemoryMarshal`, épinglage | |
| 11 | Native AOT et trimming | ce que l'AOT supprime, avertissements de trimming, démarrage et taille mesurés | |
| 12 | Diagnostic en production | `dotnet-counters`, `dotnet-trace`, `dotnet-dump`, EventPipe, `System.Diagnostics.Metrics` | |
| — | [Journal](journal/) | | |

Les leçons 5 à 12 sont prévues et pas encore écrites.

## Prérequis

- Le [SDK .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) et [Git](https://git-scm.com/downloads). Sous Windows, lancez les scripts du cours depuis Git Bash.
- `check.sh` restaure [`ilspycmd`](https://www.nuget.org/packages/ilspycmd) comme outil .NET local (version 11.0.0.9375, épinglée dans [`.config/dotnet-tools.json`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/.config/dotnet-tools.json)) et récupère les trois projets GA qu'utilise le programme, environ 11 Mo.
- Pour les benchmarks, une machine que vous pouvez laisser au calme quelques minutes : fermez le navigateur, branchez le portable sur secteur.

## Cours liés sur ce site

- [C# pour débutants](../csharp-beginner/) : le langage à partir de zéro, écrit en même temps que ce cours.
- [Théorie musicale pour Guitar Alchemist](../music-theory-ga/) lit les mêmes projets GA pour ce qu'ils calculent ; ce cours les lit pour la façon dont ils s'exécutent.
- [Rust pour développeurs C#/Java](../rust-for-csharp-java/) rend explicite ce que .NET décide pour vous : la possession au lieu d'un ramasse-miettes, l'emprunt au lieu des règles de sûreté de `ref`.

## Ressources

- [Notions fondamentales de .NET : gestion de la mémoire et ramasse-miettes](https://learn.microsoft.com/dotnet/standard/garbage-collection/), et les [paramètres de configuration du GC](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector).
- La [référence du langage C#](https://learn.microsoft.com/dotnet/csharp/language-reference/), en particulier [les ref structs](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct) et [la programmation asynchrone](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/).
- Stephen Toub, [Performance Improvements in .NET 10](https://devblogs.microsoft.com/dotnet/performance-improvements-in-net-10/) et [How async/await really works in C#](https://devblogs.microsoft.com/dotnet/how-async-await-really-works/), sur le blog .NET.
- Le dépôt [dotnet/runtime](https://github.com/dotnet/runtime) : les leçons renvoient aux lignes du runtime sur lesquelles elles s'appuient, au tag `v10.0.12` (commit `4271d88`).
- [BenchmarkDotNet](https://benchmarkdotnet.org/) et ses [bonnes pratiques](https://benchmarkdotnet.org/articles/guides/good-practices.html).
- Konrad Kokosa, *Pro .NET Memory Management* (Apress, 2018) : antérieur à .NET 10, c'est toujours le livre le plus approfondi sur le GC.
