---
title: Diario
description: Notas de progreso fechadas del curso de TypeScript avanzado — el proyecto del curso sobre TypeScript 7.0.2, los límites del verificador medidos, las predicciones que las pruebas de tipos desmintieron, el lado de C# y Java, los tamaños de los bundles, lo que las lecciones encontraron en GuitarAlchemist/ga, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] El proyecto del curso: TypeScript 7.0.2, Zod 4.6.5, Valibot 1.5.0, ArkType 2.2.3 y esbuild 0.28.2 fijados en su propio `package.json` y su archivo de bloqueo
- [x] `check.sh`: pruebas de tipos, fragmentos de error, ejemplos y soluciones ejecutados con Node.js 24.21.0, tamaños de los bundles, comparaciones en C# y Java, todo comparado con `expected/`
- [ ] CI en Linux, Windows y macOS
- [x] Lección 1: programación a nivel de tipos
- [x] Lección 2: varianza y asignabilidad
- [x] Lección 3: modelar con tipos
- [x] Lección 4: fronteras en tiempo de ejecución
- [ ] Lección 5: archivos de declaración

## QA

El compilador de TypeScript, .NET 10 y dos bibliotecas de validación. Varias filas describen un comportamiento documentado contra el que se estrella una intuición, y la columna Estado lo dice. Las constantes del verificador se leyeron en [`checker.go`](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go) en el commit fijado antes de medirlas. Nada se ha reportado aguas arriba.

| Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|
| Un límite de recursión a nivel de tipos es una propiedad del tipo | Es una propiedad del archivo: las instanciaciones se cachean, así que lo que cabe depende de lo que el archivo evaluó antes | tsc 7.0.2, un `Reverse` no terminal | 48 elementos pasan y 49 fallan cuando está solo en el archivo; con un `Reverse` de 40 evaluado antes en el mismo archivo, pasan 80 | Reproducido; un límite medido en un archivo no es un límite para otro [2026-09-15](#2026-09-15--los-límites-del-verificador-medidos) |
| Un tipo contextual de literal de plantilla ensancha los literales a `string` | Los conserva: un tipo literal de plantilla cuenta como contexto literal | tsc 7.0.2, `satisfies Record<GovernanceHealthStatus, HexColor>` | Solo un tipo contextual como `string` los ensancha | Por diseño, y lo contrario de lo que esperaba el autor [2026-09-15](#2026-09-15--predicciones-que-las-pruebas-de-tipos-desmintieron) |
| Un parámetro de tipo `const` restringido por un array mutable cae a `string[]` | Infiere una tupla mutable | tsc, comprobado contra 5.0.4, 5.2.2 y 5.3.3 | Cierto de la 5.0 a la 5.2; cambió en la 5.3. La frontera se localizó bisecando tres versiones fijadas | Reproducido; un cambio de comportamiento, correctamente atribuido [2026-09-15](#2026-09-15--predicciones-que-las-pruebas-de-tipos-desmintieron) |
| `in out T` sobre un tipo que solo lee `T` se rechaza | Se acepta, porque `in out` vuelve invariante un tipo, lo que siempre es seguro | tsc 7.0.2 | Solo falla una anotación que contradice la estructura, con `TS2636` | Por diseño [2026-09-15](#2026-09-15--predicciones-que-las-pruebas-de-tipos-desmintieron) |
| Un `as` a un tipo al que le faltan propiedades se rechaza igual en todas partes | Directamente es `TS2352`; pasando por una variable los tipos son comparables y compila | tsc 7.0.2 | La segunda forma es la que se encuentra en código real, y es la que muestra la lección 2 | Por diseño; la mitad peligrosa es la silenciosa [2026-09-15](#2026-09-15--predicciones-que-las-pruebas-de-tipos-desmintieron) |
| `dotnet run file.cs` puede serializar un tipo anónimo | Falla en ejecución | programas de archivo único de .NET 10 | `Reflection-based serialization has been disabled for this application`, porque estos programas se publican con AOT nativo por defecto. `#:property PublishAot=false` lo restablece | Reproducido, no reportado [2026-09-15](#2026-09-15--el-lado-de-c-y-java) |
| `System.Text.Json` respeta por defecto las anotaciones de nulabilidad y de obligatoriedad | `RespectNullableAnnotations` y `RespectRequiredConstructorParameters`, ambos añadidos en .NET 9, vienen desactivados | `System.Text.Json`, .NET 9+ | Con ellos activados, el record de C# es un esquema | Por diseño; lo que sorprende es el valor por defecto [2026-09-15](#2026-09-15--el-lado-de-c-y-java) |
| Importar un validador elimina lo que no se usa | El import de barril no: `z` es un objeto que referencia todas las funciones | Zod 4.6.5 empaquetado por esbuild 0.28.2, minificado | 442,7 kB con `import { z } from 'zod'` frente a 87,4 kB con `import * as z from 'zod'` | Reproducido; la forma con espacio de nombres es también la de la documentación [2026-09-15](#2026-09-15--tamaños-de-los-bundles) |
| Validadores del mismo esquema tienen tamaños comparables | No | Valibot 1.5.0, `zod/mini`, Zod 4.6.5 | Valibot 4,8 kB minificado, unas 18 veces más pequeño que Zod; `zod/mini` unas 5 veces más pequeño | Medido en Windows, no reportado [2026-09-15](#2026-09-15--tamaños-de-los-bundles) |
| `JsonHubProtocol` necesita un servidor en marcha para mostrar lo que envía SignalR | No | SignalR de ASP.NET Core | `WriteMessage` sobre un `InvocationMessage` da el texto exacto, lo que zanjó qué pone el hub de GA en el cable sin arrancarlo | Una técnica, no un defecto — y es lo que permitió responder sin conexión a una pregunta de navegador [2026-09-15](#2026-09-15--el-lado-de-c-y-java) |

## Experimentos

En este curso una predicción es una línea de código: `type _1 = Expect<Equal<…>>`, que `tsc` comprueba junto con el resto del proyecto, así que una predicción equivocada hace fallar `check.sh` antes de que nada se ejecute. Cuatro de estas seis estaban equivocadas, y la sección que el diario les dedica se llama precisamente *predicciones que las pruebas de tipos desmintieron*. La última fila es la única donde la prueba vino tras la sospecha, y lo dice.

| Pregunta | Hipótesis | Resultado | Veredicto | Dónde |
|---|---|---|---|---|
| ¿Predicen las constantes del verificador dónde falla de verdad el código a nivel de tipos? | Leídas primero en `checker.go`: 100 instanciaciones anidadas, 5 000 000 en una expresión, 1000 pasos de un tipo condicional terminal, 100 000 miembros para una unión en producto cartesiano | Un constructor de tuplas terminal llega a 999 y falla en 1000 con `TS2589`; una unión de cinco posiciones de dígitos, 100 000 cadenas, falla con `TS2590`. Las medidas concuerdan | Confirmada | [2026-09-15](#2026-09-15--los-límites-del-verificador-medidos) |
| ¿Dónde falla un `Reverse` no terminal? | Planteada como difícil de predecir, e implícitamente como si tuviera un único número por respuesta | 48 pasan y 49 falla cuando está solo en el archivo; 80 pasan si un `Reverse` de 40 elementos se evalúa antes en el mismo archivo, porque las instanciaciones se cachean | La idea de un número único queda refutada | [2026-09-15](#2026-09-15--los-límites-del-verificador-medidos) |
| ¿Ensancha `satisfies Record<GovernanceHealthStatus, HexColor>` los colores a `string`? | Sí, escrita antes de ejecutar la prueba de tipos | Conserva los tipos literales: un tipo literal de plantilla como tipo contextual cuenta como contexto literal | Refutada, por una compilación fallida | [2026-09-15](#2026-09-15--predicciones-que-las-pruebas-de-tipos-desmintieron) |
| ¿Cae un parámetro de tipo `const` restringido por un array mutable a `string[]`? | Sí, escrita antes de ejecutar la prueba de tipos | Infiere una tupla mutable. La expectativa valía de la 5.0 a la 5.2 y cambió en la 5.3, comprobado contra 5.0.4, 5.2.2 y 5.3.3 | Refutada, y la frontera de versión localizada | [2026-09-15](#2026-09-15--predicciones-que-las-pruebas-de-tipos-desmintieron) |
| ¿Se rechaza `in out T` sobre un tipo que solo lee `T`? | Sí, escrita antes de ejecutar la prueba de tipos | Se acepta: `in out` vuelve invariante un tipo, lo que siempre es seguro. Solo falla una anotación contradictoria, con `TS2636` | Refutada | [2026-09-15](#2026-09-15--predicciones-que-las-pruebas-de-tipos-desmintieron) |
| ¿Esconde algo el `as` de `stopFrom`? | Sospechado, pero la prueba de tipos se añadió después — esta fila es la única entrada retrospectiva de la tabla | `EventOf<LiveState>` vale `never`: la aserción ocultaba que el estado `stopped` no tiene evento `stop`. La función toma ahora `Exclude<LiveState, 'stopped'>`, sin aserción | Refutada, a posteriori | [2026-09-15](#2026-09-15--predicciones-que-las-pruebas-de-tipos-desmintieron) |

## 2026-09-15 — El proyecto del curso

- El curso tiene su propio [`package.json`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/package.json), separado del del curso base, con las mismas versiones de TypeScript y Node.js: 7.0.2 y 24.21.0. El [`tsconfig.json`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/tsconfig.json) añade `exactOptionalPropertyTypes` y `noUncheckedIndexedAccess` a `strict`, ya que la lección 2 depende de la primera, y mantiene `erasableSyntaxOnly` para que Node.js ejecute cada ejemplo directamente, sin paso de build.
- Las pruebas de tipos viven en los ejemplos: líneas `type _1 = Expect<Equal<…>>` que `tsc` comprueba con todo el proyecto. Una predicción errónea hace fallar `check.sh` antes de que se ejecute nada, lo que ocurrió varias veces al escribir las lecciones 1 a 3, como se lista más abajo.
- `check.sh` es el script del curso base con dos añadidos: [`bundle-size.mjs`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/bundle-size.mjs), cuya salida se compara como cualquier otra, y comparaciones en C# que referencian ASP.NET Core con `#:sdk Microsoft.NET.Sdk.Web`.
- El repositorio de GA no se clona por completo en Windows: las carpetas `test-results/` de Playwright están en el repositorio, con rutas de más de 260 caracteres. Un clon disperso (*sparse*) de las carpetas que usan las lecciones, con `git config core.longpaths true`, funciona.

## 2026-09-15 — Los límites del verificador, medidos

- Los límites son constantes en [`internal/checker/checker.go`](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go): 100 instanciaciones anidadas y 5,000,000 en una expresión, 1,000 pasos de un tipo condicional con recursión de cola, y 100,000 miembros para una unión construida por producto cartesiano.
- Las mediciones coinciden: un constructor de tuplas con recursión de cola llega a 999 elementos y falla en 1,000 con `TS2589`; una unión de cinco posiciones de dígitos, 100,000 cadenas, falla con `TS2590`.
- Un `Reverse` sin recursión de cola es más difícil de predecir. Solo en su archivo, 48 elementos pasan y 49 fallan. Con un `Reverse` de 40 elementos evaluado antes en el mismo archivo, pasan 80 elementos: las instanciaciones se guardan en caché, y la segunda evaluación parte de los resultados de la primera. Un límite a nivel de tipos medido en un archivo no es un límite para otro archivo.

## 2026-09-15 — Predicciones que las pruebas de tipos desmintieron

- Esperaba que `satisfies Record<GovernanceHealthStatus, HexColor>`, donde `HexColor` es un tipo de plantilla literal, ensanchara los colores a `string`. Conserva los tipos literales: un tipo de plantilla literal como tipo contextual cuenta como contexto literal, y solo un tipo contextual como `string` los ensancha.
- Esperaba que un parámetro de tipo `const` con una restricción de array mutable recurriera a `string[]`. Ese era el comportamiento de la 5.0 a la 5.2; desde la 5.3 infiere una tupla mutable. Lo comprobé con `npx -p typescript@5.0.4`, `5.2.2` y `5.3.3`.
- Esperaba que `in out T` en un tipo que solo lee `T` fuera rechazado. Se acepta: `in out` hace invariante un tipo, lo que siempre es seguro, y solo una anotación que contradice la estructura, como `in` en un tipo que devuelve `T`, es un error (`TS2636`).
- En la primera versión de la máquina de estados de la lección 3, una función `stopFrom` usaba `as` para que `send(state, 'stop')` compilara para cualquier estado. La prueba de tipos que añadí después mostró que `EventOf<LiveState>` es `never`: la aserción ocultaba que el estado `stopped` no tiene evento `stop`. La función toma ahora `Exclude<LiveState, 'stopped'>`, sin aserción.
- Un literal de objeto afirmado con `as` a un tipo del que le faltan propiedades no siempre se acepta: directamente, `tsc` informa de `TS2352`; a través de una variable, los tipos son comparables y compila. La lección 2 muestra la segunda forma, que es la que se encuentra en código real.

## 2026-09-15 — El lado de C# y Java

- `dotnet run file.cs` sobre un archivo que serializa un tipo anónimo falló con "Reflection-based serialization has been disabled for this application". Las aplicaciones basadas en archivo se publican con AOT nativo por defecto, y esa opción también desactiva el JSON basado en reflexión en tiempo de ejecución; `#:property PublishAot=false` en el archivo lo restaura.
- `JsonHubProtocol` puede usarse sin servidor: `WriteMessage` sobre un `InvocationMessage` da el texto exacto que envía SignalR, lo que zanjó qué pone el hub de GA en la red sin arrancarlo.
- En `System.Text.Json`, `RespectNullableAnnotations` y `RespectRequiredConstructorParameters`, ambas de .NET 9, están desactivadas por defecto; con ellas, el record de C# es un esquema.

## 2026-09-15 — Tamaños de los bundles

- El mismo esquema Zod, empaquetado por esbuild, ocupa 442.7 kB minificado con `import { z } from 'zod'` y 87.4 kB con `import * as z from 'zod'`. La diferencia es el *tree shaking*: `z` es un objeto que referencia todas las funciones. La lección 4 mantiene la forma de espacio de nombres, que es también la de la documentación.
- Valibot, 4.8 kB minificado, es unas 18 veces más pequeño que Zod para este esquema, y `zod/mini` unas 5 veces.
- Los tamaños se miden en Windows. La salida de esbuild no depende del SO, y la CI los compara en Linux y macOS (*por verificar* cuando el workflow se haya ejecutado).

## 2026-09-15 — Lo que las lecciones encontraron en GuitarAlchemist/ga

En el commit [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381), en `ReactComponents/ga-react-components` y `Apps/ga-server/GaApi/Hubs`:

- **Una actualización `NodeChanged` perdida** (lección 4). El hub envía `nodeId`; el cliente afirma que el mensaje es un `GovernanceNode`, cuya clave es `id`; `updateNodeHealth` busca el nodo por `id` y descarta la actualización en silencio. Una búsqueda en el código no encuentra ningún llamador de `BroadcastNodeChanged`, así que el bug está latente.
- **Ningún contrato compartido entre el hub y el cliente** (lección 1). El hub deriva de `Hub`, no de `Hub<T>`, y envía los nombres de método como cadenas; el cliente registra diez manejadores con cadenas. El comentario de documentación del hub lista un evento `HealthUpdate` que nunca envía, y la opción `onScreenshotRequest` del cliente maneja el evento `RequestScreenshot`.
- **`ViewerInfo.displayName`** (lección 2) se declara `displayName?: string` en TypeScript y el record de C# lo envía como `null`; el código funciona porque cada lectura usa `?.` o `??`.
- **Dos numeraciones de cuerdas** (lección 3): cuatro interfaces llamadas `FretboardPosition`, todas con `string: number`; `InstrumentConfig.ts` y `GuitarFretboard.tsx` cuentan las cuerdas desde 0, mientras que `VexTabViewer.tsx` e `InverseKinematics.tsx` toman números de cuerda desde 1.
- **El estado de voz de `ChatWidget.tsx`** (lección 3): `isListening` y `voiceState` pueden contradecirse; `startListening` lee `voiceState` sin listarlo en sus dependencias de `useCallback`, así que sus comprobaciones `voiceState === 'listening'` ven un valor obsoleto; `sendMessage(…).then(…)` no tiene `catch`, y una petición fallida puede dejar el estado en `'processing'`.
- **Fronteras sin comprobar** (lección 4): 42 llamadas a `JSON.parse`, 55 líneas que afirman `response.json()` con `as`, y 34 `as unknown as`, fuera de las pruebas.

No los he comunicado al repositorio de GA; se listan aquí tal como se encontraron.

## Por verificar

- El camino de `NodeChanged` en un servidor en marcha, si algo empieza a llamar a `BroadcastNodeChanged`.
- El `voiceState` obsoleto en `ChatWidget.tsx`, en un navegador con reconocimiento de voz: un error mientras escucha debería dejar el indicador en `'listening'`.
- Las salidas del curso en Linux y macOS, cuando se ejecute el workflow de la CI.
