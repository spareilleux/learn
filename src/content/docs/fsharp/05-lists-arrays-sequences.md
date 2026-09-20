---
title: "5. Lists, arrays and sequences"
description: Choose between immutable lists, mutable arrays and lazy sequences, then compose transformations with pipelines instead of loops.
sidebar:
  order: 5
---

C# has `List<T>`, arrays and `IEnumerable<T>`; Java has `List<T>`, arrays and `Stream<T>`. F# exposes the same trade-offs more explicitly through three collection families.

| F# type | Shape | Evaluation | Typical use |
|---|---|---|---|
| `'T list` | immutable linked list | eager | recursive algorithms, prepend-heavy transformations |
| `'T array` | mutable contiguous storage | eager | indexing, interop and performance-sensitive buffers |
| `seq<'T>` | `IEnumerable<T>` | lazy | streaming or computed-on-demand pipelines |

Official references: [`List`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-collections-listmodule.html), [`Array`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-collections-arraymodule.html) and [`Seq`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-collections-seqmodule.html).

## One pipeline, three storage models

From [`l05_collections.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l05_collections.fsx):

```fsharp
let openStrings = [ 40; 45; 50; 55; 59; 64 ]
let upTwoFrets = openStrings |> List.map ((+) 2)

let mutablePitches = openStrings |> List.toArray
mutablePitches[1] <- 46
```

`List.map` returns a new list. Array item assignment uses `<-`, the same mutation operator introduced in lesson 2. Converting is explicit because the cost and mutability change.

## Laziness is observable

```fsharp
let mutable evaluated = 0
let chromatic =
    seq {
        for pitch in 40 .. 44 do
            evaluated <- evaluated + 1
            yield pitch
    }
```

Measured output:

```text
before Seq.take: 0
first three: [40; 41; 42]
after Seq.take: 3
```

Creating a sequence executes nothing. `Seq.take 3 |> Seq.toList` pulls only three elements. Enumerating it again repeats the effects; use `Seq.cache` when repeated enumeration should reuse values, or materialize with `Seq.toArray`/`Seq.toList` when the input is finite.

## Transform, filter, choose, fold

- `map` changes every element.
- `filter` keeps elements satisfying a predicate.
- `choose` combines `Option`-producing mapping with filtering.
- `fold` carries explicit state from left to right.
- `collect` maps each input to a collection and flattens once.

```fsharp
let playedFrets = [ Some 0; None; Some 7; Some 9 ]
let played = playedFrets |> List.choose id
// [0; 7; 9]
```

Prefer the module matching the concrete collection (`List.map`, `Array.map`). `Seq.map` accepts every `IEnumerable<T>`, but it also makes an eager source lazy and can hide repeated work.

## Exercise

Given six optional fret positions, produce the sounding MIDI pitches while preserving string order. Use `List.choose`, not mutable accumulation. Then rewrite it as a lazy sequence and state when it is evaluated.

Continue with [modules and project organization](../06-modules-namespaces/).

