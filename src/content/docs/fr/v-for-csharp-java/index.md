---
title: V pour développeurs C#/Java — Mission
description: Apprendre le langage V à partir de ce que tu connais déjà en C# et en Java — chaque exemple, erreur du compilateur et panic est exécuté en CI sous Windows, Linux et macOS.
sidebar:
  label: Mission
  order: 0
---

:::note[Version étudiée]
[V](https://vlang.io/) **0.5.2**, la [version de juillet 2026](https://github.com/vlang/v/releases/tag/0.5.2). Chaque exemple de ce cours se trouve dans [`code/v-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/v-for-csharp-java), à côté de sa sortie attendue. [`.github/workflows/v-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/v-examples.yml) installe V 0.5.2 depuis la release GitHub sous Linux, Windows et macOS, exécute chaque exemple, compile chaque snippet qu'une leçon montre comme rejeté, et compare les sorties et les messages du compilateur avec ceux collés dans les leçons.
:::

## Pourquoi j'apprends ça

V promet un petit langage, proche de Go, qui compile vers C en une seconde environ, avec des variables immuables par défaut, sans `null`, sans exceptions, et avec un ramasse-miettes (GC) que l'on peut désactiver.
J'écris du C# et je lis beaucoup de Java. Je veux savoir lesquelles de ces promesses tiennent en version 0.5.2, ce que V coûte en échange, et où sa documentation et son compilateur divergent.

## À qui s'adresse ce cours

Tu es à l'aise avec C# ou Java : classes, interfaces, génériques, exceptions, collections, [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/) ou [streams](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html).
Tu n'as jamais écrit de V, et tu n'as pas besoin de connaître C. Chaque leçon part du concept que tu connais déjà et montre où V est d'accord, où il diffère, et ce que dit le compilateur quand tu te trompes.

## V en un tableau

| | C# | Java | V |
|---|---|---|---|
| Compile vers | IL, exécuté par le CLR | bytecode, exécuté par la JVM | C, compilé en exécutable natif |
| Outil de build | [`dotnet`](https://learn.microsoft.com/dotnet/core/tools/) | [Maven](https://maven.apache.org/), [Gradle](https://gradle.org/) | `v` lui-même |
| Fichier de projet | `.csproj` | `pom.xml`, `build.gradle` | `v.mod` (optionnel) |
| Variable locale | `var x = 1;` (mutable) | `var x = 1;` (mutable) | `x := 1` (immuable), `mut x := 1` |
| Classe | `class`, `record`, `struct` | `class`, `record` | `struct` avec des méthodes, sans héritage |
| Valeur absente | `null`, `int?` | `null`, `Optional<T>` | `?T` et `none` |
| Échec | exceptions | exceptions vérifiées et non vérifiées | `!T`, `error()` et `or { }` |
| Mémoire | GC générationnel | GC (G1 par défaut) | GC Boehm par défaut, `-autofree`, `-gc none` |
| Espaces de noms | `namespace` | `package` | un module par dossier |
| Visibilité | `public`, `internal`, `private` | `public`, package-private, `private` | `pub` ou privé au module |

Sources : [ramasse-miettes .NET](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals), [ramasse-miettes G1](https://docs.oracle.com/en/java/javase/25/gctuning/garbage-first-g1-garbage-collector1.html), [documentation de V](https://docs.vlang.io/introduction.html).

## La documentation et la version

[docs.vlang.io](https://docs.vlang.io/introduction.html) est générée à partir de `doc/docs.md` sur la branche `master` de V, qui a évolué depuis 0.5.2 : sa page [The default compiler](https://docs.vlang.io/the-default-compiler.html), par exemple, n'existe pas dans la documentation de 0.5.2. Ce cours renvoie à docs.vlang.io pour les concepts et vérifie chaque comportement avec 0.5.2 elle-même ; la documentation de la version étudiée est [`doc/docs.md` au tag 0.5.2](https://github.com/vlang/v/blob/0.5.2/doc/docs.md), et la bibliothèque standard est décrite sur [modules.vlang.io](https://modules.vlang.io/).

## Les données

Les leçons 3 et 4 lisent [`code/v-for-csharp-java/data/pages.csv`](https://github.com/spareilleux/learn/blob/main/code/v-for-csharp-java/data/pages.csv) : les 319 pages de ce site au commit `cbcbb42`, avec leur locale, leur cours, leur titre et leur nombre de lignes. C'est une copie du fichier que le [cours LadybugDB](../ladybugdb/) extrait de ce dépôt.

Les leçons 5 à 8 lisent [`code/v-for-csharp-java/data/ga`](https://github.com/spareilleux/learn/tree/main/code/v-for-csharp-java/data/ga) : les 111 projets .NET de [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) au commit [`a26a7893`](https://github.com/GuitarAlchemist/ga/commit/a26a7893), leurs 266 références de projet et 478 références de package, copiés eux aussi du cours LadybugDB. La leçon 7 parcourt leurs références en parallèle, la leçon 8 teste un module qui les analyse.

## À la fin de ce cours, je saurai

- installer V sous Windows, Linux et macOS, et organiser un programme en modules ;
- modéliser des données avec des structs, des méthodes, des interfaces et des types somme au lieu de classes ;
- gérer l'absence et l'échec avec `?`, `!` et `or { }` au lieu de `null` et des exceptions ;
- dire où un tableau, une map ou une struct est copié, partagé ou libéré ;
- écrire du code concurrent avec `spawn` et des canaux (*channels*) ;
- tester, formater et documenter un module, et appeler une bibliothèque C.

## Plan

| # | Leçon | Tu connais déjà |
|---|---|---|
| 1 | [Installation, `v run`, modules et projets](01-install-and-projects/) | `dotnet new`, `dotnet run`, `javac`, `java` |
| 2 | [Types, variables immuables, structs et méthodes](02-types-structs-methods/) | `var`, `readonly`/`final`, classes, records |
| 3 | [Erreurs : `?`, `!` et `or { }`](03-errors-option-result/) | `null`, `Optional`, exceptions |
| 4 | [Tableaux, maps, slices et mémoire](04-arrays-maps-memory/) | `List<T>`, `Dictionary`, `ArrayList`, `HashMap`, le GC |
| 5 | [Interfaces et génériques](05-interfaces-generics/) | interfaces, génériques, contraintes |
| 6 | [Enums, types somme et `match`](06-sum-types-match/) | enums, hiérarchies scellées, expressions `switch` |
| 7 | [Concurrence : `spawn`, canaux et `shared`](07-concurrency/) | `Task`, `CompletableFuture`, threads virtuels, `lock`/`synchronized` |
| 8 | [Tests, `v fmt`, `v vet` et `v doc`](08-tests-tools/) | xUnit/JUnit, `dotnet format`, analyseurs, commentaires de documentation XML |
| 9 | Appeler du C (à venir) | P/Invoke, JNI, l'API FFM |
| 10 | JSON et un serveur web avec `veb` | `System.Text.Json`, ASP.NET Core, Jackson, Spring |
| 11 | L'ORM et SQLite | Entity Framework, JPA |
| 12 | Packages, compilation croisée et déploiement | NuGet/Maven Central, `dotnet publish`, `jlink` |
| — | [Journal](journal/) | |

## Ressources

- [Documentation de V](https://docs.vlang.io/introduction.html), et [`doc/docs.md` au tag 0.5.2](https://github.com/vlang/v/blob/0.5.2/doc/docs.md)
- [Bibliothèque standard de V](https://modules.vlang.io/)
- [Code source de V](https://github.com/vlang/v), et la [release 0.5.2](https://github.com/vlang/v/releases/tag/0.5.2) qu'utilise ce cours
- [Tests du langage V](https://github.com/vlang/v/tree/0.5.2/vlib/v/tests) : la documentation indique que le compilateur et ses tests font foi quand ils la contredisent
