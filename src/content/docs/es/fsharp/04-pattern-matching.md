---
title: 4. Coincidencia de patrones
description: match junto a la expresión switch de C# y el switch con patrones de Java — constantes, patrones «o», guardas, tuplas, casos de unión, records y listas, las advertencias por reglas incompletas e inalcanzables, y lo que la coincidencia de patrones encontró en el parser de acordes y el script BinObj de GA.
sidebar:
  order: 4
---

Código: los scripts [`examples/l04_*.fsx`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples) y el fragmento rechazado [`compile_fail/l04_warnaserror.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/compile_fail/l04_warnaserror.fsx).

## `match` es una expresión `switch`

C# 8 añadió la expresión `switch`, y C# 9 sus patrones relacionales y `or`:

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

Java 21 tiene `switch` con patrones y guardas `when`. El [`match`](https://learn.microsoft.com/dotnet/fsharp/language-reference/match-expressions) de F# es la construcción en la que se inspiraron:

```fsharp
// match prueba los patrones de arriba abajo; gana el primero que encaja
let intervalName semitones =
    match semitones with
    | 0 -> "unison"
    | 3 | 4 -> "third" // patrón «o»
    | 7 -> "perfect fifth"
    | 12 -> "octave"
    | n when n > 12 -> $"compound interval ({n - 12} above an octave)" // guarda
    | _ -> "other" // comodín

for semitones in [ 0; 4; 7; 10; 19 ] do
    printfn "%d: %s" semitones (intervalName semitones)

// Una tupla compara varios valores a la vez
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

- Cada regla es `| patrón -> expresión`. Las reglas se prueban en orden, y el valor del `match` es la expresión de la primera regla que encaja. Como `if`, `match` es una expresión: todas sus ramas tienen el mismo tipo.
- `3 | 4` es un **patrón «o»**, el `3 or 4` de C#.
- `n when n > 12` **enlaza** el valor con `n`, y luego una **guarda** lo comprueba. F# no tiene patrones relacionales como el `> 12` de C#: una guarda hace el mismo trabajo.
- `_` coincide con cualquier cosa, como el descarte de C#.
- `match stringNumber, fret with` compara una tupla. `_, 0` significa «cualquier cuerda, traste 0»; `(5 | 6), f` anida un patrón «o» dentro del patrón de tupla y enlaza el traste.

## Casos de unión y opciones

Los patrones rinden de verdad con las [uniones discriminadas](../03-records-unions-options/#uniones-discriminadas): un patrón puede comprobar el caso y descomponer sus datos en un solo paso.

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
    | Fretted 1 -> "first fret" // un caso con una constante dentro
    | Fretted fret -> $"fret {fret}" // un caso que enlaza sus datos
    | Barre(fret, 6) -> $"full barre on fret {fret}"
    | Barre(fret = f; strings = n) -> $"barre on fret {f} across {n} strings" // por nombre de campo

for fingering in [ Open; Muted; Fretted 1; Fretted 5; Barre(1, 6); Barre(3, 4) ] do
    printfn "%s" (describe fingering)

// Option también es una unión: Some y None son sus casos
let capoLabel capo =
    match capo with
    | None
    | Some 0 -> "no capo"
    | Some fret -> $"capo on fret {fret}"

printfn "%s, %s, %s" (capoLabel None) (capoLabel (Some 0)) (capoLabel (Some 2))

// function es fun x -> match x with, como en el ChordRenderer de Guitar Alchemist
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

- `Fretted 1` solo coincide con el valor `Fretted 1`; `Fretted fret` coincide con cualquier `Fretted` y llama `fret` a sus datos. El orden importa: al revés, `Fretted fret` atraparía primero `Fretted 1`.
- `Barre(fret = f; strings = n)` compara los campos por nombre, separados por `;`.
- Un patrón «o» puede ocupar dos líneas, como `None` y `Some 0`.
- `function` es un atajo para una lambda que compara su argumento de inmediato: `let isPlayed = function | … ` es `let isPlayed x = match x with | …`.

La versión en C# de `describe` usaría patrones de tipo sobre una jerarquía de records (`Fretted { Fret: 1 } => …`, `Fretted f => …`). Se parece, y lo es, con una diferencia de la que trata la sección siguiente.

### Código real: el renderizador de acordes de GA

El [`ChordRenderer.fs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Generators/ChordRenderer.fs#L5-L40) de GA convierte de nuevo en texto el `ChordAst` de la lección 3. Es casi todo coincidencia de patrones:

```fsharp
module ChordRenderer =
    let renderAccidental =
        function
        | Natural -> ""
        | Sharp -> "#"
        | Flat -> "b"
        | DoubleSharp -> "##"
        | DoubleFlat -> "bb"

    // (renderQuality, líneas 14-21, tiene la misma forma)

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

- `renderAccidental` es una `function` con una regla por caso de `AccidentalType`, y sin `_`: si GA añade algún día un triple sostenido, el compilador señalará esta función.
- `Alteration(acc, deg)` descompone la tupla que lleva el caso.
- `Some(n, acc)` anida un patrón de tupla dentro del patrón `Some`: coincide con un bajo y nombra su letra y su alteración en un solo paso.
- `List.map renderComponent` aplica la función a cada componente; la lección 5 trata de `List`.

## El compilador comprueba que se trata cada caso

Este es un `match` que olvida dos casos:

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

El compilador conoce todos los casos de `Accidental` y nombra uno que ninguna regla cubre. Es una advertencia, así que el script se ejecuta, y falla en tiempo de ejecución con una `MatchFailureException` cuando `DoubleFlat` llega de verdad (F# Interactive también imprime la pila de llamadas, que el `check.sh` del curso elimina).

C# también avisa, pero no puede ser tan preciso. Una expresión `switch` sobre la jerarquía de records `Fingering` de la lección 3 que trata `Open`, `Fretted` y `Muted`, las tres subclases, sigue recibiendo `warning CS8509: … For example, the pattern '_' is not covered`: otro ensamblado podría añadir una subclase. Sobre un enum que enumera todos sus valores con nombre, recibe CS8524, porque `(Accidental)3` también es un valor válido. Así que el código C# termina con un brazo `_ =>`, que silencia la advertencia para siempre (el [diario](../journal/#2026-09-15--comparaciones-con-c) tiene los dos archivos). Java 21 sí comprueba un `switch` sobre una interfaz `sealed`, y rechaza un caso que falta. Las uniones F# son cerradas como los tipos sellados de Java, y F# comprueba todos los patrones: tuplas de uniones, opciones anidadas, listas.

Una advertencia que deja que el programa falle más tarde debería ser un error. En un proyecto, `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`, o `<WarningsAsErrors>FS0025</WarningsAsErrors>` solo para esta advertencia, lo hace para toda la compilación; TARS activa la primera en [`v2/Directory.Build.props`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/Directory.Build.props#L3), GA no. Para un script, `dotnet fsi` acepta la [opción del compilador](https://learn.microsoft.com/dotnet/fsharp/language-reference/compiler-options) `--warnaserror+:25`:

```text
> dotnet fsi --warnaserror+:25 compile_fail/l04_warnaserror.fsx
l04_warnaserror.fsx(10,11): error FS0025: Incomplete pattern matches on this expression. For example, the value 'DoubleFlat' may indicate a case not covered by the pattern(s).
```

### Las guardas anulan la comprobación

El compilador no puede evaluar una guarda. Estas tres reglas cubren todos los enteros, pero solo un lector puede verlo:

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

Esta vez el mensaje no da ningún ejemplo: el compilador no sabe qué valor se escapa. Escribe la última regla sin guarda, `| _ -> "same note"`, y la advertencia desaparece.

### Reglas que nunca coinciden

Las reglas se prueban en orden, así que una regla situada después de un patrón que lo atrapa todo es código muerto:

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

### Los comodines ocultan los casos nuevos

`_` es cómodo y peligroso del mismo modo que el `default` de C#. La función `isPlayed` de arriba usa `| _ -> true` para tres casos; si se añade a `Fingering` un quinto caso `Harmonic of fret: int`, `isPlayed` responde `true` para él sin decir nada, y no aparece ninguna advertencia. `renderAccidental` en GA, con una regla por caso, recibiría la advertencia. Es mejor enumerar los casos de una unión cuya lista puede crecer; deja `_` para conjuntos abiertos de valores como los enteros y las cadenas.

## Patrones de listas y recursión

Una lista está vacía, `[]`, o es un elemento seguido del resto de la lista, `head :: tail`. Los patrones descomponen las listas según esas dos formas:

```fsharp
// Patrones de listas: [] es la lista vacía, head :: tail separa el primer elemento
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

// Una función recursiva (rec) recorre la lista elemento a elemento
let rec total frets =
    match frets with
    | [] -> 0
    | fret :: rest -> fret + total rest

printfn "%d" (total [ 3; 2; 0; 1; 0 ])

// Los patrones también funcionan en let y en los parámetros
let (note, octave) = ("A", 4)
let lowest (first :: _) = first // advertencia: [] no se trata
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

- `[ single ]` coincide con una lista de exactamente un elemento, `[ low; high ]` de exactamente dos.
- `lowest :: rest` coincide con cualquier lista no vacía. Colocado primero, atraparía también las listas de uno y dos elementos.
- Una función que se llama a sí misma necesita [`rec`](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/recursive-functions-the-rec-keyword). `total` tiene la forma clásica: una regla para la lista vacía y una regla que trata un elemento y se llama recursivamente con el resto. La lección 5 muestra las funciones de biblioteca que te ahorran escribir la mayoría de estas funciones.
- Los patrones no son solo para `match`. `let (note, octave) = …` descompone una tupla, y `let describeAgent (AgentId id) = …` en la lección 3 desenvolvía una unión de un solo caso en un parámetro. También se comprueban: `lowest (first :: _)` recibe FS0025, ya que una lista vacía no tiene primer elemento.

### Código real: el script BinObj de GA

El [`Scripts/BinObj.fsx`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Scripts/BinObj.fsx) de GA busca las carpetas `bin` y `obj` de un árbol de código fuente, con una función recursiva sobre una lista:

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

- `match EnumerateDirectories path with | [] -> [] | subfolders -> …` trata una carpeta sin subcarpetas y luego enlaza la lista no vacía con un nombre.
- `isObjOrBinFolder >> not` compone la prueba con `not`, la [composición de la lección 2](../02-values-and-functions/#lambdas--y-): «no es una carpeta bin u obj».
- `List.collect getFoldersToDelete` entra recursivamente en cada subcarpeta restante y concatena los resultados.

El curso carga el script y ejecuta su función sobre un árbol pequeño ([`examples/l04_ga_binobj.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l04_ga_binobj.fsx)):

```fsharp
// Un árbol pequeño en la carpeta temporal
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

:::caution[Lo que encontró el curso]
Los patrones son correctos; la prueba no. `EnumerateDirectories` devuelve rutas completas, y `EndsWith("bin", true, …)` es verdadero para cualquier carpeta cuyo nombre *termina* con esas letras, sin distinguir mayúsculas: se seleccionan `Docs/cabin` y `Robin`, y ni siquiera se visita `Robin/Songs`. Comparar exactamente el nombre de la carpeta, `Path.GetFileName folderName` con `"bin"` y `"obj"`, lo arreglaría. El script define las funciones pero nunca las llama, así que ejecutar `dotnet fsi Scripts/BinObj.fsx` no hace nada y no borra nada. Detalles en el [diario](../journal/).
:::

## Código real: coincidencia sobre `Result` en el parser de acordes de GA

El [`ChordParser.parse`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Parsers/ChordParser.fs#L86-L89) de GA ejecuta un parser de FParsec y convierte su resultado, una unión de FParsec, en el `Result` de F#:

```fsharp
    let parse chordStr =
        match run pChord chordStr with
        | Success(result, _, _) -> Result.Ok result
        | Failure(errorMsg, _, _) -> Result.Error errorMsg
```

`Success(result, _, _)` enlaza el primero de tres valores e ignora los otros dos. El curso carga el parser y compara el `Result` que devuelve ([`examples/l04_ga_parse.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l04_ga_parse.fsx)):

```fsharp
#r "nuget: FParsec, 1.1.1"
#load "../external/ga/ChordAst.fs" "../external/ga/ChordRenderer.fs" "../external/ga/ChordParser.fs"

open GA.Business.DSL.Parsers
open GA.Business.DSL.Generators

// El ChordParser.parse de Guitar Alchemist devuelve un Result: Ok con el AST, o Error con el mensaje de FParsec
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

Las tres primeras líneas son casos de la propia prueba de GA, [`ChordDslTests.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Tests/Common/GA.Business.DSL.Tests/ChordDslTests.cs#L11-L18). `H7`, el nombre alemán de B7, se rechaza con el mensaje de FParsec.

:::caution[Lo que encontró el curso]
`C7sus4` se convierte en `C7`, y `Am(maj7)` en `Am`: el parser se detiene en el primer carácter que no entiende, y `parse` devuelve `Ok` con lo que ha leído hasta ahí. Nunca se le dice al parser que la entrada debe terminar ahí (el `eof` de FParsec), así que el resto se descarta sin avisar. `ChordDslService.Parse` y `Normalize` heredan el comportamiento, y también el [`ResponseValidator`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.Core.Orchestration/Services/ResponseValidator.cs#L30-L38) en C# del chatbot de GA, que llama a `Parse` con cada palabra de una respuesta que parece un acorde y solo mira si ha tenido éxito. La lección 11 vuelve sobre ello con FParsec; el [diario](../journal/) tiene los detalles.
:::

## Puntos clave

- `match value with | pattern -> result` prueba las reglas en orden y es una expresión; `function` es una lambda que compara su argumento.
- Los patrones se combinan: constantes, `_`, `|` para las alternativas, guardas `when`, tuplas, casos de unión con sus datos, campos por nombre, `[]` y `head :: tail` para las listas.
- El compilador avisa cuando falta un caso (FS0025) o una regla es inalcanzable (FS0026); convierte FS0025 en error en los proyectos, y evita `_` en uniones que pueden crecer.
- Las guardas no se analizan: la última regla de un match con guardas no debería tener guarda.
- Los patrones funcionan también en `let` y en los parámetros, con las mismas comprobaciones.

## Ejercicios

1. Escribe `quality semitones`, que devuelve `"perfect"` para 0, 5, 7 y 12, `"minor"` para 1, 3, 8 y 10, `"major"` para 2, 4, 9 y 11, `"tritone"` para 6, un mensaje para los números negativos y otro para los intervalos mayores que una octava. Usa patrones «o» y una guarda, e imprime el resultado para -3, 0, 3, 4, 6, 7, 11 y 14.

<details>
<summary>Solución</summary>

[`exercises/l04_ex_intervals.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l04_ex_intervals.fsx):

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

La guarda va primero, así que no hace falta excluir los números negativos más adelante. El `_` final es correcto aquí: los enteros son un conjunto abierto, y todo valor por encima de 12 merece la misma respuesta. `%3d` rellena el número hasta tres caracteres.

</details>

2. Corrige la función `symbol` de [El compilador comprueba que se trata cada caso](#el-compilador-comprueba-que-se-trata-cada-caso) para que el script imprima `C#` y `Cbb` sin advertencia. ¿Por qué no añadir `| _ -> ""`?

<details>
<summary>Solución</summary>

[`exercises/l04_ex_symbol_fixed.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l04_ex_symbol_fixed.fsx):

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

`| _ -> ""` también quita la advertencia, pero imprime `C` para un doble bemol: una respuesta errónea en lugar de un error. Y el próximo caso que se añada a `Accidental` recibiría la misma respuesta errónea, sin advertencia que señale esta función.

</details>

3. La prueba `Test_Complex_Alterations` de GA analiza `C13#11b9` y espera tres componentes. Escribe una función recursiva `countAlterations` sobre una `ChordComponent list`, con patrones de listas, que cuente los componentes `Alteration` y `Alt`, y úsala con el resultado del parser de GA para ese acorde.

<details>
<summary>Solución</summary>

[`exercises/l04_ex_count.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l04_ex_count.fsx):

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

// El acorde de la prueba Test_Complex_Alterations de GA (Tests/Common/GA.Business.DSL.Tests/ChordDslTests.cs)
match ChordParser.parse "C13#11b9" with
| Ok chord -> printfn "%A: %d alterations" chord.Components (countAlterations chord.Components)
| Error message -> printfn "%s" message
```

```text
[Extension "13"; Alteration (Sharp, "11"); Alteration (Flat, "9")]: 2 alterations
```

`(Alteration _ | Alt) :: rest` pone un patrón «o» en la cabeza de un patrón de lista; `Alteration _` ignora los datos del caso. Los dos lados de un patrón «o» deben enlazar los mismos nombres, aquí solo `rest`, fuera de los paréntesis.

</details>

## Fuentes

- [Expresiones match](https://learn.microsoft.com/dotnet/fsharp/language-reference/match-expressions), [coincidencia de patrones](https://learn.microsoft.com/dotnet/fsharp/language-reference/pattern-matching)
- [Funciones recursivas: la palabra clave `rec`](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/recursive-functions-the-rec-keyword), [listas](https://learn.microsoft.com/dotnet/fsharp/language-reference/lists)
- [Opciones del compilador](https://learn.microsoft.com/dotnet/fsharp/language-reference/compiler-options) (`--warnaserror`)
- C#: [la expresión `switch`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression), [patrones](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/patterns); Java: [coincidencia de patrones para `switch`](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html)
- [FParsec: ejecutar parsers](https://www.quanttec.com/fparsec/users-guide/parser-functions.html)
