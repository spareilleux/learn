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
- [ ] Leçon 5 : interaction, `Raycaster` et contrôles de caméra

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
- Pour les leçons suivantes : `Ocean.tsx` utilise `PostProcessing`, renommé `RenderPipeline` dans r183 ; 16 fichiers utilisent `ShaderMaterial` ou du GLSL, et 10 utilisent `EffectComposer`, que `WebGPURenderer` ne prend pas en charge ; `Experiments/ThreeJS-BSP-Loader` importe `WebGPURenderer` depuis un chemin supprimé dans r167 ; le visualiseur d'embeddings du tableau de bord retire un écouteur de redimensionnement avec un nouveau `bind`, ce qui ne retire rien.

## À vérifier

- Si une scène modélisée en centimètres a besoin de lumières 10 000 fois plus fortes pour avoir le même aspect qu'en mètres (leçon 2).
- Les textures KTX2 : chargement, formats GPU choisis sur chaque OS, mémoire (leçon 8).
- Draco face à meshopt sur un gros modèle et sur de nombreux petits, sur un vrai réseau (leçon 4, exercice 3).
- WebGPU sur une machine Linux ou Windows dotée d'un GPU, autre que celle de l'auteur.
