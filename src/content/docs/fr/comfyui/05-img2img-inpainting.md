---
title: '5. Img2img, inpainting et outpainting'
description: 'Partir d''une image plutôt que du bruit — l''envoyer au serveur par l''API, ce que denoise change vraiment dans le planning de bruit, trois façons de repeindre une partie d''une image avec SDXL et ce que chacune fait aux pixels masqués, recoller le résultat pour que le reste de l''image reste intact, et agrandir une toile — avec les rendus comparés sur un GPU et les nœuds de masque vérifiés en CI.'
sidebar:
  order: 5
---

Code : les workflows [`05-img2img.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-img2img.api.json), [`05-inpaint-vaeencode.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json), [`05-inpaint-noisemask.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-noisemask.api.json), [`05-inpaint-model.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json) et [`05-outpaint.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-outpaint.api.json) ; l'envoi de fichier dans [`csharp/ComfyClient.cs`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/csharp/ComfyClient.cs), l'image de masque dans [`csharp/Images.cs`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/csharp/Images.cs), et le workflow que la CI exécute sans modèle dans [`05-masks.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-masks.api.json).

Les leçons 1 à 4 partaient d'un latent vide pour chaque image, et `KSampler` le remplissait de bruit. Cette leçon donne plutôt au sampler une image existante. Le point de départ est le métronome de la leçon 1, graine 42, et chaque rendu ci-dessous utilise SDXL base 1.0 ou sa variante d'inpainting.

## Envoyer une image au serveur

Un workflow ne peut pas lire un fichier sur le disque du client. `LoadImage` lit dans le dossier `input` du serveur, donc un client envoie d'abord le fichier avec `POST /upload/image` : un formulaire multipart avec le fichier dans une partie nommée `image`, et des champs facultatifs `subfolder`, `type` et `overwrite` ([`server.py`, lignes 397 à 467](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L397-L467)). La réponse donne le nom à mettre dans l'entrée `image` de `LoadImage`. Le client du cours fait les deux avec une seule option :

```text
comfy run http://127.0.0.1:8188 workflows/05-img2img.api.json --image 10.image=metronome.png
```

Ce qui se passe quand un nom est déjà pris n'est pas dans la documentation. La CI envoie deux fois le même fichier, puis un fichier différent sous le même nom, puis ce dernier de nouveau avec `overwrite`, puis un fichier dans `../outside` :

```text
POST /upload/image pattern-hole.png: 200, name pattern-hole.png, subfolder "", type input
POST /upload/image pattern-hole.png: 200, name pattern-hole (1).png, subfolder "", type input
POST /upload/image pattern-hole.png: 200, name pattern-hole.png, subfolder "", type input
HttpRequestException: POST /upload/image: 400 
```

La première ligne est le second envoi d'octets identiques : le serveur compare un hachage et garde le fichier existant ([lignes 423 à 432](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L423-L432)). Des octets différents reçoivent un nouveau nom, et un client qui suppose le nom de son propre fichier lirait l'ancienne image. `overwrite` remplace le fichier. Un sous-dossier qui sort du dossier d'entrée est refusé.

### Le masque est la partie transparente

`LoadImage` a deux sorties : l'image, et un masque calculé à partir de son canal alpha comme `1 - alpha` ([`nodes.py`, lignes 1784 à 1790](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1784-L1790)). Les pixels transparents sont ceux à repeindre. Une image sans alpha donne un masque de zéros, de 64 pixels sur 64 quelle que soit la taille de l'image. C'est l'outil du cours qui prépare l'entrée de cette leçon, plutôt qu'un éditeur d'images : `comfy cut` copie une image et rend une ellipse transparente, ici autour des petits objets à l'avant droit de l'établi.

```text
comfy cut metronome.png metronome-hole.png 850 860 120 80
metronome-hole.png: 1024 x 1024, 30176 transparent pixels, pixel SHA-256 051cb95373b4342f
```

Un masque peint en blanc sur noir dans un éditeur d'images n'a pas d'alpha. [`LoadImageMask`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1815-L1856) le lit avec `channel` réglé sur `red`, `green` ou `blue`, et utilise ce canal tel quel ; avec `channel` réglé sur `alpha`, il inverse comme `LoadImage`.

## Img2img : denoise

L'img2img encode l'image avec le VAE et passe ce latent à `KSampler` à la place d'un latent vide. `denoise` décide alors quelle part de l'image survit. La leçon 2 a décrit l'échantillonnage comme un planning de niveaux de bruit, du plus haut jusqu'à zéro. Avec un `denoise` inférieur à 1, [`set_steps`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/samplers.py#L1431-L1441) calcule un planning plus long et n'en garde que la fin :

```python
new_steps = int(steps/denoise)
sigmas = self.calculate_sigmas(new_steps).to(self.device)
self.sigmas = sigmas[-(steps + 1):]
```

`denoise` ne réduit donc pas le travail : avec 25 étapes et un `denoise` de 0,5, ComfyUI construit un planning de 50 étapes et en exécute les 25 dernières, en partant d'un niveau de bruit à mi-chemin. La barre de progression du serveur a montré 25 étapes pour chaque valeur, et les temps étaient les mêmes :

| denoise | Temps, modèles chargés |
|---|---|
| 0,3 | 5,13 s |
| 0,5 | 4,63 s |
| 0,7 | 4,68 s |
| 0,9 | 4,88 s |

![Cinq images côte à côte. La première est la photographie de la leçon 1, un objet en laiton qui ressemble à un sablier sur un établi. Les quatre suivantes sont des versions façon aquarelle : avec un denoise de 0,3 et de 0,5, la composition est identique et le style change ; avec 0,7, la fenêtre et les outils commencent à bouger ; avec 0,9, l'objet est plus simple, les outils sont différents et la fenêtre a une nouvelle forme.](../../../../assets/comfyui/l05-img2img.webp)

*Rendu par ComfyUI v0.36.0 : Stable Diffusion XL base 1.0, graine 42, 25 étapes, CFG 7, `euler`, `normal`, workflow [`05-img2img.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-img2img.api.json) avec le prompt « a watercolor painting of a brass metronome on an old wooden workbench, morning light through a window ». De gauche à droite : l'image de départ, puis `denoise` 0,3, 0,5, 0,7 et 0,9.*

À 0,3 et 0,5, le sampler commence assez tard pour que seuls les textures et les couleurs changent. À 0,9, il part d'un bruit presque pur, et il ne reste que la répartition grossière des zones claires et sombres.

## L'inpainting, de trois façons

L'inpainting repeint la partie masquée et garde le reste. ComfyUI a trois façons de le faire avec SDXL, et elles ne font pas la même chose aux pixels masqués.

| Workflow | Nœuds | Ce dont part le sampler |
|---|---|---|
| `05-inpaint-vaeencode` | `VAEEncodeForInpaint`, modèle de base | l'image avec les pixels masqués passés au gris moyen, `denoise` 1 |
| `05-inpaint-noisemask` | `VAEEncode`, `SetLatentNoiseMask`, modèle de base | l'image inchangée, avec un masque de bruit |
| `05-inpaint-model` | `InpaintModelConditioning`, UNet d'inpainting SDXL | l'image inchangée, et l'image grisée et le masque comme entrées supplémentaires du modèle |

[`VAEEncodeForInpaint`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L412-L450) remplace les pixels masqués par du gris avant d'encoder, et arrondit le masque à 0 ou 1 :

```python
m = (1.0 - mask.round()).squeeze(1)
for i in range(3):
    pixels[:,:,:,i] -= 0.5
    pixels[:,:,:,i] *= m
    pixels[:,:,:,i] += 0.5
```

Son entrée `grow_mask_by` n'élargit que le masque de bruit, pas la zone grise. Ni le [tutoriel d'inpainting](https://docs.comfy.org/tutorials/basic/inpaint) ni la page du nœud ne mentionnent le gris.

Le masque de bruit est ce qui permet au sampler de garder le reste de l'image. À chaque étape, [`KSamplerX0Inpaint`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/samplers.py#L634-L643) place hors du masque le latent d'origine, bruité au niveau courant, et le remet encore dans la sortie du modèle :

```python
x = x * denoise_mask + self.inner_model.inner_model.scale_latent_inpaint(x=x, sigma=sigma, noise=self.noise, latent_image=self.latent_image, denoise_mask=denoise_mask) * latent_mask
out = self.inner_model(x, sigma, model_options=model_options, seed=seed)
if denoise_mask is not None:
    out = out * denoise_mask + self.latent_image * latent_mask
```

Le modèle de base n'a jamais été entraîné à combler un trou : il débruite tout le latent, et le masque jette ce qu'il a fait à l'extérieur. Le modèle [SD-XL inpainting 0.1](https://huggingface.co/diffusers/stable-diffusion-xl-1.0-inpainting-0.1) est un UNet entraîné pour cela, avec « 5 additional input channels (4 for the encoded masked-image and 1 for the mask itself) », c'est-à-dire cinq canaux d'entrée supplémentaires, quatre pour l'image masquée encodée et un pour le masque lui-même. Il fait 5,1 Go en fp16, sous la licence CreativeML Open RAIL++-M comme SDXL, et sa fiche dit « The model is intended for research purposes only. », c'est-à-dire que le modèle est destiné uniquement à la recherche. Il n'a ni encodeurs de texte ni VAE propres, donc le workflow le charge avec `UNETLoader` et prend le reste dans le checkpoint SDXL. ComfyUI le reconnaît à ses 9 canaux d'entrée ([`model_detection.py`, lignes 1465 à 1469](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/model_detection.py#L1465-L1469)). [`InpaintModelConditioning`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L453-L502) construit ces entrées supplémentaires : il grise les pixels masqués comme `VAEEncodeForInpaint`, encode le résultat comme latent supplémentaire, et renvoie l'image **d'origine** encodée comme latent à échantillonner.

L'exemple de la fiche du modèle règle `strength=0.99`, avec le commentaire « make sure to use `strength` below 1.0 », c'est-à-dire de garder `strength` sous 1,0, ce qui correspond à `denoise` dans ComfyUI.

![Six recadrages de l'avant droit de l'établi, chacun de 340 pixels sur 240. L'original a deux petits objets en bois. VAEEncodeForInpaint : les objets ont disparu, et une ellipse pâle avec une autre texture de bois montre où était le masque. Masque de bruit avec un denoise de 1 : une bande bleuâtre uniforme et une petite tache blanche dans une ellipse visible. Masque de bruit avec un denoise de 0,8 : les deux objets sont toujours là, plus sombres et plus durs, avec un contour sombre. Modèle d'inpainting avec un denoise de 0,99 : une cloche en laiton couchée sur le côté et une pièce de bois ronde, dans la même lumière que le reste de l'établi.](../../../../assets/comfyui/l05-inpaint.webp)

*Rendu par ComfyUI v0.36.0 : Stable Diffusion XL base 1.0, et le UNet SD-XL inpainting 0.1 pour le dernier recadrage ; graine 42, 25 étapes, CFG 7, `euler`, `normal`, prompt « a small brass bell on an old wooden workbench, morning light through a window, photograph ». De gauche à droite : l'original, [`05-inpaint-vaeencode`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json), [`05-inpaint-noisemask`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-noisemask.api.json) avec `denoise` 1 et 0,8, et [`05-inpaint-model`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json) avec `denoise` 0,99. Chaque recadrage est le résultat recollé dans l'original.*

- `VAEEncodeForInpaint` a effacé les objets. Le sampler est parti d'une tache grise et a peint du bois uni, et le bord du masque se voit comme un changement de texture.
- Le modèle de base avec un masque de bruit et un `denoise` de 1 n'avait rien sur quoi s'appuyer dans le masque, et a peint quelque chose qui ne correspond ni au prompt ni à l'établi.
- À un `denoise` de 0,8, le même workflow a gardé la forme des objets, et n'a changé que leur teinte.
- Le modèle d'inpainting est le seul qui a dessiné quelque chose de nouveau, une cloche couchée sur le côté, dans la lumière de la scène.

Le même workflow avec un `denoise` de 1,0 au lieu de 0,99 a donné presque la même image : une différence moyenne de 0,016 niveau, et 0,01 % des pixels de plus de 8. L'avertissement de la fiche ne s'est pas vérifié sur cette image.

## Recoller le résultat

Un VAE ne rend pas les pixels qu'on lui a donnés. Chaque workflow ci-dessus décode une image complète de 1024 sur 1024, y compris la partie hors du masque. La commande `compare` du cours ne compte que les pixels opaques d'une image de masque, et peut donc mesurer cette partie :

```text
> comfy compare metronome.png inpaint-model_00001_.png --outside metronome-hole.png
identical pixels: no
compared: 1018400 opaque pixels of the mask
largest difference: 160 of 255, mean 1.888
pixels that differ: 96.34 %, by more than 8: 6.20 %

> comfy compare metronome.png inpaint-model-composite_00001_.png --outside metronome-hole.png
identical pixels: yes
compared: 1018400 opaque pixels of the mask
largest difference: 0 of 255, mean 0.000
pixels that differ: 0.00 %, by more than 8: 0.00 %
```

L'image décodée a changé 6,2 % des pixels que personne n'a demandé de repeindre, surtout sur les contours et les textures fines. La fiche de SD-XL inpainting le signale aussi : « The autoencoding part of the model is lossy. », c'est-à-dire que la partie autoencodeur du modèle perd de l'information. Chaque workflow se termine donc par [`ImageCompositeMasked`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_mask.py#L80-L104), qui prend les pixels décodés dans le masque et les pixels d'origine à l'extérieur. Les deux nœuds SaveImage de chaque workflow enregistrent les deux versions.

## L'outpainting

L'outpainting est de l'inpainting sur une toile plus grande. [`ImagePadForOutpaint`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L2003-L2065) ajoute une bordure remplie de gris, et renvoie un masque qui vaut 1 sur la bordure et 0 sur l'image d'origine. Avec `feathering`, le masque monte aussi à l'intérieur de l'original, près des côtés ajoutés, pour que le sampler puisse modifier une bande des anciens pixels et que la jointure ne se voie pas. Il saute ce fondu quand l'image fait moins de deux fois la largeur du fondu en largeur ou en hauteur ([ligne 2044](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L2044)).

![Une image large, de 1536 pixels sur 1024, réduite : l'objet en laiton sur son établi au milieu, avec un atelier ajouté des deux côtés : des étagères et une lampe à gauche, la fenêtre prolongée et un étau à droite.](../../../../assets/comfyui/l05-outpaint.webp)

*Rendu par ComfyUI v0.36.0 : UNet SD-XL inpainting 0.1 avec les encodeurs de texte et le VAE de SDXL base 1.0, graine 42, 25 étapes, CFG 7, `euler`, `normal`, `denoise` 0,99, workflow [`05-outpaint.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-outpaint.api.json) : 256 pixels ajoutés à gauche et à droite, fondu de 40.*

Le serveur a mis 14,7 secondes pour cette image de 1536 sur 1024, contre 8,0 secondes pour le même modèle en 1024 sur 1024. Le masque fondu est un dégradé, et seuls `InpaintModelConditioning` et `SetLatentNoiseMask` le conservent : `VAEEncodeForInpaint` l'arrondit à 0 ou 1, ce qui transforme le fondu en bord net.

## Ce que vérifie la CI

L'envoi de fichiers et les nœuds de masque n'ont pas besoin de modèle. La CI crée une mire de 64 sur 48 avec une ellipse transparente, l'envoie, et exécute [`05-masks.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-masks.api.json) sur le CPU : le masque de `LoadImage`, `ImagePadForOutpaint`, `ImageCompositeMasked`, et le nœud `Canny` de la leçon 6. Elle compare les empreintes de pixels des quatre autres sorties sous Linux, Windows et macOS :

```text
GET /view node 5: ci/padded_00001_.png, 96 x 56, pixel SHA-256 7ecd793c72d18001
GET /view node 7: ci/padded-mask_00001_.png, 96 x 56, pixel SHA-256 85051ce419e3c75f
GET /view node 3: ci/mask_00001_.png, 64 x 48, pixel SHA-256 7d894dc1b0ac1189
GET /view node 10: ci/composite_00001_.png, 64 x 48, pixel SHA-256 8b6753a52c0f4a66
```

Lu avec Pillow, le masque vaut 255 dans l'ellipse et 0 à l'extérieur, avec une courte rampe là où `comfy cut` a adouci l'alpha. Le remplissage est un gris de 127. En travers du bord gauche de l'image d'origine, le masque agrandi passe par 255, 113, 28 et 0, une valeur tous les 4 pixels : c'est le `feathering` de 12 à l'œuvre. L'empreinte de Canny est affichée mais pas comparée, parce qu'elle diffère d'une machine à l'autre, comme l'explique la leçon 6.

## Points clés

- Envoie les images d'entrée avec `POST /upload/image`, et utilise le nom que renvoie le serveur : des octets identiques gardent le nom existant, des octets différents en reçoivent un nouveau.
- `LoadImage` fabrique son masque à partir de la transparence, comme `1 - alpha`. Un masque noir et blanc sans alpha passe par `LoadImageMask` avec un canal de couleur.
- `denoise` fait démarrer le sampler en cours de route dans un planning plus long. Il change la part de l'image qui survit, pas le nombre d'étapes exécutées.
- `VAEEncodeForInpaint` grise les pixels masqués et demande un `denoise` de 1. Un masque de bruit garde l'image qu'il recouvre. Un modèle d'inpainting, alimenté par `InpaintModelConditioning`, est celui qui peint quelque chose de nouveau en contexte.
- Le VAE modifie les pixels partout : recolle le résultat avec `ImageCompositeMasked`.

## À toi de jouer

Prends une photo à toi et efface quelque chose avec chacune des trois voies, sur le même masque et la même graine. Compare les résultats hors du masque avec `compare` : la voie compte moins que de savoir quels pixels tu as gardés. Repeins ensuite la même zone à denoise 0,4, 0,7 et 1, et note où ton sujet cesse d'être reconnaissable.

## Exercices

1. Avec 20 étapes et un `denoise` de 0,4, combien de niveaux de bruit `set_steps` calcule-t-il, combien en garde-t-il, et combien d'étapes s'exécutent ?
2. Rends `05-inpaint-vaeencode` avec un `denoise` de 0,5. À quoi t'attends-tu dans le masque, et pourquoi ?
3. Fabrique un masque à bord adouci, avec le dernier argument de `comfy cut` réglé à 24 pixels, et exécute `05-inpaint-model` et `05-inpaint-vaeencode` dessus. Lequel garde le bord adouci ?

<details>
<summary>Solution 1</summary>

`int(20 / 0.4)` vaut 50, donc il calcule le planning de 50 étapes, qui a 51 niveaux de bruit, et en garde les 21 derniers. Le sampler exécute 20 étapes entre ces 21 niveaux, en partant du niveau où aurait été l'étape 30 du planning de 50 étapes.

</details>

<details>
<summary>Solution 2</summary>

Les pixels masqués étaient gris avant l'encodage, et un `denoise` de 0,5 part d'un niveau où les grandes formes de l'image sont conservées. Le sampler devrait donc garder une tache grise dans le masque. Le rendu l'a confirmé, et plus nettement que prévu : une ellipse grise uniforme avec seulement un léger ombrage, et aucune texture de bois. À la moitié de la plage de bruit, SDXL a traité le gris comme une partie de l'image.

</details>

<details>
<summary>Solution 3</summary>

```text
comfy cut metronome.png metronome-soft.png 850 860 120 80 24
```

`InpaintModelConditioning` transmet le masque tel quel, donc le masque de bruit du sampler garde le dégradé, et la composition fond les deux images à travers lui. `VAEEncodeForInpaint` arrondit le masque, donc le résultat a un bord net là où l'alpha passe la moitié.

Les rendus, graine 42, le confirment. Avec le modèle d'inpainting, deux nouveaux objets en bois sont posés sur l'établi, et aucun bord ne se voit, même dans l'image décodée avant la composition. Avec `VAEEncodeForInpaint`, l'image décodée a une ellipse nette de bois pâle et plus rugueux, avec un liseré sombre le long de son bord supérieur.

</details>

## Sources

- Documentation de ComfyUI : [image vers image](https://docs.comfy.org/tutorials/basic/image-to-image), [inpainting](https://docs.comfy.org/tutorials/basic/inpaint), [outpainting](https://docs.comfy.org/tutorials/basic/outpaint), [routes du serveur](https://docs.comfy.org/development/comfyui-server/comms_routes).
- ComfyUI à la v0.36.0 : [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), [`comfy/samplers.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/samplers.py), [`comfy_extras/nodes_mask.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_mask.py), [`comfy/model_detection.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/model_detection.py), [`server.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py).
- Fiche du modèle : [SD-XL Inpainting 0.1](https://huggingface.co/diffusers/stable-diffusion-xl-1.0-inpainting-0.1).
