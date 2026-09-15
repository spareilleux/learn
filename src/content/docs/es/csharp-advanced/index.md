---
title: C# avanzado — Misión
description: Lo que ocurre bajo el capó de C# 14, .NET 10 y ASP.NET Core — la memoria, el recolector de basura, async, el rendimiento medido, los canales, TPL Dataflow, Rx.NET y los flujos asíncronos, y después la pila web y las herramientas —, cada afirmación comprobada con un programa, el IL o un benchmark, sobre código real de Guitar Alchemist, con los equivalentes en Spring y Reactor.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Cada salida de las lecciones procede de [`code/csharp-advanced`](https://github.com/spareilleux/learn/tree/main/code/csharp-advanced). [`check.sh`](https://github.com/spareilleux/learn/blob/b4d713f86711b770a75d7504f334c5871c95f820/code/csharp-advanced/check.sh) compila el programa del curso contra [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) clonado en el commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), ejecuta cada lección, desensambla los ejemplos con [la herramienta de línea de comandos de ILSpy](https://github.com/icsharpcode/ILSpy/tree/master/ICSharpCode.ILSpyCmd), compila cada fragmento rechazado con [Roslyn](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/) y lo compara todo con los archivos esperados. [`.github/workflows/csharp-advanced-examples.yml`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/.github/workflows/csharp-advanced-examples.yml) hace lo mismo en Linux, Windows y macOS, y comprueba que cada benchmark se ejecuta. Las líneas que dependen de la máquina empiezan por `# ` y no se comparan; los tiempos de los benchmarks proceden de la máquina del autor, nunca de la CI. Salidas capturadas en septiembre de 2026 con el SDK de .NET 10.0.112 y el runtime de .NET 10.0.12.
:::

## Por qué aprendo esto

Llevo años escribiendo C#, y la mayor parte de lo que sé sobre su rendimiento es folclore: «los structs son más rápidos», «evita LINQ», «usa siempre `ConfigureAwait(false)`», «`FrozenDictionary` es el rápido». Parte de ello era cierto en .NET Framework 4.5 y es falso en .NET 10, donde el JIT elimina asignaciones que el IL pide. Este curso sustituye cada pieza de folclore por algo que puedo observar: el tamaño de un objeto, el IL que emitió el compilador, la máquina de estados que hay detrás de `await`, la generación de un array, una tabla de BenchmarkDotNet.

Lo mismo vale para el código que mueve datos entre tareas y para ASP.NET Core. Uso canales y `BackgroundService` sin haber comprobado qué pasa cuando un consumidor se detiene antes de tiempo o un productor lanza una excepción, y configuro ASP.NET Core copiando lo que funcionó la última vez. Las partes posteriores del curso convierten también esas preguntas en programas.

Las mediciones se hacen sobre código real, no sobre clases de juguete: [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA), una gran base de código .NET 10 sobre teoría musical. Sus objetos de valor, sus cachés, su generador de voicings y sus servicios hospedados son justo el tipo de código donde surgen estas preguntas, y las lecciones encontraron varios lugares donde GA paga por algo que no pretendía, o se bloquea donde debería fallar.

## A quién va dirigido este curso

Escribes C# a diario y conoces bien el lenguaje: genéricos, LINQ, `async`/`await`, records, coincidencia de patrones. Quieres saber qué hacen el compilador, el JIT, el recolector de basura y ASP.NET Core con ese código, y medir antes de optimizar. Si estás empezando con C#, comienza por el curso [C# para principiantes](../csharp-beginner/), que termina donde empieza este.

Si también trabajas con Java, las partes 2 y 3 terminan cada lección con una tabla «Si conoces Spring y Reactor», de C# a Java. El [curso de Spring Boot, Spring Cloud y Reactor](../spring-cloud-reactor/) va en sentido contrario, de ASP.NET Core a Spring; los dos cursos se enlazan entre sí en lugar de explicar dos veces lo mismo.

## Al terminar este curso, sabré

- predecir el tamaño de un valor o de un objeto, detectar el boxing en el IL y saber cuándo lo elimina el JIT;
- usar `ref`, `in`, `ref readonly`, `Span<T>` y `stackalloc` sin copias defensivas ni referencias que escapan;
- explicar las generaciones, los montones de objetos grandes y de objetos fijados y los modos del GC, y leer `GC.GetGCMemoryInfo`;
- leer la máquina de estados que el compilador genera para un método `async`, elegir entre `Task` y `ValueTask`, y evitar interbloqueos y cancelaciones perdidas;
- escribir un benchmark de BenchmarkDotNet que mida lo que creo que mide, e interpretar la compilación por niveles y la PGO;
- elegir entre `Dictionary`, `FrozenDictionary`, `SearchValues` y la aritmética simple, y vectorizar un bucle con `Vector<T>` o `TensorPrimitives`;
- conectar productores y consumidores con canales, TPL Dataflow, Rx.NET o `IAsyncEnumerable`, y decir para cada uno qué ocurre con backpressure, ante un error y ante una cancelación;
- seguir una petición a través de ASP.NET Core, de Kestrel al endpoint, y elegir con criterio las duraciones de los servicios, las opciones, los filtros, los servicios hospedados, la resiliencia y la caché;
- observar y probar un servicio ASP.NET Core, y publicarlo con Native AOT;
- y, en la última parte: árboles de expresión, generadores de código fuente, analizadores de Roslyn e interoperabilidad.

## El ejemplo conductor

Las partes 1 y 2 miden el propio código de GA. La parte 3 construye un pequeño servicio de escalas y acordes sobre los tipos de dominio de GA, el equivalente en ASP.NET Core del servicio de escalas del [curso de Spring Boot, Spring Cloud y Reactor](../spring-cloud-reactor/#el-ejemplo-conductor): los mismos endpoints, para que cada lección pueda comparar las dos implementaciones línea por línea.

## Plan

### Parte 1: runtime y rendimiento

| # | Lección | Bajo el capó | Medido en GA |
|---|---|---|---|
| 1 | [Memoria: valores, referencias y spans](01-memory-values-and-spans/) | disposición de los objetos, boxing en el IL, `ref`/`in`, `ref struct`, `Span<T>`, `stackalloc` | `PitchClass`, `PitchClassSetId.ItemsSpan` |
| 2 | [El recolector de basura](02-garbage-collector/) | generaciones, LOH y POH, GC de estación de trabajo y de servidor, DATAS, finalizadores, `GC.GetGCMemoryInfo` | asignaciones de `ItemsSpan` con `[MemoryDiagnoser]` |
| 3 | [async y await bajo el capó](03-async-under-the-hood/) | la máquina de estados generada, `ValueTask`, `SynchronizationContext`, `ConfigureAwait`, cancelación, `IAsyncEnumerable` | `Try.OfAsync`, `LazyWithExpiration` |
| 4 | [Rendimiento medido](04-measured-performance/) | BenchmarkDotNet, JIT por niveles y PGO, `SearchValues`, `FrozenDictionary`, `Vector<T>` | resta de `PitchClass`, `SimdOps.Dot` |
| 5 | Genéricos en profundidad | restricciones, miembros abstractos estáticos, matemáticas genéricas, `allows ref struct`, cómo comparte el JIT el código genérico | `IStaticValueObjectList<TSelf>` de GA |

### Parte 2: concurrencia y flujo de datos

| # | Lección | Bajo el capó | Spring y Reactor |
|---|---|---|---|
| 6 | [Channels](06-channels/) | canales acotados y no acotados, modos de canal lleno, finalización y errores, varios productores y consumidores, cancelación; el generador de voicings y el comando de indexación de GA | `onBackpressureBuffer`, `onBackpressureDrop`, `BlockingQueue` |
| 7 | [TPL Dataflow](07-tpl-dataflow/) | bloques y enlaces, paralelismo y orden, `BoundedCapacity`, errores que solo bajan, finalización; la demo de Dataflow de GA | `flatMap` con concurrencia, `buffer`, `publishOn` |
| 8 | [Rx.NET](08-rx-net/) | `IObservable<T>`, frío y caliente, operadores en tiempo virtual, schedulers, sin backpressure, reintentos; la demo reactiva de GA | `Flux`, `Sinks`, `publishOn`, `StepVerifier.withVirtualTime` |
| 9 | [Elegir un flujo](09-choosing-streams/) | `IAsyncEnumerable` y `System.Linq.AsyncEnumerable`, los cuatro tipos de flujo medidos lado a lado, puentes, rendimiento, un diagrama de decisión | [Reactor: `Mono` y `Flux`](../spring-cloud-reactor/02-reactor-mono-and-flux/), [Reactor por dentro](../spring-cloud-reactor/03-reactor-under-the-hood/) |
| 10 | Estado compartido y el grupo de subprocesos | `System.Threading.Lock`, `Interlocked`, colecciones concurrentes, `Parallel.ForEachAsync`, inanición del grupo de subprocesos | `synchronized`, `ReentrantLock`, hilos virtuales |

### Parte 3: ASP.NET Core en profundidad

| # | Lección | Bajo el capó | Spring y Reactor |
|---|---|---|---|
| 11 | Hospedaje, `WebApplication` y Kestrel | el host genérico, el builder, los límites de conexión y de petición de Kestrel, el apagado ordenado | [Spring Boot visto desde ASP.NET Core](../spring-cloud-reactor/01-spring-boot-from-aspnet-core/), Tomcat y Netty embebidos |
| 12 | El pipeline de middlewares | `Use`, `Map`, `Run`, orden, cortocircuitos, manejo de excepciones, enrutamiento de endpoints | filtros Servlet, `WebFilter` |
| 13 | Inyección de dependencias y opciones | duraciones, dependencias cautivas, validación de ámbitos, servicios con clave, `IOptions`, `IOptionsSnapshot`, `IOptionsMonitor`, validación | el contenedor de Spring, `@ConfigurationProperties` |
| 14 | Minimal APIs y controladores | manejadores de rutas y enlace de parámetros, filtros, validación, `TypedResults`, respuestas `IAsyncEnumerable` en streaming | `@RestController`, endpoints funcionales de [WebFlux](../spring-cloud-reactor/04-webflux/) |
| 15 | Servicios hospedados | `IHostedService`, `BackgroundService`, orden de arranque y de apagado, excepciones, colas con canales; los servicios hospedados de GA | `@Scheduled`, `SmartLifecycle` |
| 16 | Autenticación y autorización | esquemas, manejadores, JWT bearer, directivas y requisitos | Spring Security |
| 17 | gRPC y SignalR | contratos protobuf, llamadas en streaming, hubs, backpressure a través de la red | Spring gRPC, WebSocket, RSocket |
| 18 | Resiliencia, limitación de velocidad y caché de salida | `Microsoft.Extensions.Http.Resilience`, pipelines de Polly, limitadores de velocidad, directivas de caché de salida | Resilience4j, Spring Cloud Circuit Breaker |
| 19 | OpenTelemetry y diagnóstico en producción | `System.Diagnostics.Metrics`, `ActivitySource`, exportadores de OpenTelemetry, `dotnet-counters`, `dotnet-trace`, `dotnet-dump` | Micrometer, Actuator |
| 20 | Pruebas con `WebApplicationFactory` | el host de pruebas, sustituir servicios, autenticación en las pruebas, Testcontainers | `@SpringBootTest`, `WebTestClient` |
| 21 | Native AOT y recorte | publicar una API con Native AOT, advertencias de recorte, el generador de delegados de solicitud, arranque y tamaño medidos | imágenes nativas de GraalVM |

### Parte 4: metaprogramación y herramientas

| # | Lección | Bajo el capó |
|---|---|---|
| 22 | Árboles de expresión, reflexión y generadores de código fuente | en qué se compila una lambda, `Expression<T>`, el coste de la reflexión, generadores incrementales, `[GeneratedRegex]` |
| 23 | Analizadores y correcciones de código de Roslyn | modelos sintácticos y semánticos, escribir un analizador y sus pruebas |
| 24 | Interoperabilidad y código no seguro | `[LibraryImport]`, punteros de función, `Unsafe`, `MemoryMarshal`, fijación |
| — | [Diario](journal/) | |

Las lecciones 5 y 10 a 24 están planificadas y aún no se han escrito; las lecciones 6 a 9 se escribieron antes que la lección 5, y no dependen de ella.

## Requisitos previos

- El [SDK de .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) y [Git](https://git-scm.com/downloads). En Windows, ejecuta los scripts del curso desde Git Bash.
- `check.sh` restaura [`ilspycmd`](https://www.nuget.org/packages/ilspycmd) como herramienta local de .NET (versión 11.0.0.9375, fijada en [`.config/dotnet-tools.json`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/.config/dotnet-tools.json)), descarga los tres proyectos de GA que usa el programa, unos 11 MB, y restaura [`System.Reactive`](https://www.nuget.org/packages/System.Reactive) 7.0.0 para la lección 8.
- Para los benchmarks, una máquina que puedas mantener tranquila durante unos minutos: cierra el navegador y enchufa el portátil.

## Cursos relacionados en este sitio

- [C# para principiantes](../csharp-beginner/): el lenguaje desde cero, escrito al mismo tiempo que este curso.
- [Spring Boot, Spring Cloud y Reactor para desarrolladores C#](../spring-cloud-reactor/): las mismas preguntas desde el lado de Java, con el mismo ejemplo conductor.
- [Teoría musical para Guitar Alchemist](../music-theory-ga/) lee los mismos proyectos de GA por lo que calculan; este curso los lee por cómo se ejecutan.
- [Rust para desarrolladores C#/Java](../rust-for-csharp-java/) hace explícito lo que .NET decide por ti: ownership en lugar de un recolector de basura, préstamos en lugar de las reglas de seguridad de `ref`.

## Recursos

- [Fundamentos de .NET: administración de memoria y recolección de elementos no utilizados](https://learn.microsoft.com/dotnet/standard/garbage-collection/), y las [opciones de configuración del GC](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector).
- [Referencia del lenguaje C#](https://learn.microsoft.com/dotnet/csharp/language-reference/), en particular los [ref structs](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct) y la [programación asincrónica](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/).
- Stephen Toub, [Performance Improvements in .NET 10](https://devblogs.microsoft.com/dotnet/performance-improvements-in-net-10/) y [How async/await really works in C#](https://devblogs.microsoft.com/dotnet/how-async-await-really-works/), en el blog de .NET.
- El repositorio [dotnet/runtime](https://github.com/dotnet/runtime): las lecciones enlazan las líneas del runtime en las que se apoyan, en la etiqueta `v10.0.12` (commit `4271d88`).
- [BenchmarkDotNet](https://benchmarkdotnet.org/) y sus [buenas prácticas](https://benchmarkdotnet.org/articles/guides/good-practices.html).
- Microsoft Learn: [canales](https://learn.microsoft.com/dotnet/core/extensions/channels), [TPL Dataflow](https://learn.microsoft.com/dotnet/standard/parallel-programming/dataflow-task-parallel-library), [fundamentos de ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/).
- Ian Griffiths y Lee Campbell, [Introduction to Rx.NET, 2nd edition](https://introtorx.com/), gratuito en línea.
- Konrad Kokosa, *Pro .NET Memory Management* (Apress, 2018): anterior a .NET 10, sigue siendo el libro más profundo sobre el GC.
