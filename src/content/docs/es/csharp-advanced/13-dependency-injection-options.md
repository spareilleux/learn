---
title: 13. Inyección de dependencias y options
description: Convertir lifetimes singleton, scoped y transient en reglas de propiedad, detectar captive dependencies, usar keyed services y validar options.
sidebar:
  order: 13
---

La [inyección de dependencias de ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/dependency-injection) es un sistema de propiedad. Un lifetime dice cuánto tiempo pueden compartirse una instancia y su estado.

## Los lifetimes no son trucos de rendimiento

- **singleton**: una instancia raíz, thread-safe y sin estado scoped capturado;
- **scoped**: una instancia por scope, normalmente una petición HTTP;
- **transient**: una instancia por resolución, todavía propiedad del contenedor.

```text
same scope returns same instance: True
singleton returns same instance: True
different scopes return different instances: True
captive scoped dependency rejected: True
```

Los [keyed services](https://learn.microsoft.com/aspnet/core/fundamentals/dependency-injection#keyed-services) seleccionan implementación mediante una clave de composición. No disperses esa clave como service locator en el dominio.

## Options como contrato

[`IOptions<T>`](https://learn.microsoft.com/dotnet/core/extensions/options) es una vista singleton, `IOptionsSnapshot<T>` recalcula por scope e `IOptionsMonitor<T>` observa cambios. Reloadable no significa seguro: define qué ve una operación en vuelo.

El programa configura capacidad inválida y observa `OptionsValidationException`. `ValidateOnStart` lleva ese fallo al inicio de una aplicación hosted.

## Ejecutar la prueba

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l13
```

La salida verificada es [`expected/l13.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l13.txt).

## Ejercicios

1. Inyecta un repositorio scoped en un cache singleton y repara la propiedad.
2. Configura dos formatters keyed y mueve la selección de clave a la composición.
3. Recarga capacidad durante trabajo en vuelo y escribe el invariante.

<details>
<summary>Soluciones</summary>

1. Haz el consumidor scoped, pasa datos inmutables al singleton o crea y desecha scopes explícitos en infraestructura.
2. Resuelve el servicio keyed al componer e inyecta un contrato sin clave en dominio.
3. Aplica el nuevo valor a nuevas colas o ejecuta una migración explícita con admisión detenida.

</details>
