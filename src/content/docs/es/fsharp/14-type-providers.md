---
title: 14. Proveedores de tipos — datos tipados desde una muestra
description: Usar los proveedores CSV y JSON de FSharp.Data, distinguir la inferencia en compilación de los datos en ejecución y decidir cuándo un esquema externo estable pertenece al sistema de tipos.
sidebar:
  order: 14
---

Código: [`examples/l14_type_providers.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l14_type_providers.fsx), ejecutado por el harness con FSharp.Data 8.2.0.

## Tipos suministrados al compilador

Un [proveedor de tipos](https://learn.microsoft.com/dotnet/fsharp/tutorials/type-providers/) de F# es un componente del compilador que expone tipos, propiedades y métodos a partir de una fuente de información. En lugar de leer una celda CSV mediante `row["strings"]` y convertirla, el compilador puede ofrecer `row.Strings : int` desde una muestra representativa.

No es reflexión en ejecución ni permiso para que el esquema cambie sin aviso. La muestra se inspecciona cuando el script o proyecto se comprueba; los valores leídos después deben respetar esa forma. Microsoft recomienda los proveedores para espacios de información cuyo esquema es estable durante la vida del código compilado.

## CSV: columnas y tipos primitivos inferidos

[`FSharp.Data`](https://fsprojects.github.io/FSharp.Data/) ofrece proveedores para CSV, JSON, XML y HTML. El script fija la versión y conserva la muestra en el código para que la compilación no dependa de un servicio de red:

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

El editor y el compilador saben que `Name` y `Frets` son strings y que `Strings` es un entero. Cambiar `row.Strings` por `row.StringCount` falla al compilar porque la muestra no contiene esa columna.

```text
C major: 6 strings, frets x32010
D minor: 6 strings, frets xx0231
```

Para datos reales, guarda una muestra pequeña y revisada con el código y llama a `Voicings.Load(pathOrUrl)` en ejecución. Así el contrato de compilación es determinista y los datos pueden cambiar.

## JSON: una forma anidada y tipada

El mismo mecanismo funciona para un evento de gobernanza:

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

También se proporcionan el tipo anidado `Health` y el tipo de los elementos del array. Una muestra mayor o heterogénea cambia la inferencia; FSharp.Data permite además declarar un esquema explícito para campos importantes.

## Proveedores borrados y generativos

La documentación de F# distingue dos modelos:

- un proveedor **borrado** expone tipos durante la compilación, pero no los emite como tipos .NET ordinarios en el assembly;
- un proveedor **generativo** emite tipos que otros assemblies pueden consumir.

Los proveedores de acceso a datos de FSharp.Data usan el modelo borrado. Programas contra la vista proporcionada, mientras los valores de ejecución usan representaciones subyacentes. En un límite público duradero suele convenir mapearlos a tus propios records.

## Cuándo usar uno

Usa un proveedor cuando el espacio de información externo sea grande, descubrible y suficientemente estable para que la ayuda del compilador elimine plumbing repetitivo. Prefiere un decoder ordinario con validación cuando los esquemas cambien por tenant, evolucionen en ejecución o deban producir errores de dominio precisos.

| Pregunta | Proveedor de tipos | Decoder + validación |
|---|---|---|
| Muestra o esquema estable al compilar | muy apropiado | también funciona |
| Se espera deriva en ejecución | frágil | gestión explícita |
| Importa la exploración interactiva | excelente | manual |
| Modelo de dominio público | mapear a records propios | ya es tuyo |

## Ejercicio

Agrega una columna `difficulty` a la muestra CSV con los valores `easy` y `medium`. Imprímela para cada voicing. Escribe después `row.Dificulty` deliberadamente y observa que el error se rechaza antes de ejecutar.

<details>
<summary>Solución</summary>

```fsharp
type Voicings =
    CsvProvider<"""name,strings,frets,difficulty
C major,6,x32010,easy
D minor,6,xx0231,medium""">

for row in Voicings.GetSample().Rows do
    printfn "%s: %s" row.Name row.Difficulty
```

</details>

## Para recordar

- Un proveedor de tipos extiende el tipado desde una fuente de información externa estable.
- La muestra da forma a la compilación; los datos de ejecución deben respetar ese contrato.
- Fija la versión del paquete y conserva muestras locales y revisables.
- Mapea los valores proporcionados a records de dominio en límites públicos duraderos.
