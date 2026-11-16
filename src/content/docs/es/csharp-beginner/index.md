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
| 5 | [Clases y objetos](05-classes-and-objects/) | campos, propiedades, constructores, métodos, `static` |
| 6 | [Records, structs y enums](06-records-structs-enums/) | tipos de valor y de referencia, igualdad, `enum` |
| 7 | [Interfaces y herencia](07-interfaces-and-inheritance/) | `interface`, `abstract`, `override`, polimorfismo |
| 8 | [Excepciones y seguridad frente a null](08-exceptions-and-null-safety/) | `try`/`catch`/`finally`, `throw`, tipos de referencia que aceptan valores null |
| 9 | [Colecciones y LINQ](09-collections-and-linq/) | `Dictionary<TKey, TValue>`, `HashSet<T>`, `Where`, `Select`, `OrderBy` |
| 10 | [Archivos y texto](10-files-and-text/) | `File`, `Path`, leer un archivo CSV de los proyectos de Guitar Alchemist |
| 11 | [Pruebas unitarias](11-unit-tests/) | xUnit, `dotnet test`, probar los métodos de las lecciones anteriores |
| 12 | [Un pequeño proyecto](12-small-project/) | una solución con una biblioteca, una app de consola y pruebas, un paquete NuGet, un primer vistazo a `async` |
| — | [Diario](journal/) | |

## Lo más destacado del diario

El [diario](journal/) recoge lo que la escritura y las pruebas de este curso sacaron a la luz. Estos son los hallazgos que cambian la forma de escribir o ejecutar un programa; cada fila enlaza con la lección que lo enseña y con la entrada del diario que contiene la medición.

| Lo que encontró el diario | Por qué importa | Ver |
|---|---|---|
| Un `Writeline` mal escrito (CS0117) solo se señala una vez corregidos el `;` y las comillas que faltan en el mismo programa: los errores de sintaxis ocultan los demás | Corregir un error puede hacer aparecer otros nuevos; es un avance, no un retroceso | [Lección 1](01-first-program/), [diario](journal/#2026-09-14--el-sdk-y-las-aplicaciones-basadas-en-archivos) |
| `double.TryParse("1.5")` depende de la cultura: `true` y 15 en `es-ES`, donde el punto separa los miles, `false` en `fr-FR` | El mismo programa lee un número distinto en una máquina española o francesa | [Lección 2](02-variables-and-types/), [diario](journal/#2026-09-14--el-sdk-y-las-aplicaciones-basadas-en-archivos) |
| Las advertencias solo se muestran cuando el SDK compila: un segundo `dotnet run` de un archivo sin cambios no muestra ninguna, ni siquiera con `--no-cache`; `dotnet clean` las hace volver | Una advertencia que desaparece en la ejecución siguiente no está corregida | [Lección 3](03-conditions-and-loops/), [diario](journal/#2026-09-14--el-sdk-y-las-aplicaciones-basadas-en-archivos) |
| El literal `0` se convierte en una enumeración sin cast, y CS8524 avisa de una expresión `switch` que tiene un brazo por nombre | Una variable de enumeración puede contener un número sin nombre: el programa de la lección falla con 7 | [Lección 6](06-records-structs-enums/), [diario](journal/#2026-10-01--records-structs-y-enums) |
| Un borrador decía que `shape[i].Fret += 2` sobre una lista de `readonly record struct` da CS1612; una sonda compilada antes de publicar dio CS8852 | Cada salida y cada mensaje de error del curso se pega desde una ejecución, nunca se escribe de memoria | [Lección 6](06-records-structs-enums/), [diario](journal/#2026-10-01--records-structs-y-enums) |
| En Guitar Alchemist, el `ToString() => Name` de `ChordTemplate` no es `sealed`: sus records derivados muestran todas sus propiedades en lugar del nombre del acorde | El `override` de la lección 7 se encuentra con los records de la lección 6 en código real; un punto de llamada de GA registra el volcado. Aún no comunicado a GA | [Lección 7](07-interfaces-and-inheritance/), [tabla QA](journal/#qa) |
| Una advertencia de nulabilidad señala por dónde entra `null`, no dónde falla el programa: CS8618 está en la declaración de la propiedad, y la línea que falla no tiene ninguna advertencia | Corrige cada advertencia donde está, aunque esté lejos del fallo | [Lección 8](08-exceptions-and-null-safety/), [diario](journal/#2026-10-02--excepciones-y-seguridad-frente-a-null) |
| Guitar Alchemist silencia quince advertencias de nulabilidad en `NoWarn`, dos veces. Su código no tiene ninguna que ocultar, pero un archivo de prueba con siete errores de nulabilidad compiló sin advertencias | Silenciar una advertencia también silencia los errores que aún están por venir. Aún no comunicado a GA | [Lección 8](08-exceptions-and-null-safety/), [tabla QA](journal/#qa) |
| El `foreach` de un diccionario sigue el orden de inserción solo hasta el primer `Remove`: una clave añadida después ocupa el lugar de la clave quitada | Un resultado ordenado guardado en un `Dictionary` sigue ordenado por casualidad; ordena cuando el orden importa | [Lección 9](09-collections-and-linq/), [diario](journal/#2026-10-02--colecciones-y-linq) |
| Tres de los cuatro archivos YAML que leen los servicios de conocimiento musical de Guitar Alchemist no se cargan; cada cargador captura la excepción y sigue con un solo elemento por defecto | Un `catch` que solo muestra un mensaje oculta el error: GA cuenta 16 artistas y nada falla. Comunicado en la [issue 797 de GA](https://github.com/GuitarAlchemist/ga/issues/797); corrección propuesta en la [PR 808 de GA](https://github.com/GuitarAlchemist/ga/pull/808) | [Lección 9](09-collections-and-linq/), [tabla QA](journal/#qa) |
| Una ruta relativa parte del directorio actual, no del archivo del programa: `l10_where.cs` encuentra `data/ga-projects.csv` cuando `dotnet run` arranca en `code/csharp-beginner`, y no lo encuentra desde la raíz del repositorio | El mismo programa encuentra su archivo o no según la carpeta desde la que arranca; una ruta construida a partir de `EntryPointFileDirectoryPath` funciona desde las dos | [Lección 10](10-files-and-text/), [diario](journal/#2026-10-03--archivos-y-texto) |
| La cadena de formato con la que Guitar Alchemist escribe su CSV de naturalidad sigue la cultura de la máquina: con `fr-FR`, `2.50` se convierte en `2,50`, y una fila de 6 valores se corta en 8 | Un archivo escrito en una máquina francesa no se vuelve a leer con `Split(',')`; escribe los números con `CultureInfo.InvariantCulture`. Corrección propuesta en la [PR 811 de GA](https://github.com/GuitarAlchemist/ga/pull/811) | [Lección 10](10-files-and-text/), [tabla QA](journal/#qa) |
| Las pruebas de Guitar Alchemist para sus servicios YAML pasan mientras tres de los cuatro archivos no se cargan: tres pruebas se omiten, y las demás comprueban «más que cero», lo que cumple el único elemento por defecto | Una prueba que solo comprueba «más que cero» no ve un valor de repliegue; comprueba el valor real. Corrección propuesta en la [PR 808 de GA](https://github.com/GuitarAlchemist/ga/pull/808) | [Lección 11](11-unit-tests/), [tabla QA](journal/#qa) |
| Con los argumentos invertidos, `Assert.Equal` llama «Expected» al resultado del método y «Actual» al valor de la prueba; la regla de analizador xUnit2000 avisa antes de que se ejecuten las pruebas | El valor esperado va primero; lee también las advertencias de la compilación de las pruebas | [Lección 11](11-unit-tests/), [diario](journal/#2026-10-03--pruebas-unitarias) |
| `dotnet test` en la carpeta de una solución solo compila los proyectos de pruebas y lo que referencian: con un error de compilación en la aplicación de consola, las pruebas pasan igualmente y terminan con el código 0 | Ejecuta también `dotnet build` antes de fiarte de unas pruebas en verde | [Lección 12](12-small-project/), [diario](journal/#2026-10-03--un-pequeño-proyecto) |
| En el `Directory.Build.props` de Guitar Alchemist, las líneas `PackageReference Update` pensadas para alinear las versiones de los paquetes no cambian nada: el archivo se importa antes que los elementos propios de los proyectos | Comprueba la versión que elige una restauración; `Directory.Build.targets` o la gestión centralizada de paquetes hacen lo que esas líneas pretenden. Corrección propuesta en la [PR 812 de GA](https://github.com/GuitarAlchemist/ga/pull/812) | [Lección 12](12-small-project/), [tabla QA](journal/#qa) |

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
