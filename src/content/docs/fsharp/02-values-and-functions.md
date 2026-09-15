---
title: 2. Values, functions and type inference
description: let instead of var, immutable values by default, types inferred for parameters and results, no implicit conversions, if as an expression, curried functions, partial application, and the |> and >> operators — with GA's pitch-class transformations and TARS's text normalizer.
sidebar:
  order: 2
---

Code: the scripts [`examples/l02_*.fsx`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples), the rejected snippets [`compile_fail/l02_*.fsx`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/compile_fail) and the session [`sessions/l02_inference.txt`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/sessions/l02_inference.txt).

## `let` binds a name to a value

In C#, `var strings = 6;` declares a variable: you can assign it again later. In F#, `let strings = 6` gives the name `strings` to the value `6`, and that's final:

```fsharp
let strings = 6
strings <- 7
```

```text
l02_immutable.fsx(2,1): error FS0027: This value is not mutable. Consider using the mutable keyword, e.g. 'let mutable strings = expression'.
```

A `let` is closer to C#'s `readonly` field or Java's `final` local, except that it's the default, and that it applies to values of every kind. When you really need a variable, the compiler tells you how: `let mutable`, and the assignment operator `<-`.

```fsharp
// mutable opts in to assignment, and <- assigns
let mutable total = 0

for fret in 1..12 do
    total <- total + fret

printfn "Frets 1 to 12 add up to %d" total
```

```text
Frets 1 to 12 add up to 78
```

`for fret in 1..12 do` is C#'s `foreach` over the range 1 to 12, both included. Idiomatic F# rarely needs this loop: lesson 5 replaces it with `List.sum`. `mutable` isn't wrong, but it's local and explicit, and it stands out when you read the code.

### `=` compares, `<-` assigns

The trap that catches every C# developer on the first day:

```fsharp
let restring () =
    let mutable strings = 6
    strings = 7 // = compares: this line computes false and drops it
    printfn "%d strings" strings

restring ()
```

```text
l02_equality_warning.fsx(3,5): warning FS0020: The result of this equality expression has type 'bool' and is implicitly discarded. Consider using 'let' to bind the result to a name, e.g. 'let result = expression'. If you intended to mutate a value, then use the '<-' operator e.g. 'strings <- expression'.

6 strings
```

In F#, `=` in an expression is equality, C#'s `==`. `strings = 7` is `false`, a value that the line throws away; `strings` is still 6. It's only a warning, so the script runs: treat FS0020 as an error.

### Shadowing

Two `let` with the same name at the top level of a script or module are rejected:

```fsharp
let tuning = "E2 A2 D3 G3 B3 E4"
let tuning = "D2 A2 D3 G3 B3 E4"
printfn "%s" tuning
```

```text
l02_duplicate.fsx(2,5): error FS0037: Duplicate definition of value 'tuning'
```

Inside a function, a new `let` may reuse a name: it defines a new value that *hides* the previous one from that line on. Nothing is modified:

```fsharp
let label (name: string) =
    let name = name.Trim() // a new value that hides the parameter
    let name = name.ToUpperInvariant() // and another one
    $"[{name}]"

printfn "%s" (label "  e minor ")
```

```text
[E MINOR]
```

C# rejects a local variable that reuses the name of a parameter; Rust allows shadowing in the same way as F#.

## The compiler infers the types

Here is what F# Interactive answers for a few definitions ([`sessions/l02_inference.txt`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/sessions/l02_inference.txt)):

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

- `float` is F#'s name for `System.Double`, C#'s `double`. `int` is `System.Int32`, `string` is `System.String`. `**` is the power operator (`Math.Pow`).
- C#'s `var` infers the type of a local variable. F# infers **parameters and return types** too. `add` has no annotation; `+` with nothing else to go on defaults to `int`.
- One annotation is enough to change that: in `addFloats`, `(a: float)` makes `+` a float addition, so `b` and the result are floats.
- `twice` works for any type: F# made it **generic** on its own. `'a` is a type parameter, C#'s `T`. The type reads "takes a function from `'a` to `'a`, and a value `'a`, and returns an `'a`". In C#, you would write `static T Twice<T>(Func<T, T> f, T x)`.
- `first` takes a tuple and returns its first element, whatever the types: `'a * 'b -> 'a`. [Lesson 3](../03-records-unions-options/) is about tuples.

Inference goes from top to bottom and from left to right, which is one more reason for the file order of [lesson 1](../01-first-program/#files-compile-in-order). Public functions of a library usually get annotations anyway: they document the API, and they keep a change inside the function from silently changing its signature.

## No implicit conversions

C# converts an `int` to a `double` for you. F# never converts a number implicitly:

```fsharp
let semitones = 7
let ratio = 2.0 ** (semitones / 12.0)
```

```text
l02_int_float.fsx(2,33): error FS0001: The type 'float' does not match the type 'int'
```

`semitones / 12.0` divides an `int` by a `float`: F# refuses, where C# would silently compute a `double`. The conversion functions have the name of the target type:

```fsharp
let semitones = 7
let ratio = 2.0 ** (float semitones / 12.0) // float converts explicitly

printfn "A fifth multiplies the frequency by %.4f" ratio
printfn "A2 = 110 Hz, so E3 = %.2f Hz" (110.0 * ratio)

printfn "%d" (int 3.99) // int truncates, like a cast in C#
printfn "%s" (string 440) // string calls ToString
printfn "%d" (int "22") // int also parses a string, and throws if it can't
```

```text
A fifth multiplies the frequency by 1.4983
A2 = 110 Hz, so E3 = 164.81 Hz
3
440
22
```

`float semitones` is a function call, like `printfn "…" ratio`: the function, then its argument. It's the same `float` as the type name; F# uses the name for both. The [casting and conversions](https://learn.microsoft.com/dotnet/fsharp/language-reference/casting-and-conversions) page lists the functions.

## Everything is an expression

In C#, `if` is a statement and `?:` is its expression form. In F#, `if … then … else` *is* the expression, and so is a block:

```fsharp
// if/then/else is an expression: it has a value, like C#'s ?: operator
let fretLabel fret = if fret = 0 then "open" else $"fret {fret}"
printfn "%s, %s" (fretLabel 0) (fretLabel 3)

// A block is an expression too: its value is its last line
let positions =
    let strings = 6
    let frets = 22
    strings * (frets + 1)

printfn "%d positions, open strings included" positions

// Functions that only have an effect return unit, written ()
let nothing = printfn "printfn returns unit"
printfn "%A" nothing
```

```text
open, fret 3
138 positions, open strings included
printfn returns unit
()
```

- `positions` is computed by a block whose inner values, `strings` and `frets`, don't exist outside it.
- F# has no `void`. A function that returns nothing useful returns `unit`, whose only value is written `()`. That is why `let restring () = …` above takes `()`: it takes one argument, the unit value, and you call it with `restring ()`. Calling a C# `void` method from F# returns `unit` too.

An `if` without `else` can only be of type `unit`: if it produced a string when the condition is true, what would it produce when it's false?

```fsharp
let fretLabel fret = if fret = 0 then "open"
```

```text
l02_if_without_else.fsx(1,39): error FS0001: This 'if' expression is missing an 'else' branch. Because 'if' is an expression, and not a statement, add an 'else' branch which also returns a value of type 'string'.
```

## Functions

### Parameters are separated by spaces

The pitch classes of music theory number the twelve notes of an octave: 0 is C, 1 is C♯, and so on up to 11, B. Transposing a note adds semitones and wraps around at 12. Guitar Alchemist's [`HarmonicTransformationService`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Services/HarmonicTransformationService.fs#L10) starts with this function:

```fsharp
let normalize pc = ((pc % 12) + 12) % 12
```

`%` of a negative number is negative in F#, as in C#: `-5 % 12` is `-5`. So the function adds 12 and takes `% 12` again, to land between 0 and 11: `normalize -5` is 7, G.

```fsharp
// Pitch classes: 0 = C, 1 = C#, ..., 11 = B. Guitar Alchemist's HarmonicTransformationService uses this formula.
let normalize pc = ((pc % 12) + 12) % 12
printfn "%d %d" (-5 % 12) (normalize -5) // % keeps the sign, normalize doesn't

// Two parameters separated by spaces: transpose has the type int -> int -> int
let transpose interval pc = normalize (pc + interval)

let names = [| "C"; "C#"; "D"; "D#"; "E"; "F"; "F#"; "G"; "G#"; "A"; "A#"; "B" |]
let name pc = names[pc]

printfn "%s" (name (transpose 7 0))

// Partial application: give only the first argument, get a function back
let upAFifth = transpose 7
printfn "%s %s %s" (name (upAFifth 0)) (name (upAFifth 7)) (name (upAFifth 2))

// A negative number argument: the minus sign touches the number
printfn "%s" (name (transpose -1 0))

// Pipeline: x |> f is f x
printfn "%s" (0 |> upAFifth |> upAFifth |> upAFifth |> name)

// Composition: f >> g is fun x -> g (f x)
let fifthName = upAFifth >> name
printfn "%s" (fifthName 9)

// Lambda: fun pc -> ... is C#'s pc => ...
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

`[| … |]` is an array, and `names[pc]` indexes it. `name (transpose 7 0)` needs its parentheses: without them, `name transpose 7 0` would pass three arguments to `name`.

### Curried functions and partial application

`transpose` has the type `int -> int -> int`. Read the arrows from the right: `transpose` takes an `int` and returns a function `int -> int`. `transpose 7 0` is `(transpose 7) 0`. Functions that take their parameters one at a time like this are called **curried**, after the logician Haskell Curry.

So `transpose 7`, with one argument, is a complete value: a function that transposes up a fifth. That's **partial application**. The C# equivalent needs nested lambdas:

```csharp
Func<int, Func<int, int>> transpose = interval => pc => Normalize(pc + interval);
var upAFifth = transpose(7);
```

and Java has `Function<Integer, Function<Integer, Integer>>`. F# makes it the default way to write a function, which is why the order of parameters matters: the one you are most likely to fix goes first. `interval` comes before `pc`, so that `transpose 7` means something.

The C# habit of calling with parentheses and commas passes **one tuple** instead of two arguments:

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

`int * int` is the type of the tuple `(7, 0)`. Methods of .NET classes, on the other hand, are called with parentheses and commas: `name.Trim()`, `Regex.Replace(s, pattern, "")`. The next section shows where the two meet.

Spaces around a minus sign matter too. `transpose -1 0` passes `-1`, but `transpose - 1 0` subtracts:

```fsharp
printfn "%d" (transpose - 1 0)
```

```text
l02_minus_spaced.fsx(4,27): error FS0003: This value is not a function and cannot be applied.
```

F# reads `transpose - (1 0)`, and `1` is not a function that could be applied to `0`.

### Lambdas, `|>` and `>>`

- `fun pc -> transpose -1 pc` is a lambda, C#'s `pc => Transpose(-1, pc)`. Since `transpose -1` is already that function, `let downASemitone = transpose -1` would do the same.
- `x |> f` is `f x`: the **pipe** operator passes the value on its left to the function on its right. `0 |> upAFifth |> upAFifth |> upAFifth |> name` reads in the order the work happens, as a LINQ method chain does. It's defined in FSharp.Core as an ordinary function of two arguments, which calls the second with the first.
- `f >> g` is the **composition** of two functions: a new function that calls `f`, then `g` on the result.

TARS writes its text preprocessing as a pipeline, in [`TextNormalizer.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/TextNormalizer.fs#L71-L73):

```fsharp
    /// Extract keywords from text (normalize -> tokenize -> remove stop words -> dedup)
    let extractKeywords (text: string) =
        text |> normalize |> tokenize |> removeStopWords |> List.distinct
```

Each step is a function of the module that takes the result of the previous one; the comment and the code say the same thing, in the same order. Its first step, [`normalize`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/TextNormalizer.fs#L51-L58), mixes .NET methods (called with parentheses) and F# pipes, with lambdas in the middle:

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

- `(text: string)` is annotated because `text.ToLowerInvariant()` calls a method: F# needs to know the type of `text` before a `.`, since inference goes left to right.
- `@"…"` is a verbatim string, as in C#.
- `|> fun s -> …` pipes into a lambda, one per line.

The course's [`examples/l02_tars_normalize.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l02_tars_normalize.fsx) retypes this function (TARS has no license file, so the course doesn't copy the file) and runs it:

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

The pattern `[^a-z0-9\s]` removes everything that isn't an ASCII letter, a digit or a space. For an agent framework written in F#, that includes `#`: the keywords of "learn F#" are `learn` and `f`, and `C#` becomes the single letter `c`. Accented letters disappear from the middle of words: `café` becomes `caf`. TARS's [test](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/tests/Tars.Tests/TextNormalizerTests.fs#L6-L11) only uses an English sentence. The journal notes it; lesson 5 comes back to this module.

## Real code: curried members in GA

`HarmonicTransformationService` is a class (lesson 9), whose members are curried like the functions above. [Its `Transpose`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Services/HarmonicTransformationService.fs#L12-L16):

```fsharp
    /// <summary>
    /// Transposes a set of pitch classes.
    /// </summary>
    member _.Transpose (interval: Interval) (pcs: PitchClassSet) : PitchClassSet =
        pcs |> Set.map (fun pc -> normalize (pc + interval))
```

`Interval` and `PitchClassSet` are type abbreviations from [`MusicalSetTypes.fs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Types/MusicalSetTypes.fs#L8-L12): other names for `int` and `Set<int>`. `Set.map` applies the lambda to each element of the set. The `: PitchClassSet` after the parameters annotates the result.

The course loads GA's file with `#load` and calls it ([`examples/l02_ga_transformations.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l02_ga_transformations.fsx)):

```fsharp
// Guitar Alchemist's HarmonicTransformationService, loaded from the copies in external/ga
#load "../external/ga/MusicalSetTypes.fs" "../external/ga/HarmonicTransformationService.fs"

open GA.Business.DSL.Services

let service = HarmonicTransformationService()
let cMajor = set [ 0; 4; 7 ] // C E G

printfn "%A" (service.Transpose 7 cMajor) // up a fifth: G B D

let upAFifth = service.Transpose 7 // a method with curried parameters can be partially applied
printfn "%A" (cMajor |> upAFifth |> upAFifth) // D F# A

printfn "%A" (service.Invert 0 cMajor) // mirrored around C: C F Ab

// Compiled, the curried member is an ordinary .NET method with two parameters: C# calls Transpose(2, set)
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

The last two lines show how F# compiles a curried member: an ordinary method `Transpose(int interval, FSharpSet<int> pcs)`. GA's C# tests call it that way, in [`HarmonicTransformationTests.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Tests/Common/GA.Business.DSL.Tests/HarmonicTransformationTests.cs#L15-L18): `_service.Transpose(2, cMajor)`. Partial application stays on the F# side; lesson 20 is about designing F# APIs that C# consumes comfortably.

:::caution[What the course found]
The same class has a [`GetNormalForm`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Services/HarmonicTransformationService.fs#L35-L58) method, "a simplified normal order transposed to zero". A normal form must give the same answer for a chord and for its transpositions, but it doesn't:

```fsharp
let chord = set [ 0; 4; 7; 8 ]
printfn "%A" (service.GetNormalForm chord)
printfn "%A" (service.GetNormalForm(service.Transpose 8 chord))
```

```text
[0; 4; 7; 8]
[0; 3; 4; 8]
```

Two rotations of this set have the smallest span, 8 semitones, and `List.minBy fst` keeps whichever comes first, so the answer depends on where the set starts. The normal order also compares the inner intervals when spans are equal, which would pick `[0; 3; 4; 8]` both times. GitHub's code search found no caller of `GetNormalForm` in GA on 2026-09-15, so nothing uses the wrong answer yet. Details in the [journal](../journal/).
:::

## Key takeaways

- `let` gives a name to a value that never changes; `let mutable` and `<-` are the explicit exception, and `=` always compares.
- The compiler infers the types of values, parameters and results, and generalizes functions when it can (`'a`); one annotation is enough to steer it.
- Numbers never convert implicitly: `float`, `int` and `string` convert explicitly.
- `if`, blocks and `try` are expressions; `unit` and `()` replace `void`.
- Functions take their arguments separated by spaces and are curried: `transpose 7` is a function. `|>` pipes a value into a function, `>>` composes two functions, and `fun x -> …` is a lambda.

## Exercises

1. In equal temperament, each semitone multiplies the frequency by the twelfth root of 2, and A4 is 440 Hz. Write `frequency`, which takes the number of semitones from A4 (an `int`, negative below A4), and print the frequencies of A4, E4 (5 semitones below) and E2 (29 below) with two decimals.

<details>
<summary>Solution</summary>

[`exercises/l02_ex_frequency.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l02_ex_frequency.fsx):

```fsharp
// Equal temperament: each semitone multiplies the frequency by 2^(1/12), and A4 is 440 Hz
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

`float semitonesFromA4` is required: without it, `semitonesFromA4 / 12.0` is the error FS0001 of [No implicit conversions](#no-implicit-conversions). F# infers `frequency: semitonesFromA4: int -> float`.

</details>

2. Write `interval fromPc toPc`, the number of semitones to go *up* from one pitch class to another (from E, 4, to C, 0, is 8). Then define `fromE` by partial application, and use it on G (7), C (0) and, with `|>`, E (4).

<details>
<summary>Solution</summary>

[`exercises/l02_ex_partial.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l02_ex_partial.fsx):

```fsharp
let normalize pc = ((pc % 12) + 12) % 12

// Semitones to go up from one pitch class to another
let interval fromPc toPc = normalize (toPc - fromPc)

let fromE = interval 4 // partial application: int -> int

printfn "E up to G: %d semitones" (fromE 7)
printfn "E up to C: %d semitones" (fromE 0)
printfn "E up to E: %d semitones" (4 |> fromE)
```

```text
E up to G: 3 semitones
E up to C: 8 semitones
E up to E: 0 semitones
```

`0 - 4` is `-4`, and `normalize` turns it into 8: this is why GA's formula adds 12 before the second `% 12`.

</details>

3. This script has three mistakes. Run it, fix what F# reports, and run it again until it prints `capo on fret 3: frequencies multiplied by 1.1892`. How many runs did it take?

```fsharp
let capo = 2
capo <- 3
let ratio = 2.0 ** (capo / 12.0)
let label = if capo = 0 then "no capo"
```

<details>
<summary>Solution</summary>

Four runs: F# Interactive reports one mistake per run here. The first run:

```text
l02_ex_broken.fsx(2,1): error FS0027: This value is not mutable. Consider using the mutable keyword, e.g. 'let mutable capo = expression'.
```

After `let mutable capo = 2`, the second run:

```text
l02_ex_broken_step2.fsx(3,28): error FS0001: The type 'float' does not match the type 'int'
```

After `float capo`, the third run:

```text
l02_ex_broken_step3.fsx(4,30): error FS0001: This 'if' expression is missing an 'else' branch. Because 'if' is an expression, and not a statement, add an 'else' branch which also returns a value of type 'string'.
```

The fixed script ([`exercises/l02_ex_fixed.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/exercises/l02_ex_fixed.fsx)), with the `printfn` that the question asked for:

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

A capo on fret 3 raises every string by 3 semitones, and `2.0 ** (3.0 / 12.0)` is about 1.1892.

</details>

## Sources

- [Values](https://learn.microsoft.com/dotnet/fsharp/language-reference/values/), [`let` bindings](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/let-bindings)
- [Type inference](https://learn.microsoft.com/dotnet/fsharp/language-reference/type-inference), [automatic generalization](https://learn.microsoft.com/dotnet/fsharp/language-reference/generics/automatic-generalization)
- [Casting and conversions](https://learn.microsoft.com/dotnet/fsharp/language-reference/casting-and-conversions), [basic types](https://learn.microsoft.com/dotnet/fsharp/language-reference/basic-types)
- [Conditional expressions](https://learn.microsoft.com/dotnet/fsharp/language-reference/conditional-expressions-if-then-else), [unit type](https://learn.microsoft.com/dotnet/fsharp/language-reference/unit-type)
- [Functions](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/), [lambda expressions](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/lambda-expressions-the-fun-keyword), [FSharp.Core operators](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-operators.html)
- [Symbol and operator reference](https://learn.microsoft.com/dotnet/fsharp/language-reference/symbol-and-operator-reference/)
