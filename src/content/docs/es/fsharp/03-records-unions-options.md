---
title: 3. Tuplas, records, uniones y opciones
description: Modelar datos con tuplas, records inmutables con igualdad estructural, uniones discriminadas en lugar de jerarquías de clases y Option en lugar de null — con el AST de acordes de GA y los casos de unión que TARS tuvo que calificar 342 veces.
sidebar:
  order: 3
---

Código: los scripts [`examples/l03_*.fsx`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples) y los fragmentos rechazados [`compile_fail/l03_*.fsx`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/compile_fail).

En C# y Java, los datos suelen vivir en clases: campos, un constructor, `Equals` y `GetHashCode` si te acuerdas, y una jerarquía de clases cuando un valor puede tomar varias formas. Los records (C# 9, Java 16) y las jerarquías selladas (C# con clases base `abstract`, Java 17 con `sealed interface`) lo han acortado. F# tiene formas cortas para todo ello desde el principio, y son la manera normal de modelar datos:

| Quieres | C# | Java | F# |
|---|---|---|---|
| unos cuantos valores juntos, sin nombre | `(string, int)` | un record o `Map.Entry` | tupla `string * int` |
| campos con nombre, inmutables, comparados por valor | `record` | `record` | record |
| una forma entre varias, cada una con sus datos | clase base abstracta y subclases | `sealed interface` y records | unión discriminada |
| un valor que puede faltar | `null`, `Nullable<T>` | `null`, `Optional<T>` | `Option<'T>` |

## Tuplas

```fsharp
// Una tupla agrupa valores sin declarar un tipo: aquí string * int
let lowString = ("E", 2)
printfn "%A" lowString
printfn "%s" (fst lowString)

// Deconstrucción, como var (note, octave) = ... en C#
let (note, octave) = lowString
printfn "%s%d" note octave

// Una función devuelve varios valores en una tupla
let octavesAndSemitones interval = (interval / 12, interval % 12)
let octaves, semitones = octavesAndSemitones 29 // los paréntesis son opcionales
printfn "29 semitones = %d octaves and %d semitones" octaves semitones

// Las tuplas F# son objetos System.Tuple; las tuplas struct son System.ValueTuple, las tuplas de C#
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

- El tipo de `("E", 2)` se escribe `string * int`: el `*` se lee «y», como en un producto de tipos.
- `fst` y `snd` devuelven el primer y el segundo elemento de un par.
- La última línea muestra una diferencia con C#: una tupla F# es un [`System.Tuple`](https://learn.microsoft.com/dotnet/api/system.tuple-2), un objeto en el montón, mientras que el `(string, int)` de C# es un [`System.ValueTuple`](https://learn.microsoft.com/dotnet/api/system.valuetuple-2), una struct. `struct ("A", 4)` crea una tupla de valor, la que hay que usar al llamar a código C# que la espera. La [página de tuplas](https://learn.microsoft.com/dotnet/fsharp/language-reference/tuples) tiene los detalles.

Una tupla sirve para dos o tres valores que viajan juntos un momento. En cuanto los valores tienen nombre en tu cabeza, dales nombre en el código: un record.

## Records

```fsharp
type GuitarString = { Note: string; Octave: int; Gauge: float }

let low = { Note = "E"; Octave = 2; Gauge = 0.046 } // las etiquetas le indican el tipo a F#
let high = { low with Octave = 4; Gauge = 0.010 } // copia y actualización, como with en C#

printfn "%s%d, gauge %.3f" low.Note low.Octave low.Gauge
printfn "%A" high

// Igualdad y comparación estructurales, generadas por el compilador
printfn "%b" (high = { Note = "E"; Octave = 4; Gauge = 0.010 })
printfn "%b" (low = high)
printfn "%b" (low < high) // campos comparados en orden: Note y luego Octave
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

- `type GuitarString = { … }` declara un [record](https://learn.microsoft.com/dotnet/fsharp/language-reference/records). El equivalente en C# es `record GuitarString(string Note, int Octave, double Gauge);`.
- El valor `{ Note = "E"; Octave = 2; Gauge = 0.046 }` no contiene ningún nombre de tipo: F# encuentra el tipo de record a partir de sus etiquetas.
- `{ low with Octave = 4; Gauge = 0.010 }` es una copia con dos campos cambiados, el `low with { Octave = 4, Gauge = 0.010 }` de C#.
- `=` compara los campos, y `<` los compara en orden, primero `Note`. Los records de C# tienen igualdad por valor pero no orden; F# genera ambos, además de un código hash.

Hay que dar todos los campos, y ningún campo se puede cambiar:

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

`FSI_0001` es el módulo en el que F# Interactive envuelve el script. Un record de C# con parámetros posicionales se comporta igual, pero un record de C# también puede tener propiedades `set`, y un `new` de C# puede dejar una propiedad con su valor por defecto. Un record F# siempre tiene todos sus valores, desde el principio.

## Uniones discriminadas

Un acorde de do mayor en la guitarra se toca `x32010`: la cuerda de mi grave está apagada, luego traste 3, traste 2, una cuerda al aire, traste 1, una cuerda al aire. Cada cuerda está en una situación entre varias, y cada situación tiene datos distintos. En C#, escribirías una pequeña jerarquía de clases:

```csharp
abstract record Fingering;
sealed record Open : Fingering;
sealed record Fretted(int Fret) : Fingering;
sealed record Barre(int Fret, int Strings) : Fingering;
sealed record Muted : Fingering;
```

En F#, es un solo tipo, una [unión discriminada](https://learn.microsoft.com/dotnet/fsharp/language-reference/discriminated-unions):

```fsharp
// Una unión discriminada: un valor es exactamente uno de los casos
type Accidental =
    | Natural
    | Sharp
    | Flat

// Cada caso puede llevar sus propios datos
type Fingering =
    | Open
    | Fretted of fret: int
    | Barre of fret: int * strings: int
    | Muted

// Do mayor, de la cuerda de mi grave a la de mi agudo: x32010
let cMajor = [ Muted; Fretted 3; Fretted 2; Open; Fretted 1; Open ]
printfn "%A" cMajor

let fMajor = Barre(fret = 1, strings = 6) // campos con nombre
printfn "%A" fMajor
printfn "%b %b" (Fretted 3 = Fretted 3) (Sharp = Flat)
```

```text
[Muted; Fretted 3; Fretted 2; Open; Fretted 1; Open]
Barre (1, 6)
true false
```

- `Accidental` tiene casos sin datos: es una enumeración, pero cerrada. Un `enum` de C# acepta `(Accidental)42`; un valor de unión solo puede ser uno de sus casos.
- `Fretted of fret: int` lleva un `int`, llamado `fret`. `Barre of fret: int * strings: int` lleva dos valores. Los nombres son opcionales, y útiles: aparecen en la información sobre herramientas y permiten `Barre(fret = 1, strings = 6)`.
- Cada caso es también una función constructora: `Fretted 3` construye un valor de tipo `Fingering`, y `Fretted` solo es una función `int -> Fingering`.
- La igualdad y la comparación se generan, como en los records.

La verdadera ventaja aparece con la coincidencia de patrones, en la [lección 4](../04-pattern-matching/): el compilador conoce la lista completa de casos y avisa cuando a un `match` se le olvida uno. Un `switch` de C# sobre la jerarquía de records no puede saber que nadie añadió una quinta subclase en otro archivo.

### Código real: el AST de acordes de GA

Guitar Alchemist analiza símbolos de acordes como `F#m7b5/C` y los convierte en un árbol sintáctico. Los tipos de ese árbol están en [`ChordAst.fs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Types/ChordAst.fs#L3-L29), y son records y uniones:

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

Veintisiete líneas describen todos los símbolos de acordes que entiende GA. Los tipos se anidan: un record `ChordAst` contiene una lista de uniones `ChordComponent`, uno de cuyos casos contiene un `AccidentalType` y una cadena. `Quality: QualityType option` dice que un acorde puede no tener calidad escrita (`C7`), y `Bass: (string * AccidentalType) option` que puede no tener bajo, y que un bajo es una tupla de una letra y una alteración. La versión en C# serían una docena de archivos.

El curso carga este archivo y el renderizador de GA, y construye `F#m7b5/C` a mano ([`examples/l03_ga_chords.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l03_ga_chords.fsx)):

```fsharp
// El AST de acordes y el renderizador de Guitar Alchemist, cargados desde las copias de external/ga
#load "../external/ga/ChordAst.fs" "../external/ga/ChordRenderer.fs"

open GA.Business.DSL.Types
open GA.Business.DSL.Generators

// F#m7b5/C como valor del record ChordAst de GA
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

`%A` imprime el valor con sintaxis F#, que puedes volver a pegar en un script. `ChordRenderer.render` convierte el árbol de nuevo en texto; la lección 4 lee su código.

## Option en lugar de null

`Some Minor` y `None` son los dos casos de [`Option`](https://learn.microsoft.com/dotnet/fsharp/language-reference/options), una unión definida en FSharp.Core:

```fsharp
type Option<'T> =
    | None
    | Some of 'T
```

`int option` es otra forma de escribir `Option<int>`. Un `int option` es `Some 2` o `None`, y el tipo lo dice: el código que lo recibe debe tratar ambos. Un `string` de F#, en cambio, no debería ser null.

```fsharp
// Option: Some valor, o None, en lugar de null
let capo: int option = Some 2
let noCapo: int option = None

let describe capo =
    capo
    |> Option.map (fun fret -> $"capo on fret {fret}")
    |> Option.defaultValue "no capo"

printfn "%s, %s" (describe capo) (describe noCapo)
printfn "%A %A" capo noCapo

// Un método .NET puede devolver null: Option.ofObj lo convierte en None
let variable = System.Environment.GetEnvironmentVariable "FSHARP_COURSE_VARIABLE_THAT_IS_NOT_SET"
printfn "%A" (Option.ofObj variable)
```

```text
capo on fret 2, no capo
Some 2 None
None
```

- [`Option.map`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-optionmodule.html#map) aplica una función al valor que hay dentro de `Some` y deja `None` como está: el `capo?.ToString()` de C#, pero para cualquier función. `Option.defaultValue` es el `??` de C#. El renderizador de GA usa esas mismas dos funciones para la calidad de un acorde: `ast.Quality |> Option.map renderQuality |> Option.defaultValue ""`.
- `Option.ofObj` es el puente desde las API .NET, que devuelven `null` para «nada».

`None` no es un `null` disfrazado que se pueda olvidar comprobar: el tipo `int option` no es `int`, así que no puedes sumar `capo + 1` sin decir qué pasa cuando no hay cejilla. Y `null` no es una opción:

```fsharp
let capo: int option = null
```

```text
l03_option_null.fsx(1,24): error FS0043: The type 'int option' does not have 'null' as a proper value
```

Compara con el `Optional<T>` de Java, una clase cuya variable puede ser a su vez `null`, y con los tipos de referencia anulables de C#, que son advertencias añadidas sobre tipos que siguen aceptando `null`. F# 9 añadió tipos de referencia anulables para la interoperabilidad con las API .NET; la lección 9 los trata.

## Uniones de un solo caso

Una unión con un solo caso envuelve un valor en un tipo propio. TARS da así tipos distintos a sus identificadores, en [`Primitives.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Primitives.fs#L5-L9):

```fsharp
/// Unique identifier for an agent
type AgentId = AgentId of Guid

/// Unique identifier for a correlation/conversation
type CorrelationId = CorrelationId of Guid
```

Los dos contienen un `Guid`, pero no son intercambiables:

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

Con parámetros `Guid` simples, el compilador habría aceptado la llamada. `let describeAgent (AgentId id) = …` desenvuelve el valor en el propio parámetro, un patrón que explica la lección 4 ([`examples/l03_single_case.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l03_single_case.fsx) ejecuta la llamada correcta). En C#, lo más parecido es `readonly record struct AgentId(Guid Value)`: más ceremonia, la misma seguridad.

## Cuando los nombres de casos chocan

Los casos de unión son nombres en el ámbito, como las funciones. Si dos uniones tienen un caso con el mismo nombre, **gana la definida en último lugar**. `Ok` y `Error` son los casos del tipo `Result` de FSharp.Core (lección 7), siempre en el ámbito, así que una unión con su propio caso `Error` oculta `Result.Error` en todas las líneas que vienen después. Esta es la situación reducida a unas pocas líneas:

```fsharp
// Reducido a partir de TARS (v2/src/Tars.Core/Domain.fs): una unión con un caso llamado Error
type PartialFailure =
    | Warning of message: string
    | Error of message: string

let checkFret fret : Result<int, string> =
    if fret >= 0 then Ok fret else Error "negative fret"
```

```text
l03_case_shadowing.fsx(7,36): error FS0001: All branches of an 'if' expression must return values implicitly convertible to the type of the first branch, which here is 'Result<int,string>'. This branch returns a value of type 'PartialFailure'.
```

`Error "negative fret"` construyó un `PartialFailure`, no un `Result`. TARS tiene exactamente esto. [`Domain.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Domain.fs#L62-L78), el octavo archivo de `Tars.Core`, declara:

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

El efecto sigue el orden de archivos de la lección 1. [`Budget.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Budget.fs#L206), compilado antes que `Domain.fs`, escribe un simple `Error e` y obtiene `Result.Error`. Los archivos compilados después deben calificar: [`ConstitutionLoader.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/ConstitutionLoader.fs#L87) escribe `Result.Error`, y [`ArcTypes.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/ArcTypes.fs#L103-L105) llega a `FSharp.Core.Result.Error`. En este commit, `v2/src` contiene 342 apariciones de `Result.Error`. `Failure` choca del mismo modo: la unión `Performative`, unas líneas más arriba, también tiene un caso `Failure`, y el [`AgentWorkflow.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/AgentWorkflow.fs#L89-L93) de TARS escribe completos `ExecutionOutcome.Success`, `ExecutionOutcome.PartialSuccess` y `ExecutionOutcome.Failure`.

La respuesta de F# es el atributo [`RequireQualifiedAccess`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-requirequalifiedaccessattribute.html): los casos de la unión deben escribirse entonces con su nombre, así que no ocultan nada.

```fsharp
// RequireQualifiedAccess: los casos deben escribirse PartialFailure.Warning y PartialFailure.Error
[<RequireQualifiedAccess>]
type PartialFailure =
    | Warning of message: string
    | Error of message: string

let checkFret fret : Result<int, string> =
    if fret >= 0 then Ok fret else Error "negative fret" // Error vuelve a ser el caso de Result

printfn "%A" (checkFret 3)
printfn "%A" (checkFret -1)
printfn "%A" (PartialFailure.Warning "low confidence")
```

```text
Ok 3
Error "negative fret"
Warning "low confidence"
```

TARS lo usa en otros sitios: [`AgentDefinition.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/AgentDefinition.fs#L9-L26) marca su unión `AgentSkill`, cuyos casos `Reasoning`, `Planning` y `Coding` chocarían si no con los de `AgentDomain` y `CapabilityKind`. Añadirlo a una unión existente como `PartialFailure` rompe el código que la usa, que debe entonces calificar cada caso: es una decisión que conviene tomar al crear el tipo.

## Puntos clave

- Una tupla (`string * int`) agrupa valores sin nombre; las tuplas F# son `System.Tuple`, y `struct (…)` crea las tuplas de valor de C#.
- Un record tiene campos con nombre e inmutables, igualdad y comparación estructurales, y `{ r with … }` para copiarlo con cambios.
- Una unión discriminada enumera todas las formas que puede tomar un valor, cada caso con sus datos: sustituye a las enumeraciones y a las pequeñas jerarquías de clases.
- `Option` (`Some` / `None`) sustituye a `null`; `Option.map` y `Option.defaultValue` trabajan con ella, y `Option.ofObj` convierte desde .NET.
- Las uniones de un solo caso dan tipos distintos a los primitivos; `[<RequireQualifiedAccess>]` evita que los casos de unión oculten otros nombres, como `Result.Error`.

## Ejercicios

1. Declara un record `Tuning` con un nombre, una lista de notas (`string list`) y un traste de cejilla opcional. Crea la afinación estándar y luego, copiándola, *Drop D* (la cuerda grave bajada a re2) y la afinación estándar con una cejilla en el traste 2. Imprime Drop D y comprueba con `=` que la versión con cejilla es igual a una segunda copia hecha de la misma forma.

<details>
<summary>Solución</summary>

[`exercises/l03_ex_record.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l03_ex_record.fsx):

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

La igualdad llega hasta el fondo: las listas se comparan elemento a elemento, y `Some 2 = Some 2`. `capoOn2` comparte su lista `Notes` con `standard`, lo que no supone ningún riesgo porque ninguno de los dos puede cambiarla.

</details>

2. Un lick de guitarra es una secuencia de técnicas: una nota pulsada, un hammer-on de un traste a otro, un slide de un traste a otro o un bend de un número de semitonos (1.0 para un tono). Modélalo con una unión, escribe un lick de cuatro técnicas e imprímelo. ¿Un slide de 7 a 9 es igual a un slide de 9 a 7?

<details>
<summary>Solución</summary>

[`exercises/l03_ex_union.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l03_ex_union.fsx):

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

Los valores se comparan en orden, así que los dos slides son distintos, como en la guitarra. `HammerOn(5, 7)` y `Slide(5, 7)` también son distintos, aunque llevan los mismos datos: el caso forma parte del valor.

</details>

3. Con el `ChordAst` y el `ChordRenderer` de GA (cárgalos como en [Código real: el AST de acordes de GA](#código-real-el-ast-de-acordes-de-ga)), construye los acordes `Bbmaj7/D` y `Eaug`, y renderízalos. Fíjate en cómo escribe GA `Cmaj9` más arriba: ¿dónde va `maj7`?

<details>
<summary>Solución</summary>

[`exercises/l03_ex_ga_chord.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l03_ex_ga_chord.fsx):

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

// El mismo acorde escrito con una calidad: mismo texto, árbol distinto
let withQuality = { bFlatMajor7OverD with Quality = Some Major; Components = [ Extension "7" ] }
printfn "%s %b" (ChordRenderer.render withQuality) (withQuality = bFlatMajor7OverD)
```

```text
Bbmaj7/D
Eaug
Bbmaj7/D false
```

El bemol es la alteración de la fundamental, no parte de su letra. `maj7` se puede escribir de dos formas: sin calidad y `Extension "maj7"`, o `Quality = Some Major` con `Extension "7"`. Ambas se renderizan como `Bbmaj7/D`, pero los dos árboles no son iguales. El parser de GA produce la primera forma: los comentarios de [`ChordParser.fs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Parsers/ChordParser.fs#L24-L32) mantienen `maj7` como un solo token. Dos árboles para un acorde significan que `=` puede considerar distinto un mismo acorde; la lección 12 trata del diseño de tipos en los que eso no puede ocurrir.

</details>

## Fuentes

- [Tuplas](https://learn.microsoft.com/dotnet/fsharp/language-reference/tuples), [records](https://learn.microsoft.com/dotnet/fsharp/language-reference/records), [expresiones de copia y actualización de records](https://learn.microsoft.com/dotnet/fsharp/language-reference/copy-and-update-record-expressions)
- [Uniones discriminadas](https://learn.microsoft.com/dotnet/fsharp/language-reference/discriminated-unions), [opciones](https://learn.microsoft.com/dotnet/fsharp/language-reference/options), [módulo `Option`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-optionmodule.html)
- [Diferencias entre records y clases](https://learn.microsoft.com/dotnet/fsharp/language-reference/records#differences-between-records-and-classes) (igualdad estructural) y [`RequireQualifiedAccessAttribute`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-requirequalifiedaccessattribute.html)
- [Convenciones de código de F#: tipos](https://learn.microsoft.com/dotnet/fsharp/style-guide/conventions)
- C#: [records](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record), [tipos de tupla](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/value-tuples); Java: [records](https://docs.oracle.com/en/java/javase/25/language/records.html), [clases selladas](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html)
