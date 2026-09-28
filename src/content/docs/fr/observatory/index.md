---
title: Observatoire interactif
description: Explorer un prototype 3D Godot avec un modèle Blender et des textures générées localement avec ComfyUI.
sidebar:
  label: Observatoire
  order: 0
---

[Ouvrir l'observatoire 3D](../../demos/observatory/) dans un navigateur de bureau compatible WebGL 2. Le premier chargement télécharge environ 51 Mo de moteur et de scène. Les téléphones et tablettes ne sont pas pris en charge : il faut un clavier et une souris.

Clique dans la scène pour regarder autour de toi. Déplace-toi avec **WASD** ou **ZQSD** ; maintiens **Shift** pour accélérer. **Échap** libère la souris. Si le navigateur refuse la capture du pointeur, maintiens le bouton droit et fais glisser la souris. Les touches **1–7** activent des points de vue ; **F** bascule en vol libre, puis **E/Espace** monte et **C** descend. La caméra permet d'explorer, mais ce n'est pas encore un personnage avec collisions. La capture de la souris a été vérifiée dans la version native ; son comportement dans une fenêtre Chrome, Edge ou Firefox ordinaire reste à tester. Signale tout problème propre à ton navigateur.

Tous les cours du site sont rangés dans la bibliothèque. Au rez-de-chaussée, chaque domaine du site a sa travée, avec une plaque, et ses cours sont présentés de face, à hauteur des yeux. Vise un volume, avec le réticule quand la souris est capturée ou avec le pointeur, pour voir sa fiche ; clique dessus ou appuie sur **Entrée** pour ouvrir le cours dans un nouvel onglet. La touche **L** affiche le catalogue de tous les cours. La scène lit la liste des cours sur le site au démarrage : un nouveau cours arrive donc sur les étagères sans nouvelle version de la scène. Les titres sont dans la langue de la page d'où tu viens, sinon dans celle de ton navigateur.

Le prototype comprend un portail en acier texturé, créé dans Blender, et des textures produites localement avec ComfyUI. Le marbre, le grain des reliures, la pierre taillée, les salissures de l'acier et trois panneaux de vitrail (soleil et lune, arbre elfique, alambic) viennent du modèle SDXL 1.0 déjà présent ; l'ornement de pilier vient de SDXL 1.0 avec ControlNet Union SDXL. Des shaders en font des reliures de cuir et de toile avec nerfs et filets dorés, une pierre appareillée avec joints et caissons, un acier brossé et des vitraux rétroéclairés. La balustrade a des balustres tournés en bronze sous une main courante en noyer.

Le rendu natif plus riche utilise Godot Forward+ : reflets en espace écran, éclairage indirect, brouillard volumétrique et halo lumineux. La version navigateur utilise le moteur Compatibility sous WebGL 2, où ces effets natifs sont réduits ou absents : les vitraux n'y projettent pas de rayons de lumière, et les livres, le bronze et l'acier y reçoivent des compensations simples pour l'éclairage indirect manquant. Aucune version ne prétend faire du ray tracing matériel en temps réel : Blender Cycles a servi à cuire les textures de l'acier, pas au rendu de la scène interactive.

La salle reste stylisée, surtout son faisceau central, et les lettres des dos de livres sont des glyphes décoratifs, pas des titres lisibles ; seuls les volumes des cours portent de vrais titres. C'est un prototype jouable, pas encore un environnement photoréaliste. Les cours [Blender](../blender/) et [ComfyUI](../comfyui/) présentent les outils de création des assets.

Crédits et licences : [Godot Engine et bibliothèques incluses](../../demos/observatory/LICENSES.txt) ; [licence du modèle SDXL 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/blob/main/LICENSE.md) (CreativeML Open RAIL++-M) ; [ControlNet Union SDXL](https://huggingface.co/xinsir/controlnet-union-sdxl-1.0) (Apache-2.0). Les textures générées sont des assets, pas une redistribution des poids des modèles.
