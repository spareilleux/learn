---
title: "5. Listes, tableaux et séquences"
description: Choisir entre listes immuables, tableaux mutables et séquences paresseuses, puis composer les transformations avec des pipelines.
sidebar:
  order: 5
---

C# possède `List<T>`, les tableaux et `IEnumerable<T>` ; Java, `List<T>`, les tableaux et `Stream<T>`. F# rend leurs compromis explicites avec trois familles.

| Type F# | Forme | Évaluation | Usage typique |
|---|---|---|---|
| `'T list` | liste chaînée immuable | immédiate | récursion et transformations qui ajoutent en tête |
| `'T array` | stockage contigu mutable | immédiate | indexation, interop et buffers performants |
| `seq<'T>` | `IEnumerable<T>` | paresseuse | flux et calcul à la demande |

Références officielles : [`List`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-collections-listmodule.html), [`Array`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-collections-arraymodule.html) et [`Seq`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-collections-seqmodule.html).

## Un pipeline, trois stockages

Extrait de [`l05_collections.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l05_collections.fsx) :

```fsharp
let openStrings = [ 40; 45; 50; 55; 59; 64 ]
let upTwoFrets = openStrings |> List.map ((+) 2)

let mutablePitches = openStrings |> List.toArray
mutablePitches[1] <- 46
```

`List.map` renvoie une nouvelle liste. L’affectation dans un tableau utilise `<-`. La conversion est explicite parce que le coût et la mutabilité changent.

## La paresse est observable

```fsharp
let mutable evaluated = 0
let chromatic =
    seq {
        for pitch in 40 .. 44 do
            evaluated <- evaluated + 1
            yield pitch
    }
```

Sortie mesurée :

```text
before Seq.take: 0
first three: [40; 41; 42]
after Seq.take: 3
```

Créer la séquence n’exécute rien. `Seq.take 3 |> Seq.toList` ne tire que trois éléments. Une nouvelle énumération répète les effets ; utilise `Seq.cache` pour réutiliser les valeurs, ou matérialise une source finie avec `Seq.toArray` ou `Seq.toList`.

`map` transforme, `filter` sélectionne, `choose` combine un mapping vers `Option` et le filtrage, `fold` transporte un état explicite, et `collect` mappe puis aplatit une fois.

```fsharp
let playedFrets = [ Some 0; None; Some 7; Some 9 ]
let played = playedFrets |> List.choose id
// [0; 7; 9]
```

Préfère le module de la collection concrète. `Seq.map` accepte tout `IEnumerable<T>`, mais rend aussi une source immédiate paresseuse et peut masquer un travail répété.

## Exercice

À partir de six frettes optionnelles, produis les hauteurs MIDI jouées en conservant l’ordre des cordes. Utilise `List.choose`, sans accumulation mutable. Réécris ensuite avec une séquence et indique quand elle est évaluée.

Continue avec [les modules et l’organisation du projet](../06-modules-namespaces/).

