---
title: "5. Listas, arrays y secuencias"
description: Elegir entre listas inmutables, arrays mutables y secuencias perezosas, y componer transformaciones con pipelines.
sidebar:
  order: 5
---

C# tiene `List<T>`, arrays e `IEnumerable<T>`; Java, `List<T>`, arrays y `Stream<T>`. F# hace explícitos sus compromisos con tres familias.

| Tipo F# | Forma | Evaluación | Uso típico |
|---|---|---|---|
| `'T list` | lista enlazada inmutable | inmediata | recursión y transformaciones que añaden al inicio |
| `'T array` | almacenamiento contiguo mutable | inmediata | indexación, interop y buffers sensibles al rendimiento |
| `seq<'T>` | `IEnumerable<T>` | perezosa | streaming y cálculo bajo demanda |

Referencias oficiales: [`List`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-collections-listmodule.html), [`Array`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-collections-arraymodule.html) y [`Seq`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-collections-seqmodule.html).

## Un pipeline, tres almacenamientos

De [`l05_collections.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l05_collections.fsx):

```fsharp
let openStrings = [ 40; 45; 50; 55; 59; 64 ]
let upTwoFrets = openStrings |> List.map ((+) 2)

let mutablePitches = openStrings |> List.toArray
mutablePitches[1] <- 46
```

`List.map` devuelve una lista nueva. La asignación de un elemento del array usa `<-`. La conversión es explícita porque cambian el coste y la mutabilidad.

## La pereza es observable

```fsharp
let mutable evaluated = 0
let chromatic =
    seq {
        for pitch in 40 .. 44 do
            evaluated <- evaluated + 1
            yield pitch
    }
```

Salida medida:

```text
before Seq.take: 0
first three: [40; 41; 42]
after Seq.take: 3
```

Crear la secuencia no ejecuta nada. `Seq.take 3 |> Seq.toList` solo solicita tres elementos. Volver a enumerarla repite los efectos; usa `Seq.cache` para reutilizar valores o materializa una fuente finita con `Seq.toArray` o `Seq.toList`.

`map` transforma, `filter` selecciona, `choose` combina un mapeo a `Option` con filtrado, `fold` transporta estado explícito y `collect` mapea y aplana una vez.

```fsharp
let playedFrets = [ Some 0; None; Some 7; Some 9 ]
let played = playedFrets |> List.choose id
// [0; 7; 9]
```

Prefiere el módulo de la colección concreta. `Seq.map` acepta cualquier `IEnumerable<T>`, pero también vuelve perezosa una fuente inmediata y puede ocultar trabajo repetido.

## Ejercicio

A partir de seis trastes opcionales, produce los tonos MIDI que suenan conservando el orden de cuerdas. Usa `List.choose`, sin acumulación mutable. Después reescribe con una secuencia e indica cuándo se evalúa.

Continúa con [módulos y organización del proyecto](../06-modules-namespaces/).

