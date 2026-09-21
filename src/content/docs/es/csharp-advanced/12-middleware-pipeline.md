---
title: 12. El pipeline de middleware
description: Tratar Use, Map y Run como control de flujo anidado cuyo orden determina seguridad, errores, routing y short-circuits.
sidebar:
  order: 12
---

El [middleware de ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/middleware/) es control de flujo anidado. El código antes de `next` se ejecuta al entrar; el código posterior, al salir. El orden de registro es comportamiento observable.

## La cebolla es ejecutable

```text
GET /ok: 200; outer:before -> endpoint -> outer:after
```

El gate hace short-circuit de `/blocked`:

```text
GET /blocked: 429; outer:before -> gate:short-circuit -> outer:after
```

El endpoint no aparece porque el gate no llama `next`. El middleware exterior sí completa su camino de respuesta.

## Reglas de orden con consecuencias

- el handler de excepciones debe envolver el código que convierte;
- forwarded headers preceden a lectores de scheme, host o client IP;
- routing selecciona endpoint antes de autorización basada en metadatos;
- autenticación establece principal antes de autorización;
- un `Run` terminal finaliza su rama.

`Map` ramifica por ruta y `MapWhen` por predicado. Una rama no es un nuevo proceso ni una frontera de confianza.

## Ejecutar la prueba

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l12
```

La salida verificada es [`expected/l12.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l12.txt).

## Ejercicios

1. Pon el handler de excepción después de un endpoint que lanza.
2. Añade un correlation ID y decide cómo tratar uno proporcionado por el cliente.
3. Añade una rama `/admin` y prueba que la autorización se ejecuta.

<details>
<summary>Soluciones</summary>

1. Solo puede envolver componentes registrados después; muévelo antes.
2. Valida la entrada, consérvala solo como baggage no confiable y genera el ID de servidor para logs.
3. Coloca autorización en la rama o usa metadatos de endpoint. La ruta sola no concede autoridad.

</details>
