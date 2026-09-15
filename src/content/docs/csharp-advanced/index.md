---
title: Advanced C# — Mission
description: What happens under the hood of C# 14, .NET 10 and ASP.NET Core — memory, the garbage collector, async, measured performance, channels, TPL Dataflow, Rx.NET and async streams, then the web stack and the tooling — each claim checked by a program, the IL or a benchmark, on real Guitar Alchemist code, with the Spring and Reactor equivalents.
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
Every output in the lessons comes from [`code/csharp-advanced`](https://github.com/spareilleux/learn/tree/main/code/csharp-advanced). [`check.sh`](https://github.com/spareilleux/learn/blob/b4d713f86711b770a75d7504f334c5871c95f820/code/csharp-advanced/check.sh) builds the course program against [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) cloned at commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), runs each lesson, disassembles the examples with [ILSpy's command-line tool](https://github.com/icsharpcode/ILSpy/tree/master/ICSharpCode.ILSpyCmd), compiles every rejected snippet with [Roslyn](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/), and compares all of it with the expected files. [`.github/workflows/csharp-advanced-examples.yml`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/.github/workflows/csharp-advanced-examples.yml) does the same on Linux, Windows and macOS, and checks that every benchmark runs. Lines that depend on the machine start with `# ` and are not compared; benchmark timings come from the author's machine, never from CI. Outputs captured in September 2026 with the .NET SDK 10.0.112 and the .NET 10.0.12 runtime.
:::

## Why I'm learning this

I have written C# for years, and most of what I know about its performance is folklore: "structs are faster", "avoid LINQ", "always `ConfigureAwait(false)`", "`FrozenDictionary` is the fast one". Some of it was true in .NET Framework 4.5 and is wrong on .NET 10, where the JIT removes allocations the IL asks for. This course replaces each piece of folklore with something I can look at: the size of an object, the IL the compiler emitted, the state machine behind `await`, the generation of an array, a BenchmarkDotNet table.

The same goes for the code that moves data between tasks and for ASP.NET Core. I use channels and `BackgroundService` without having checked what happens when a consumer stops early or a producer throws, and I configure ASP.NET Core by copying what worked last time. The later parts of the course run those questions as programs too.

The measurements run on real code, not toy classes: [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA), a large .NET 10 code base about music theory. Its value objects, its caches, its voicing generator and its hosted services are exactly the kind of code where these questions come up, and the lessons found several places where GA pays for something it didn't intend to, or hangs where it should fail.

## Who this course is for

You write C# every day and know the language well: generics, LINQ, `async`/`await`, records, pattern matching. You want to know what the compiler, the JIT, the garbage collector and ASP.NET Core do with that code, and to measure before you optimize. If you are starting with C#, begin with the [C# for beginners](../csharp-beginner/) course, which ends where this one starts.

If you also work with Java, parts 2 and 3 end each lesson with an "If you know Spring and Reactor" table, from C# to Java. The [Spring Boot, Spring Cloud and Reactor course](../spring-cloud-reactor/) goes the other way, from ASP.NET Core to Spring; the two courses link to each other instead of explaining the same thing twice.

## By the end of this course, I will be able to

- predict the size of a value or an object, spot boxing in IL, and tell when the JIT removes it;
- use `ref`, `in`, `ref readonly`, `Span<T>` and `stackalloc` without defensive copies or escaping references;
- explain generations, the large and pinned object heaps and the GC modes, and read `GC.GetGCMemoryInfo`;
- read the state machine the compiler generates for an `async` method, choose between `Task` and `ValueTask`, and avoid deadlocks and lost cancellations;
- write a BenchmarkDotNet benchmark that measures what I think it measures, and interpret tiered compilation and PGO;
- choose between `Dictionary`, `FrozenDictionary`, `SearchValues` and plain arithmetic, and vectorize a loop with `Vector<T>` or `TensorPrimitives`;
- connect producers and consumers with channels, TPL Dataflow, Rx.NET or `IAsyncEnumerable`, and say for each what happens under backpressure, on an error and on cancellation;
- follow a request through ASP.NET Core, from Kestrel to the endpoint, and choose service lifetimes, options, filters, hosted services, resilience and caching deliberately;
- observe and test an ASP.NET Core service, and publish it with Native AOT;
- and, in the last part: expression trees, source generators, Roslyn analyzers and interop.

## The running example

Parts 1 and 2 measure GA's own code. Part 3 builds a small scales and chords service on GA's domain types, the ASP.NET Core counterpart of the scales service in the [Spring Boot, Spring Cloud and Reactor course](../spring-cloud-reactor/#the-running-example): the same endpoints, so that each lesson can compare the two implementations line by line.

## Outline

### Part 1: runtime and performance

| # | Lesson | Under the hood | Measured on GA |
|---|---|---|---|
| 1 | [Memory: values, references and spans](01-memory-values-and-spans/) | object layout, boxing in IL, `ref`/`in`, `ref struct`, `Span<T>`, `stackalloc` | `PitchClass`, `PitchClassSetId.ItemsSpan` |
| 2 | [The garbage collector](02-garbage-collector/) | generations, LOH and POH, workstation and server GC, DATAS, finalizers, `GC.GetGCMemoryInfo` | allocations of `ItemsSpan` with `[MemoryDiagnoser]` |
| 3 | [async and await under the hood](03-async-under-the-hood/) | the generated state machine, `ValueTask`, `SynchronizationContext`, `ConfigureAwait`, cancellation, `IAsyncEnumerable` | `Try.OfAsync`, `LazyWithExpiration` |
| 4 | [Measured performance](04-measured-performance/) | BenchmarkDotNet, tiered JIT and PGO, `SearchValues`, `FrozenDictionary`, `Vector<T>` | `PitchClass` subtraction, `SimdOps.Dot` |
| 5 | Generics in depth | constraints, static abstract members, generic math, `allows ref struct`, how the JIT shares generic code | GA's `IStaticValueObjectList<TSelf>` |

### Part 2: concurrency and data flow

| # | Lesson | Under the hood | Spring and Reactor |
|---|---|---|---|
| 6 | [Channels](06-channels/) | bounded and unbounded channels, full modes, completion and errors, several producers and consumers, cancellation; GA's voicing generator and index command | `onBackpressureBuffer`, `onBackpressureDrop`, `BlockingQueue` |
| 7 | [TPL Dataflow](07-tpl-dataflow/) | blocks and links, parallelism and order, `BoundedCapacity`, faults that only flow downstream, completion; GA's Dataflow demo | `flatMap` with concurrency, `buffer`, `publishOn` |
| 8 | [Rx.NET](08-rx-net/) | `IObservable<T>`, cold and hot, operators in virtual time, schedulers, no backpressure, retries; GA's reactive demo | `Flux`, `Sinks`, `publishOn`, `StepVerifier.withVirtualTime` |
| 9 | [Choosing a stream](09-choosing-streams/) | `IAsyncEnumerable` and `System.Linq.AsyncEnumerable`, the four stream types measured side by side, bridges, throughput, a decision chart | [Reactor: `Mono` and `Flux`](../spring-cloud-reactor/02-reactor-mono-and-flux/), [Reactor under the hood](../spring-cloud-reactor/03-reactor-under-the-hood/) |
| 10 | Shared state and the thread pool | `System.Threading.Lock`, `Interlocked`, concurrent collections, `Parallel.ForEachAsync`, thread pool starvation | `synchronized`, `ReentrantLock`, virtual threads |

### Part 3: ASP.NET Core in depth

| # | Lesson | Under the hood | Spring and Reactor |
|---|---|---|---|
| 11 | Hosting, `WebApplication` and Kestrel | the generic host, the builder, Kestrel's connection and request limits, graceful shutdown | [Spring Boot seen from ASP.NET Core](../spring-cloud-reactor/01-spring-boot-from-aspnet-core/), embedded Tomcat and Netty |
| 12 | The middleware pipeline | `Use`, `Map`, `Run`, ordering, short-circuits, exception handling, endpoint routing | Servlet filters, `WebFilter` |
| 13 | Dependency injection and options | lifetimes, captive dependencies, scope validation, keyed services, `IOptions`, `IOptionsSnapshot`, `IOptionsMonitor`, validation | the Spring container, `@ConfigurationProperties` |
| 14 | Minimal APIs and controllers | route handlers and parameter binding, filters, validation, `TypedResults`, streaming `IAsyncEnumerable` responses | `@RestController`, [WebFlux](../spring-cloud-reactor/04-webflux/) functional endpoints |
| 15 | Hosted services | `IHostedService`, `BackgroundService`, startup and shutdown order, exceptions, queues with channels; GA's hosted services | `@Scheduled`, `SmartLifecycle` |
| 16 | Authentication and authorization | schemes, handlers, JWT bearer, policies and requirements | Spring Security |
| 17 | gRPC and SignalR | protobuf contracts, streaming calls, hubs, backpressure over the network | Spring gRPC, WebSocket, RSocket |
| 18 | Resilience, rate limiting and output caching | `Microsoft.Extensions.Http.Resilience`, Polly pipelines, rate limiters, output cache policies | Resilience4j, Spring Cloud Circuit Breaker |
| 19 | OpenTelemetry and diagnostics in production | `System.Diagnostics.Metrics`, `ActivitySource`, OpenTelemetry exporters, `dotnet-counters`, `dotnet-trace`, `dotnet-dump` | Micrometer, Actuator |
| 20 | Testing with `WebApplicationFactory` | the test host, replacing services, authentication in tests, Testcontainers | `@SpringBootTest`, `WebTestClient` |
| 21 | Native AOT and trimming | publishing an API with Native AOT, trimming warnings, the request delegate generator, startup and size measured | GraalVM native images |

### Part 4: metaprogramming and tooling

| # | Lesson | Under the hood |
|---|---|---|
| 22 | Expression trees, reflection and source generators | what a lambda compiles to, `Expression<T>`, the cost of reflection, incremental generators, `[GeneratedRegex]` |
| 23 | Roslyn analyzers and code fixes | syntax and semantic models, writing an analyzer and its tests |
| 24 | Interop and unsafe code | `[LibraryImport]`, function pointers, `Unsafe`, `MemoryMarshal`, pinning |
| — | [Journal](journal/) | |

Lessons 5 and 10 to 24 are planned and not written yet; lessons 6 to 9 were written before lesson 5, and don't depend on it.

## Prerequisites

- The [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) and [Git](https://git-scm.com/downloads). On Windows, run the course scripts from Git Bash.
- `check.sh` restores [`ilspycmd`](https://www.nuget.org/packages/ilspycmd) as a local .NET tool (version 11.0.0.9375, pinned in [`.config/dotnet-tools.json`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/.config/dotnet-tools.json)), fetches the three GA projects the program uses, about 11 MB, and restores [`System.Reactive`](https://www.nuget.org/packages/System.Reactive) 7.0.0 for lesson 8.
- For the benchmarks, a machine you can keep quiet for a few minutes: close the browser, plug in the laptop.

## Related courses on this site

- [C# for beginners](../csharp-beginner/): the language from zero, written at the same time as this course.
- [Spring Boot, Spring Cloud and Reactor for C# developers](../spring-cloud-reactor/): the same questions from the Java side, with the same running example.
- [Music theory for Guitar Alchemist](../music-theory-ga/) reads the same GA projects for what they compute; this course reads them for how they run.
- [Rust for C#/Java developers](../rust-for-csharp-java/) makes explicit what .NET decides for you: ownership instead of a garbage collector, borrowing instead of `ref` safety rules.

## Resources

- [.NET fundamentals: memory management and garbage collection](https://learn.microsoft.com/dotnet/standard/garbage-collection/), and the [GC configuration settings](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector).
- [C# language reference](https://learn.microsoft.com/dotnet/csharp/language-reference/), in particular [ref structs](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct) and [asynchronous programming](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/).
- Stephen Toub, [Performance Improvements in .NET 10](https://devblogs.microsoft.com/dotnet/performance-improvements-in-net-10/) and [How async/await really works in C#](https://devblogs.microsoft.com/dotnet/how-async-await-really-works/), on the .NET blog.
- The [dotnet/runtime](https://github.com/dotnet/runtime) repository: the lessons link the lines of the runtime they rely on, at tag `v10.0.12` (commit `4271d88`).
- [BenchmarkDotNet](https://benchmarkdotnet.org/) and its [good practices](https://benchmarkdotnet.org/articles/guides/good-practices.html).
- Microsoft Learn: [channels](https://learn.microsoft.com/dotnet/core/extensions/channels), [TPL Dataflow](https://learn.microsoft.com/dotnet/standard/parallel-programming/dataflow-task-parallel-library), [ASP.NET Core fundamentals](https://learn.microsoft.com/aspnet/core/fundamentals/).
- Ian Griffiths and Lee Campbell, [Introduction to Rx.NET, 2nd edition](https://introtorx.com/), free online.
- Konrad Kokosa, *Pro .NET Memory Management* (Apress, 2018): older than .NET 10, still the deepest book on the GC.
