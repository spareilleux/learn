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
- [x] Leçon 5 : classes et objets
- [x] Leçon 6 : records, structs et enums
- [x] Leçon 7 : interfaces et héritage (en local ; CI sur trois OS à vérifier)

## QA

| Attendu | Ce qui se passe | Où | Mesure | Statut |
|---|---|---|---|---|
| Afficher un modèle d'accord de GA montre son `Name`, comme le veut le `ToString() => Name` du record de base | Les records dérivés `TonalModal` et `Analytical` synthétisent chacun leur propre `ToString`, qui énumère toutes les propriétés : `TonalModal { Name = Major 7th, PitchClassSet = 0 4 7 E, … }`. Un record dérivé ne garde le `ToString` de la base que s'il est `sealed` ([records, mise en forme intégrée](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record#built-in-formatting-for-display)) | [ChordTemplate.cs:84](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L84) ; un appelant, [ContextualChordsController.cs:301](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Apps/ga-server/GA.Fretboard.Service/Controllers/ContextualChordsController.cs#L301), passe `template.ToString()` à un service qui le journalise ([FretboardServices.cs:536](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Apps/ga-server/GA.Fretboard.Service/Services/FretboardServices.cs#L536)) | Une sonde console qui référence GA.Domain.Core au commit `5c3a52a`, SDK 10.0.112 : le dump pour `ToString()` et `$"{template}"` sur les deux records ; une réplique avec `sealed` a affiché `maj7` ([entrée](#2026-10-01--interfaces-et-héritage)) | Reproduit ; non signalé à GA |

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

## 2026-09-29 — Classes et objets

- La leçon 5 présente la construction, l'identité des instances, les champs privés, les propriétés publiques, les méthodes et un compteur `static` partagé, puis propose de créer une classe `PracticeSession`. Les pages anglaise, française et espagnole contiennent les mêmes extraits C# testés et les mêmes sorties du compilateur.
- Sous Windows, avec le SDK 10.0.112, `C:/Program Files/Git/bin/bash.exe check.sh` a réussi pour les exemples, les solutions et les extraits refusés du cours, y compris les nouveaux fichiers `l05_*`. Les deux nouveaux extraits refusés ont produit respectivement CS0122 et CS0200. Le `bash` par défaut de la machine était celui de WSL et ne trouvait pas le `dotnet` Windows : ce premier échec venait de l'environnement de test, pas du code.
- Ce résultat local ne remplace pas une nouvelle CI sur trois OS et ne prouve pas que la leçon est publiée. Les leçons 6 à 12 restent au stade de plan.

## 2026-09-30 — La leçon 5 dans la CI sur trois OS

- Le [run 36664604662](https://github.com/spareilleux/learn/actions/runs/36664604662) du workflow *C# for beginners examples*, sur le commit `669d42a` de la [PR #60](https://github.com/spareilleux/learn/pull/60), a réussi sous `ubuntu-latest`, `windows-latest` et `macos-latest`. Dans la sortie de chaque job, `check.sh` affiche `ok` pour `l05_objects`, `l05_ex_practice`, `l05_get_only_property` et `l05_private_field` : les sorties et les diagnostics CS0122 et CS0200 correspondent à `expected/` sur les trois OS.

## 2026-10-01 — Records, structs et enums

- La leçon 6 compare une structure et une classe (copie à l'affectation, copie en argument, `Equals`), puis présente les records (`==` sur les données, `ToString`, `with`, `readonly record struct`) et les énumérations (numérotées à partir de 0, valeur par défaut, casts, `Enum.IsDefined`, `Enum.Parse`). Elle compte quatre exemples, trois exercices et cinq extraits refusés, dont les diagnostics sont CS0019, CS1612, CS8852 (trois fois dans deux fichiers) et CS0266. Un script a vérifié que les trois langues partagent les mêmes blocs de code, commentaires mis à part, et que chaque bloc correspond à son fichier dans `code/csharp-beginner` et `expected/`.
- Sous Windows, avec le SDK 10.0.112 et Git Bash, `check.sh` s'est terminé avec le code 0 et 75 lignes `ok`, dont les 12 fichiers `l06_*`. Ce n'est pas encore une exécution de la CI sur trois OS.
- Puis dans la CI : le [run 36865237779](https://github.com/spareilleux/learn/actions/runs/36865237779) du workflow *C# for beginners examples*, sur le commit `114b5ed` de la [PR #93](https://github.com/spareilleux/learn/pull/93), a réussi sous `ubuntu-latest`, `windows-latest` et `macos-latest`. Chaque job affiche `ok` pour les 12 fichiers `l06_*` ; les jobs comptent 76 lignes `ok` sous Linux et macOS et 75 sous Windows, car `check.sh` ne lance l'exemple à shebang avec `./` que sous Linux et macOS.
- Surprises, toutes reprises dans la leçon : CS8524 avertit pour une expression `switch` qui a une branche par nom, et son exemple est `(ChordQuality)5` alors que le programme échoue sur 7 ; le littéral `0` se convertit en énumération sans cast, alors que `2` donne CS0266 ; une `List<T>` de structures modifiables refuse `shape[0].Fret = 5` avec CS1612.
- Un brouillon de l'exercice 3 disait que `shape[i].Fret += 2` sur une liste de `readonly record struct` donne le même CS1612. Une sonde compilée avant publication a donné CS8852 ; le texte a été corrigé, et `compile_fail/l06_readonly_position.cs` conserve désormais les deux lignes CS8852. Deux autres phrases reposent sur des sondes restées hors du code du cours : ranger une copie modifiée avec `shape[0] = position;` a affiché 5, et `List<T>.Contains` sur une classe sans égalité propre a répondu `False`.
- Dogfooding : au commit `5c3a52a` de GA, [`ChordQuality`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordQuality.cs#L10-L23) commence par `Other`, et `PositionLocation`, `Str` et `Fret` sont des types `readonly record struct`. Rien dans cette leçon n'a révélé de problème dans GA.

## 2026-10-01 — Interfaces et héritage

- La leçon 7 construit `Guitar` et `Ukulele` sur une classe de base `StringInstrument` (`base(...)`, `virtual`, `override`, `base.Describe()`, `ToString`), puis une classe abstraite `Instrument` avec une méthode abstraite `Play`, puis une interface `IHasRange` qu'une classe et un record implémentent tous deux. Elle compte quatre exemples, dont un qui compile avec l'avertissement CS0114, trois exercices et cinq extraits refusés, dont les diagnostics sont CS0506, CS0509, CS0144, CS0534 et CS0535. Le script utilisé pour la leçon 6 a vérifié les 20 blocs de code des trois langues contre `code/csharp-beginner` et `expected/`.
- Sous Windows, avec le SDK 10.0.112 et Git Bash, `check.sh` s'est terminé avec le code 0 et 87 lignes `ok`, dont les 12 fichiers `l07_*`. Ce n'est pas encore une exécution de la CI sur trois OS.
- Deux phrases du brouillon ne reposaient sur aucune exécution et ont changé avant publication. Que seule une variable de type `Ukulele` trouve une méthode qui masque est désormais une ligne de `examples/l07_hiding_warning.cs`, qui affiche `a ukulele`. « Les numéros MIDI sont ceux de la leçon 4, où do4 vaut 60 » était faux, puisque la leçon 4 ne donne aucun numéro MIDI ; la phrase dit maintenant que les numéros MIDI comptent des demi-tons, 12 par octave.
- Dogfooding : au commit `5c3a52a` de GA, [`ChordTemplate`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L15-L18) est un record abstrait dont les records dérivés `TonalModal` et `Analytical` redéfinissent `Name`, et dont le propre [`ToString() => Name`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L84) n'est pas `sealed`. La page sur les records dit qu'un `ToString` `sealed` empêche le compilateur d'en synthétiser un dans les records dérivés ([mise en forme intégrée pour l'affichage](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record#built-in-formatting-for-display)) ; celui-ci devait donc être masqué. Une sonde l'a confirmé : un projet console qui référence GA.Domain.Core et GA.Domain.Services au commit `5c3a52a`, compilé avec le SDK 10.0.112, a affiché `TonalModal { Name = Major 7th, PitchClassSet = 0 4 7 E, … }` pour `ToString()` et pour `$"{template}"` sur un `TonalModal`, sur un `Analytical` et sur `ChordTemplateFactory.CreateModalChords(...).First()`, et la réflexion a désigné le record dérivé comme le type qui déclare `ToString`. Une réplique de même forme avec `public sealed override string ToString() => Name` a affiché `maj7`. Un seul site d'appel en dépend : [ContextualChordsController.cs:301](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Apps/ga-server/GA.Fretboard.Service/Controllers/ContextualChordsController.cs#L301) passe `template.ToString()` à `GetVoicingsForChordAsync`, qui le journalise ([FretboardServices.cs:536](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Apps/ga-server/GA.Fretboard.Service/Services/FretboardServices.cs#L536)) ; la réponse HTTP prend le nom de l'accord dans la route, pas dans cette chaîne. Le constat figure dans le tableau QA ; il n'a pas été signalé à GA.

## À vérifier

- Les exemples et diagnostics de la leçon 7 dans la CI Linux, Windows et macOS, après l'ouverture d'une PR.
- Les commandes d'installation pour Linux et macOS : seul le `setup-dotnet` de la CI a tourné sur ces OS.
- La démonstration du débogueur de la leçon 3 dans VS Code, Visual Studio et Rider, pour une application basée sur un fichier et pour un projet. VS Code 1.118 et Rider sont installés sur ma machine ; Visual Studio ne l'est pas.
- Les conditions de licence des trois éditeurs, au moment de la lecture.

## Questions ouvertes

- Les `Str` et `Fret` de GA déclarent chacun une conversion implicite depuis `int` ([Str.cs:45](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Instruments/Primitives/Str.cs#L45), [Fret.cs:72](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Instruments/Primitives/Fret.cs#L72)). `new PositionLocation(3, 5)`, avec la corde et la frette inversées sous forme de simples nombres, compile-t-il sans avertissement ? Non exécuté.
