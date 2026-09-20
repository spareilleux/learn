---
title: F# pour développeurs C#/Java — Mission
description: F# 10 sur .NET 10, du premier script au niveau expert, pour les développeurs C# et Java sans expérience de la programmation fonctionnelle — chaque script, message du compilateur et exercice exécuté en CI, avec du vrai code de TARS et de Guitar Alchemist.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Chaque script, session F# Interactive, solution d'exercice et message du compilateur des leçons provient de [`code/fsharp`](https://github.com/spareilleux/learn/tree/main/code/fsharp). [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/fsharp/check.sh) les exécute avec le SDK .NET 10 et compare leur sortie aux fichiers attendus ; le workflow `.github/workflows/fsharp-examples.yml` fait de même sous Linux, Windows et macOS (voir le [journal](journal/) pour son état). Les sorties ont été capturées en septembre 2026 avec le SDK .NET 10.0.112, qui contient F# 10.
:::

## Pourquoi ce cours

Vous écrivez du C# ou du Java. Vous avez utilisé des lambdas, LINQ ou les streams, des records, peut-être des expressions `switch` avec des motifs. F# reprend ces idées, que C# et Java ont empruntées aux langages fonctionnels ces quinze dernières années, et en fait la norme : des valeurs qui ne changent pas, des fonctions qui renvoient des valeurs au lieu de modifier un état, des types qui décrivent chaque cas de vos données, et un compilateur qui vérifie que vous les avez tous traités.

F# tourne sur .NET, appelle toutes les bibliothèques .NET et compile vers le même langage intermédiaire que C#. Vous n'avez pas à quitter votre écosystème pour l'apprendre, et ce que vous apprenez change votre façon d'écrire du C#.

Ce cours utilise les versions actuelles : [F# 10](https://learn.microsoft.com/dotnet/fsharp/whats-new/fsharp-10), livré avec [.NET 10](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-10/overview), sorti en novembre 2025.

## Du vrai code : TARS et Guitar Alchemist

Les exemples viennent de deux bases de code F# publiques, épinglées sur un commit pour que les liens continuent de pointer vers le code que décrivent les leçons :

- **[TARS](https://github.com/GuitarAlchemist/tars)**, un framework d'agents en F# (raisonnement, workflows multi-agents, grammaires probabilistes), au commit [`87464ce`](https://github.com/GuitarAlchemist/tars/tree/87464ce583c42cd11c3d76836e05842377455b24). Son code actif se trouve dans `v2/` : les leçons ne citent que des projets que sa solution `v2/Tars.sln` compile et que sa CI teste.
- **[Guitar Alchemist](https://github.com/GuitarAlchemist/ga)** (GA), une application de théorie musicale écrite surtout en C#, dont le DSL musical, les parseurs, la configuration et le serveur de langage sont en F#, au commit [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381).

Quand un extrait de GA compile seul, le cours garde une copie du fichier dans [`code/fsharp/external/ga`](https://github.com/spareilleux/learn/tree/main/code/fsharp/external/ga) (GA est sous licence MIT) et l'exécute. TARS n'a pas de fichier de licence : son code est donc lié et cité, et reproduit en quelques lignes seulement là où il faut montrer un comportement. Ce que les leçons trouvent dans ces dépôts (un bug, du code mort, un script qui ne s'exécute pas) va dans le [journal](journal/).

## Déroulement des leçons

Chaque leçon part de ce que vous écririez en C# (et en Java quand c'est différent), puis :

1. **la manière F#**, avec un court script et la sortie qu'il a réellement affichée ;
2. **le point de vue du compilateur** : les erreurs et avertissements que vous rencontrerez, avec leur message exact ;
3. **du vrai code** de TARS ou de GA qui utilise la notion ;
4. **des exercices**, avec une solution sous *Solution* : essayez d'abord, puis ouvrez-la.

## À la fin de ce cours, je saurai

- exécuter des scripts F# et F# Interactive, et organiser un projet F# dont les fichiers compilent dans l'ordre ;
- modéliser un domaine avec des records, des unions discriminées et des options, pour que les états invalides ne compilent pas ;
- écrire des fonctions qui se composent, avec des pipelines, l'application partielle et un filtrage par motif exhaustif ;
- gérer les erreurs avec `Result`, et écrire et lire des expressions de calcul, y compris les miennes ;
- tester du code F# avec xUnit, FsCheck et Expecto, et analyser du texte avec FParsec ;
- mesurer et réduire les allocations, et choisir entre `Async`, `Task` et `MailboxProcessor` ;
- lire et étendre une vraie base de code F#, et publier une bibliothèque F# que du code C# consomme confortablement.

## Plan

| # | Leçon | Notions | Vrai code |
|---|---|---|---|
| | **Débutant** | | |
| 1 | [Scripts, F# Interactive et projets](01-first-program/) | `dotnet fsi`, scripts `.fsx`, `printfn`, `#r "nuget:"`, indentation, l'ordre des fichiers d'un `.fsproj` | `GA.Business.DSL.fsproj` et `Scripts/ModesConfig.fsx` de GA, `Tars.Core.fsproj` de TARS |
| 2 | [Valeurs, fonctions et inférence de types](02-values-and-functions/) | `let`, immuabilité, `mutable`, inférence, curryfication, application partielle, `\|>` et `>>`, des expressions partout | `HarmonicTransformationService` de GA, `TextNormalizer` de TARS |
| 3 | [Tuples, records, unions et options](03-records-unions-options/) | tuples, records et `with`, unions discriminées, `Option`, unions à un seul cas, `RequireQualifiedAccess` | `ChordAst` de GA, `Domain.fs` et `Primitives.fs` de TARS |
| 4 | [Filtrage par motif](04-pattern-matching/) | `match`, gardes, motifs « ou », motifs de listes et de records, avertissements d'exhaustivité | `ChordRenderer`, `ChordParser` et `BinObj.fsx` de GA, `AgentWorkflow.fs` de TARS |
| 5 | [Listes, tableaux et séquences](05-lists-arrays-sequences/) | modules `List`, `Array` et `Seq`, pipelines à côté de LINQ et des streams, évaluation paresseuse | |
| 6 | [Modules, espaces de noms et organisation d'un projet](06-modules-namespaces/) | modules, espaces de noms, `private` et `internal`, fichiers de signature | |
| | **Intermédiaire** | | |
| 7 | [Les erreurs avec `Result`](07-result-errors/) | programmation orientée « rails », `Result` à côté des exceptions | |
| 8 | [Expressions de calcul — un parseur pour un DSL](08-computation-expressions/) | `seq`, `async`, `task`, builders, `Bind`, `Return`, un parser CE et la fin explicite du texte | le DSL musical de GA |
| 9 | Les objets en F# | classes, interfaces, expressions objet, appel de bibliothèques C# | |
| 10 | Tests | xUnit, tests de propriétés avec FsCheck, Expecto | |
| 11 | Parseurs | FParsec et combinateurs écrits à la main | le DSL musical de GA |
| 12 | Modéliser un domaine | unités de mesure, types fantômes, rendre les états illégaux non représentables | `Budget` de TARS |
| | **Avancé et expert** | | |
| 13 | Expressions de calcul personnalisées | builders, `let!` et `and!`, ce que génère le compilateur | `AgentWorkflow` de TARS |
| 14 | [Type providers — des données typées à partir d'un échantillon](14-type-providers/) | providers effacés et génératifs, inférence CSV et JSON, stabilité du schéma | FSharp.Data |
| 15 | Performance | structs, `inline`, `Span`, `voption`, allocations mesurées avec BenchmarkDotNet | |
| 16 | Concurrence | `MailboxProcessor`, `Async` à côté de `Task`, canaux | |
| 17 | Métaprogrammation | Myriad, FSharp.Compiler.Service | le pool de sessions F# Interactive de GA |
| 18 | Outillage | un serveur de langage en F#, Fantomas, analyseurs | `GaMusicTheoryLsp` de GA |
| 19 | Architecture d'une vraie application F# | une lecture guidée de TARS | TARS |
| 20 | Publier une bibliothèque F# pour C# | conception d'API, `[<CompiledName>]`, options et unions vues de C# | |
| — | [Journal](journal/) | | |

Les leçons 9 à 13 et 15 à 20 sont prévues et pas encore écrites.

## Prérequis

- Vous programmez en C# ou en Java. Aucune expérience de la programmation fonctionnelle n'est nécessaire.
- Le [SDK .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0), sous Windows, Linux (ou WSL) ou macOS. La leçon 1 vérifie l'installation ; le cours [C# pour débutants](../csharp-beginner/01-first-program/#installer-le-sdk-net) la détaille pour chaque système.
- Un éditeur qui prend en charge F# : [Visual Studio Code](https://code.visualstudio.com/) avec l'extension [Ionide](https://ionide.io/), [JetBrains Rider](https://www.jetbrains.com/rider/), ou [Visual Studio](https://visualstudio.microsoft.com/) sous Windows.

## Cours liés

- [C# avancé](../csharp-advanced/) couvre ce qui se passe sous .NET : la mémoire, le ramasse-miettes, `async` et la performance mesurée. Ce cours y renvoie plutôt que de le répéter ; les leçons 15 et 16 s'appuient dessus.
- [Rust pour développeurs C#/Java](../rust-for-csharp-java/) aborde les mêmes idées sous un autre angle : [les enums et `match`](../rust-for-csharp-java/05-structs-enums-match/), [`Option` et `Result`](../rust-for-csharp-java/06-option-result/).

## Ressources

- [La documentation F#](https://learn.microsoft.com/dotnet/fsharp/), avec sa [visite guidée de F#](https://learn.microsoft.com/dotnet/fsharp/tour) et sa [référence du langage](https://learn.microsoft.com/dotnet/fsharp/language-reference/).
- [Nouveautés de F# 10](https://learn.microsoft.com/dotnet/fsharp/whats-new/fsharp-10).
- [La référence de l'API FSharp.Core](https://fsharp.github.io/fsharp-core-docs/) : les modules `List`, `Option`, `Result` et le reste de la bibliothèque de base.
- [La spécification du langage F#](https://fsharp.org/specs/language-spec/) et les RFC de conception dans [fsharp/fslang-design](https://github.com/fsharp/fslang-design).
- [dotnet/fsharp](https://github.com/dotnet/fsharp) : le compilateur, FSharp.Core et F# Interactive.
- [Le guide de style F#](https://learn.microsoft.com/dotnet/fsharp/style-guide/) et [les conventions de codage F#](https://learn.microsoft.com/dotnet/fsharp/style-guide/conventions).
