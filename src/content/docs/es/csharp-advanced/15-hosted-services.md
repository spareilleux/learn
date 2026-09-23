---
title: 15. Servicios hospedados y trabajo en segundo plano
description: Controlar inicio, apagado, fallos, colas limitadas y scopes de inyección con IHostedService y BackgroundService.
sidebar:
  order: 15
---

Un [`IHostedService`](https://learn.microsoft.com/dotnet/core/extensions/scoped-service) participa en el ciclo de vida del host. [`BackgroundService`](https://learn.microsoft.com/dotnet/core/extensions/workers) aporta el bucle `ExecuteAsync`, pero el host sigue siendo dueño del inicio, la cancelación y el apagado.

## Requisitos previos

Completa primero [inyección de dependencias y opciones](../13-dependency-injection-options/) y [channels](../06-channels/). Ya debes comprender los ciclos de vida de servicios, los cancellation tokens y los flujos asíncronos.

## El host posee el ciclo de vida

El experimento inicia un host, espera barreras explícitas, procesa dos elementos y pide el apagado. No usa `Thread.Sleep` y cada espera está limitada a cinco segundos.

En .NET 10, [todo `BackgroundService.ExecuteAsync` se ejecuta en un hilo de segundo plano](https://learn.microsoft.com/dotnet/core/compatibility/extensions/10.0/backgroundservice-executeasync-task). El trabajo que debe acabar antes de iniciar otros servicios pertenece al constructor, a [`StartAsync`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.hosting.ihostedservice.startasync) o a [`IHostedLifecycleService`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.hosting.ihostedlifecycleservice), no a la parte anterior al primer `await` de `ExecuteAsync`.

## Una cola limitada es un contrato de aplicación

El worker consume un [`Channel<T>`](https://learn.microsoft.com/dotnet/core/extensions/channels) limitado. `BoundedChannelFullMode.Wait` aplica backpressure cuando la cola está llena. Una API real debería esperar `WriteAsync`; esta prueba pequeña usa `TryWrite` porque su capacidad y sus dos escrituras son fijas.

[`AddHostedService`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.dependencyinjection.servicecollectionhostedserviceextensions.addhostedservice) registra el worker como singleton. Por tanto, una dependencia scoped se resuelve dentro de un [`IServiceScope`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.dependencyinjection.iservicescope) nuevo para cada elemento. Inyectarla en el constructor del worker crearía una dependencia cautiva.

```text
== The host starts one singleton worker and the queue owns the work
startup observed: True
queued results: C major@scope-1 | G major@scope-2
fresh scope per item: True
shutdown cancellation observed: True
```

## Los fallos son una política

La política predeterminada del host .NET 10 detiene la aplicación cuando un `BackgroundService` lanza una excepción. La prueba fija `BackgroundServiceExceptionBehavior.StopHost`, libera una barrera de fallo y observa `ApplicationStopping`:

```text
== A BackgroundService fault stops its host
fault requested host stop: True
```

Detener el host no es recuperación. Producción aún necesita una política explícita de reintento, dead-letter u operación para trabajo que pueda repetirse con seguridad.

## Ejecutar la prueba

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l15
```

La salida comprobada está en [`expected/l15.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l15.txt).

## Ejercicios

1. Sustituye `TryWrite` por una API asíncrona y prueba que un tercer elemento espera cuando las dos plazas están ocupadas.
2. Añade un resultado de fallo por elemento sin detener el worker singleton.
3. Introduce un segundo consumidor e indica qué garantía de orden se pierde.

<details>
<summary>Soluciones</summary>

1. Devuelve `ValueTask`, espera `Writer.WriteAsync` y retén los dos primeros elementos con barreras. Libera una y verifica que la tercera escritura termina; no deduzcas bloqueo de una demora.
2. Captura la excepción de una operación, completa su `TaskCompletionSource` con un fallo tipado y continúa el bucle. No trates la cancelación del host como fallo de trabajo.
3. Usa `SingleReader = false` y dos workers. Las lecturas siguen FIFO, pero el orden de terminación depende del procesamiento; añade números de secuencia si el consumidor debe reordenar.

</details>
