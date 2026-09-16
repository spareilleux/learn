---
title: Diario
description: Notas de progreso fechadas del curso de three.js — fijar three.js r186, Vite 8.3 y Playwright 1.63, medir páginas WebGPU en Chromium sin interfaz en tres sistemas operativos, con qué renderizan realmente los runners de CI, sorpresas en @types/three y DRACOLoader, lo que el curso encontró en el código 3D de GuitarAlchemist/ga, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] three 0.186.0, `@types/three` 0.186.0, Vite 8.3.0, TypeScript 7.0.2, Playwright 1.63.0 y glTF Transform 4.5.0 fijados en el propio `package.json` del curso y en su archivo de bloqueo
- [x] `check.sh`: comprobación de tipos, los scripts de Node.js, cada página de lección sondeada en Chromium sin interfaz, la compilación de producción, comparados con `expected/`
- [x] CI en Ubuntu, Windows y macOS
- [x] Lección 1: escena, cámara, renderizador
- [x] Lección 2: geometrías, materiales, luces y sombras
- [x] Lección 3: color, mapeo de tonos y entornos HDR
- [x] Lección 4: modelos glTF y animaciones
- [ ] Lección 5: interacción, `Raycaster` y controles de cámara

## 2026-09-16 — Versiones

- `npm view three` da 0.186.0, publicada el 8 de septiembre de 2026, y `@types/three` 0.186.0. El curso las fija de forma exacta en [`code/threejs/package.json`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/package.json), con Vite 8.3.0, TypeScript 7.0.2, Playwright 1.63.0 y su Chromium 153, glTF Transform 4.5.0, `draco3dgltf` 1.5.7, `meshoptimizer` 1.2.0 y `pngjs` 7.0.0, sobre Node.js 24.21.0 en CI.
- La versión r186 es la versión npm `0.186.0`. Las lecciones citan el código fuente en la etiqueta `r186` de [mrdoob/three.js](https://github.com/mrdoob/three.js/tree/r186).
- `require('three/package.json')` falla: el mapa `exports` del paquete no lo incluye. La comprobación de versión de `check.sh` lee el archivo con `fs` en su lugar.
- Las páginas de la documentación están en `https://threejs.org/docs/pages/<Class>.html` y `https://threejs.org/manual/pages/<page>.html`; las lecciones enlazan esas URL, todas comprobadas.

## 2026-09-16 — Medir páginas en un navegador sin interfaz

- Cada página de lección informa de lo que hizo el renderizador mediante una promesa `window.probe`, y [`scripts/probe.mjs`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/scripts/probe.mjs) arranca Vite, abre la página con Playwright a 800 por 450 píxeles y una relación de píxeles de 1, e imprime el informe. Las páginas que se animan usan pasos fijos cuando se sondean, así que el tercer fotograma es el mismo en todas las máquinas.
- Mi primera sonda se colgaba en la página de `WebGLRenderer`: la página reemplazaba `window.probe` después de que `page.evaluate` hubiera empezado a esperar la promesa antigua. Ahora las páginas resuelven una promesa creada una sola vez, en [`src/probe.ts`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/src/probe.ts), y `probe.mjs` se rinde a los 30 segundos.
- Los colores se leen de la captura de pantalla, en las posiciones que indica la página.
- El modo sin interfaz predeterminado de Playwright en Windows da WebGPU en la RTX 5080 del autor ("nvidia, blackwell"). `chromium-headless-shell`, la compilación más ligera, no tiene adaptador WebGPU: `WebGPURenderer` recurre a WebGL 2, sobre SwiftShader. `check.sh` ejecuta la lección 1 en ambos.

## 2026-09-16 — Con qué renderizan los runners de CI

- La primera ejecución de CI, [35114590607](https://github.com/spareilleux/learn/actions/runs/35114590607), falló en los tres sistemas operativos, por tres motivos: el `coordinateSystem` que informa la página depende del backend; algunos colores difieren en uno respecto a la GPU del autor; y en macOS, el aviso de Vite, en stderr, llegaba antes que sus líneas de stdout. Ahora las sondas filtran las líneas que dependen del backend, [`compare.mjs`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/scripts/compare.mjs) acepta una diferencia de 2 por canal en los colores, y el stderr de la compilación se imprime después de su stdout.
- La ejecución [35115118564](https://github.com/spareilleux/learn/actions/runs/35115118564) pasó. Sus registros muestran con qué dibuja cada runner. `ubuntu-24.04` y `windows-2025-vs2026` no tienen GPU: WebGPU no está disponible, y tanto `WebGPURenderer` como `forceWebGL` ejecutan WebGL 2 sobre SwiftShader (Subzero). `macos-26-arm64` tiene WebGPU, en un adaptador "apple", y WebGL 2 en "ANGLE Metal Renderer: Apple Paravirtual device"; su headless shell usa SwiftShader (LLVM 10.0.0).
- Dos colores difieren en uno en los runners: ACES convierte el lineal 0.18 en 127 en la GPU del autor y en 128 en CI, y Neutral convierte 0.05 en 33 y en 34.
- Así que una ejecución de CI en verde demuestra que las escenas se construyen, se cargan y producen los mismos contadores y colores, con un margen de 2, en un rasterizador por software y en la GPU de Apple. No demuestra nada sobre WebGPU en Windows o Linux.

## 2026-09-16 — Sorpresas

- **`WebGPURenderer` cuenta una llamada de dibujo más de las que tiene la escena.** Con mapeo de tonos, o con un espacio de color de salida distinto del espacio de trabajo, renderiza la escena en un destino y dibuja el resultado en una pasada de salida: 2 llamadas de dibujo y 13 triángulos para un cubo. `WebGLRenderer` convierte en cada shader e informa 1. Los objetos `info` de los dos renderizadores tampoco tienen la misma forma.
- **`@types/three` describe mal `toJSON()`.** En 0.186.0, `Object3DJSON` declara `children` como cadenas y no tiene `geometries` ni `materials`, mientras que en tiempo de ejecución se escriben objetos y ambos arreglos. La lección 1 guarda los errores del compilador en [`errors/l01_tojson_types.ts`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/errors/l01_tojson_types.ts). No he buscado si ya existe una incidencia en three-types/three-ts-types, ni he abierto una.
- **`WebGPURenderer` lee la caja de la cámara de sombras una sola vez.** `ShadowNode` llama a `updateProjectionMatrix()` cuando construye la sombra; un cambio posterior necesita tu propia llamada.
- **`PCFSoftShadowMap` ya no existe en `WebGPURenderer` en r186** y emite un aviso. `LunarLanderEngine.ts` y `MinimalThreeInstrument.tsx` de GA todavía lo usan con `WebGPURenderer`.
- **Una luz puntual de 800 lúmenes son 63.66 candelas, y una luz focal de 800 lúmenes 254.65**: `SpotLight.power` usa π, no 4π, y no cambia con el ángulo del cono.
- **El PMREM cuesta 17 renderizados** para un entorno de 256 por 128: 1 en el primer nivel, y luego 2 por cada uno de los otros 8. Ocurre incluso cuando `scene.environment` es una simple textura equirrectangular.
- **Desde r185, `DRACOLoader` encuentra sus decodificadores con `import.meta.url`**, algo que r184 no hacía. Vite copia entonces los cinco archivos de decodificador en la compilación, 1.31 MB, cuando un navegador carga dos. La compilación también avisa de que `three.webgpu` supera los 500 kB.
- **Draco y meshopt descartan vértices.** Los dos descartan los dos vértices de los polos que crea `SphereGeometry` y que ningún triángulo usa; el `weld()` de Draco además fusiona las esquinas del cuerpo no indexado.
- El `meshopt()` de glTF Transform imprime líneas `prune: Removed types... Accessor` en stdout; están en `expected/` tal cual.

## 2026-09-16 — GuitarAlchemist/ga

El curso lee GA en el commit [`05c8eda`](https://github.com/GuitarAlchemist/ga/tree/05c8eda013f2a4d11efaa52c4ca94674521ee684), que usa three 0.180. 139 archivos bajo directorios `src` importan three; 33 de ellos llaman a `requestAnimationFrame`, 3 a `setAnimationLoop`; 29 crean un `WebGLRenderer` y 8 un `WebGPURenderer`; 15 usan `Clock`, obsoleto desde r183. Nada de lo que sigue se ha comunicado a GA.

- `ThreeFretboard.tsx` espera que `WebGPURenderer` lance una excepción cuando falta WebGPU, y dice "Using WebGPU renderer" en todas las máquinas, ya que el renderizador recurre a WebGL 2 en su lugar (lección 1). Sus sombras solo se activan para un `WebGLRenderer`, así que la ruta alternativa no tiene ninguna (lección 2).
- `ThreeFretboard.tsx` pide `samples: 8`; la especificación de WebGPU permite 1 o 4 muestras para una textura. Qué hace r180 con 8 en cada backend está *por verificar*.
- Su luz puntual de 0.6 cd con `distance: 20` da alrededor del 5 % de la luz principal donde está más cerca del mástil (lección 2), y una única textura de canvas sirve como mapa de color, de rugosidad, de normales y de relieve.
- Su textura de madera no tiene `colorSpace`, así que se ve más clara de como se pintó, y su entorno es un degradado de 8 bits cuyo PMREM el renderizador construye de todos modos (lección 3). Cuánto difiere en pantalla el color de la madera está *por verificar* en un navegador.
- `Guitar3D.tsx` construye un entorno negro con `fromScene` sobre una escena que solo contiene una luz ambiental, y anuncia compatibilidad con KTX2 y meshopt sin configurar ninguno de los dos decodificadores (lecciones 3 y 4).
- `Ocean.tsx` carga los decodificadores de Draco desde gstatic.com; `DemerzelFaceOverlay.tsx` oculta los errores de KTX2 reemplazando `console.error` durante una carga; `HandAnimationTest.tsx` actualiza un `AnimationMixer` que no tiene ninguna acción (lección 4).
- Para lecciones posteriores: `Ocean.tsx` usa `PostProcessing`, renombrado `RenderPipeline` en r183; 16 archivos usan `ShaderMaterial` o GLSL, y 10 usan `EffectComposer`, que `WebGPURenderer` no admite; `Experiments/ThreeJS-BSP-Loader` importa `WebGPURenderer` desde una ruta eliminada en r167; el visor de embeddings del panel quita un listener de redimensionado con un nuevo `bind`, lo que no quita nada.

## Por verificar

- Si una escena modelada en centímetros necesita luces 10 000 veces más fuertes para verse igual que en metros (lección 2).
- Texturas KTX2: carga, formatos de GPU elegidos en cada sistema operativo, memoria (lección 8).
- Draco frente a meshopt en un modelo grande y en muchos pequeños, sobre una red real (lección 4, ejercicio 3).
- WebGPU en una máquina Linux o Windows con GPU, fuera de la del autor.
