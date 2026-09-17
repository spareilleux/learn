---
title: three.js pour développeurs C#/Java — Mission
description: La 3D temps réel dans le navigateur avec three.js r186, WebGPURenderer et son repli sur WebGL 2, les matériaux à nœuds TSL, glTF et React Three Fiber, pour les développeurs qui connaissent C# ou Java et TypeScript — chaque scène est mesurée dans Chromium headless et chaque nombre est comparé en CI sous Windows, Linux et macOS.
sidebar:
  label: Mission
  order: 0
---

:::note[Version étudiée]
[three.js](https://threejs.org/) **r186** (le paquet npm `three` 0.186.0, publié le 8 septembre 2026), avec [`@types/three`](https://www.npmjs.com/package/@types/three) 0.186.0, servi et construit par [Vite](https://vite.dev/) 8.3.0, vérifié avec [TypeScript](https://www.typescriptlang.org/) 7.0.2, et mesuré dans Chromium headless avec [Playwright](https://playwright.dev/) 1.63.0 sur [Node.js](https://nodejs.org/) 24. Les scènes et les scripts du cours se trouvent dans [`code/threejs`](https://github.com/spareilleux/learn/tree/eeca669/code/threejs), avec un `package.json` et un fichier de verrouillage qui fixent aussi [glTF Transform](https://gltf-transform.dev/) 4.5.0, et pour les leçons 9 à 13 [React](https://react.dev/) 19.2.8, [React Three Fiber](https://r3f.docs.pmnd.rs/) 9.7.0, [drei](https://drei.docs.pmnd.rs/) 10.7.8, [Rapier](https://rapier.rs/) 0.20.0, [IWER](https://github.com/meta-quest/immersive-web-emulation-runtime) 2.4.0, [Vitest](https://vitest.dev/) 5.0.1 et [pixelmatch](https://github.com/mapbox/pixelmatch) 7.2.0. [`.github/workflows/threejs-examples.yml`](https://github.com/spareilleux/learn/blob/eeca669/.github/workflows/threejs-examples.yml) exécute [`check.sh`](https://github.com/spareilleux/learn/blob/eeca669/code/threejs/check.sh) sous Linux, Windows et macOS : il vérifie les types de tout le code, exécute les scripts Node.js et les tests de composants, ouvre chaque page de leçon dans Chromium headless, construit les pages, et compare les sorties avec celles collées dans les leçons.
:::

## Pourquoi j'apprends ça

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) dessine en 3D un manche de guitare, un océan, un système solaire et quelques dizaines d'autres scènes avec three.js. Certaines utilisent le nouveau `WebGPURenderer` et son langage de shaders, TSL ; la plupart utilisent encore `WebGLRenderer` et du GLSL écrit à la main. En développeur C#, je connais le `Viewport3D` de WPF et un peu MonoGame. three.js ressemble aux deux au premier abord : un graphe de scène, une caméra, des maillages et des lumières. Puis les détails divergent : le renderer peut choisir WebGPU ou WebGL dans mon dos, une couleur hexadécimale n'est pas le nombre que reçoit le shader, l'intensité d'une lumière s'exprime en candelas, et un modèle arrive sous forme de fichier glTF qui a besoin de ses propres décodeurs.

Ce cours apprend three.js tel qu'il est en septembre 2026, et non tel que le montrent la plupart des tutoriels : `WebGPURenderer` d'abord, `setAnimationLoop` au lieu de `requestAnimationFrame`, TSL au lieu de `ShaderMaterial`, les imports `three/addons`, `Timer` au lieu de `Clock`, `HDRLoader` au lieu de `RGBELoader`.

## À qui s'adresse ce cours

Tu es à l'aise avec C# ou Java, et tu as suivi [JavaScript pour développeurs C#/Java](../javascript-for-csharp-java/) et [TypeScript pour développeurs C#/Java](../typescript-for-csharp-java/), ou tu connais leur contenu : modules ES et npm, `async` et `await`, classes, types structurels. La leçon 9 utilise React ; le [cours React (Vite)](../react-vite/) couvre ce dont elle a besoin. Aucune expérience préalable de la 3D n'est nécessaire, mais si tu as utilisé [WPF 3D](https://learn.microsoft.com/dotnet/desktop/wpf/graphics-multimedia/3-d-graphics-overview), [MonoGame](https://monogame.net/) ou [JavaFX 3D](https://openjfx.io/javadoc/25/javafx.graphics/javafx/scene/SubScene.html), chaque leçon dit ce qui s'y transpose.

## three.js en un tableau

| | WPF 3D | MonoGame | JavaFX 3D | three.js |
|---|---|---|---|---|
| Où il dessine | un élément `Viewport3D` | la fenêtre du jeu | une `SubScene` | un `<canvas>` créé par le renderer |
| Graphe de scène | `ModelVisual3D`, `Model3DGroup` | aucun : on dessine chaque modèle | `Group`, `MeshView` | `Scene`, `Group`, `Mesh` |
| Axes | main droite, Y vers le haut | matrices main droite, Y vers le haut | Y vers le bas | main droite, Y vers le haut |
| Géométrie | `MeshGeometry3D` | tampons de sommets et d'indices | `TriangleMesh` | `BufferGeometry` |
| Matériaux | `DiffuseMaterial`, `SpecularMaterial` | `BasicEffect`, effets personnalisés | `PhongMaterial` | à base physique : `MeshStandardMaterial`, matériaux à nœuds |
| La boucle | en mode retenu : WPF redessine quand quelque chose change | `Update` et `Draw`, appelées par `Game` | `AnimationTimer` | `renderer.setAnimationLoop(callback)` |
| API GPU | Direct3D 9 | DirectX ou OpenGL | Direct3D ou OpenGL, via Prism | WebGPU, ou WebGL 2 en repli |
| Shaders | aucun | effets HLSL | aucun | TSL, compilé en WGSL ou en GLSL |
| Fichiers de modèles | rien d'intégré | le content pipeline (FBX, X) | rien d'intégré | glTF 2.0 avec `GLTFLoader` |

## Les données

Les scènes propres au cours sont petites et déterministes : un cube, un morceau de manche de guitare fait de primitives, des pastilles de couleur, dix sphères dans un studio HDR, et un métronome écrit en fichier glTF par un script. Chaque page rapporte ce que le renderer a fait, et un script Playwright le lit, si bien que les nombres des leçons viennent d'une exécution, pas de la mémoire.

Le vrai code est [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) au commit [`05c8eda`](https://github.com/GuitarAlchemist/ga/commit/05c8eda013f2a4d11efaa52c4ca94674521ee684), principalement [`ThreeFretboard.tsx`](https://github.com/GuitarAlchemist/ga/blob/05c8eda013f2a4d11efaa52c4ca94674521ee684/ReactComponents/ga-react-components/src/components/ThreeFretboard.tsx), son manche de guitare en 3D. Les composants React de GA demandent three.js 0.180, six versions derrière ce cours. Les leçons citent le code de GA là où il illustre bien un point, y compris ce qui a changé depuis r180 ; les constats sont dans le [journal](journal/).

## Démos en direct

Chaque page de leçon tourne sur ce site, dans un cadre replié sous sa capture, avec un panneau *Try it* qui règle les paramètres de la page, ceux qu'utilisent les exercices. Cinq scènes complètes réunissent les leçons sur une guitare entière modélisée en code : une [guitare à jouer](../../threejs-demos/demos/guitar.html) (leçon 5), des [voicings d'accords](../../threejs-demos/demos/voicing.html) sur la touche de GA (leçon 13), un [studio](../../threejs-demos/demos/studio.html) avec ombres, environnement HDR et bloom (leçon 7), des [médiators lancés sur la guitare](../../threejs-demos/demos/physics.html) avec Rapier (leçon 10), et la [guitare en VR](../../threejs-demos/demos/xr.html?emulate) (leçon 11). Un cadre ne charge rien tant qu'il n'est pas déplié. Le build entier pèse 9.4 Mo, surtout les deux builds de Rapier en WebAssembly.

## À la fin de ce cours, je saurai

- mettre en place un projet three.js avec Vite et TypeScript, et expliquer ce que fait `WebGPURenderer` quand WebGPU manque ;
- construire des scènes à partir de géométries, de matériaux à base physique et de lumières, avec des ombres, et lire `renderer.info` pour savoir ce qui a été demandé au GPU ;
- garder des couleurs justes de la texture à l'écran : espaces colorimétriques, tone mapping et environnements HDR ;
- charger des modèles glTF avec leurs animations, et choisir entre les compressions Draco, meshopt et KTX2 ;
- sélectionner des objets et déplacer la caméra, écrire des matériaux et des effets en TSL, et post-traiter une scène ;
- dessiner des milliers d'objets avec l'instanciation, `BatchedMesh` et les niveaux de détail, et mesurer le résultat ;
- écrire les mêmes scènes avec React Three Fiber, ajouter de la physique avec Rapier et un mode WebXR ;
- tester du code 3D en CI, et savoir ce qu'un navigateur headless sans GPU peut vérifier et ce qu'il ne peut pas vérifier.

## Plan

| # | Leçon | Ce que tu connais déjà |
|---|---|---|
| 1 | [Scène, caméra, renderer](01-scene-camera-renderer/) | le `Viewport3D` et la `PerspectiveCamera` de WPF, la boucle `Game` de MonoGame, la `SubScene` de JavaFX |
| 2 | [Géométries, matériaux, lumières et ombres](02-geometries-materials-lights/) | `MeshGeometry3D`, `DiffuseMaterial`, `BasicEffect`, lumières directionnelles et ponctuelles |
| 3 | [Couleur, tone mapping et environnements HDR](03-color-tone-mapping-environments/) | sRGB, `Color` dans WPF ou JavaFX, photos HDR |
| 4 | [Charger des modèles glTF et des animations](04-gltf-models-and-animations/) | le content pipeline de MonoGame, les storyboards WPF, `AnimationTimer` |
| 5 | [Interaction, `Raycaster` et contrôles de caméra](05-interaction-raycaster-controls/) | le hit testing dans WPF, `VisualTreeHelper.HitTest`, le `PickResult` de JavaFX |
| 6 | [TSL et matériaux à nœuds](06-tsl-node-materials/) | effets HLSL, graphes de shaders |
| 7 | [Post-traitement avec `RenderPipeline`](07-post-processing-renderpipeline/) | render targets, pixel shaders |
| 8 | [La performance, mesurée : instanciation, `BatchedMesh`, LOD, frustum culling](08-performance-instancing-batching-lod/) | dessin instancié, profileurs |
| 9 | [React Three Fiber et drei](09-react-three-fiber-drei/) | le data binding de WPF, composants Blazor ou React |
| 10 | [Physique avec Rapier en WebAssembly](10-physics-rapier-wasm/) | BEPUphysics, moteurs physiques de jeux |
| 11 | [WebXR](11-webxr/) | Windows Mixed Reality, OpenXR |
| 12 | [Tests et CI : rendu headless, captures d'écran comparées, et leurs limites](12-tests-and-ci/) | automatisation d'interface, tests de snapshot |
| 13 | [Projet : le manche de guitare 3D de GuitarAlchemist, porté vers WebGPU](13-project-ga-fretboard/) | les leçons qui la précèdent |
| — | [Journal](journal/) | |

Le cours est terminé : les 13 leçons ont été écrites et vérifiées le 16 septembre 2026. Ce qui reste à essayer sur du vrai matériel, un casque de réalité virtuelle, un téléphone, WebGPU sous Linux, est listé dans le journal.

## Ressources

- Le [manuel de three.js](https://threejs.org/manual/), sa [documentation](https://threejs.org/docs/), ses [exemples](https://threejs.org/examples/), et le [guide de migration](https://github.com/mrdoob/three.js/wiki/Migration-Guide)
- [WebGPURenderer](https://threejs.org/manual/pages/webgpurenderer.html) dans le manuel, et la [documentation de TSL](https://threejs.org/docs/pages/TSL.html)
- Le code source au tag de version : [mrdoob/three.js@r186](https://github.com/mrdoob/three.js/tree/r186)
- Spécifications de [WebGPU](https://gpuweb.github.io/gpuweb/) et de [WGSL](https://gpuweb.github.io/gpuweb/wgsl/), W3C
- [Spécification glTF 2.0](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html), Khronos
- [React Three Fiber](https://r3f.docs.pmnd.rs/) et [drei](https://drei.docs.pmnd.rs/)
- [Le guide JavaScript de Rapier](https://rapier.rs/docs/user_guides/javascript/getting_started_js/)
- [WebXR Device API](https://www.w3.org/TR/webxr/), W3C, et l'[Immersive Web Emulation Runtime](https://github.com/meta-quest/immersive-web-emulation-runtime) de Meta
