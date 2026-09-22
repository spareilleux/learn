---
title: Journal
description: Notes de progression datées du cours F# — le SDK et F# Interactive, le fonctionnement des vérifications, et ce que les leçons ont trouvé dans TARS et Guitar Alchemist, avec les points encore à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Code du cours : scripts, sessions F# Interactive, extraits rejetés, solutions des exercices et trois petits projets, comparés à leur sortie attendue par `check.sh`
- [ ] CI sous Linux, Windows et macOS : poussée, verte le 2026-09-16, rouge depuis le 2026-09-20 sur trois fichiers attendus (voir le 2026-09-22)
- [x] Leçon 1 : scripts, F# Interactive et projets
- [x] Leçon 2 : valeurs, fonctions et inférence de types
- [x] Leçon 3 : tuples, records, unions et options
- [x] Leçon 4 : filtrage par motif
- [x] Leçon 5 : listes, tableaux et séquences
- [x] Leçon 6 : modules, espaces de noms et organisation d'un projet
- [x] Leçon 7 : les erreurs avec `Result`
- [x] Leçon 8 : expressions de calcul appliquées au parsing d'un DSL
- [x] Leçon 14 : type providers CSV et JSON avec FSharp.Data 8.2.0

## QA

Le SDK .NET 10 (10.0.112), F# 10 et `dotnet fsi` 14.0.112.0 ; TARS à `87464ce` et GuitarAlchemist/ga à `32f143c` pour les cas pratiques. La première ligne concerne le cours lui-même : c'est la raison pour laquelle la CI est rouge depuis le 2026-09-20. Rien n'a été signalé en amont. Le tableau d'expériences qui suit est inchangé.

| Attendu | Ce qui se passe | Où | Mesure | État |
|---|---|---|---|---|
| Les sorties attendues commitées avec les leçons 5 à 8 sont ce qu'impriment les exemples | Trois d'entre elles finissent par une ligne vide de plus que ce qu'impriment les exemples, et la CI échoue sur les trois OS | `code/fsharp/expected/l05_collections.txt`, `l06_modules.txt`, `l07_result.txt`, commit `69a02c4` | `FAIL l05_collections`, `FAIL l06_modules`, `FAIL l07_result` sur chaque OS dans [l'exécution 35528402823](https://github.com/spareilleux/learn/actions/runs/35528402823) ; les fichiers finissent par `exit 0` suivi de deux sauts de ligne | Reproduit ; diagnostiqué, pas encore corrigé [2026-09-22](#2026-09-22--ci-sur-trois-os) |
| Un script s'exécute de haut en bas, donc un `printfn` placé avant une erreur s'affiche | Tout le script est vérifié d'abord, donc rien ne s'affiche | `l01_format_type.fsx`, `dotnet fsi` 14.0.112.0, F# 10.0 | Le `printfn` au-dessus de l'erreur n'affiche rien | Par conception [2026-09-15](#2026-09-15--le-sdk-et-f-interactive) |
| Un compilateur signale en un passage toutes les erreurs indépendantes d'un fichier | F# Interactive en signale une par exécution | F# Interactive 14.0.112.0, exercice 3 de la leçon 2 | Trois fautes indépendantes demandent quatre exécutions | Reproduit ; savoir si `dotnet build` les regroupe reste *à vérifier* [2026-09-15](#2026-09-15--le-sdk-et-f-interactive) |
| `dotnet fsi` et `dotnet build` présentent un diagnostic de la même façon | `fsi` affiche le nom de fichier nu ; `dotnet build` affiche le chemin complet, ajoute ` [project.fsproj]`, affiche chaque erreur deux fois et laisse des espaces en fin de ligne dans le texte de FS0001 | SDK 10.0.112 | La même erreur, deux formes | Reproduit ; `check.sh` retire le chemin, le suffixe, les doublons et les espaces finaux [2026-09-15](#2026-09-15--le-sdk-et-f-interactive) |
| Une égalité utilisée comme instruction avertit où qu'elle apparaisse | `strings = 7` lève FS0020 dans une fonction et rien au niveau racine d'un script | `dotnet fsi`, SDK 10.0.112 | FS0020 dans une fonction ; aucun avertissement au niveau racine | Reproduit, non signalé [2026-09-15](#2026-09-15--le-sdk-et-f-interactive) |
| Une tabulation est un blanc, donc du code indenté par tabulations compile | Le compilateur le refuse | F# Interactive, SDK 10.0.112 | `error FS1161: TABs are not allowed in F# code unless the #indent "off" option is used` | Par conception [2026-09-15](#2026-09-15--le-sdk-et-f-interactive) |
| Un `switch` C# avec une branche par sous-classe `sealed` d'un `abstract record` est exhaustif | Roslyn avertit quand même ; le programme compile et s'exécute | `hierarchy.cs(3,42)`, SDK 10.0.112 | `warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive).` | Par conception : C# n'a pas de hiérarchies fermées, et c'est ce que montre la comparaison [2026-09-15](#2026-09-15--comparaisons-avec-c) |
| Un `switch` C# sur les trois valeurs nommées d'un `enum` est exhaustif | Roslyn avertit d'une valeur sans nom hors de l'ensemble déclaré | `enumswitch.cs(3,41)`, SDK 10.0.112 | `warning CS8524: … For example, the pattern '(Accidental)3' is not covered.` | Par conception [2026-09-15](#2026-09-15--comparaisons-avec-c) |
| Les fichiers `.fs` de l'arborescence active sont compilés par un projet | Neuf fichiers `.fs` de `v2/src` ne sont dans aucun `.fsproj`, et un projet manque à la solution, si bien que la CI ne le construit jamais | GuitarAlchemist/tars à `87464ce`, `v2/src` ; `Tars.LSP.fsproj` absent de `v2/Tars.sln` | `Fibonacci.fs`, `LintRunner.fs`, `OllamaClient.fs`, `ToolFactory.fs` et cinq autres ; deux font 95 et 3 octets | Reproduit ; utilisé en leçon 1 [2026-09-15](#2026-09-15--dogfooding--tars) |
| Le badge « License: MIT » du README pointe vers un fichier `LICENSE` | Il n'y a pas de fichier `LICENSE` à ce commit | GuitarAlchemist/tars à `87464ce`, le lien du README vers `./LICENSE` | Un lien cassé | Reproduit, non signalé [2026-09-15](#2026-09-15--dogfooding--tars) |
| Un `Error` nu en F# désigne `Result.Error` | Deux unions déclarées sans `[<RequireQualifiedAccess>]` le masquent, et chaque fichier suivant doit le qualifier | [`Domain.fs`, lignes 62-78](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Domain.fs#L62-L78) | 342 occurrences de `Result.Error` dans `v2/src` ; `ArcTypes.fs` va jusqu'à `FSharp.Core.Result.Error` | Reproduit dans `compile_fail/l03_case_shadowing.fsx` et montré en leçon 3 ; le corriger en amont casserait l'API [2026-09-15](#2026-09-15--dogfooding--tars) |
| Un normaliseur de texte garde les caractères significatifs de son entrée | Son motif `[^a-z0-9\s]` retire `#` et toutes les lettres accentuées, et aucun test ne couvre l'un ou l'autre | [`TextNormalizer.fs`, lignes 51-58](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/TextNormalizer.fs#L51-L58) | `"learn F#"` donne les mots-clés `learn` et `f` ; `café` donne `caf` | Reproduit ; montré en leçon 2 [2026-09-15](#2026-09-15--dogfooding--tars) |
| Un type documenté comme sûr entre threads lit son état mutable sous son verrou | `Remaining` prend le verrou ; la propriété `Consumed` rend le champ `mutable consumed` sans lui | [`Budget.fs`, lignes 133-150](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Budget.fs#L133-L150), `BudgetGovernor` | Lu dans le code | Non reproduit : cette ligne est une lecture de code. Gardé pour la leçon 16 [2026-09-15](#2026-09-15--dogfooding--tars) |
| Un analyseur qui rend `Ok` a consommé toute son entrée | `pChord` n'est pas suivi de `eof` : il s'arrête au premier caractère qu'il ne connaît pas et rend `Ok` pour le préfixe | GuitarAlchemist/ga à `32f143c`, `ChordParser.parse`, repris par `ChordDslService` et par le `ResponseValidator` du chatbot | `C7sus4` est lu comme `C7` ; `Am(maj7)` comme `Am` | Reproduit dans `examples/l04_ga_parse.fsx` et montré en leçon 4 ; un correctif y est proposé, non soumis [2026-09-15](#2026-09-15--dogfooding--guitar-alchemist) |
| La forme normale ne dépend pas de la transposition | `List.minBy fst` garde la première rotation d'étendue égale au lieu de comparer les intervalles intérieurs, et la réponse bouge avec la transposition | GuitarAlchemist/ga à `32f143c`, `HarmonicTransformationService.GetNormalForm` | `{0, 4, 7, 8}` donne `[0; 4; 7; 8]` ; le même ensemble transposé de 8 donne `[0; 3; 4; 8]` | Reproduit dans `examples/l02_ga_transformations.fsx` ; aucun appelant trouvé, et aucun test ne le couvre [2026-09-15](#2026-09-15--dogfooding--guitar-alchemist) |

## Expériences

| Question | Hypothèse | Résultat mesuré | Verdict | Preuve |
|---|---|---|---|---|
| Une expression de calcul minimale rend-elle la grammaire d'un DSL lisible sans masquer les erreurs ? | `Bind` et `Return` suffisent pour la grammaire séquentielle de notes. | Quatre cas passent, dont le rejet d'une lettre invalide et du texte restant. | Confirmée | [Entrée du 2026-09-20](#2026-09-20--expressions-de-calcul-et-type-providers), [`l08_parser_ce.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l08_parser_ce.fsx) |
| FSharp.Data infère-t-il des membres CSV et JSON imbriqués utiles sous .NET 10 ? | FSharp.Data 8.2.0 exposera les colonnes et propriétés typées en F# 10. | Deux lignes CSV et un document JSON imbriqué compilent et affichent les valeurs typées attendues. | Confirmée | [Entrée du 2026-09-20](#2026-09-20--expressions-de-calcul-et-type-providers), [`l14_type_providers.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l14_type_providers.fsx) |

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

## 2026-09-20 — Collections, modules et `Result`

- Ajout de la leçon 5 avec des comparaisons exécutables entre les transformations immédiates de `List` et `Array` et un pipeline `Seq` paresseux.
- Ajout de la leçon 6 avec des modules imbriqués, une visibilité explicite et un petit exemple d'organisation qui garde une surface publique étroite.
- Ajout de la leçon 7 avec un pipeline de validation fondé sur `Result`, la composition explicite des erreurs et la frontière entre les échecs attendus et les exceptions.
- `dotnet fsi` a reproduit les sorties conservées pour `l05_collections.fsx`, `l06_modules.fsx` et `l07_result.fsx` avec le SDK .NET 10.0.112.

## 2026-09-20 — Expressions de calcul et type providers

- Ajout de la leçon 8 autour d'un vrai builder `Parser<'T>`. Le harness exécute les cas de succès, de token invalide et de texte restant ; ce dernier rend explicite l'invariant de fin d'entrée.
- Ajout de la leçon 14 avec FSharp.Data 8.2.0, épinglé depuis NuGet. Les échantillons CSV et JSON sont des chaînes locales : le typage ne dépend pas d'un schéma distant.
- `dotnet fsi` a produit les sorties conservées dans `expected/l08_parser_ce.txt` et `expected/l14_type_providers.txt` avec le SDK .NET 10.0.112.

## 2026-09-22 — CI sur trois OS

- L'entrée du 2026-09-15 dit que le workflow n'est pas poussé. Il l'a été ensuite : [l'exécution 35097250880](https://github.com/spareilleux/learn/actions/runs/35097250880), le 2026-09-16, est passée sur `ubuntu-latest`, `windows-latest` et `macos-latest`.
- [L'exécution 35528402823](https://github.com/spareilleux/learn/actions/runs/35528402823), le 2026-09-20, la première après les leçons 5 à 8 et 14, a échoué sur les trois. L'essentiel de son journal est fait de lignes `ok`, ce qui la faisait passer pour un échec sans vérification fautive. Il y en a une : `FAIL l05_collections`, `FAIL l06_modules` et `FAIL l07_result`, une fois par OS, chacune suivie d'un `diff` qui retire une ligne vide en fin de fichier. Les trois fichiers attendus finissent par `exit 0` et deux sauts de ligne ; les autres fichiers attendus, par un seul. `check.sh` met `status=1` à chaque écart et continue, si bien que toutes les vérifications suivantes affichent encore `ok` et que le script sort avec 1 à la fin. Le diagnostic est d'auggie, vérifié contre le journal d'exécution et les fichiers ; on ne sait pas comment ces lignes en trop sont entrées dans le commit.
- Le correctif consiste à retirer un saut de ligne final dans chacun des trois fichiers. Il n'est pas encore appliqué.
- La même exécution tranche deux notes *à vérifier* : `l04_ga_parse`, avec `EbΔ9` et les guillemets `‘…’` de FParsec, affiche `ok` sur le runner Windows, et chaque leçon imprime la même sortie sous Linux, macOS et Windows, à ces trois fichiers près.

## À vérifier

- Les dossiers de sortie de compilation de la leçon 1 sous Linux et macOS (exécutable `Hello`, dossiers de ressources).
- <kbd>Alt</kbd>+<kbd>Entrée</kbd> pour envoyer du code à F# Interactive dans VS Code avec Ionide, Rider et Visual Studio.
- Si `dotnet build` signale en une seule exécution plusieurs erreurs indépendantes d'un même fichier, là où F# Interactive en a signalé une.
