---
title: TypeScript avanzado — Misión
description: El sistema de tipos, las herramientas y TypeScript a escala, para desarrolladores que escriben TypeScript estricto a diario — cada prueba de tipos, error del compilador y ejemplo verificado por tsc 7.0.2 y ejecutado por Node.js 24, con el lado de C# y Java, sobre el frontend y el hub de Guitar Alchemist.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Cada salida de las lecciones viene de [`code/typescript-advanced`](https://github.com/spareilleux/learn/tree/main/code/typescript-advanced), que tiene su propio `package.json` y su archivo de bloqueo: [TypeScript](https://www.typescriptlang.org/) **7.0.2**, `@types/node` 24.13.4, [Zod](https://zod.dev/) 4.6.5, [Valibot](https://valibot.dev/) 1.5.0, [ArkType](https://arktype.io/) 2.2.3, `@standard-schema/spec` 1.1.0 y [esbuild](https://esbuild.github.io/) 0.28.2. [`check.sh`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/check.sh) ejecuta `tsc` sobre el proyecto, cuyas pruebas de tipos deben pasar, y sobre cada fragmento de error por separado; ejecuta cada ejemplo y solución con [Node.js](https://nodejs.org/) 24.21.0; empaqueta el mismo esquema con cada biblioteca de validación; compila y ejecuta las comparaciones en C# y Java; y compara todo ello con los archivos de `expected/`. Un workflow que hace lo mismo en Linux, Windows y macOS está escrito y todavía no se ha ejecutado (*por verificar*). Salidas capturadas en septiembre de 2026.
:::

## Por qué aprendo esto

Después del curso [TypeScript para desarrolladores C#/Java](../typescript-for-csharp-java/), sé leer y escribir TypeScript estricto. Lo que todavía no sé hacer es leer los tipos de los que están hechas las bibliotecas: un esquema Zod cuyo tipo se calcula a partir de su definición, un router que conoce los parámetros de una ruta a partir de la cadena de la ruta, un emisor de eventos que comprueba el nombre de un evento y la forma de su carga útil. Esos tipos son programas, ejecutados por el verificador, y tienen su propio flujo de control, su propia recursión y sus propios límites.

La otra mitad es lo que ocurre alrededor del verificador: qué promete un tipo cuando los datos llegan por un socket, cómo se compila un proyecto grande, qué dicen los archivos de declaración de un paquete, y qué cambió cuando el compilador se reescribió en Go. Este curso desmonta cada una de esas cosas, sobre código real: el frontend de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) y el hub SignalR con el que habla.

## Para quién es este curso

Escribes TypeScript con `strict` activado, y te manejas bien con las uniones, el *narrowing*, los genéricos, `keyof` y un primer tipo mapeado, que son las lecciones 2 a 4 del curso base. Conoces bien C# o Java, ya que las comparaciones son con ellos. No hace falta que hayas escrito un tipo condicional ni un archivo de declaración.

El curso base presenta cada herramienta donde un desarrollador C# o Java la necesita por primera vez. Este curso da por hecho que las usas, y mira cómo las evalúa el verificador, dónde dejan de funcionar y cómo se construyen las bibliotecas sobre ellas. Los componentes, JSX y el DOM corresponden al curso [React (Vite)](../react-vite/).

## TypeScript avanzado en una tabla

| | C# | Java | TypeScript |
|---|---|---|---|
| Calcular un tipo a partir de otro | generadores de código fuente, T4 | procesadores de anotaciones | tipos condicionales, mapeados y de plantilla literal, ejecutados por el verificador |
| Una cadena que lleva un tipo | no: un objeto clave tipado | no: un token `Class<T>` | un tipo literal: `'NodeChanged'` es un tipo |
| Varianza declarada | `in`/`out` en interfaces y delegados, comprobada | `? extends`, `? super` en el lugar de uso | medida a partir de la estructura; `in`/`out` opcionales, comprobadas en parte |
| Un envoltorio nominal | `readonly record struct`, sin asignación de memoria | un record, un objeto | una marca (*brand*), borrada: coste cero, cero comprobación en tiempo de ejecución |
| Verificar datos de fuera | los tipos existen en tiempo de ejecución: `System.Text.Json` puede comprobarlos | Jackson, Bean Validation | una biblioteca de esquemas, cuyo tipo se deriva del esquema |
| Fallos esperados | excepciones, o un tipo resultado | excepciones comprobadas | una unión resultado, y excepciones para los bugs |

## Los datos

Las lecciones usan [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) en el commit [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381): la biblioteca de componentes [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components), en particular su vista de gobernanza Prime Radiant, y el hub C# que la alimenta, [`Apps/ga-server/GaApi/Hubs/GovernanceHub.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Apps/ga-server/GaApi/Hubs/GovernanceHub.cs). Las lecciones reducen las líneas que citan a archivos que se ejecutan por sí solos, e indican de dónde viene cada una. El código fuente del propio verificador se cita de [microsoft/typescript-go](https://github.com/microsoft/typescript-go) en la etiqueta `typescript/v7.0.2` (commit [`2bd066d`](https://github.com/microsoft/typescript-go/tree/2bd066d87f5bafd315be9f40889d0a60b9e58e0b)). Lo que las lecciones encontraron en GA está en el [diario](journal/).

## Al final de este curso, sabré

- escribir y probar tipos que calculan otros tipos: tipos condicionales, `infer`, tipos mapeados con reasignación de claves, tipos de plantilla literal, tipos recursivos, y conocer los límites en los que el verificador se rinde;
- predecir la varianza que mide `tsc`, detectar dónde no es segura, y controlar la inferencia con `satisfies`, los parámetros de tipo `const` y `NoInfer`;
- modelar un dominio de modo que los errores sean errores de compilación: marcas, tipos opacos, uniones sin estados imposibles, máquinas de estados tipadas;
- verificar los datos en la frontera del programa con una biblioteca de esquemas, y devolver errores tipados en lugar de lanzarlos;
- escribir y publicar archivos de declaración, configurar la resolución de módulos para Node.js y los bundlers, y publicar un paquete para ESM y CommonJS;
- compilar un proyecto grande con referencias de proyecto, medir dónde pasa el tiempo el verificador, y llevar un proyecto a TypeScript 7;
- usar los decoradores estándar, la API del compilador y reglas de lint tipadas, y probar los tipos en la CI;
- leer cómo están construidas las bibliotecas tipadas: builders, APIs fluidas, rutas tipadas y constructores de consultas.

## Plan

| # | Lección | Ya conoces |
|---|---|---|
| 1 | [Programación a nivel de tipos](01-type-level-programming/) | genéricos, resolución de sobrecargas, generadores de código fuente |
| 2 | [Varianza y asignabilidad](02-variance-and-assignability/) | `IEnumerable<out T>`, comodines, inferencia de tipos |
| 3 | [Modelar con tipos](03-modeling-with-types/) | records, objetos de valor, jerarquías selladas, el patrón estado |
| 4 | [Fronteras en tiempo de ejecución: esquemas y errores tipados](04-runtime-borders/) | `System.Text.Json`, Jackson, Bean Validation, excepciones |
| 5 | Archivos de declaración: `.d.ts`, `declare module`, aumentación de módulos y global, tipar una biblioteca JavaScript, DefinitelyTyped | ensamblados de referencia, archivos de documentación XML |
| 6 | Módulos y resolución: `moduleResolution` `nodenext` y `bundler`, `exports` e `imports`, paquetes duales ESM/CommonJS, `isolatedDeclarations`, `verbatimModuleSyntax` | la carga de ensamblados, el module path de Java |
| 7 | A escala: referencias de proyecto, `tsc -b`, workspaces de npm y pnpm, `--generateTrace`, el rendimiento del verificador | soluciones, builds incrementales, builds Maven multimódulo |
| 8 | Decoradores: el estándar ECMAScript, los metadatos, y lo que cambió desde `experimentalDecorators` | atributos, anotaciones |
| 9 | La API del compilador y las herramientas: transformaciones, el servicio de lenguaje, una regla typescript-eslint tipada | analizadores Roslyn, procesadores de anotaciones |
| 10 | El compilador nativo: TypeScript 7, qué cambió, compatibilidad, mediciones | el paso de los compiladores de .NET Framework a Roslyn |
| 11 | Pruebas de tipos: `expect-type`, `tsd`, `vitest --typecheck` | pruebas de una API pública, pruebas de analizadores |
| 12 | Patrones de biblioteca: builders tipados, APIs fluidas, inferencia de rutas, constructores de consultas tipados | LINQ, Entity Framework, jOOQ |
| — | [Diario](journal/) | |

Las lecciones 5 a 12 están planificadas y todavía no se han escrito.

## Requisitos previos

- [Node.js 24](https://nodejs.org/) y [Git](https://git-scm.com/downloads). En Windows, ejecuta el script del curso desde Git Bash: `npm ci`, y luego `bash check.sh` en `code/typescript-advanced`.
- El [SDK de .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) y un [JDK 25](https://openjdk.org/projects/jdk/25/), solo para las comparaciones; `check.sh` se las salta cuando falta `dotnet` o `java`.

## Cursos relacionados en este sitio

- [TypeScript para desarrolladores C#/Java](../typescript-for-csharp-java/): el lenguaje sobre el que se construye este curso.
- [JavaScript para desarrolladores C#/Java](../javascript-for-csharp-java/): lo que se ejecuta una vez borrados los tipos.
- [C# avanzado](../csharp-advanced/): el mismo tipo de curso para C#, sobre el mismo repositorio de GA.

## Recursos

- El [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html), en particular [Type Manipulation](https://www.typescriptlang.org/docs/handbook/2/types-from-types.html), y la [referencia de TSConfig](https://www.typescriptlang.org/tsconfig/).
- Las [notas de versión de TypeScript](https://www.typescriptlang.org/docs/handbook/release-notes/overview.html): la mayoría de las funcionalidades de este curso llegaron en una versión entre la 4.1 y la 5.4, y cada lección enlaza la que la introdujo.
- [microsoft/typescript-go](https://github.com/microsoft/typescript-go), el compilador en Go, cuyo `internal/checker/checker.go` contiene los límites citados en la lección 1, y [microsoft/TypeScript](https://github.com/microsoft/TypeScript), el compilador en TypeScript hasta la versión 6.
- [Standard Schema](https://standardschema.dev/), la interfaz que comparten las bibliotecas de validación de la lección 4.
- [ECMAScript® Language Specification](https://tc39.es/ecma262/), y [Node.js 24 — Módulos: TypeScript](https://nodejs.org/docs/latest-v24.x/api/typescript.html).
