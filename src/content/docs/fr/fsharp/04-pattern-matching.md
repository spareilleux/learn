---
title: 4. Filtrage par motif
description: match à côté de l'expression switch de C# et du switch à motifs de Java — constantes, motifs « ou », gardes, tuples, cas d'union, records et listes, les avertissements pour les règles incomplètes et inaccessibles, et ce que le filtrage a trouvé dans le parseur d'accords et le script BinObj de GA.
sidebar:
  order: 4
---

Code : les scripts [`examples/l04_*.fsx`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples) et l'extrait rejeté [`compile_fail/l04_warnaserror.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/compile_fail/l04_warnaserror.fsx).

## `match` est une expression `switch`

C# 8 a ajouté l'expression `switch`, et C# 9 ses motifs relationnels et `or` :

```csharp
string IntervalName(int semitones) => semitones switch
{
    0 => "unison",
    3 or 4 => "third",
    7 => "perfect fifth",
    12 => "octave",
    > 12 => "compound interval",
    _ => "other",
};
```

Java 21 a `switch` avec des motifs et des gardes `when`. Le [`match`](https://learn.microsoft.com/dotnet/fsharp/language-reference/match-expressions) de F# est la construction sur laquelle ils ont été modelés :

```fsharp
// match essaie les motifs de haut en bas ; le premier qui convient l'emporte
let intervalName semitones =
    match semitones with
    | 0 -> "unison"
    | 3 | 4 -> "third" // motif « ou »
    | 7 -> "perfect fifth"
    | 12 -> "octave"
    | n when n > 12 -> $"compound interval ({n - 12} above an octave)" // garde
    | _ -> "other" // joker

for semitones in [ 0; 4; 7; 10; 19 ] do
    printfn "%d: %s" semitones (intervalName semitones)

// Un tuple filtre plusieurs valeurs à la fois
let position (stringNumber, fret) =
    match stringNumber, fret with
    | _, 0 -> "open string"
    | (5 | 6), f -> $"bass string, fret {f}"
    | s, f -> $"string {s}, fret {f}"

printfn "%s" (position (6, 0))
printfn "%s" (position (5, 3))
printfn "%s" (position (2, 1))
```

```text
0: unison
4: third
7: perfect fifth
10: other
19: compound interval (7 above an octave)
open string
bass string, fret 3
string 2, fret 1
```

- Chaque règle s'écrit `| motif -> expression`. Les règles sont essayées dans l'ordre, et la valeur du `match` est l'expression de la première règle qui convient. Comme `if`, `match` est une expression : toutes ses branches ont le même type.
- `3 | 4` est un **motif « ou »**, le `3 or 4` de C#.
- `n when n > 12` **lie** la valeur à `n`, puis une **garde** la teste. F# n'a pas de motifs relationnels comme le `> 12` de C# : une garde fait le même travail.
- `_` correspond à n'importe quoi, comme le discard de C#.
- `match stringNumber, fret with` filtre un tuple. `_, 0` signifie « n'importe quelle corde, case 0 » ; `(5 | 6), f` imbrique un motif « ou » dans le motif de tuple et lie la case.

## Cas d'union et options

Les motifs rapportent vraiment avec les [unions discriminées](../03-records-unions-options/#unions-discriminées) : un motif peut tester le cas et décomposer ses données en une seule étape.

```fsharp
type Fingering =
    | Open
    | Fretted of fret: int
    | Barre of fret: int * strings: int
    | Muted

let describe fingering =
    match fingering with
    | Open -> "open string"
    | Muted -> "not played"
    | Fretted 1 -> "first fret" // un cas avec une constante à l'intérieur
    | Fretted fret -> $"fret {fret}" // un cas qui lie ses données
    | Barre(fret, 6) -> $"full barre on fret {fret}"
    | Barre(fret = f; strings = n) -> $"barre on fret {f} across {n} strings" // par nom de champ

for fingering in [ Open; Muted; Fretted 1; Fretted 5; Barre(1, 6); Barre(3, 4) ] do
    printfn "%s" (describe fingering)

// Option est aussi une union : Some et None sont ses cas
let capoLabel capo =
    match capo with
    | None
    | Some 0 -> "no capo"
    | Some fret -> $"capo on fret {fret}"

printfn "%s, %s, %s" (capoLabel None) (capoLabel (Some 0)) (capoLabel (Some 2))

// function est fun x -> match x with, comme dans le ChordRenderer de Guitar Alchemist
let isPlayed =
    function
    | Muted -> false
    | _ -> true

printfn "%b %b" (isPlayed Muted) (isPlayed (Fretted 3))
```

```text
open string
not played
first fret
fret 5
full barre on fret 1
barre on fret 3 across 4 strings
no capo, no capo, capo on fret 2
false true
```

- `Fretted 1` ne correspond qu'à la valeur `Fretted 1` ; `Fretted fret` correspond à n'importe quel `Fretted` et nomme ses données `fret`. L'ordre compte : inversé, `Fretted fret` attraperait `Fretted 1` en premier.
- `Barre(fret = f; strings = n)` filtre les champs par leur nom, séparés par `;`.
- Un motif « ou » peut s'étendre sur deux lignes, comme `None` et `Some 0`.
- `function` est un raccourci pour une lambda qui filtre immédiatement son argument : `let isPlayed = function | … ` est `let isPlayed x = match x with | …`.

La version C# de `describe` utiliserait des motifs de type sur une hiérarchie de records (`Fretted { Fret: 1 } => …`, `Fretted f => …`). Cela se ressemble, et c'est bien le cas, à une différence près, dont parle la section suivante.

### Du vrai code : le moteur de rendu d'accords de GA

Le [`ChordRenderer.fs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Generators/ChordRenderer.fs#L5-L40) de GA retransforme en texte le `ChordAst` de la leçon 3. C'est presque entièrement du filtrage par motif :

```fsharp
module ChordRenderer =
    let renderAccidental =
        function
        | Natural -> ""
        | Sharp -> "#"
        | Flat -> "b"
        | DoubleSharp -> "##"
        | DoubleFlat -> "bb"

    // (renderQuality, lignes 14-21, a la même forme)

    let renderComponent =
        function
        | Extension s -> s
        | Alteration(acc, deg) -> (renderAccidental acc) + deg
        | Omission deg -> "(no " + deg + ")"
        | Alt -> "alt"

    let render (ast: ChordAst) =
        let root = ast.Root + (renderAccidental ast.RootAccidental)
        let qual = ast.Quality |> Option.map renderQuality |> Option.defaultValue ""
        let comps = ast.Components |> List.map renderComponent |> String.concat ""

        let bass =
            match ast.Bass with
            | Some(n, acc) -> "/" + n.ToUpper() + (renderAccidental acc)
            | None -> ""

        root + qual + comps + bass
```

- `renderAccidental` est une `function` avec une règle par cas d'`AccidentalType`, et pas de `_` : si GA ajoute un jour un triple dièse, le compilateur désignera cette fonction.
- `Alteration(acc, deg)` décompose le tuple porté par le cas.
- `Some(n, acc)` imbrique un motif de tuple dans le motif `Some` : il correspond à une basse et nomme sa lettre et son altération en une étape.
- `List.map renderComponent` applique la fonction à chaque composant ; la leçon 5 porte sur `List`.

## Le compilateur vérifie que chaque cas est traité

Voici un `match` qui oublie deux cas :

```fsharp
type Accidental =
    | Natural
    | Sharp
    | Flat
    | DoubleSharp
    | DoubleFlat

let symbol accidental =
    match accidental with
    | Natural -> ""
    | Sharp -> "#"
    | Flat -> "b"

printfn "C%s" (symbol Sharp)
printfn "C%s" (symbol DoubleFlat)
printfn "never printed"
```

```text
l04_incomplete.fsx(9,11): warning FS0025: Incomplete pattern matches on this expression. For example, the value 'DoubleFlat' may indicate a case not covered by the pattern(s).

C#
Microsoft.FSharp.Core.MatchFailureException: The match cases were incomplete
Stopped due to error
```

Le compilateur connaît chaque cas d'`Accidental`, et en nomme un qu'aucune règle ne couvre. C'est un avertissement, donc le script s'exécute, et échoue à l'exécution avec une `MatchFailureException` quand `DoubleFlat` arrive vraiment (F# Interactive affiche aussi la pile d'appels, que le `check.sh` du cours supprime).

C# avertit aussi, mais ne peut pas être aussi précis. Une expression `switch` sur la hiérarchie de records `Fingering` de la leçon 3 qui traite `Open`, `Fretted` et `Muted`, les trois sous-classes, reçoit quand même `warning CS8509: … For example, the pattern '_' is not covered` : un autre assembly pourrait ajouter une sous-classe. Sur une énumération dont chaque valeur nommée est listée, elle reçoit CS8524, parce que `(Accidental)3` est aussi une valeur valide. Le code C# se termine donc par un bras `_ =>`, qui fait taire l'avertissement pour de bon (le [journal](../journal/#2026-09-15--comparaisons-avec-c) contient les deux fichiers). Java 21 vérifie bien un `switch` sur une interface `sealed`, et rejette un cas manquant. Les unions F# sont fermées comme les types scellés de Java, et F# vérifie tous les motifs : tuples d'unions, options imbriquées, listes.

Un avertissement qui laisse le programme planter plus tard devrait être une erreur. Dans un projet, `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`, ou `<WarningsAsErrors>FS0025</WarningsAsErrors>` pour ce seul avertissement, le fait pour toute la compilation ; TARS active le premier dans [`v2/Directory.Build.props`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/Directory.Build.props#L3), GA non. Pour un script, `dotnet fsi` accepte l'[option du compilateur](https://learn.microsoft.com/dotnet/fsharp/language-reference/compiler-options) `--warnaserror+:25` :

```text
> dotnet fsi --warnaserror+:25 compile_fail/l04_warnaserror.fsx
l04_warnaserror.fsx(10,11): error FS0025: Incomplete pattern matches on this expression. For example, the value 'DoubleFlat' may indicate a case not covered by the pattern(s).
```

### Les gardes mettent la vérification en échec

Le compilateur ne peut pas évaluer une garde. Ces trois règles couvrent tous les entiers, mais seul un lecteur peut le voir :

```fsharp
let direction interval =
    match interval with
    | n when n > 0 -> "up"
    | n when n < 0 -> "down"
    | n when n = 0 -> "same note"

printfn "%s %s %s" (direction 5) (direction -2) (direction 0)
```

```text
l04_guards_warning.fsx(2,11): warning FS0025: Incomplete pattern matches on this expression.

up down same note
```

Cette fois, le message ne donne pas d'exemple : le compilateur ne sait pas quelle valeur s'échappe. Écrivez la dernière règle sans garde, `| _ -> "same note"`, et l'avertissement disparaît.

### Les règles qui ne correspondent jamais

Les règles sont essayées dans l'ordre : une règle placée après un motif qui attrape tout est du code mort :

```fsharp
let intervalName semitones =
    match semitones with
    | 0 -> "unison"
    | _ -> "other"
    | 7 -> "perfect fifth"

printfn "%s" (intervalName 7)
```

```text
l04_never_matched.fsx(5,7): warning FS0026: This rule will never be matched

other
```

### Les jokers cachent les nouveaux cas

`_` est pratique et dangereux de la même façon que le `default` de C#. La fonction `isPlayed` ci-dessus utilise `| _ -> true` pour trois cas ; si un cinquième cas `Harmonic of fret: int` est ajouté à `Fingering`, `isPlayed` répond `true` pour lui sans rien dire, et aucun avertissement n'apparaît. `renderAccidental` dans GA, avec une règle par cas, recevrait l'avertissement. Préférez lister les cas d'une union dont la liste peut s'allonger ; gardez `_` pour les ensembles ouverts de valeurs comme les entiers et les chaînes.

## Motifs de listes et récursion

Une liste est soit vide, `[]`, soit un élément suivi du reste de la liste, `head :: tail`. Les motifs décomposent les listes selon ces deux formes :

```fsharp
// Motifs de listes : [] est la liste vide, head :: tail sépare le premier élément
let describeStrings strings =
    match strings with
    | [] -> "no strings"
    | [ single ] -> $"only {single}"
    | [ low; high ] -> $"{low} and {high}"
    | lowest :: rest -> $"{lowest}, then {List.length rest} more"

printfn "%s" (describeStrings [])
printfn "%s" (describeStrings [ "G4" ])
printfn "%s" (describeStrings [ "C4"; "G4" ])
printfn "%s" (describeStrings [ "E2"; "A2"; "D3"; "G3"; "B3"; "E4" ])

// Une fonction récursive (rec) parcourt la liste un élément à la fois
let rec total frets =
    match frets with
    | [] -> 0
    | fret :: rest -> fret + total rest

printfn "%d" (total [ 3; 2; 0; 1; 0 ])

// Les motifs fonctionnent aussi dans let et dans les paramètres
let (note, octave) = ("A", 4)
let lowest (first :: _) = first // avertissement : [] n'est pas traité
printfn "%s%d %s" note octave (lowest [ "E2"; "A2" ])
```

```text
l04_lists.fsx(24,13): warning FS0025: Incomplete pattern matches on this expression. For example, the value '[]' may indicate a case not covered by the pattern(s).

no strings
only G4
C4 and G4
E2, then 5 more
6
A4 E2
```

- `[ single ]` correspond à une liste d'exactement un élément, `[ low; high ]` d'exactement deux.
- `lowest :: rest` correspond à n'importe quelle liste non vide. Placé en premier, il attraperait aussi les listes d'un et de deux éléments.
- Une fonction qui s'appelle elle-même a besoin de [`rec`](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/recursive-functions-the-rec-keyword). `total` a la forme classique : une règle pour la liste vide, et une règle qui traite un élément et s'appelle récursivement sur le reste. La leçon 5 montre les fonctions de bibliothèque qui évitent d'écrire la plupart de ces fonctions.
- Les motifs ne servent pas qu'à `match`. `let (note, octave) = …` décompose un tuple, et `let describeAgent (AgentId id) = …` dans la leçon 3 déballait une union à un seul cas dans un paramètre. Ils sont vérifiés aussi : `lowest (first :: _)` reçoit FS0025, puisqu'une liste vide n'a pas de premier élément.

### Du vrai code : le script BinObj de GA

Le [`Scripts/BinObj.fsx`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Scripts/BinObj.fsx) de GA cherche les dossiers `bin` et `obj` d'une arborescence de sources, avec une fonction récursive sur une liste :

```fsharp
open System.Globalization
open System.IO

let EnumerateDirectories path =
    Directory.EnumerateDirectories(path) |> Seq.toList

let isObjOrBinFolder (folderName: string) =
    folderName.EndsWith("obj", true, CultureInfo.InvariantCulture)
    || folderName.EndsWith("bin", true, CultureInfo.InvariantCulture)

let rec getFoldersToDelete path =
    match EnumerateDirectories path with
    | [] -> []
    | subfolders ->
        let targetFolders = subfolders |> List.filter isObjOrBinFolder

        let targets =
            subfolders
            |> List.filter (isObjOrBinFolder >> not)
            |> List.collect getFoldersToDelete
            |> List.append targetFolders

        targets
```

- `match EnumerateDirectories path with | [] -> [] | subfolders -> …` traite un dossier sans sous-dossiers, puis lie la liste non vide à un nom.
- `isObjOrBinFolder >> not` compose le test avec `not`, la [composition de la leçon 2](../02-values-and-functions/#lambdas--et-) : « n'est pas un dossier bin ou obj ».
- `List.collect getFoldersToDelete` descend récursivement dans chaque sous-dossier restant et concatène les résultats.

Le cours charge le script et exécute sa fonction sur une petite arborescence ([`examples/l04_ga_binobj.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l04_ga_binobj.fsx)) :

```fsharp
// Une petite arborescence dans le dossier temporaire
let root = Path.Combine(Path.GetTempPath(), $"fsharp-course-binobj-{Environment.ProcessId}")

for folder in [ "App/bin"; "App/obj"; "App/src"; "Docs/cabin"; "Robin/Songs"; "Empty" ] do
    Directory.CreateDirectory(Path.Combine(root, folder)) |> ignore

for path in getFoldersToDelete root |> List.sort do
    printfn "%s" (Path.GetRelativePath(root, path).Replace('\\', '/'))

Directory.Delete(root, true)
```

```text
App/bin
App/obj
Docs/cabin
Robin
```

:::caution[Ce que le cours a trouvé]
Les motifs sont justes ; le test ne l'est pas. `EnumerateDirectories` renvoie des chemins complets, et `EndsWith("bin", true, …)` est vrai pour tout dossier dont le nom *se termine* par ces lettres, sans tenir compte de la casse : `Docs/cabin` et `Robin` sont sélectionnés, et `Robin/Songs` n'est même pas visité. Comparer exactement le nom du dossier, `Path.GetFileName folderName` avec `"bin"` et `"obj"`, corrigerait cela. Le script définit les fonctions mais ne les appelle jamais : exécuter `dotnet fsi Scripts/BinObj.fsx` ne fait rien et ne supprime rien. Détails dans le [journal](../journal/).
:::

## Du vrai code : filtrer un `Result` dans le parseur d'accords de GA

Le [`ChordParser.parse`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Parsers/ChordParser.fs#L86-L89) de GA exécute un parseur FParsec et convertit son résultat, une union de FParsec, en `Result` F# :

```fsharp
    let parse chordStr =
        match run pChord chordStr with
        | Success(result, _, _) -> Result.Ok result
        | Failure(errorMsg, _, _) -> Result.Error errorMsg
```

`Success(result, _, _)` lie la première de trois valeurs et ignore les deux autres. Le cours charge le parseur et filtre le `Result` qu'il renvoie ([`examples/l04_ga_parse.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l04_ga_parse.fsx)) :

```fsharp
#r "nuget: FParsec, 1.1.1"
#load "../external/ga/ChordAst.fs" "../external/ga/ChordRenderer.fs" "../external/ga/ChordParser.fs"

open GA.Business.DSL.Parsers
open GA.Business.DSL.Generators

// Le ChordParser.parse de Guitar Alchemist renvoie un Result : Ok avec l'AST, ou Error avec le message de FParsec
let normalize (input: string) =
    match ChordParser.parse input with
    | Ok ast -> $"{input} -> {ChordRenderer.render ast}"
    | Error message -> $"{input} -> error:\n{message}"

for input in [ "Cmi7"; "EbΔ9"; "F#m7b5/C"; "C7sus4"; "Am(maj7)"; "H7" ] do
    printfn "%s" (normalize input)
```

```text
Cmi7 -> Cm7
EbΔ9 -> Ebmaj9
F#m7b5/C -> F#m7b5/C
C7sus4 -> C7
Am(maj7) -> Am
H7 -> error:
Error in Ln: 1 Col: 1
H7
^
Expecting: any char in ‘CDEFGABcdefgab’
```

Les trois premières lignes sont des cas du propre test de GA, [`ChordDslTests.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Tests/Common/GA.Business.DSL.Tests/ChordDslTests.cs#L11-L18). `H7`, le nom allemand de B7, est rejeté avec le message de FParsec.

:::caution[Ce que le cours a trouvé]
`C7sus4` devient `C7`, et `Am(maj7)` devient `Am` : le parseur s'arrête au premier caractère qu'il ne comprend pas, et `parse` renvoie `Ok` avec ce qu'il a lu jusque-là. On n'indique jamais au parseur que l'entrée doit se terminer là (le `eof` de FParsec) : le reste est donc abandonné sans bruit. `ChordDslService.Parse` et `Normalize` héritent de ce comportement, tout comme le [`ResponseValidator`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.Core.Orchestration/Services/ResponseValidator.cs#L30-L38) C# du chatbot de GA, qui appelle `Parse` sur chaque mot d'une réponse qui ressemble à un accord et regarde seulement si l'appel a réussi. La leçon 11 y revient avec FParsec ; le [journal](../journal/) donne les détails.
:::

## À retenir

- `match value with | pattern -> result` essaie les règles dans l'ordre et est une expression ; `function` est une lambda qui filtre son argument.
- Les motifs se combinent : constantes, `_`, `|` pour les alternatives, gardes `when`, tuples, cas d'union avec leurs données, champs par nom, `[]` et `head :: tail` pour les listes.
- Le compilateur avertit quand un cas manque (FS0025) ou qu'une règle est inaccessible (FS0026) ; faites de FS0025 une erreur dans les projets, et évitez `_` sur les unions qui peuvent s'agrandir.
- Les gardes ne sont pas analysées : la dernière règle d'un match avec gardes ne devrait pas avoir de garde.
- Les motifs fonctionnent aussi dans `let` et dans les paramètres, avec les mêmes vérifications.

## Exercices

1. Écrivez `quality semitones`, qui renvoie `"perfect"` pour 0, 5, 7 et 12, `"minor"` pour 1, 3, 8 et 10, `"major"` pour 2, 4, 9 et 11, `"tritone"` pour 6, un message pour les nombres négatifs, et un autre pour les intervalles plus grands qu'une octave. Utilisez des motifs « ou » et une garde, et affichez le résultat pour -3, 0, 3, 4, 6, 7, 11 et 14.

<details>
<summary>Solution</summary>

[`exercises/l04_ex_intervals.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l04_ex_intervals.fsx) :

```fsharp
let quality semitones =
    match semitones with
    | n when n < 0 -> "negative: turn it into an upward interval first"
    | 0
    | 5
    | 7
    | 12 -> "perfect"
    | 1
    | 3
    | 8
    | 10 -> "minor"
    | 2
    | 4
    | 9
    | 11 -> "major"
    | 6 -> "tritone"
    | _ -> "compound: larger than an octave"

for semitones in [ -3; 0; 3; 4; 6; 7; 11; 14 ] do
    printfn "%3d: %s" semitones (quality semitones)
```

```text
 -3: negative: turn it into an upward interval first
  0: perfect
  3: minor
  4: major
  6: tritone
  7: perfect
 11: major
 14: compound: larger than an octave
```

La garde vient en premier : les nombres négatifs n'ont donc pas besoin d'être exclus plus loin. Le `_` final est justifié ici : les entiers sont un ensemble ouvert, et toute valeur au-dessus de 12 mérite la même réponse. `%3d` complète le nombre à trois caractères.

</details>

2. Corrigez la fonction `symbol` de [Le compilateur vérifie que chaque cas est traité](#le-compilateur-vérifie-que-chaque-cas-est-traité) pour que le script affiche `C#` et `Cbb` sans avertissement. Pourquoi ne pas ajouter `| _ -> ""` ?

<details>
<summary>Solution</summary>

[`exercises/l04_ex_symbol_fixed.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l04_ex_symbol_fixed.fsx) :

```fsharp
let symbol accidental =
    match accidental with
    | Natural -> ""
    | Sharp -> "#"
    | Flat -> "b"
    | DoubleSharp -> "##"
    | DoubleFlat -> "bb"
```

```text
C#
Cbb
```

`| _ -> ""` supprime aussi l'avertissement, mais affiche `C` pour un double bémol : une mauvaise réponse au lieu d'une erreur. Et le prochain cas ajouté à `Accidental` recevrait la même mauvaise réponse, sans avertissement pour désigner cette fonction.

</details>

3. Le test `Test_Complex_Alterations` de GA analyse `C13#11b9` et attend trois composants. Écrivez une fonction récursive `countAlterations` sur une `ChordComponent list`, avec des motifs de listes, qui compte les composants `Alteration` et `Alt`, et utilisez-la sur le résultat du parseur de GA pour cet accord.

<details>
<summary>Solution</summary>

[`exercises/l04_ex_count.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l04_ex_count.fsx) :

```fsharp
#r "nuget: FParsec, 1.1.1"
#load "../external/ga/ChordAst.fs" "../external/ga/ChordParser.fs"

open GA.Business.DSL.Types
open GA.Business.DSL.Parsers

let rec countAlterations components =
    match components with
    | [] -> 0
    | (Alteration _ | Alt) :: rest -> 1 + countAlterations rest
    | _ :: rest -> countAlterations rest

// L'accord du test Test_Complex_Alterations de GA (Tests/Common/GA.Business.DSL.Tests/ChordDslTests.cs)
match ChordParser.parse "C13#11b9" with
| Ok chord -> printfn "%A: %d alterations" chord.Components (countAlterations chord.Components)
| Error message -> printfn "%s" message
```

```text
[Extension "13"; Alteration (Sharp, "11"); Alteration (Flat, "9")]: 2 alterations
```

`(Alteration _ | Alt) :: rest` place un motif « ou » dans la tête d'un motif de liste ; `Alteration _` ignore les données du cas. Les deux côtés d'un motif « ou » doivent lier les mêmes noms, ici seulement `rest`, hors des parenthèses.

</details>

## Sources

- [Expressions match](https://learn.microsoft.com/dotnet/fsharp/language-reference/match-expressions), [critères spéciaux](https://learn.microsoft.com/dotnet/fsharp/language-reference/pattern-matching)
- [Fonctions récursives : le mot-clé `rec`](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/recursive-functions-the-rec-keyword), [listes](https://learn.microsoft.com/dotnet/fsharp/language-reference/lists)
- [Options du compilateur](https://learn.microsoft.com/dotnet/fsharp/language-reference/compiler-options) (`--warnaserror`)
- C# : [l'expression `switch`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression), [motifs](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/patterns) ; Java : [filtrage par motif pour `switch`](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html)
- [FParsec : exécuter des parseurs](https://www.quanttec.com/fparsec/users-guide/parser-functions.html)
