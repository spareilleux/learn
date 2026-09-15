---
title: Journal
description: Notes de progression datées du cours C# pour débutants — le SDK et les applications basées sur des fichiers, les vérifications sur trois OS, les surprises rencontrées en écrivant les exemples, et les points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Code du cours : applications basées sur des fichiers, extraits refusés et solutions des exercices, comparés à leur sortie attendue par `check.sh`
- [x] CI sous Linux, Windows et macOS
- [x] Leçon 1 : installer .NET et exécuter ton premier programme
- [x] Leçon 2 : variables, types et saisie
- [x] Leçon 3 : conditions et boucles
- [x] Leçon 4 : méthodes, tableaux et listes
- [ ] Leçon 5 : classes et objets

## 2026-09-14 — Le SDK et les applications basées sur des fichiers

- Ma machine a deux SDK : 10.0.112 et 11.0.100-preview.3.26207.106. Sans [`global.json`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/global.json), `dotnet` choisit la préversion. Le dossier du cours fixe `10.0.100` avec `rollForward: latestFeature`, ce qui sélectionne ici 10.0.112.
- Le même jour, WinGet propose `Microsoft.DotNet.SDK.10` en version 10.0.401 : une bande de fonctionnalités plus récente que la mienne. La [page des applications basées sur des fichiers](https://learn.microsoft.com/dotnet/core/sdk/file-based-apps) indique que `#:include` est disponible à partir du SDK 10.0.300 ; la leçon 1 dit donc qu'une application basée sur un fichier tient en un seul fichier par défaut, et que `#:include` en ajoute d'autres à partir de ce SDK. Je n'ai pas essayé `#:include` : mon SDK est plus ancien.
- Les exemples sont des applications basées sur des fichiers plutôt qu'un projet par leçon : un débutant tape un fichier et l'exécute, sans rien configurer. Un simple `dotnet run app.cs` a pris 0,9 s la première fois et 0,2 s la suivante.
- Les autres fichiers `.cs` du même dossier ne sont pas compilés avec l'application : `hello.cs` a fonctionné à côté d'un fichier plein d'erreurs.
- **Les avertissements ne s'affichent que quand le SDK compile.** Un second `dotnet run` d'un fichier inchangé n'affiche aucun avertissement, et `dotnet run --no-cache` n'y change rien : il saute la vérification « à jour » de l'application basée sur un fichier, mais MSBuild trouve toujours la sortie compilée à jour et n'appelle pas le compilateur. Un `dotnet clean app.cs` avant chaque exécution fait revenir les avertissements ; [`check.sh`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/check.sh#L25-L50) le fait, et la leçon 3 le dit au lecteur.
- Les erreurs du compilateur vont sur la sortie standard, avec le chemin complet du fichier ; `The build failed. Fix the build errors and run again.` va sur la sortie d'erreur. `check.sh` fusionne les deux et ne garde que le nom du fichier, pour que les fichiers attendus soient les mêmes sur toutes les machines.
- Les erreurs de syntaxe cachent les autres : dans le programme cassé de l'exercice 2 de la leçon 1, la faute de frappe `Writeline` (CS0117) n'est signalée qu'une fois le `;` et le guillemet manquants corrigés. L'exercice repose là-dessus.
- Entrée standard : quand l'entrée vient d'un fichier, le texte tapé n'apparaît pas dans la sortie, donc les fichiers attendus contiennent les questions directement suivies des réponses. Les leçons montrent le terminal tel qu'une personne le voit, avec les lignes tapées, et le disent.
- Culture : la culture de mon Windows est `en-CA`. Avec `es-ES`, `double.TryParse("1.5")` renvoie `true` et 15, car le point sépare les milliers en espagnol ; avec `fr-FR`, il renvoie `false`. L'exemple fixe chaque culture explicitement, donc la sortie est la même sur tous les OS. Les autres exemples n'utilisent que des formats qui s'affichent de la même façon en `en-CA`, en `en-US` et dans la culture invariante du runner Linux.

## 2026-09-14 — CI

- Commit [`b19a296`](https://github.com/spareilleux/learn/commit/b19a296), exécution [34914488934](https://github.com/spareilleux/learn/actions/runs/34914488934) : verte sur les trois OS. `actions/setup-dotnet`, avec le `global.json` du cours, a installé le SDK **10.0.401** sur les trois runners, alors que les sorties ont été capturées avec 10.0.112 : tous les messages du compilateur sont identiques. Les jobs ont pris 54 s sous Linux, 1 min 36 s sous macOS et 2 min 18 s sous Windows, avec un `dotnet clean` et une compilation pour chacune des 58 applications basées sur des fichiers.
- `Math.Pow(2, 7 / 12.0)` affiché avec tous ses chiffres, `164.81377845643496`, est le même sur les trois OS.
- La ligne shebang `#!/usr/bin/env -S dotnet --` fonctionne sur les runners Linux et macOS après `chmod +x`, et `dotnet run` l'ignore sous Windows.
- Les codes de sortie d'une exception non gérée diffèrent, donc `check.sh` les affiche et ne compare que `exit crash` :
  - Linux et macOS : 134 (le processus s'interrompt, `SIGABRT`) pour les trois exemples qui plantent ;
  - Windows, vu depuis Git Bash : 127 pour `IndexOutOfRangeException` et `SwitchExpressionException`, et 139 avec un message « Segmentation fault » pour `NullReferenceException` ;
  - Windows, vu depuis PowerShell : `0xE0434352` (-532462766), le code d'une exception .NET, pour `IndexOutOfRangeException`, mais `0xC0000005` (-1073741819), une violation d'accès, pour `NullReferenceException`.

## 2026-09-14 — Dogfooding

- Les exemples utilisent Guitar Alchemist comme petites données : l'accordage standard de [`Tuning.Default`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Tuning.cs#L20-L23) au commit `a826864`, et douze noms de projets de `code/ladybugdb/data/ga/projects.csv`, extraits au commit `a26a7893`. Rien dans ces leçons n'a révélé de problème dans GA.

## À vérifier

- Les commandes d'installation pour Linux et macOS : seul le `setup-dotnet` de la CI a tourné sur ces OS.
- La démonstration du débogueur de la leçon 3 dans VS Code, Visual Studio et Rider, pour une application basée sur un fichier et pour un projet. VS Code 1.118 et Rider sont installés sur ma machine ; Visual Studio ne l'est pas.
- Les conditions de licence des trois éditeurs, au moment de la lecture.
