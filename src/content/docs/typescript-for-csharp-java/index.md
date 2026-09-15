---
title: TypeScript for C#/Java developers — Mission
description: TypeScript for developers who know C# or Java and have taken the JavaScript course — every example, compiler error and solution checked by tsc 7.0.2 and run by Node.js 24 in CI on Windows, Linux and macOS, with the C# and Java side next to it.
sidebar:
  label: Mission
  order: 0
---

:::note[Version studied]
[TypeScript](https://www.typescriptlang.org/) **7.0.2**, the first stable release of the compiler ported to Go, published on 2026-07-08, and [Node.js](https://nodejs.org/) **24.21.0**, whose type stripping runs the `.ts` files of the course without a build step. Every example is in [`code/typescript-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/typescript-for-csharp-java), with its own `package.json` and lock file that pin `typescript` 7.0.2, `@types/node` 24.13.4 and tsx 4.23.13. [`.github/workflows/typescript-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/typescript-examples.yml) installs Node.js 24.21.0, .NET 10 and Java 25 on Linux, Windows and macOS, runs `tsc` on the project and on every error snippet, runs every example and solution with Node.js, compiles the C# and Java comparisons, and compares all the outputs with the ones pasted in the lessons.
:::

## Why I'm learning this

The front ends of [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) are written in TypeScript, and so are the configuration files of this site. I read that code as a C# developer, and it looks like C# with the types in the wrong place, until it doesn't: an object is accepted where a class was expected, a cast converts nothing, a generic has no `T` at run time, and a program with type errors runs anyway.
The [JavaScript course](../javascript-for-csharp-java/) covered what happens at run time. This one covers what `tsc` checks, what it can't, and where the two meet.

## Who this course is for

You are comfortable with C# or Java, including generics, interfaces and nullable reference types or `Optional`, and you have followed the [JavaScript for C#/Java developers](../javascript-for-csharp-java/) course, or know its content: modules and npm, values and conversions, functions and `this`, prototypes and classes. The lessons link to its pages instead of explaining JavaScript again.

Components, JSX and the DOM belong to the **React (Vite)** course that follows this one. This course runs TypeScript in Node.js, where every example can be checked and run in CI, and looks at React code only as data from the GA repository.

## TypeScript in one table

| | C# | Java | TypeScript |
|---|---|---|---|
| Compiler | `csc`, through `dotnet build` | `javac` | `tsc`, which checks and can write JavaScript |
| Project file | `.csproj` | `pom.xml`, `build.gradle` | `tsconfig.json`, next to `package.json` |
| Types at run time | reified: `typeof(T)`, `is T` | erased generics, checked casts | none: every type is erased, casts included |
| Compatibility | nominal: declared inheritance | nominal | structural: the same shape is the same type |
| A type error | stops the build | stops the build | stops nothing unless the build asks `tsc` |
| Absent value | `string?` with warnings | `Optional<T>`, annotations | `string \| undefined`, errors under `strictNullChecks` |
| One of several cases | class hierarchy, `switch` with patterns | `sealed interface`, `switch` with patterns | union types and narrowing |
| Generics | reified, variance on interfaces | erased, wildcards | erased, structural variance, types computed from types |

## The data

The lessons use real code as material. [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) is quoted at commit [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6), in its two React front ends, [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components) and [`Apps/ga-client`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client), which I installed and checked with `tsc` 5.9.3 and 7.0.2. This site, built with [Astro](https://docs.astro.build/), is the other TypeScript project, at commit [`8ba378e`](https://github.com/spareilleux/learn/commit/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3). The lessons reduce the lines they quote to files that run on their own, and say where each one comes from. What `tsc` found in those projects is in the [journal](journal/).

## By the end of this course, I will be able to

- set up a TypeScript project for Node.js, read its `tsconfig.json`, and make type errors fail the build;
- read a `tsc` diagnostic and relate its code to what C# or Java would have said;
- predict when two types are compatible, and give a type a name when structure isn't enough;
- model data as unions, narrow them, and get a compile error when a case is missing;
- check data from outside the program at the border, instead of asserting its type;
- write generic functions and types, and explain why `new T()` and `instanceof T` don't exist;
- compute types from other types with `keyof`, mapped and conditional types;
- type a JavaScript library, a Node.js package and a front end built with Vite, and migrate a JavaScript project to `strict`.

## Outline

| # | Lesson | You already know |
|---|---|---|
| 1 | [The compiler and the tooling](01-compiler-and-tooling/) | `csc`, `javac`, `.csproj`, compiler warnings and errors |
| 2 | [Structural typing](02-structural-typing/) | interfaces, `var`, `readonly`/`final`, `object`, `dynamic`, nullable reference types |
| 3 | [Unions and narrowing](03-unions-and-narrowing/) | class hierarchies, `switch` with patterns, sealed interfaces, casts |
| 4 | [Generics](04-generics/) | `List<T>`, constraints, `IEnumerable<out T>`, wildcards, type erasure |
| 5 | Type-level programming: conditional types, `infer`, template literal types and `satisfies` (coming next) | overload resolution, `typeof`, attributes |
| 6 | Classes in TypeScript: modifiers, `abstract`, `implements`, decorators | classes, access modifiers, attributes and annotations |
| 7 | Modules and declaration files: `.d.ts`, `@types`, `declare module`, typing JavaScript with JSDoc | reference assemblies, `extern`, JAR metadata |
| 8 | Asynchronous code and errors: `Promise<T>`, typed errors, result types | `Task<T>`, exceptions, `CompletableFuture`, checked exceptions |
| 9 | Data at the border: `fetch`, JSON, schema validation and types generated from OpenAPI | `System.Text.Json`, Jackson, NSwag, OpenAPI Generator |
| 10 | Testing code and types: Vitest, `@ts-expect-error`, type tests | xUnit, JUnit, analyzers |
| 11 | Projects at scale: project references, `tsc -b`, monorepos, typescript-eslint | solutions, multi-module Maven builds, analyzers |
| 12 | Migrating to `strict`: GuitarAlchemist/ga's front ends, and TypeScript 6 to 7 | enabling nullable reference types on an existing project |
| — | [Journal](journal/) | |

## Resources

- [The TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) and the [TSConfig reference](https://www.typescriptlang.org/tsconfig/)
- [TypeScript release notes](https://www.typescriptlang.org/docs/handbook/release-notes/overview.html), and the [TypeScript 7 announcement](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/)
- [microsoft/TypeScript](https://github.com/microsoft/TypeScript), whose [`diagnosticMessages.json`](https://github.com/microsoft/TypeScript/blob/v6.0.3/src/compiler/diagnosticMessages.json) lists every error code, and [microsoft/typescript-go](https://github.com/microsoft/typescript-go), the Go port
- [Node.js 24 — Modules: TypeScript](https://nodejs.org/docs/latest-v24.x/api/typescript.html)
- [ECMAScript® Language Specification](https://tc39.es/ecma262/), the language that TypeScript adds types to
