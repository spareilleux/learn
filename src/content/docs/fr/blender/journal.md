---
title: Journal
description: 'Notes de progression datées du cours Blender — Blender 5.2.2 LTS épinglé, une installation portable, des scripts exécutés en arrière-plan et comparés en CI sur trois systèmes, un rendu Cycles aux mêmes pixels sous Windows, Linux et macOS, un bug d''espace colorimétrique dans une texture générée, ce que l''exporteur glTF abandonne ou ignore par défaut, et les points à vérifier.'
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

## À vérifier

- L'installation avec winget, Snap et Flathub, et les versions qu'ils proposent.
- Les commandes PowerShell de téléchargement et d'extraction de la leçon 1, telles qu'écrites.
- L'interface sous WSLg.
- EEVEE sur une machine sans GPU, et si les démarrages ultérieurs plus rapides d'EEVEE viennent d'un cache de shaders sur disque.
- Si les rendus GPU avec une graine fixe sont reproductibles, d'une exécution à l'autre et d'un GPU à l'autre.
