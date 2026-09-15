---
title: 2. Valores, funciones e inferencia de tipos
description: let en lugar de var, valores inmutables por defecto, tipos inferidos para parámetros y resultados, sin conversiones implícitas, if como expresión, funciones currificadas, aplicación parcial y los operadores |> y >> — con las transformaciones de clases de altura de GA y el normalizador de texto de TARS.
sidebar:
  order: 2
---

Código: los scripts [`examples/l02_*.fsx`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples), los fragmentos rechazados [`compile_fail/l02_*.fsx`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/compile_fail) y la sesión [`sessions/l02_inference.txt`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/sessions/l02_inference.txt).

## `let` asocia un nombre a un valor

En C#, `var strings = 6;` declara una variable: puedes volver a asignarla más tarde. En F#, `let strings = 6` da el nombre `strings` al valor `6`, y es definitivo:

```fsharp
let strings = 6
strings <- 7
```

```text
l02_immutable.fsx(2,1): error FS0027: This value is not mutable. Consider using the mutable keyword, e.g. 'let mutable strings = expression'.
```

Un `let` se parece más a un campo `readonly` de C# o a una variable local `final` de Java, salvo que es lo predeterminado y que se aplica a valores de cualquier tipo. Cuando de verdad necesitas una variable, el compilador te dice cómo: `let mutable` y el operador de asignación `<-`.

```fsharp
// mutable permite la asignación, y <- asigna
let mutable total = 0

for fret in 1..12 do
    total <- total + fret

printfn "Frets 1 to 12 add up to %d" total
```

```text
Frets 1 to 12 add up to 78
```

`for fret in 1..12 do` es el `foreach` de C# sobre el rango de 1 a 12, ambos incluidos. El F# idiomático rara vez necesita este bucle: la lección 5 lo sustituye por `List.sum`. `mutable` no es un error, pero es local y explícito, y destaca al leer el código.

### `=` compara, `<-` asigna

La trampa en la que cae todo desarrollador C# el primer día:

```fsharp
let restring () =
    let mutable strings = 6
    strings = 7 // = compara: esta línea calcula false y lo descarta
    printfn "%d strings" strings

restring ()
```

```text
l02_equality_warning.fsx(3,5): warning FS0020: The result of this equality expression has type 'bool' and is implicitly discarded. Consider using 'let' to bind the result to a name, e.g. 'let result = expression'. If you intended to mutate a value, then use the '<-' operator e.g. 'strings <- expression'.

6 strings
```

En F#, `=` dentro de una expresión es la igualdad, el `==` de C#. `strings = 7` es `false`, un valor que la línea descarta; `strings` sigue valiendo 6. Solo es una advertencia, así que el script se ejecuta: trata FS0020 como un error.

### Ocultamiento

Dos `let` con el mismo nombre en el nivel superior de un script o de un módulo se rechazan:

```fsharp
let tuning = "E2 A2 D3 G3 B3 E4"
let tuning = "D2 A2 D3 G3 B3 E4"
printfn "%s" tuning
```

```text
l02_duplicate.fsx(2,5): error FS0037: Duplicate definition of value 'tuning'
```

Dentro de una función, un nuevo `let` puede reutilizar un nombre: define un valor nuevo que *oculta* al anterior a partir de esa línea. No se modifica nada:

```fsharp
let label (name: string) =
    let name = name.Trim() // un valor nuevo que oculta el parámetro
    let name = name.ToUpperInvariant() // y otro más
    $"[{name}]"

printfn "%s" (label "  e minor ")
```

```text
[E MINOR]
```

C# rechaza una variable local que reutiliza el nombre de un parámetro; Rust permite el ocultamiento igual que F#.

## El compilador infiere los tipos

Esto es lo que responde F# Interactive para algunas definiciones ([`sessions/l02_inference.txt`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/sessions/l02_inference.txt)):

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

- `float` es el nombre F# de `System.Double`, el `double` de C#. `int` es `System.Int32`, `string` es `System.String`. `**` es el operador de potencia (`Math.Pow`).
- El `var` de C# infiere el tipo de una variable local. F# infiere también **los parámetros y los tipos de retorno**. `add` no tiene anotación; `+`, sin más información, usa `int` por defecto.
- Basta una anotación para cambiarlo: en `addFloats`, `(a: float)` convierte `+` en una suma de flotantes, así que `b` y el resultado son flotantes.
- `twice` funciona con cualquier tipo: F# la ha hecho **genérica** por sí solo. `'a` es un parámetro de tipo, el `T` de C#. El tipo se lee «toma una función de `'a` a `'a` y un valor `'a`, y devuelve un `'a`». En C#, escribirías `static T Twice<T>(Func<T, T> f, T x)`.
- `first` toma una tupla y devuelve su primer elemento, sean cuales sean los tipos: `'a * 'b -> 'a`. La [lección 3](../03-records-unions-options/) trata de las tuplas.

La inferencia va de arriba abajo y de izquierda a derecha, que es una razón más para el orden de los archivos de la [lección 1](../01-first-program/#los-archivos-compilan-en-orden). Las funciones públicas de una biblioteca suelen llevar anotaciones de todos modos: documentan la API e impiden que un cambio dentro de la función modifique su firma sin que nadie lo note.

## Sin conversiones implícitas

C# convierte un `int` en `double` por ti. F# nunca convierte un número implícitamente:

```fsharp
let semitones = 7
let ratio = 2.0 ** (semitones / 12.0)
```

```text
l02_int_float.fsx(2,33): error FS0001: The type 'float' does not match the type 'int'
```

`semitones / 12.0` divide un `int` entre un `float`: F# se niega, donde C# calcularía un `double` sin decir nada. Las funciones de conversión tienen el nombre del tipo de destino:

```fsharp
let semitones = 7
let ratio = 2.0 ** (float semitones / 12.0) // float convierte explícitamente

printfn "A fifth multiplies the frequency by %.4f" ratio
printfn "A2 = 110 Hz, so E3 = %.2f Hz" (110.0 * ratio)

printfn "%d" (int 3.99) // int trunca, como un cast en C#
printfn "%s" (string 440) // string llama a ToString
printfn "%d" (int "22") // int también analiza una cadena, y lanza una excepción si no puede
```

```text
A fifth multiplies the frequency by 1.4983
A2 = 110 Hz, so E3 = 164.81 Hz
3
440
22
```

`float semitones` es una llamada a función, como `printfn "…" ratio`: la función y luego su argumento. Es el mismo `float` que el nombre del tipo; F# usa el nombre para ambas cosas. La página de [conversiones y cast](https://learn.microsoft.com/dotnet/fsharp/language-reference/casting-and-conversions) enumera las funciones.

## Todo es una expresión

En C#, `if` es una instrucción y `?:` es su forma de expresión. En F#, `if … then … else` *es* la expresión, y un bloque también:

```fsharp
// if/then/else es una expresión: tiene un valor, como el operador ?: de C#
let fretLabel fret = if fret = 0 then "open" else $"fret {fret}"
printfn "%s, %s" (fretLabel 0) (fretLabel 3)

// Un bloque también es una expresión: su valor es su última línea
let positions =
    let strings = 6
    let frets = 22
    strings * (frets + 1)

printfn "%d positions, open strings included" positions

// Las funciones que solo tienen un efecto devuelven unit, que se escribe ()
let nothing = printfn "printfn returns unit"
printfn "%A" nothing
```

```text
open, fret 3
138 positions, open strings included
printfn returns unit
()
```

- `positions` se calcula con un bloque cuyos valores internos, `strings` y `frets`, no existen fuera de él.
- F# no tiene `void`. Una función que no devuelve nada útil devuelve `unit`, cuyo único valor se escribe `()`. Por eso `let restring () = …` recibe `()`: recibe un argumento, el valor unit, y se llama con `restring ()`. Llamar a un método `void` de C# desde F# también devuelve `unit`.

Un `if` sin `else` solo puede ser de tipo `unit`: si produjera una cadena cuando la condición es verdadera, ¿qué produciría cuando es falsa?

```fsharp
let fretLabel fret = if fret = 0 then "open"
```

```text
l02_if_without_else.fsx(1,39): error FS0001: This 'if' expression is missing an 'else' branch. Because 'if' is an expression, and not a statement, add an 'else' branch which also returns a value of type 'string'.
```

## Funciones

### Los parámetros se separan con espacios

Las clases de altura de la teoría musical numeran las doce notas de una octava: 0 es do, 1 es do♯, y así hasta 11, si. Transponer una nota suma semitonos y vuelve a 0 después de 11. El [`HarmonicTransformationService`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Services/HarmonicTransformationService.fs#L10) de Guitar Alchemist empieza con esta función:

```fsharp
let normalize pc = ((pc % 12) + 12) % 12
```

El `%` de un número negativo es negativo en F#, como en C#: `-5 % 12` es `-5`. Por eso la función suma 12 y vuelve a aplicar `% 12`, para quedar entre 0 y 11: `normalize -5` es 7, sol.

```fsharp
// Clases de altura: 0 = do, 1 = do#, ..., 11 = si. El HarmonicTransformationService de Guitar Alchemist usa esta fórmula.
let normalize pc = ((pc % 12) + 12) % 12
printfn "%d %d" (-5 % 12) (normalize -5) // % conserva el signo, normalize no

// Dos parámetros separados por espacios: transpose tiene el tipo int -> int -> int
let transpose interval pc = normalize (pc + interval)

let names = [| "C"; "C#"; "D"; "D#"; "E"; "F"; "F#"; "G"; "G#"; "A"; "A#"; "B" |]
let name pc = names[pc]

printfn "%s" (name (transpose 7 0))

// Aplicación parcial: se da solo el primer argumento y se obtiene una función
let upAFifth = transpose 7
printfn "%s %s %s" (name (upAFifth 0)) (name (upAFifth 7)) (name (upAFifth 2))

// Un argumento negativo: el signo menos va pegado al número
printfn "%s" (name (transpose -1 0))

// Pipeline: x |> f es f x
printfn "%s" (0 |> upAFifth |> upAFifth |> upAFifth |> name)

// Composición: f >> g es fun x -> g (f x)
let fifthName = upAFifth >> name
printfn "%s" (fifthName 9)

// Lambda: fun pc -> ... es el pc => ... de C#
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

`[| … |]` es un array, y `names[pc]` lo indexa. `name (transpose 7 0)` necesita sus paréntesis: sin ellos, `name transpose 7 0` pasaría tres argumentos a `name`.

### Funciones currificadas y aplicación parcial

`transpose` tiene el tipo `int -> int -> int`. Lee las flechas desde la derecha: `transpose` toma un `int` y devuelve una función `int -> int`. `transpose 7 0` es `(transpose 7) 0`. Las funciones que reciben sus parámetros de uno en uno de esta forma se llaman **currificadas**, por el lógico Haskell Curry.

Así que `transpose 7`, con un solo argumento, es un valor completo: una función que transpone una quinta hacia arriba. Eso es la **aplicación parcial**. El equivalente en C# necesita lambdas anidadas:

```csharp
Func<int, Func<int, int>> transpose = interval => pc => Normalize(pc + interval);
var upAFifth = transpose(7);
```

y Java tiene `Function<Integer, Function<Integer, Integer>>`. F# lo convierte en la forma normal de escribir una función, y por eso importa el orden de los parámetros: el que más probablemente vas a fijar va primero. `interval` va antes que `pc`, para que `transpose 7` tenga sentido.

La costumbre de C# de llamar con paréntesis y comas pasa **una tupla** en lugar de dos argumentos:

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

`int * int` es el tipo de la tupla `(7, 0)`. Los métodos de las clases .NET, en cambio, se llaman con paréntesis y comas: `name.Trim()`, `Regex.Replace(s, pattern, "")`. La sección siguiente muestra dónde se encuentran ambas formas.

Los espacios alrededor de un signo menos también importan. `transpose -1 0` pasa `-1`, pero `transpose - 1 0` resta:

```fsharp
printfn "%d" (transpose - 1 0)
```

```text
l02_minus_spaced.fsx(4,27): error FS0003: This value is not a function and cannot be applied.
```

F# lee `transpose - (1 0)`, y `1` no es una función que se pueda aplicar a `0`.

### Lambdas, `|>` y `>>`

- `fun pc -> transpose -1 pc` es una lambda, el `pc => Transpose(-1, pc)` de C#. Como `transpose -1` ya es esa función, `let downASemitone = transpose -1` haría lo mismo.
- `x |> f` es `f x`: el operador **pipe** pasa el valor de su izquierda a la función de su derecha. `0 |> upAFifth |> upAFifth |> upAFifth |> name` se lee en el orden en que se hace el trabajo, como una cadena de métodos LINQ. Está definido en FSharp.Core como una función ordinaria de dos argumentos, que llama a la segunda con el primero.
- `f >> g` es la **composición** de dos funciones: una función nueva que llama a `f` y luego a `g` con el resultado.

TARS escribe su preprocesamiento de texto como un pipeline, en [`TextNormalizer.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/TextNormalizer.fs#L71-L73):

```fsharp
    /// Extract keywords from text (normalize -> tokenize -> remove stop words -> dedup)
    let extractKeywords (text: string) =
        text |> normalize |> tokenize |> removeStopWords |> List.distinct
```

Cada paso es una función del módulo que toma el resultado del anterior; el comentario y el código dicen lo mismo, en el mismo orden. Su primer paso, [`normalize`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/TextNormalizer.fs#L51-L58), mezcla métodos .NET (llamados con paréntesis) y pipes de F#, con lambdas en medio:

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

- `(text: string)` está anotado porque `text.ToLowerInvariant()` llama a un método: F# necesita conocer el tipo de `text` antes de un `.`, ya que la inferencia va de izquierda a derecha.
- `@"…"` es una cadena literal, como en C#.
- `|> fun s -> …` envía a una lambda, una por línea.

El script [`examples/l02_tars_normalize.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l02_tars_normalize.fsx) del curso vuelve a escribir esta función (TARS no tiene archivo de licencia, así que el curso no copia el archivo) y la ejecuta:

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

El patrón `[^a-z0-9\s]` elimina todo lo que no sea una letra ASCII, un dígito o un espacio. Para un framework de agentes escrito en F#, eso incluye `#`: las palabras clave de «learn F#» son `learn` y `f`, y `C#` se convierte en la letra `c`. Las letras acentuadas desaparecen en medio de las palabras: `café` se convierte en `caf`. La [prueba](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/tests/Tars.Tests/TextNormalizerTests.fs#L6-L11) de TARS solo usa una frase en inglés. El diario lo anota; la lección 5 vuelve sobre este módulo.

## Código real: miembros currificados en GA

`HarmonicTransformationService` es una clase (lección 9), cuyos miembros están currificados como las funciones anteriores. [Su `Transpose`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Services/HarmonicTransformationService.fs#L12-L16):

```fsharp
    /// <summary>
    /// Transposes a set of pitch classes.
    /// </summary>
    member _.Transpose (interval: Interval) (pcs: PitchClassSet) : PitchClassSet =
        pcs |> Set.map (fun pc -> normalize (pc + interval))
```

`Interval` y `PitchClassSet` son abreviaturas de tipo de [`MusicalSetTypes.fs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Types/MusicalSetTypes.fs#L8-L12): otros nombres para `int` y `Set<int>`. `Set.map` aplica la lambda a cada elemento del conjunto. El `: PitchClassSet` tras los parámetros anota el resultado.

El curso carga el archivo de GA con `#load` y lo llama ([`examples/l02_ga_transformations.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l02_ga_transformations.fsx)):

```fsharp
// El HarmonicTransformationService de Guitar Alchemist, cargado desde las copias de external/ga
#load "../external/ga/MusicalSetTypes.fs" "../external/ga/HarmonicTransformationService.fs"

open GA.Business.DSL.Services

let service = HarmonicTransformationService()
let cMajor = set [ 0; 4; 7 ] // do mi sol

printfn "%A" (service.Transpose 7 cMajor) // una quinta arriba: sol si re

let upAFifth = service.Transpose 7 // un método con parámetros currificados se puede aplicar parcialmente
printfn "%A" (cMajor |> upAFifth |> upAFifth) // re fa# la

printfn "%A" (service.Invert 0 cMajor) // reflejado alrededor de do: do fa lab

// Una vez compilado, el miembro currificado es un método .NET ordinario de dos parámetros: C# llama a Transpose(2, set)
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

Las dos últimas líneas muestran cómo compila F# un miembro currificado: un método ordinario `Transpose(int interval, FSharpSet<int> pcs)`. Las pruebas C# de GA lo llaman así, en [`HarmonicTransformationTests.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Tests/Common/GA.Business.DSL.Tests/HarmonicTransformationTests.cs#L15-L18): `_service.Transpose(2, cMajor)`. La aplicación parcial se queda del lado de F#; la lección 20 trata del diseño de API F# que C# consume cómodamente.

:::caution[Lo que encontró el curso]
La misma clase tiene un método [`GetNormalForm`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Services/HarmonicTransformationService.fs#L35-L58), «un orden normal simplificado transpuesto a cero». Una forma normal debe dar la misma respuesta para un acorde y para sus transposiciones, pero no es así:

```fsharp
let chord = set [ 0; 4; 7; 8 ]
printfn "%A" (service.GetNormalForm chord)
printfn "%A" (service.GetNormalForm(service.Transpose 8 chord))
```

```text
[0; 4; 7; 8]
[0; 3; 4; 8]
```

Dos rotaciones de este conjunto tienen la menor extensión, 8 semitonos, y `List.minBy fst` se queda con la que aparece primero, así que la respuesta depende de dónde empieza el conjunto. El orden normal también compara los intervalos interiores cuando las extensiones son iguales, lo que elegiría `[0; 3; 4; 8]` las dos veces. La búsqueda de código de GitHub no encontró ningún llamador de `GetNormalForm` en GA el 2026-09-15, así que nada usa todavía la respuesta errónea. Detalles en el [diario](../journal/).
:::

## Puntos clave

- `let` da un nombre a un valor que nunca cambia; `let mutable` y `<-` son la excepción explícita, y `=` siempre compara.
- El compilador infiere los tipos de valores, parámetros y resultados, y generaliza las funciones cuando puede (`'a`); basta una anotación para orientarlo.
- Los números nunca se convierten implícitamente: `float`, `int` y `string` convierten de forma explícita.
- `if`, los bloques y `try` son expresiones; `unit` y `()` sustituyen a `void`.
- Las funciones reciben sus argumentos separados por espacios y están currificadas: `transpose 7` es una función. `|>` envía un valor a una función, `>>` compone dos funciones y `fun x -> …` es una lambda.

## Ejercicios

1. En el temperamento igual, cada semitono multiplica la frecuencia por la raíz duodécima de 2, y el la4 está a 440 Hz. Escribe `frequency`, que recibe el número de semitonos desde el la4 (un `int`, negativo por debajo del la4), e imprime las frecuencias del la4, del mi4 (5 semitonos por debajo) y del mi2 (29 por debajo) con dos decimales.

<details>
<summary>Solución</summary>

[`exercises/l02_ex_frequency.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l02_ex_frequency.fsx):

```fsharp
// Temperamento igual: cada semitono multiplica la frecuencia por 2^(1/12), y el la4 está a 440 Hz
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

`float semitonesFromA4` es obligatorio: sin él, `semitonesFromA4 / 12.0` es el error FS0001 de [Sin conversiones implícitas](#sin-conversiones-implícitas). F# infiere `frequency: semitonesFromA4: int -> float`.

</details>

2. Escribe `interval fromPc toPc`, el número de semitonos que hay que *subir* de una clase de altura a otra (de mi, 4, a do, 0, son 8). Después define `fromE` por aplicación parcial y úsala con sol (7), do (0) y, con `|>`, mi (4).

<details>
<summary>Solución</summary>

[`exercises/l02_ex_partial.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l02_ex_partial.fsx):

```fsharp
let normalize pc = ((pc % 12) + 12) % 12

// Semitonos que hay que subir de una clase de altura a otra
let interval fromPc toPc = normalize (toPc - fromPc)

let fromE = interval 4 // aplicación parcial: int -> int

printfn "E up to G: %d semitones" (fromE 7)
printfn "E up to C: %d semitones" (fromE 0)
printfn "E up to E: %d semitones" (4 |> fromE)
```

```text
E up to G: 3 semitones
E up to C: 8 semitones
E up to E: 0 semitones
```

`0 - 4` es `-4`, y `normalize` lo convierte en 8: por eso la fórmula de GA suma 12 antes del segundo `% 12`.

</details>

3. Este script tiene tres errores. Ejecútalo, corrige lo que señale F# y vuelve a ejecutarlo hasta que imprima `capo on fret 3: frequencies multiplied by 1.1892`. ¿Cuántas ejecuciones hicieron falta?

```fsharp
let capo = 2
capo <- 3
let ratio = 2.0 ** (capo / 12.0)
let label = if capo = 0 then "no capo"
```

<details>
<summary>Solución</summary>

Cuatro ejecuciones: aquí F# Interactive señala un error por ejecución. La primera:

```text
l02_ex_broken.fsx(2,1): error FS0027: This value is not mutable. Consider using the mutable keyword, e.g. 'let mutable capo = expression'.
```

Tras `let mutable capo = 2`, la segunda:

```text
l02_ex_broken_step2.fsx(3,28): error FS0001: The type 'float' does not match the type 'int'
```

Tras `float capo`, la tercera:

```text
l02_ex_broken_step3.fsx(4,30): error FS0001: This 'if' expression is missing an 'else' branch. Because 'if' is an expression, and not a statement, add an 'else' branch which also returns a value of type 'string'.
```

El script corregido ([`exercises/l02_ex_fixed.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l02_ex_fixed.fsx)), con el `printfn` que pedía el enunciado:

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

Una cejilla en el traste 3 sube cada cuerda 3 semitonos, y `2.0 ** (3.0 / 12.0)` es aproximadamente 1.1892.

</details>

## Fuentes

- [Valores](https://learn.microsoft.com/dotnet/fsharp/language-reference/values/), [enlaces `let`](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/let-bindings)
- [Inferencia de tipos](https://learn.microsoft.com/dotnet/fsharp/language-reference/type-inference), [generalización automática](https://learn.microsoft.com/dotnet/fsharp/language-reference/generics/automatic-generalization)
- [Conversiones y cast](https://learn.microsoft.com/dotnet/fsharp/language-reference/casting-and-conversions), [tipos básicos](https://learn.microsoft.com/dotnet/fsharp/language-reference/basic-types)
- [Expresiones condicionales](https://learn.microsoft.com/dotnet/fsharp/language-reference/conditional-expressions-if-then-else), [tipo unit](https://learn.microsoft.com/dotnet/fsharp/language-reference/unit-type)
- [Funciones](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/), [expresiones lambda](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/lambda-expressions-the-fun-keyword), [operadores de FSharp.Core](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-operators.html)
- [Referencia de símbolos y operadores](https://learn.microsoft.com/dotnet/fsharp/language-reference/symbol-and-operator-reference/)
