---
title: 4. Pattern matching
description: match next to C#'s switch expression and Java's pattern switch — constants, or-patterns, guards, tuples, union cases, records and lists, the warnings for incomplete and unreachable rules, and what matching found in GA's chord parser and BinObj script.
sidebar:
  order: 4
---

Code: the scripts [`examples/l04_*.fsx`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples) and the rejected snippet [`compile_fail/l04_warnaserror.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/compile_fail/l04_warnaserror.fsx).

## `match` is a `switch` expression

C# 8 added the `switch` expression, and C# 9 its relational and `or` patterns:

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

Java 21 has `switch` with patterns and `when` guards. F#'s [`match`](https://learn.microsoft.com/dotnet/fsharp/language-reference/match-expressions) is the construct these were modeled on:

```fsharp
// match tries the patterns from top to bottom; the first one that fits wins
let intervalName semitones =
    match semitones with
    | 0 -> "unison"
    | 3 | 4 -> "third" // or-pattern
    | 7 -> "perfect fifth"
    | 12 -> "octave"
    | n when n > 12 -> $"compound interval ({n - 12} above an octave)" // guard
    | _ -> "other" // wildcard

for semitones in [ 0; 4; 7; 10; 19 ] do
    printfn "%d: %s" semitones (intervalName semitones)

// A tuple matches several values at once
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

- Each rule is `| pattern -> expression`. The rules are tried in order, and the value of the `match` is the expression of the first rule that fits. Like `if`, `match` is an expression: all its branches have the same type.
- `3 | 4` is an **or-pattern**, C#'s `3 or 4`.
- `n when n > 12` **binds** the value to `n`, then a **guard** tests it. F# has no relational patterns like C#'s `> 12`: a guard does the same job.
- `_` matches anything, like C#'s discard.
- `match stringNumber, fret with` matches a tuple. `_, 0` means "any string, fret 0"; `(5 | 6), f` nests an or-pattern inside the tuple pattern and binds the fret.

## Union cases and options

Patterns really pay off with [discriminated unions](../03-records-unions-options/#discriminated-unions): a pattern can test the case and take its data apart in one step.

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
    | Fretted 1 -> "first fret" // a case with a constant inside
    | Fretted fret -> $"fret {fret}" // a case that binds its data
    | Barre(fret, 6) -> $"full barre on fret {fret}"
    | Barre(fret = f; strings = n) -> $"barre on fret {f} across {n} strings" // by field name

for fingering in [ Open; Muted; Fretted 1; Fretted 5; Barre(1, 6); Barre(3, 4) ] do
    printfn "%s" (describe fingering)

// Option is a union too: Some and None are its cases
let capoLabel capo =
    match capo with
    | None
    | Some 0 -> "no capo"
    | Some fret -> $"capo on fret {fret}"

printfn "%s, %s, %s" (capoLabel None) (capoLabel (Some 0)) (capoLabel (Some 2))

// function is fun x -> match x with, as in Guitar Alchemist's ChordRenderer
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

- `Fretted 1` matches only the value `Fretted 1`; `Fretted fret` matches any `Fretted` and names its data `fret`. Order matters: swapped, `Fretted fret` would catch `Fretted 1` first.
- `Barre(fret = f; strings = n)` matches the fields by name, separated by `;`.
- An or-pattern can span two lines, as `None` and `Some 0` do.
- `function` is a shortcut for a lambda that matches its argument immediately: `let isPlayed = function | … ` is `let isPlayed x = match x with | …`.

The C# version of `describe` would use type patterns on a record hierarchy (`Fretted { Fret: 1 } => …`, `Fretted f => …`). It looks alike, and it is, with one difference that the next section is about.

### Real code: GA's chord renderer

GA's [`ChordRenderer.fs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Generators/ChordRenderer.fs#L5-L40) turns the `ChordAst` of lesson 3 back into text. It's almost entirely pattern matching:

```fsharp
module ChordRenderer =
    let renderAccidental =
        function
        | Natural -> ""
        | Sharp -> "#"
        | Flat -> "b"
        | DoubleSharp -> "##"
        | DoubleFlat -> "bb"

    // (renderQuality, lines 14-21, has the same shape)

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

- `renderAccidental` is a `function` with one rule per case of `AccidentalType`, and no `_`: if GA adds a triple sharp one day, the compiler will point at this function.
- `Alteration(acc, deg)` takes apart the tuple carried by the case.
- `Some(n, acc)` nests a tuple pattern inside the `Some` pattern: it matches a bass note and names its letter and accidental in one step.
- `List.map renderComponent` applies the function to each component; lesson 5 is about `List`.

## The compiler checks that every case is handled

Here is a `match` that forgets two cases:

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

The compiler knows every case of `Accidental`, and names one that no rule covers. It's a warning, so the script runs, and fails at run time with a `MatchFailureException` when `DoubleFlat` actually arrives (F# Interactive also prints the stack trace, which the course's `check.sh` removes).

C# warns too, but it can't be as precise. A `switch` expression over the `Fingering` record hierarchy of lesson 3 that handles `Open`, `Fretted` and `Muted`, all three subclasses, still gets `warning CS8509: … For example, the pattern '_' is not covered`: another assembly could add a subclass. Over an enum that lists every named value, it gets CS8524, because `(Accidental)3` is a valid value too. So C# code ends with a `_ =>` arm, which silences the warning for good (the [journal](../journal/#2026-09-15--c-comparisons) has the two files). Java 21 does check a `switch` over a `sealed` interface, and rejects a missing case. F# unions are closed like Java's sealed types, and F# checks every pattern: tuples of unions, nested options, lists.

A warning that lets the program crash later should be an error. In a project, `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`, or `<WarningsAsErrors>FS0025</WarningsAsErrors>` for this warning only, does that for the whole build; TARS sets the first one in [`v2/Directory.Build.props`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/Directory.Build.props#L3), GA doesn't. For a script, `dotnet fsi` takes the [compiler option](https://learn.microsoft.com/dotnet/fsharp/language-reference/compiler-options) `--warnaserror+:25`:

```text
> dotnet fsi --warnaserror+:25 compile_fail/l04_warnaserror.fsx
l04_warnaserror.fsx(10,11): error FS0025: Incomplete pattern matches on this expression. For example, the value 'DoubleFlat' may indicate a case not covered by the pattern(s).
```

### Guards defeat the check

The compiler can't evaluate a guard. These three rules cover every integer, but only a reader can see it:

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

This time the message gives no example: the compiler doesn't know which value escapes. Write the last rule without a guard, `| _ -> "same note"`, and the warning goes away.

### Rules that never match

Rules are tried in order, so a rule after a pattern that catches everything is dead code:

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

### Wildcards hide new cases

`_` is convenient and dangerous in the same way as C#'s `default`. The `isPlayed` function above uses `| _ -> true` for three cases; if a fifth case `Harmonic of fret: int` is added to `Fingering`, `isPlayed` silently answers `true` for it, and no warning appears. `renderAccidental` in GA, with a rule for each case, would get the warning. Prefer listing the cases in a union whose list may grow; keep `_` for open sets of values like integers and strings.

## List patterns and recursion

A list is either empty, `[]`, or an element followed by the rest of the list, `head :: tail`. Patterns take lists apart along those two shapes:

```fsharp
// List patterns: [] is the empty list, head :: tail splits off the first element
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

// A recursive function (rec) walks the list one element at a time
let rec total frets =
    match frets with
    | [] -> 0
    | fret :: rest -> fret + total rest

printfn "%d" (total [ 3; 2; 0; 1; 0 ])

// Patterns also work in let and in parameters
let (note, octave) = ("A", 4)
let lowest (first :: _) = first // warning: [] is not handled
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

- `[ single ]` matches a list of exactly one element, `[ low; high ]` of exactly two.
- `lowest :: rest` matches any non-empty list. Placed first, it would catch the one- and two-element lists too.
- A function that calls itself needs [`rec`](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/recursive-functions-the-rec-keyword). `total` is the classic shape: a rule for the empty list, and a rule that handles one element and recurses on the rest. Lesson 5 shows the library functions that save you from writing most of these.
- Patterns aren't only for `match`. `let (note, octave) = …` takes a tuple apart, and `let describeAgent (AgentId id) = …` in lesson 3 unwrapped a single-case union in a parameter. They are checked too: `lowest (first :: _)` gets FS0025, since an empty list has no first element.

### Real code: GA's BinObj script

GA's [`Scripts/BinObj.fsx`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Scripts/BinObj.fsx) looks for the `bin` and `obj` folders of a source tree, with a recursive function over a list:

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

- `match EnumerateDirectories path with | [] -> [] | subfolders -> …` handles a folder without subfolders, then binds the non-empty list to a name.
- `isObjOrBinFolder >> not` composes the test with `not`, the [composition of lesson 2](../02-values-and-functions/#lambdas--and-): "is not a bin or obj folder".
- `List.collect getFoldersToDelete` recurses into each remaining subfolder and concatenates the results.

The course loads the script and runs its function on a small tree ([`examples/l04_ga_binobj.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l04_ga_binobj.fsx)):

```fsharp
// A small tree in the temporary folder
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

:::caution[What the course found]
The patterns are right; the test isn't. `EnumerateDirectories` returns full paths, and `EndsWith("bin", true, …)` is true for any folder whose name *ends* with those letters, ignoring case: `Docs/cabin` and `Robin` are selected, and `Robin/Songs` isn't even visited. Comparing the folder name exactly, `Path.GetFileName folderName` against `"bin"` and `"obj"`, would fix it. The script defines the functions but never calls them, so running `dotnet fsi Scripts/BinObj.fsx` does nothing and deletes nothing. Details in the [journal](../journal/).
:::

## Real code: matching on `Result` in GA's chord parser

GA's [`ChordParser.parse`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.DSL/Parsers/ChordParser.fs#L86-L89) runs an FParsec parser and converts its result, a union of FParsec, into F#'s `Result`:

```fsharp
    let parse chordStr =
        match run pChord chordStr with
        | Success(result, _, _) -> Result.Ok result
        | Failure(errorMsg, _, _) -> Result.Error errorMsg
```

`Success(result, _, _)` binds the first of three values and ignores the other two. The course loads the parser and matches on the `Result` it returns ([`examples/l04_ga_parse.fsx`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/examples/l04_ga_parse.fsx)):

```fsharp
#r "nuget: FParsec, 1.1.1"
#load "../external/ga/ChordAst.fs" "../external/ga/ChordRenderer.fs" "../external/ga/ChordParser.fs"

open GA.Business.DSL.Parsers
open GA.Business.DSL.Generators

// Guitar Alchemist's ChordParser.parse returns a Result: Ok with the AST, or Error with FParsec's message
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

The first three lines are cases of GA's own test, [`ChordDslTests.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Tests/Common/GA.Business.DSL.Tests/ChordDslTests.cs#L11-L18). `H7`, the German name of B7, is rejected with FParsec's message.

:::caution[What the course found]
`C7sus4` becomes `C7`, and `Am(maj7)` becomes `Am`: the parser stops at the first character it doesn't understand, and `parse` returns `Ok` with what it read so far. The parser is never told that the input must end there (FParsec's `eof`), so the rest is silently dropped. `ChordDslService.Parse` and `Normalize` inherit the behavior, and so does the C# [`ResponseValidator`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Common/GA.Business.Core.Orchestration/Services/ResponseValidator.cs#L30-L38) of GA's chatbot, which calls `Parse` on each chord-like word of an answer and only looks at whether it succeeded. Lesson 11 comes back to it with FParsec; the [journal](../journal/) has the details.
:::

## Key takeaways

- `match value with | pattern -> result` tries the rules in order and is an expression; `function` is a lambda that matches its argument.
- Patterns combine: constants, `_`, `|` for alternatives, `when` guards, tuples, union cases with their data, fields by name, `[]` and `head :: tail` for lists.
- The compiler warns when a case is missing (FS0025) or a rule can't be reached (FS0026); make FS0025 an error in projects, and avoid `_` on unions that may grow.
- Guards aren't analyzed: the last rule of a guarded match should have no guard.
- Patterns work in `let` and in parameters too, with the same checks.

## Exercises

1. Write `quality semitones`, which returns `"perfect"` for 0, 5, 7 and 12, `"minor"` for 1, 3, 8 and 10, `"major"` for 2, 4, 9 and 11, `"tritone"` for 6, a message for negative numbers, and another for intervals larger than an octave. Use or-patterns and one guard, and print the result for -3, 0, 3, 4, 6, 7, 11 and 14.

<details>
<summary>Solution</summary>

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

The guard comes first, so the negative numbers don't need to be excluded later. The final `_` is right here: the integers are an open set, and every value above 12 deserves the same answer. `%3d` pads the number to three characters.

</details>

2. Fix the `symbol` function of [The compiler checks that every case is handled](#the-compiler-checks-that-every-case-is-handled) so that the script prints `C#` and `Cbb` without a warning. Why not add `| _ -> ""`?

<details>
<summary>Solution</summary>

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

`| _ -> ""` also removes the warning, but prints `C` for a double flat: a wrong answer instead of an error. And the next case added to `Accidental` would get the same wrong answer, with no warning to point at this function.

</details>

3. GA's test `Test_Complex_Alterations` parses `C13#11b9` and expects three components. Write a recursive function `countAlterations` over a `ChordComponent list`, with list patterns, that counts the `Alteration` and `Alt` components, and use it on the result of GA's parser for that chord.

<details>
<summary>Solution</summary>

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

// The chord of GA's test Test_Complex_Alterations (Tests/Common/GA.Business.DSL.Tests/ChordDslTests.cs)
match ChordParser.parse "C13#11b9" with
| Ok chord -> printfn "%A: %d alterations" chord.Components (countAlterations chord.Components)
| Error message -> printfn "%s" message
```

```text
[Extension "13"; Alteration (Sharp, "11"); Alteration (Flat, "9")]: 2 alterations
```

`(Alteration _ | Alt) :: rest` puts an or-pattern inside the head of a list pattern; `Alteration _` ignores the data of the case. Both sides of an or-pattern must bind the same names, here only `rest`, outside the parentheses.

</details>

## Sources

- [Match expressions](https://learn.microsoft.com/dotnet/fsharp/language-reference/match-expressions), [pattern matching](https://learn.microsoft.com/dotnet/fsharp/language-reference/pattern-matching)
- [Recursive functions: the `rec` keyword](https://learn.microsoft.com/dotnet/fsharp/language-reference/functions/recursive-functions-the-rec-keyword), [lists](https://learn.microsoft.com/dotnet/fsharp/language-reference/lists)
- [Compiler options](https://learn.microsoft.com/dotnet/fsharp/language-reference/compiler-options) (`--warnaserror`)
- C#: [the `switch` expression](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression), [patterns](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/patterns); Java: [pattern matching for `switch`](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html)
- [FParsec: running parsers](https://www.quanttec.com/fparsec/users-guide/parser-functions.html)
