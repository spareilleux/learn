---
title: Java for C# developers — Mission
description: Learn modern Java (25 LTS) by mapping it onto what you already know from C# and .NET.
sidebar:
  label: Mission
  order: 0
---

:::note[Versions studied]
Java **25** (LTS), compared with C# **14** on .NET **10**. Every Java example in this course is run in CI from [`code/java-for-csharp`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp) and its output compared with the lesson. Every "this does not compile" snippet is compiled and checked against the exact javac diagnostic, and the C# side of each comparison is run too.
:::

## Why I'm learning this

I think in C#. But much of the code I read every day is Java: [Spring](https://spring.io/) services, build plugins, libraries whose C# port lags behind. The two languages look so alike that it is easy to write Java *as if* it were C#, and to be surprised at run time: `==` on two `Integer`s, a generic type that has vanished, a checked exception that won't compile.

This course is the map I wanted: for each topic, what carries over from C#, what only looks the same, and what has no equivalent.

## Who this course is for

You write C# comfortably: classes, interfaces, generics, LINQ, `async`/`await`, NuGet and the [`dotnet` CLI](https://learn.microsoft.com/dotnet/core/tools/). You have read some Java but never shipped it. A follow-up course, *Spring Boot, Spring Cloud and Reactor for C# developers*, builds on this one.

## By the end of this course, I will be able to

- install a JDK, run Java code and build a project with [Maven](https://maven.apache.org/) or [Gradle](https://gradle.org/);
- predict where Java's value semantics, equality and numbers differ from C#;
- model data with classes, records, enums and sealed interfaces;
- use generics knowing what type erasure takes away;
- handle checked exceptions, `null` and `Optional`;
- translate LINQ and delegates into Streams and functional interfaces;
- write concurrent code with virtual threads instead of `async`/`await`;
- test, package and run a Java application on the JVM.

## Outline

| # | Lesson | You already know |
|---|---|---|
| 1 | [The JDK and build tools](01-jdk-and-build-tools/) | the .NET SDK, `dotnet run`, [NuGet](https://www.nuget.org/), `.csproj` |
| 2 | [Types, equality and operators](02-types-and-operators/) | value types, `checked`, `==`, string interpolation |
| 3 | [Classes, records and enums](03-classes-records-enums/) | properties, `virtual`/`override`, `record`, `enum` |
| 4 | [Generics and type erasure](04-generics-and-erasure/) | reified generics, `where T : new()`, `in`/`out` variance |
| 5 | [Exceptions, `null` and `Optional`](05-exceptions-null-optional/) | exceptions, `using`, nullable reference types |
| 6 | [Lambdas and functional interfaces](06-lambdas-and-functional-interfaces/) | delegates, `Func`/`Action`, events |
| 7 | [Collections and Streams](07-collections-and-streams/) | `List<T>`, `Dictionary`, LINQ |
| 8 | [Pattern matching](08-pattern-matching/) | `switch` expressions, `is` patterns, records |
| 9 | [Concurrency and virtual threads](09-concurrency-and-virtual-threads/) | `Task`, `async`/`await`, `lock`, `Parallel` |
| 10 | [Maven and Gradle in depth](10-maven-and-gradle-in-depth/) | NuGet, Central Package Management, solutions |
| 11 | [Testing](11-testing/) | xUnit, Moq, FluentAssertions |
| 12 | The standard library you reach for *(coming next)* | `DateTime`, `decimal`, `HttpClient`, `System.IO` |
| 13 | The JVM at run time | the CLR, GC settings, `dotnet-counters`, Native AOT |
| 14 | Annotations, reflection and modules | attributes, source generators, assemblies |

[Journal](journal/) — what I tried, what surprised me, what I still need to verify.

## Resources

- [dev.java](https://dev.java/learn/) — Oracle's official Java tutorials, up to date with recent releases.
- [The Java Language Specification, Java SE 25](https://docs.oracle.com/javase/specs/jls/se25/html/index.html) — the reference when two tutorials disagree.
- [Java SE 25 API documentation](https://docs.oracle.com/en/java/javase/25/docs/api/index.html).
- [OpenJDK JEP index](https://openjdk.org/jeps/0) — every language and JVM change, with its motivation.
- [Maven — Getting Started](https://maven.apache.org/guides/getting-started/) and the [Gradle user manual](https://docs.gradle.org/current/userguide/userguide.html).
