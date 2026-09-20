---
title: "6. Modules, namespaces et organisation du projet"
description: Organiser du code F# avec namespaces, modules, niveaux d’accès, fichiers de signature et ordre de compilation explicite du fsproj.
sidebar:
  order: 6
---

Un namespace donne un nom .NET qualifié aux types. Un module regroupe valeurs, fonctions et types. Là où C# utilise souvent une classe statique, F# utilise un module.

Références officielles : [namespaces](https://learn.microsoft.com/dotnet/fsharp/language-reference/namespaces), [modules](https://learn.microsoft.com/dotnet/fsharp/language-reference/modules), [contrôle d’accès](https://learn.microsoft.com/dotnet/fsharp/language-reference/access-control) et [fichiers de signature](https://learn.microsoft.com/dotnet/fsharp/language-reference/signature-files).

## Modules imbriqués

Extrait de [`l06_modules.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l06_modules.fsx) :

```fsharp
module Music =
    module Pitch =
        let private normalize pitchClass = ((pitchClass % 12) + 12) % 12

        let name pitchClass =
            [| "C"; "C#"; "D"; "Eb"; "E"; "F"; "F#"; "G"; "Ab"; "A"; "Bb"; "B" |]
            |> Array.item (normalize pitchClass)
```

`normalize` n’est visible que dans `Pitch` ; `Music.Pitch.name` est public. `internal` expose un membre à l’assembly courant, mais pas aux consommateurs. Choisis la visibilité la plus étroite permettant de tester le comportement public.

## Namespace ou module ?

```fsharp
namespace GuitarAlchemist.Theory

module Pitch =
    let name pitchClass = ...

type Chord(root: int) =
    member _.Root = root
```

Un namespace ne peut pas contenir directement de bindings `let`. Un fichier entier peut commencer par `module GuitarAlchemist.Theory.Pitch`.

## L’ordre des fichiers est l’ordre des dépendances

F# compile les fichiers de haut en bas. Un fichier utilise les définitions listées avant lui, jamais celles qui suivent.

```xml
<ItemGroup>
  <Compile Include="Domain.fs" />
  <Compile Include="Parser.fs" />
  <Compile Include="Program.fs" />
</ItemGroup>
```

Cela rend la direction des dépendances visible et empêche les cycles accidentels.

## Fichiers de signature

Un `.fsi` précède son `.fs` et déclare la surface publique :

```fsharp
module GuitarAlchemist.Theory.Pitch

val name: pitchClass: int -> string
```

L’implémentation peut garder d’autres helpers invisibles. Les signatures sont utiles aux frontières stables d’une bibliothèque, mais coûteuses lorsque tous les détails internes évoluent ; ne les ajoute pas mécaniquement partout.

## Exercice

Sépare le script en `Pitch.fs`, `Chord.fs` et `Program.fs`, dans cet ordre. Ajoute `Pitch.fsi` qui n’expose que `name`, puis vérifie qu’un appel à `normalize` depuis `Program.fs` échoue à la compilation.

Continue avec [les erreurs et `Result`](../07-result-errors/).

