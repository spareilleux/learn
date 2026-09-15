---
title: C# pour débutants — Mission
description: Apprendre à programmer en C# 14 sur .NET 10 en partant de zéro — variables, conditions, boucles, méthodes et collections, chaque notion expliquée avec de courts programmes réellement exécutés, et des exercices corrigés.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Chaque programme des leçons, chaque solution d'exercice et chaque erreur du compilateur vient de [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner). [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/csharp-beginner/check.sh) les exécute avec le SDK .NET 10 et compare leur sortie aux fichiers attendus ; [`.github/workflows/csharp-beginner-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/csharp-beginner-examples.yml) fait de même sous Linux, Windows et macOS. Les sorties ont été capturées en septembre 2026 avec le SDK .NET 10.0.112.
:::

## Pourquoi ce cours

Les autres cours de langages de ce site supposent que tu écris déjà du C# ou du Java. Celui-ci, non. Il s'adresse à quelqu'un qui n'a jamais programmé, ou qui a écrit un peu de Python, de JavaScript ou des formules de tableur, et qui veut apprendre C# correctement.

C# est un bon premier langage : le compilateur vérifie ton programme avant qu'il ne s'exécute et explique ce qui ne va pas, les outils sont gratuits sous Windows, Linux et macOS, et le même langage sert à écrire des outils en ligne de commande, des sites web, des jeux et des applications de bureau. Le cours utilise les versions actuelles : [C# 14](https://learn.microsoft.com/dotnet/csharp/whats-new/csharp-14) et [.NET 10](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-10/overview), sortis en novembre 2025.

## Comment fonctionnent les leçons

Chaque leçon présente quelques notions, et pour chacune :

1. **l'idée**, en mots simples ;
2. **un court programme** qui l'utilise, avec la sortie qu'il a vraiment affichée ;
3. **les erreurs** que font les débutants avec elle, avec le message exact du compilateur ;
4. **des exercices**, avec une solution cachée sous *Solution* : essaie d'abord, puis ouvre-la.

Les exemples utilisent de petites données réelles quand ça aide : les notes d'une guitare, l'accordage qu'utilise [Guitar Alchemist](https://github.com/GuitarAlchemist/ga), les noms de ses projets. Pas besoin de jouer de la musique pour les suivre.

## À la fin de ce cours, je saurai

- installer le SDK .NET, exécuter un fichier C# et créer un projet, sous Windows, Linux ou macOS ;
- lire une erreur du compilateur et la corriger ;
- ranger des valeurs dans des variables du bon type, convertir d'un type à l'autre, et lire ce qui est tapé au clavier ;
- prendre des décisions avec `if` et `switch`, et répéter un travail avec des boucles ;
- découper un programme en méthodes, et travailler avec des tableaux et des listes ;
- modéliser mes propres données avec des classes et des records, et gérer les erreurs avec des exceptions ;
- lire et écrire des fichiers, tester mon code, et utiliser un package NuGet.

## Plan

| # | Leçon | Notions |
|---|---|---|
| 1 | [Installer .NET et exécuter ton premier programme](01-first-program/) | SDK, `dotnet run app.cs`, instructions, projets, erreurs du compilateur |
| 2 | [Variables, types et saisie](02-variables-and-types/) | `int`, `double`, `decimal`, `string`, `bool`, `var`, conversions, interpolation, `Console.ReadLine` |
| 3 | [Conditions et boucles](03-conditions-and-loops/) | `if`, `switch`, `for`, `foreach`, `while`, `break`, le débogueur |
| 4 | [Méthodes, tableaux et listes](04-methods-arrays-lists/) | paramètres, valeurs de retour, tableaux, `List<T>`, premiers pas avec `null` |
| 5 | Classes et objets | champs, propriétés, constructeurs, méthodes, `static` |
| 6 | Records, structs et enums | types valeur et types référence, égalité, `enum` |
| 7 | Interfaces et héritage | `interface`, `abstract`, `override`, polymorphisme |
| 8 | Exceptions et sécurité face à null | `try`/`catch`/`finally`, `throw`, types référence nullables |
| 9 | Collections et LINQ | `Dictionary<TKey, TValue>`, `HashSet<T>`, `Where`, `Select`, `OrderBy` |
| 10 | Fichiers et texte | `File`, `Path`, lire un fichier CSV des projets de Guitar Alchemist |
| 11 | Tests unitaires | xUnit, `dotnet test`, tester les méthodes des leçons précédentes |
| 12 | Un petit projet | une solution avec une bibliothèque, une application console et des tests, un package NuGet, un premier regard sur `async` |
| — | [Journal](journal/) | |

Les leçons 5 à 12 sont prévues et pas encore écrites.

## Prérequis

- Un ordinateur sous Windows 10 ou 11, une distribution Linux récente (ou WSL), ou macOS 14 ou plus récent.
- Environ 1 Go d'espace disque pour le SDK .NET.
- Un terminal : la leçon 1 explique comment en ouvrir un.
- Un éditeur : [Visual Studio Code](https://code.visualstudio.com/) avec l'extension C# Dev Kit, [Visual Studio](https://visualstudio.microsoft.com/) sous Windows, ou [JetBrains Rider](https://www.jetbrains.com/rider/). La leçon 1 les compare.

## Après ce cours

Un cours *C# avancé*, écrit en même temps que celui-ci, commence là où il s'arrête : la mémoire, le ramasse-miettes, `async` sous le capot et les performances mesurées. Les cours [Java pour développeurs C#](../java-for-csharp/) et [Rust pour développeurs C#/Java](../rust-for-csharp-java/) partent de C#.

## Ressources

- [Documentation C#](https://learn.microsoft.com/dotnet/csharp/), avec sa [visite guidée de C#](https://learn.microsoft.com/dotnet/csharp/tour-of-csharp/) et ses [notions fondamentales](https://learn.microsoft.com/dotnet/csharp/fundamentals/program-structure/).
- [Référence du langage C#](https://learn.microsoft.com/dotnet/csharp/language-reference/) : chaque mot-clé, opérateur et erreur du compilateur.
- [Vue d'ensemble de la CLI .NET](https://learn.microsoft.com/dotnet/core/tools/) : la commande `dotnet`.
- [Applications basées sur des fichiers](https://learn.microsoft.com/dotnet/core/sdk/file-based-apps) : exécuter un seul fichier `.cs`.
