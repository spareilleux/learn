---
title: "Go for C# and Java developers — Mission"
description: "A complete introduction to Go 1.27 through a tested study-log CLI."
sidebar:
  label: Mission
  order: 0
---

## Why learn this

You already know how to model data, handle failure and build applications in C# or Java. Go keeps many of those goals but changes the mechanisms: copied values, slice descriptors, implicit interfaces, explicit errors, goroutines and a small standard toolchain. This course builds a concrete bridge from those existing skills. The objective is to make correct predictions about a Go program and ship a small understandable command, rather than translate class syntax mechanically.

## Prerequisites

Be comfortable with functions, collections, interfaces, generics, basic JSON and unit tests in either C# or Java. You need a terminal, an editor and the [Go toolchain](https://go.dev/doc/install). The language baseline is Go 1.27 and the coordinator’s installed compiler is Go 1.27.1 on Windows/amd64. The examples use only the standard library, so there is no framework, account or external API to configure.

## What you will build

The study-log CLI reads a JSON array of sessions, validates names and durations, filters by minimum minutes and prints an ordered report. By the final lesson, the executable composes the same study package used throughout the course. A small HTTP handler is a second adapter around that core. Networking exercises run in memory; no public service is required. You will learn where value copying ends, who owns resources, how to preserve error identity and how to test the complete application boundary.

## Course plan

| # | Lesson | Builds toward |
|---|---|---|
| 1 | [Toolchain and modules](01-toolchain-and-modules/) | A shared local package |
| 2 | [Values, types and strings](02-values-types-and-strings/) | Typed durations and names |
| 3 | [Control flow and functions](03-control-flow-and-functions/) | Selection and totals |
| 4 | [Arrays and slices](04-arrays-and-slices/) | Explicit ownership of collections |
| 5 | [Maps and structs](05-maps-and-structs/) | Named records and aggregation |
| 6 | [Pointers and methods](06-pointers-and-methods/) | Controlled mutation |
| 7 | [Interfaces and composition](07-interfaces-and-composition/) | Small behavior contracts |
| 8 | [Errors, defer and resources](08-errors-defer-and-resources/) | Useful input diagnostics |
| 9 | [Files, JSON and Unicode](09-files-json-and-unicode/) | Validated JSON records |
| 10 | [Generics and collections](10-generics-and-collections/) | Typed transformations |
| 11 | [Goroutines and channels](11-goroutines-and-channels/) | Bounded work lifetimes |
| 12 | [HTTP and context](12-http-and-context/) | A testable HTTP boundary |
| 13 | [Testing](13-testing/) | Behavior and integration checks |
| 14 | [CLI capstone](14-cli-capstone/) | A working report command |

## How to study

Read the lessons in order. Predict the output before executing each command and keep experimental edits separate from the fixtures. Each chapter includes two corrected exercises; attempt them before opening the solutions. The identical code, commands and output contracts are used in English, French and Spanish. Platform-neutral commands start from the repository root and then enter code/go-for-csharp-java. The complete source is in [code/go-for-csharp-java](https://github.com/spareilleux/learn/tree/main/code/go-for-csharp-java).

## Verification and limits

The module includes fourteen runnable commands, an exact-output examples.json manifest, semantic unit tests, CLI integration tests, HTTP handler tests and a loader fuzz target. Tests, vet, formatting, all fourteen exact outputs and a bounded loader fuzz run passed on Go 1.27.1 under Windows/amd64. Source snippets and translations were checked against the completed module. The [journal](journal/) records conditions, findings and separate evidence for hosted CI, publication and learner study. The capstone reads a local log; it does not provide accounting or durable streaming guarantees.

Continue with [Advanced Go](../go-advanced/) after completing the capstone.

## Primary resources

- [Go 1.27](https://go.dev/doc/go1.27)
- [Language specification](https://go.dev/ref/spec)
- [Standard library](https://pkg.go.dev/std)
- [Module tutorial](https://go.dev/doc/tutorial/create-module)
