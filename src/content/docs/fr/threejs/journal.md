---
title: Journal
description: Notes d'avancement datées du cours three.js — l'épinglage de three.js r186, Vite 8.3, Playwright 1.63, React Three Fiber 9, Rapier 0.20 et IWER, la mesure de pages WebGPU dans Chromium headless sur trois OS, ce avec quoi les runners de CI dessinent vraiment, des surprises dans @types/three et DRACOLoader, ce que le cours a trouvé dans le code 3D de GuitarAlchemist/ga, et les points à vérifier.
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
- [x] Leçon 9 : React Three Fiber et drei
- [x] Leçon 10 : physique avec Rapier en WebAssembly
- [x] Leçon 11 : WebXR, émulé
- [x] Leçon 12 : tests et CI
- [x] Leçon 13 : projet, le manche de guitare 3D de GuitarAlchemist
- [x] Leçon 14 : labo, Guitar Alchemist en 3D, quinze expériences mesurées
- [x] Cours terminé
- [x] Démos en direct : chaque page de leçon et cinq scènes complètes, publiées sous le site avec un panneau *Try it*

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

## 2026-09-16 — Leçons 9 à 13 : versions

- React 19.3.0 est sorti le 9 septembre 2026, mais `@react-three/fiber` 9.7.0 déclare `react` `>=19 <19.3` : le cours épingle React 19.2.8, avec drei 10.7.8. R3F 10 et drei 11 sont en alpha. `@react-three/test-renderer` 9.1.1 et Vitest 5.0.1 testent les composants.
- Rapier 0.20.0 a été publié le 8 août 2026. L'addon `RapierPhysics` de three.js r186 charge encore la 0.17.3 depuis skypack.dev, et `@react-three/rapier` 2.2.0 épingle la 0.19.2. Le cours utilise à la fois `@dimforge/rapier3d-compat` et `@dimforge/rapier3d-deterministic-compat` ; leurs classes ont des membres privés, donc TypeScript refuse le type d'un module pour l'autre sans cast.
- IWER 2.4.0 émule un Quest 3 ; pixelmatch 7.2.0 compare les captures d'écran.

## 2026-09-16 — Leçons 9 à 13 : ce qu'ont trouvé les pages

- **R3F 9.7.0 émet un avertissement sur `WebGPURenderer` sans qu'on lui demande rien.** Le `shadows` de `<Canvas>` vaut `false` par défaut, et R3F règle `PCFSoftShadowMap` pour tout booléen ; `WebGPURenderer` le réinitialise avec un avertissement, une fois par rendu de `<Canvas>`. Son store crée aussi un `THREE.Clock` déprécié.
- **Le `<Text>` de drei dessine un quad vide sur `WebGPURenderer`** : troika-three-text injecte son shader via `onBeforeCompile`, que le moteur de rendu à nœuds n'appelle jamais.
- **Les comptes de rendus dépendent de la machine.** Dans `chromium-headless-shell`, 10 mises à jour d'état espacées d'une image ont donné 6 rendus au lieu de 11, et un déplacement de souris en 5 étapes moins de rendus que sur le GPU : React regroupe les mises à jour et le navigateur fusionne les événements de pointeur quand les images sont lentes. Les pages utilisent `flushSync`, et ne rapportent aucun compte après les actions de pointeur.
- **Chromium sous Windows avertit que `powerPreference` est ignoré** chaque fois que R3F le passe ; les autres OS, non. `check.sh` filtre la ligne.
- **Les builds déterministe et standard de Rapier ont donné le même hash d'état sous Windows x64**, dans Node.js et dans le navigateur. Avec un pas variable entre 1/144 et 1/30 s, 16 médiators sur 24 ont atterri ailleurs et un est passé à travers un sol de 20 cm. Une balle rapide a traversé un mur dynamique mince sans CCD, mais pas un mur fixe.
- **IWER a besoin de `forceInstall`** dans Chromium, qui a déjà un `navigator.xr`, **et de `stereoEnabled`**, sinon le viewport de l'œil droit fait 0 pixel de large.
- **La première sonde WebXR est restée bloquée dix minutes** en gardant le verrou GPU partagé : le backend WebGL 2 levait une exception à chaque image XR, la page attendait des images indéfiniment, et l'exécution a été arrêtée à la main. La cause est le `XRWebGLLayer.framebuffer` d'IWER, `null`, utilisé comme clé de `WeakMap` dans `WebGLState.drawBuffers`. La page intercepte maintenant les erreurs de rendu et borne ses attentes, et `probe.mjs` s'arrête de lui-même après deux fois son délai plus 30 secondes.
- **Dans r186, `WebGPURenderer` n'entre dans une session WebXR sur WebGPU qu'avec `XRGPUBinding` et la fonctionnalité `webgpu`** ; son message d'erreur mentionne un `VRButtonGPU` qui n'existe pas. `WebGLXRFallback` change de moteur de rendu, mais les contrôleurs que la page a pris au premier moteur de rendu cessent de recevoir des événements. Seul le `WebGLRenderer` classique a rendu les deux yeux avec IWER.
- **Un `InstancedMesh` ignore `setColorAt` si son premier rendu n'avait pas de couleurs d'instance** : les marqueurs du portage s'affichaient en blanc jusqu'à ce que l'attribut soit alloué dès le départ.
- **`@react-three/test-renderer` a besoin de `IS_REACT_ACT_ENVIRONMENT`**, sinon React avertit à chaque mise à jour et R3F libère plus tard ; son build CommonJS charge `three.cjs` à côté du build en module ES, sans séparer les classes qu'utilise la scène.
- **Pixels** : la même page deux fois a donné des octets identiques ; WebGPU face à ANGLE sur le même GPU différait de 294 pixels, face à SwiftShader de 10 330, aucun au-dessus du seuil par défaut de pixelmatch une fois l'anticrénelage écarté.
- **Une image importée par une leçon doit exister avant la page** : la leçon 11 a un jour importé une capture d'écran pas encore convertie, et le build Astro de l'arbre de travail partagé a échoué pour les autres sessions qui y travaillaient jusqu'à ce que l'image soit ajoutée.

## 2026-09-16 — Les leçons 9 à 13 sur les runners de CI

- L'exécution [35175914560](https://github.com/spareilleux/learn/actions/runs/35175914560) a réussi sur les trois OS du premier coup. Le build standard de Rapier a donné le hash d'état `68235a2bdba192f1` sous Linux x64 et macOS arm64 aussi, dans Node.js et dans le navigateur, le même que le build déterministe : pour cette scène, et pas comme une garantie.
- macOS a exécuté les pages sur WebGPU avec l'adaptateur « apple » ; Linux et Windows sur le WebGL 2 de SwiftShader, où le `ThreeFretboard` de GA a produit ses 253 lignes d'erreur WebGL et où R3F a averti 13 fois à propos de `PCFSoftShadowMap` au lieu de 14.
- Avant le push, la vérification locale a comparé la page de repli de la leçon 11 à sa sortie WebGL 2 sur le GPU de l'auteur : la page finit sur WebGL 2 après avoir démarré sur WebGPU. `check.sh` n'utilise maintenant la sortie WebGL 2 que quand la page a tourné sur WebGL 2 dès le départ.

## 2026-09-16 — GuitarAlchemist/ga, leçons 9 à 13

Rien de ce qui suit n'a été signalé à GA.

- Les composants React de GA utilisent R3F 8, drei 9 et React 18, avec `WebGLRenderer` dans les 6 fichiers qui ont un `<Canvas>` ; `ThreeFretboard.tsx` n'utilise pas R3F. L'explorateur BSP met à jour un état React avec une copie de la position de la caméra à chaque image, et `GuitarAlchemistLogo3D.tsx` passe un nouvel objet dans `args`, ce qui reconstruit sa géométrie à chaque rendu (leçon 9).
- Aucune bibliothèque de physique : Cheese Avalanche est écrit à la main avec un pas variable plafonné à 1/30 s ; le lunar lander utilise un pas fixe de 1/120 s avec un accumulateur (leçon 10).
- Aucun code WebXR (leçon 11).
- 22 fichiers de specs Playwright, dont les 7 hors de la suite du tableau de bord, 6 d'entre eux sur des pages 3D, ne sont exécutés par aucun workflow de CI ; des attentes de 3 secondes pour WebGPU ; un `toBeTruthy()` sur le buffer d'une capture d'écran ; une vérification de canvas noir qui appelle `getContext('2d')` sur un canvas WebGL et ne peut jamais réussir ; 13 fichiers de résultats de tests commités, issus d'une exécution en échec (leçon 12).
- `ThreeFretboard.tsx`, reproduit et mesuré : 69 draw calls et 32 textures pour un manche vide ; 10 rendus de son parent avec les mêmes notes reconstruisent la scène 10 fois et font fuir 29 textures de sprites à chaque fois ; un pixel ratio qui va jusqu'à 6 ; `samples: 8`, qui ne dessine rien sur le WebGL 2 de SwiftShader ; des cordes deux fois trop épaisses, puisqu'un tirant sert de rayon ; et une prop `onPositionClick` jamais appelée. Le portage dessine le même manche en 6 draw calls avec 4 textures, et sélectionne des notes (leçon 13).

## 2026-09-17 — Démos en direct

- Les pages sont construites par une seconde configuration Vite, `vite.demos.config.ts`, avec la base `/learn/threejs-demos/`, dans `public/threejs-demos`, que le site copie tel quel. Les sources des pages des leçons sont inchangées, puisque les leçons 4, 8 et 13 citent leur build ; un plugin de cette configuration ajoute le panneau *Try it* aux seules pages construites. Une page ne se pilote pas de l'extérieur : chaque contrôle règle donc un paramètre d'URL et recharge la page. Le panneau est lil-gui 0.17, la copie que three.js livre dans `three/addons/libs` : aucune nouvelle dépendance.
- Le build pèse 9.4 Mo en 75 fichiers. Les builds standard et déterministe de Rapier, chacun avec son WebAssembly intégré en base64, font 2.9 Mo chacun ; `three.tsl` 0.69 Mo. `check.sh` le reconstruit et le compare à la copie commitée (`diff -r`, hors modèles et HDR régénérés).
- Les cadres sont dans un `<details>` fermé, avec `loading="lazy"` : rien ne se charge tant qu'un lecteur n'en déplie pas un.
- La guitare est modélisée en code : aucune guitare glTF sous licence connue n'était disponible. 47 405 triangles en 32 draw calls ; de l'instanciation pour les frettes, les repères, les plots, les pontets, les boutons et les mécaniques.
- Le `body.handle` de Rapier est un flottant qui regroupe un index et une génération : `handle % 8` n'est pas un index de palette ; chaque médiator garde maintenant la couleur de son numéro de lancer. Et les couleurs réglées avec `setColorAt` n'atteignaient le GPU que dans une image de `setAnimationLoop` : une sonde qui appelait `render()` elle-même voyait des médiators blancs. En r186, `InstanceNode` les envoie dans sa mise à jour par image.
- La page VR utilise le `WebGLRenderer` classique, comme la leçon 11 l'a trouvé nécessaire avec IWER. Pendant une session, son écouteur `resize` ne doit rien faire : `WebGLRenderer` avertit « Can't change size while VR device is presenting ».
- Sur une page à taille de téléphone (émulation Pixel 7 de Playwright), les cadres mesuraient d'abord 150 pixels de haut : les styles du site écrasent l'attribut `height` de l'iframe, donc la hauteur est maintenant un style en ligne, `min(420px, 70vh)`. Le panneau démarre replié dans un cadre étroit. Avec un CPU ralenti 4 fois mais le GPU de bureau de l'auteur, les cinq scènes tenaient 60 images par seconde en WebGPU et avec `?webgl` ; sur le GPU d'un vrai téléphone de milieu de gamme, c'est *à vérifier*.
- La première sonde d'une page qui importe une nouvelle dépendance a échoué avec « Execution context was destroyed » : Vite a optimisé la dépendance et rechargé la page. Le second essai est passé.

## 2026-09-17 — Leçon 14, le labo 3D Guitar Alchemist

- Quinze expériences dans `code/threejs/ga-lab`, chacune avec une hypothèse et des prédictions chiffrées committées le 16 septembre avant son exécution, mesurées le 17 septembre sur une RTX 5080 dans Chromium 153 avec les requêtes d'horodatage WebGPU. Sur 61 prédictions, 19 étaient fausses en tout ou partie et 2 n'ont pas pu être mesurées ; elles restent dans la leçon.
- Les images sont rendues en boucle serrée sans `requestAnimationFrame`, vsync désactivé, et la page fait avancer elle-même `renderer._nodes.nodeFrame` : sans cela, les shadow maps et le bloom ne se mettent pas à jour. `onSubmittedWorkDone()` n'a jamais résolu sous 3.5 ms environ : les temps GPU viennent des requêtes d'horodatage.
- Constats r186 : `InstancedMesh` avec morph targets échoue avec une instance (pas de `morphTargetInfluences`) et avec plusieurs quand on les définit ; `BatchedMesh` fait un appel par objet sur WebGPU ; le compute TSL tourne sur WebGL 2 ; `renderer.info.memory.texturesSize` compte 0 pour les textures compressées.
- L'index OPTIC-K de GA contient 313 047 vecteurs de 124 dimensions (OPTK v4), pas 112. Le labo le lit en lecture seule ; la CI utilise un substitut synthétique.
- Le CCD de Rapier n'arrête pas un médiator cinématique : il traverse la corde à 30 et 60 pas par seconde dans tous les cas.
- Le build R3F embarquait `three` à côté de `three/webgpu` : 565 ko gzip contre 210 pour la même scène sans React.
- Les textures de bois ComfyUI sont en attente : l'expérience 4 du labo ComfyUI GA n'avait pas encore de sortie.
- La CI (`threejs-ga-lab.yml`) compare les compteurs `renderer.info` sur WebGL 2 sur trois OS, jamais les temps. Une capture Playwright a bloqué 300 s une fois sur macOS : le lanceur garde désormais le résultat quand une capture échoue.

## À vérifier

- La mémoire GPU des KTX2 avec un outil GPU.
- Le premier rendu de R3F sur un build de production.
- Un alias de `three` vers `three/webgpu`.
- Le manche à taille réelle et le décalage de tête de 25 mm d'IWER sur un casque.
- La latence audio au microphone.
- `powerPreference` sur un portable à deux GPU.
- La démo VR avec un vrai casque : l'entrée dans la session, les rayons des manettes, la note et l'impulsion haptique.
- Si les médiators lancés sans CCD traversent les frettes de la démo physique.
- Les cinq scènes complètes sur un téléphone : fréquence d'images, et si la shadow map de 2048 × 2048 et le bloom du studio tiennent.
- Si une scène modélisée en centimètres a besoin de lumières 10 000 fois plus fortes pour avoir le même aspect qu'en mètres (leçon 2).
- Les textures KTX2 : chargement, formats GPU choisis sur chaque OS, mémoire.
- Si `ThreeHeadstock.tsx` appelle `onTuningPegClick` une fois par écouteur périmé après les nouvelles exécutions de son effet (leçon 5).
- Si `ThreeFretboard.tsx` est reconstruit à chaque rendu de ses parents dans les pages de GA (leçon 8).
- Le temps GPU, pas seulement le temps CPU, avec le `timestamp-query` de WebGPU (leçon 8).
- Draco face à meshopt sur un gros modèle et sur de nombreux petits, sur un vrai réseau (leçon 4, exercice 3).
- WebGPU sur une machine Linux ou Windows dotée d'un GPU, autre que celle de l'auteur.
- `XRGPUBinding` : quels navigateurs et quels casques le proposent, et `WebGPURenderer` dans une vraie session WebXR (leçon 11).
- Le backend WebGL 2 et `WebGLXRFallback` sur un vrai casque, dont le framebuffer de couche n'est pas `null` (leçon 11).
- La fréquence d'images, le rendu fovéal et le confort de la page WebXR sur un Quest (leçon 11).
- S'il existe un troika-three-text compatible avec WebGPU pour le `<Text>` de drei (leçon 9).
- La fréquence à laquelle les parents de GA rendent `ThreeFretboard` et l'explorateur BSP en pratique, avec le profileur de React (leçons 9 et 13).
- `samples: 8` sur le WebGL 2 de vrais GPU, selon leur `MAX_SAMPLES` (leçon 13).
- Pourquoi Rapier a arrêté une balle rapide sur un mur fixe mince sans CCD (leçon 10).
