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
| 5 | [Classes et objets](05-classes-and-objects/) | champs, propriétés, constructeurs, méthodes, `static` |
| 6 | [Records, structs et enums](06-records-structs-enums/) | types valeur et types référence, égalité, `enum` |
| 7 | [Interfaces et héritage](07-interfaces-and-inheritance/) | `interface`, `abstract`, `override`, polymorphisme |
| 8 | [Exceptions et sécurité face à null](08-exceptions-and-null-safety/) | `try`/`catch`/`finally`, `throw`, types référence nullables |
| 9 | [Collections et LINQ](09-collections-and-linq/) | `Dictionary<TKey, TValue>`, `HashSet<T>`, `Where`, `Select`, `OrderBy` |
| 10 | [Fichiers et texte](10-files-and-text/) | `File`, `Path`, lire un fichier CSV des projets de Guitar Alchemist |
| 11 | [Tests unitaires](11-unit-tests/) | xUnit, `dotnet test`, tester les méthodes des leçons précédentes |
| 12 | [Un petit projet](12-small-project/) | une solution avec une bibliothèque, une application console et des tests, un package NuGet, un premier regard sur `async` |
| — | [Journal](journal/) | |

## Les points marquants du journal

Le [journal](journal/) consigne ce que l'écriture et les tests de ce cours ont fait apparaître. Voici les constats qui changent la façon d'écrire ou d'exécuter un programme ; chaque ligne renvoie à la leçon qui l'enseigne et à l'entrée du journal qui contient la mesure.

| Ce que le journal a trouvé | Pourquoi c'est important | Voir |
|---|---|---|
| Un `Writeline` mal orthographié (CS0117) n'est signalé qu'une fois corrigés le `;` et le guillemet manquants du même programme : les erreurs de syntaxe cachent les autres | Corriger une erreur peut en faire apparaître de nouvelles ; c'est un progrès, pas un recul | [Leçon 1](01-first-program/), [journal](journal/#2026-09-14--le-sdk-et-les-applications-basées-sur-des-fichiers) |
| `double.TryParse("1.5")` dépend de la culture : `true` et 15 en `es-ES`, où le point sépare les milliers, `false` en `fr-FR` | Le même programme lit un nombre différent sur une machine espagnole ou française | [Leçon 2](02-variables-and-types/), [journal](journal/#2026-09-14--le-sdk-et-les-applications-basées-sur-des-fichiers) |
| Les avertissements ne s'affichent que lorsque le SDK compile : un second `dotnet run` d'un fichier inchangé n'en affiche aucun, même avec `--no-cache` ; `dotnet clean` les fait revenir | Un avertissement disparu à l'exécution suivante n'est pas corrigé pour autant | [Leçon 3](03-conditions-and-loops/), [journal](journal/#2026-09-14--le-sdk-et-les-applications-basées-sur-des-fichiers) |
| Le littéral `0` se convertit en énumération sans cast, et CS8524 avertit pour une expression `switch` qui a une branche par nom | Une variable d'énumération peut contenir un nombre sans nom : le programme de la leçon échoue sur 7 | [Leçon 6](06-records-structs-enums/), [journal](journal/#2026-10-01--records-structs-et-enums) |
| Un brouillon disait que `shape[i].Fret += 2` sur une liste de `readonly record struct` donne CS1612 ; une sonde compilée avant publication a donné CS8852 | Chaque sortie et chaque message d'erreur du cours est collé depuis une exécution, jamais écrit de mémoire | [Leçon 6](06-records-structs-enums/), [journal](journal/#2026-10-01--records-structs-et-enums) |
| Dans Guitar Alchemist, le `ToString() => Name` de `ChordTemplate` n'est pas `sealed` : ses records dérivés affichent toutes leurs propriétés au lieu du nom de l'accord | L'`override` de la leçon 7 rencontre les records de la leçon 6 dans du vrai code ; un site d'appel de GA journalise le dump. Pas encore signalé à GA | [Leçon 7](07-interfaces-and-inheritance/), [tableau QA](journal/#qa) |
| Un avertissement de nullabilité désigne l'endroit où `null` entre, pas celui où le programme plante : CS8618 se trouve sur la déclaration de la propriété, et la ligne qui plante n'a aucun avertissement | Corrige chaque avertissement là où il est, même loin du plantage | [Leçon 8](08-exceptions-and-null-safety/), [journal](journal/#2026-10-02--exceptions-et-sécurité-face-à-null) |
| Guitar Alchemist fait taire quinze avertissements de nullabilité dans `NoWarn`, deux fois. Son code n'en a aucun à cacher, mais un fichier de test contenant sept erreurs de nullabilité a compilé sans avertissement | Faire taire un avertissement fait aussi taire les erreurs à venir. Pas encore signalé à GA | [Leçon 8](08-exceptions-and-null-safety/), [tableau QA](journal/#qa) |
| Le `foreach` d'un dictionnaire suit l'ordre d'ajout seulement jusqu'au premier `Remove` : une clé ajoutée ensuite prend la place de la clé retirée | Un résultat trié rangé dans un `Dictionary` reste trié par hasard ; trie quand l'ordre compte | [Leçon 9](09-collections-and-linq/), [journal](journal/#2026-10-02--collections-et-linq) |
| Trois des quatre fichiers YAML que lisent les services de connaissances musicales de Guitar Alchemist ne se chargent pas ; chaque chargeur attrape l'exception et continue avec un seul élément par défaut | Un `catch` qui se contente d'afficher cache le bogue : GA compte 16 artistes, et rien n'échoue. Signalé dans l'[issue GA n° 797](https://github.com/GuitarAlchemist/ga/issues/797) | [Leçon 9](09-collections-and-linq/), [tableau QA](journal/#qa) |
| Un chemin relatif part du dossier courant, pas du fichier du programme : `l10_where.cs` trouve `data/ga-projects.csv` quand `dotnet run` part de `code/csharp-beginner`, et le manque depuis la racine du dépôt | Le même programme trouve son fichier ou non selon le dossier d'où il part ; un chemin construit à partir de `EntryPointFileDirectoryPath` marche depuis les deux | [Leçon 10](10-files-and-text/), [journal](journal/#2026-10-03--fichiers-et-texte) |
| La chaîne de format avec laquelle Guitar Alchemist écrit son CSV de naturalité suit la culture de la machine : avec `fr-FR`, `2.50` devient `2,50`, et une ligne de 6 valeurs se coupe en 8 | Un fichier écrit sur une machine française ne se relit pas avec `Split(',')` ; écris les nombres avec `CultureInfo.InvariantCulture`. Pas encore signalé à GA | [Leçon 10](10-files-and-text/), [tableau QA](journal/#qa) |
| Les tests de Guitar Alchemist pour ses services YAML réussissent alors que trois des quatre fichiers ne se chargent pas : trois tests sont ignorés, et les autres vérifient « plus que zéro », ce que satisfait le seul élément par défaut | Un test qui vérifie seulement « plus que zéro » ne voit pas une valeur de repli ; vérifie la vraie valeur. Pas encore signalé à GA | [Leçon 11](11-unit-tests/), [tableau QA](journal/#qa) |
| Avec ses arguments inversés, `Assert.Equal` appelle « Expected » le résultat de la méthode et « Actual » la valeur du test ; la règle d'analyseur xUnit2000 le signale avant que les tests tournent | La valeur attendue vient en premier ; lis aussi les avertissements de la compilation des tests | [Leçon 11](11-unit-tests/), [journal](journal/#2026-10-03--tests-unitaires) |
| `dotnet test` dans le dossier d'une solution ne compile que les projets de test et ce qu'ils référencent : avec une erreur de compilation dans l'application console, les tests réussissent quand même et se terminent avec le code 0 | Lance aussi `dotnet build` avant de te fier à des tests au vert | [Leçon 12](12-small-project/), [journal](journal/#2026-10-03--un-petit-projet) |
| Dans le `Directory.Build.props` de Guitar Alchemist, les lignes `PackageReference Update` censées aligner les versions des packages ne changent rien : le fichier est importé avant les éléments propres des projets | Vérifie la version que choisit une restauration ; `Directory.Build.targets` ou la gestion centralisée des packages font ce que ces lignes visent. Pas encore signalé à GA | [Leçon 12](12-small-project/), [tableau QA](journal/#qa) |

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
