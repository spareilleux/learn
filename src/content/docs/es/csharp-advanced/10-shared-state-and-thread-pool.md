---
title: 10. Estado compartido y thread pool
description: Elegir Lock, Interlocked, colecciones concurrentes y Parallel.ForEachAsync según el invariante, y diagnosticar starvation sin convertir cada espera asíncrona en un hilo bloqueado.
sidebar:
  order: 10
---

Un bug concurrente no requiere hardware desafortunado. Dos workers pueden leer el mismo valor, calcular el mismo sucesor y escribirlo. El ejemplo fuerza ese scheduling con una barrera: dos incrementos dejan `1`.

## Proteger el invariante, no la línea

[`System.Threading.Lock`](https://learn.microsoft.com/dotnet/api/system.threading.lock) es el primitivo moderno de .NET cuando varias lecturas y escrituras forman un invariante. [`Interlocked`](https://learn.microsoft.com/dotnet/api/system.threading.interlocked) sirve para un contador atómico o una operación compare-and-swap. Una colección concurrente protege su propia operación, no una secuencia de negocio completa.

```text
two increments without synchronization: 1
Lock count: 10000
Interlocked count: 10000
AddOrUpdate count: 1000
```

`ConcurrentDictionary.AddOrUpdate` puede invocar una factory varias veces bajo contención. Mantén las factories puras y separa los efectos en una operación idempotente.

## El paralelismo es un presupuesto

[`Parallel.ForEachAsync`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.parallel.foreachasync) limita cuerpos activos con `MaxDegreeOfParallelism`. El programa observa dos cuerpos para un límite de dos. Es un presupuesto local, no backpressure end-to-end.

La starvation aparece cuando hilos bloqueados esperan trabajo que necesita esos mismos workers. Prefiere esperas asíncronas para I/O, limita el CPU y mide con `dotnet-counters` antes de aumentar mínimos.

## Ejecutar la prueba

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l10
```

La salida portable está en [`expected/l10.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l10.txt).

## Ejercicios

1. Sustituye el contador por total y checksum. Explica por qué dos llamadas `Interlocked` no hacen atómico el par.
2. Pon una llamada HTTP en `GetOrAdd`, cuenta las llamadas bajo contención y elimina el efecto.
3. Compara grados 2, 8 y 64 ante una dependencia limitada a cuatro llamadas.

<details>
<summary>Soluciones</summary>

1. Protege ambos campos con un solo `Lock` o sustituye atómicamente un valor inmutable. Dos escrituras atómicas independientes exponen un estado intermedio.
2. La factory puede ejecutarse varias veces aunque gane un solo valor. El efecto debe ser idempotente y externo al primitivo de colección.
3. El grado correcto viene del throughput y la latencia medidos; el número de CPU no define la capacidad de la dependencia.

</details>
