---
title: Architecture patterns — Mission
description: Compare layered, onion, clean, hexagonal and modular-monolith designs on one practice-plan use case, with falsifiable decisions and failure exercises.
sidebar:
  label: Mission
  order: 0
---

## Mission

Choose a boundary because it makes a specific change safer or cheaper. This course compares five architectural patterns without treating them as a ranking. It complements the [hexagonal architecture course](../hexagonal-architecture/) by asking when a simpler layered design is sufficient, how onion and clean architecture overlap with ports and adapters, and why a modular monolith addresses a different decision.

Our tracer use case is **save a guitarist's practice plan**: accept a named plan containing three chord shapes, validate it against a catalog revision, persist it, and return a receipt. All four lessons use this same case. It is a teaching design, not a feature implemented in any ecosystem repository.

## Prerequisites and completion

Know functions, interfaces, a database transaction and the difference between a process and a library. No account, paid model or service is required. The exercises are design and failure-trace exercises with worked solutions; there is no executable application or performance benchmark in this first slice.

You finish with a dependency map, a contract, a failure table and a one-page decision whose rejection conditions another developer can test. Suggested time: two hours; this is a study estimate, not a measured completion time.

## Plan

| Lesson | Deliverable |
|---|---|
| [1. Start with a change](01-change-and-boundaries/) | Assumptions, invariants and a measurable baseline |
| [2. Five patterns, one use case](02-five-patterns/) | Dependency and ownership comparison |
| [3. When a boundary crosses a process](03-failure-and-distribution/) | Retry, concurrency and recovery contract |
| [4. Evaluate an ecosystem seam](04-ecosystem-decisions/) | Bounded GA/Gaia/IX/Demerzel experiment and decision |
| [Journal](journal/) | Sources, validation evidence and unverified work |

## Primary resources

- [Microsoft: common web application architectures](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures).
- [Cockburn: original ports and adapters article](https://alistair.cockburn.us/hexagonal-architecture).
- [Palermo: onion architecture, part 1](https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/).
- [Martin: clean architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html).
- [Spring Modulith: module fundamentals](https://docs.spring.io/spring-modulith/reference/fundamentals.html) and [structural verification](https://docs.spring.io/spring-modulith/reference/verification.html).
- [Amazon Builders' Library: idempotent APIs](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).

These sources establish terminology. Our workload, thresholds, trade-off judgments and proposed ecosystem experiments are course assumptions, not conclusions measured in those sources.
