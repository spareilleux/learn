---
title: 14. Type providers — typed data from a sample
description: Use FSharp.Data CSV and JSON type providers, understand compile-time inference versus runtime data, and decide when a stable external schema belongs in the type system.
sidebar:
  order: 14
---

Code: [`examples/l14_type_providers.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l14_type_providers.fsx), executed by the course harness with FSharp.Data 8.2.0.

## Types supplied to the compiler

An F# [type provider](https://learn.microsoft.com/dotnet/fsharp/tutorials/type-providers/) is a compiler component that exposes types, properties and methods from an information source. Instead of reading a CSV cell through `row["strings"]` and converting it yourself, the compiler can offer `row.Strings : int` from a representative sample.

This is not runtime reflection and it is not permission for the schema to change unnoticed. The sample is inspected while the script or project is type-checked; the program later reads values that must still fit that shape. Microsoft recommends type providers for information spaces whose schema is stable during the lifetime of the compiled code.

## CSV: inferred columns and primitive types

[`FSharp.Data`](https://fsprojects.github.io/FSharp.Data/) provides type providers for CSV, JSON, XML and HTML. The script pins the package version and keeps its sample inline so compilation does not depend on a network service:

```fsharp
#r "nuget: FSharp.Data, 8.2.0"

open FSharp.Data

type Voicings =
    CsvProvider<"""name,strings,frets
C major,6,x32010
D minor,6,xx0231""">

for row in Voicings.GetSample().Rows do
    printfn "%s: %d strings, frets %s" row.Name row.Strings row.Frets
```

The editor and compiler know that `Name` and `Frets` are strings and that `Strings` is an integer. Renaming `row.Strings` to `row.StringCount` fails at compile time because the sample has no such column.

```text
C major: 6 strings, frets x32010
D minor: 6 strings, frets xx0231
```

For real data, keep a small, reviewed sample with the source, then call `Voicings.Load(pathOrUrl)` at runtime. That separates a deterministic compile-time contract from the changing data being loaded.

## JSON: a typed nested shape

The same mechanism works for a governance event:

```fsharp
type GovernanceNode =
    JsonProvider<"""{
      "id": "ga.chord-parser",
      "health": { "resilienceScore": 0.98 },
      "tags": ["music", "dsl"]
    }""">

let node = GovernanceNode.GetSample()
printfn "%s: %.2f [%s]" node.Id node.Health.ResilienceScore (String.concat ", " node.Tags)
```

```text
ga.chord-parser: 0.98 [music, dsl]
```

The nested `Health` type and the array element type are provided too. A larger or heterogeneous sample changes what is inferred; for important fields, FSharp.Data also supports an explicit schema rather than relying only on examples.

## Erased and generative providers

The F# documentation distinguishes two implementation models:

- an **erased** provider exposes types during compilation, but those provided types are not emitted as ordinary .NET types in your assembly;
- a **generative** provider emits types that other assemblies can consume.

FSharp.Data's data-access providers use the erased model. You program against the provided view, while runtime values use underlying representations. That is why a public library boundary often benefits from mapping provider values into your own records.

## When to use one

Use a type provider when the external information space is large, discoverable and stable enough that compiler assistance removes repetitive, error-prone plumbing. Prefer an ordinary decoder plus validation when schemas are tenant-specific, evolve independently at runtime, or must produce domain-specific error messages.

| Question | Type provider | Decoder + validation |
|---|---|---|
| Stable sample or schema at build time | strong fit | also works |
| Runtime schema drift is expected | brittle | explicit handling |
| Interactive discovery matters | excellent | manual |
| Public domain model | map to your records | already yours |

## Exercise

Add a `difficulty` column to the CSV sample with values `easy` and `medium`. Print it for each voicing. Then deliberately write `row.Dificulty` and observe that the misspelling is rejected before the script runs.

<details>
<summary>Solution</summary>

```fsharp
type Voicings =
    CsvProvider<"""name,strings,frets,difficulty
C major,6,x32010,easy
D minor,6,xx0231,medium""">

for row in Voicings.GetSample().Rows do
    printfn "%s: %s" row.Name row.Difficulty
```

</details>

## What to remember

- A type provider extends type checking from a stable external information source.
- The sample shapes compilation; runtime data can still be different and must respect that contract.
- Pin the provider package and keep compile-time samples local and reviewable.
- Map provider values into domain records at durable public boundaries.
