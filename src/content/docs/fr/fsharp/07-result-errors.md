---
title: "7. Les erreurs avec Result"
description: Modéliser les échecs attendus comme des données, composer les validations avec bind et réserver les exceptions aux frontières exceptionnelles.
sidebar:
  order: 7
---

Une exception sort du flux normal. `Result<'ok,'error>` garde un échec attendu dans le type de retour :

```fsharp
type Result<'ok, 'error> =
    | Ok of 'ok
    | Error of 'error
```

Références officielles : le [module `Result`](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-resultmodule.html) et la [gestion des exceptions](https://learn.microsoft.com/dotnet/fsharp/language-reference/exception-handling/).

## Valider à la frontière

Extrait de [`l07_result.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l07_result.fsx) :

```fsharp
type Fret = private Fret of int

module Fret =
    let create value =
        if value >= 0 && value <= 24 then Ok (Fret value)
        else Error $"fret {value} is outside 0..24"
```

Le cas d’union privé empêche de construire `Fret -1`. Les appelants passent par `Fret.create`. Une saisie invalide est une donnée attendue, pas une panne exceptionnelle du système.

## Parser, puis valider

```fsharp
let parseInt (text: string) =
    match System.Int32.TryParse text with
    | true, value -> Ok value
    | false, _ -> Error $"'{text}' is not an integer"

let parseFret text =
    text |> parseInt |> Result.bind Fret.create
```

`Result.bind` n’appelle la fonction suivante que pour `Ok` ; une `Error` traverse inchangée. L’annotation `string` compte avec .NET 10 : `Int32.TryParse` possède des surcharges pour chaîne, span de caractères et span d’octets UTF-8. Sans annotation, F# émet FS0041.

Sortie mesurée :

```text
OK 3 -> 3
ERROR -1 -> fret -1 is outside 0..24
ERROR x -> 'x' is not an integer
sum: Ok 10
```

- `Result.map` transforme une réussite avec une fonction qui ne peut échouer.
- `Result.bind` poursuit avec une fonction qui renvoie un autre `Result`.
- `Result.mapError` change la représentation de l’erreur.
- un pattern matching final décide quoi afficher ou renvoyer.

Garde les exceptions pour les invariants rompus, l’annulation et les frontières d’infrastructure qui en lancent déjà. Intercepte étroitement et traduis une seule fois vers une erreur métier lorsque la récupération a un sens.

## Exercice

Parse un fingering à six éléments tel que `x 3 2 0 1 0`. Renvoie toutes les erreurs de validation plutôt que la première : cela demande une validation applicative, pas un simple `Result.bind`. Compare ce compromis avant l’implémentation.

Ensuite, les [computation expressions](../08-computation-expressions/) retirent le plumbing répétitif de `bind` tout en conservant le même chemin d’erreur.

