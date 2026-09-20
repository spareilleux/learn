---
title: 8. Computation expressions — a parser for a DSL
description: Understand seq, async and task expressions, then build a small parser computation expression where let! sequences the grammar of a note DSL and Result carries precise failures.
sidebar:
  order: 8
---

Code: [`examples/l08_parser_ce.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l08_parser_ce.fsx), executed by the course harness.

## One syntax, several kinds of computation

An F# [computation expression](https://learn.microsoft.com/dotnet/fsharp/language-reference/computation-expressions) has the form `builder { ... }`. The builder decides what `let!`, `do!`, `return`, `yield` and the other keywords mean.

| Expression | Computation being described | Rough C#/Java neighbour |
|---|---|---|
| `seq { yield value }` | lazy sequence | iterator / `IEnumerable`, `Stream` |
| `async { let! value = work }` | F# asynchronous workflow | composed futures |
| `task { let! value = work }` | .NET `Task` | `async`/`await`, `CompletableFuture` |
| `parser { let! value = rule }` | a parser that can consume input or fail | parser combinator pipeline |

This is syntax directed by ordinary methods. In particular:

```fsharp
parser {
    let! value = rule
    return transform value
}
```

is translated conceptually to:

```fsharp
parser.Bind(rule, fun value -> parser.Return(transform value))
```

`let!` is therefore not assignment and not automatically asynchronous. It unwraps the context chosen by the builder. `and!` represents independent computations and requires operations such as `MergeSources`; this lesson's parser is sequential because each grammar rule consumes the remainder left by the preceding rule.

## The computation type

The example represents a parser as a function from the unconsumed input to either a value plus the rest, or an error:

```fsharp
type Parser<'value> =
    private
    | Parser of (string -> Result<'value * string, string>)
```

`bind` runs the first parser. On failure it keeps the error; on success it gives the value to the function that builds the next parser and runs that parser on the remaining text:

```fsharp
let bind next parser =
    Parser(fun input ->
        match run parser input with
        | Error error -> Error error
        | Ok(value, rest) -> run (next value) rest)
```

The builder only needs three members for the syntax used here:

```fsharp
type ParserBuilder() =
    member _.Bind(parser, next) = Parser.bind next parser
    member _.Return(value) = Parser.result value
    member _.ReturnFrom(parser) = parser

let parser = ParserBuilder()
```

Adding `Delay`, `Combine`, `TryWith`, `Using`, `While` or `MergeSources` would enable more language constructs. Do not add them by habit: the methods of a builder are its public grammar.

## The note DSL

The complete script defines small rules for a literal, a character satisfying a predicate, an optional accidental and the end of the input. The actual grammar then reads like its intent:

```fsharp
let noteParser =
    parser {
        let! _ = Parser.literal "note "
        let! letter = Parser.satisfy "note letter A-G" (fun value -> value >= 'A' && value <= 'G')
        let! accidental = Parser.optionalChar [ '#'; 'b' ]
        let! octave = Parser.satisfy "octave 0-9" Char.IsDigit
        do! Parser.endOfInput

        let name =
            match accidental with
            | Some symbol -> $"{letter}{symbol}"
            | None -> string letter

        return { Name = name; Octave = int (string octave) }
    }
```

The measured output is:

```text
OK note C#4      -> C#4
OK note Eb3      -> Eb3
ERROR note H2    -> expected note letter A-G, got 'H'
ERROR note C#4 tail -> expected end of input, got " tail"
```

`do! Parser.endOfInput` is important. Without it, `note C#4 tail` would succeed and silently ignore the suffix — exactly the class of DSL bug recorded for GA's chord parser in the [journal](../journal/#2026-09-15--dogfooding-guitar-alchemist).

## Where to stop building it yourself

This teaching parser does not track line and column positions, distinguish a recoverable mismatch from a committed failure, or implement controlled backtracking. For a production grammar, use a tested library such as [FParsec](https://www.quanttec.com/fparsec/) or a project parser with the same guarantees. The computation expression is still useful: it exposes the sequencing policy and keeps the grammar separate from error propagation.

## Exercise

Write a parser for `octave 4`. Reuse `literal`, `satisfy` and `endOfInput`; return the octave as an `int`. Verify that `octave 42` fails because input remains.

<details>
<summary>Solution</summary>

```fsharp
let octaveParser =
    parser {
        let! _ = Parser.literal "octave "
        let! digit = Parser.satisfy "octave 0-9" Char.IsDigit
        do! Parser.endOfInput
        return int (string digit)
    }
```

The one-digit rule is intentional. Supporting several digits is a new grammar decision, not a reason to remove the end-of-input check.

</details>

## What to remember

- A computation expression is syntax controlled by a builder, not synonymous with async code.
- `let!` calls `Bind`; `return` calls `Return`; the builder defines their effect.
- A parser builder makes sequencing and failure propagation reusable, so the grammar stays visible.
- An explicit end-of-input rule prevents valid prefixes from accepting invalid DSL commands.
