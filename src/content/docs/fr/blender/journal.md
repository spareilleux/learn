---
title: Journal
description: 'Notes de progression datées du cours Blender — Blender 5.2.2 LTS épinglé, une installation portable, des scripts exécutés en arrière-plan et comparés en CI sur trois systèmes, un rendu Cycles aux mêmes pixels sous Windows, Linux et macOS, un bug d''espace colorimétrique dans une texture générée, ce que l''exporteur glTF abandonne ou ignore par défaut, deux modèles Hunyuan3D sortis de ComfyUI nettoyés dans Blender avec ce qui a échoué, et les points à vérifier.'
sidebar:
  order: 99
---

## Progression

- [x] Blender 5.2.2 LTS (commit `d13f752e3b9c`), installé depuis l'archive portable
- [x] `check.sh` : le script `bpy` de chaque leçon exécuté avec `--background --factory-startup`, son rapport comparé avec `expected/`
- [x] CI sous Ubuntu, Windows et macOS, avec Cycles sur le CPU
- [x] Leçon 1 : l'interface, et le fichier .blend comme base de données
- [x] Leçon 2 : modélisation polygonale et modificateurs
- [x] Leçon 3 : matériaux, UV, et ce que glTF en garde
- [x] Leçon 4 : lumières, caméras, et rendu avec EEVEE et Cycles
- [x] Traductions française et espagnole
- [x] Un pipeline de nettoyage pour les modèles `.glb` générés dans ComfyUI, essayé sur deux modèles Hunyuan3D
- [ ] Leçon 5 : scripter avec `bpy`

## 2026-09-16 — Versions et installation

- La page LTS de Blender liste 5.2.2 et 4.5.14, toutes deux publiées le 15 septembre 2026. Le cours épingle 5.2.2, tag `v5.2.2`, commit `d13f752e3b9c4f8c261cda552b1021f8bcc0382c`.
- L'archive Windows fait 404 453 484 octets, et son SHA-256 correspond à `blender-5.2.2.sha256`. Elle est extraite sur un disque séparé, et rien n'est installé dans le système.
- winget proposait encore 5.2.1 le jour de la sortie de 5.2.2. Le fichier de sommes de contrôle ne liste aucun build Intel pour macOS, seulement `macos-arm64`.
- Les pages de projects.blender.org répondent `403` à `curl`, mais pas son API : `/api/v1/repos/blender/blender/raw/<path>?ref=<sha>` a renvoyé les fichiers au commit épinglé. Les fichiers Python cités dans les leçons (l'exporteur glTF, les propriétés de Cycles) sont identiques à ceux du build installé, aux fins de ligne près.
- Ordre de la leçon 1 : `bpy` entre dans chaque leçon dès la première, au lieu d'attendre la leçon 5 ; la mission explique pourquoi.

## 2026-09-16 — Scripts, CI et ce qu'ils ont montré

- La première exécution de la CI est passée sur les trois systèmes. Chaque job a pris environ une minute, dont 25 à 27 s pour `check.sh` ; le reste est le téléchargement (environ 350 à 400 Mo) et la décompression. Le rendu de référence à 4096 échantillons de la leçon 4 a pris 13 à 18 s sur les runners, contre 1,4 s sur le CPU à 24 threads de l'auteur.
- L'empreinte du rendu Cycles à 16 échantillons, en 8 bits après AgX, était la même sous Windows et Linux sur x86-64 et sous macOS sur Apple Silicon. `check.sh` l'a d'abord affichée sans la comparer ; après cette exécution, il la compare.
- Le fichier `.blend` enregistré par la leçon 1 fait 96 061 octets sur la machine de l'auteur et sur le runner Linux, 96 053 sur le runner Windows et 96 055 sur celui de macOS : sa taille n'est pas comparée.
- La texture de palissandre générée était d'abord beaucoup trop sombre. `Image.pixels` sur une image sRGB 8 bits stocke les valeurs données comme des octets, sans conversion, et le script avait d'abord converti la couleur en linéaire. La leçon 3 raconte l'histoire.
- L'exporteur glTF a abandonné une Noise Texture connectée à la Roughness sans message dans son log, laissant la rugosité par défaut de glTF, 1. Il n'applique pas les modificateurs sauf si `export_apply` est activé. Et `export_format="GLTF_EMBEDDED"` est refusé sauf si une préférence de l'add-on l'active, bien que le manuel documente ce format.
- En 5.2, lire `Material.use_nodes` affiche un `DeprecationWarning` : la propriété sera supprimée en 6.0. L'enum de `RenderSettings.engine`, lue depuis la classe, ne liste que `BLENDER_EEVEE`, alors que choisir `BLENDER_WORKBENCH` ou `CYCLES` fonctionne.
- Les premières lumières (12, 3 et 15 W) étaient beaucoup trop fortes pour une scène d'un demi-mètre de large ; la leçon utilise 3, 0,6 et 4 W.

## 2026-09-16 — Images

- Les rendus viennent de `scripts/render_images.py` : Cycles sur le CPU pour les images des leçons, et Cycles avec OptiX et EEVEE pour les durées, exécutés sous le verrou GPU de la machine, puisque d'autres travaux partagent le GPU.
- La capture de l'interface vient de Blender démarré avec une fenêtre et d'un script qui sélectionne le cube, écarte le pointeur et appelle `bpy.ops.screen.screenshot` depuis un timer. Avec `--factory-startup`, l'écran d'accueil Quick Setup couvrait le viewport, donc la capture a utilisé un dossier de configuration utilisateur séparé (`BLENDER_USER_CONFIG`) dont les préférences désactivent cet écran. Quitter depuis le script a quand même écrit `quit.blend` dans le dossier temporaire du système.

## 2026-09-17 — Des modèles générés dans ComfyUI, nettoyés dans Blender

La demande : de vrais modèles 3D sortis de ComfyUI, repris dans Blender et montrés ici avec ce qui a échoué. Atlas, une autre session de travail de ce projet, a généré un métronome et un gramophone avec ComfyUI (voir le [cours ComfyUI](../../comfyui/)), en deux temps :

1. [SDXL base 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0) a dessiné chaque objet seul sur fond blanc, vu de trois quarts et légèrement d'en haut : 1024 × 1024 px, 30 pas, CFG 6,5, `dpmpp_2m` avec le planificateur `karras`, graines 5101 (métronome) et 5110 (gramophone).
2. [Hunyuan3D 2.0](https://github.com/Tencent-Hunyuan/Hunyuan3D-2), avec les poids fp16 réempaquetés par Comfy-Org ([`hunyuan3d-dit-v2_fp16`](https://huggingface.co/Comfy-Org/hunyuan3D_2.0_repackaged)) et les nœuds natifs de ComfyUI ([tutoriel de Comfy](https://docs.comfy.org/tutorials/3d/hunyuan3D-2)), a changé chaque image en maillage : `ImageOnlyCheckpointLoader` → `CLIPVisionEncode` (crop `center`) → `Hunyuan3Dv2Conditioning` → `EmptyLatentHunyuan3Dv2` (resolution 3072) → `KSampler` (30 steps, CFG 5, `euler`/`normal`, seed 7) → `VAEDecodeHunyuan3D` (8000 chunks, octree resolution 380) → `VoxelToMesh` (surface net, threshold 0.6) → `SaveGLB`. ComfyUI v0.36.0.

La licence de Hunyuan3D 2.0 précise qu'elle ne s'applique pas dans l'Union européenne, au Royaume-Uni et en Corée du Sud. Seuls des rendus des modèles sont publiés ici ; les fichiers `.glb` restent hors du dépôt.

Blender a ensuite exécuté [`scripts/glb_pipeline.py`](https://github.com/spareilleux/learn/blob/9480173/code/blender/scripts/glb_pipeline.py) en arrière-plan sur chaque fichier. Il fusionne les sommets par distance, retire les parties flottantes, recalcule les normales, met à l'échelle réelle, décime, rend compte du maillage avant et après, rend une turntable Cycles, exporte un `.glb` avec les modificateurs appliqués, et le relit. La CI l'exécute sur un petit médiator construit en `bpy`, avec les défauts d'un maillage généré (`scripts/pipeline_check.py`), avec et sans remesh voxel : les rapports, remesh compris, étaient identiques sur les trois runners.

![Métronome, de gauche à droite : l'image SDXL ; le maillage après le premier nettoyage, le cadran et le balancier changés en relief et une surface rugueuse ; après un remesh voxel de 1,2 mm, plus lisse, avec le même relief ; l'arrière après le remesh, une face plate que l'image ne montrait pas](../../../../assets/blender/comfy3d-metronome.webp)

![Gramophone, de gauche à droite : l'image SDXL, avec une ligne de sol sous le meuble ; le maillage après le premier nettoyage, le pavillon plein de triangles déchirés et une dalle sous le meuble ; après un remesh voxel de 3 mm, un pavillon fermé, avec quelques fragments de la dalle au sol ; la vue de côté après le remesh](../../../../assets/blender/comfy3d-gramophone.webp)

Ce qu'ont dit les rapports :

| | Métronome | Gramophone |
|---|---|---|
| `.glb` de Hunyuan3D | 15 944 172 octets | 17 421 112 octets |
| Sommets, triangles | 438 348, 890 140 | 433 806, 1 017 760 |
| Arêtes non manifold | 19 084 | 189 748 |
| Parties séparées | 86 | 20 |
| UV, textures | aucun, aucune | aucun, aucune |
| Decimate vers 20 000 triangles | 882 644 → 43 302, cible manquée | 1 004 809 → 317 253, cible manquée |
| `.glb` nettoyé, sans remesh | 632 484 octets | 5 835 300 octets |
| Remesh voxel, puis Decimate | 1,2 mm : 223 100 → 20 000 | 3 mm : 195 848 → 20 000 |
| Après remesh : arêtes non manifold, parties séparées | 0, 1 | 0, 3 |
| `.glb` nettoyé, avec remesh | 361 100 octets | 361 000 octets |

- **Pas de texture, donc pas d'éclairage cuit.** L'échec prévu, un éclairage peint dans la texture, n'a pas eu lieu : ce workflow ne produit que la forme, avec un matériau vide et sans carte UV. Le bois, le laiton et le cadran des images SDXL sont perdus ; couleurs et matériaux sont à refaire dans Blender.
- **Topologie.** Un surface net construit sa surface sur une grille de voxels. Là où une paroi est plus fine qu'un voxel, comme le pavillon du gramophone, les deux faces tombent probablement sur les mêmes arêtes : le rapport y a compté 189 748 arêtes non manifold, contre 19 084 sur le métronome plein. [Decimate](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/decimate.html) en mode Collapse s'est arrêté bien au-dessus de sa cible sur les deux modèles, et la première version du pipeline n'affichait que le ratio demandé. Le rapport affiche maintenant les triangles obtenus et signale une cible manquée.
- **Remesh voxel.** Le [modificateur Remesh](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/remesh.html) en mode Voxel reconstruit une surface fermée. Après lui, Decimate a atteint exactement 20 000 triangles, et les deux maillages n'avaient plus ni bord ni arête non manifold. Son prix : les détails plus petits qu'un voxel disparaissent, et les parois fines se cassent en miettes. Le pipeline repasse maintenant son filtre de parties flottantes après le remesh ; il a retiré 22 miettes du métronome et 2 du gramophone. Les deux fragments qui restent au gramophone portent chacun plus de 1 % des faces.
- **Arrière inventé.** L'arrière et les côtés du métronome, que l'image ne montre pas, sont sortis en faces planes et plausibles. Le cadran gravé, les graduations et le balancier de l'image sont devenus du relief sur la face avant : Hunyuan3D lit le détail peint comme de la forme.
- **Le fond.** La ligne où le sol blanc rejoint le mur blanc sous le gramophone est devenue une dalle sous le meuble. Le filtre de parties flottantes l'a gardée, et le remesh n'a fait que la casser en fragments. La correction se place avant l'étape 3D, dans le détourage de l'image.
- **Petites choses.** Le métronome portait un sommet sans aucune face : glTF l'abandonne, et la taille relue était donc plus petite que la taille écrite. Le pipeline supprime maintenant ces sommets. L'origine est remise en bas après le remesh sans remettre à l'échelle, si bien que le métronome remaillé mesure 22,98 cm de haut au lieu de 23.
- **Temps, sur la machine de l'auteur.** 17 à 29 s par modèle pour tout le pipeline, import et export compris ; 0,15 à 0,36 s par image de turntable à 512 × 512 px et 32 échantillons, Cycles sur le CPU. Les tailles réelles (23 cm et 60 cm de haut) sont des choix pour cet essai, pas des mesures.

## 2026-09-19 — Cathédrale orbitale : le cadrage avant la génération

Cette étude procédurale réutilise les fonctions `stage.aim` et `stage.area_light` du cours. Hypothèse avant le rendu : un aperçu CPU à faible nombre d'échantillons suffit pour juger le cadrage avant de mobiliser le GPU pour ComfyUI.

- Windows, Blender 5.2.2 LTS, Cycles CPU, 8 threads, 24 échantillons, 1100 × 700 pixels, 314 objets.
- Premier rendu : **6.698 s**. La caméra oblique plaçait les piliers devant les anneaux ; l'inspection visuelle a conduit à rejeter ce cadrage.
- Deuxième rendu : **7.025 s**. Une caméra centrée dégage les anneaux et l'allée. Les deux processus se sont terminés avec le code 0 ; le script vérifie les objets et la sortie PNG.
- Verdict : hypothèse confirmée pour détecter ce défaut de cadrage, pas pour la qualité finale. Temps total de rendu : **13.723 s** ; rendu GPU : **0 s**.
- Source : `code/blender/scripts/orbital_cathedral.py`. Preuves locales : `C:/tmp/blender-comfy-scenes-20260919/orbital-v1/` et `orbital-v2/`, avec un PNG, un blend éditable et un rapport JSON par version. Ces fichiers ne sont pas publiés.
- La scène Blender ouverte par l'utilisateur n'a pas été modifiée. Le connecteur MCP était indisponible ; un processus séparé démarré avec la configuration d'usine a produit l'étude.
- ComfyUI était indisponible sur le port 8188. Aucune inférence ComfyUI, API payante ou téléchargement de modèle. Le code de l'artefact Claude reste inaccessible : c'est une étude originale, pas son adaptation.
- Avertissements non bloquants : affectations `use_nodes` obsolètes et chemins des brosses intégrées que Blender ne pouvait pas rendre relatifs. L'exécution Linux/macOS, la portabilité du blend, le raffinement des matériaux et l'étape ComfyUI restent **à vérifier**.

## À vérifier

- L'installation avec winget, Snap et Flathub, et les versions qu'ils proposent.
- Les commandes PowerShell de téléchargement et d'extraction de la leçon 1, telles qu'écrites.
- L'interface sous WSLg.
- EEVEE sur une machine sans GPU, et si les démarrages ultérieurs plus rapides d'EEVEE viennent d'un cache de shaders sur disque.
- Si les rendus GPU avec une graine fixe sont reproductibles, d'une exécution à l'autre et d'un GPU à l'autre.
