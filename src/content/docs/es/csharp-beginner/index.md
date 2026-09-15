---
title: C# para principiantes — Misión
description: Aprende a programar en C# 14 sobre .NET 10 desde cero — variables, condiciones, bucles, métodos y colecciones, cada noción explicada con programas cortos que se ejecutaron de verdad, y ejercicios con solución.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Cada programa de las lecciones, cada solución de ejercicio y cada error del compilador procede de [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner). [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/csharp-beginner/check.sh) los ejecuta con el SDK de .NET 10 y compara su salida con los archivos esperados; [`.github/workflows/csharp-beginner-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/csharp-beginner-examples.yml) hace lo mismo en Linux, Windows y macOS. Las salidas se capturaron en septiembre de 2026 con el SDK de .NET 10.0.112.
:::

## Por qué este curso

Los demás cursos de lenguajes de este sitio dan por hecho que ya escribes C# o Java. Este no. Es para alguien que nunca ha programado, o que ha escrito un poco de Python, JavaScript o fórmulas de hoja de cálculo, y quiere aprender C# bien.

C# es un buen primer lenguaje: el compilador revisa tu programa antes de ejecutarlo y explica qué está mal, las herramientas son gratuitas en Windows, Linux y macOS, y el mismo lenguaje sirve para herramientas de línea de comandos, sitios web, juegos y aplicaciones de escritorio. El curso usa las versiones actuales: [C# 14](https://learn.microsoft.com/dotnet/csharp/whats-new/csharp-14) y [.NET 10](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-10/overview), publicadas en noviembre de 2025.

## Cómo funcionan las lecciones

Cada lección presenta algunas nociones y, para cada una:

1. **la idea**, con palabras sencillas;
2. **un programa corto** que la usa, con la salida que imprimió de verdad;
3. **los errores** que cometen los principiantes con ella, con el mensaje exacto del compilador;
4. **ejercicios**, con una solución oculta bajo *Solución*: inténtalo primero y luego ábrela.

Los ejemplos usan datos pequeños y reales cuando ayudan: las notas de una guitarra, la afinación que usa [Guitar Alchemist](https://github.com/GuitarAlchemist/ga), los nombres de sus proyectos. No hace falta tocar música para seguirlos.

## Al terminar este curso, sabré

- instalar el SDK de .NET, ejecutar un archivo C# y crear un proyecto, en Windows, Linux o macOS;
- leer un error del compilador y corregirlo;
- guardar valores en variables del tipo adecuado, convertir entre tipos y leer lo que se escribe con el teclado;
- tomar decisiones con `if` y `switch`, y repetir trabajo con bucles;
- dividir un programa en métodos, y trabajar con arrays y listas;
- modelar mis propios datos con clases y records, y gestionar errores con excepciones;
- leer y escribir archivos, probar mi código y usar un paquete NuGet.

## Plan

| # | Lección | Nociones |
|---|---|---|
| 1 | [Instalar .NET y ejecutar tu primer programa](01-first-program/) | SDK, `dotnet run app.cs`, instrucciones, proyectos, errores del compilador |
| 2 | [Variables, tipos y entrada](02-variables-and-types/) | `int`, `double`, `decimal`, `string`, `bool`, `var`, conversiones, interpolación, `Console.ReadLine` |
| 3 | [Condiciones y bucles](03-conditions-and-loops/) | `if`, `switch`, `for`, `foreach`, `while`, `break`, el depurador |
| 4 | [Métodos, arrays y listas](04-methods-arrays-lists/) | parámetros, valores de retorno, arrays, `List<T>`, primeros pasos con `null` |
| 5 | Clases y objetos | campos, propiedades, constructores, métodos, `static` |
| 6 | Records, structs y enums | tipos de valor y de referencia, igualdad, `enum` |
| 7 | Interfaces y herencia | `interface`, `abstract`, `override`, polimorfismo |
| 8 | Excepciones y seguridad frente a null | `try`/`catch`/`finally`, `throw`, tipos de referencia que aceptan valores null |
| 9 | Colecciones y LINQ | `Dictionary<TKey, TValue>`, `HashSet<T>`, `Where`, `Select`, `OrderBy` |
| 10 | Archivos y texto | `File`, `Path`, leer un archivo CSV de los proyectos de Guitar Alchemist |
| 11 | Pruebas unitarias | xUnit, `dotnet test`, probar los métodos de las lecciones anteriores |
| 12 | Un pequeño proyecto | una solución con una biblioteca, una app de consola y pruebas, un paquete NuGet, un primer vistazo a `async` |
| — | [Diario](journal/) | |

Las lecciones 5 a 12 están planificadas y aún no se han escrito.

## Requisitos previos

- Un ordenador con Windows 10 u 11, una distribución de Linux reciente (o WSL), o macOS 14 o posterior.
- Alrededor de 1 GB de disco para el SDK de .NET.
- Una terminal: la lección 1 explica cómo abrir una.
- Un editor: [Visual Studio Code](https://code.visualstudio.com/) con la extensión C# Dev Kit, [Visual Studio](https://visualstudio.microsoft.com/) en Windows, o [JetBrains Rider](https://www.jetbrains.com/rider/). La lección 1 los compara.

## Después de este curso

Un curso de *C# avanzado*, escrito al mismo tiempo que este, empieza donde este termina: la memoria, el recolector de basura, `async` por dentro y el rendimiento medido. Los cursos [Java para desarrolladores C#](../java-for-csharp/) y [Rust para desarrolladores C#/Java](../rust-for-csharp-java/) parten de C#.

## Recursos

- [Documentación de C#](https://learn.microsoft.com/dotnet/csharp/), con su [recorrido por C#](https://learn.microsoft.com/dotnet/csharp/tour-of-csharp/) y sus [fundamentos](https://learn.microsoft.com/dotnet/csharp/fundamentals/program-structure/).
- [Referencia del lenguaje C#](https://learn.microsoft.com/dotnet/csharp/language-reference/): cada palabra clave, operador y error del compilador.
- [Información general de la CLI de .NET](https://learn.microsoft.com/dotnet/core/tools/): el comando `dotnet`.
- [Aplicaciones basadas en archivos](https://learn.microsoft.com/dotnet/core/sdk/file-based-apps): ejecutar un único archivo `.cs`.
