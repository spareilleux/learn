---
title: 14. Minimal APIs y controladores
description: Comparar binding de route handlers, endpoint filters, TypedResults, controladores y respuestas IAsyncEnumerable en streaming dentro de una sola tabla de routing.
sidebar:
  order: 14
---

Las [Minimal APIs](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis) y los [controladores](https://learn.microsoft.com/aspnet/core/web-api/) publican endpoints mediante endpoint routing. Elige según composición, no por eslóganes.

## El binding es un contrato público

Un handler liga route, query, headers, servicios y body desde parámetros. Haz explícita la fuente cuando la ambigüedad sea peligrosa.

```text
without key: 400; with key: 200 {"root":"C","notes":7}
```

[`TypedResults`](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis/responses) conserva tipos concretos para tests y OpenAPI. Un endpoint filter decora handlers; la autorización corresponde al sistema de autorización y a metadatos de endpoint.

## Donde los controladores siguen siendo profundos

Los controladores aportan convenciones, model binding, filtros y validación. El programa mapea ambos estilos en la misma tabla:

```text
controller: 200 {"symbol":"Cmaj7","characters":5}
```

No dupliques policy: cada transporte llama la misma seam de aplicación.

## Streaming

`IAsyncEnumerable<T>` permite consumo asíncrono por el serializer. Los proxies aún pueden bufferizar; para entrega progresiva mide toda la ruta y elige NDJSON, SSE o SignalR según contrato.

## Ejecutar la prueba

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l14
```

La salida verificada es [`expected/l14.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l14.txt).

## Ejercicios

1. Añade `notes` negativo y un contrato portable de error.
2. Expón la misma operación por Minimal API y controlador sin duplicar policy.
3. Cancela el stream tras el primer elemento y prueba que la fuente observa cancelación.

<details>
<summary>Soluciones</summary>

1. Rechaza en la frontera con problem details estable y prueba estado, media type y payload.
2. Liga entradas a un comando/query único, llama un solo handler y mapea el resultado en cada adapter.
3. Pasa `RequestAborted`, cierra la respuesta en el cliente y comprueba el `finally` o la sonda de cancelación.

</details>
