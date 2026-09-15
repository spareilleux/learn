---
title: JavaScript para desarrolladores C#/Java — Misión
description: JavaScript para desarrolladores que conocen C# o Java y quieren dejar de llevarse sorpresas — cada ejemplo, error y solución se ejecuta con Node.js 24 en CI en Windows, Linux y macOS, con el equivalente en C# y Java al lado.
sidebar:
  label: Misión
  order: 0
---

:::note[Versión estudiada]
[Node.js](https://nodejs.org/) **24.21.0**, la versión de soporte a largo plazo actual ("Krypton", LTS desde octubre de 2025), con su motor [V8](https://v8.dev/) 13.6 y [npm](https://docs.npmjs.com/) 11.19. El lenguaje en sí es [ECMAScript](https://tc39.es/ecma262/), el estándar que implementan los navegadores y Node.js. Cada ejemplo de este curso está en [`code/javascript-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/javascript-for-csharp-java), junto a su salida esperada. [`.github/workflows/javascript-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/javascript-examples.yml) instala Node.js 24.21.0, .NET 10 y Java 25 en Linux, Windows y macOS, ejecuta cada ejemplo, snippet de error y solución, y compara las salidas con las que se pegan en las lecciones.
:::

## Por qué aprendo esto

Escribo C# y leo bastante Java, y escribo JavaScript cuando no queda otra: un script de compilación, un componente del frontend de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga), la configuración de este sitio.
Cada vez, la sintaxis me resulta lo bastante familiar como para dejar de prestar atención, y entonces algo me sorprende: un `0` que se convierte en `0.5`, un método que pierde su objeto, una copia que no lo es.
Quiero aprender las reglas que hay detrás de esas sorpresas, a partir de la especificación y del propio Node.js, en lugar de coleccionarlas bug a bug.

## Para quién es este curso

Te manejas bien con C# o Java: clases, interfaces, genéricos, excepciones, colecciones, [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/) o [streams](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html).
Has leído o escrito algo de JavaScript, y te ha sorprendido. Cada lección parte de lo que ya sabes, muestra dónde JavaScript coincide y dónde difiere, e imprime lo que dice Node.js, errores incluidos.

Este curso es la base de otros dos. Los tipos estáticos corresponden al próximo curso **TypeScript para desarrolladores C#/Java**, así que este solo menciona TypeScript donde no cambia nada en tiempo de ejecución. El DOM, JSX y los componentes corresponden al curso **React (Vite)** que sigue a TypeScript, así que este curso ejecuta JavaScript en Node.js y solo mira el navegador como otro entorno anfitrión.

## JavaScript en una tabla

| | C# | Java | JavaScript |
|---|---|---|---|
| Especificación | [Especificación del lenguaje C#](https://learn.microsoft.com/dotnet/csharp/language-reference/language-specification/readme) | [Java Language Specification](https://docs.oracle.com/javase/specs/jls/se25/html/index.html) | [ECMAScript](https://tc39.es/ecma262/), una nueva edición cada junio |
| Se ejecuta en | el CLR, tras compilar a IL | la JVM, tras compilar a bytecode | un motor que analiza el código fuente: V8 en Chrome y Node.js, SpiderMonkey en Firefox, JavaScriptCore en Safari |
| Tipos | estáticos | estáticos | dinámicos: los valores tienen tipos, las variables no |
| Números | `int`, `long`, `double`, `decimal`… | `int`, `long`, `double`… | `number` (un `double`) y `bigint` |
| Valor ausente | `null` | `null` | `undefined` y `null` |
| Objetos | instancias de clases | instancias de clases | bolsas de propiedades enlazadas a un prototipo; `class` se construye sobre eso |
| Gestor de paquetes | NuGet | Maven, Gradle | npm (o pnpm, Yarn) |
| Archivo de proyecto | `.csproj` | `pom.xml`, `build.gradle` | `package.json` |
| Módulos | ensamblados y espacios de nombres | paquetes y módulos | un módulo por archivo, ES modules o CommonJS |

## Los datos

Las lecciones usan código real como material. Cuando una lección cita [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), lo hace en el commit [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6), en los frontends React [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components) y [`Apps/ga-client`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client). Esos archivos son TypeScript; las lecciones reducen las líneas que citan a JavaScript puro, que es lo que se ejecuta una vez eliminados los tipos. Este sitio, construido con [Astro](https://docs.astro.build/), es el otro proyecto JavaScript real que examinan las lecciones.

## Al final de este curso, sabré

- instalar Node.js en Windows, Linux y macOS, ejecutar un archivo y gestionar un proyecto con npm;
- decir si un archivo es un ES module o un módulo CommonJS, y hacer que ambos funcionen juntos;
- predecir qué hacen `==`, `+`, `||` e `if` con cualquier par de valores, y elegir el operador que no sorprende;
- decir qué es `this` en cualquier llamada, y conservarlo en un callback;
- usar prototipos y clases, y copiar y comparar objetos a propósito;
- escribir código asíncrono con promesas y `async`/`await`, y explicar el bucle de eventos;
- probar, depurar y publicar un paquete Node.js.

## Plan

| # | Lección | Ya conoces |
|---|---|---|
| 1 | [Node.js, npm y módulos](01-node-npm-modules/) | `dotnet run`, NuGet, `java`, Maven, espacios de nombres |
| 2 | [Valores y tipos](02-values-and-types/) | `var`, `readonly`/`final`, `double`, `null`, `Equals` |
| 3 | [Funciones, ámbito, closures y `this`](03-functions-and-scope/) | métodos, lambdas, delegados, variables capturadas |
| 4 | [Objetos, prototipos y clases](04-objects-prototypes-classes/) | clases, herencia, propiedades, records |
| 5 | Arrays, iteración y colecciones (próximamente) | `List<T>`, LINQ, streams, `Dictionary`, `HashMap`, `IEnumerable`, iteradores |
| 6 | Errores y excepciones | `try`/`catch`/`finally`, tipos de excepción, `using` y try-with-resources |
| 7 | JavaScript asíncrono: el bucle de eventos, las promesas, `async`/`await` | `Task`, `async`/`await`, `CompletableFuture` |
| 8 | La biblioteca estándar de Node.js: archivos, rutas, streams y procesos | `System.IO`, `java.nio.file`, `Process` |
| 9 | Pruebas y depuración: `node:test`, el inspector, ESLint | xUnit, JUnit, los depuradores de Visual Studio e IntelliJ, analizadores |
| 10 | npm a fondo: versiones, archivos de bloqueo, workspaces, `exports` y publicación | NuGet y Maven Central |
| 11 | Texto, expresiones regulares, fechas e `Intl` | `Regex`, `DateTime`, `java.time`, `CultureInfo` |
| 12 | De Node.js al navegador: módulos de script, `fetch` y bundlers | archivos estáticos de ASP.NET, una compilación de frontend |
| — | [Diario](journal/) | |

## Recursos

- [ECMAScript® Language Specification](https://tc39.es/ecma262/), el borrador vivo; las [ediciones publicadas por Ecma](https://ecma-international.org/publications-and-standards/standards/ecma-262/)
- [MDN — referencia de JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference) y [guía de JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide)
- [Documentación de Node.js 24](https://nodejs.org/docs/latest-v24.x/api/)
- [Documentación de npm](https://docs.npmjs.com/)
- [Calendario de versiones de Node.js](https://github.com/nodejs/Release#release-schedule)
