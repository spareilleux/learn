---
title: "7. Errors with Result"
description: Model expected failure as data, compose validation with bind, and reserve exceptions for exceptional boundaries.
sidebar:
  order: 7
---

An exception jumps out of the normal control flow. `Result<'ok,'error>` keeps an expected failure in the function's return type:

```fsharp
type Result<'ok, 'error> =
    | Ok of 'ok
    | Error of 'error
```

Official references: the [`Result` module](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-resultmodule.html) and [F# error handling](https://learn.microsoft.com/dotnet/fsharp/language-reference/exception-handling/).

## Validate at the boundary

From [`l07_result.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l07_result.fsx):

```fsharp
type Fret = private Fret of int

module Fret =
    let create value =
        if value >= 0 && value <= 24 then Ok (Fret value)
        else Error $"fret {value} is outside 0..24"
```

The private union case means callers cannot construct `Fret -1`; they must use `Fret.create`. The error is expected input data, not an exceptional system failure.

## Parse, then validate

```fsharp
let parseInt (text: string) =
    match System.Int32.TryParse text with
    | true, value -> Ok value
    | false, _ -> Error $"'{text}' is not an integer"

let parseFret text =
    text |> parseInt |> Result.bind Fret.create
```

`Result.bind` calls the next function only for `Ok`; an `Error` passes through unchanged. This is railway-oriented programming without a special framework.

The `string` annotation is significant on .NET 10: `Int32.TryParse` has string, character-span and UTF-8 byte-span overloads. Without the annotation, F# reports FS0041 because it cannot choose an overload before seeing a caller.

Measured cases:

```text
OK 3 -> 3
ERROR -1 -> fret -1 is outside 0..24
ERROR x -> 'x' is not an integer
sum: Ok 10
```

## Map, bind and compose

- `Result.map f` transforms the successful value with a function that cannot fail.
- `Result.bind f` continues with a function returning another `Result`.
- `Result.mapError f` changes the error representation.
- pattern matching handles the final branch where the application must decide what to display or return.

Use exceptions for broken invariants, cancellation and infrastructure boundaries that already throw. Catch narrowly, translate once into a domain error when recovery is meaningful, and retain the original diagnostic for logs.

## Exercise

Parse a six-element fingering such as `x 3 2 0 1 0`. Return all validation errors rather than stopping at the first one. This requires an applicative validation shape, not ordinary `Result.bind`; compare the trade-off before implementing it.

Next, [computation expressions](../08-computation-expressions/) remove the repetitive bind plumbing from a parser while preserving the same error path.

