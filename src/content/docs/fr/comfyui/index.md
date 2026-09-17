---
title: ComfyUI, de débutant à expert — Mission
description: 'Apprendre ComfyUI, l''application à nœuds pour les modèles de diffusion, d''une première image jusqu''à la production — le graphe de nœuds, la diffusion et la reproductibilité, les workflows en JSON, l''API HTTP et WebSocket depuis C# et Java, la retouche d''images, ControlNet, LoRA, les modèles récents et leurs licences, l''agrandissement et les textures, la vidéo, les nœuds personnalisés et leur sécurité, et son exploitation comme service — avec des rendus mesurés sur un GPU et le reste vérifié en CI sans GPU.'
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Le code du cours est dans [`code/comfyui`](https://github.com/spareilleux/learn/tree/main/code/comfyui) : des workflows dans les deux formats JSON, un outil C# et un client Java. `check.sh` vérifie ce qui tourne sans GPU ni modèle : il valide et convertit les workflows, démarre [ComfyUI](https://github.com/Comfy-Org/ComfyUI) **v0.36.0** avec `--cpu`, exécute les clients C# et Java contre lui sur un workflow qui n'a besoin d'aucun modèle, et compare chaque sortie avec les fichiers de `expected/`. Un workflow, `comfyui-examples.yml`, l'exécute sous Linux, Windows et macOS. Les rendus, les durées et les empreintes de pixels des leçons viennent d'une seule machine : Windows 11, une NVIDIA GeForce RTX 5080 de 16 Go, et la version portable de ComfyUI, en septembre 2026. Rien n'a été mesuré sur un autre GPU, un autre pilote ou un autre système, et les leçons le disent là où ça compte.
:::

## Pourquoi j'apprends ça

Les autres cours d'apprentissage automatique du site chargent des modèles depuis du code : [Candle](../candle/) en Rust, et ONNX Runtime dans le [cours sur l'IA de GA](../ga-ai/). ComfyUI fait l'inverse. C'est une application où tu relies des modèles entre eux dans un graphe, dans un navigateur, et sa bibliothèque de modèles de workflows couvre les images, la vidéo, l'audio et les modèles 3D.

Je veux savoir comment il fonctionne sous le graphe, ce qui rend une image reproductible, et comment un service C# ou Java peut s'en servir comme moteur de rendu : par exemple pour générer des textures pour ce site et pour GuitarAlchemist, ce qui est le projet de la dernière leçon.

## À qui s'adresse ce cours

Tu écris du C# ou du Java. Tu connais HTTP, JSON et le code asynchrone. Tu n'as pas besoin de connaître Python, PyTorch, ni le fonctionnement des modèles de diffusion : la leçon 2 explique ce qu'il te faut, et renvoie vers les articles. Les images des leçons ont été rendues sur un GPU NVIDIA de 16 Go, dont SDXL a utilisé environ 7 Go ; la façon dont les modèles plus récents tiennent sur des cartes plus petites est le sujet de la leçon 8. Sans GPU, tu peux quand même suivre les leçons sur le JSON et l'API avec le workflow CPU qu'utilise la CI.

## À la fin de ce cours, je saurai

- installer ComfyUI sous Windows, Linux ou macOS, et exécuter un graphe texte-vers-image ;
- expliquer ce que font les réseaux du checkpoint, la graine, les étapes, le CFG, le sampler et le scheduler, et ce qui rend un rendu reproductible ;
- lire, convertir, valider et comparer des workflows dans les deux formats JSON ;
- mettre des workflows en file d'attente et les suivre depuis C# et Java par l'API HTTP et WebSocket ;
- retoucher des images avec l'img2img, l'inpainting et l'outpainting, et les contrôler avec ControlNet et LoRA ;
- choisir un modèle récent pour une machine et un usage, lire sa licence, et le faire tenir en VRAM avec des poids quantifiés ;
- agrandir des images, créer des textures raccordables, et générer de courtes vidéos ;
- juger le code d'un nœud personnalisé avant de l'installer ;
- exploiter ComfyUI comme service derrière une API à moi.

## Plan

| # | Leçon | En termes de C# ou de Java |
|---|---|---|
| 1 | [Le graphe de nœuds, l'installation et une première image](01-install-first-image/) | un graphe de flux de données, comme les blocs de TPL Dataflow |
| 2 | [La diffusion, et ce qui rend une image reproductible](02-diffusion-reproducibility/) | `new Random(seed)`, et le déterminisme des calculs en virgule flottante |
| 3 | [Les workflows en JSON : le format de l'interface, le format de l'API, et les différences](03-workflow-json/) | `System.Text.Json`, Jackson, un schéma |
| 4 | [L'API HTTP et WebSocket depuis C# et Java](04-http-websocket-api/) | `HttpClient`, `ClientWebSocket`, `java.net.http` |
| 5 | [Img2img, inpainting et outpainting](05-img2img-inpainting/) | — |
| 6 | [ControlNet : contours et profondeur](06-controlnet/) | — |
| 7 | [LoRA : chargement, empilement, et ce qu'implique d'en entraîner un](07-lora/) | un plugin qui modifie des poids |
| 8 | [Modèles récents et leurs licences, quantification et VRAM](08-recent-models-quantization/) | choisir une dépendance et sa licence |
| 9 | Agrandissement, textures raccordables et HDR | — |
| 10 | Vidéo | — |
| 11 | Les nœuds personnalisés, et leur sécurité | des paquets NuGet ou Maven qui exécutent du code à l'installation |
| 12 | ComfyUI en production : un service, une file d'attente, plusieurs GPU | un worker derrière une file de tâches |
| 13 | Projet : des textures pour ce site et pour GuitarAlchemist | — |
| — | [Journal](journal/) | |

Les leçons 5 à 13 sont le plan ; elles changeront à mesure que les premières m'apprendront ce qui compte.

## Modèles et images

Le cours commence avec [Stable Diffusion XL base 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0), sous la licence CreativeML Open RAIL++-M, et ajoute des modèles leçon après leçon. Chaque leçon donne la licence et la taille de téléchargement de chaque modèle. Aucun fichier de modèle n'est dans le dépôt. Chaque image du cours a une légende avec son modèle, sa graine et son workflow, et aucune image ne montre une personne réelle ou une marque.

## Ressources

- La [documentation de ComfyUI](https://docs.comfy.org/), et le [code source à la v0.36.0](https://github.com/Comfy-Org/ComfyUI/tree/ee71d5c4993f29086b27fde1629a945ae48425bf).
- Les [exemples ComfyUI](https://comfyanonymous.github.io/ComfyUI_examples/), par l'auteur original de ComfyUI.
- Le [hub de modèles de Hugging Face](https://huggingface.co/models), où les modèles et leurs fiches sont publiés.
- R. Rombach et al., [High-Resolution Image Synthesis with Latent Diffusion Models](https://arxiv.org/abs/2112.10752), 2021, l'article à l'origine de Stable Diffusion.
