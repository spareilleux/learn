---
title: Diario
description: Notas de progreso fechadas del curso de React (Vite) — fijar React 19.3, Vite 8.3 y Vitest 5, capturar el servidor de desarrollo y una actualización HMR en un script, sorpresas en Vite, Vitest y @types/react, lo que el curso encontró en los componentes React de GuitarAlchemist/ga, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] React 19.3.0, Vite 8.3.0, TypeScript 7.0.2, Vitest 5.0.0, Testing Library y oxlint fijados en el propio `package.json` del curso y en su archivo de bloqueo
- [x] `check.sh`: `create-vite`, el servidor de desarrollo, una actualización HMR, `tsc`, `vite build`, oxlint, cada fragmento de error y cada prueba, comparados con `expected/`
- [ ] CI en tres sistemas operativos (ver más abajo)
- [x] Lección 1: un proyecto Vite
- [x] Lección 2: componentes y JSX
- [x] Lección 3: estado y renderizado
- [x] Lección 4: eventos y formularios
- [ ] Lección 5: efectos

## 2026-09-15 — Versiones

- `npm view` da React y React DOM 19.3.0, publicados el 9 de septiembre de 2026, Vite 8.3.0, `@vitejs/plugin-react` 6.1.1, Vitest 5.0.0, jsdom 30.0.1, `@testing-library/react` 16.3.3, `@testing-library/dom` 10.4.2, `@testing-library/user-event` 14.6.7, oxlint 1.83.0 y `create-vite` 9.2.1. El curso los fija exactamente en [`code/react-vite/package.json`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/package.json), y usa el Node.js 24.21.0 y el TypeScript 7.0.2 de los demás cursos del sitio.
- La plantilla `react-ts` de `create-vite` 9.2.1 pide TypeScript `~6.0.2`, no 7.0: un rango con `~` solo admite 6.0.x. El curso usa 7.0.2, y `tsc -b` verifica los dos proyectos de la plantilla sin ningún cambio. Su `strict` no aparece, porque es el valor por defecto desde TypeScript 6.0, y su herramienta de lint es oxlint en lugar de ESLint, con una opción `--eslint` para recuperar ESLint.
- Vite 8 empaqueta con Rolldown y transforma con Oxc. La [lección 1 del curso de TypeScript](../../typescript-for-csharp-java/01-compiler-and-tooling/#en-proyectos-reales) dice que Vite elimina los tipos con esbuild: es cierto para el Vite 5 de GA, y ya no para Vite 8. `@vitejs/plugin-react` 6 tampoco depende de Babel; Fast Refresh lo hace Oxc.
- El archivo de bloqueo escrito en Windows lista los paquetes nativos de todas las plataformas como dependencias opcionales: `@rolldown/binding-*`, `@oxlint/*` y `@typescript/typescript-*`.

## 2026-09-15 — Capturar el servidor de desarrollo

- El servidor de desarrollo, los módulos que sirve y el mensaje HMR se capturan con scripts, no a mano: [`dev-start.mjs`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/scripts/dev-start.mjs) inicia `vite` y lo detiene cuando se imprime la URL, [`dev-module.mjs`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/scripts/dev-module.mjs) solicita una URL mediante la API JavaScript de Vite, y [`hmr.mjs`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/scripts/hmr.mjs) se conecta al WebSocket de HMR, edita una copia de `App.tsx` e imprime los mensajes.
- Cuando la salida no es un terminal, Vite no imprime la línea `press h + enter to show help`. Mi primer `dev-start.mjs` esperaba esa línea, nunca la vio, y dejó un servidor en marcha en el puerto 5199; ahora espera `use --host to expose`.
- En Windows, `server.close()` llamado justo después de la primera solicitud de módulo nunca terminaba: Node.js imprimió "Detected unsettled top-level await" y salió con el código 13. La solicitud había arrancado el optimizador de dependencias, que seguía en marcha. Esperar `server.environments.client.waitForRequestsIdle()` antes de `close()` lo arregló. No he comprobado si Linux o macOS se comportan igual (*por verificar*), ni he buscado una issue existente de Vite.
- Git Bash en Windows reescribe los argumentos que empiezan por `/`: `vite build --base /learn/react-vite/` generó páginas que pedían `/Program Files/Git/learn/react-vite/assets/…`. `check.sh` define `MSYS_NO_PATHCONV=1`, y los scripts reciben las rutas de módulo sin su barra inicial.
- Las salidas se normalizan con [`normalize.mjs`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/normalize.mjs): duraciones, el hash `?v=` de las dependencias preempaquetadas, las marcas de tiempo de HMR y los source maps en línea. Los nombres de los archivos de producción, como `index-BQ_Vbf-Q.js`, son hashes del contenido y se mantienen tal cual.
- Que Fast Refresh conserve el estado no está en `check.sh`, que solo ve el mensaje del WebSocket. Lo comprobé a mano en un navegador: tres clics en el contador, dos en el capo, y luego una edición del encabezado en `App.tsx`. El encabezado cambió, el contador y el capo conservaron sus valores, y una variable definida en `window` antes de la edición sobrevivió, así que la página no se había recargado. Para la lección 1, también serví con `vite preview` el build con un error de tipo e hice clic dos veces en su botón: `Count is 01`, y luego `Count is 011`.

## 2026-09-15 — Vitest y Testing Library

- React Testing Library desmonta los componentes renderizados después de cada prueba solo cuando el framework de pruebas expone un `afterEach` global. Vitest no lo hace, salvo con `globals: true`, así que el DOM de una prueba se quedaba en la siguiente y las consultas encontraban dos formularios. [`src/testing/setup.ts`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/src/testing/setup.ts) llama a `cleanup` en `afterEach`, como describe la [documentación de Testing Library](https://testing-library.com/docs/react-testing-library/api#cleanup).
- El reporter por defecto de Vitest imprime la salida de consola agrupada por momento, no por prueba, y la agrupación cambiaba entre ejecuciones. El [`reporter.mjs`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/scripts/reporter.mjs) del curso recoge cada log con su prueba y los imprime en orden al final, y `check.sh` ejecuta un archivo de prueba por ejecución de Vitest.
- Las advertencias de desarrollo de React, la clave que falta o el input controlado, van a `console.error`, y el reporter las imprime con un prefijo `console.error:`, así que las lecciones las citan a partir de las pruebas.
- Un contador a nivel de módulo, en una primera versión de la prueba de StrictMode de la lección 3, seguía contando de una prueba a la siguiente: Vitest aísla los archivos de prueba, no las pruebas. El componente impuro recibe ahora como prop el array que modifica.
- `tsconfig.app.json` tenía al principio la lib `DOM.Iterable`, para expandir un `NodeList` en una prueba. Con TypeScript 7.0.2, `DOM` solo lo acepta; la configuración del curso tiene ahora el `["ES2023", "DOM"]` de la plantilla.

## 2026-09-15 — @types/react y React 19.3

- `@types/react` 19.3.0 marca `FormEvent` y `FormEventHandler` como `@deprecated`, con el comentario "FormEvent doesn't actually exist", y remite a `ChangeEvent`, `InputEvent` y `SubmitEvent`. `ChangeEvent` tiene dos parámetros de tipo, el current target y el target. La lección 4 usa `SubmitEvent<HTMLFormElement>` para `onSubmit`.
- El tipo de retorno de un componente, en el mensaje de `tsc`, es `Promise<ReactNode> | ReactNode`: los tipos aceptan componentes asíncronos, para los Server Components.
- En StrictMode, React 19.3 renderiza dos veces un componente impuro al montarlo, y el DOM muestra la salida del segundo render, "Played so far: G G".

## 2026-09-15 — La CI

- [`react-vite-examples.yml`](https://github.com/spareilleux/learn/blob/f6417a9/.github/workflows/react-vite-examples.yml) ejecuta `npm ci` y `bash check.sh` en Ubuntu, Windows y macOS con Node.js 24.21.0. `check.sh` tarda unos 50 segundos en mi máquina Windows.
- El primer push fue rechazado: el token de GitHub usado para el push no tiene el scope `workflow`, que GitHub exige para crear un archivo bajo `.github/workflows`. El código se subió sin el workflow, y la ejecución en tres sistemas operativos sigue pendiente (*por verificar*: diferencias entre sistemas, como el orden de la lista de archivos de `create-vite` o el formato de salida de oxlint).

## 2026-09-15 — Lo que el curso encontró en GuitarAlchemist/ga

En el commit [`8cc8c5a`](https://github.com/GuitarAlchemist/ga/commit/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41), en `ReactComponents/ga-react-components` y `Apps/ga-client`; `Apps/ga-dashboard` es una aplicación Angular 21, fuera de este curso. Nada de esto se ha comunicado a GA.

- **Filas expandidas recordadas por índice.** [`DynamicPanel.tsx`](https://github.com/GuitarAlchemist/ga/blob/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components/src/components/PrimeRadiant/DynamicPanel.tsx#L76-L120) guarda sus filas expandidas en un `Set<number>` de posiciones en los datos filtrados y consultados periódicamente. Tras un filtro o una consulta que cambia el orden, queda expandida otra fila. La lección 3 lo reproduce en `ExpandableList.tsx`. Los datos del panel son `unknown[]`; qué campo podría servir de identidad depende de las definiciones de los paneles (*por verificar*).
- **Un bucle de renders entre dos componentes.** [`NotesSelector.tsx`](https://github.com/GuitarAlchemist/ga/blob/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components/src/components/NotesSelector.tsx#L15-L18) llama a `onNotesChange` desde un efecto que depende de él, y [`ScaleSelector.tsx`](https://github.com/GuitarAlchemist/ga/blob/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components/src/components/ScaleSelector.tsx#L18-L21) pasa un manejador nuevo en cada render, que guarda un array nuevo. La reducción de la lección 4 termina con "Maximum update depth exceeded". `ScaleSelector` también guarda en el estado `scale`, derivado de las notas. Se exporta desde `components/index.ts`, y ninguna aplicación de GA lo renderiza en este commit, así que el bucle está latente. No he montado el propio componente de GA (*por verificar*).
- **Una ventana deslizante con clave por índice.** [`DemerzelCriticOverlay.tsx`](https://github.com/GuitarAlchemist/ga/blob/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components/src/components/PrimeRadiant/DemerzelCriticOverlay.tsx#L179-L189) dibuja las diez últimas puntuaciones con `key={i}`, y sus barras tienen `transition: height 0.3s ease`: una vez llena la ventana, cada nueva puntuación cambia y anima todas las barras. El ejercicio 3 de la lección 2 muestra la reutilización de elementos; no he observado la animación (*por verificar*).
- **Las reglas React de oxlint.** oxlint 1.83.0 con `react/no-array-index-key`, `react/exhaustive-deps` y `typescript/no-explicit-any` señala, en `ga-react-components/src`, 85 claves por índice, 34 listas de dependencias de efectos o callbacks que no coinciden con lo que lee la función, y 11 `any` explícitos; en `ga-client/src`, 6 claves por índice. `react/jsx-key` y `react/rules-of-hooks` no señalan nada. Los recuentos son resultados de lint, no errores: la mayoría de las claves por índice están en listas que nunca cambian.
- **Efectos sin limpieza.** Una búsqueda aproximada de las llamadas a `useEffect` que inician un temporizador, un listener o una suscripción y no devuelven limpieza encontró una: [`ChatWidget.tsx`](https://github.com/GuitarAlchemist/ga/blob/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components/src/components/PrimeRadiant/ChatWidget.tsx#L810-L815) inicia un `setTimeout` de 300 ms que no se cancela si el componente se desmonta antes. La búsqueda es textual, no un parser (*por verificar* antes de sacar conclusiones).
- **Opciones de escena.** [`SceneOptions.tsx`](https://github.com/GuitarAlchemist/ga/blob/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components/src/components/PrimeRadiant/SceneOptions.tsx#L119) también notifica a su padre desde un efecto, una vez al montarse, con la regla de dependencias desactivada. Su fusión de los parámetros de URL y las opciones guardadas ya es objeto de la pull request abierta [GuitarAlchemist/ga#683](https://github.com/GuitarAlchemist/ga/pull/683), del curso de JavaScript; este curso no la corrige otra vez.
- **Build y servidor de desarrollo.** El script `build` de `ga-react-components` es `vite build` sin `tsc`, y su `vite.config.ts`, de 3005 líneas, añade middleware para decenas de endpoints `/dev-data/` detrás de un túnel de Cloudflare (lección 1). El script `dev` de `Apps/ga-client` se niega a arrancar, y dice que se use `ga-react-components` en su lugar. El repositorio también versiona archivos generados: `tsconfig.app.tsbuildinfo`, `playwright-report` y `test-results` en `ga-react-components`.

## Por verificar

- El bloqueo de `server.close()` en Linux y macOS, y si Vite tiene una issue para ello.
- El `ScaleSelector` y el `NotesSelector` de GA montados con Material UI, y la animación de DemerzelCriticOverlay.
- Un campo de identidad para las filas de `DynamicPanel` en las definiciones de paneles de GA.
- Las salidas del curso en Linux y macOS, cuando la CI se ejecute.
