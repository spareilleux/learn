---
title: "6. Módulos, namespaces y organización del proyecto"
description: Organizar código F# con namespaces, módulos, niveles de acceso, archivos de firma y el orden explícito de compilación del fsproj.
sidebar:
  order: 6
---

Un namespace da a los tipos un nombre .NET cualificado. Un módulo agrupa valores, funciones y tipos. Donde C# suele usar una clase estática, F# usa un módulo.

Referencias oficiales: [namespaces](https://learn.microsoft.com/dotnet/fsharp/language-reference/namespaces), [módulos](https://learn.microsoft.com/dotnet/fsharp/language-reference/modules), [control de acceso](https://learn.microsoft.com/dotnet/fsharp/language-reference/access-control) y [archivos de firma](https://learn.microsoft.com/dotnet/fsharp/language-reference/signature-files).

## Módulos anidados

De [`l06_modules.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l06_modules.fsx):

```fsharp
module Music =
    module Pitch =
        let private normalize pitchClass = ((pitchClass % 12) + 12) % 12

        let name pitchClass =
            [| "C"; "C#"; "D"; "Eb"; "E"; "F"; "F#"; "G"; "Ab"; "A"; "Bb"; "B" |]
            |> Array.item (normalize pitchClass)
```

`normalize` solo es visible dentro de `Pitch`; `Music.Pitch.name` es público. `internal` expone un miembro al assembly actual, no a consumidores. Usa la visibilidad más estrecha que permita probar el comportamiento público.

## ¿Namespace o módulo?

```fsharp
namespace GuitarAlchemist.Theory

module Pitch =
    let name pitchClass = ...

type Chord(root: int) =
    member _.Root = root
```

Un namespace no puede contener directamente bindings `let`. Un archivo entero puede comenzar con `module GuitarAlchemist.Theory.Pitch`.

## El orden de archivos es el orden de dependencias

F# compila los archivos de arriba abajo. Un archivo usa definiciones listadas antes, nunca después.

```xml
<ItemGroup>
  <Compile Include="Domain.fs" />
  <Compile Include="Parser.fs" />
  <Compile Include="Program.fs" />
</ItemGroup>
```

Esto hace visible la dirección de dependencias y evita ciclos accidentales.

## Archivos de firma

Un `.fsi` precede a su `.fs` y declara la superficie pública:

```fsharp
module GuitarAlchemist.Theory.Pitch

val name: pitchClass: int -> string
```

La implementación puede tener helpers invisibles. Las firmas son útiles en límites estables de biblioteca, pero costosas cuando cambia cada detalle interno; no las añadas mecánicamente a todo archivo.

## Ejercicio

Divide el script en `Pitch.fs`, `Chord.fs` y `Program.fs`, en ese orden. Añade `Pitch.fsi` que solo exponga `name` y confirma que llamar a `normalize` desde `Program.fs` falla al compilar.

Continúa con [errores y `Result`](../07-result-errors/).

