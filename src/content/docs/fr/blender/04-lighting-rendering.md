---
title: 4. Lumières, caméras, et rendu avec EEVEE et Cycles
description: 'Les lumières de surface en watts et l''éclairage trois points, une caméra orientée par le code, la transformation de vue AgX, puis les deux moteurs de rendu — EEVEE, un rastériseur, et Cycles, un path tracer — avec le bruit de Cycles mesuré en fonction du nombre d''échantillons, une graine qui donne les mêmes pixels sous Windows, Linux et macOS, l''échantillonnage adaptatif, OpenImageDenoise, et des durées sur CPU, sur GPU et avec EEVEE sur une machine.'
sidebar:
  order: 4
---

Code : le script de la leçon, [`scripts/l04_render.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/l04_render.py), la scène dans [`scripts/stage.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/stage.py), les images dans [`scripts/render_images.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/render_images.py), et le rapport, [`expected/l04_render.txt`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/expected/l04_render.txt).

## Les lumières

Blender a quatre [types de lumières](https://docs.blender.org/manual/en/5.2/render/lights/light_object.html) : **point**, **spot**, **area** (surface) et **sun** (soleil). La puissance d'une lumière point, spot ou de surface est en watts, et l'intensité d'un soleil en watts par mètre carré, puisqu'il éclaire tout depuis une distance infinie. Ce sont des watts de puissance rayonnée, la lumière réellement émise, pas les watts électriques inscrits sur la boîte d'une ampoule. La lumière d'une source point, spot ou de surface décroît avec le carré de la distance.

Une **lumière de surface** émet depuis un rectangle ou un disque. Plus elle est grande par rapport à sa distance à l'objet, plus les ombres sont douces et les reflets larges, comme avec la softbox d'un photographe. La taille ne change pas la puissance : une lumière plus grande à la même puissance la répartit sur une plus grande surface.

[`stage.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/stage.py) éclaire la touche comme un studio éclaire un produit, avec un **éclairage trois points** : une lumière *principale* (key) qui donne la forme et les ombres principales, une lumière *de remplissage* (fill) plus faible de l'autre côté qui débouche les ombres, et une lumière *de contour* (rim) à l'arrière qui détache les bords sur le fond :

```text
== Lights and camera
Fill: AREA 0.6 W size 0.50 m color (0.85, 0.90, 1.00) location (0.35, 0.45, 0.25)
Key: AREA 3.0 W size 0.25 m color (1.00, 0.95, 0.88) location (0.05, -0.45, 0.45)
Rim: AREA 4.0 W size 0.10 m color (1.00, 1.00, 1.00) location (-0.25, 0.20, 0.12)
camera: lens 50.0 mm sensor 36.0 mm horizontal field of view 39.6 degrees location (-0.120, -0.200, 0.140)
world background: (0.020, 0.020, 0.025) strength 1.00
```

La lumière principale est légèrement chaude et celle de remplissage légèrement froide, un choix courant. Les watts semblent faibles parce que la scène est petite : les lumières sont à 30 à 65 cm d'une touche de 48 cm de long. La première version utilisait 12, 3 et 15 W, et le rendu était si lumineux que le palissandre paraissait gris. Le **world** (monde) est l'environnement autour de la scène : ici un gris sombre, presque noir, qui éclaire aussi un peu la scène depuis toutes les directions.

Les lumières et les caméras regardent le long de leur axe local −Z. Le script les oriente avec un quaternion :

```python
def aim(obj, target):
    """Points an object's -Z axis (where cameras and lights look) at a target, with +Y up."""
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
```

Une contrainte **Track To** fait la même chose et suit la cible quand elle bouge ; la leçon 7 couvre les contraintes. L'objectif de 50 mm de la caméra sur le capteur par défaut de 36 mm donne un champ de vision horizontal de 2 × atan(18 / 50) = 39,6°, un objectif « normal » en photographie.

## Des valeurs de lumière aux pixels : la transformation de vue

Un moteur de rendu calcule des valeurs **scene-referred** (relatives à la scène) : des quantités linéaires de lumière, de 0 à bien au-dessus de 1 dans une zone très lumineuse. Un écran affiche des valeurs **display-referred** (relatives à l'affichage) : 8 bits par canal, en sRGB. La [transformation de vue](https://docs.blender.org/manual/en/5.2/render/color_management/displays_views.html) (view transform) convertit les unes en les autres :

```text
== Color management
display device sRGB | view transform AgX | look None | exposure 0.0 | gamma 1.0
```

La valeur par défaut, **AgX**, est une courbe de tone mapping que le manuel présente comme une amélioration de Filmic, avec 16,5 stops de plage dynamique, et qui désature les couleurs très lumineuses comme le fait la pellicule. **Standard** n'applique que la courbe sRGB et écrête tout ce qui dépasse 1. Le choix change le PNG et l'image à l'écran, mais pas les valeurs linéaires que garde un fichier EXR (exercice 3). three.js a le même pipeline et propose aussi AgX ([leçon 3 de three.js](../../threejs/03-color-tone-mapping-environments/)).

## Deux moteurs de rendu

Blender 5.2 livre trois moteurs, `BLENDER_EEVEE`, `BLENDER_WORKBENCH` et `CYCLES`. Workbench dessine l'ombrage solide du viewport. Les deux autres rendent les mêmes scènes et les mêmes nœuds de shader, de deux façons différentes :

- **[EEVEE](https://docs.blender.org/manual/en/5.2/render/eevee/index.html)** est un **rastériseur** (rasterizer), comme un moteur de jeu ou three.js : il dessine chaque triangle sur le GPU et approxime les ombres, les reflets et la lumière indirecte avec des techniques dont le coût par image est fixe. Il est rapide et interactif, et il rend par le GPU, y compris en arrière-plan : la CI du cours, qui n'a pas de GPU, ne l'exécute pas (*à vérifier* : EEVEE sur une machine sans GPU).
- **[Cycles](https://docs.blender.org/manual/en/5.2/render/cycles/index.html)** est un **path tracer** (traceur de chemins) : pour chaque pixel, il suit des chemins de lumière aléatoires à travers la scène, qui rebondissent sur les surfaces, et en fait la moyenne. Il est physiquement réaliste : les ombres douces, les reflets et la lumière indirecte sont justes sans astuces, mais le résultat est bruité tant que la moyenne ne porte pas sur assez de chemins. Il tourne sur le CPU, ou sur un GPU via CUDA ou OptiX (NVIDIA), HIP (AMD), oneAPI (Intel) ou Metal (Apple), comme le liste la [page sur le rendu GPU](https://docs.blender.org/manual/en/5.2/render/cycles/gpu_rendering.html).

![La touche rendue par Cycles avec 256 échantillons et débruitage : des ombres douces sous les frettes et un reflet le long de chaque fil de frette](../../../../assets/blender/l04-cycles.webp)

![La même scène rendue par EEVEE avec 64 échantillons : les mêmes matériaux, des ombres de contact plus nettes et plus sombres, et des reflets plus plats sur les frettes](../../../../assets/blender/l04-eevee.webp)

Sur la machine de l'auteur, un Intel Core Ultra 9 285K (24 threads) et une RTX 5080 avec le pilote 610.88, les deux rendus en 960 × 540 ont pris :

| Rendu | 1er processus Blender | 2e processus | 3e processus |
|---|---|---|---|
| Cycles, CPU, 256 échantillons, débruité | 4,01 s | 4,40 s | 4,05 s |
| Cycles, GPU avec OptiX, 256 échantillons, débruité | 3,08 s | 1,89 s | 1,45 s |
| EEVEE, 64 échantillons | 11,78 s | 1,14 s, puis 0,19 s | 0,92 s, puis 0,28 s |

Chaque chiffre est la durée d'un appel à `bpy.ops.render.render` dans [`render_images.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/render_images.py), exécuté trois fois dans des processus Blender séparés ; les deuxième et troisième exécutions ont rendu EEVEE deux fois. Le premier rendu EEVEE a compilé les shaders de la scène. Les processus suivants ont mis environ une seconde pour leur premier rendu EEVEE, ce qui suggère un cache de shaders sur disque (*à vérifier*), et le second rendu dans le même processus n'en a pris qu'une fraction. Le GPU a lui aussi été plus lent à sa première exécution. À cette taille et sur cette scène, le GPU bat le CPU d'un facteur 3 environ, et EEVEE bat les deux, une fois chaud. Ce sont des exécutions uniques sur une scène, pas un benchmark.

## Cycles : bruit et échantillons

La valeur d'un pixel dans Cycles est une **estimation de Monte-Carlo** : la moyenne de N échantillons aléatoires. L'erreur d'une telle moyenne décroît comme 1/√N, donc diviser le bruit par deux demande quatre fois plus d'échantillons. Le script le vérifie. Il rend la scène en 160 × 90 avec 4096 échantillons comme référence, puis avec moins d'échantillons, l'échantillonnage adaptatif et le débruitage désactivés, enregistre chaque rendu en EXR 32 bits, et mesure l'écart quadratique moyen des valeurs linéaires par rapport à la référence :

```text
== Cycles settings
device CPU | samples 4096 | adaptive True threshold 0.010 | denoise True OPENIMAGEDENOISE | seed 0 | max bounces 12 | clamp indirect 10.0

== Noise against the sample count (160 x 90, no adaptive sampling, no denoising)
reference: 4096 samples, mean linear RGB (0.051, 0.036, 0.036)
   1 samples: RMS difference from the reference 0.0519
   4 samples: RMS difference from the reference 0.0233 | previous / this 2.23
  16 samples: RMS difference from the reference 0.0122 | previous / this 1.90
  64 samples: RMS difference from the reference 0.0065 | previous / this 1.88
 256 samples: RMS difference from the reference 0.0028 | previous / this 2.29
```

Chaque multiplication par quatre divise l'erreur par 2 environ, comme le prédit 1/√N. Les rapports oscillent entre 1,88 et 2,29 parce que la référence a son propre bruit, et qu'une image de 160 × 90 est un petit échantillon. La première ligne montre les réglages d'usine : 4096 échantillons au plus ([`properties.py`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/intern/cycles/blender/addon/properties.py#L485-L490)), l'échantillonnage adaptatif et le débruitage.

![Quatre rendus de la touche : 1 échantillon, plein de points colorés ; 16 échantillons, granuleux ; 16 échantillons débruités, lisse ; 256 échantillons, presque lisse](../../../../assets/blender/l04-samples.webp)

En haut à gauche, 1 échantillon ; en haut à droite, 16 ; en bas à gauche, 16 avec OpenImageDenoise ; en bas à droite, 256.

### L'échantillonnage adaptatif

Avec l'[échantillonnage adaptatif](https://docs.blender.org/manual/en/5.2/render/cycles/render_settings/sampling.html) (adaptive sampling), Cycles arrête d'échantillonner un pixel dès que son bruit estimé passe sous le **seuil de bruit** (noise threshold), si bien que les pixels unis du fond s'arrêtent tôt et que les bords des frettes continuent. Le nombre d'échantillons devient un maximum. L'exercice 2 mesure ce qu'il fait gagner.

### La graine

Les nombres aléatoires viennent d'un échantillonneur initialisé par une **graine** (seed), comme `new Random(seed)` en C# ou en Java. La même graine donne la même image ; une autre graine donne la même moyenne avec un motif de bruit différent :

```text
== The seed
16 samples, seed 0 twice: identical True | seed 0 and seed 1: identical False RMS between them 0.0173
```

Pour une animation, **Use Animated Seed** change la graine à chaque image, parce qu'un motif de bruit qui reste fixe pendant que l'image bouge se voit davantage qu'un motif qui change.

La reproductibilité va plus loin qu'une seule machine. Le script enregistre le rendu à 16 échantillons en PNG 8 bits et calcule l'empreinte de ses pixels :

```text
== The same render, 8 bits after the view transform
pixels sha256 52b315b4edce59f3eaad17709705db365ed4cefa92c2c5a15053bef2d06be536
mean 8-bit RGB (48.5, 42.5, 43.4)
```

`check.sh` compare cette empreinte, et dans la CI du cours elle est la même sous Windows et Linux sur x86-64 et sous macOS sur Apple Silicon ([exécution 35172142583](https://github.com/spareilleux/learn/actions/runs/35172142583)) : les rendus CPU de cette scène sont identiques au bit près sur les trois systèmes et les deux architectures de CPU. C'était un résultat, pas une hypothèse ; le script a d'abord affiché l'empreinte sans la comparer, jusqu'à ce qu'une exécution de la CI montre que les trois concordaient. Les rendus GPU n'ont pas été comparés.

### Le débruitage

Un débruiteur (denoiser) est un réseau de neurones qui estime l'image propre à partir d'un rendu bruité, en s'aidant de passes supplémentaires comme les couleurs et les normales des surfaces. Cycles propose [OpenImageDenoise](https://www.openimagedenoise.org/) d'Intel, sur le CPU ou un GPU, et le débruiteur OptiX de NVIDIA :

```text
== Denoising
16 samples + OpenImageDenoise: RMS difference from the reference 0.0101 | without: 0.0122
```

L'image débruitée paraît bien plus propre que l'image bruitée, comme le montre l'image ci-dessus, mais son erreur par rapport à la référence n'est inférieure que de 17 % environ. Le bruit a disparu, mais le débruiteur doit deviner le détail qu'il cachait, et en 160 × 90, les frettes et les repères ne font que quelques pixels de large : ses suppositions sont lisses, pas exactes. Le débruitage aide surtout quand les détails sont grands par rapport aux pixels, et quelques échantillons de plus l'aident à mieux deviner.

## Points clés

- Les lumières point, spot et de surface sont en watts de puissance rayonnée, le soleil en watts par mètre carré ; la taille d'une lumière de surface fixe la douceur de ses ombres.
- Les rendus sont linéaires ; la transformation de vue, AgX par défaut, les convertit pour l'affichage, et un EXR garde les valeurs linéaires.
- EEVEE rastérise sur le GPU et est rapide une fois ses shaders compilés ; Cycles fait du path tracing sur le CPU ou le GPU, et il est physiquement réaliste mais bruité.
- Le bruit de Cycles décroît comme 1/√N : quatre fois plus d'échantillons pour moitié moins de bruit. L'échantillonnage adaptatif dépense les échantillons là où est le bruit.
- Une graine fixe donne des rendus identiques ; ici, le rendu CPU était identique au bit près sous Windows, Linux et macOS.
- Le débruitage supprime le bruit, pas l'erreur : il devine le détail qu'il ne voit pas.

## Exercices

1. Double la puissance de la lumière principale, rends 256 échantillons, et compare le RGB linéaire moyen avec la référence. Pourquoi la moyenne ne double-t-elle pas ?
2. Active l'échantillonnage adaptatif avec un seuil de bruit de 0,01 et 4096 échantillons au plus. Comment son erreur se compare-t-elle à celle de 256 échantillons sans lui, et combien de temps prend-il ?
3. Passe la transformation de vue à **Standard** et rends de nouveau 16 échantillons, en PNG et en EXR. Qu'est-ce qui change ?

<details>
<summary>Solution 1</summary>

```text
== Exercise 1: twice the key light
mean linear RGB at 256 samples: key 6 W (0.063, 0.041, 0.039) | key 3 W (reference) (0.051, 0.036, 0.036)
```

La moyenne augmente d'environ 24 % dans le rouge, pas de 100 %. La lumière s'additionne : la lumière de remplissage, celle de contour et le world n'ont pas changé, et une grande partie de l'image est un fond que la lumière principale n'atteint pas. Doubler une lumière ne double que sa propre contribution.

</details>

<details>
<summary>Solution 2</summary>

```text
== Exercise 2: adaptive sampling
adaptive, threshold 0.01, at most 4096 samples: RMS difference from the reference 0.0018
```

Son erreur, 0,0018, est inférieure à celle de 256 échantillons (0,0028). Sur la machine de l'auteur, il a pris 0,26 s, contre 1,40 s pour la référence à 4096 échantillons sans échantillonnage adaptatif, et environ 0,1 s pour 256 échantillons. Les durées sont les lignes que `check.sh` ne compare pas.

</details>

<details>
<summary>Solution 3</summary>

```text
== Exercise 3: the Standard view transform
mean 8-bit RGB: Standard (54.5, 48.3, 49.8) | AgX (48.5, 42.5, 43.4)
the linear EXR is the same under both view transforms: True
```

Le PNG est plus clair avec Standard : AgX compresse les tons pour laisser de la place aux hautes lumières, et Standard ne le fait pas. L'EXR est identique, parce qu'il contient les valeurs linéaires d'avant la transformation de vue.

</details>

## Sources

- Manuel de Blender 5.2 : [objets lumières](https://docs.blender.org/manual/en/5.2/render/lights/light_object.html), [affichages et vues](https://docs.blender.org/manual/en/5.2/render/color_management/displays_views.html), [EEVEE](https://docs.blender.org/manual/en/5.2/render/eevee/index.html), [Cycles](https://docs.blender.org/manual/en/5.2/render/cycles/index.html), [échantillonnage](https://docs.blender.org/manual/en/5.2/render/cycles/render_settings/sampling.html), [rendu GPU](https://docs.blender.org/manual/en/5.2/render/cycles/gpu_rendering.html), [chemins de lumière](https://docs.blender.org/manual/en/5.2/render/cycles/render_settings/light_paths.html).
- Code source de Blender à 5.2.2 : les réglages de rendu de Cycles dans [`intern/cycles/blender/addon/properties.py`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/intern/cycles/blender/addon/properties.py).
- [OpenImageDenoise](https://www.openimagedenoise.org/).
- M. Pharr, W. Jakob, G. Humphreys, [Physically Based Rendering: From Theory to Implementation](https://pbr-book.org/), 4e édition, chapitre 2 sur l'intégration de Monte-Carlo.
