---
title: Observatoire interactif
description: Explorer un prototype 3D Godot avec un modèle Blender et des textures générées localement avec ComfyUI.
sidebar:
  label: Observatoire
  order: 0
---

[Ouvrir l'observatoire 3D](../../demos/observatory/) dans un navigateur de bureau compatible WebGL 2. Le premier chargement télécharge environ 47 Mo de moteur et de scène. Les téléphones et tablettes ne sont pas pris en charge : il faut un clavier et une souris.

Clique dans la scène pour regarder autour de toi. Déplace-toi avec **WASD** ou **ZQSD** ; maintiens **Shift** pour accélérer. **Échap** libère la souris. Si le navigateur refuse la capture du pointeur, maintiens le bouton droit et fais glisser la souris. Les touches **1–7** activent des points de vue ; **F** bascule en vol libre, puis **E/Espace** monte et **C** descend. La caméra permet d'explorer, mais ce n'est pas encore un personnage avec collisions. La capture de la souris a été vérifiée dans la version native ; son comportement dans une fenêtre Chrome, Edge ou Firefox ordinaire reste à tester. Signale tout problème propre à ton navigateur.

Le prototype comprend un portail en acier texturé, créé dans Blender, et deux textures produites localement avec ComfyUI : le marbre avec le modèle SDXL 1.0 déjà présent, et un ornement de pilier avec SDXL 1.0 et ControlNet Union SDXL. Le rendu natif plus riche utilise Godot Forward+ : reflets en espace écran, éclairage indirect et halo lumineux. La version navigateur utilise le moteur Compatibility sous WebGL 2 ; certains effets natifs y sont réduits ou absents. Aucune version ne prétend faire du ray tracing matériel en temps réel : Blender Cycles a servi à cuire les textures de l'acier, pas au rendu de la scène interactive.

La salle reste stylisée, surtout ses livres et son faisceau central. C'est un prototype jouable, pas encore un environnement photoréaliste. Les cours [Blender](../blender/) et [ComfyUI](../comfyui/) présentent les outils de création des assets.

Crédits et licences : [Godot Engine et bibliothèques incluses](../../demos/observatory/LICENSES.txt) ; [licence du modèle SDXL 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/blob/main/LICENSE.md) (CreativeML Open RAIL++-M) ; [ControlNet Union SDXL](https://huggingface.co/xinsir/controlnet-union-sdxl-1.0) (Apache-2.0). Les textures générées sont des assets, pas une redistribution des poids des modèles.
