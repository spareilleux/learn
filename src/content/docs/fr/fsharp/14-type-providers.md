---
title: 14. Type providers — des données typées à partir d'un échantillon
description: Utiliser les type providers CSV et JSON de FSharp.Data, distinguer l'inférence à la compilation des données d'exécution et décider quand un schéma externe stable appartient au système de types.
sidebar:
  order: 14
---

Code : [`examples/l14_type_providers.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l14_type_providers.fsx), exécuté par le harness avec FSharp.Data 8.2.0.

## Des types fournis au compilateur

Un [type provider](https://learn.microsoft.com/dotnet/fsharp/tutorials/type-providers/) F# est un composant du compilateur qui expose des types, propriétés et méthodes à partir d'une source d'information. Au lieu de lire une cellule CSV avec `row["strings"]` puis de la convertir, le compilateur peut proposer `row.Strings : int` grâce à un échantillon représentatif.

Ce n'est ni de la réflexion à l'exécution, ni une permission de laisser le schéma dériver silencieusement. L'échantillon est inspecté pendant le typage du script ou du projet ; les valeurs lues ensuite doivent toujours respecter cette forme. Microsoft recommande les type providers pour des espaces d'information dont le schéma reste stable pendant la durée de vie du code compilé.

## CSV : colonnes et types primitifs inférés

[`FSharp.Data`](https://fsprojects.github.io/FSharp.Data/) fournit des type providers pour CSV, JSON, XML et HTML. Le script épingle la version du package et garde l'échantillon dans le code afin que la compilation ne dépende pas d'un service réseau :

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

L'éditeur et le compilateur savent que `Name` et `Frets` sont des chaînes et que `Strings` est un entier. Renommer `row.Strings` en `row.StringCount` échoue à la compilation, car l'échantillon ne contient pas cette colonne.

```text
C major: 6 strings, frets x32010
D minor: 6 strings, frets xx0231
```

Pour de vraies données, conservez un petit échantillon révisé avec le code, puis appelez `Voicings.Load(pathOrUrl)` à l'exécution. Le contrat de compilation reste alors déterministe tandis que les données évoluent.

## JSON : une structure imbriquée typée

Le même mécanisme fonctionne pour un événement de gouvernance :

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

Le type imbriqué `Health` et le type des éléments du tableau sont également fournis. Un échantillon plus vaste ou hétérogène modifie l'inférence ; FSharp.Data accepte aussi un schéma explicite pour les champs importants.

## Providers effacés et génératifs

La documentation F# distingue deux modèles :

- un provider **effacé** expose ses types pendant la compilation, sans les émettre comme types .NET ordinaires dans l'assembly ;
- un provider **génératif** émet des types consommables par d'autres assemblies.

Les providers d'accès aux données de FSharp.Data utilisent le modèle effacé. Vous programmez contre la vue fournie, mais les valeurs d'exécution reposent sur des représentations sous-jacentes. À une frontière publique durable, mappez-les généralement vers vos propres records.

## Quand en utiliser un

Utilisez un type provider quand l'espace d'information externe est vaste, découvrable et assez stable pour que l'aide du compilateur retire du plumbing répétitif et fragile. Préférez un décodeur ordinaire avec validation quand les schémas varient par tenant, évoluent indépendamment à l'exécution ou doivent produire des erreurs métier précises.

| Question | Type provider | Décodeur + validation |
|---|---|---|
| Échantillon ou schéma stable à la compilation | excellent choix | fonctionne aussi |
| Dérive attendue à l'exécution | fragile | gestion explicite |
| Découverte interactive importante | excellente | manuelle |
| Modèle de domaine public | mapper vers vos records | déjà sous votre contrôle |

## Exercice

Ajoutez une colonne `difficulty` à l'échantillon CSV avec les valeurs `easy` et `medium`. Affichez-la pour chaque voicing. Écrivez ensuite volontairement `row.Dificulty` et constatez que la faute est rejetée avant l'exécution.

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

## À retenir

- Un type provider étend le typage à partir d'une source d'information externe stable.
- L'échantillon façonne la compilation ; les données d'exécution doivent encore respecter ce contrat.
- Épinglez le package et gardez les échantillons de compilation locaux et révisables.
- Mappez les valeurs fournies vers des records métier aux frontières publiques durables.
