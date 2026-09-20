---
title: "7. Errores con Result"
description: Modelar fallos esperados como datos, componer validaciones con bind y reservar excepciones para límites excepcionales.
sidebar:
  order: 7
---

Una excepción sale del flujo normal. `Result<'ok,'error>` mantiene un fallo esperado en el tipo de retorno:

```fsharp
type Result<'ok, 'error> =
    | Ok of 'ok
    | Error of 'error
```

Referencias oficiales: el [módulo `Result`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-resultmodule.html) y el [manejo de excepciones](https://learn.microsoft.com/dotnet/fsharp/language-reference/exception-handling/).

## Validar en el límite

De [`l07_result.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l07_result.fsx):

```fsharp
type Fret = private Fret of int

module Fret =
    let create value =
        if value >= 0 && value <= 24 then Ok (Fret value)
        else Error $"fret {value} is outside 0..24"
```

El caso de unión privado impide construir `Fret -1`; los consumidores pasan por `Fret.create`. Una entrada inválida es un dato esperado, no un fallo excepcional del sistema.

## Analizar y después validar

```fsharp
let parseInt (text: string) =
    match System.Int32.TryParse text with
    | true, value -> Ok value
    | false, _ -> Error $"'{text}' is not an integer"

let parseFret text =
    text |> parseInt |> Result.bind Fret.create
```

`Result.bind` llama a la siguiente función solo para `Ok`; un `Error` pasa sin cambios. La anotación `string` importa en .NET 10: `Int32.TryParse` tiene sobrecargas para string, span de caracteres y span de bytes UTF-8. Sin anotación, F# emite FS0041.

Salida medida:

```text
OK 3 -> 3
ERROR -1 -> fret -1 is outside 0..24
ERROR x -> 'x' is not an integer
sum: Ok 10
```

- `Result.map` transforma un éxito con una función que no falla.
- `Result.bind` continúa con una función que devuelve otro `Result`.
- `Result.mapError` cambia la representación del error.
- un pattern matching final decide qué mostrar o devolver.

Reserva las excepciones para invariantes rotos, cancelación y límites de infraestructura que ya las lanzan. Captura de forma estrecha y traduce una sola vez a un error de dominio cuando recuperarse tenga sentido.

## Ejercicio

Analiza un fingering de seis elementos como `x 3 2 0 1 0`. Devuelve todos los errores de validación, no solo el primero: eso requiere validación aplicativa, no un simple `Result.bind`. Compara el compromiso antes de implementarlo.

Después, las [computation expressions](../08-computation-expressions/) eliminan el plumbing repetitivo de `bind` conservando el mismo camino de error.

