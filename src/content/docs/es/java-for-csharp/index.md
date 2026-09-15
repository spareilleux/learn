---
title: Java para desarrolladores C# — Misión
description: Aprender Java moderno (25 LTS) relacionándolo con lo que ya sabes de C# y .NET.
sidebar:
  label: Misión
  order: 0
---

:::note[Versiones estudiadas]
Java **25** (LTS), comparado con C# **14** sobre .NET **10**. Cada ejemplo Java de este curso se ejecuta en CI desde [`code/java-for-csharp`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp) y su salida se compara con la lección. Cada fragmento «esto no compila» se compila y se contrasta con el diagnóstico exacto de javac, y el lado C# de cada comparación también se ejecuta.
:::

## Por qué estoy aprendiendo esto

Pienso en C#. Pero buena parte del código que leo cada día es Java: servicios [Spring](https://spring.io/), plugins de build, bibliotecas cuyo port a C# va con retraso. Los dos lenguajes se parecen tanto que es fácil escribir Java *como si* fuera C#, y llevarse sorpresas en tiempo de ejecución: `==` entre dos `Integer`, un tipo genérico que ha desaparecido, una excepción comprobada (checked) que no compila.

Este curso es el mapa que me hubiera gustado tener: para cada tema, lo que se traslada desde C#, lo que solo lo parece y lo que no tiene equivalente.

## A quién va dirigido este curso

Escribes C# con soltura: clases, interfaces, genéricos, LINQ, `async`/`await`, NuGet y la [CLI `dotnet`](https://learn.microsoft.com/dotnet/core/tools/). Has leído algo de Java pero nunca lo has llevado a producción. Un curso de continuación, [*Spring Boot, Spring Cloud y Reactor para desarrolladores C#*](../spring-cloud-reactor/), se apoya en este.

## Al final de este curso, sabré

- instalar un JDK, ejecutar código Java y compilar un proyecto con [Maven](https://maven.apache.org/) o [Gradle](https://gradle.org/);
- predecir en qué se diferencian de C# la semántica de valor, la igualdad y los números de Java;
- modelar datos con clases, records, enums e interfaces selladas;
- usar genéricos sabiendo lo que quita el borrado de tipos (type erasure);
- manejar las excepciones comprobadas, `null` y `Optional`;
- traducir LINQ y los delegados a Streams e interfaces funcionales;
- escribir código concurrente con hilos virtuales en lugar de `async`/`await`;
- probar, empaquetar y ejecutar una aplicación Java sobre la JVM.

## Plan

| # | Lección | Ya conoces |
|---|---|---|
| 1 | [El JDK y las herramientas de build](01-jdk-and-build-tools/) | el SDK de .NET, `dotnet run`, [NuGet](https://www.nuget.org/), `.csproj` |
| 2 | [Tipos, igualdad y operadores](02-types-and-operators/) | tipos de valor, `checked`, `==`, interpolación de cadenas |
| 3 | [Clases, records y enums](03-classes-records-enums/) | propiedades, `virtual`/`override`, `record`, `enum` |
| 4 | [Genéricos y borrado de tipos](04-generics-and-erasure/) | genéricos reificados, `where T : new()`, varianza `in`/`out` |
| 5 | [Excepciones, `null` y `Optional`](05-exceptions-null-optional/) | excepciones, `using`, tipos de referencia anulables |
| 6 | [Lambdas e interfaces funcionales](06-lambdas-and-functional-interfaces/) | delegados, `Func`/`Action`, eventos |
| 7 | [Colecciones y Streams](07-collections-and-streams/) | `List<T>`, `Dictionary`, LINQ |
| 8 | [Pattern matching](08-pattern-matching/) | expresiones `switch`, patrones `is`, records |
| 9 | [Concurrencia e hilos virtuales](09-concurrency-and-virtual-threads/) | `Task`, `async`/`await`, `lock`, `Parallel` |
| 10 | [Maven y Gradle a fondo](10-maven-and-gradle-in-depth/) | NuGet, Central Package Management, soluciones |
| 11 | [Pruebas](11-testing/) | xUnit, Moq, FluentAssertions |
| 12 | [La biblioteca estándar del día a día](12-standard-library/) | `DateTime`, `decimal`, `HttpClient`, `System.IO` |
| 13 | La JVM en tiempo de ejecución *(próximamente)* | el CLR, ajustes del GC, `dotnet-counters`, Native AOT |
| 14 | Anotaciones, reflexión y módulos | atributos, generadores de código fuente, ensamblados |

[Diario](journal/) — lo que probé, lo que me sorprendió, lo que aún me queda por verificar.

## Recursos

- [dev.java](https://dev.java/learn/) — los tutoriales oficiales de Java de Oracle, al día con las últimas versiones.
- [The Java Language Specification, Java SE 25](https://docs.oracle.com/javase/specs/jls/se25/html/index.html) — la referencia cuando dos tutoriales no coinciden.
- [Documentación de la API de Java SE 25](https://docs.oracle.com/en/java/javase/25/docs/api/index.html).
- [Índice de JEP de OpenJDK](https://openjdk.org/jeps/0) — cada cambio del lenguaje y de la JVM, con su motivación.
- [Maven — Getting Started](https://maven.apache.org/guides/getting-started/) y el [manual de usuario de Gradle](https://docs.gradle.org/current/userguide/userguide.html).
