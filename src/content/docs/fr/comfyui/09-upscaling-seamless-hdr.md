---
title: '9. Agrandissement, textures raccordables et HDR'
description: 'Rendre les images plus grandes, raccordables et plus profondes — un modèle d''agrandissement à côté des redimensionnements nearest et Lanczos, le hires fix dans l''espace des pixels et dans l''espace latent et ce que denoise y change, le décodage par tuiles, une texture de bois raccordable faite uniquement avec des nœuds du cœur, et ce que contiennent les fichiers PNG 16 bits, EXR linéaire et AVIF HLG quand ils viennent d''un modèle de diffusion, mesuré sur un GPU.'
sidebar:
  order: 9
---

Code : les workflows [`09-upscale-model.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-upscale-model.api.json), [`09-hires-fix.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-hires-fix.api.json), [`09-latent-upscale.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-latent-upscale.api.json), [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-seamless.api.json) et [`09-exr.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-exr.api.json) ; le décodeur de PNG 16 bits dans [`csharp/Png.cs`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/csharp/Png.cs).

Z-Image-Turbo dessine des images de 1024 × 1024. Un tirage, un fond d'écran ou une texture sur le manche d'une guitare en 3D demande plus de pixels, des bords qui se répètent sans raccord visible, ou plus de 8 bits par canal. Cette leçon fait chacune de ces choses avec des nœuds du cœur, et vérifie ce que contiennent vraiment les fichiers.

Les rendus ont tourné sur une RTX 5080 avec ComfyUI v0.36.0. La règle de RAM de la leçon 8 a choisi le modèle à chaque démarrage : Z-Image-Turbo nvfp4 avec l'encodeur de texte fp4 quand 22 Go de RAM étaient libres, int8 avec fp8 quand il y en avait 24 Go. Chaque légende nomme celui qu'elle a utilisé.

## Les modèles d'agrandissement

Un modèle d'agrandissement est un petit réseau convolutif entraîné à transformer une petite image en une image plus grande et plus nette. ComfyUI le charge avec [`UpscaleModelLoader`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_upscale_model.py#L20-L47), depuis le dossier `models/upscale_models`, par la bibliothèque [spandrel](https://github.com/chaiNNer-org/spandrel), et l'exécute avec `ImageUpscaleWithModel`, « Upscale Image (using Model) ». Aucun modèle de diffusion n'intervient, et le prompt ne joue aucun rôle.

Le cours utilise [Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN) x4plus, le modèle du blueprint de ComfyUI *Image Upscale (Z-image-Turbo)*. Comfy-Org le reconditionne sous le nom `RealESRGAN_x4plus.safetensors`, 66 857 836 octets, dans [Comfy-Org/Real-ESRGAN_repackaged](https://huggingface.co/Comfy-Org/Real-ESRGAN_repackaged). Sa licence est BSD-3-Clause.

Les licences comptent ici aussi. Le README de spandrel dit que le paquet « only contains architectures with permissive and public domain licenses », qu'il ne contient que des architectures sous licences permissives ou dans le domaine public, mais cela couvre son code, pas les poids : 4x-UltraSharp, un modèle ESRGAN populaire, est sous CC BY-NC-SA 4.0, non commerciale, d'après [OpenModelDB](https://openmodeldb.info/models/4x-UltraSharp). Le [tutoriel sur l'agrandissement](https://docs.comfy.org/tutorials/basic/upscale) de la documentation utilise un autre fichier, 4x-ESRGAN d'OpenModelDB, au format `.pth`.

Le nœud travaille par tuiles : [512 pixels avec 32 de recouvrement](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_upscale_model.py#L79-L95), en divisant la taille des tuiles par deux après chaque erreur de mémoire insuffisante, jusqu'à 128. La taille n'a pas d'entrée dans l'interface.

`09-upscale-model.api.json` découpe un détail de 256 × 256 dans un rendu et l'agrandit quatre fois de trois façons :

![Trois recadrages de 512 × 512 du même manche de guitare devant un mur de briques, agrandis quatre fois. Nearest : des blocs carrés de quatre pixels sur les cordes et les frettes. Lanczos : lisse mais flou, avec de légers halos le long des frettes. Real-ESRGAN : des frettes et des cordes nettes, une brique plus plate, et le fil des frettes dessiné en lignes claires et propres.](../../../../assets/comfyui/l09-upscale-methods.webp)

*Rendu par ComfyUI v0.36.0 : le détail en (384, 384) du premier rendu de la section suivante, agrandi 4 × avec `ImageScaleBy` `nearest-exact`, `ImageScaleBy` `lanczos`, et `ImageUpscaleWithModel` avec `RealESRGAN_x4plus.safetensors`, workflow [`09-upscale-model.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-upscale-model.api.json). Chaque panneau montre les 512 × 512 pixels du milieu du résultat de 1024 × 1024, à l'échelle 1:1.*

Le modèle d'agrandissement invente des contours plausibles ; Lanczos ne fait qu'interpoler. L'exécution a pris 2,08 secondes, chargement du modèle compris.

## Le hires fix

Un modèle d'agrandissement rend plus net ce qui est là ; il n'ajoute pas de détail. Le *hires fix* en ajoute : « Hires fix is just creating an image at a lower resolution, upscaling it and then sending it through img2img », dit l'[exemple en deux passes](https://comfyanonymous.github.io/ComfyUI_examples/2_pass_txt2img/) de ComfyUI, c'est-à-dire créer une image à une résolution plus basse, l'agrandir, puis la faire passer par l'img2img. La deuxième passe est l'img2img de la leçon 5, avec un denoise bas, sur l'image agrandie.

`09-hires-fix.api.json` suit le blueprint *Image Upscale (Z-image-Turbo)* :

1. Z-Image-Turbo dessine une image de 1024 × 1024, comme dans la leçon 8.
2. Real-ESRGAN l'agrandit à 4096 × 4096, et `ImageScaleBy` `lanczos` 0,5 la ramène à 2048 × 2048.
3. `VAEEncode`, puis un `KSampler` avec 5 étapes, CFG 1, `dpmpp_2m_sde`, `beta` et un denoise de 0,33, les valeurs du blueprint.
4. `VAEDecodeTiled` décode le latent de 2048 × 2048 en tuiles de 1024 pixels.

Le deuxième prompt du blueprint est « masterpiece, 8k » ; le workflow garde plutôt le premier prompt.

![Quatre panneaux. D'abord, le rendu entier de 1024 × 1024 : une guitare acoustique appuyée contre un mur de briques à côté d'une vitrine avec d'autres guitares. Puis le même recadrage de 512 × 512 de trois versions en 2048 × 2048 : Lanczos, flou ; Real-ESRGAN, des cordes et des briques nettes ; hires fix, avec un nouveau veinage du bois, une nouvelle texture de brique et les repères de frettes déplacés.](../../../../assets/comfyui/l09-hires-fix.webp)

*Rendu par ComfyUI v0.36.0 : Z-Image-Turbo nvfp4 avec Qwen3 4B fp4 mixed, graine 42, 8 étapes, CFG 1, `res_multistep`, `simple`, shift 3, prompt « an acoustic guitar leaning against a brick wall in a small music shop, warm evening light, photograph », workflow [`09-hires-fix.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-hires-fix.api.json). De gauche à droite : la première passe ; le recadrage de (768, 768) à (1280, 1280) de Lanczos 2 ×, de Real-ESRGAN puis Lanczos 0,5, et du hires fix avec un denoise de 0,33 et la graine 42.*

Regarde le manche : le hires fix ajoute du veinage et de la texture, et déplace aussi les repères de frettes. Le denoise décide de ce qu'il a le droit de changer :

![Quatre recadrages de 512 × 512 de la tête et du manche de la guitare devant le mur de briques, après le hires fix avec un denoise de 0,2, 0,33, 0,5 et 0,7. À 0,2, l'image est l'image agrandie avec un peu plus de texture. À 0,33, les briques gagnent du grain. À 0,5, les joints de mortier et les taches des briques changent. À 0,7, la tête est redessinée avec d'autres mécaniques, et le manche est plus étroit.](../../../../assets/comfyui/l09-hires-denoise.webp)

*Rendu par ComfyUI v0.36.0 : le même workflow et la même première passe, deuxième passe avec un denoise de 0,2, 0,33, 0,5 et 0,7, recadrage de (768, 256) à (1280, 768).*

### Temps et mémoire

En 1024 × 1024, une étape prenait environ 0,3 seconde. En 2048 × 2048, une étape prenait de 2,2 à 2,8 secondes : quatre fois plus de pixels, et environ huit fois plus de temps. Les couches d'attention comparent chaque patch à tous les autres, donc leur coût croît avec le carré du nombre de patchs. Avec le modèle chargé, le workflow entier avec une nouvelle graine a pris 26,4 secondes ; changer seulement le denoise de la deuxième passe a pris 16,4 secondes, parce que ComfyUI a réutilisé la première passe et l'agrandissement mis en cache (leçon 4).

`VAEDecodeTiled` n'est pas nécessaire ici pour la mémoire. Le même graphe avec un simple `VAEDecode` s'est exécuté sans l'avertissement « Ran out of memory when regular VAE decoding, retrying with tiled VAE decoding » que ComfyUI affiche [quand il se rabat sur le décodage par tuiles](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/sd.py#L1267), c'est-à-dire que la mémoire a manqué pour le décodage VAE normal et qu'il réessaie par tuiles. Les deux images diffèrent en moyenne de 0,93 niveau par canal, au plus de 29 sur 255, et de plus de 8 niveaux sur 0,02 % des pixels : le fondu entre tuiles de [`VAEDecodeTiled`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L343-L378) est proche, pas identique. Garde-le pour les images en 4K, la vidéo ou un GPU plus petit.

### Dans l'espace latent

Le hires fix plus ancien saute les pixels : [`LatentUpscaleBy`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1369-L1388) agrandit le latent lui-même, ici avec `bislerp`, et un deuxième `KSampler` échantillonne avec un denoise de 0,3, 0,55 ou 0,75.

![Trois recadrages de 512 × 512 de la même tête et du même manche après un agrandissement latent et une deuxième passe avec un denoise de 0,3, 0,55 et 0,75. À 0,3, l'image est couverte d'un grain fin et bruité, et les cordes sont dédoublées. À 0,55, elle est propre, avec la brique redessinée. À 0,75, la tête et les repères de frettes sont redessinés.](../../../../assets/comfyui/l09-latent-denoise.webp)

*Rendu par ComfyUI v0.36.0 : Z-Image-Turbo nvfp4, même première passe, `LatentUpscaleBy` `bislerp` 2 ×, deuxième `KSampler` avec 8 étapes, `res_multistep`, `simple`, denoise de 0,3, 0,55 et 0,75, workflow [`09-latent-upscale.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-latent-upscale.api.json).*

Un latent agrandi n'est pas un latent que le VAE aurait pu produire : avec un denoise de 0,3, il ne reste pas assez d'étapes au sampler pour le nettoyer, et le grain reste. Il lui faut environ 0,55, ce qui change aussi une plus grande part de l'image. Le chemin par les pixels garde la composition avec un denoise plus bas, au prix d'un modèle d'agrandissement. La deuxième passe a pris ici 17,8 secondes, avec 8 étapes en 2048 × 2048.

Pour les grandes images en morceaux, le cœur a aussi `SplitImageToTileList` et `ImageMergeTileList`, qui fondent les tuiles avec une fenêtre sinusoïdale ; échantillonner chaque tuile puis les fusionner est *à vérifier*. Les nœuds de diffusion par tuiles comme *Ultimate SD Upscale* sont des nœuds personnalisés (leçon 11).

## Les textures raccordables

Une texture se raccorde quand son bord droit prolonge son bord gauche, et son bord inférieur son bord supérieur. Un rendu ne le fait pas : le répéter en 2 × 2 fait apparaître une grille. Certains outils font boucler les convolutions du modèle autour de l'image ; le cœur de ComfyUI n'a pas d'option de ce genre dans la v0.36.0. Un remplissage `circular` apparaît dans [`pad_to_patch_size`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/ldm/common_dit.py#L5-L13), pour le découpage en patchs, là où aucune entrée n'y donne accès.

Le contournement classique fonctionne avec des nœuds du cœur :

1. **Décaler de moitié.** Quatre nœuds `ImageCropV2` découpent les quarts, et trois nœuds `ImageStitch` les échangent. Les anciens bords se rencontrent maintenant en croix au milieu, et les nouveaux bords étaient voisins dans le rendu, donc ils se raccordent.
2. **Masquer la croix.** `SolidMask`, `FeatherMask` et `MaskComposite` construisent une croix douce, de 384 pixels de large avec 128 pixels de fondu de chaque côté.
3. **Repeindre la croix.** `VAEEncode` et `SetLatentNoiseMask` (leçon 5), puis un `KSampler` avec un denoise de 1,0 et le même prompt.
4. **Garder les bords.** `ImageCompositeMasked` recolle les pixels repeints à travers le masque, pour que les bords restent exactement tels qu'ils étaient.

![Quatre panneaux de 384 × 384. Une texture de palissandre au veinage vertical. La même texture décalée de moitié, avec un raccord horizontal et vertical visible au milieu. Un carré noir avec une croix blanche, douce sur ses bords. Le résultat, où le milieu montre un veinage continu et aucune ligne nette.](../../../../assets/comfyui/l09-seamless-steps.webp)

*Rendu par ComfyUI v0.36.0 : Z-Image-Turbo int8 convrot avec Qwen3 4B fp8 mixed, graine 42 pour les deux passes, 8 étapes, CFG 1, `res_multistep`, `simple`, prompt « flat top-down photograph of dark rosewood, fine straight grain, even soft lighting, no shadows, wood texture », une photographie à plat, vue de dessus, de palissandre sombre au veinage fin et droit, workflow [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-seamless.api.json). De gauche à droite : le rendu, le décalage, le masque, le résultat.*

Le workflow assemble aussi chaque texture en 2 × 2, pour vérifier le raccord à l'œil :

![Quatre aperçus en mosaïque, chacun une répétition en 2 × 2. Le palissandre tel que rendu : une grille nette de raccords durs. Le palissandre après la réparation : aucun raccord dur, avec des blocs un peu plus sombres et plus clairs encore visibles. L'érable pâle tel que rendu : une grille de raccords. L'érable après la réparation : aucun raccord dur, avec de douces bandes verticales de bois plus clair et plus sombre.](../../../../assets/comfyui/l09-seamless.webp)

*Rendu par ComfyUI v0.36.0 : le même workflow et le même modèle. De gauche à droite : le palissandre tel que rendu, puis réparé ; l'érable, prompt « flat top-down photograph of pale maple wood, a planed board with fine straight grain, even soft lighting, wood texture », tel que rendu, puis réparé. Chaque panneau est une répétition de 2048 × 2048 affichée en 512 × 512.*

Pour mesurer un raccord, compare le saut à travers lui avec le saut entre des pixels voisins ordinaires. La différence absolue moyenne entre deux colonnes adjacentes, en niveaux sur 255 :

| Palissandre, int8 | Rangée du milieu | Colonne du milieu | Rangées voisines typiques | Colonnes voisines typiques |
|---|---|---|---|---|
| Décalé, avant la réparation | 9,41 | 10,35 | 3,08 | 5,66 |
| Réparé, denoise 0,85 | 3,58 | 5,81 | 3,04 | 5,51 |
| Réparé, denoise 1,0 | 3,67 | 5,68 | 3,03 | 5,56 |

Les raccords sont redescendus à la variation propre de la texture. Ce que les nombres ne montrent pas, c'est le ton : les moitiés venaient de parties du rendu de luminosité moyenne différente, et la retouche les fond sur 384 pixels au lieu de supprimer la différence. Sur l'érable, la colonne du milieu saute encore de 9,88 contre 5,71 pour ses voisines : son veinage est lisse, donc la marche se voit. Un prompt qui demande un matériau uniforme, éclairé de façon égale, aide plus que n'importe quel réglage.

La première tentative, avec une croix de 160 pixels, 64 pixels de fondu et un denoise de 0,7, a laissé une ligne mouchetée et une marche visible : le journal la montre.

## Le HDR, et ce que contiennent les fichiers

Un modèle de diffusion dessine dans la plage du VAE : l'étape de sortie par défaut [ramène chaque pixel entre 0 et 1](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/sd.py#L507-L508). Le PNG 8 bits de `SaveImage` [arrondit cette plage à 256 niveaux](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1698-L1699). `SaveImageAdvanced`, « Save Image (Advanced) », [en écrit davantage](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_images.py#L1725-L1881) :

- **PNG**, 8 ou 16 bits par canal, sRGB.
- **EXR**, flottant 32 bits. `input_color_space` dit ce que sont les pixels : le sRGB est converti en lumière linéaire, `HDR` est décodé depuis le HLG, et `linear` est écrit tel quel.
- **AVIF**, 8 ou 10 bits, sRGB, `HDR` (BT.2020 avec HLG) ou `HDR PQ`.

Au format API, les options d'une entrée dynamique ont des noms avec des points : `"format": "exr"`, `"format.bit_depth": "32-bit float"`, `"format.input_color_space": "sRGB"`.

`09-exr.api.json` enregistre le rendu de 1024 × 1024 du hires fix de trois façons. [`ImageColorSpace`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_images.py#L1111-L1179) le convertit en HLG avant l'AVIF. Les fichiers ont été relus avec PyAV, depuis le Python de la version portable :

| Fichier | Taille | Ce qu'il contient |
|---|---|---|
| `SaveImage`, PNG 8 bits | 1 623 741 octets | 256 niveaux par canal |
| PNG 16 bits | 1 922 698 octets | `rgb48be`, et toujours 256 niveaux distincts dans le canal rouge |
| EXR, entrée sRGB | 12 600 735 octets | `gbrpf32le`, non compressé, minimum 0,0, maximum 1,0, aucune valeur au-dessus de 1 |
| AVIF, HLG | 117 350 octets | `yuv420p10le`, primaires 9 (BT.2020), transfert 18 (HLG) |

Les fichiers plus profonds contiennent les mêmes 256 niveaux. Un PNG 16 bits ou un EXR flottant est utile comme entrée d'une étape ultérieure qui travaille en flottant, comme l'étalonnage des couleurs. Une lumière plus vive que le blanc ne vient pas du modèle : rien dans l'EXR ne dépasse 1,0, qui, dans la convention de ComfyUI, est le blanc de référence à 203 nits du sRGB. La description du nœud le dit : « Linear 1.0 uses the same 203-nit reference white as sRGB; HLG uses a 1000-nit reference display. », le 1,0 linéaire utilise le même blanc de référence à 203 nits que le sRGB, et le HLG un écran de référence à 1000 nits.

Deux pièges :

- `LatentOperationTonemapReinhard`, trouvé en cherchant « hdr latent », applique un tone mapping [au vecteur de guidage](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_latent.py#L373-L407), pour dompter un CFG élevé. Il ne produit aucun pixel HDR.
- **`LoadImage` peut ne pas lister l'EXR qu'il vient d'enregistrer, et cela dépend de la machine.** [Le filtre](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/folder_paths.py#L229-L253) demande à `mimetypes` de Python le type de chaque fichier et garde ceux qui commencent par `image` ; or `mimetypes` lit la table du système d'exploitation : le registre sous Windows, des fichiers comme `/etc/mime.types` ailleurs. Mesuré par [`data/mime-info.py`](https://github.com/spareilleux/learn/blob/main/code/comfyui/data/mime-info.py) sur trois machines, toutes en Python 3.13 : sur cette machine Windows et sur l'exécuteur `macos-latest`, `.exr` n'a **aucun** type MIME, donc la liste l'écarte ; sur l'exécuteur `ubuntu-latest`, il vaut `image/aces`, et la liste le garde. Même ComfyUI, même workflow, liste différente. `.glb` se partage de la même façon, et `.flac` vaut `audio/flac` sur ce Linux et `audio/x-flac` sur les deux autres — les deux commencent par `audio`, donc celui-là ne change rien. C'est ce qui compte quand un workflow est partagé : un fichier construit sur une machine où `.exr` a un type MIME désigne une image que la même liste refuse de proposer ailleurs — le workflow reste valide, mais il n'est plus reproductible. S'il faut relire un EXR, passe-le par son chemin depuis ton propre nœud, ou ajoute le type à la machine.

### Dans three.js

three.js lit ces fichiers. [EXRLoader](https://threejs.org/docs/pages/EXRLoader.html) prend en charge l'EXR non compressé, tel que ComfyUI l'écrit, et le charge par défaut en `HalfFloatType` ; charger ce fichier dans un navigateur est *à vérifier*. Pour les fichiers `.hdr`, `RGBELoader` est déprécié depuis r180 : utilise [HDRLoader](https://threejs.org/docs/pages/HDRLoader.html). Pour une texture de couleur, un PNG 8 bits avec `texture.colorSpace = SRGBColorSpace` suffit en général ; [MeshStandardMaterial](https://threejs.org/docs/pages/MeshStandardMaterial.html) attend les cartes de données comme `normalMap` en `NoColorSpace`. La leçon 13 construit de telles textures pour le site.

## Points clés

- Un modèle d'agrandissement rend l'image plus nette sans prompt ; vérifie la licence de ses poids, pas seulement celle de son architecture.
- Le hires fix ajoute du détail avec une deuxième passe d'img2img. Un denoise de 0,2 à 0,35 garde la composition dans l'espace des pixels ; un agrandissement latent demande environ 0,55 et change davantage.
- En 2048 × 2048, chaque étape a pris environ huit fois plus de temps qu'en 1024 × 1024.
- Le cœur de ComfyUI n'a pas de convolution qui boucle : décale la texture de moitié, repeins une croix douce, recolle-la à travers le masque, et mesure les raccords.
- Un PNG 16 bits, un EXR flottant ou un AVIF HLG fait à partir d'un rendu ne contient aucune lumière au-delà du blanc : la sortie du VAE est ramenée entre 0 et 1.

## À toi de jouer

Fais une texture raccordable pour quelque chose à toi : le bois d'une touche, un pickguard en métal brossé, un tissu de grille de haut-parleur. Rends-la, exécute `09-seamless.api.json` avec ton prompt et `--set 5.text=...`, et assemble-la en 2 × 2. Puis essaie de la casser : un prompt avec un grand motif, comme « a single knot in the middle », un seul nœud au milieu, et regarde ce que la croix en fait.

## Exercices

1. Tu agrandis un rendu de 1024 × 1024 en 2048 × 2048 pour un tirage. Quel chemin garde exactement la composition, lequel ajoute du détail, et que coûte chacun ?
2. Un collègue enregistre un rendu de Z-Image-Turbo en EXR 32 bits et te demande de l'utiliser comme carte d'environnement HDR, « puisque c'est du HDR ». Que lui réponds-tu ?
3. Dans `09-seamless.api.json`, pourquoi `ImageCompositeMasked` recolle-t-il l'image repeinte à travers le masque, au lieu d'enregistrer la sortie de `VAEDecode` ?

<details>
<summary>Solution 1</summary>

Lanczos ou un modèle d'agrandissement garde chaque forme à sa place : Lanczos est instantané et flou, Real-ESRGAN a pris environ 2 secondes ici et rend les contours plus nets. Le hires fix ajoute du détail en échantillonnant de nouveau en 2048 × 2048, à environ 2,5 secondes par étape sur ce GPU, et déplace les petits éléments : avec un denoise de 0,33, les repères de frettes ont bougé. Pour un tirage de cette guitare, Real-ESRGAN puis un hires fix de 0,2 à 0,3 est un bon point de départ ; compare les recadrages avant de choisir.

</details>

<details>
<summary>Solution 2</summary>

Le conteneur est HDR, le contenu ne l'est pas. Le VAE ramène sa sortie entre 0 et 1, donc le pixel le plus lumineux vaut 1,0, le blanc sRGB : la lumière chaude de l'image n'est pas plus vive qu'un mur blanc, et une carte d'environnement faite à partir d'elle éclaire une scène comme une image sRGB plate. L'EXR reste utile pour l'étalonnage en flottant. Un vrai environnement HDR demande une lumière mesurée ou rendue, par exemple une photo en bracketing ou un rendu 3D, *à vérifier* avec ton moteur de rendu.

</details>

<details>
<summary>Solution 3</summary>

`SetLatentNoiseMask` limite le bruit à la zone masquée, mais l'image entière passe quand même par `VAEEncode` et `VAEDecode`, et le VAE modifie légèrement chaque pixel : la leçon 5 l'a mesuré hors du masque. Les bords doivent rester exactement tels qu'ils étaient, parce que ce sont eux qui se raccordent. Recoller à travers le masque prend les pixels non masqués dans l'image décalée, intacts.

</details>

## Sources

- X. Wang, L. Xie, C. Dong et Y. Shan, [Real-ESRGAN: Training Real-World Blind Super-Resolution with Pure Synthetic Data](https://arxiv.org/abs/2107.10833), 2021.
- Documentation de ComfyUI : [tutoriel sur l'agrandissement](https://docs.comfy.org/tutorials/basic/upscale), [ImageColorSpace](https://docs.comfy.org/built-in-nodes/ImageColorSpace) ; exemples de ComfyUI : [2 pass txt2img](https://comfyanonymous.github.io/ComfyUI_examples/2_pass_txt2img/).
- ComfyUI à la v0.36.0 : [`comfy_extras/nodes_upscale_model.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_upscale_model.py), [`comfy_extras/nodes_images.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_images.py), [`comfy_extras/nodes_latent.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_latent.py), [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), [`comfy/sd.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/sd.py), [`folder_paths.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/folder_paths.py).
- Modèles : [xinntao/Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN), [Comfy-Org/Real-ESRGAN_repackaged](https://huggingface.co/Comfy-Org/Real-ESRGAN_repackaged), [OpenModelDB 4x-UltraSharp](https://openmodeldb.info/models/4x-UltraSharp), [chaiNNer-org/spandrel](https://github.com/chaiNNer-org/spandrel).
- three.js : [EXRLoader](https://threejs.org/docs/pages/EXRLoader.html), [HDRLoader](https://threejs.org/docs/pages/HDRLoader.html), [MeshStandardMaterial](https://threejs.org/docs/pages/MeshStandardMaterial.html).
