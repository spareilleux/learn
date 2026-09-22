---
title: Journal
description: 'Notes de progression datées du cours Blender — Blender 5.2.2 LTS épinglé, une installation portable, des scripts exécutés en arrière-plan et comparés en CI sur trois systèmes, un rendu Cycles aux mêmes pixels sous Windows, Linux et macOS, un bug d''espace colorimétrique dans une texture générée, ce que l''exporteur glTF abandonne ou ignore par défaut, deux objets modélisés en bpy face aux deux mêmes générés depuis une image, deux modèles Hunyuan3D sortis de ComfyUI nettoyés dans Blender avec ce qui a échoué, et les points à vérifier.'
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
- [x] Deux modèles procéduraux en `bpy`, comparés aux modèles générés
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

La demande : de vrais modèles 3D sortis de ComfyUI, repris dans Blender et montrés ici avec ce qui a échoué. La génération est l'œuvre d'Atlas, une autre session de travail de ce projet, avec son script `objets.py` (non publié) : il a produit un métronome et un gramophone avec ComfyUI (voir le [cours ComfyUI](../../comfyui/)), en deux temps :

1. [SDXL base 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0) a dessiné chaque objet seul sur fond blanc, vu de trois quarts et légèrement d'en haut : 1024 × 1024 px, 30 pas, CFG 6,5, `dpmpp_2m` avec le planificateur `karras`, graines 5101 (métronome) et 5110 (gramophone).
2. [Hunyuan3D 2.0](https://github.com/Tencent-Hunyuan/Hunyuan3D-2), avec les poids fp16 réempaquetés par Comfy-Org ([`hunyuan3d-dit-v2_fp16`](https://huggingface.co/Comfy-Org/hunyuan3D_2.0_repackaged)) et les nœuds natifs de ComfyUI ([tutoriel de Comfy](https://docs.comfy.org/tutorials/3d/hunyuan3D-2)), a changé chaque image en maillage : `ImageOnlyCheckpointLoader` → `CLIPVisionEncode` (crop `center`) → `Hunyuan3Dv2Conditioning` → `EmptyLatentHunyuan3Dv2` (resolution 3072) → `KSampler` (30 steps, CFG 5, `euler`/`normal`, seed 7) → `VAEDecodeHunyuan3D` (8000 chunks, octree resolution 380) → `VoxelToMesh` (surface net, threshold 0.6) → `SaveGLB`. ComfyUI v0.36.0.

La licence de Hunyuan3D 2.0 ne s'applique pas dans l'Union européenne, au Royaume-Uni et en Corée du Sud, et sa clause 5.c interdit d'afficher les sorties hors de ce territoire. Ce site peut être lu là-bas : ni les modèles ni leurs rendus ne sont donc publiés ici, et les constats ci-dessous sont décrits en mots.

Le pipeline de nettoyage a été écrit pour ce cours par L2, la session qui le rédige. Blender a exécuté [`scripts/glb_pipeline.py`](https://github.com/spareilleux/learn/blob/9480173/code/blender/scripts/glb_pipeline.py) en arrière-plan sur chaque fichier. Il fusionne les sommets par distance, retire les parties flottantes, recalcule les normales, met à l'échelle réelle, décime, rend compte du maillage avant et après, rend une turntable Cycles, exporte un `.glb` avec les modificateurs appliqués, et le relit. La CI l'exécute sur un petit médiator construit en `bpy`, avec les défauts d'un maillage généré (`scripts/pipeline_check.py`), avec et sans remesh voxel : les rapports, remesh compris, étaient identiques sur les trois runners.

Ce qu'ont montré les rendus en turntable. Le métronome a gardé sa pyramide, son socle et sa clé de remontage ; le cadran, les graduations et le balancier de l'image sont sortis en relief sur la face avant, avec une surface rugueuse avant le remesh et plus lisse après. Le pavillon du gramophone était plein de triangles déchirés avant le remesh et fermé après, et une dalle sous le meuble s'est cassée en quelques fragments.

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

## 2026-09-22 — Modéliser en bpy face à l'image→3D

Les deux mêmes objets, un métronome et un gramophone, ont été faits deux fois : générés depuis une image SDXL par Hunyuan3D 2.0 (l'entrée ci-dessus), puis modélisés en `bpy`. La seconde voie a été choisie après lecture de la licence de Hunyuan3D, dont la clause 5.c interdit d'afficher ses sorties hors d'un territoire qui exclut l'Union européenne, le Royaume-Uni et la Corée du Sud — le cours ComfyUI raconte ce versant dans la [leçon 8](../../comfyui/08-recent-models-quantization/#lire-la-licence-avant-de-publier-une-sortie). Les scripts ont été écrits par un agent de la session orchestratrice ; ils sont gardés dans le cours, dans [`scripts/atlas/`](https://github.com/spareilleux/learn/blob/50da8f8/code/blender/scripts/atlas/), parce qu'ils rendent la comparaison concrète.

![Deux modèles faits en bpy, rendus avec Workbench : un métronome en bois avec sa graduation et son balancier, et un gramophone au pavillon de révolution, avec un disque et son étiquette](../../../../assets/blender/atlas-bpy-models.webp)

| | Hunyuan3D 2.0, puis nettoyé | Modélisé en `bpy` |
|---|---|---|
| Métronome : triangles | 890 140, puis 43 302 après Decimate, 20 000 après un remesh voxel | 3 370 |
| Gramophone : triangles | 1 017 760, puis 317 253, 20 000 après un remesh | 5 950 |
| `.glb` | 15,9 Mo et 17,4 Mo bruts ; 361 Ko chacun après le remesh | 91 176 et 150 944 octets |
| Arêtes non manifold | 19 084 et 189 748 | 0 et 0 |
| Pièces, noms | un seul bloc, `Material_0` | `corps`, `tige`, `poids` ; `caisse`, `pavillon`, `disque`, `etiquette`, `repere` |
| Animation | aucune | balancier ±19,99° en 1,5 s ; disque 720° en 1,54 s |
| Matériaux | aucun | une couleur Principled par pièce |
| Échelle et axes | à donner à la main après coup | 1 unité de haut, socle sur l'origine, face vers +Z |

- **Ce que le code apporte.** Chaque pièce est un objet nommé : la page qui charge le modèle peut donner à chacune son matériau et l'animer. Le balancier du métronome tourne autour d'un pivot, le disque du gramophone autour d'un autre ; les deux animations partent dans le glTF et bouclent proprement. Rien n'est laissé à l'interprétation : la hauteur vaut exactement 1, le socle est sur l'origine, la face regarde +Z.
- **Ce qu'il coûte.** Environ 510 lignes de modélisation pour les deux objets, plus 120 pour la vérification, et le modèle est exactement aussi détaillé que le dit le code : la graduation du métronome, ce sont douze traits extrudés, pas une plaque gravée ; le bois est une couleur, pas un fil. Un modèle image→3D donne en une minute une forme qu'il faudrait une heure à modéliser, avec les défauts décrits dans l'entrée ci-dessus.
- **Relire le fichier.** [`scripts/atlas_check.py`](https://github.com/spareilleux/learn/blob/50da8f8/code/blender/scripts/atlas_check.py) construit les deux modèles, puis ouvre chaque `.glb` deux fois : une fois comme octets, en analysant le bloc JSON pour afficher l'arbre de nœuds, les matériaux et les échantillonneurs d'animation, et une fois par l'importeur, pour les triangles et la boîte englobante. La courbe de rotation est déroulée clé par clé, si bien que le rapport montre de vrais angles plutôt que des quaternions : `0.000 s: 0.00 deg, 0.367 s: 19.99 deg, 0.750 s: 0.00 deg`, et si la première clé égale la dernière. La CI compare tout le rapport avec `expected/`.
- **Les axes de glTF.** Blender travaille en Z vers le haut avec la face vers −Y ; l'exporteur écrit Y vers le haut avec la face vers +Z. La vérification affiche la boîte englobante dans les axes de glTF, c'est-à-dire ce que voit celui qui consomme le fichier : `x [-0.2495, 0.2495], y [0.0000, 1.0000], z [-0.1747, 0.1747]`.
- **Un détail de l'exporteur.** Les 720° du disque en 1,54 s s'écrivent en 155 clés, et non en deux clés avec un nombre de tours : glTF range les rotations en quaternions, qui ne savent pas dire « deux tours ». Un lecteur qui interpole entre deux quaternions prend le chemin court : un tour complet doit donc être découpé en clés.
- **Mémoire.** Blender n'est lancé ici qu'avec au moins 12 Go de mémoire libre. La veille, un bake Cycles d'une autre scène a planté dans Embree pendant la construction de son BVH, avec 1 Go libre sur une machine de 64 Go.

## 2026-09-22 — Occlusion cuite dans les sommets, et distinguer un effet réel d'une image plus sombre

La question vient d'une autre page de ce projet, le [Banc de Placement](../../artifacts/#banc-de-placement) : une pièce dessinée par un moteur WebGL2 écrit à la main — une guitare, un bureau, un tapis, six lampes ponctuelles — où rien ne pose vraiment sur rien. Une occlusion cuite dans Blender et livrée à raison d'un octet par sommet vaudrait-elle son poids dans une page ? Rien n'a été modifié dans cette page : la cuisson, le shader rapiécé et les trois mesures ci-dessous ont tous tourné sur une copie locale.

**La cuisson.** Une capture sans écran de la page a sorti ses appels de dessin — 803 dessins sur 518 maillages — dont 220 ne bougent jamais. Ceux-là ont été reconstruits dans Blender et cuits avec Cycles dans un attribut de couleur par point, `bpy.ops.object.bake(type="AO", target="VERTEX_COLORS")` : 21 533 sommets, 25,9 s pour la passe d'occlusion ambiante et 24,4 s pour l'indirecte. Un octet par sommet fait 21 533 octets ; porté en base64 dans le JSON de la page, 39 856. Une copie rapiécée de la page le lie comme attribut de sommet et multiplie par lui un terme de son shader.

**Deux chiffres, trois mesures.** Les mêmes trois angles de caméra à chaque fois, et les mêmes deux nombres : le pourcentage de pixels dont la luminance Rec.601 bouge de plus de 4,5/255, et l'écart de luminance moyenne. Les trois vues s'appellent ci-dessous `default`, `low-left` et `high-right`.

| | pixels changés | écart moyen | luminance moyenne | dispersion de la luminance |
|---|---|---|---|---|
| occlusion sur le terme ambiant | 4,2, 5,0, 4,4 % | 1,23, 1,24, 1,30 | −0,4 | −0,16, −0,10, −0,07 |
| aussi sur ce que diffusent les six lampes | 47,8, 35,6, 52,1 % | 6,98, 5,64, 6,84 | −6,1 | −1,27, −0,18, −0,57 |
| les mêmes, exposition remise en place | 58,3, 41,2, 59,7 % | 6,84, 6,25, 6,52 | 0,0 | +1,44, +1,82, +1,95 |

- **La première piste ne change presque rien.** Ne multiplier que le terme ambiant par l'occlusion déplace 4 à 5 % des pixels, d'une moyenne de 1,2 sur 255. Dans ce shader, le coefficient ambiant va de 0,026 à 0,105 selon le matériau : le terme qu'il pondère ne pèse qu'une petite part de la couleur finale, il n'y avait donc pas grand-chose à en retirer. 40 Ko pour cela, c'est un mauvais marché.
- **La seconde avait l'air spectaculaire, et c'était le problème.** Multiplier par l'occlusion ce que diffusent les six lampes assombrit toute l'image : la luminance moyenne perd 6,1 sur 255, soit environ 10 % d'exposition. Un 0,9 uniforme sur l'image entière « changerait » lui aussi 48 % des pixels, et ne montrerait rigoureusement rien. La troisième mesure remet donc la luminance moyenne là où elle était — un gain unique en lumière linéaire, comme fonctionne une exposition, et non sur les octets sRGB — puis repose les deux mêmes questions.
- **Le pourcentage de pixels changés a monté, de 47,8 à 58,3 %.** Défaire l'assombrissement devait le faire s'effondrer. Le gain à lui seul pousse presque chaque pixel au-delà du seuil : ce chiffre mesurait l'exposition, dans les deux sens, et ne pouvait donc pas répondre à la question. **Un pourcentage de pixels changés ne veut rien dire sans contrôle d'exposition** — et un chiffre qui monte quand on retire le facteur parasite n'est pas une mesure faible, c'est la mauvaise mesure.
- **Ce qui répond, c'est la dispersion de la luminance.** Une exposition pure laisse l'écart-type intact une fois le gain défait, et c'est exactement ce que fait la piste ambiante : +0,04, +0,09, +0,11, du bruit. La piste diffuse l'élargit de 1,44, 1,82 et 1,95 pendant que la moyenne reste fixe — le côté éclairé monte tandis que les creux descendent. C'est la définition du contraste local. Le critère se généralise : pour savoir si un effet est réel ou seulement plus sombre, on tient la moyenne et on regarde la dispersion.
- **La vérification croisée.** L'écart moyen bouge à peine quand l'exposition est remise, 6,98 → 6,84 sur la première vue : l'assombrissement n'en était pas la cause. Deux chiffres réagissent au recalage en sens contraires — l'un s'en nourrit, l'autre l'ignore — et tous deux pointent dans la même direction. C'est ce qui rend le verdict solide.
- **Verdict : confirmé.** L'occlusion cuite par sommet achète ici de vraies ombres de contact, pour environ 40 Ko, mais sur la seconde piste seulement : sur le terme diffus, pas sur le seul terme ambiant.
- **Où cela s'arrête, au même niveau que le résultat.** Trois vues d'une seule scène. Et seuls les 220 dessins statiques sont cuits : une ombre cuite est collée à sa géométrie, si bien qu'un objet déplacé au-dessus d'un sol cuit n'emporte pas son ombre et n'en reçoit pas. La technique ne vaut que pour ce qui ne bouge pas, et qui la reprend doit le savoir avant d'en budgéter les octets.
- **Non publié.** La cuisson, la page rapiécée et le script de mesure vivent hors du dépôt et ne sont pas publiés ; l'artefact lui-même n'a pas été touché.

## À vérifier

- L'installation avec winget, Snap et Flathub, et les versions qu'ils proposent.
- Les commandes PowerShell de téléchargement et d'extraction de la leçon 1, telles qu'écrites.
- L'interface sous WSLg.
- EEVEE sur une machine sans GPU, et si les démarrages ultérieurs plus rapides d'EEVEE viennent d'un cache de shaders sur disque.
- Si les rendus GPU avec une graine fixe sont reproductibles, d'une exécution à l'autre et d'un GPU à l'autre.
