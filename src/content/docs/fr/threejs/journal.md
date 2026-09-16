---
title: Journal
description: Notes d'avancement datées du cours three.js — l'épinglage de three.js r186, Vite 8.3 et Playwright 1.63, la mesure de pages WebGPU dans Chromium headless sur trois OS, ce avec quoi les runners de CI dessinent vraiment, des surprises dans @types/three et DRACOLoader, ce que le cours a trouvé dans le code 3D de GuitarAlchemist/ga, et les points à vérifier.
sidebar:
  order: 99
---

## Avancement

- [x] three 0.186.0, `@types/three` 0.186.0, Vite 8.3.0, TypeScript 7.0.2, Playwright 1.63.0 et glTF Transform 4.5.0 épinglés dans le `package.json` et le fichier de verrouillage propres au cours
- [x] `check.sh` : la vérification des types, les scripts Node.js, chaque page de leçon sondée dans Chromium headless, le build de production, comparés à `expected/`
- [x] CI sur Ubuntu, Windows et macOS
- [x] Leçon 1 : scène, caméra, moteur de rendu
- [x] Leçon 2 : géométries, matériaux, lumières et ombres
- [x] Leçon 3 : couleur, tone mapping et environnements HDR
- [x] Leçon 4 : modèles glTF et animations
- [x] Leçon 5 : interaction, `Raycaster` et contrôles de caméra
- [x] Leçon 6 : TSL et matériaux à nœuds
- [x] Leçon 7 : post-traitement avec `RenderPipeline`
- [x] Leçon 8 : la performance, mesurée
- [ ] Leçon 9 : React Three Fiber et drei

## 2026-09-16 — Versions

- `npm view three` donne 0.186.0, publiée le 8 septembre 2026, et `@types/three` 0.186.0. Le cours les épingle exactement dans [`code/threejs/package.json`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/package.json), avec Vite 8.3.0, TypeScript 7.0.2, Playwright 1.63.0 et son Chromium 153, glTF Transform 4.5.0, `draco3dgltf` 1.5.7, `meshoptimizer` 1.2.0 et `pngjs` 7.0.0, sur Node.js 24.21.0 en CI.
- La release r186 correspond à la version npm `0.186.0`. Les leçons citent le code source au tag `r186` de [mrdoob/three.js](https://github.com/mrdoob/three.js/tree/r186).
- `require('three/package.json')` échoue : la table `exports` du paquet ne le liste pas. La vérification de version dans `check.sh` lit donc le fichier avec `fs`.
- Les pages de documentation sont à `https://threejs.org/docs/pages/<Class>.html` et `https://threejs.org/manual/pages/<page>.html` ; les leçons pointent vers ces URL, toutes vérifiées.

## 2026-09-16 — Mesurer des pages dans un navigateur headless

- Chaque page de leçon rapporte ce qu'a fait le moteur de rendu à travers une promesse `window.probe`, et [`scripts/probe.mjs`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/scripts/probe.mjs) démarre Vite, ouvre la page avec Playwright en 800 par 450 pixels avec un pixel ratio de 1, et affiche le rapport. Les pages animées avancent par pas fixes quand elles sont sondées, si bien que la troisième image est la même sur toutes les machines.
- Ma première sonde restait bloquée sur la page `WebGLRenderer` : la page remplaçait `window.probe` après que `page.evaluate` avait commencé à attendre l'ancienne promesse. Les pages résolvent désormais une promesse créée une seule fois, dans [`src/probe.ts`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/src/probe.ts), et `probe.mjs` abandonne au bout de 30 secondes.
- Les couleurs sont lues dans la capture d'écran, aux positions que la page indique.
- Le mode headless par défaut de Playwright, sous Windows, donne WebGPU sur la RTX 5080 de l'auteur (« nvidia, blackwell »). `chromium-headless-shell`, la version allégée, n'a pas d'adaptateur WebGPU : `WebGPURenderer` se replie sur WebGL 2, avec SwiftShader. `check.sh` exécute la leçon 1 dans les deux.

## 2026-09-16 — Ce avec quoi les runners de CI dessinent

- La première exécution de la CI, [35114590607](https://github.com/spareilleux/learn/actions/runs/35114590607), a échoué sur les trois OS, pour trois raisons : le `coordinateSystem` rapporté par la page dépend du backend ; quelques couleurs diffèrent d'une unité par rapport au GPU de l'auteur ; et sous macOS, l'avertissement de Vite, sur stderr, arrivait avant ses lignes sur stdout. Les sondes filtrent maintenant les lignes qui dépendent du backend, [`compare.mjs`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/scripts/compare.mjs) accepte un écart de 2 par canal dans les couleurs, et le stderr du build est affiché après son stdout.
- L'exécution [35115118564](https://github.com/spareilleux/learn/actions/runs/35115118564) est passée. Ses logs montrent avec quoi dessine chaque runner. `ubuntu-24.04` et `windows-2025-vs2026` n'ont pas de GPU : WebGPU n'est pas disponible, et `WebGPURenderer` comme `forceWebGL` tournent en WebGL 2 sur SwiftShader (Subzero). `macos-26-arm64` a WebGPU, sur un adaptateur « apple », et WebGL 2 sur « ANGLE Metal Renderer: Apple Paravirtual device » ; son headless shell utilise SwiftShader (LLVM 10.0.0).
- Deux couleurs diffèrent d'une unité sur les runners : ACES transforme le linéaire 0.18 en 127 sur le GPU de l'auteur et en 128 en CI, et Neutral transforme 0.05 en 33 et en 34.
- Une CI au vert prouve donc que les scènes se construisent, se chargent, et produisent les mêmes compteurs et les mêmes couleurs, à 2 près, sur un rastériseur logiciel et sur le GPU d'Apple. Elle ne prouve rien sur WebGPU sous Windows ou Linux.

## 2026-09-16 — Surprises

- **`WebGPURenderer` compte un draw call de plus que la scène n'en a.** Avec du tone mapping, ou avec un espace colorimétrique de sortie différent de l'espace de travail, il rend la scène dans une cible et dessine le résultat dans une passe de sortie : 2 draw calls et 13 triangles pour un cube. `WebGLRenderer` convertit dans chaque shader et rapporte 1. Les objets `info` des deux moteurs de rendu n'ont pas non plus la même forme.
- **`@types/three` décrit mal `toJSON()`.** Dans 0.186.0, `Object3DJSON` déclare `children` comme des chaînes et n'a ni `geometries` ni `materials`, alors que l'exécution écrit des objets et les deux tableaux. La leçon 1 conserve les erreurs du compilateur dans [`errors/l01_tojson_types.ts`](https://github.com/spareilleux/learn/blob/8e8f303/code/threejs/errors/l01_tojson_types.ts). Je n'ai pas cherché d'issue existante dans three-types/three-ts-types, et je n'en ai pas ouvert.
- **La boîte de la caméra d'ombre n'est lue qu'une fois par `WebGPURenderer`.** `ShadowNode` appelle `updateProjectionMatrix()` quand il construit l'ombre ; un changement ultérieur demande votre propre appel.
- **`PCFSoftShadowMap` a disparu de `WebGPURenderer` dans r186** et produit un avertissement. `LunarLanderEngine.ts` et `MinimalThreeInstrument.tsx` de GA l'utilisent encore avec `WebGPURenderer`.
- **Une lumière ponctuelle de 800 lumens fait 63.66 candelas, et un spot de 800 lumens 254.65** : `SpotLight.power` utilise π, pas 4π, et ne change pas avec l'angle du cône.
- **La PMREM coûte 17 rendus** pour un environnement de 256 par 128 : 1 dans le premier niveau, puis 2 pour chacun des 8 autres. Elle a lieu même quand `scene.environment` est une simple texture équirectangulaire.
- **Depuis r185, `DRACOLoader` trouve ses décodeurs avec `import.meta.url`**, ce que r184 ne faisait pas. Vite copie alors les cinq fichiers de décodeur dans le build, 1.31 MB, alors qu'un navigateur en charge deux. Le build avertit aussi que `three.webgpu` dépasse 500 kB.
- **Draco et meshopt éliminent des sommets.** Tous deux éliminent les deux sommets de pôle que `SphereGeometry` crée et qu'aucun triangle n'utilise ; le `weld()` de Draco fusionne en plus les coins du corps non indexé.
- Le `meshopt()` de glTF Transform affiche des lignes `prune: Removed types... Accessor` sur stdout ; elles figurent telles quelles dans `expected/`.

## 2026-09-16 — GuitarAlchemist/ga

Le cours lit GA au commit [`05c8eda`](https://github.com/GuitarAlchemist/ga/tree/05c8eda013f2a4d11efaa52c4ca94674521ee684), qui utilise three 0.180. 139 fichiers sous des répertoires `src` importent three ; 33 d'entre eux appellent `requestAnimationFrame`, 3 `setAnimationLoop` ; 29 créent un `WebGLRenderer` et 8 un `WebGPURenderer` ; 15 utilisent `Clock`, déprécié dans r183. Rien de ce qui suit n'a été signalé à GA.

- `ThreeFretboard.tsx` s'attend à ce que `WebGPURenderer` lève une exception quand WebGPU manque, et affiche « Using WebGPU renderer » sur toutes les machines, puisque le moteur de rendu se replie plutôt sur WebGL 2 (leçon 1). Ses ombres ne sont activées que pour un `WebGLRenderer`, donc le chemin de repli n'en a aucune (leçon 2).
- `ThreeFretboard.tsx` demande `samples: 8` ; la spécification WebGPU autorise 1 ou 4 échantillons pour une texture. Ce que fait r180 avec 8 sur chaque backend est *à vérifier*.
- Sa lumière ponctuelle de 0.6 cd avec `distance: 20` donne environ 5 % de la lumière principale là où elle est le plus proche du manche (leçon 2), et une seule texture de canvas sert de carte de couleur, de rugosité, de normales et de relief.
- Sa texture de bois n'a pas de `colorSpace`, elle s'affiche donc plus claire que peinte, et son environnement est un dégradé sur 8 bits dont le moteur de rendu construit quand même la PMREM (leçon 3). L'écart de couleur du bois à l'écran est *à vérifier* dans un navigateur.
- `Guitar3D.tsx` construit un environnement noir avec `fromScene` sur une scène qui ne contient qu'une lumière ambiante, et annonce la prise en charge de KTX2 et de meshopt sans régler aucun des deux décodeurs (leçons 3 et 4).
- `Ocean.tsx` charge les décodeurs de Draco depuis gstatic.com ; `DemerzelFaceOverlay.tsx` masque les erreurs KTX2 en remplaçant `console.error` pendant un chargement ; `HandAnimationTest.tsx` met à jour un `AnimationMixer` qui n'a aucune action (leçon 4).
- `Experiments/ThreeJS-BSP-Loader` importe `WebGPURenderer` depuis un chemin supprimé dans r167 ; le visualiseur d'embeddings du tableau de bord retire un écouteur de redimensionnement avec un nouveau `bind`, ce qui ne retire rien.
- `ThreeHeadstock.tsx` ajoute un écouteur de clic au même canvas à chaque exécution de son effet et ne le retire jamais ; `TonalOrbit.tsx` et `MinimalThreeInstrument.tsx` lancent un rayon à chaque événement de souris, le second avec un nouveau `Raycaster` à chaque fois ; `InteractionHandler.ts`, dans Prime Radiant, le fait comme la leçon ; 4 des 25 fichiers qui utilisent `OrbitControls` ne les libèrent jamais (leçon 5).
- Le ciel GLSL de `Sunburst3D.tsx`, copié dans `ImmersiveMusicalWorld.tsx`, ne peut pas tourner sur `WebGPURenderer` ; `FresnelGlowTSL.ts` fige l'intensité et la couleur de sa couronne dans le shader sous forme de constantes ; `MoebiusPassTSL.ts` est un `ShaderPass` GLSL malgré son nom (leçon 6).
- `Ocean.tsx` et `LunarLanderEngine.ts` utilisent `PostProcessing`, renommé `RenderPipeline` dans r183, et `Ocean.tsx` ne libère jamais le pipeline ni ses nœuds ; `ForceRadiant.tsx` tourne sur `WebGPURenderer` sans les effets de bloom et de `ShaderPass` de son chemin WebGL, une « tâche de suivi » ; les 10 fichiers qui utilisent `EffectComposer` s'en servent correctement pour WebGL (leçon 7).
- `ThreeFretboard.tsx` crée une géométrie et un matériau par frette et par repère, reconstruit sa scène chaque fois que sa prop `positions` est un nouveau tableau, y compris le `[]` par défaut, et ne libère pas ses 29 sprites ; `NodeInstancer.ts` instancie bien ses nœuds, avec le culling désactivé ; GA n'utilise ni `BatchedMesh` ni `THREE.LOD` (leçon 8).

## 2026-09-16 — Leçons 5 à 8 : pointeurs, shaders, effets, comptes

- **De vrais événements de pointeur dans une page headless.** [`scripts/probe.mjs`](https://github.com/spareilleux/learn/blob/8bf126b/code/threejs/scripts/probe.mjs) effectue maintenant les déplacements et les glisser-déposer qu'une page liste, avec la souris de Playwright, et demande à la page ce qu'elle a vu après chacun. Chromium les transforme en événements `pointermove`, `pointerdown` et `pointerup`, que `OrbitControls` traite comme ceux d'un utilisateur : un glisser de 120 pixels a tourné la caméra de 96°.
- **Une caméra hors de la scène a une matrice périmée dans un script.** La première version de `l05-raycaster.ts` projetait un point à un NDC de −3.6 : le rendu met à jour la matrice monde de la caméra, et un script Node.js ne fait pas de rendu. `camera.updateMatrixWorld()` l'a corrigé.
- **Une feuille de style partagée fait partie du hash de chaque chunk.** Ajouter les règles de mise en page de la leçon 5 à `page.css` a changé le nom de tous les chunks du build, y compris le `04-gltf-CCDSPzCq.js` que cite la leçon 4. La leçon 5 a reçu sa propre feuille de style, et `check.sh` construit d'abord les pages des leçons 1 à 4 seules, avec un filtre `PAGES`, avant de tout construire : avec les pages des leçons 5 à 8, Rolldown nomme le chunk WebGPU partagé `three.tsl` au lieu de `three.webgpu`.
- **`PostProcessing` s'appelle `RenderPipeline` depuis r183, et `pipeline.dispose()` libère un seul matériau.** Les 11 render targets du bloom et celui de la passe de scène restent jusqu'à ce que les nœuds eux-mêmes soient libérés.
- **`DirectRenderPipeline.render` prend la scène et la caméra**, contrairement à `RenderPipeline.render()`, donc TypeScript le refuse dans une variable `RenderPipeline` ; et il dessine un fond uni sous la forme d'une sphère de 1 984 triangles.
- **`renderer.info.render` s'additionne entre les appels à `render()` d'une même image d'animation.** Une page qui rendait 60 images dans une boucle pour les chronométrer rapportait 610 061 draw calls ; la leçon 8 lit d'abord les comptes.

## 2026-09-16 — Les runners de CI et les leçons 5 à 8

- L'exécution [35123228046](https://github.com/spareilleux/learn/actions/runs/35123228046) a réussi sous macOS (WebGPU sur l'adaptateur « apple ») et échoué sous Linux et Windows, où `WebGPURenderer` se replie sur WebGL 2 avec SwiftShader. Quatre différences, toutes réelles :
  - Les chaînes de bloom comptent un programme de plus sur WebGL 2 : 14 au lieu de 13, 16 au lieu de 15.
  - Avec FXAA, le pixel du halo vaut 135, 176, 197 sur SwiftShader, là où le GPU de l'auteur donne 132, 174, 195 sur les deux backends : 3 de plus que ce qu'accepte `compare.mjs`.
  - Un `BatchedMesh` est dessiné avec `WEBGL_multi_draw` et compté comme 2 draw calls, pas 10 001.
  - Le fichier de shader WebGPU contient du GLSL, puisque la page tournait sur WebGL 2.
- Les pages de la leçon 8 à 800 000 triangles dépassaient le délai : le résultat de la sonde arrivait, mais la capture d'écran de Playwright attendait plus de 30 secondes derrière les 60 images chronométrées encore en file dans le rasteriseur logiciel.
- La correction : `check.sh` compare une sonde avec `expected/<name>.webgl.txt` quand ce fichier existe et que la page a tourné sur WebGL 2. Les cinq fichiers viennent de `chromium-headless-shell` sur la machine de l'auteur, dont le SwiftShader a donné les mêmes valeurs que les runners. La ligne GLSL est comparée, et la ligne WGSL seulement affichée. La leçon 8 chronomètre 20 images, et ses sondes attendent jusqu'à 240 secondes (`PROBE_TIMEOUT`). L'exécution [35124756498](https://github.com/spareilleux/learn/actions/runs/35124756498) a réussi sur les trois OS.

## À vérifier

- Si une scène modélisée en centimètres a besoin de lumières 10 000 fois plus fortes pour avoir le même aspect qu'en mètres (leçon 2).
- Les textures KTX2 : chargement, formats GPU choisis sur chaque OS, mémoire.
- Si `ThreeHeadstock.tsx` appelle `onTuningPegClick` une fois par écouteur périmé après les nouvelles exécutions de son effet (leçon 5).
- Si `ThreeFretboard.tsx` est reconstruit à chaque rendu de ses parents dans les pages de GA (leçon 8).
- Le temps GPU, pas seulement le temps CPU, avec le `timestamp-query` de WebGPU (leçon 8).
- Draco face à meshopt sur un gros modèle et sur de nombreux petits, sur un vrai réseau (leçon 4, exercice 3).
- WebGPU sur une machine Linux ou Windows dotée d'un GPU, autre que celle de l'auteur.
