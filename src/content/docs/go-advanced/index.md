---
title: "Advanced Go for C#/Java developers — Mission"
description: "Fourteen practical lessons on ownership, concurrency, boundaries and a tested HTTP job service."
sidebar:
  label: "Mission"
  order: 0
---

## Why study advanced Go?

Knowing syntax is not enough to review a service that owns buffers, coordinates workers and must stop predictably. This course develops those skills by following concrete contracts through small reusable packages. Its audience already understands C# or Java services and has completed [Go for C#/Java developers](../go-for-csharp-java/). You should be comfortable with slices, interfaces, errors, goroutines, channels, HTTP and basic tests before beginning.

The target is **Go 1.27**, with the authored module declaring `go 1.27.0`. The installed verification compiler supplied for this work is Go 1.27.1 on Windows/amd64. Current version semantics matter: Go 1.27 supports generic methods and stabilizes JSON v2. Read the [official release notes](https://go.dev/doc/go1.27) alongside the [language specification](https://go.dev/ref/spec) rather than applying an older tutorial's restrictions.

## What you will be able to do

- Choose package boundaries and make ownership explicit.
- Explain memory visibility and limit concurrent work.
- Preserve error contracts and distinguish typed nil from nil interfaces.
- Build bounded HTTP and framing boundaries with deterministic local tests.
- Design fuzz properties and performance experiments without inventing results.
- Integrate validation, copied admission, cancellation and drain in a complete service.

## How to work through the course

The code lives in [code/go-advanced](https://github.com/spareilleux/learn/tree/main/code/go-advanced), an independent standard-library-only module. Each lesson shows exact checked-in Go files and a command under `cmd/l01` through `cmd/l14`. Start in the repository root, enter `code/go-advanced` and run the lesson command. No container, database, credential, external service or separately installed framework is needed.

Predict output before execution, explain why each result is safe to observe, then solve both exercises before opening their complete solutions. The expected stdout contracts live in `examples.json`. Tests cover ownership, error identities, iterator stopping, atomics, cancellation, framing, HTTP and service drain. The capstone is an in-memory bounded job service, not a production deployment template or a durable queue.

The commands use portable Go CLI syntax on Windows, Linux/WSL and macOS. Race instrumentation has platform and C toolchain requirements beyond an ordinary test run; check the official detector documentation before running it. Profiling listeners must remain on loopback. Benchmark, active fuzz, trace and escape-analysis results need their own recorded conditions and are not implied by a successful build.

## Course plan

1. [Package and module boundaries](01-package-and-module-boundaries/)
2. [Memory, escape analysis and GC](02-memory-escape-and-gc/)
3. [Generics and iterators](03-generics-and-iterators/)
4. [Error contracts and typed nil](04-error-contracts-and-typed-nil/)
5. [Memory model, synchronization and atomics](05-memory-model-sync-and-atomics/)
6. [Bounded pipelines](06-bounded-pipelines/)
7. [Cancellation, deadlines and shutdown](07-cancellation-deadlines-and-shutdown/)
8. [Production HTTP boundaries](08-production-http/)
9. [Streaming and framing](09-streaming-and-framing/)
10. [Race, fuzz and property tests](10-race-fuzz-and-property-tests/)
11. [Benchmarks, pprof and trace](11-benchmarks-pprof-and-trace/)
12. [Reflection, encoding and boundaries](12-reflection-and-encoding/)
13. [Dependencies, builds and security](13-dependencies-builds-and-security/)
14. [An integrated HTTP job service](14-service-capstone/)

## Resources

- [Go](https://go.dev/doc/)
- [Go 1.27](https://go.dev/doc/go1.27)
- [Specification](https://go.dev/ref/spec)
- [Memory model](https://go.dev/ref/mem)
- [Standard library](https://pkg.go.dev/std)

## Journal and verification status

The [learning journal](journal/) separates authored material, actual technical verification, pending measurements and learner questions. Compilation and example replay do not establish that a human learner can complete the course.
