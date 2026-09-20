---
title: 8. Expresiones de cómputo — un parser para un DSL
description: Entender las expresiones seq, async y task, y construir una expresión de parsing donde let! encadena la gramática de un DSL de notas y Result transporta los errores.
sidebar:
  order: 8
---

Código: [`examples/l08_parser_ce.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l08_parser_ce.fsx), ejecutado por el harness del curso.

## Una sintaxis, varios tipos de cómputo

Una [expresión de cómputo](https://learn.microsoft.com/dotnet/fsharp/language-reference/computation-expressions) de F# tiene la forma `builder { ... }`. El builder decide qué significan `let!`, `do!`, `return`, `yield` y las demás palabras clave.

| Expresión | Cómputo descrito | Vecino aproximado en C#/Java |
|---|---|---|
| `seq { yield value }` | secuencia perezosa | iterador / `IEnumerable`, `Stream` |
| `async { let! value = work }` | workflow asíncrono de F# | composición de futures |
| `task { let! value = work }` | `Task` de .NET | `async`/`await`, `CompletableFuture` |
| `parser { let! value = rule }` | parser que consume texto o falla | pipeline de combinadores de parsing |

Esta sintaxis está dirigida por métodos ordinarios. Por ejemplo:

```fsharp
parser {
    let! value = rule
    return transform value
}
```

se traduce conceptualmente a:

```fsharp
parser.Bind(rule, fun value -> parser.Return(transform value))
```

`let!` no es una asignación ni es automáticamente asíncrono. Extrae el contexto elegido por el builder. `and!` representa cómputos independientes y requiere operaciones como `MergeSources`; nuestro parser es secuencial porque cada regla consume el resto que dejó la anterior.

## El tipo de cómputo

El ejemplo representa un parser como una función que recibe el texto no consumido y devuelve un valor con el resto, o un error:

```fsharp
type Parser<'value> =
    private
    | Parser of (string -> Result<'value * string, string>)
```

`bind` ejecuta el primer parser. Si falla conserva el error; si tiene éxito entrega el valor a la función que construye el siguiente parser y lo ejecuta sobre el texto restante:

```fsharp
let bind next parser =
    Parser(fun input ->
        match run parser input with
        | Error error -> Error error
        | Ok(value, rest) -> run (next value) rest)
```

El builder solo necesita tres miembros para la sintaxis usada aquí:

```fsharp
type ParserBuilder() =
    member _.Bind(parser, next) = Parser.bind next parser
    member _.Return(value) = Parser.result value
    member _.ReturnFrom(parser) = parser

let parser = ParserBuilder()
```

Agregar `Delay`, `Combine`, `TryWith`, `Using`, `While` o `MergeSources` habilitaría más construcciones. No las agregues por costumbre: los métodos del builder son su gramática pública.

## El DSL de notas

El script completo define reglas pequeñas para un literal, un carácter que satisface un predicado, una alteración opcional y el final del texto. La gramática expresa entonces su intención:

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

Salida medida:

```text
OK note C#4      -> C#4
OK note Eb3      -> Eb3
ERROR note H2    -> expected note letter A-G, got 'H'
ERROR note C#4 tail -> expected end of input, got " tail"
```

`do! Parser.endOfInput` es esencial. Sin él, `note C#4 tail` tendría éxito e ignoraría el sufijo, exactamente la clase de error de DSL registrada para el parser de acordes de GA en el [diario](../journal/#2026-09-15--dogfooding-guitar-alchemist).

## Hasta dónde construirlo uno mismo

Este parser didáctico no conserva línea y columna, no distingue un desacuerdo recuperable de un fallo comprometido y no implementa backtracking controlado. Para una gramática de producción, usa una biblioteca probada como [FParsec](https://www.quanttec.com/fparsec/) o un parser de proyecto con las mismas garantías. La expresión de cómputo sigue siendo útil porque hace visible la política de secuenciación y separa la gramática de la propagación de errores.

## Ejercicio

Escribe un parser para `octave 4`. Reutiliza `literal`, `satisfy` y `endOfInput`, y devuelve la octava como `int`. Comprueba que `octave 42` falla porque queda texto.

<details>
<summary>Solución</summary>

```fsharp
let octaveParser =
    parser {
        let! _ = Parser.literal "octave "
        let! digit = Parser.satisfy "octave 0-9" Char.IsDigit
        do! Parser.endOfInput
        return int (string digit)
    }
```

La regla de un dígito es deliberada. Admitir varios dígitos es una decisión nueva de gramática, no una razón para quitar la comprobación del final.

</details>

## Para recordar

- Una expresión de cómputo es sintaxis dirigida por un builder, no un sinónimo de código asíncrono.
- `let!` llama a `Bind`; `return` llama a `Return`; el builder define su efecto.
- Un builder de parsing reutiliza la secuenciación y la propagación de errores sin ocultar la gramática.
- Una regla explícita de final impide que un prefijo válido acepte un comando DSL inválido.
