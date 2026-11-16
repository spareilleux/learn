---
title: "BRUTAL : le Colosse"
description: Un prototype en C# et Vulkan, construit avec BRUTAL pour essayer un autre moteur pour l'Observatoire, en path tracing sur une GeForce RTX.
---

<video controls playsinline preload="metadata" poster="../../../demos/brutal/colossus-day.jpg" width="1280" height="536" style="width: 100%; height: auto;"><source src="../../../demos/brutal/colossus.mp4" type="video/mp4"></video>

*Une minute de la cinématique, de la fin d'après-midi à la nuit, puis vers l'aube : 62 s, 9,3 Mo, avec le son.*

L'[Observatoire](../) est une scène Godot. Pour voir si un autre moteur pourrait le porter, un prototype a été construit avec [BRUTAL](https://github.com/ahwootech/BRUTAL), le framework C# d'Ahwoo sur Vulkan. C'est une évaluation, pas un abandon de Godot, et il n'y a rien à télécharger.

## Ce que montre la vidéo

- **L'essaim :** dix mille corps, simulés par Jolt Physics à 120 pas par seconde, volent entre les tours et se rassemblent en un visage colossal. Ses yeux et sa bouche brillent.
- **La ville :** douze variantes de tours brutalistes, modélisées par des règles dans Blender, avec bandeaux de fenêtres, grilles en caissons, ailettes et feux d'avertissement.
- **Les blocs :** une structure sur une mesa, générée par une petite bibliothèque F# à partir de blocs typés et imbriqués.
- **La lumière :** chaque pixel suit un chemin d'au plus trois rebonds, avec un rayon d'ombre vers le soleil à chacun. DLSS Ray Reconstruction débruite les chemins, et DLSS Qualité agrandit 1067 × 600 en 1600 × 900.
- **La nuit :** le soleil se couche sur un cycle de 128 secondes. Le ciel se remplit d'étoiles, et les fenêtres et les feux s'allument.
- **Le son :** l'essaim, le vent, un chant sans paroles et des souffles, tous synthétisés en C# au démarrage du programme et placés dans la scène avec OpenAL Soft. Il n'y a pas de voix.

<figure>
<img src="../../../demos/brutal/colossus-day.jpg" alt="Le visage de l'essaim parmi les tours, dans la brume de l'après-midi, le soleil à côté" width="1280" height="536" loading="lazy" />
<figcaption>L'après-midi : le visage parmi les tours.</figcaption>
</figure>

<figure>
<img src="../../../demos/brutal/colossus-dusk.jpg" alt="Le visage au crépuscule, de près, les yeux brillants parmi les fenêtres allumées" width="1280" height="536" loading="lazy" />
<figcaption>Le crépuscule : les yeux brillent.</figcaption>
</figure>

<figure>
<img src="../../../demos/brutal/colossus-towers.jpg" alt="Vue vers le haut entre les tours aux fenêtres allumées, vers un ciel sombre" width="1280" height="536" loading="lazy" />
<figcaption>Entre les tours, vers le ciel.</figcaption>
</figure>

## Comment c'est mesuré

La vidéo a été rendue sur une seule machine, une GeForce RTX 5080, le 2026-10-21. Le programme enregistre à 60 images par seconde fixes, quel que soit son rythme, et fond chaque paire en une image d'une vidéo à 30 images par seconde : 6 720 images pour 112 secondes, dont voici une minute. Le GPU a pris 7,37 ms par image en médiane et 13,34 ms au 95ᵉ centile, pour le path tracing, le débruitage et l'agrandissement ensemble.

## Pourquoi il n'y a pas de téléchargement

- La licence de BRUTAL, dérivée de MIT, demande à toute version distribuée de créditer Ahwoo, d'afficher le logo BRUTAL inchangé avant le démarrage et de fournir son `NOTICE.txt`. Ce prototype est une expérience locale et n'est pas distribué.
- DLSS a besoin des bibliothèques Streamline de NVIDIA, qui ne sont pas redistribuées ici.

## Crédits

- **Moteur :** [BRUTAL](https://github.com/ahwootech/BRUTAL) par Ahwoo, sous la BRUTAL License v1.0.
- **Physique :** [Jolt Physics](https://github.com/jrouwe/JoltPhysics) (MIT).
- **Fenêtre et interface :** [GLFW](https://www.glfw.org/) (zlib), [Dear ImGui](https://github.com/ocornut/imgui) et [ImPlot](https://github.com/epezent/implot) (MIT).
- **Son :** [OpenAL Soft](https://openal-soft.org/) (LGPL-2.1). Chaque son est synthétisé par le programme.
- **Aussi, par les paquets de BRUTAL :** [FreeType](https://freetype.org/) pour le texte et [shaderc](https://github.com/google/shaderc) (Apache-2.0) pour les shaders.
- **Agrandissement et débruitage :** NVIDIA DLSS, par [Streamline](https://github.com/NVIDIA-RTX/Streamline). NVIDIA, GeForce RTX et DLSS sont des marques de NVIDIA Corporation.
- **Le visage :** le portrait d'un buste de marbre imaginaire, peint par [Z-Image-Turbo](https://huggingface.co/Tongyi-MAI/Z-Image-Turbo) (Apache-2.0), détouré par [BiRefNet](https://github.com/ZhengPeng7/BiRefNet) (MIT), et transformé en maillage par [TRELLIS.2](https://huggingface.co/microsoft/TRELLIS.2-4B) (MIT) avec les caractéristiques de [DINOv3](https://github.com/facebookresearch/dinov3). Built with DINOv3. Chaque modèle a tourné en local.
- **Textures :** générées en local avec Z-Image-Turbo.
- **Tours :** modélisées dans Blender par un script.
