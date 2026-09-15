---
title: JavaScript for C#/Java developers — Mission
description: JavaScript for developers who know C# or Java and want to stop being surprised — every example, error and solution run with Node.js 24 in CI on Windows, Linux and macOS, with the C# and Java side next to it.
sidebar:
  label: Mission
  order: 0
---

:::note[Version studied]
[Node.js](https://nodejs.org/) **24.21.0**, the current long-term support release ("Krypton", LTS since October 2025), with its [V8](https://v8.dev/) engine 13.6 and [npm](https://docs.npmjs.com/) 11.19. The language itself is [ECMAScript](https://tc39.es/ecma262/), the standard that browsers and Node.js implement. Every example of this course is in [`code/javascript-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/javascript-for-csharp-java), next to its expected output. [`.github/workflows/javascript-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/javascript-examples.yml) installs Node.js 24.21.0, .NET 10 and Java 25 on Linux, Windows and macOS, runs every example, error snippet and solution, and compares the outputs with the ones pasted in the lessons.
:::

## Why I'm learning this

I write C# and read a lot of Java, and I write JavaScript when I have to: a build script, a component of [Guitar Alchemist](https://github.com/GuitarAlchemist/ga)'s front end, the configuration of this site.
Each time, the syntax looks familiar enough that I stop paying attention, and then something surprises me: a `0` that becomes `0.5`, a method that loses its object, a copy that isn't one.
I want to learn the rules behind those surprises, from the specification and from Node.js itself, instead of collecting them one bug at a time.

## Who this course is for

You are comfortable with C# or Java: classes, interfaces, generics, exceptions, collections, [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/) or [streams](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html).
You have read or written some JavaScript, and you have been surprised by it. Each lesson starts from what you already know, shows where JavaScript agrees and where it differs, and prints what Node.js says, including its errors.

This course is the base of two others. Static types belong to the coming **TypeScript for C#/Java developers** course, so this one only mentions TypeScript where it changes nothing at run time. The DOM, JSX and components belong to the **React (Vite)** course that follows TypeScript, so this course runs JavaScript in Node.js and only looks at the browser as another host.

## JavaScript in one table

| | C# | Java | JavaScript |
|---|---|---|---|
| Specification | [C# language specification](https://learn.microsoft.com/dotnet/csharp/language-reference/language-specification/readme) | [Java Language Specification](https://docs.oracle.com/javase/specs/jls/se25/html/index.html) | [ECMAScript](https://tc39.es/ecma262/), a new edition every June |
| Runs on | the CLR, after compilation to IL | the JVM, after compilation to bytecode | an engine that parses the source: V8 in Chrome and Node.js, SpiderMonkey in Firefox, JavaScriptCore in Safari |
| Types | static | static | dynamic: values have types, variables don't |
| Numbers | `int`, `long`, `double`, `decimal`… | `int`, `long`, `double`… | `number` (a `double`) and `bigint` |
| Absent value | `null` | `null` | `undefined` and `null` |
| Objects | instances of classes | instances of classes | property bags linked to a prototype; `class` builds on that |
| Package manager | NuGet | Maven, Gradle | npm (or pnpm, Yarn) |
| Project file | `.csproj` | `pom.xml`, `build.gradle` | `package.json` |
| Modules | assemblies and namespaces | packages and modules | one module per file, ES modules or CommonJS |

## The data

The lessons use real code as material. Where a lesson quotes [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), it is at commit [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6), in the React front ends [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components) and [`Apps/ga-client`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client). Those files are TypeScript; the lessons reduce the lines they quote to plain JavaScript, which is what runs once the types are removed. This site, built with [Astro](https://docs.astro.build/), is the other real JavaScript project the lessons look at.

## By the end of this course, I will be able to

- install Node.js on Windows, Linux and macOS, run a file, and manage a project with npm;
- say whether a file is an ES module or a CommonJS module, and make the two work together;
- predict what `==`, `+`, `||` and `if` do with any pair of values, and choose the operator that doesn't surprise;
- say what `this` is in any call, and keep it in a callback;
- use prototypes and classes, and copy and compare objects on purpose;
- write asynchronous code with promises and `async`/`await`, and explain the event loop;
- test, debug and publish a Node.js package.

## Outline

| # | Lesson | You already know |
|---|---|---|
| 1 | [Node.js, npm and modules](01-node-npm-modules/) | `dotnet run`, NuGet, `java`, Maven, namespaces |
| 2 | [Values and types](02-values-and-types/) | `var`, `readonly`/`final`, `double`, `null`, `Equals` |
| 3 | [Functions, scope, closures and `this`](03-functions-and-scope/) | methods, lambdas, delegates, captured variables |
| 4 | [Objects, prototypes and classes](04-objects-prototypes-classes/) | classes, inheritance, properties, records |
| 5 | Arrays, iteration and collections (coming next) | `List<T>`, LINQ, streams, `Dictionary`, `HashMap`, `IEnumerable`, iterators |
| 6 | Errors and exceptions | `try`/`catch`/`finally`, exception types, `using` and try-with-resources |
| 7 | Asynchronous JavaScript: the event loop, promises, `async`/`await` | `Task`, `async`/`await`, `CompletableFuture` |
| 8 | The Node.js standard library: files, paths, streams and processes | `System.IO`, `java.nio.file`, `Process` |
| 9 | Testing and debugging: `node:test`, the inspector, ESLint | xUnit, JUnit, the Visual Studio and IntelliJ debuggers, analyzers |
| 10 | npm in depth: versions, lock files, workspaces, `exports` and publishing | NuGet and Maven Central |
| 11 | Text, regular expressions, dates and `Intl` | `Regex`, `DateTime`, `java.time`, `CultureInfo` |
| 12 | From Node.js to the browser: script modules, `fetch` and bundlers | ASP.NET static files, a front-end build |
| — | [Journal](journal/) | |

## Resources

- [ECMAScript® Language Specification](https://tc39.es/ecma262/), the living draft; the [editions published by Ecma](https://ecma-international.org/publications-and-standards/standards/ecma-262/)
- [MDN — JavaScript reference](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference) and [JavaScript guide](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide)
- [Node.js 24 documentation](https://nodejs.org/docs/latest-v24.x/api/)
- [npm documentation](https://docs.npmjs.com/)
- [Node.js release schedule](https://github.com/nodejs/Release#release-schedule)
