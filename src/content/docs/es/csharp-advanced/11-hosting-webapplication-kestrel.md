---
title: 11. Hosting, WebApplication y Kestrel
description: Seguir la responsabilidad desde el generic host hasta WebApplication, Kestrel, DI, callbacks de ciclo de vida y apagado graceful mediante un servidor loopback real.
sidebar:
  order: 11
---

[`WebApplication`](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis/webapplication) compone configuración, logging, inyección, middleware y endpoints. El generic host posee el ciclo de vida; [Kestrel](https://learn.microsoft.com/aspnet/core/fundamentals/servers/kestrel) posee el transporte de red.

## Lo que ensambla el builder

`CreateBuilder` carga configuración y servicios. `Build` congela ese grafo en una aplicación. `StartAsync` inicia hosted services y servidor; `StopAsync` inicia el apagado graceful.

El programa enlaza Kestrel a un puerto loopback efímero, llama realmente `/health` y observa callbacks:

```text
started callback observed: True
GET /health: 200 {"status":"ready"}
graceful stop callbacks observed: stopping=True, stopped=True
```

Esto prueba la composición del curso, no readiness de producción. Aún hay que declarar límites, timeouts, confianza en forwarded headers, TLS y presupuesto de apagado.

## Graceful no significa infinito

`ApplicationStopping` pide detener la admisión. El trabajo en vuelo debe terminar dentro del presupuesto o dejar evidencia durable de recuperación. En contenedores, el timeout del host debe caber en el período de gracia del orquestador.

## Ejecutar la prueba

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l11
```

La salida verificada es [`expected/l11.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l11.txt).

## Ejercicios

1. Añade un endpoint lento que observe `RequestAborted` y dispara el apagado.
2. Fija un límite pequeño de body en Kestrel y prueba justo debajo y encima.
3. Prueba forwarded headers con un proxy permitido y una petición directa falsificada.

<details>
<summary>Soluciones</summary>

1. Prueba que la petición entró, llama `StopAsync` con un token limitado y registra la cancelación observada.
2. Configura antes de `Build`, verifica el estado y que el endpoint rechazado no fue invocado.
3. Declara proxies/redes conocidos; una petición directa no debe elegir su identidad de cliente.

</details>
