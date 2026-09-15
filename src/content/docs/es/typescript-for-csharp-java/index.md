---
title: TypeScript para desarrolladores C#/Java — Misión
description: TypeScript para desarrolladores que conocen C# o Java y han seguido el curso de JavaScript — cada ejemplo, error del compilador y solución verificado por tsc 7.0.2 y ejecutado por Node.js 24 en CI en Windows, Linux y macOS, con el equivalente en C# y Java al lado.
sidebar:
  label: Misión
  order: 0
---

:::note[Versión estudiada]
[TypeScript](https://www.typescriptlang.org/) **7.0.2**, la primera versión estable del compilador portado a Go, publicada el 2026-07-08, y [Node.js](https://nodejs.org/) **24.21.0**, cuya eliminación de tipos (*type stripping*) ejecuta los archivos `.ts` del curso sin paso de compilación. Cada ejemplo está en [`code/typescript-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/typescript-for-csharp-java), con su propio `package.json` y su archivo de bloqueo, que fijan `typescript` 7.0.2, `@types/node` 24.13.4 y tsx 4.23.13. [`.github/workflows/typescript-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/typescript-examples.yml) instala Node.js 24.21.0, .NET 10 y Java 25 en Linux, Windows y macOS, ejecuta `tsc` sobre el proyecto y sobre cada fragmento de error, ejecuta cada ejemplo y solución con Node.js, compila las comparaciones en C# y Java, y compara todas las salidas con las que se pegan en las lecciones.
:::

## Por qué aprendo esto

Los frontends de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) están escritos en TypeScript, igual que los archivos de configuración de este sitio. Leo ese código como desarrollador C#, y parece C# con los tipos en el lugar equivocado, hasta que deja de parecerlo: se acepta un objeto donde se esperaba una clase, un cast no convierte nada, un genérico no tiene `T` en tiempo de ejecución, y un programa con errores de tipo se ejecuta igualmente.
El [curso de JavaScript](../javascript-for-csharp-java/) trató lo que ocurre en tiempo de ejecución. Este trata lo que `tsc` verifica, lo que no puede verificar, y dónde se encuentran ambos.

## Para quién es este curso

Te manejas bien con C# o Java, incluidos los genéricos, las interfaces y los tipos de referencia anulables u `Optional`, y has seguido el curso [JavaScript para desarrolladores C#/Java](../javascript-for-csharp-java/), o conoces su contenido: módulos y npm, valores y conversiones, funciones y `this`, prototipos y clases. Las lecciones enlazan a sus páginas en lugar de volver a explicar JavaScript.

Los componentes, JSX y el DOM corresponden al curso **React (Vite)** que sigue a este. Este curso ejecuta TypeScript en Node.js, donde cada ejemplo puede verificarse y ejecutarse en CI, y solo mira código React como datos del repositorio de GA.

## TypeScript en una tabla

| | C# | Java | TypeScript |
|---|---|---|---|
| Compilador | `csc`, a través de `dotnet build` | `javac` | `tsc`, que verifica y puede escribir JavaScript |
| Archivo de proyecto | `.csproj` | `pom.xml`, `build.gradle` | `tsconfig.json`, junto a `package.json` |
| Tipos en tiempo de ejecución | reificados: `typeof(T)`, `is T` | genéricos borrados, casts comprobados | ninguno: todos los tipos se borran, casts incluidos |
| Compatibilidad | nominal: herencia declarada | nominal | estructural: la misma forma es el mismo tipo |
| Un error de tipo | detiene la build | detiene la build | no detiene nada salvo que la build se lo pida a `tsc` |
| Valor ausente | `string?` con advertencias | `Optional<T>`, anotaciones | `string \| undefined`, errores con `strictNullChecks` |
| Uno de varios casos | jerarquía de clases, `switch` con patrones | `sealed interface`, `switch` con patrones | tipos unión y *narrowing* |
| Genéricos | reificados, varianza en las interfaces | borrados, comodines | borrados, varianza estructural, tipos calculados a partir de tipos |

## Los datos

Las lecciones usan código real como material. [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) se cita en el commit [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6), en sus dos frontends React, [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components) y [`Apps/ga-client`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client), que instalé y verifiqué con `tsc` 5.9.3 y 7.0.2. Este sitio, construido con [Astro](https://docs.astro.build/), es el otro proyecto TypeScript, en el commit [`8ba378e`](https://github.com/spareilleux/learn/commit/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3). Las lecciones reducen las líneas que citan a archivos que se ejecutan por sí solos, e indican de dónde viene cada una. Lo que `tsc` encontró en esos proyectos está en el [diario](journal/).

## Al final de este curso, sabré

- configurar un proyecto TypeScript para Node.js, leer su `tsconfig.json` y hacer que los errores de tipo hagan fallar la build;
- leer un diagnóstico de `tsc` y relacionar su código con lo que habría dicho C# o Java;
- predecir cuándo dos tipos son compatibles, y dar un nombre a un tipo cuando la estructura no basta;
- modelar datos como uniones, estrecharlas y obtener un error de compilación cuando falta un caso;
- verificar en la frontera los datos que vienen de fuera del programa, en lugar de afirmar su tipo;
- escribir funciones y tipos genéricos, y explicar por qué `new T()` e `instanceof T` no existen;
- calcular tipos a partir de otros tipos con `keyof`, tipos mapeados y tipos condicionales;
- tipar una biblioteca JavaScript, un paquete Node.js y un frontend construido con Vite, y migrar un proyecto JavaScript a `strict`.

## Plan

| # | Lección | Ya conoces |
|---|---|---|
| 1 | [El compilador y las herramientas](01-compiler-and-tooling/) | `csc`, `javac`, `.csproj`, advertencias y errores del compilador |
| 2 | [Tipado estructural](02-structural-typing/) | interfaces, `var`, `readonly`/`final`, `object`, `dynamic`, tipos de referencia anulables |
| 3 | [Uniones y *narrowing*](03-unions-and-narrowing/) | jerarquías de clases, `switch` con patrones, interfaces selladas, casts |
| 4 | [Genéricos](04-generics/) | `List<T>`, restricciones, `IEnumerable<out T>`, comodines, borrado de tipos |
| 5 | Programación a nivel de tipos: tipos condicionales, `infer`, tipos de plantilla literal y `satisfies` (próximamente) | resolución de sobrecargas, `typeof`, atributos |
| 6 | Clases en TypeScript: modificadores, `abstract`, `implements`, decoradores | clases, modificadores de acceso, atributos y anotaciones |
| 7 | Módulos y archivos de declaración: `.d.ts`, `@types`, `declare module`, tipar JavaScript con JSDoc | ensamblados de referencia, `extern`, metadatos de los JAR |
| 8 | Código asíncrono y errores: `Promise<T>`, errores tipados, tipos resultado | `Task<T>`, excepciones, `CompletableFuture`, excepciones comprobadas |
| 9 | Datos en la frontera: `fetch`, JSON, validación de esquemas y tipos generados a partir de OpenAPI | `System.Text.Json`, Jackson, NSwag, OpenAPI Generator |
| 10 | Probar el código y los tipos: Vitest, `@ts-expect-error`, pruebas de tipos | xUnit, JUnit, analizadores |
| 11 | Proyectos a escala: referencias de proyecto, `tsc -b`, monorepos, typescript-eslint | soluciones, builds Maven multimódulo, analizadores |
| 12 | Migrar a `strict`: los frontends de GuitarAlchemist/ga, y de TypeScript 6 a 7 | activar los tipos de referencia anulables en un proyecto existente |
| — | [Diario](journal/) | |

## Recursos

- [The TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) y la [referencia de TSConfig](https://www.typescriptlang.org/tsconfig/)
- [Notas de versión de TypeScript](https://www.typescriptlang.org/docs/handbook/release-notes/overview.html), y el [anuncio de TypeScript 7](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/)
- [microsoft/TypeScript](https://github.com/microsoft/TypeScript), cuyo [`diagnosticMessages.json`](https://github.com/microsoft/TypeScript/blob/v6.0.3/src/compiler/diagnosticMessages.json) enumera todos los códigos de error, y [microsoft/typescript-go](https://github.com/microsoft/typescript-go), el port a Go
- [Node.js 24 — Módulos: TypeScript](https://nodejs.org/docs/latest-v24.x/api/typescript.html)
- [ECMAScript® Language Specification](https://tc39.es/ecma262/), el lenguaje al que TypeScript añade tipos
