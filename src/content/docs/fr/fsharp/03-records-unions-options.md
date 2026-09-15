---
title: 3. Tuples, records, unions et options
description: Modéliser les données avec des tuples, des records immuables à égalité structurelle, des unions discriminées au lieu de hiérarchies de classes et Option au lieu de null — avec l'AST d'accords de GA et les cas d'union que TARS a dû qualifier 342 fois.
sidebar:
  order: 3
---

Code : les scripts [`examples/l03_*.fsx`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples) et les extraits rejetés [`compile_fail/l03_*.fsx`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/compile_fail).

En C# et en Java, les données vivent en général dans des classes : des champs, un constructeur, `Equals` et `GetHashCode` si on y pense, et une hiérarchie de classes quand une valeur peut prendre plusieurs formes. Les records (C# 9, Java 16) et les hiérarchies scellées (C# avec des classes de base `abstract`, Java 17 avec `sealed interface`) ont raccourci tout cela. F# a des formes courtes pour tout cela depuis le début, et c'est la manière normale de modéliser les données :

| Vous voulez | C# | Java | F# |
|---|---|---|---|
| quelques valeurs ensemble, sans nom | `(string, int)` | un record ou `Map.Entry` | tuple `string * int` |
| des champs nommés, immuables, comparés par valeur | `record` | `record` | record |
| une forme parmi plusieurs, chacune avec ses données | classe de base abstraite et sous-classes | `sealed interface` et records | union discriminée |
| une valeur qui peut manquer | `null`, `Nullable<T>` | `null`, `Optional<T>` | `Option<'T>` |

## Tuples

```fsharp
// Un tuple regroupe des valeurs sans déclarer de type : ici string * int
let lowString = ("E", 2)
printfn "%A" lowString
printfn "%s" (fst lowString)

// Déconstruction, comme var (note, octave) = ... en C#
let (note, octave) = lowString
printfn "%s%d" note octave

// Une fonction renvoie plusieurs valeurs dans un tuple
let octavesAndSemitones interval = (interval / 12, interval % 12)
let octaves, semitones = octavesAndSemitones 29 // les parenthèses sont facultatives
printfn "29 semitones = %d octaves and %d semitones" octaves semitones

// Les tuples F# sont des objets System.Tuple ; les tuples struct sont des System.ValueTuple, les tuples de C#
let structTuple = struct ("A", 4)
printfn "%s and %s" (lowString.GetType().Name) (structTuple.GetType().Name)
```

```text
("E", 2)
E
E2
29 semitones = 2 octaves and 5 semitones
Tuple`2 and ValueTuple`2
```

- Le type de `("E", 2)` s'écrit `string * int` : le `*` se lit « et », comme dans un produit de types.
- `fst` et `snd` renvoient le premier et le deuxième élément d'une paire.
- La dernière ligne montre une différence avec C# : un tuple F# est un [`System.Tuple`](https://learn.microsoft.com/dotnet/api/system.tuple-2), un objet sur le tas, alors que le `(string, int)` de C# est un [`System.ValueTuple`](https://learn.microsoft.com/dotnet/api/system.valuetuple-2), une struct. `struct ("A", 4)` crée un tuple valeur, celui à utiliser pour appeler du code C# qui en attend un. La [page sur les tuples](https://learn.microsoft.com/dotnet/fsharp/language-reference/tuples) donne les détails.

Un tuple convient pour deux ou trois valeurs qui voyagent ensemble un moment. Dès que les valeurs ont un nom dans votre tête, donnez-leur un nom dans le code : un record.

## Records

```fsharp
type GuitarString = { Note: string; Octave: int; Gauge: float }

let low = { Note = "E"; Octave = 2; Gauge = 0.046 } // les étiquettes indiquent le type à F#
let high = { low with Octave = 4; Gauge = 0.010 } // copie et mise à jour, comme with en C#

printfn "%s%d, gauge %.3f" low.Note low.Octave low.Gauge
printfn "%A" high

// Égalité et comparaison structurelles, générées par le compilateur
printfn "%b" (high = { Note = "E"; Octave = 4; Gauge = 0.010 })
printfn "%b" (low = high)
printfn "%b" (low < high) // champs comparés dans l'ordre : Note, puis Octave
```

```text
E2, gauge 0.046
{ Note = "E"
  Octave = 4
  Gauge = 0.01 }
true
false
true
```

- `type GuitarString = { … }` déclare un [record](https://learn.microsoft.com/dotnet/fsharp/language-reference/records). L'équivalent C# est `record GuitarString(string Note, int Octave, double Gauge);`.
- La valeur `{ Note = "E"; Octave = 2; Gauge = 0.046 }` ne contient pas de nom de type : F# trouve le type de record à partir de ses étiquettes.
- `{ low with Octave = 4; Gauge = 0.010 }` est une copie dont deux champs changent, le `low with { Octave = 4, Gauge = 0.010 }` de C#.
- `=` compare les champs, et `<` les compare dans l'ordre, `Note` d'abord. Les records C# ont l'égalité par valeur mais pas d'ordre ; F# génère les deux, plus un code de hachage.

Chaque champ doit être fourni, et aucun champ ne peut être modifié :

```fsharp
type GuitarString = { Note: string; Octave: int; Gauge: float }

let low = { Note = "E"; Octave = 2 }
```

```text
l03_record_missing_field.fsx(3,11): error FS0764: No assignment given for field 'Gauge' of type 'FSI_0001.GuitarString'
```

```fsharp
let low = { Note = "E"; Octave = 2; Gauge = 0.046 }
low.Note <- "D"
```

```text
l03_record_immutable.fsx(4,1): error FS0005: This field is not mutable
```

`FSI_0001` est le module dans lequel F# Interactive enveloppe le script. Un record C# à paramètres positionnels se comporte de la même façon, mais un record C# peut aussi avoir des propriétés `set`, et un `new` C# peut laisser une propriété à sa valeur par défaut. Un record F# a toujours toutes ses valeurs, dès le départ.

## Unions discriminées

Un accord de do majeur à la guitare se joue `x32010` : la corde de mi grave est étouffée, puis case 3, case 2, une corde à vide, case 1, une corde à vide. Chaque corde est dans une situation parmi plusieurs, et chaque situation a des données différentes. En C#, vous écririez une petite hiérarchie de classes :

```csharp
abstract record Fingering;
sealed record Open : Fingering;
sealed record Fretted(int Fret) : Fingering;
sealed record Barre(int Fret, int Strings) : Fingering;
sealed record Muted : Fingering;
```

En F#, c'est un seul type, une [union discriminée](https://learn.microsoft.com/dotnet/fsharp/language-reference/discriminated-unions) :

```fsharp
// Une union discriminée : une valeur est exactement l'un des cas
type Accidental =
    | Natural
    | Sharp
    | Flat

// Chaque cas peut porter ses propres données
type Fingering =
    | Open
    | Fretted of fret: int
    | Barre of fret: int * strings: int
    | Muted

// Do majeur, de la corde de mi grave à la corde de mi aigu : x32010
let cMajor = [ Muted; Fretted 3; Fretted 2; Open; Fretted 1; Open ]
printfn "%A" cMajor

let fMajor = Barre(fret = 1, strings = 6) // champs nommés
printfn "%A" fMajor
printfn "%b %b" (Fretted 3 = Fretted 3) (Sharp = Flat)
```

```text
[Muted; Fretted 3; Fretted 2; Open; Fretted 1; Open]
Barre (1, 6)
true false
```

- `Accidental` a des cas sans données : c'est une énumération, mais fermée. Un `enum` C# accepte `(Accidental)42` ; une valeur d'union ne peut être que l'un de ses cas.
- `Fretted of fret: int` porte un `int`, nommé `fret`. `Barre of fret: int * strings: int` porte deux valeurs. Les noms sont facultatifs, et utiles : ils apparaissent dans les info-bulles et permettent `Barre(fret = 1, strings = 6)`.
- Chaque cas est aussi une fonction constructeur : `Fretted 3` construit une valeur de type `Fingering`, et `Fretted` seul est une fonction `int -> Fingering`.
- L'égalité et la comparaison sont générées, comme pour les records.

Le véritable avantage apparaît avec le filtrage par motif, dans la [leçon 4](../04-pattern-matching/) : le compilateur connaît la liste complète des cas et avertit quand un `match` en oublie un. Un `switch` C# sur la hiérarchie de records ne peut pas savoir que personne n'a ajouté une cinquième sous-classe dans un autre fichier.

### Du vrai code : l'AST des accords de GA

Guitar Alchemist analyse les symboles d'accords comme `F#m7b5/C` en un arbre syntaxique. Les types de cet arbre sont dans [`ChordAst.fs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Types/ChordAst.fs#L3-L29), et ce sont des records et des unions :

```fsharp
namespace GA.Business.DSL.Types

type QualityType =
    | Major
    | Minor
    | Diminished
    | Augmented
    | Suspended
    | Dominant // Derived during semantic analysis usually

type AccidentalType =
    | Natural
    | Sharp
    | Flat
    | DoubleSharp
    | DoubleFlat

type ChordComponent =
    | Extension of string
    | Alteration of AccidentalType * string
    | Omission of string
    | Alt

type ChordAst =
    { Root: string
      RootAccidental: AccidentalType
      Quality: QualityType option
      Components: ChordComponent list
      Bass: (string * AccidentalType) option }
```

Vingt-sept lignes décrivent tous les symboles d'accords que GA comprend. Les types s'imbriquent : un record `ChordAst` contient une liste d'unions `ChordComponent`, dont l'un des cas contient un `AccidentalType` et une chaîne. `Quality: QualityType option` dit qu'un accord peut n'avoir aucune qualité écrite (`C7`), et `Bass: (string * AccidentalType) option` qu'il peut n'avoir aucune basse, et qu'une basse est un tuple d'une lettre et d'une altération. La version C# ferait une douzaine de fichiers.

Le cours charge ce fichier et le moteur de rendu de GA, et construit `F#m7b5/C` à la main ([`examples/l03_ga_chords.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l03_ga_chords.fsx)) :

```fsharp
// L'AST d'accords et le moteur de rendu de Guitar Alchemist, chargés depuis les copies de external/ga
#load "../external/ga/ChordAst.fs" "../external/ga/ChordRenderer.fs"

open GA.Business.DSL.Types
open GA.Business.DSL.Generators

// F#m7b5/C comme valeur du record ChordAst de GA
let halfDiminished =
    { Root = "F"
      RootAccidental = Sharp
      Quality = Some Minor
      Components = [ Extension "7"; Alteration(Flat, "5") ]
      Bass = Some("C", Natural) }

printfn "%s" (ChordRenderer.render halfDiminished)
printfn "%A" halfDiminished

let c = { Root = "C"; RootAccidental = Natural; Quality = None; Components = []; Bass = None }
printfn "%s" (ChordRenderer.render c)
printfn "%s" (ChordRenderer.render { c with Quality = Some Major; Components = [ Extension "9" ] })
```

```text
F#m7b5/C
{ Root = "F"
  RootAccidental = Sharp
  Quality = Some Minor
  Components = [Extension "7"; Alteration (Flat, "5")]
  Bass = Some ("C", Natural) }
C
Cmaj9
```

`%A` affiche la valeur en syntaxe F#, que vous pouvez recoller dans un script. `ChordRenderer.render` retransforme l'arbre en texte ; la leçon 4 lit son code.

## Option au lieu de null

`Some Minor` et `None` ci-dessus sont les deux cas d'[`Option`](https://learn.microsoft.com/dotnet/fsharp/language-reference/options), une union définie dans FSharp.Core :

```fsharp
type Option<'T> =
    | None
    | Some of 'T
```

`int option` est une autre façon d'écrire `Option<int>`. Un `int option` est soit `Some 2`, soit `None`, et le type le dit : le code qui le reçoit doit traiter les deux. Une `string` F#, en revanche, n'est pas censée être null.

```fsharp
// Option : Some valeur, ou None, au lieu de null
let capo: int option = Some 2
let noCapo: int option = None

let describe capo =
    capo
    |> Option.map (fun fret -> $"capo on fret {fret}")
    |> Option.defaultValue "no capo"

printfn "%s, %s" (describe capo) (describe noCapo)
printfn "%A %A" capo noCapo

// Une méthode .NET peut renvoyer null : Option.ofObj le transforme en None
let variable = System.Environment.GetEnvironmentVariable "FSHARP_COURSE_VARIABLE_THAT_IS_NOT_SET"
printfn "%A" (Option.ofObj variable)
```

```text
capo on fret 2, no capo
Some 2 None
None
```

- [`Option.map`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-optionmodule.html#map) applique une fonction à la valeur contenue dans `Some`, et laisse `None` tel quel : le `capo?.ToString()` de C#, mais pour n'importe quelle fonction. `Option.defaultValue` est le `??` de C#. Le moteur de rendu de GA utilise ces deux mêmes fonctions pour la qualité d'un accord : `ast.Quality |> Option.map renderQuality |> Option.defaultValue ""`.
- `Option.ofObj` est la passerelle depuis les API .NET, qui renvoient `null` pour « rien ».

`None` n'est pas un `null` déguisé que l'on pourrait oublier de vérifier : le type `int option` n'est pas `int`, donc on ne peut pas écrire `capo + 1` sans dire ce qui se passe quand il n'y a pas de capodastre. Et `null` n'est pas une option :

```fsharp
let capo: int option = null
```

```text
l03_option_null.fsx(1,24): error FS0043: The type 'int option' does not have 'null' as a proper value
```

Comparez avec l'`Optional<T>` de Java, une classe dont la variable peut elle-même être `null`, et avec les types référence nullables de C#, des avertissements ajoutés par-dessus des types qui acceptent toujours `null`. F# 9 a ajouté les types référence nullables pour l'interopérabilité avec les API .NET ; la leçon 9 les couvre.

## Unions à un seul cas

Une union à un seul cas enveloppe une valeur dans un type à part. TARS donne ainsi des types distincts à ses identifiants, dans [`Primitives.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Primitives.fs#L5-L9) :

```fsharp
/// Unique identifier for an agent
type AgentId = AgentId of Guid

/// Unique identifier for a correlation/conversation
type CorrelationId = CorrelationId of Guid
```

Les deux contiennent un `Guid`, mais ils ne sont pas interchangeables :

```fsharp
open System

type AgentId = AgentId of Guid
type CorrelationId = CorrelationId of Guid

let describeAgent (AgentId id) = $"agent {id}"

let conversation = CorrelationId(Guid.NewGuid())
printfn "%s" (describeAgent conversation)
```

```text
l03_single_case_mixup.fsx(9,29): error FS0001: This expression was expected to have type
    'AgentId'
but here has type
    'CorrelationId'
```

Avec de simples paramètres `Guid`, le compilateur aurait accepté l'appel. `let describeAgent (AgentId id) = …` déballe la valeur dans le paramètre lui-même, un motif qu'explique la leçon 4 ([`examples/l03_single_case.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l03_single_case.fsx) exécute l'appel correct). En C#, le plus proche est `readonly record struct AgentId(Guid Value)` : plus de cérémonie, la même sécurité.

## Quand des noms de cas entrent en collision

Les cas d'union sont des noms dans la portée, comme les fonctions. Si deux unions ont un cas du même nom, **celle définie en dernier l'emporte**. `Ok` et `Error` sont les cas du type `Result` de FSharp.Core (leçon 7), toujours dans la portée : une union qui a son propre cas `Error` masque donc `Result.Error` pour toutes les lignes en dessous. Voici la situation réduite à quelques lignes :

```fsharp
// Réduit depuis TARS (v2/src/Tars.Core/Domain.fs) : une union avec un cas nommé Error
type PartialFailure =
    | Warning of message: string
    | Error of message: string

let checkFret fret : Result<int, string> =
    if fret >= 0 then Ok fret else Error "negative fret"
```

```text
l03_case_shadowing.fsx(7,36): error FS0001: All branches of an 'if' expression must return values implicitly convertible to the type of the first branch, which here is 'Result<int,string>'. This branch returns a value of type 'PartialFailure'.
```

`Error "negative fret"` a construit un `PartialFailure`, pas un `Result`. TARS a exactement ce cas. [`Domain.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Domain.fs#L62-L78), le huitième fichier de `Tars.Core`, déclare :

```fsharp
/// Represents a non-fatal issue encountered during execution
type PartialFailure =
    | Warning of message: string
    | Error of message: string
    | Degradation of feature: string * reason: string
    | Timeout of operation: string * duration: TimeSpan
    | SubAgentTimeout of agentId: AgentId * taskId: Guid
    | ToolError of tool: string * error: string
    | LowConfidence of score: float * details: string
    | ProtocolViolation of message: string
    | ConstraintViolation of violation: string

/// Represents the outcome of an agentic operation, supporting partial success
type ExecutionOutcome<'T> =
    | Success of value: 'T
    | PartialSuccess of value: 'T * warnings: PartialFailure list
    | Failure of errors: PartialFailure list
```

L'effet suit l'ordre des fichiers de la leçon 1. [`Budget.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Budget.fs#L206), compilé avant `Domain.fs`, écrit un simple `Error e` et obtient `Result.Error`. Les fichiers compilés après doivent qualifier : [`ConstitutionLoader.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/ConstitutionLoader.fs#L87) écrit `Result.Error`, et [`ArcTypes.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/ArcTypes.fs#L103-L105) va jusqu'à `FSharp.Core.Result.Error`. À ce commit, `v2/src` contient 342 occurrences de `Result.Error`. `Failure` entre en collision de la même façon : l'union `Performative`, quelques lignes plus haut, a elle aussi un cas `Failure`, et l'[`AgentWorkflow.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/AgentWorkflow.fs#L89-L93) de TARS écrit en entier `ExecutionOutcome.Success`, `ExecutionOutcome.PartialSuccess` et `ExecutionOutcome.Failure`.

La réponse de F# est l'attribut [`RequireQualifiedAccess`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-requirequalifiedaccessattribute.html) : les cas de l'union doivent alors s'écrire avec son nom, et ne masquent donc rien.

```fsharp
// RequireQualifiedAccess : les cas doivent s'écrire PartialFailure.Warning et PartialFailure.Error
[<RequireQualifiedAccess>]
type PartialFailure =
    | Warning of message: string
    | Error of message: string

let checkFret fret : Result<int, string> =
    if fret >= 0 then Ok fret else Error "negative fret" // Error est de nouveau le cas de Result

printfn "%A" (checkFret 3)
printfn "%A" (checkFret -1)
printfn "%A" (PartialFailure.Warning "low confidence")
```

```text
Ok 3
Error "negative fret"
Warning "low confidence"
```

TARS l'utilise ailleurs : [`AgentDefinition.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/AgentDefinition.fs#L9-L26) marque son union `AgentSkill`, dont les cas `Reasoning`, `Planning` et `Coding` entreraient sinon en collision avec ceux d'`AgentDomain` et de `CapabilityKind`. L'ajouter à une union existante comme `PartialFailure` casse le code qui l'utilise, qui doit alors qualifier chaque cas : c'est une décision à prendre à la création du type.

## À retenir

- Un tuple (`string * int`) regroupe des valeurs sans nom ; les tuples F# sont des `System.Tuple`, et `struct (…)` crée les tuples valeur de C#.
- Un record a des champs nommés et immuables, l'égalité et la comparaison structurelles, et `{ r with … }` pour le copier avec des modifications.
- Une union discriminée liste toutes les formes que peut prendre une valeur, chaque cas avec ses données : elle remplace les énumérations et les petites hiérarchies de classes.
- `Option` (`Some` / `None`) remplace `null` ; `Option.map` et `Option.defaultValue` travaillent avec, `Option.ofObj` convertit depuis .NET.
- Les unions à un seul cas donnent des types distincts aux primitives ; `[<RequireQualifiedAccess>]` empêche les cas d'union de masquer d'autres noms, comme `Result.Error`.

## Exercices

1. Déclarez un record `Tuning` avec un nom, une liste de notes (`string list`) et une case de capodastre facultative. Créez l'accordage standard, puis *Drop D* (la corde grave descendue en ré2) et l'accordage standard avec un capodastre en case 2, en le copiant. Affichez Drop D, et vérifiez avec `=` que la version avec capodastre est égale à une seconde copie faite de la même façon.

<details>
<summary>Solution</summary>

[`exercises/l03_ex_record.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l03_ex_record.fsx) :

```fsharp
type Tuning = { Name: string; Notes: string list; Capo: int option }

let standard = { Name = "Standard"; Notes = [ "E2"; "A2"; "D3"; "G3"; "B3"; "E4" ]; Capo = None }
let dropD = { standard with Name = "Drop D"; Notes = [ "D2"; "A2"; "D3"; "G3"; "B3"; "E4" ] }
let capoOn2 = { standard with Capo = Some 2 }

printfn "%A" dropD
printfn "%b" (capoOn2 = { standard with Capo = Some 2 })
printfn "%b" (standard.Notes = capoOn2.Notes)
```

```text
{ Name = "Drop D"
  Notes = ["D2"; "A2"; "D3"; "G3"; "B3"; "E4"]
  Capo = None }
true
true
```

L'égalité descend jusqu'au bout : les listes sont comparées élément par élément, et `Some 2 = Some 2`. `capoOn2` partage sa liste `Notes` avec `standard`, ce qui ne pose aucun problème puisque ni l'un ni l'autre ne peut la modifier.

</details>

2. Un plan de guitare est une suite de techniques : une note piquée, un hammer-on d'une case à une autre, un glissé d'une case à une autre, ou un bend d'un nombre de demi-tons (1.0 pour un ton). Modélisez-le avec une union, écrivez un plan de quatre techniques et affichez-le. Un glissé de 7 à 9 est-il égal à un glissé de 9 à 7 ?

<details>
<summary>Solution</summary>

[`exercises/l03_ex_union.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l03_ex_union.fsx) :

```fsharp
type Technique =
    | Picked
    | HammerOn of fromFret: int * toFret: int
    | Slide of fromFret: int * toFret: int
    | Bend of semitones: float

let lick = [ Picked; HammerOn(5, 7); Slide(fromFret = 7, toFret = 9); Bend 1.0 ]
printfn "%A" lick
printfn "%b" (Slide(7, 9) = Slide(9, 7))
```

```text
[Picked; HammerOn (5, 7); Slide (7, 9); Bend 1.0]
false
```

Les valeurs sont comparées dans l'ordre : les deux glissés diffèrent donc, comme sur la guitare. `HammerOn(5, 7)` et `Slide(5, 7)` diffèrent aussi, bien qu'ils portent les mêmes données : le cas fait partie de la valeur.

</details>

3. Avec le `ChordAst` et le `ChordRenderer` de GA (chargez-les comme dans [Du vrai code : l'AST des accords de GA](#du-vrai-code--last-des-accords-de-ga)), construisez les accords `Bbmaj7/D` et `Eaug`, et rendez-les. Regardez comment GA écrit `Cmaj9` plus haut : où va `maj7` ?

<details>
<summary>Solution</summary>

[`exercises/l03_ex_ga_chord.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l03_ex_ga_chord.fsx) :

```fsharp
#load "../external/ga/ChordAst.fs" "../external/ga/ChordRenderer.fs"

open GA.Business.DSL.Types
open GA.Business.DSL.Generators

let bFlatMajor7OverD =
    { Root = "B"
      RootAccidental = Flat
      Quality = None
      Components = [ Extension "maj7" ]
      Bass = Some("D", Natural) }

let eAugmented = { bFlatMajor7OverD with Root = "E"; RootAccidental = Natural; Quality = Some Augmented; Components = []; Bass = None }

printfn "%s" (ChordRenderer.render bFlatMajor7OverD)
printfn "%s" (ChordRenderer.render eAugmented)

// Le même accord écrit avec une qualité : même texte, arbre différent
let withQuality = { bFlatMajor7OverD with Quality = Some Major; Components = [ Extension "7" ] }
printfn "%s %b" (ChordRenderer.render withQuality) (withQuality = bFlatMajor7OverD)
```

```text
Bbmaj7/D
Eaug
Bbmaj7/D false
```

Le bémol est l'altération de la fondamentale, pas une partie de sa lettre. `maj7` peut s'écrire de deux façons : sans qualité et `Extension "maj7"`, ou `Quality = Some Major` avec `Extension "7"`. Les deux rendent `Bbmaj7/D`, mais les deux arbres ne sont pas égaux. Le parseur de GA produit la première forme : les commentaires de [`ChordParser.fs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Parsers/ChordParser.fs#L24-L32) gardent `maj7` comme un seul jeton. Deux arbres pour un accord signifient que `=` peut déclarer différent un même accord ; la leçon 12 porte sur la conception de types où cela ne peut pas arriver.

</details>

## Sources

- [Tuples](https://learn.microsoft.com/dotnet/fsharp/language-reference/tuples), [records](https://learn.microsoft.com/dotnet/fsharp/language-reference/records), [expressions de copie et de mise à jour de records](https://learn.microsoft.com/dotnet/fsharp/language-reference/copy-and-update-record-expressions)
- [Unions discriminées](https://learn.microsoft.com/dotnet/fsharp/language-reference/discriminated-unions), [options](https://learn.microsoft.com/dotnet/fsharp/language-reference/options), [module `Option`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-optionmodule.html)
- [Différences entre records et classes](https://learn.microsoft.com/dotnet/fsharp/language-reference/records#differences-between-records-and-classes) (égalité structurelle) et [`RequireQualifiedAccessAttribute`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-requirequalifiedaccessattribute.html)
- [Conventions de codage F# : types](https://learn.microsoft.com/dotnet/fsharp/style-guide/conventions)
- C# : [records](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record), [types tuple](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/value-tuples) ; Java : [records](https://docs.oracle.com/en/java/javase/25/language/records.html), [classes scellées](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html)
