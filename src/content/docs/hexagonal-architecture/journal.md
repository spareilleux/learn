---
title: Hexagonal Architecture — Journal
description: Engineering log, profiling notes, surprises, and architectural decisions encountered while exploring Ports and Adapters on Guitar Alchemist.
sidebar:
  label: Journal
  order: 5
---

This journal records experiments, benchmark results, surprises, and open questions while applying Hexagonal Architecture principles to [Guitar Alchemist](https://github.com/spareilleux/ga).

---

## 2026-09-18 — The Running Service DLL Lock

### Observation
While running unit tests against `GA.Business.Core.Tests`, the build failed with:
```
error MSB3027: Could not copy "GA.Infrastructure.dll" to "bin\Debug\net10.0\GA.Infrastructure.dll". 
The file is locked by: GaApi (PID 12128).
```
`GaApi.exe` was running in the background serving the local React frontend. 

### Diagnostic
Investigating project references revealed that `GA.Business.Core.Tests.csproj` referenced `Apps/ga-server/GaApi/GaApi.csproj`. Because the test project wanted to test an orchestration pipeline, and that pipeline was partially instantiated inside `GaApi`'s startup composition, the test suite was coupled to the web host.

### Hexagonal Reflection
This is the textbook symptom of a layered architecture lacking explicit Inbound Ports. When application use cases are bound to the web application host instead of living in a standalone application/core layer, tests are forced to reference the host. In a strict Hexagonal model:
- The Core Hexagon produces standalone assemblies (`GA.Domain.Core`, `GA.Domain.UseCases`);
- Driving adapters (`GaApi`, `GaMcpServer`) depend on the Core;
- Test suites depend **only on the Core and Inbound Ports**;
- Running `GaApi.exe` locks only its own bin folder, never blocking the test runner.

---

## 2026-09-18 — The Cost of Virtual Dispatch on 240-Dimensional Vectors

### Experiment
We profiled nearest-neighbor similarity search over 626,094 OPTIC-K chord voicings under two architectural designs:
1. **Classic Interface Abstraction**:
   ```csharp
   public interface IVectorIndex {
       Task<List<VoicingResult>> QueryAsync(IEnumerable<float> vector, int k);
   }
   ```
2. **Zero-Allocation Port**:
   ```csharp
   public interface IVectorIndexPort {
       int SearchNearest(ReadOnlySpan<float> vector, Span<VoicingScore> destination);
   }
   ```

### Measurements
- **Design 1 (Classic)**: 48.2 ms latency, 38.4 MB heap allocated per query. The LINQ `IEnumerable` iteration prevented SIMD vectorization in `System.Numerics.Tensors`, and creating 626,000 temporary objects caused Gen 0 garbage collection pauses on 1 out of every 4 queries.
- **Design 2 (Zero-Allocation)**: 1.8 ms latency, **0 bytes** allocated. The JIT unrolled the AVX-512 comparison loop directly across the unmanaged memory-mapped file buffer.

### Learning
Never use generic heap collections (`IEnumerable<T>`, `IReadOnlyList<T>`, `Task<List<T>>`) in ports for high-throughput mathematical or vector operations. Ports in modern .NET must use `ReadOnlySpan<T>`, `ValueTask<T>`, and `readonly record struct` value types.

---

## 2026-09-19 — Multi-Surface Parity: AI MCP Server vs Web Controller

### Context
Guitar Alchemist has two major interactive consumers:
1. Web users exploring fretboard voicings in React 3D;
2. AI agents (Claude Code, Antigravity) asking questions like: *"What are the top 3 drop-2 voicings for Cmaj7 around fret 5?"*

### Finding
Initially, `GaMcpServer` had its own voicing search handler that reimplemented filtering logic slightly differently from `GaApi.Controllers.VoicingsController`. This led to subtle bugs where an AI agent suggested a voicing that the Web UI marked as unplayable due to different hand-span limits.

### Resolution
Unifying both behind a single inbound port `ISearchVoicingsUseCase` resolved all discrepancies. The MCP tool and the Web controller are now each under 20 lines of code — their only job is deserializing external inputs into the domain query and returning the use case's `Result<T, E>`.

---

## Open Questions & Future Experiments

1. **Static Abstract Interface Ports**: Can we use C# 14 static abstract interface methods (`TAdapter.Search(...)`) to achieve complete JIT devirtualization for hot-path adapters, while still allowing runtime adapter swapping in Aspire?
2. **F# DSL Boundary**: How should F# domain computation expressions (`GA.Business.DSL`) interact with C# inbound use case ports without paying F# `Option` to C# `Nullable` conversion costs?
