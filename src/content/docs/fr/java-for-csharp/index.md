---
title: Java pour développeurs C# — Mission
description: Apprendre le Java moderne (25 LTS) en le mettant en correspondance avec ce que l'on connaît déjà de C# et de .NET.
sidebar:
  label: Mission
  order: 0
---

:::note[Versions étudiées]
Java **25** (LTS), comparé à C# **14** sur .NET **10**. Chaque exemple Java de ce cours est exécuté en CI depuis [`code/java-for-csharp`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp) et sa sortie comparée à la leçon. Chaque extrait « ceci ne compile pas » est compilé et vérifié par rapport au diagnostic javac exact, et le côté C# de chaque comparaison est exécuté lui aussi.
:::

## Pourquoi j'apprends ça

Je pense en C#. Mais une bonne partie du code que je lis chaque jour est du Java : des services [Spring](https://spring.io/), des plugins de build, des bibliothèques dont le portage C# est en retard. Les deux langages se ressemblent tant qu'il est facile d'écrire du Java *comme si* c'était du C#, et d'être surpris à l'exécution : `==` entre deux `Integer`, un type générique qui a disparu, une exception vérifiée (checked) qui ne compile pas.

Ce cours est la carte que j'aurais voulu avoir : pour chaque sujet, ce qui se transpose depuis C#, ce qui n'en a que l'apparence, et ce qui n'a pas d'équivalent.

## À qui s'adresse ce cours

Vous écrivez du C# avec aisance : classes, interfaces, génériques, LINQ, `async`/`await`, NuGet et la [CLI `dotnet`](https://learn.microsoft.com/dotnet/core/tools/). Vous avez lu un peu de Java sans jamais en livrer. Un cours de suite, *Spring Boot, Spring Cloud et Reactor pour développeurs C#*, s'appuie sur celui-ci.

## À la fin de ce cours, je saurai

- installer un JDK, exécuter du code Java et compiler un projet avec [Maven](https://maven.apache.org/) ou [Gradle](https://gradle.org/) ;
- prédire où la sémantique de valeur, l'égalité et les nombres de Java diffèrent de C# ;
- modéliser des données avec des classes, des records, des enums et des interfaces scellées ;
- utiliser les génériques en sachant ce que l'effacement de type (type erasure) retire ;
- gérer les exceptions vérifiées, `null` et `Optional` ;
- traduire LINQ et les délégués en Streams et en interfaces fonctionnelles ;
- écrire du code concurrent avec des threads virtuels au lieu de `async`/`await` ;
- tester, empaqueter et exécuter une application Java sur la JVM.

## Plan

| # | Leçon | Vous connaissez déjà |
|---|---|---|
| 1 | [Le JDK et les outils de build](01-jdk-and-build-tools/) | le SDK .NET, `dotnet run`, [NuGet](https://www.nuget.org/), `.csproj` |
| 2 | [Types, égalité et opérateurs](02-types-and-operators/) | types valeur, `checked`, `==`, interpolation de chaînes |
| 3 | [Classes, records et enums](03-classes-records-enums/) | propriétés, `virtual`/`override`, `record`, `enum` |
| 4 | [Génériques et effacement de type](04-generics-and-erasure/) | génériques réifiés, `where T : new()`, variance `in`/`out` |
| 5 | [Exceptions, `null` et `Optional`](05-exceptions-null-optional/) | exceptions, `using`, types référence nullables |
| 6 | [Lambdas et interfaces fonctionnelles](06-lambdas-and-functional-interfaces/) | délégués, `Func`/`Action`, événements |
| 7 | [Collections et Streams](07-collections-and-streams/) | `List<T>`, `Dictionary`, LINQ |
| 8 | [Pattern matching](08-pattern-matching/) | expressions `switch`, motifs `is`, records |
| 9 | [Concurrence et threads virtuels](09-concurrency-and-virtual-threads/) | `Task`, `async`/`await`, `lock`, `Parallel` |
| 10 | [Maven et Gradle en profondeur](10-maven-and-gradle-in-depth/) | NuGet, Central Package Management, solutions |
| 11 | [Tests](11-testing/) | xUnit, Moq, FluentAssertions |
| 12 | La bibliothèque standard du quotidien *(à venir)* | `DateTime`, `decimal`, `HttpClient`, `System.IO` |
| 13 | La JVM à l'exécution | le CLR, réglages du GC, `dotnet-counters`, Native AOT |
| 14 | Annotations, réflexion et modules | attributs, générateurs de source, assemblies |

[Journal](journal/) — ce que j'ai essayé, ce qui m'a surpris, ce qu'il me reste à vérifier.

## Ressources

- [dev.java](https://dev.java/learn/) — les tutoriels Java officiels d'Oracle, à jour des dernières versions.
- [The Java Language Specification, Java SE 25](https://docs.oracle.com/javase/specs/jls/se25/html/index.html) — la référence quand deux tutoriels ne sont pas d'accord.
- [Documentation de l'API Java SE 25](https://docs.oracle.com/en/java/javase/25/docs/api/index.html).
- [Index des JEP d'OpenJDK](https://openjdk.org/jeps/0) — chaque évolution du langage et de la JVM, avec sa motivation.
- [Maven — Getting Started](https://maven.apache.org/guides/getting-started/) et le [manuel utilisateur de Gradle](https://docs.gradle.org/current/userguide/userguide.html).
