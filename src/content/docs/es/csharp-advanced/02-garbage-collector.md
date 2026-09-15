---
title: "Lección 2: El recolector de basura"
description: Las generaciones y la promoción, el umbral exacto del montón de objetos grandes, los montones de objetos fijados y congelados, las referencias débiles y los finalizadores, el GC de estación de trabajo, de servidor y concurrente, lo que informa GC.GetGCMemoryInfo, y las asignaciones medidas con el MemoryDiagnoser de BenchmarkDotNet en Guitar Alchemist.
sidebar:
  label: 2. El recolector de basura
  order: 2
---

La lección 1 contó los bytes de cada asignación. Esta lección sigue a esos bytes después de su asignación: qué montón los recibe, cuándo vuelve a mirarlos el recolector de basura (GC), qué hace con los objetos que sobreviven y cómo su configuración cambia todo eso. Cada comportamiento se observa desde dentro del programa con la clase [`GC`](https://learn.microsoft.com/dotnet/api/system.gc), y después se miden con [BenchmarkDotNet](https://benchmarkdotnet.org/) las asignaciones de código real de GA.

Los enlaces de GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6); los enlaces del runtime apuntan al commit [`4271d88`](https://github.com/dotnet/runtime/tree/4271d88e0aebf3d04f188f1334c2220d80555ef6) de `dotnet/runtime`, con la etiqueta `v10.0.12`.

## Ejecutar el programa de la lección

```bash
bash code/csharp-advanced/check.sh                                   # cada lección, comparada con expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- l2  # solo esta lección, después de check.sh
```

El código está en [`Advanced/Lesson2.cs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson2.cs). Las líneas que empiezan por `# ` dependen de la máquina (tamaños de montón, tiempos de pausa, número de procesadores): la lección las cita tal como salen en la máquina del autor, un Intel Core Ultra 9 285K con 24 núcleos y 64 GB de memoria, y en los runners de la CI cuando difieren de forma interesante.

## Generaciones

El GC de .NET es *generacional*: supone que la mayoría de los objetos mueren jóvenes, y recolecta los objetos jóvenes con mucha más frecuencia que los viejos ([Fundamentos de la recolección de elementos no utilizados](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals#generations)). Los objetos nuevos van a la generación 0. Un objeto que sigue referenciado cuando se recolecta su generación se *promueve* a la siguiente, hasta la generación 2. Una recolección gen0 solo examina gen0 (más las referencias que los objetos viejos tienen hacia los jóvenes, registradas por la barrera de escritura); una recolección gen2, también llamada recolección *completa*, lo examina todo.

El programa asigna un acorde de tres notas y llama a [`GC.Collect()`](https://learn.microsoft.com/dotnet/api/system.gc.collect), que fuerza una recolección completa y bloqueante ([`Lesson2.cs#L58-L73`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson2.cs#L58-L73)):

```text
== Generations: an object that survives a collection is promoted
new int[3]           generation 0
after GC.Collect()   generation 1
after a second one   generation 2
after a third one    generation 2
GC.Collect(0) then new int[3]: generation 0
```

Dos recolecciones bastaron para que el acorde envejeciera. Esa es la trampa de llamar a `GC.Collect()` en el código de una aplicación: no libera memoria antes de ninguna forma útil, pero promueve todos los objetos vivos, que después esperan a la siguiente recolección completa, la más cara, para liberarse. El programa del curso solo lo llama para hacer visible el comportamiento del GC.

## El montón de objetos grandes, al byte

Los objetos de 85,000 bytes o más van al montón de objetos grandes (LOH), que solo se recolecta con la generación 2 y no se compacta de forma predeterminada ([El montón de objetos grandes](https://learn.microsoft.com/dotnet/standard/garbage-collection/large-object-heap)). La documentación dice «85,000 bytes»; el programa encuentra el límite exacto.

```text
== Large object heap: 85,000 bytes and more, counted with the object header
new byte[   84,975]  object size    85,000  generation 0
new byte[   84,976]  object size    85,000  generation 2
new byte[1,000,000]  object size 1,000,024  generation 2
new double[10,622]   object size    85,000  generation 2
```

`GC.GetGeneration` indica que los objetos del LOH son de generación 2. Los dos primeros arrays cuestan 85,000 bytes cada uno, pero solo el segundo es grande. El runtime decide antes de redondear: en [`gchelpers.cpp#L644-L659`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/vm/gchelpers.cpp#L644-L659), el `totalSize` de un array es su número de elementos multiplicado por el tamaño de un elemento, más el tamaño base de 24 bytes, y el array va al LOH cuando `totalSize >= LARGE_OBJECT_SIZE`, que vale 85,000 según [`gc.h#L105`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/gc/gc.h#L105). 24 + 84,975 = 84,999 bytes sigue siendo pequeño, y después se redondea a 85,000. 24 + 84,976 = 85,000 es grande. Un array de 10,622 `double` llega exactamente a 85,000.

El umbral se puede configurar con `GCLOHThreshold` ([`gcconfig.h#L82`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/gc/gcconfig.h#L82), [configuración del GC](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector#large-object-heap-threshold)), y el programa lee su valor actual en la sección siguiente. Los búferes grandes que se asignan y se descartan en un bucle son una causa clásica de recolecciones gen2; [`ArrayPool<T>.Shared`](https://learn.microsoft.com/dotnet/api/system.buffers.arraypool-1.shared) existe precisamente para reutilizarlos.

## El montón de objetos fijados

El código nativo, o una operación de E/S en curso, puede necesitar un array que el GC no debe mover mientras compacta el montón. Fijar un array normal con `fixed` o con un `GCHandle` bloquea la compactación a su alrededor y fragmenta la generación 0. Desde .NET 5, [`GC.AllocateArray<T>(length, pinned: true)`](https://learn.microsoft.com/dotnet/api/system.gc.allocatearray) asigna en su lugar en un montón aparte, el montón de objetos fijados (POH), que, como el LOH, se recolecta con la generación 2.

```text
== Pinned object heap: GC.AllocateArray(pinned: true)
pinned byte[1024]    generation 2
ordinary byte[1024]  generation 0
heaps in GCGenerationInfo: 5 (gen0, gen1, gen2, LOH, POH)
```

[`GCMemoryInfo.GenerationInfo`](https://learn.microsoft.com/dotnet/api/system.gcmemoryinfo.generationinfo) describe cinco montones: las tres generaciones, el LOH y el POH. En la máquina del autor, después de la recolección, el POH contenía 9,232 bytes: el propio runtime ya había colocado ahí 8,184 bytes antes del kilobyte del programa.

## Objetos alcanzables: referencias débiles y finalizadores

El GC libera un objeto cuando ya nada *alcanzable* hace referencia a él: ninguna variable local de un método en ejecución, ningún campo estático, ningún campo de otro objeto alcanzable. Una [`WeakReference`](https://learn.microsoft.com/dotnet/standard/garbage-collection/weak-references) apunta a un objeto sin mantenerlo vivo ([`Lesson2.cs#L99-L135`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson2.cs#L99-L135)). Los objetos se crean en un método aparte que no se inserta en línea: en el método que ejecuta `GC.Collect()`, una variable local podría seguir conteniéndolos, sobre todo en código sin optimizar.

```text
== Reachability: a weak reference does not keep an object alive
only weakly reachable:  IsAlive False
still referenced:       IsAlive True (4 notes)
```

Una clase con un [finalizador](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/finalizers) (`~Finalizable()`) sigue un camino más largo. Cuando el GC encuentra inalcanzable uno de sus objetos, todavía no puede liberarlo: lo mueve a una cola, y un subproceso finalizador dedicado ejecuta su finalizador. El objeto, de nuevo alcanzable desde esa cola, lo libera una recolección posterior. Una referencia débil *corta* deja de seguir al objeto en cuanto es inalcanzable; una referencia débil *larga*, creada con `trackResurrection: true`, lo sigue hasta que desaparece de verdad.

```text
== Finalizers: a finalizable object is freed one collection later
after 1 collection:  finalized 1, short weak IsAlive False, long weak IsAlive True
after 2 collections: finalized 1, short weak IsAlive False, long weak IsAlive False
bytes of new Finalizable(): 24, of new object(): 24
```

El objeto finalizable no cuesta más bytes, pero sobrevive a una recolección más, con la posibilidad de ser promovido por el camino, y su registro en la cola de finalización hace más lenta la asignación. Por eso las clases [`IDisposable`](https://learn.microsoft.com/dotnet/standard/garbage-collection/implementing-dispose) que tienen un finalizador llaman a `GC.SuppressFinalize(this)` en `Dispose()`, y por eso la mayoría de las clases no deberían tener ningún finalizador: envuelve los identificadores nativos en un [`SafeHandle`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.safehandle), que ya tiene uno.

## GC de estación de trabajo, de servidor y concurrente

El runtime incluye un único GC con varios modos ([Recolección de elementos no utilizados de estación de trabajo y de servidor](https://learn.microsoft.com/dotnet/standard/garbage-collection/workstation-server-gc)):

- El GC de **estación de trabajo**, el predeterminado para las aplicaciones de consola y de escritorio, usa un solo montón y recolecta en el subproceso que desencadenó la recolección.
- El GC de **servidor**, el predeterminado para ASP.NET Core, usa un montón y un subproceso de GC por procesador lógico, con presupuestos de gen0 mucho mayores: más capacidad de proceso, más memoria. Desde .NET 9, [DATAS](https://learn.microsoft.com/dotnet/standard/garbage-collection/datas) (adaptación dinámica al tamaño de las aplicaciones) está activado de forma predeterminada con el GC de servidor y ajusta el número de montones a la carga.
- El GC **concurrente** (en segundo plano), activado de forma predeterminada en ambos, ejecuta la mayor parte de una recolección gen2 mientras la aplicación sigue ejecutándose.

Los eliges en el archivo del proyecto (`<ServerGarbageCollection>`, `<ConcurrentGarbageCollection>`), en `runtimeconfig.json` (`System.GC.Server`, `System.GC.Concurrent`) o con variables de entorno ([configuración del GC](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector)). `check.sh` ejecuta el programa tres veces: con los valores predeterminados, con `DOTNET_gcServer=1` y con `DOTNET_gcConcurrent=0`. [`GC.GetConfigurationVariables()`](https://learn.microsoft.com/dotnet/api/system.gc.getconfigurationvariables) devuelve la configuración que usa realmente el GC.

```text
== GC mode
GCSettings.IsServerGC: False
GCSettings.LatencyMode: Interactive
GC.MaxGeneration: 2
GC.GetConfigurationVariables()["ServerGC"]: False
GC.GetConfigurationVariables()["ConcurrentGC"]: True
GC.GetConfigurationVariables()["LOHThreshold"]: 85000
GC.GetConfigurationVariables()["GCDynamicAdaptationMode"]: 1
```

```text
== GC mode
GCSettings.IsServerGC: True
GCSettings.LatencyMode: Interactive
GC.MaxGeneration: 2
GC.GetConfigurationVariables()["ServerGC"]: True
GC.GetConfigurationVariables()["ConcurrentGC"]: True
GC.GetConfigurationVariables()["LOHThreshold"]: 85000
GC.GetConfigurationVariables()["GCDynamicAdaptationMode"]: 1
```

```text
== GC mode
GCSettings.IsServerGC: False
GCSettings.LatencyMode: Batch
GC.MaxGeneration: 2
GC.GetConfigurationVariables()["ServerGC"]: False
GC.GetConfigurationVariables()["ConcurrentGC"]: False
GC.GetConfigurationVariables()["LOHThreshold"]: 85000
GC.GetConfigurationVariables()["GCDynamicAdaptationMode"]: 1
```

[`GCSettings.LatencyMode`](https://learn.microsoft.com/dotnet/api/system.runtime.gcsettings.latencymode) refleja la concurrencia: `Interactive` con el GC en segundo plano, `Batch` sin él. `GCDynamicAdaptationMode` vale 1 en las tres ejecuciones: la opción está activada, pero solo se aplica cuando lo está el GC de servidor. Las líneas que dependen de la máquina muestran lo que cuesta en memoria el GC de servidor:

| Máquina | Procesadores | Montones de estación de trabajo | `GCGen0MaxBudget` de estación de trabajo | Montones de servidor | `GCGen0MaxBudget` de servidor |
|---|---:|---:|---:|---:|---:|
| Autor (Windows, x64) | 24 | 1 | 18,874,368 | 24 | 209,715,200 |
| CI Linux (x64) | 4 | 1 | 16,777,216 | 4 | 209,715,200 |
| CI Windows (x64) | 4 | 1 | 25,165,824 | 4 | 209,715,200 |
| CI macOS (Arm64) | 3 | 1 | 6,291,456 | 3 | 209,715,200 |

El presupuesto de gen0 es la cantidad de memoria asignada tras la cual empieza una recolección gen0; con el GC de estación de trabajo, el runtime lo deriva del tamaño de la caché del procesador, así que cambia de una máquina a otra. El GC de estación de trabajo no concurrente indicó 134,217,728 bytes en las cuatro máquinas.

## Lo que informa `GC.GetGCMemoryInfo`

[`GC.GetGCMemoryInfo()`](https://learn.microsoft.com/dotnet/api/system.gc.getgcmemoryinfo) describe la última recolección: su generación, si compactó, sus tiempos de pausa y el tamaño de cada montón antes y después. El programa fuerza una recolección gen2 bloqueante y con compactación mediante `GC.Collect(2, GCCollectionMode.Forced, blocking: true, compacting: true)`, y luego la lee:

```text
== GC.GetGCMemoryInfo after an induced, blocking, compacting collection
Generation 2, Compacted True, Concurrent False
# Index 11, PauseDurations[0] 0.156 ms, PauseTimePercentage 4.3%
# HeapSizeBytes 275,648, FragmentedBytes 528, TotalCommittedBytes 1,495,040
# TotalAvailableMemoryBytes 68,403,589,120, HighMemoryLoadThresholdBytes 61,563,230,208
#   gen0: before 4,200, after 560
#   gen1: before 416, after 0
#   gen2: before 277,504, after 266,904
#   LOH: before 0, after 0
#   POH: before 8,184, after 8,184
```

Esta fue la undécima recolección del programa (`Index`), pausó el proceso durante 0.16 ms y dejó un montón de 276 KB: un programa pequeño, incluso con las tablas estáticas de GA cargadas. `TotalAvailableMemoryBytes` es la memoria física que el GC cree que puede usar, o el límite del contenedor cuando lo hay; por encima de `HighMemoryLoadThresholdBytes` (90% de forma predeterminada), recolecta de forma más agresiva. Los mismos valores se exportan como [métricas del runtime](https://learn.microsoft.com/dotnet/core/diagnostics/built-in-metrics-runtime), como `dotnet.gc.last_collection.heap.size`, que un panel de supervisión puede seguir en producción; la lección 12 las usa.

## Los objetos de vida corta son baratos, hasta que dejan de serlo

La hipótesis generacional hace baratos los objetos de vida corta: una recolección gen0 solo examina los objetos vivos, y saltarse los muertos no cuesta nada. El programa asigna un millón de arrays pequeños, y cada uno se conserva solo hasta que los dieciséis siguientes lo reemplazan ([`Lesson2.cs#L160-L177`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson2.cs#L160-L177)):

```text
== Allocation budget: many short-lived objects, few collections
allocated 32,000,152 bytes for 1,000,000 arrays of 2 ints, 16 still referenced
```

32 MB de basura provocaron una recolección gen0 en la máquina del autor, en la CI de Linux y en la CI de Windows, y cinco en la CI de macOS, cuyo presupuesto de gen0 es de 6 MB. No se promovió ninguno. El coste vuelve cuando los objetos de vida corta se hacen grandes (el LOH), o viven justo lo suficiente para ser promovidos a gen1 o gen2: una caché con ámbito de solicitud, un búfer que sobrevive a un `await`. Entonces el GC tiene que copiarlos y, tarde o temprano, ejecutar una recolección completa para liberarlos.

## Medir las asignaciones con BenchmarkDotNet

`GC.GetAllocatedBytesForCurrentThread()` sirve para una llamada. Para código que se ejecuta millones de veces, el [`[MemoryDiagnoser]`](https://benchmarkdotnet.org/articles/configs/diagnosers.html) de BenchmarkDotNet informa, por operación, de los bytes asignados y del número de recolecciones gen0, gen1 y gen2 por cada 1,000 operaciones. [`Benchmarks/AllocationBenchmarks.cs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Benchmarks/AllocationBenchmarks.cs) mide las asignaciones de la lección 1, incluido `PitchClassSetId.ItemsSpan` de GA frente a un array en caché:

```csharp
[MemoryDiagnoser]
public class AllocationBenchmarks
{
    private static readonly PitchClassSetId[] CachedIds = [.. PitchClassSetId.Items];

    [Benchmark(Baseline = true)]
    public int GaPitchClassSetIdItemsSpan() => PitchClassSetId.ItemsSpan.Length;

    [Benchmark]
    public int CachedArraySpan() => new ReadOnlySpan<PitchClassSetId>(CachedIds).Length;
```

```bash
cd code/csharp-advanced
dotnet run -c Release --project Benchmarks -- --filter "*AllocationBenchmarks*"
```

En la máquina del autor, sin nada más en ejecución:

```text
BenchmarkDotNet v0.15.8, Windows 11 (10.0.26200.9445/25H2/2025Update/HudsonValley2)
Intel Core Ultra 9 285K 3.70GHz, 1 CPU, 24 logical and 24 physical cores
.NET SDK 10.0.112
  [Host]     : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
  DefaultJob : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
```

| Method                     | Mean          | Error      | StdDev      | Median        | Ratio | RatioSD | Gen0   | Allocated | Alloc Ratio |
|--------------------------- |--------------:|-----------:|------------:|--------------:|------:|--------:|-------:|----------:|------------:|
| GaPitchClassSetIdItemsSpan | 1,158.0046 ns | 70.7784 ns | 208.6918 ns | 1,173.2269 ns | 1.035 |    0.28 | 0.8698 |   16408 B |       1.000 |
| CachedArraySpan            |     0.0899 ns |  0.0292 ns |   0.0860 ns |     0.0770 ns | 0.000 |    0.00 |      - |         - |       0.000 |
| GaPitchClassItemsSpan      |     0.0543 ns |  0.0258 ns |   0.0761 ns |     0.0130 ns | 0.000 |    0.00 |      - |         - |       0.000 |
| VoicingWithSplit           |    60.0266 ns |  1.2168 ns |   2.3151 ns |    60.1405 ns | 0.054 |    0.01 | 0.0114 |     216 B |       0.013 |
| VoicingWithSpans           |    46.0624 ns |  0.9406 ns |   2.2536 ns |    46.1613 ns | 0.041 |    0.01 |      - |         - |       0.000 |
| Format                     |    19.1902 ns |  0.4152 ns |   0.8759 ns |    19.1456 ns | 0.017 |    0.00 | 0.0030 |      56 B |       0.003 |
| Interpolate                |    12.4961 ns |  0.3073 ns |   0.7479 ns |    12.6991 ns | 0.011 |    0.00 | 0.0017 |      32 B |       0.002 |

Los tiempos proceden de una sola máquina y una sola ejecución, y la CI nunca los compara. Las asignaciones no dependen de la máquina:

- `GaPitchClassSetIdItemsSpan` asigna **16,408 bytes en cada llamada**, la copia de 4,096 identificadores que encontró la lección 1, y provoca 0.87 recolecciones gen0 por cada mil llamadas: un bucle que lee `ItemsSpan` mil veces causa casi una recolección. Además tarda alrededor de un microsegundo, y sus tiempos están dispersos (BenchmarkDotNet advierte de que la distribución es *multimodal*), porque algunas llamadas pagan una recolección y otras no.
- `CachedArraySpan` y el propio `PitchClass.ItemsSpan` de GA, que devuelve un array en caché, no asignan nada. Sus medias, una décima de nanosegundo, están por debajo de lo que BenchmarkDotNet puede medir: indica *ZeroMeasurement*, «indistinguible del método vacío». El JIT los redujo a la lectura de una longitud.
- Analizar el voicing `"x 3 2 0 1 0"` con `string.Split` asigna 216 bytes (el array y seis cadenas); la versión con spans no asigna nada y es alrededor de una cuarta parte más rápida.
- `Format` asigna 56 bytes, el objeto con boxing y la cadena, e `Interpolate` 32, solo la cadena, como se midió en la lección 1. La columna `Gen0` convierte esos bytes en recolecciones: 3 por millón de llamadas para `Format`.

Lee primero `Allocated`: es exacto y reproducible. Lee `Mean` con su `Error` y su `StdDev`, y con las advertencias que BenchmarkDotNet imprime debajo de la tabla. La lección 4 trata de cómo obtener tiempos en los que puedas confiar.

## Ejercicios

1. ¿Cuál es el `char[]` más pequeño que va al montón de objetos grandes?
2. [`GC.TryStartNoGCRegion`](https://learn.microsoft.com/dotnet/api/system.gc.trystartnogcregion) pide al GC que no recolecte mientras una sección crítica asigna menos de una cantidad dada. Inicia una región de 1 MB, asigna mil arrays de 100 bytes e indica el modo de latencia y el número de recolecciones gen0 dentro de la región.
3. `GC.GetGeneration("C major")` no devuelve ni 0, ni 1, ni 2. ¿Qué devuelve y por qué? Prueba también con `typeof(PitchClass)`.

<details>
<summary>Soluciones</summary>

1. Un `char` ocupa 2 bytes, y el tamaño base del array es de 24 bytes: 24 + 2 × *n* ≥ 85,000 da *n* = **42,488**. Con un elemento menos, el array se queda en la generación 0.

    ```text
    1. new char[42,487] generation 0, new char[42,488] generation 2
    ```

2. La región se inicia, el modo de latencia pasa a ser `NoGCRegion`, y mil arrays de 128 bytes cada uno (24 + 100, redondeado) caben en el 1 MB reservado: ninguna recolección. `EndNoGCRegion` restaura el modo anterior. Asignar más de la cantidad solicitada termina la región en silencio, y entonces `EndNoGCRegion` lanza `InvalidOperationException`.

    ```text
    2. TryStartNoGCRegion(1 MB) True, LatencyMode NoGCRegion, gen0 collections for 1,000 arrays 0
       after EndNoGCRegion: LatencyMode Interactive, 16 arrays kept
    ```

3. Devuelve `int.MaxValue`. Desde .NET 8, los literales de cadena, los objetos `RuntimeType` y algunos otros objetos que el runtime sabe que vivirán para siempre se asignan en un montón *congelado*, ajeno al GC, que el GC nunca examina ([nota sobre el cambio importante](https://learn.microsoft.com/dotnet/core/compatibility/core-libraries/8.0/getgeneration-return-value)). Una cadena construida en tiempo de ejecución con los mismos caracteres es un objeto gen0 normal. El código que usaba la generación como índice de un array falla con estos objetos.

    ```text
    3. GC.GetGeneration("C major") 2147483647, of new string('C', 7) 0, of typeof(PitchClass) 2147483647
    ```

</details>

## Puntos clave

- Los objetos nuevos empiezan en la generación 0; cada recolección a la que sobreviven los promueve, hasta la generación 2. `GC.Collect()` en el código de una aplicación sobre todo promueve objetos vivos.
- Un array va al montón de objetos grandes cuando su tamaño sin redondear, 24 bytes más sus elementos, llega a 85,000 bytes: `byte[84,976]`, `char[42,488]`, `double[10,622]`. El LOH y el montón de objetos fijados se recolectan con la generación 2.
- Un finalizador retrasa la liberación al menos una recolección. Prefiere `IDisposable` y `SafeHandle`.
- El GC de servidor cambia memoria por capacidad de proceso: un montón por procesador y un presupuesto de gen0 de 200 MB, ajustado por DATAS desde .NET 9. Los presupuestos del GC de estación de trabajo dependen de la máquina.
- `GC.GetGCMemoryInfo()` y `GC.GetConfigurationVariables()` muestran lo que hizo el GC y cómo está configurado, desde dentro del proceso.
- `[MemoryDiagnoser]` convierte «esto asigna memoria» en bytes y recolecciones por operación. `PitchClassSetId.ItemsSpan` de GA aparece ahí como 16,408 bytes por llamada y casi una recolección gen0 por cada mil llamadas.

## Fuentes

- Microsoft Learn: [Fundamentos de la recolección de elementos no utilizados](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals), [El montón de objetos grandes](https://learn.microsoft.com/dotnet/standard/garbage-collection/large-object-heap), [GC de estación de trabajo y de servidor](https://learn.microsoft.com/dotnet/standard/garbage-collection/workstation-server-gc), [DATAS](https://learn.microsoft.com/dotnet/standard/garbage-collection/datas), [Opciones de configuración del GC](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector), [Referencias débiles](https://learn.microsoft.com/dotnet/standard/garbage-collection/weak-references), [Finalizadores](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/finalizers), [`GC.GetGeneration` puede devolver `Int32.MaxValue`](https://learn.microsoft.com/dotnet/core/compatibility/core-libraries/8.0/getgeneration-return-value), [Métricas del runtime de .NET](https://learn.microsoft.com/dotnet/core/diagnostics/built-in-metrics-runtime).
- dotnet/runtime en `v10.0.12` (commit `4271d88`): [`gchelpers.cpp`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/vm/gchelpers.cpp#L644-L659), [`gc.h`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/gc/gc.h#L105), [`gcconfig.h`](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/src/coreclr/gc/gcconfig.h#L82).
- BenchmarkDotNet: [Diagnosticadores](https://benchmarkdotnet.org/articles/configs/diagnosers.html).
