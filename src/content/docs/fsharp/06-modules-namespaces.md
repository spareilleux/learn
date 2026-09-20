---
title: "6. Modules, namespaces and project organization"
description: Organize F# code with namespaces, modules, access modifiers, signature files and the explicit compilation order of an fsproj.
sidebar:
  order: 6
---

A namespace gives .NET types a qualified name. A module groups values, functions and types. C# developers often reach for a static class where F# uses a module.

Official references: [namespaces](https://learn.microsoft.com/dotnet/fsharp/language-reference/namespaces), [modules](https://learn.microsoft.com/dotnet/fsharp/language-reference/modules), [access control](https://learn.microsoft.com/dotnet/fsharp/language-reference/access-control) and [signature files](https://learn.microsoft.com/dotnet/fsharp/language-reference/signature-files).

## Nested modules

From [`l06_modules.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l06_modules.fsx):

```fsharp
module Music =
    module Pitch =
        let private normalize pitchClass = ((pitchClass % 12) + 12) % 12

        let name pitchClass =
            [| "C"; "C#"; "D"; "Eb"; "E"; "F"; "F#"; "G"; "Ab"; "A"; "Bb"; "B" |]
            |> Array.item (normalize pitchClass)
```

`normalize` is visible only inside `Pitch`; `Music.Pitch.name` is public. `internal` exposes a member to the current assembly but not to consumers. Use the narrowest visibility that supports tests through public behavior.

## Namespace or module?

```fsharp
namespace GuitarAlchemist.Theory

module Pitch =
    let name pitchClass = ...

type Chord(root: int) =
    member _.Root = root
```

A namespace cannot directly contain `let` bindings; put them in a module. A file can begin with `module GuitarAlchemist.Theory.Pitch` when the entire file is one module.

## File order is dependency order

F# compiles project files top to bottom. A file may use definitions from files listed before it, never after it.

```xml
<ItemGroup>
  <Compile Include="Domain.fs" />
  <Compile Include="Parser.fs" />
  <Compile Include="Program.fs" />
</ItemGroup>
```

This makes dependency direction visible and prevents accidental cycles. Reordering files in the IDE changes the project file and can change whether it compiles.

## Signature files

A `.fsi` file precedes the matching `.fs` file and declares the public surface:

```fsharp
// Pitch.fsi
module GuitarAlchemist.Theory.Pitch

val name: pitchClass: int -> string
```

The implementation may contain helpers that consumers cannot see. Signature files are useful at stable library boundaries, but expensive when every internal function changes; do not add them mechanically to every file.

## Exercise

Split the lesson script into `Pitch.fs`, `Chord.fs` and `Program.fs`, list them in dependency order, then add `Pitch.fsi` exposing only `name`. Confirm that trying to call `normalize` from `Program.fs` fails at compile time.

Continue with [errors and `Result`](../07-result-errors/).

