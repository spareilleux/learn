---
title: Advanced TypeScript — Mission
description: The type system, the tooling and TypeScript at scale, for developers who write strict TypeScript every day — every type test, compiler error and example checked by tsc 7.0.2 and run by Node.js 24, with the C# and Java side, on the front end and hub of Guitar Alchemist.
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
Every output in the lessons comes from [`code/typescript-advanced`](https://github.com/spareilleux/learn/tree/main/code/typescript-advanced), which has its own `package.json` and lock file: [TypeScript](https://www.typescriptlang.org/) **7.0.2**, `@types/node` 24.13.4, [Zod](https://zod.dev/) 4.6.5, [Valibot](https://valibot.dev/) 1.5.0, [ArkType](https://arktype.io/) 2.2.3, `@standard-schema/spec` 1.1.0 and [esbuild](https://esbuild.github.io/) 0.28.2. [`check.sh`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/check.sh) runs `tsc` on the project, whose type tests must pass, and on every error snippet alone; runs every example and solution with [Node.js](https://nodejs.org/) 24.21.0; bundles the same schema with each validation library; compiles and runs the C# and Java comparisons; and compares all of it with the files in `expected/`. A workflow that does the same on Linux, Windows and macOS is written and hasn't run yet (*to verify*). Outputs captured in September 2026.
:::

## Why I'm learning this

After the [TypeScript for C#/Java developers](../typescript-for-csharp-java/) course, I can read and write strict TypeScript. What I can't do yet is read the types that libraries are made of: a Zod schema whose type is computed from its definition, a router that knows the parameters of a path from the path string, an event emitter that checks the name of an event and the shape of its payload. Those types are programs, run by the checker, and they have their own control flow, their own recursion and their own limits.

The other half is what happens around the checker: what a type promises when the data comes from a socket, how a large project is compiled, what the declaration files of a package say, and what changed when the compiler was rewritten in Go. This course takes each of those apart, on real code: the front end of [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) and the SignalR hub it talks to.

## Who this course is for

You write TypeScript with `strict` on, and you are comfortable with unions, narrowing, generics, `keyof` and a first mapped type, which are lessons 2 to 4 of the base course. You know C# or Java well, since the comparisons are with them. You don't need to have written a conditional type or a declaration file.

The base course introduces each tool where a C# or Java developer first needs it. This course assumes that you use them, and looks at how the checker evaluates them, where they stop working, and how libraries are built on top of them. Components, JSX and the DOM belong to the [React (Vite)](../react-vite/) course.

## Advanced TypeScript in one table

| | C# | Java | TypeScript |
|---|---|---|---|
| Computing a type from another | source generators, T4 | annotation processors | conditional, mapped and template literal types, run by the checker |
| A string that carries a type | no: a typed key object | no: a `Class<T>` token | a literal type: `'NodeChanged'` is a type |
| Declared variance | `in`/`out` on interfaces and delegates, checked | `? extends`, `? super` at the use site | measured from the structure; `in`/`out` optional, partly checked |
| A nominal wrapper | `readonly record struct`, no allocation | a record, an object | a brand, erased: zero cost, zero run-time check |
| Checking data from outside | the types exist at run time: `System.Text.Json` can check them | Jackson, Bean Validation | a schema library, whose type is derived from the schema |
| Expected failures | exceptions, or a result type | checked exceptions | a result union, and exceptions for bugs |

## The data

The lessons use [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) at commit [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381): the component library [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components), in particular its Prime Radiant governance view, and the C# hub that feeds it, [`Apps/ga-server/GaApi/Hubs/GovernanceHub.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Apps/ga-server/GaApi/Hubs/GovernanceHub.cs). The lessons reduce the lines they quote to files that run on their own and say where each one comes from. The checker's own source is quoted from [microsoft/typescript-go](https://github.com/microsoft/typescript-go) at the tag `typescript/v7.0.2` (commit [`2bd066d`](https://github.com/microsoft/typescript-go/tree/2bd066d87f5bafd315be9f40889d0a60b9e58e0b)). What the lessons found in GA is in the [journal](journal/).

## By the end of this course, I will be able to

- write and test types that compute other types: conditional types, `infer`, mapped types with key remapping, template literal types, recursive types, and know the limits at which the checker gives up;
- predict the variance that `tsc` measures, spot where it is unsound, and control inference with `satisfies`, `const` type parameters and `NoInfer`;
- model a domain so that the mistakes are compile errors: brands, opaque types, unions without impossible states, typed state machines;
- check data at the border of the program with a schema library, and return typed errors instead of throwing them;
- write and publish declaration files, configure module resolution for Node.js and bundlers, and publish a package for ESM and CommonJS;
- compile a large project with project references, measure where the checker spends its time, and move a project to TypeScript 7;
- use standard decorators, the compiler API and typed lint rules, and test types in CI;
- read how typed libraries are built: builders, fluent APIs, typed routes and query builders.

## Outline

| # | Lesson | You already know |
|---|---|---|
| 1 | [Type-level programming](01-type-level-programming/) | generics, overload resolution, source generators |
| 2 | [Variance and assignability](02-variance-and-assignability/) | `IEnumerable<out T>`, wildcards, type inference |
| 3 | [Modeling with types](03-modeling-with-types/) | records, value objects, sealed hierarchies, the state pattern |
| 4 | [Runtime borders: schemas and typed errors](04-runtime-borders/) | `System.Text.Json`, Jackson, Bean Validation, exceptions |
| 5 | Declaration files: `.d.ts`, `declare module`, module and global augmentation, typing a JavaScript library, DefinitelyTyped | reference assemblies, XML documentation files |
| 6 | Modules and resolution: `moduleResolution` `nodenext` and `bundler`, `exports` and `imports`, dual ESM/CommonJS packages, `isolatedDeclarations`, `verbatimModuleSyntax` | assembly loading, the module path of Java |
| 7 | At scale: project references, `tsc -b`, npm and pnpm workspaces, `--generateTrace`, the checker's performance | solutions, incremental builds, multi-module Maven builds |
| 8 | Decorators: the ECMAScript standard, metadata, and what changed from `experimentalDecorators` | attributes, annotations |
| 9 | The compiler API and tooling: transforms, the language service, a typed typescript-eslint rule | Roslyn analyzers, annotation processors |
| 10 | The native compiler: TypeScript 7, what changed, compatibility, measurements | the move from the .NET Framework compilers to Roslyn |
| 11 | Type tests: `expect-type`, `tsd`, `vitest --typecheck` | tests of a public API, analyzers' tests |
| 12 | Library patterns: typed builders, fluent APIs, route inference, typed query builders | LINQ, Entity Framework, jOOQ |
| — | [Journal](journal/) | |

Lessons 5 to 12 are planned and not written yet.

## Prerequisites

- [Node.js 24](https://nodejs.org/) and [Git](https://git-scm.com/downloads). On Windows, run the course script from Git Bash: `npm ci`, then `bash check.sh` in `code/typescript-advanced`.
- The [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) and a [JDK 25](https://openjdk.org/projects/jdk/25/), only for the comparisons; `check.sh` skips them when `dotnet` or `java` is missing.

## Related courses on this site

- [TypeScript for C#/Java developers](../typescript-for-csharp-java/): the language this course builds on.
- [JavaScript for C#/Java developers](../javascript-for-csharp-java/): what runs once the types are erased.
- [Advanced C#](../csharp-advanced/): the same kind of course for C#, on the same GA repository.

## Resources

- The [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html), in particular [Type Manipulation](https://www.typescriptlang.org/docs/handbook/2/types-from-types.html), and the [TSConfig reference](https://www.typescriptlang.org/tsconfig/).
- The [TypeScript release notes](https://www.typescriptlang.org/docs/handbook/release-notes/overview.html): most features of this course arrived in a release between 4.1 and 5.4, and each lesson links the one that introduced it.
- [microsoft/typescript-go](https://github.com/microsoft/typescript-go), the compiler in Go, whose `internal/checker/checker.go` holds the limits quoted in lesson 1, and [microsoft/TypeScript](https://github.com/microsoft/TypeScript), the compiler in TypeScript up to version 6.
- [Standard Schema](https://standardschema.dev/), the interface shared by the validation libraries of lesson 4.
- [ECMAScript® Language Specification](https://tc39.es/ecma262/), and [Node.js 24 — Modules: TypeScript](https://nodejs.org/docs/latest-v24.x/api/typescript.html).
