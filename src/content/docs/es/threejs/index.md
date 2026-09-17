---
title: three.js para desarrolladores C#/Java — Misión
description: 3D en tiempo real en el navegador con three.js r186, WebGPURenderer y su alternativa WebGL 2, materiales de nodos TSL, glTF y React Three Fiber, para desarrolladores que conocen C# o Java y TypeScript — cada escena medida en Chromium headless y cada número comparado en CI en Windows, Linux y macOS.
sidebar:
  label: Misión
  order: 0
---

:::note[Versión estudiada]
[three.js](https://threejs.org/) **r186** (el paquete npm `three` 0.186.0, publicado el 8 de septiembre de 2026), con [`@types/three`](https://www.npmjs.com/package/@types/three) 0.186.0, servido y construido por [Vite](https://vite.dev/) 8.3.0, verificado con [TypeScript](https://www.typescriptlang.org/) 7.0.2 y medido en Chromium headless con [Playwright](https://playwright.dev/) 1.63.0 sobre [Node.js](https://nodejs.org/) 24. Las escenas y los scripts del curso están en [`code/threejs`](https://github.com/spareilleux/learn/tree/eeca669/code/threejs), con un `package.json` y un archivo de bloqueo que también fijan [glTF Transform](https://gltf-transform.dev/) 4.5.0, y para las lecciones 9 a 13 [React](https://react.dev/) 19.2.8, [React Three Fiber](https://r3f.docs.pmnd.rs/) 9.7.0, [drei](https://drei.docs.pmnd.rs/) 10.7.8, [Rapier](https://rapier.rs/) 0.20.0, [IWER](https://github.com/meta-quest/immersive-web-emulation-runtime) 2.4.0, [Vitest](https://vitest.dev/) 5.0.1 y [pixelmatch](https://github.com/mapbox/pixelmatch) 7.2.0. [`.github/workflows/threejs-examples.yml`](https://github.com/spareilleux/learn/blob/eeca669/.github/workflows/threejs-examples.yml) ejecuta [`check.sh`](https://github.com/spareilleux/learn/blob/eeca669/code/threejs/check.sh) en Linux, Windows y macOS: verifica los tipos de todo, ejecuta los scripts de Node.js y las pruebas de componentes, abre cada página de lección en Chromium headless, construye las páginas y compara las salidas con las que se pegan en las lecciones.
:::

## Por qué aprendo esto

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) dibuja con three.js un mástil de guitarra en 3D, un océano, un sistema solar y unas cuantas decenas de escenas más. Algunas usan el nuevo `WebGPURenderer` y su lenguaje de shading, TSL; la mayoría todavía usa `WebGLRenderer` y GLSL escrito a mano. Como desarrollador C#, conozco el `Viewport3D` de WPF y un poco de MonoGame. three.js se parece a ambos al principio: un grafo de escena, una cámara, mallas y luces. Luego los detalles cambian: el renderer puede elegir WebGPU o WebGL sin avisarme, un color hexadecimal no es el número que recibe el shader, la intensidad de una luz está en candelas, y un modelo llega como un archivo glTF que necesita sus propios decodificadores.

Este curso aprende three.js tal como es en septiembre de 2026, no como lo muestran la mayoría de los tutoriales: `WebGPURenderer` primero, `setAnimationLoop` en lugar de `requestAnimationFrame`, TSL en lugar de `ShaderMaterial`, importaciones de `three/addons`, `Timer` en lugar de `Clock`, `HDRLoader` en lugar de `RGBELoader`.

## A quién va dirigido este curso

Te manejas bien con C# o Java, y has seguido [JavaScript para desarrolladores C#/Java](../javascript-for-csharp-java/) y [TypeScript para desarrolladores C#/Java](../typescript-for-csharp-java/), o conoces su contenido: módulos ES y npm, `async` y `await`, clases, tipos estructurales. La lección 9 usa React; el [curso de React (Vite)](../react-vite/) cubre lo que necesita. No hace falta experiencia previa en 3D, pero si has usado [WPF 3D](https://learn.microsoft.com/dotnet/desktop/wpf/graphics-multimedia/3-d-graphics-overview), [MonoGame](https://monogame.net/) o [JavaFX 3D](https://openjfx.io/javadoc/25/javafx.graphics/javafx/scene/SubScene.html), cada lección dice qué se puede aprovechar.

## three.js en una tabla

| | WPF 3D | MonoGame | JavaFX 3D | three.js |
|---|---|---|---|---|
| Dónde dibuja | un elemento `Viewport3D` | la ventana del juego | una `SubScene` | un `<canvas>` creado por el renderer |
| Grafo de escena | `ModelVisual3D`, `Model3DGroup` | ninguno: dibujas cada modelo | `Group`, `MeshView` | `Scene`, `Group`, `Mesh` |
| Ejes | dextrógiros, Y hacia arriba | matrices dextrógiras, Y hacia arriba | Y hacia abajo | dextrógiros, Y hacia arriba |
| Geometría | `MeshGeometry3D` | buffers de vértices e índices | `TriangleMesh` | `BufferGeometry` |
| Materiales | `DiffuseMaterial`, `SpecularMaterial` | `BasicEffect`, efectos personalizados | `PhongMaterial` | basados en la física: `MeshStandardMaterial`, materiales de nodos |
| El bucle | retenido: WPF renderiza cuando algo cambia | `Update` y `Draw`, llamados por `Game` | `AnimationTimer` | `renderer.setAnimationLoop(callback)` |
| API de GPU | Direct3D 9 | DirectX u OpenGL | Direct3D u OpenGL, a través de Prism | WebGPU, o WebGL 2 como alternativa |
| Shaders | ninguno | efectos HLSL | ninguno | TSL, compilado a WGSL o GLSL |
| Archivos de modelo | nada integrado | el content pipeline (FBX, X) | nada integrado | glTF 2.0 con `GLTFLoader` |

## Los datos

Las escenas propias del curso son pequeñas y deterministas: un cubo, un trozo de mástil de guitarra hecho de primitivas, parches de color, diez esferas en un estudio HDR y un metrónomo escrito como archivo glTF por un script. Cada página informa de lo que hizo el renderer, y un script de Playwright lo lee, así que los números de las lecciones vienen de una ejecución, no de la memoria.

El código real es [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) en el commit [`05c8eda`](https://github.com/GuitarAlchemist/ga/commit/05c8eda013f2a4d11efaa52c4ca94674521ee684), sobre todo [`ThreeFretboard.tsx`](https://github.com/GuitarAlchemist/ga/blob/05c8eda013f2a4d11efaa52c4ca94674521ee684/ReactComponents/ga-react-components/src/components/ThreeFretboard.tsx), su mástil de guitarra en 3D. Los componentes React de GA piden three.js 0.180, seis versiones por detrás de este curso. Las lecciones citan el código de GA donde ilustra bien un punto, incluido lo que cambió desde r180; los hallazgos están en el [diario](journal/).

## Demos en vivo

Cada página de lección funciona en este sitio, en un marco plegado bajo su captura, con un panel *Try it* que fija los parámetros de la página, los que usan los ejercicios. Cinco escenas completas reúnen las lecciones sobre una guitarra entera modelada en código: una [guitarra para tocar](../../threejs-demos/demos/guitar.html) (lección 5), [voicings de acordes](../../threejs-demos/demos/voicing.html) en el diapasón de GA (lección 13), un [estudio](../../threejs-demos/demos/studio.html) con sombras, entorno HDR y bloom (lección 7), [púas lanzadas sobre la guitarra](../../threejs-demos/demos/physics.html) con Rapier (lección 10) y la [guitarra en VR](../../threejs-demos/demos/xr.html?emulate) (lección 11). Un marco no carga nada hasta que se despliega. El build entero pesa 9.4 MB, sobre todo los dos builds de Rapier en WebAssembly.

## Al final de este curso, sabré

- configurar un proyecto three.js con Vite y TypeScript, y explicar qué hace `WebGPURenderer` cuando falta WebGPU;
- construir escenas con geometrías, materiales basados en la física y luces, con sombras, y leer `renderer.info` para saber qué se le pidió a la GPU;
- mantener los colores correctos de la textura a la pantalla: espacios de color, tone mapping y entornos HDR;
- cargar modelos glTF con sus animaciones, y elegir entre la compresión Draco, meshopt y KTX2;
- seleccionar objetos y mover la cámara, escribir materiales y efectos en TSL, y aplicar posprocesado a una escena;
- dibujar miles de objetos con instancing, `BatchedMesh` y niveles de detalle, y medir el resultado;
- escribir las mismas escenas con React Three Fiber, añadir física con Rapier y un modo WebXR;
- probar código 3D en CI, y saber qué puede y qué no puede verificar un navegador headless sin GPU.

## Plan

| # | Lección | Ya conoces |
|---|---|---|
| 1 | [Escena, cámara, renderer](01-scene-camera-renderer/) | `Viewport3D` y `PerspectiveCamera` de WPF, el bucle `Game` de MonoGame, `SubScene` de JavaFX |
| 2 | [Geometrías, materiales, luces y sombras](02-geometries-materials-lights/) | `MeshGeometry3D`, `DiffuseMaterial`, `BasicEffect`, luces direccionales y puntuales |
| 3 | [Color, tone mapping y entornos HDR](03-color-tone-mapping-environments/) | sRGB, `Color` en WPF o JavaFX, fotos HDR |
| 4 | [Cargar modelos glTF y animaciones](04-gltf-models-and-animations/) | el content pipeline de MonoGame, los storyboards de WPF, `AnimationTimer` |
| 5 | [Interacción, `Raycaster` y controles de cámara](05-interaction-raycaster-controls/) | hit testing en WPF, `VisualTreeHelper.HitTest`, `PickResult` de JavaFX |
| 6 | [TSL y materiales de nodos](06-tsl-node-materials/) | efectos HLSL, grafos de shaders |
| 7 | [Posprocesado con `RenderPipeline`](07-post-processing-renderpipeline/) | render targets, pixel shaders |
| 8 | [Rendimiento, medido: instancing, `BatchedMesh`, LOD, frustum culling](08-performance-instancing-batching-lod/) | dibujo instanciado, profilers |
| 9 | [React Three Fiber y drei](09-react-three-fiber-drei/) | data binding de WPF, componentes Blazor o React |
| 10 | [Física con Rapier en WebAssembly](10-physics-rapier-wasm/) | BEPUphysics, motores de física en juegos |
| 11 | [WebXR](11-webxr/) | Windows Mixed Reality, OpenXR |
| 12 | [Pruebas y CI: renderizado headless, capturas de pantalla comparadas, y sus límites](12-tests-and-ci/) | automatización de UI, pruebas de snapshot |
| 13 | [Proyecto: el mástil de guitarra 3D de GuitarAlchemist, portado a WebGPU](13-project-ga-fretboard/) | las lecciones anteriores |
| 14 | [Laboratorio: Guitar Alchemist en 3D, quince experimentos medidos](14-guitar-alchemist-lab/) | las lecciones 8, 9, 10, 11 y 13 |
| — | [Diario](journal/) | |

El curso está completo: las 13 lecciones se escribieron y comprobaron el 16 de septiembre de 2026. La lección 14, un laboratorio de quince experimentos medidos sobre las necesidades 3D de Guitar Alchemist, se añadió el 17 de septiembre. Lo que queda por probar en hardware real, un casco de realidad virtual, un teléfono, WebGPU en Linux, figura en el diario.

## Recursos

- [Manual de three.js](https://threejs.org/manual/), [documentación](https://threejs.org/docs/), [ejemplos](https://threejs.org/examples/) y la [guía de migración](https://github.com/mrdoob/three.js/wiki/Migration-Guide)
- [WebGPURenderer](https://threejs.org/manual/pages/webgpurenderer.html) en el manual, y la [documentación de TSL](https://threejs.org/docs/pages/TSL.html)
- El código fuente en la etiqueta de la versión: [mrdoob/three.js@r186](https://github.com/mrdoob/three.js/tree/r186)
- Especificaciones de [WebGPU](https://gpuweb.github.io/gpuweb/) y [WGSL](https://gpuweb.github.io/gpuweb/wgsl/), W3C
- [Especificación de glTF 2.0](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html), Khronos
- [React Three Fiber](https://r3f.docs.pmnd.rs/) y [drei](https://drei.docs.pmnd.rs/)
- [Guía de JavaScript de Rapier](https://rapier.rs/docs/user_guides/javascript/getting_started_js/)
- [WebXR Device API](https://www.w3.org/TR/webxr/), W3C, y el [Immersive Web Emulation Runtime](https://github.com/meta-quest/immersive-web-emulation-runtime) de Meta
