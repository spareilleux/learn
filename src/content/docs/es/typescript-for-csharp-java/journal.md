---
title: Diario
description: Notas de progreso fechadas del curso de TypeScript — la instalación de TypeScript 7.0.2, la CI en tres SO, sorpresas en tsc, Node.js y dotnet, lo que encontró tsc en los frontends de GuitarAlchemist/ga y en este sitio, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] TypeScript 7.0.2 fijado en el `package.json` y el archivo de bloqueo propios del curso, con `@types/node` 24.13.4 y tsx 4.23.13
- [x] CI: `tsc` sobre el proyecto y sobre cada fragmento de error, cada ejemplo y cada solución ejecutados con Node.js 24.21.0, las comparaciones en C# y Java compiladas y ejecutadas, todo comparado con su salida esperada en tres SO
- [x] Lección 1: el compilador y las herramientas
- [x] Lección 2: tipado estructural
- [x] Lección 3: uniones y *narrowing*
- [x] Lección 4: genéricos
- [ ] Lección 5: programación a nivel de tipos

## 2026-09-14 — Instalación de TypeScript 7.0.2

- `npm view typescript version` da la 7.0.2, el port a Go, publicada el 2026-07-08. El paquete `typescript` ahora es pequeño: npm instala el compilador como un paquete por plataforma, `@typescript/typescript-win32-x64` en mi máquina, y el paso de información de la CI lista `typescript-linux-x64` en Linux y `typescript-darwin-arm64` en macOS. El archivo de bloqueo lista los veinte paquetes de plataforma como dependencias opcionales, así que `npm ci` funciona en los tres SO con el único archivo de bloqueo escrito en Windows.
- TypeScript 7.0 todavía no tiene API programática. Las herramientas que cargan el compilador como biblioteca pueden usar `@typescript/typescript6`, un paquete de compatibilidad que proporciona TypeScript 6.0 con un comando `tsc6`; no lo necesité para el curso.
- El curso fija sus versiones en [`code/typescript-for-csharp-java/package.json`](https://github.com/spareilleux/learn/blob/main/code/typescript-for-csharp-java/package.json), no en el del sitio: el propio sitio no tiene ninguna dependencia `typescript`.
- npm 11.19 ya no ejecuta los scripts de instalación por defecto. Instalar tsx imprimió `npm warn install-scripts esbuild@0.28.2 (postinstall: node install.js)`, y tsx funciona de todos modos, en los tres SO: el binario de esbuild viene de un paquete de plataforma instalado como dependencia opcional.

## 2026-09-14 — La CI

- [`typescript-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/typescript-examples.yml) instala Node.js 24.21.0, .NET 10 y Java 25, ejecuta `npm ci` en la carpeta del curso, y luego [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/typescript-for-csharp-java/check.sh) con `REQUIRE_COMPARE=1`, para que la falta de `dotnet` o `java` haga fallar la ejecución en lugar de saltarse las comparaciones.
- `check.sh` ejecuta `tsc` una vez sobre todo el proyecto, que debe pasar, y una vez por fragmento de error, con un `tsconfig` generado que extiende el del curso y lista ese único archivo; un fragmento puede pedir opciones adicionales con un comentario `// tsc options:`, como hace `noUncheckedIndexedAccess` en la lección 2. [`normalize.mjs`](https://github.com/spareilleux/learn/blob/main/code/typescript-for-csharp-java/normalize.mjs), adaptado del curso de JavaScript, hace relativas las rutas y quita los marcos de la pila y los identificadores de proceso.
- La primera ejecución falló en los tres SO, solo en dos archivos, y por el mismo motivo: las advertencias de C# `CS8602` y `CS8509` estaban en la salida de la CI y no en la mía. `dotnet run file.cs` compila un programa basado en archivo de forma incremental, y una segunda ejecución con el fuente sin cambios no llama al compilador, así que sus advertencias solo se imprimen una vez. `check.sh` ahora ejecuta `dotnet clean` sobre el archivo antes de `dotnet run --no-cache`, y las salidas capturadas en Windows coinciden en Linux y macOS. La siguiente ejecución pasó en los tres SO en 2 minutos y 41 segundos, siendo Windows el job más lento.

## 2026-09-15 — Sorpresas al escribir las lecciones 1-4

**El código de salida de `tsc` cambió entre la 6.0 y la 7.0.** Con `--noEmit` y errores, `tsc` 6.0.3 devuelve 2, y la 7.0.2 devuelve 1. En la 7.0.2, 1 significa que los errores impidieron la salida, con `noEmit` o `noEmitOnError`, y 2 que la salida se escribió a pesar de los errores, lo que la lección 1 muestra con `l01-emit`. Un paso de CI que compruebe `$? -eq 2` se rompería con la actualización; comprueba que el código no sea cero.

**`tsc file.ts` junto a un `tsconfig.json` es un error desde la 6.0.** `TS5112` se niega a ignorar la configuración en silencio, como hacían las versiones anteriores; `--ignoreConfig` restaura el comportamiento anterior. `check.sh` construye en su lugar un pequeño `tsconfig` para cada fragmento de error.

**Los miembros de una unión no se imprimen en el orden de declaración.** La misma comparación en `ForceRadiant.tsx` de GA imprime `"warning" | "error" | "unknown" | "contradictory"` con la 5.9.3 y `"contradictory" | "error" | "unknown" | "warning"` con la 7.0.2. Las [notas de la versión 6.0](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html#the---stabletypeordering-flag) lo explican: TypeScript 7 ordena los tipos por contenido para que los verificadores en paralelo coincidan. Las salidas esperadas de la lección 3 son solo las de la 7.0.2.

**Una anotación `out` errónea compila.** Escribí `interface Mislabeled<out T> { accept(value: T): void }` para el fragmento de error de la lección 4, esperando un error, y `tsc` 7.0.2 lo aceptó: `accept` es un método, los parámetros de los métodos son bivariantes, y `T` en esa posición satisface las dos anotaciones. C# señala la misma interfaz con `CS1961`. El fragmento usa ahora el error que `tsc` sí detecta, `in T` en un método que devuelve `T` (`TS2636`).

**`Array.isArray` trae de vuelta `any`.** En la solución del segundo ejercicio de la lección 2, el valor era `unknown`, y `Array.isArray(value)` lo estrechó a `any[]`: `item.name` compilaba sin comprobación. Las comprobaciones `typeof` de la solución la hacen correcta; `tsc` no las pidió. La lección 2 lo señala.

**Node.js imprime la línea sin tipos.** Cuando un archivo `.ts` falla en tiempo de ejecución, la línea del fuente en el mensaje de Node.js tiene espacios donde estaban los tipos, como en el `const guitarSource                 = instrumentSource;` de la lección 4. Así es como la eliminación de tipos conserva los números de línea y de columna.

**`module.stripTypeScriptTypes` todavía imprime un `ExperimentalWarning` en la 24.21.0**, aunque la eliminación de tipos en sí es estable y silenciosa; la lección 1 muestra la advertencia.

## 2026-09-15 — Lo que encontró tsc en GuitarAlchemist/ga (a826864)

Cloné [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) en [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6) en una carpeta de pruebas, instalé los dos frontends, y ejecuté `tsc` con la 5.9.3, la versión que resuelve el `pnpm-lock.yaml` de la biblioteca de componentes, y con la 7.0.2.

- **Nombres usados y nunca definidos.** [`Apps/ga-client/src/components/Chat/ChatInterface.tsx`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/components/Chat/ChatInterface.tsx#L219) usa `VIRTUALIZATION_THRESHOLD` (líneas 69 y 219) y `VirtualizedMessageList` (líneas 254 y 255), y nada los define ni los importa: `TS2304`. La ruta `/ai-copilot` de [`App.tsx`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/App.tsx#L105) carga ese componente, así que la página debería lanzar un `ReferenceError` al renderizarse (*por verificar* en un navegador). Reproducción: `cd Apps/ga-client && npm ci && npx tsc -b --pretty false | grep ChatInterface`. Parece un bug que merece una issue.
- **Los errores de tipo no hacen fallar el build.** Los dos frontends se construyen con `vite build`, que elimina los tipos sin verificarlos; `ga-client` da 346 errores con `tsc -b` (165 de ellos `TS6133`, variables sin usar), y `ga-react-components` 186. Un paso `tsc --noEmit` en la CI habría detectado los nombres que faltan.
- **Un archivo de bloqueo desactualizado.** En `ReactComponents/ga-react-components`, `pnpm install --frozen-lockfile` falla con `ERR_PNPM_OUTDATED_LOCKFILE`: faltan en `pnpm-lock.yaml` 21 dependencias de `package.json`, y las versiones de `@react-three/drei` y `@react-three/fiber` difieren. Instalé sin `--frozen-lockfile`, así que los recuentos de errores de la biblioteca de componentes pueden depender de las versiones que obtuve.
- **Estados que el tipo excluye.** [`ForceRadiant.tsx`, líneas 721 y 725](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx#L720-L729), compara un `GovernanceHealthStatus` con `'ok'` y `'critical'`, que la unión no contiene (`TS2367`), y [`DataLoader.ts`, líneas 276-278](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L276-L278), pasa el `healthStatus: string` de un mensaje SignalR a través de `as unknown as GovernanceNode`. O a la unión le faltan dos estados, o las comparaciones son código muerto (*por verificar* en el hub de GA). La línea 1464 del mismo archivo compara una severidad de señal, `'info' | 'warning' | 'emergency'`, con `'critical'`. La lección 3 reduce el primer caso.
- **`noImplicitAny: false` junto a `strict: true`** en [`ga-react-components/tsconfig.app.json`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/tsconfig.app.json#L17-L20). Volver a activarlo solo añade cuatro errores, en `BSPDoomExplorer.tsx` e `IxqlFormPanel.tsx`; la lección 2 los lista.
- **Datos sin comprobar.** La biblioteca de componentes tiene 34 `as unknown as`, 42 llamadas a `JSON.parse` y 18 `as any`. La cámara se restaura desde `localStorage` con `JSON.parse(saved) as { px: number; … }` ([`ForceRadiant.tsx`, línea 3558](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx#L3555-L3561)), `loadQueue<T>` devuelve `JSON.parse` como un `T[]` ([`CourseViewer.tsx`, línea 152](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/CourseViewer.tsx#L152-L159)), y el `isApiResponse<T>` de `ga-client` comprueba dos nombres de propiedad antes de prometer un `ApiResponse<T>`, con `json as T` como recurso final ([`musicService.ts`, líneas 17-49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/musicService.ts#L17-L49)). Las lecciones 3 y 4 y sus ejercicios escriben las versiones comprobadas.
- **TypeScript 7 encuentra más.** `tsc -p tsconfig.app.json` sobre la biblioteca de componentes da 180 errores en 14.7 segundos con la 5.9.3 y 197 en 1.9 segundos con la 7.0.2. Los errores nuevos son nombres de Node.js en dos scripts (`TS2591`, porque `types` vale ahora `[]` por defecto), `TS2871` ("this expression is always nullish") en `BrainstormPanel.tsx` línea 40 y `GitHubPollingManager.ts` línea 48, y `TS2550` para `.at()` en `ChatWidget.tsx` línea 1254, con `lib` fijado a ES2020; la 5.9.3 no señaló ninguno de esos códigos.
- **Detalles.** `ga-client/tsconfig.json` tiene `"sourceMaps": true` en su nivel superior, donde `tsc` lo ignora; la opción es `sourceMap`, dentro de `compilerOptions`. `src/components/PrimeRadiant/index.ts` en la biblioteca de componentes exporta `RemediationAction` dos veces (`TS2300`, líneas 101 y 129), y `ThreeFretboard.tsx` línea 780 usa un tipo `GuitarModelStyle` que no existe. `ShowcasePanel.test.tsx` de `ga-client` usa el `global` de Node.js, que los tipos del proyecto de navegador no declaran.

## 2026-09-15 — Lo que encontró tsc en este sitio (8ba378e)

`npx -p typescript@7.0.2 tsc --noEmit` en el commit [`8ba378e`](https://github.com/spareilleux/learn/commit/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3), con el `tsconfig.json` del sitio, da tres errores, los mismos con la 6.0.3. Ninguno rompe el sitio.

- `astro.config.mjs`, línea 146: la barra lateral importada de `src/streeling-sidebar.json` no coincide con el `SidebarItemUserConfig` de Starlight, porque la unión inferida de sus entradas añade `fr?: undefined` a la entrada que solo tiene traducción al español. La lección 3 explica la inferencia.
- `code/javascript-for-csharp-java/errors/l04_private_outside.js`: el `tsconfig.json` del sitio incluye `**/*`, así que `tsc` verifica el código de los cursos, incluido un fragmento de error que es incorrecto a propósito. Los `errors/*.ts` del curso de TypeScript se recogerán de la misma manera; excluir `code/` en el `tsconfig.json` del sitio mantendría a los editores y a `tsc` en los archivos propios del sitio.
- `src/content.config.ts`: `astro:content` solo se declara después de `astro sync`.

## Por verificar

- El `ReferenceError` en la página `/ai-copilot` de GA, en un navegador.
- Si el hub de gobernanza de GA envía `ok` y `critical` como estados de salud.
- Qué hace `ForceRadiant` de GA con una cámara guardada a la que le falta una coordenada.
- `new[] { 1, "two", null }` en C#, citado en la lección 2 como rechazado por falta de un mejor tipo común.
- Los comandos de instalación de la lección 1 en Linux y macOS fuera de la CI.
