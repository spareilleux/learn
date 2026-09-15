---
title: 2. Valeurs, fonctions et inférence de types
description: let au lieu de var, des valeurs immuables par défaut, des types inférés pour les paramètres et les résultats, pas de conversion implicite, if comme expression, des fonctions curryfiées, l'application partielle et les opérateurs |> et >> — avec les transformations de classes de hauteurs de GA et le normaliseur de texte de TARS.
sidebar:
  order: 2
---

Code : les scripts [`examples/l02_*.fsx`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples), les extraits rejetés [`compile_fail/l02_*.fsx`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/compile_fail) et la session [`sessions/l02_inference.txt`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/sessions/l02_inference.txt).

## `let` lie un nom à une valeur

En C#, `var strings = 6;` déclare une variable : vous pouvez la réaffecter plus tard. En F#, `let strings = 6` donne le nom `strings` à la valeur `6`, et c'est définitif :

```fsharp
let strings = 6
strings <- 7
```

```text
l02_immutable.fsx(2,1): error FS0027: This value is not mutable. Consider using the mutable keyword, e.g. 'let mutable strings = expression'.
```

Un `let` est plus proche d'un champ `readonly` de C# ou d'une variable locale `final` de Java, sauf que c'est le comportement par défaut, et qu'il s'applique à toutes les sortes de valeurs. Quand vous avez vraiment besoin d'une variable, le compilateur vous dit comment faire : `let mutable`, et l'opérateur d'affectation `<-`.

```fsharp
// mutable autorise l'affectation, et <- affecte
let mutable total = 0

for fret in 1..12 do
    total <- total + fret

printfn "Frets 1 to 12 add up to %d" total
```

```text
Frets 1 to 12 add up to 78
```

`for fret in 1..12 do` est le `foreach` de C# sur l'intervalle de 1 à 12, bornes incluses. Le F# idiomatique a rarement besoin de cette boucle : la leçon 5 la remplace par `List.sum`. `mutable` n'est pas une faute, mais il reste local et explicite, et il se remarque à la lecture du code.

### `=` compare, `<-` affecte

Le piège qui attrape chaque développeur C# le premier jour :

```fsharp
let restring () =
    let mutable strings = 6
    strings = 7 // = compare : cette ligne calcule false et le jette
    printfn "%d strings" strings

restring ()
```

```text
l02_equality_warning.fsx(3,5): warning FS0020: The result of this equality expression has type 'bool' and is implicitly discarded. Consider using 'let' to bind the result to a name, e.g. 'let result = expression'. If you intended to mutate a value, then use the '<-' operator e.g. 'strings <- expression'.

6 strings
```

En F#, `=` dans une expression est l'égalité, le `==` de C#. `strings = 7` vaut `false`, une valeur que la ligne jette ; `strings` vaut toujours 6. Ce n'est qu'un avertissement, donc le script s'exécute : traitez FS0020 comme une erreur.

### Le masquage

Deux `let` du même nom au niveau supérieur d'un script ou d'un module sont rejetés :

```fsharp
let tuning = "E2 A2 D3 G3 B3 E4"
let tuning = "D2 A2 D3 G3 B3 E4"
printfn "%s" tuning
```

```text
l02_duplicate.fsx(2,5): error FS0037: Duplicate definition of value 'tuning'
```

Dans une fonction, un nouveau `let` peut réutiliser un nom : il définit une nouvelle valeur qui *masque* la précédente à partir de cette ligne. Rien n'est modifié :

```fsharp
let label (name: string) =
    let name = name.Trim() // une nouvelle valeur qui masque le paramètre
    let name = name.ToUpperInvariant() // et une autre
    $"[{name}]"

printfn "%s" (label "  e minor ")
```

```text
[E MINOR]
```

C# rejette une variable locale qui réutilise le nom d'un paramètre ; Rust autorise le masquage de la même façon que F#.

## Le compilateur infère les types

Voici ce que F# Interactive répond pour quelques définitions ([`sessions/l02_inference.txt`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/sessions/l02_inference.txt)) :

```text
> let semitones = 7;;
val semitones: int = 7

> let ratio = 2.0 ** (7.0 / 12.0);;
val ratio: float = 1.498307077

> let name = "fifth";;
val name: string = "fifth"

> let isPerfect = true;;
val isPerfect: bool = true

> let add a b = a + b;;
val add: a: int -> b: int -> int

> let addFloats (a: float) b = a + b;;
val addFloats: a: float -> b: float -> float

> let twice f x = f (f x);;
val twice: f: ('a -> 'a) -> x: 'a -> 'a

> let first (a, b) = a;;
val first: a: 'a * b: 'b -> 'a
```

- `float` est le nom F# de `System.Double`, le `double` de C#. `int` est `System.Int32`, `string` est `System.String`. `**` est l'opérateur de puissance (`Math.Pow`).
- Le `var` de C# infère le type d'une variable locale. F# infère aussi **les paramètres et les types de retour**. `add` n'a aucune annotation ; `+`, sans autre indice, prend `int` par défaut.
- Une annotation suffit à changer cela : dans `addFloats`, `(a: float)` fait de `+` une addition de flottants, donc `b` et le résultat sont des flottants.
- `twice` fonctionne pour n'importe quel type : F# l'a rendue **générique** tout seul. `'a` est un paramètre de type, le `T` de C#. Le type se lit « prend une fonction de `'a` vers `'a` et une valeur `'a`, et renvoie un `'a` ». En C#, vous écririez `static T Twice<T>(Func<T, T> f, T x)`.
- `first` prend un tuple et renvoie son premier élément, quels que soient les types : `'a * 'b -> 'a`. La [leçon 3](../03-records-unions-options/) porte sur les tuples.

L'inférence va de haut en bas et de gauche à droite, ce qui est une raison de plus pour l'ordre des fichiers de la [leçon 1](../01-first-program/#les-fichiers-compilent-dans-lordre). Les fonctions publiques d'une bibliothèque reçoivent quand même des annotations en général : elles documentent l'API, et elles empêchent qu'un changement dans la fonction modifie sa signature sans bruit.

## Pas de conversion implicite

C# convertit un `int` en `double` pour vous. F# ne convertit jamais un nombre implicitement :

```fsharp
let semitones = 7
let ratio = 2.0 ** (semitones / 12.0)
```

```text
l02_int_float.fsx(2,33): error FS0001: The type 'float' does not match the type 'int'
```

`semitones / 12.0` divise un `int` par un `float` : F# refuse, là où C# calculerait un `double` sans rien dire. Les fonctions de conversion portent le nom du type cible :

```fsharp
let semitones = 7
let ratio = 2.0 ** (float semitones / 12.0) // float convertit explicitement

printfn "A fifth multiplies the frequency by %.4f" ratio
printfn "A2 = 110 Hz, so E3 = %.2f Hz" (110.0 * ratio)

printfn "%d" (int 3.99) // int tronque, comme un cast en C#
printfn "%s" (string 440) // string appelle ToString
printfn "%d" (int "22") // int analyse aussi une chaîne, et lève une exception s'il n'y arrive pas
```

```text
A fifth multiplies the frequency by 1.4983
A2 = 110 Hz, so E3 = 164.81 Hz
3
440
22
```

`float semitones` est un appel de fonction, comme `printfn "…" ratio` : la fonction, puis son argument. C'est le même `float` que le nom du type ; F# utilise le nom pour les deux. La page [cast et conversions](https://learn.microsoft.com/dotnet/fsharp/language-reference/casting-and-conversions) liste les fonctions.

## Tout est expression

En C#, `if` est une instruction et `?:` est sa forme expression. En F#, `if … then … else` *est* l'expression, et un bloc aussi :

```fsharp
// if/then/else est une expression : il a une valeur, comme l'opérateur ?: de C#
let fretLabel fret = if fret = 0 then "open" else $"fret {fret}"
printfn "%s, %s" (fretLabel 0) (fretLabel 3)

// Un bloc est aussi une expression : sa valeur est sa dernière ligne
let positions =
    let strings = 6
    let frets = 22
    strings * (frets + 1)

printfn "%d positions, open strings included" positions

// Les fonctions qui n'ont qu'un effet renvoient unit, écrit ()
let nothing = printfn "printfn returns unit"
printfn "%A" nothing
```

```text
open, fret 3
138 positions, open strings included
printfn returns unit
()
```

- `positions` est calculé par un bloc dont les valeurs internes, `strings` et `frets`, n'existent pas en dehors.
- F# n'a pas de `void`. Une fonction qui ne renvoie rien d'utile renvoie `unit`, dont la seule valeur s'écrit `()`. C'est pourquoi `let restring () = …` ci-dessus prend `()` : elle prend un argument, la valeur unit, et on l'appelle avec `restring ()`. Appeler une méthode C# `void` depuis F# renvoie aussi `unit`.

Un `if` sans `else` ne peut être que de type `unit` : s'il produisait une chaîne quand la condition est vraie, que produirait-il quand elle est fausse ?

```fsharp
let fretLabel fret = if fret = 0 then "open"
```

```text
l02_if_without_else.fsx(1,39): error FS0001: This 'if' expression is missing an 'else' branch. Because 'if' is an expression, and not a statement, add an 'else' branch which also returns a value of type 'string'.
```

## Fonctions

### Les paramètres sont séparés par des espaces

Les classes de hauteurs de la théorie musicale numérotent les douze notes d'une octave : 0 est do, 1 est do♯, et ainsi de suite jusqu'à 11, si. Transposer une note ajoute des demi-tons et revient à 0 après 11. Le [`HarmonicTransformationService`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Services/HarmonicTransformationService.fs#L10) de Guitar Alchemist commence par cette fonction :

```fsharp
let normalize pc = ((pc % 12) + 12) % 12
```

Le `%` d'un nombre négatif est négatif en F#, comme en C# : `-5 % 12` vaut `-5`. La fonction ajoute donc 12 et reprend `% 12`, pour tomber entre 0 et 11 : `normalize -5` vaut 7, sol.

```fsharp
// Classes de hauteurs : 0 = do, 1 = do#, ..., 11 = si. Le HarmonicTransformationService de Guitar Alchemist utilise cette formule.
let normalize pc = ((pc % 12) + 12) % 12
printfn "%d %d" (-5 % 12) (normalize -5) // % garde le signe, normalize non

// Deux paramètres séparés par des espaces : transpose a le type int -> int -> int
let transpose interval pc = normalize (pc + interval)

let names = [| "C"; "C#"; "D"; "D#"; "E"; "F"; "F#"; "G"; "G#"; "A"; "A#"; "B" |]
let name pc = names[pc]

printfn "%s" (name (transpose 7 0))

// Application partielle : donner seulement le premier argument, et recevoir une fonction
let upAFifth = transpose 7
printfn "%s %s %s" (name (upAFifth 0)) (name (upAFifth 7)) (name (upAFifth 2))

// Un argument négatif : le signe moins touche le nombre
printfn "%s" (name (transpose -1 0))

// Pipeline : x |> f est f x
printfn "%s" (0 |> upAFifth |> upAFifth |> upAFifth |> name)

// Composition : f >> g est fun x -> g (f x)
let fifthName = upAFifth >> name
printfn "%s" (fifthName 9)

// Lambda : fun pc -> ... est le pc => ... de C#
let downASemitone = fun pc -> transpose -1 pc
printfn "%s" (name (downASemitone 0))
```

```text
-5 7
G
G D A
B
A
E
B
```

`[| … |]` est un tableau, et `names[pc]` l'indexe. `name (transpose 7 0)` a besoin de ses parenthèses : sans elles, `name transpose 7 0` passerait trois arguments à `name`.

### Fonctions curryfiées et application partielle

`transpose` a le type `int -> int -> int`. Lisez les flèches depuis la droite : `transpose` prend un `int` et renvoie une fonction `int -> int`. `transpose 7 0` est `(transpose 7) 0`. Les fonctions qui prennent leurs paramètres un par un de cette façon sont dites **curryfiées**, d'après le logicien Haskell Curry.

`transpose 7`, avec un seul argument, est donc une valeur complète : une fonction qui transpose d'une quinte vers le haut. C'est l'**application partielle**. L'équivalent C# demande des lambdas imbriquées :

```csharp
Func<int, Func<int, int>> transpose = interval => pc => Normalize(pc + interval);
var upAFifth = transpose(7);
```

et Java a `Function<Integer, Function<Integer, Integer>>`. F# en fait la manière normale d'écrire une fonction, et c'est pourquoi l'ordre des paramètres compte : celui que l'on fixera le plus probablement vient en premier. `interval` vient avant `pc`, pour que `transpose 7` ait un sens.

L'habitude C# d'appeler avec des parenthèses et des virgules passe **un tuple** au lieu de deux arguments :

```fsharp
let normalize (pc: int) = ((pc % 12) + 12) % 12
let transpose (interval: int) (pc: int) = normalize (pc + interval)

let g = transpose(7, 0)
```

```text
l02_tuple_call.fsx(4,19): error FS0001: This expression was expected to have type
    'int'
but here has type
    'int * int'
```

`int * int` est le type du tuple `(7, 0)`. Les méthodes des classes .NET, en revanche, s'appellent avec des parenthèses et des virgules : `name.Trim()`, `Regex.Replace(s, pattern, "")`. La section suivante montre où les deux se rencontrent.

Les espaces autour d'un signe moins comptent aussi. `transpose -1 0` passe `-1`, mais `transpose - 1 0` soustrait :

```fsharp
printfn "%d" (transpose - 1 0)
```

```text
l02_minus_spaced.fsx(4,27): error FS0003: This value is not a function and cannot be applied.
```

F# lit `transpose - (1 0)`, et `1` n'est pas une fonction que l'on pourrait appliquer à `0`.

### Lambdas, `|>` et `>>`

- `fun pc -> transpose -1 pc` est une lambda, le `pc => Transpose(-1, pc)` de C#. Puisque `transpose -1` est déjà cette fonction, `let downASemitone = transpose -1` ferait la même chose.
- `x |> f` est `f x` : l'opérateur **pipe** passe la valeur à sa gauche à la fonction à sa droite. `0 |> upAFifth |> upAFifth |> upAFifth |> name` se lit dans l'ordre où le travail se fait, comme une chaîne de méthodes LINQ. Il est défini dans FSharp.Core comme une fonction ordinaire à deux arguments, qui appelle la deuxième avec le premier.
- `f >> g` est la **composition** de deux fonctions : une nouvelle fonction qui appelle `f`, puis `g` sur le résultat.

TARS écrit son prétraitement de texte comme un pipeline, dans [`TextNormalizer.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/TextNormalizer.fs#L71-L73) :

```fsharp
    /// Extract keywords from text (normalize -> tokenize -> remove stop words -> dedup)
    let extractKeywords (text: string) =
        text |> normalize |> tokenize |> removeStopWords |> List.distinct
```

Chaque étape est une fonction du module qui prend le résultat de la précédente ; le commentaire et le code disent la même chose, dans le même ordre. Sa première étape, [`normalize`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/TextNormalizer.fs#L51-L58), mélange des méthodes .NET (appelées avec des parenthèses) et des pipes F#, avec des lambdas au milieu :

```fsharp
    let normalize (text: string) =
        if String.IsNullOrWhiteSpace(text) then
            ""
        else
            text.ToLowerInvariant()
            |> fun s -> Regex.Replace(s, @"[^a-z0-9\s]", "") // Keep only alphanumeric and space
            |> fun s -> Regex.Replace(s, @"\s+", " ") // Collapse multiple spaces
            |> fun s -> s.Trim()
```

- `(text: string)` est annoté parce que `text.ToLowerInvariant()` appelle une méthode : F# doit connaître le type de `text` avant un `.`, puisque l'inférence va de gauche à droite.
- `@"…"` est une chaîne verbatim, comme en C#.
- `|> fun s -> …` envoie dans une lambda, une par ligne.

Le script [`examples/l02_tars_normalize.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l02_tars_normalize.fsx) du cours retape cette fonction (TARS n'a pas de fichier de licence, donc le cours ne copie pas le fichier) et l'exécute :

```fsharp
printfn "[%s]" (normalize "  How do I   learn F#? ")
printfn "[%s]" (normalize "C# and F# on .NET 10")
printfn "[%s]" (normalize "Qu'est-ce qu'un café ? ¿Qué es un acorde?")
```

```text
[how do i learn f]
[c and f on net 10]
[questce quun caf qu es un acorde]
```

Le motif `[^a-z0-9\s]` supprime tout ce qui n'est pas une lettre ASCII, un chiffre ou un espace. Pour un framework d'agents écrit en F#, cela inclut `#` : les mots-clés de « learn F# » sont `learn` et `f`, et `C#` devient la lettre unique `c`. Les lettres accentuées disparaissent au milieu des mots : `café` devient `caf`. Le [test](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/tests/Tars.Tests/TextNormalizerTests.fs#L6-L11) de TARS n'utilise qu'une phrase en anglais. Le journal le note ; la leçon 5 revient sur ce module.

## Du vrai code : les membres curryfiés de GA

`HarmonicTransformationService` est une classe (leçon 9), dont les membres sont curryfiés comme les fonctions ci-dessus. [Son `Transpose`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Services/HarmonicTransformationService.fs#L12-L16) :

```fsharp
    /// <summary>
    /// Transposes a set of pitch classes.
    /// </summary>
    member _.Transpose (interval: Interval) (pcs: PitchClassSet) : PitchClassSet =
        pcs |> Set.map (fun pc -> normalize (pc + interval))
```

`Interval` et `PitchClassSet` sont des abréviations de types de [`MusicalSetTypes.fs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Types/MusicalSetTypes.fs#L8-L12) : d'autres noms pour `int` et `Set<int>`. `Set.map` applique la lambda à chaque élément de l'ensemble. Le `: PitchClassSet` après les paramètres annote le résultat.

Le cours charge le fichier de GA avec `#load` et l'appelle ([`examples/l02_ga_transformations.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l02_ga_transformations.fsx)) :

```fsharp
// Le HarmonicTransformationService de Guitar Alchemist, chargé depuis les copies de external/ga
#load "../external/ga/MusicalSetTypes.fs" "../external/ga/HarmonicTransformationService.fs"

open GA.Business.DSL.Services

let service = HarmonicTransformationService()
let cMajor = set [ 0; 4; 7 ] // do mi sol

printfn "%A" (service.Transpose 7 cMajor) // une quinte plus haut : sol si ré

let upAFifth = service.Transpose 7 // une méthode aux paramètres curryfiés peut être appliquée partiellement
printfn "%A" (cMajor |> upAFifth |> upAFifth) // ré fa# la

printfn "%A" (service.Invert 0 cMajor) // miroir autour de do : do fa lab

// Compilé, le membre curryfié est une méthode .NET ordinaire à deux paramètres : C# appelle Transpose(2, set)
let transpose = typeof<HarmonicTransformationService>.GetMethod "Transpose"

for parameter in transpose.GetParameters() do
    printfn "%s %s" parameter.ParameterType.Name parameter.Name
```

```text
set [2; 7; 11]
set [2; 6; 9]
set [0; 5; 8]
Int32 interval
FSharpSet`1 pcs
```

Les deux dernières lignes montrent comment F# compile un membre curryfié : une méthode ordinaire `Transpose(int interval, FSharpSet<int> pcs)`. Les tests C# de GA l'appellent ainsi, dans [`HarmonicTransformationTests.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Tests/Common/GA.Business.DSL.Tests/HarmonicTransformationTests.cs#L15-L18) : `_service.Transpose(2, cMajor)`. L'application partielle reste du côté F# ; la leçon 20 porte sur la conception d'API F# que C# consomme confortablement.

:::caution[Ce que le cours a trouvé]
La même classe a une méthode [`GetNormalForm`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Services/HarmonicTransformationService.fs#L35-L58), « un ordre normal simplifié transposé à zéro ». Une forme normale doit donner la même réponse pour un accord et pour ses transpositions, mais ce n'est pas le cas :

```fsharp
let chord = set [ 0; 4; 7; 8 ]
printfn "%A" (service.GetNormalForm chord)
printfn "%A" (service.GetNormalForm(service.Transpose 8 chord))
```

```text
[0; 4; 7; 8]
[0; 3; 4; 8]
```

Deux rotations de cet ensemble ont la plus petite étendue, 8 demi-tons, et `List.minBy fst` garde celle qui vient en premier : la réponse dépend donc de l'endroit où l'ensemble commence. L'ordre normal compare aussi les intervalles intérieurs quand les étendues sont égales, ce qui choisirait `[0; 3; 4; 8]` les deux fois. La recherche de code de GitHub n'a trouvé aucun appelant de `GetNormalForm` dans GA le 2026-09-15 : rien n'utilise encore la mauvaise réponse. Détails dans le [journal](../journal/).
:::

## À retenir

- `let` donne un nom à une valeur qui ne change jamais ; `let mutable` et `<-` sont l'exception explicite, et `=` compare toujours.
- Le compilateur infère les types des valeurs, des paramètres et des résultats, et généralise les fonctions quand il le peut (`'a`) ; une annotation suffit à l'orienter.
- Les nombres ne se convertissent jamais implicitement : `float`, `int` et `string` convertissent explicitement.
- `if`, les blocs et `try` sont des expressions ; `unit` et `()` remplacent `void`.
- Les fonctions prennent leurs arguments séparés par des espaces et sont curryfiées : `transpose 7` est une fonction. `|>` envoie une valeur dans une fonction, `>>` compose deux fonctions, et `fun x -> …` est une lambda.

## Exercices

1. En tempérament égal, chaque demi-ton multiplie la fréquence par la racine douzième de 2, et le la4 est à 440 Hz. Écrivez `frequency`, qui prend le nombre de demi-tons depuis le la4 (un `int`, négatif sous le la4), et affichez les fréquences du la4, du mi4 (5 demi-tons plus bas) et du mi2 (29 plus bas) avec deux décimales.

<details>
<summary>Solution</summary>

[`exercises/l02_ex_frequency.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l02_ex_frequency.fsx) :

```fsharp
// Tempérament égal : chaque demi-ton multiplie la fréquence par 2^(1/12), et le la4 est à 440 Hz
let frequency semitonesFromA4 = 440.0 * 2.0 ** (float semitonesFromA4 / 12.0)

printfn "A4 = %.2f Hz" (frequency 0)
printfn "E4 = %.2f Hz" (frequency -5)
printfn "E2 = %.2f Hz" (frequency -29)
```

```text
A4 = 440.00 Hz
E4 = 329.63 Hz
E2 = 82.41 Hz
```

`float semitonesFromA4` est obligatoire : sans lui, `semitonesFromA4 / 12.0` donne l'erreur FS0001 de [Pas de conversion implicite](#pas-de-conversion-implicite). F# infère `frequency: semitonesFromA4: int -> float`.

</details>

2. Écrivez `interval fromPc toPc`, le nombre de demi-tons à *monter* d'une classe de hauteurs à une autre (de mi, 4, à do, 0, il y en a 8). Définissez ensuite `fromE` par application partielle, et utilisez-la sur sol (7), do (0) et, avec `|>`, mi (4).

<details>
<summary>Solution</summary>

[`exercises/l02_ex_partial.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l02_ex_partial.fsx) :

```fsharp
let normalize pc = ((pc % 12) + 12) % 12

// Demi-tons à monter d'une classe de hauteurs à une autre
let interval fromPc toPc = normalize (toPc - fromPc)

let fromE = interval 4 // application partielle : int -> int

printfn "E up to G: %d semitones" (fromE 7)
printfn "E up to C: %d semitones" (fromE 0)
printfn "E up to E: %d semitones" (4 |> fromE)
```

```text
E up to G: 3 semitones
E up to C: 8 semitones
E up to E: 0 semitones
```

`0 - 4` vaut `-4`, et `normalize` le transforme en 8 : c'est pourquoi la formule de GA ajoute 12 avant le second `% 12`.

</details>

3. Ce script contient trois erreurs. Exécutez-le, corrigez ce que F# signale, et recommencez jusqu'à ce qu'il affiche `capo on fret 3: frequencies multiplied by 1.1892`. Combien d'exécutions a-t-il fallu ?

```fsharp
let capo = 2
capo <- 3
let ratio = 2.0 ** (capo / 12.0)
let label = if capo = 0 then "no capo"
```

<details>
<summary>Solution</summary>

Quatre exécutions : ici, F# Interactive signale une erreur par exécution. La première :

```text
l02_ex_broken.fsx(2,1): error FS0027: This value is not mutable. Consider using the mutable keyword, e.g. 'let mutable capo = expression'.
```

Après `let mutable capo = 2`, la deuxième :

```text
l02_ex_broken_step2.fsx(3,28): error FS0001: The type 'float' does not match the type 'int'
```

Après `float capo`, la troisième :

```text
l02_ex_broken_step3.fsx(4,30): error FS0001: This 'if' expression is missing an 'else' branch. Because 'if' is an expression, and not a statement, add an 'else' branch which also returns a value of type 'string'.
```

Le script corrigé ([`exercises/l02_ex_fixed.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l02_ex_fixed.fsx)), avec le `printfn` que demandait l'énoncé :

```fsharp
let mutable capo = 2
capo <- 3
let ratio = 2.0 ** (float capo / 12.0)
let label = if capo = 0 then "no capo" else $"capo on fret {capo}"

printfn "%s: frequencies multiplied by %.4f" label ratio
```

```text
capo on fret 3: frequencies multiplied by 1.1892
```

Un capodastre en case 3 élève chaque corde de 3 demi-tons, et `2.0 ** (3.0 / 12.0)` vaut environ 1.1892.

</details>

## Sources

- [Valeurs](https://learn.microsoft.com/dotnet/fsharp/language-reference/values/), [liaisons `let`](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/let-bindings)
- [Inférence de type](https://learn.microsoft.com/dotnet/fsharp/language-reference/type-inference), [généralisation automatique](https://learn.microsoft.com/dotnet/fsharp/language-reference/generics/automatic-generalization)
- [Cast et conversions](https://learn.microsoft.com/dotnet/fsharp/language-reference/casting-and-conversions), [types de base](https://learn.microsoft.com/dotnet/fsharp/language-reference/basic-types)
- [Expressions conditionnelles](https://learn.microsoft.com/dotnet/fsharp/language-reference/conditional-expressions-if-then-else), [type unit](https://learn.microsoft.com/dotnet/fsharp/language-reference/unit-type)
- [Fonctions](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/), [expressions lambda](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/lambda-expressions-the-fun-keyword), [opérateurs de FSharp.Core](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-operators.html)
- [Référence des symboles et opérateurs](https://learn.microsoft.com/dotnet/fsharp/language-reference/symbol-and-operator-reference/)
