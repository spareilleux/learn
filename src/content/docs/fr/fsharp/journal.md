---
title: Journal
description: Notes de progression datées du cours F# — le SDK et F# Interactive, le fonctionnement des vérifications, et ce que les leçons ont trouvé dans TARS et Guitar Alchemist, avec les points encore à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Code du cours : scripts, sessions F# Interactive, extraits rejetés, solutions des exercices et trois petits projets, comparés à leur sortie attendue par `check.sh`
- [ ] CI sous Linux, Windows et macOS : le workflow est écrit mais pas encore poussé (voir plus bas)
- [x] Leçon 1 : scripts, F# Interactive et projets
- [x] Leçon 2 : valeurs, fonctions et inférence de types
- [x] Leçon 3 : tuples, records, unions et options
- [x] Leçon 4 : filtrage par motif
- [ ] Leçon 5 : listes, tableaux et séquences

## 2026-09-15 — Le SDK et F# Interactive

- Ma machine a les SDK .NET 10.0.112 et 11.0.100-preview.3.26207.106. Le [`global.json`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/global.json) du cours épingle `10.0.100` avec `rollForward: latestFeature`, ce qui sélectionne 10.0.112 : F# Interactive 14.0.112.0 pour F# 10.0, et FSharp.Core avec la version d'assembly 10.0.0.0.
- Les exemples sont des scripts `.fsx` exécutés avec `dotnet fsi`, plutôt que des projets : un script démarre en 2 secondes environ sur ma machine, ne demande aucune compilation, et peut charger les fichiers de GA avec `#load` et référencer FParsec avec `#r "nuget: …"`. Seule la leçon 1 compile des projets, trois petits, chacun en 2 secondes environ.
- **Un script est entièrement vérifié avant de s'exécuter** : dans `l01_format_type.fsx`, le `printfn` au-dessus de l'erreur n'affiche rien.
- **F# Interactive a signalé une erreur par exécution** dans les scripts de ce lot : l'exercice 3 de la leçon 2 contient trois erreurs indépendantes et demande quatre exécutions. Je n'ai pas vérifié si `dotnet build` en signale plusieurs à la fois dans un projet.
- Les messages du compilateur pour un script montrent le nom du fichier sans son dossier, même quand le script est exécuté depuis un autre dossier. `dotnet build` montre le chemin complet, ajoute ` [project.fsproj]` et affiche chaque erreur deux fois (une fois quand elle survient, une fois dans le résumé) : [`check.sh`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/check.sh) garde les lignes `error FS`/`warning FS`, retire le chemin et le suffixe, et supprime les doublons. Les messages sur plusieurs lignes, comme le « expected to have type » de FS0001, terminent certaines lignes par des espaces, que `check.sh` retire aussi.
- Une exception non gérée dans un script affiche la pile d'appels avec les chemins complets, puis `Stopped due to error`, et `dotnet fsi` sort avec le code 1. `check.sh` supprime les lignes `   at …`.
- Les sessions F# Interactive sont vérifiées en envoyant un fichier dans `dotnet fsi --nologo` : la sortie contient les invites `>` et les réponses, sans les lignes tapées. Les leçons montrent la saisie à côté des réponses, comme une personne les voit.
- Une égalité utilisée comme instruction (`strings = 7`) reçoit l'avertissement FS0020 dans une fonction, mais aucun avertissement au niveau supérieur d'un script : je l'ai essayé en dehors du code du cours, et la leçon 2 ne montre que la fonction.
- L'indentation avec une tabulation est rejetée : `error FS1161: TABs are not allowed in F# code unless the #indent "off" option is used` (essayé en dehors du code du cours).
- Une vérification C# derrière la leçon 4, compilée à part avec le SDK 10.0.112 : voir [2026-09-15 — Comparaisons avec C#](#2026-09-15--comparaisons-avec-c).

## 2026-09-15 — CI

- Le workflow `.github/workflows/fsharp-examples.yml` exécute `check.sh` sur `ubuntu-latest`, `windows-latest` et `macos-latest`, comme les autres cours. Il n'est pas poussé : le jeton utilisé pour pousser ce dépôt ne peut pas créer de fichiers de workflow (il lui manque la portée `workflow`). En attendant, les sorties n'ont été vérifiées que sous Windows, et tout ce qui est propre à Linux et à macOS est marqué *à vérifier*.
- Deux sorties contiennent des caractères non ASCII : `EbΔ9` et les guillemets `‘…’` de FParsec dans `l04_ga_parse`. Ils sont corrects dans Git Bash sur ma machine ; le runner Windows peut les afficher dans un autre encodage (*à vérifier*).

## 2026-09-15 — Dogfooding : TARS

TARS au commit [`87464ce`](https://github.com/GuitarAlchemist/tars/tree/87464ce583c42cd11c3d76836e05842377455b24).

- **Ce qui est actif.** Le README dit que tout le développement actif est dans `v2/`. Le workflow de CI [`dotnet.yml`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/.github/workflows/dotnet.yml#L19-L30) restaure, compile et teste seulement `v2`, et `v2/Tars.sln` contient 17 projets sous `v2/src` et un projet de tests. Le niveau supérieur du dépôt garde des dizaines de dossiers plus anciens (`TarsEngine.FSharp.*`, `backup_fake_elimination_*`…) qu'aucun workflow ne compile : les leçons ne les citent pas.
- **Neuf fichiers `.fs` que rien ne compile.** `v2/src` lui-même contient `Fibonacci.fs`, `FSharp.ReverseList.fs`, `LintRunner.fs`, `Main.fs`, `OllamaClient.fs`, `PalindromeChecker.fs`, `Program.fs`, `StaticAnalysisRunner.fs` et `ToolFactory.fs`. Aucun `.fsproj` ne les liste (les projets qui ont les mêmes noms de fichiers listent leurs propres copies, comme `Tars.Llm/OllamaClient.fs`), et deux d'entre eux sont presque vides (95 et 3 octets). `v2/src/Tars.LSP` a un projet, `Tars.LSP.fsproj`, que `Tars.sln` n'inclut pas : la CI ne le compile donc pas non plus. La leçon 1 s'en sert pour montrer qu'un projet F# ne compile que les fichiers qu'il liste.
- **Pas de fichier de licence.** Le README affiche un badge « License: MIT » qui pointe vers `./LICENSE`, mais le dépôt n'a pas de fichier `LICENSE` à ce commit : le lien est cassé. Le cours lie et cite le code de TARS mais ne copie pas ses fichiers ; `examples/l02_tars_normalize.fsx` retape une fonction de huit lignes pour l'exécuter.
- **Des cas d'union qui masquent `Result`.** [`Domain.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Domain.fs#L62-L78) déclare `PartialFailure.Error` et `ExecutionOutcome.Failure` sans `[<RequireQualifiedAccess>]`. Chaque fichier compilé après lui qui veut dire `Result.Error` doit le qualifier : `v2/src` contient 342 occurrences de `Result.Error`, et `ArcTypes.fs` écrit `FSharp.Core.Result.Error`. Les fichiers compilés avant lui, comme `Budget.fs`, écrivent un simple `Error`. Ajouter l'attribut casserait du code dans TARS (chaque `Warning`, `Error`, `Success`, `Failure` de ces unions aurait besoin du nom de son type). Reproduit dans `compile_fail/l03_case_shadowing.fsx` ; montré dans la leçon 3.
- **`TextNormalizer.normalize` ne garde que l'ASCII.** L'expression régulière `[^a-z0-9\s]` de [`TextNormalizer.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/TextNormalizer.fs#L51-L58) supprime `#` (`"learn F#"` donne les mots-clés `learn` et `f`) et toutes les lettres accentuées (`café` donne `caf`). Ses tests n'utilisent que des phrases en anglais, et je n'ai trouvé aucun appelant dans `v2/src` en dehors de ses tests (`grep` à ce commit). Montré dans la leçon 2.
- Pour la leçon 16 : `BudgetGovernor` dans [`Budget.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Budget.fs#L133-L150) se dit thread-safe et lit son `mutable consumed` sous un verrou dans `Remaining`, mais sa propriété `Consumed` renvoie le champ sans le verrou.

## 2026-09-15 — Dogfooding : Guitar Alchemist

GA au commit [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381). Six fichiers sont copiés dans [`code/fsharp/external/ga`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/external/ga), inchangés à part leurs fins de ligne.

- **`ChordParser.parse` abandonne la fin de l'entrée.** `pChord` n'est pas suivi de `eof` : le parseur s'arrête au premier caractère qu'il ne reconnaît pas et renvoie `Ok` avec ce qu'il a lu. `C7sus4` est normalisé en `C7`, et `Am(maj7)` en `Am` (`examples/l04_ga_parse.fsx`, leçon 4). `ChordDslService.Parse` et `Normalize` en héritent, et le `ResponseValidator` C# du chatbot, qui vérifie seulement si `Parse` a réussi, accepte tout mot qui commence comme un accord et correspond à son expression régulière. Une correction possible est `run (pChord .>> eof) chordStr`, avec `C7sus4` et `Am(maj7)` ajoutés à [`ChordDslTests.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Tests/Common/GA.Business.DSL.Tests/ChordDslTests.cs#L11-L18) ; un vrai `sus4` après une extension demanderait alors aussi une règle de parseur.
- **`HarmonicTransformationService.GetNormalForm` dépend de la transposition.** Pour l'ensemble `{0, 4, 7, 8}`, elle renvoie `[0; 4; 7; 8]`, et pour le même ensemble transposé de 8 demi-tons, `[0; 3; 4; 8]` : deux rotations ont la même étendue, et `List.minBy fst` garde la première au lieu de comparer les intervalles intérieurs comme le fait l'ordre normal (`examples/l02_ga_transformations.fsx`, leçon 2). La recherche de code de GitHub n'a trouvé aucun appelant de `GetNormalForm` dans GA le 2026-09-15, et le `HarmonicTransformationTests.cs` de GA ne la teste pas. Dans le même fichier, `Invert` et `ApplyNegativeHarmony` calculent la même formule (`2 * axis - pc` et `sumAxis - pc`), et le commentaire d'`ApplyNegativeHarmony` demande encore « axis = 3.5 semitones? ».
- **`Scripts/BinObj.fsx` sélectionne trop et n'exécute rien.** `isObjOrBinFolder` teste si un chemin complet *se termine par* `bin` ou `obj`, sans tenir compte de la casse : les dossiers nommés `cabin` ou `Robin` sont sélectionnés, et leurs sous-dossiers ne sont pas visités. Le script définit ses fonctions et ne les appelle jamais (`examples/l04_ga_binobj.fsx`, leçon 4).
- **`Scripts/ModesConfig.fsx` ne s'exécute pas.** Exécuté tel quel avec `dotnet fsi` depuis le dossier `Scripts`, il s'arrête à la ligne 21 avec deux `error FS3373: Invalid interpolated string` (aux colonnes 57 et 59) : une chaîne littérale `", "` dans une interpolation `$"…"`. Avec une chaîne entre triples guillemets, la même ligne reçoit `FS0039: The value, constructor, namespace or type 'Join' is not defined`, puisque le script n'a pas d'`open System` (reproduit dans l'exercice 2 de la leçon 1). Au-delà, `#r "nuget: GA.Business.Config, 1.0.0"` nomme un paquet que nuget.org n'a pas (son index de paquets a répondu `BlobNotFound` le 2026-09-15), et `#I` ajoute un dossier où chercher des assemblies, pas une source de paquets. Un autre `ModesConfig.fsx` existe à la racine du dépôt.
- **Deux arbres pour un accord.** `ChordAst` peut écrire `Bbmaj7` comme `Quality = None` avec `Extension "maj7"` (ce que produit le parseur) ou comme `Quality = Some Major` avec `Extension "7"` ; les deux rendent le même texte et sont comparés comme différents (exercice 3 de la leçon 3).

## 2026-09-15 — Comparaisons avec C#

La leçon 4 compare la vérification d'exhaustivité de F# à celle de C#. Les deux fichiers C# ci-dessous ont été compilés à part avec `dotnet run` et le SDK 10.0.112, pas dans la CI du cours :

- Une hiérarchie de records `abstract record Fingering` avec trois sous-classes `sealed`, et une expression `switch` avec un bras par sous-classe :

  ```text
  hierarchy.cs(3,42): warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern '_' is not covered.
  ```

- Un `enum Accidental { Natural, Sharp, Flat }` et une expression `switch` avec un bras par valeur nommée :

  ```text
  enumswitch.cs(3,41): warning CS8524: The switch expression does not handle some values of its input type (it is not exhaustive) involving an unnamed enum value. For example, the pattern '(Accidental)3' is not covered.
  ```

Les deux programmes se sont quand même exécutés et ont affiché leur résultat.

## À vérifier

- Tout le cours sous Linux et macOS, et sur le runner Windows, une fois le workflow poussé.
- Les dossiers de sortie de compilation de la leçon 1 sous Linux et macOS (exécutable `Hello`, dossiers de ressources).
- <kbd>Alt</kbd>+<kbd>Entrée</kbd> pour envoyer du code à F# Interactive dans VS Code avec Ionide, Rider et Visual Studio.
- Si `dotnet build` signale en une seule exécution plusieurs erreurs indépendantes d'un même fichier, là où F# Interactive en a signalé une.
