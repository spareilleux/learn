---
title: Journal
description: Notes d'avancement datées du cours ComfyUI — ComfyUI v0.36.0 et SDXL base 1.0 épinglés, une version portable avec son propre répertoire de base, deux images pour une graine, les sorties du serveur ordonnées par un ensemble et ses erreurs de validation, des tailles zlib qui changent selon le système, une CI sur CPU sous trois systèmes, les modèles des leçons 5 à 8 et leurs licences, des contours Canny qui changent selon la machine, des fichiers quantifiés mesurés dans 16 Go, et les points à vérifier.
sidebar:
  order: 99
---

## Avancement

- [x] ComfyUI v0.36.0 (commit `ee71d5c`), frontend 1.52.7, SDXL base 1.0 épinglé par l'empreinte du fichier
- [x] `check.sh` : vérifications hors ligne des workflows, conversion du format de l'interface vers celui de l'API comparée à l'export du frontend, les clients C# et Java contre ComfyUI sur le CPU
- [x] CI sous Ubuntu, Windows et macOS, sans GPU ni modèle
- [x] Leçon 1 : le graphe de nœuds, l'installation et une première image
- [x] Leçon 2 : la diffusion, et ce qui rend une image reproductible
- [x] Leçon 3 : les workflows en JSON
- [x] Leçon 4 : l'API HTTP et WebSocket depuis C# et Java
- [x] Traductions en français et en espagnol des leçons 1 à 4
- [x] Leçon 5 : img2img, inpainting et outpainting
- [x] Leçon 6 : ControlNet, contours et profondeur
- [x] Leçon 7 : LoRA
- [x] Leçon 8 : modèles récents, licences, quantification et VRAM
- [x] Traductions en français et en espagnol des leçons 5 à 8
- [x] Leçon 9 : agrandissement, textures raccordables et HDR
- [ ] Leçon 10 : vidéo
- [x] Leçon 11 : les nœuds personnalisés, et leur sécurité
- [x] Leçon 12 : ComfyUI en production
- [x] Leçon 15 : audio, lu dans le code source
- [x] Une section « à toi de jouer » sur chaque leçon écrite, et une galerie des trente images
- [ ] Leçon 13 : des textures pour ce site et pour GuitarAlchemist
- [ ] Leçon 14 : le laboratoire Guitar Alchemist

## QA

Ce que ce cours a trouvé dans ComfyUI v0.36.0, dans sa documentation et dans les fichiers qu'il charge, en les exécutant plutôt qu'en lisant ce qu'on en dit. Les liens de code pointent sur [`ee71d5c`](https://github.com/Comfy-Org/ComfyUI/tree/ee71d5c4993f29086b27fde1629a945ae48425bf), le commit épinglé par le cours. Aucun de ces points n'est encore un rapport de bogue : c'est ce que les mesures ont montré.

| Attendu | Ce qui se passe | Où | Mesure | État |
|---|---|---|---|---|
| Un dossier de base neuf démarre le serveur | Le démarrage s'arrête sur `FileNotFoundError` : le serveur liste `custom_nodes` dans le nouveau dossier avant que quoi que ce soit ne le crée | `--base-directory` | Reproduit à chaque dossier de base neuf | Reproduit ; [`server.sh`](https://github.com/spareilleux/learn/blob/main/code/comfyui/server.sh) crée le dossier vide d'abord |
| `--base-directory` ne touche pas à l'installation | Il a migré la base `user/comfyui.db` héritée de l'installation, laissé un `.bak` à côté et copié la base dans le dossier de test | `--base-directory` sans `--database-url` | L'original a été restauré depuis la sauvegarde ; les deux SHA-256 concordaient | Reproduit ; évité avec `--database-url sqlite:///:memory:` ([Vérification ComfyUI pour la scène orbitale](#2026-09-19--vérification-comfyui-pour-la-scène-orbitale)) |
| Le tutoriel de démarrage décrit `EmptyLatentImage` | Il dit que le nœud fabrique un latent de bruit. Le nœud fabrique des zéros, et c'est `KSampler` qui fait le bruit | [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), contre le [tutoriel text-to-image](https://docs.comfy.org/get_started/first_generation) | Lu dans le code du nœud au commit épinglé | Reproduit. La documentation est fausse, le comportement est juste |
| Le même graphe et la même graine donnent les mêmes pixels | L'image change quand l'invite négative est réencodée alors que l'UNet est déjà chargé | [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), `CLIPTextEncode` et `KSampler` | `698e7867…` sur un serveur neuf, `5374ac40…` à chaud : 0,92 niveau d'écart moyen, 2,63 % des pixels au-delà de 8. `--deterministic` n'a rien changé | Reproduit. L'opération responsable n'est toujours pas identifiée ([Une graine, deux images](#2026-09-16--une-graine-deux-images)) |
| Une image dans un lot vaut la même graine rendue seule | La première image du lot diffère du rendu seul | [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), `EmptyLatentImage` et `KSampler` | 0,74 niveau d'écart moyen | Reproduit |
| La validation liste tous les problèmes d'un prompt | Un lien vers un nœud absent lève un `KeyError` hors du bloc `try`, et le serveur répond une trace qui porte son chemin d'installation | [`execution.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py) | Le serveur a signalé 2 erreurs là où la vérification hors ligne en trouvait 5 ; l'une était classée sous le nœud 3 avec le nom d'entrée du nœud 8, `samples` | Reproduit |
| Les nœuds de sortie s'exécutent dans un ordre stable | Les sorties validées sont gardées dans un ensemble Python, dont l'ordre de parcours suit le hachage de chaînes randomisé | [`execution.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py) | `check.sh` a échoué à sa deuxième exécution : les deux `SaveImage` ont tourné dans l'autre ordre | Reproduit ; réglé dans le cours par `PYTHONHASHSEED=0` |
| `POST /upload/image` a un comportement documenté | Des octets identiques gardent le nom existant ; des octets différents reçoivent `name (1).png` | [`server.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py) | Les deux cas observés ; ni l'un ni l'autre n'est documenté | Reproduit. La documentation est muette |
| La page de `SetUnionControlNetType` liste les types que le nœud a | La page liste 13 types, le nœud en a 8 | [`nodes_controlnet.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_controlnet.py), contre sa [documentation](https://docs.comfy.org/built-in-nodes/SetUnionControlNetType) | Les 8 noms ont été lus dans le code du nœud | Reproduit. Prendre les noms dans le code |
| Les métadonnées d'un LoRA décrivent ses tenseurs | Les métadonnées du LCM-LoRA et son titre disent rang 1 et alpha 1 | `sdxl_LCM_lora_rank1.safetensors` | Ses tenseurs donnent rang 64 et alpha 8 | Reproduit. Les métadonnées du fichier sont fausses ; lire les tenseurs ([Les modèles des leçons 5 à 8](#2026-09-16--les-modèles-des-leçons-5-à-8)) |
| Le nom d'un fichier quantifié dit ce qu'il contient | `qwen_3_4b_fp8_mixed` contient 12 couches nvfp4, et `qwen_3_4b_fp4_mixed` 58 couches fp8 | Les encodeurs de texte Z-Image-Turbo de Comfy-Org | Comptées dans les en-têtes | Reproduit. « mixed » est l'avertissement : lire l'en-tête |
| `nvidia-smi` montre ce dont un modèle a besoin | La VRAM dynamique prend ce qui est libre, le chiffre ne dit donc rien du modèle | `--disable-dynamic-vram` et les lignes de mise en scène du journal | 12,5 à 15,3 Go utilisés pour toutes les configurations, de 19,4 Go de poids bf16 jusqu'au nvfp4 | Reproduit. Ce sont les tailles mises en scène dans le journal qui sont utiles |
| La documentation de l'API liste les routes que le serveur sert | Les routes `/api/jobs`, le préfixe `/api` sur toutes les routes et les messages binaires d'aperçu n'y sont pas | [`server.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py) | Lu dans la table de routage au commit épinglé | Reproduit. La documentation est incomplète |
| `execution_success` signifie que le rendu est lisible dans `/history` | Il est envoyé avant que l'historique ne soit écrit. Le même `prompt_id` posté deux fois s'exécute deux fois et écrase son entrée, et une reconnexion ne rejoue rien | [`execution.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py), [`server.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py) | Chaque cas a été provoqué sur un serveur CPU et ses réponses enregistrées | Reproduit ; traité dans le worker du cours ([ComfyUI en production](#2026-09-16--comfyui-en-production)) |
| `LoadImage` liste les fichiers que le serveur sait lire | Il liste ceux dont le type MIME commence par `image`, et cette table appartient à la machine, pas à ComfyUI | [`folder_paths.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/folder_paths.py#L229-L253) | `.exr` n'a aucun type MIME sur cette machine Windows ni sur l'exécuteur `macos-latest`, et vaut `image/aces` sur `ubuntu-latest`, toutes en Python 3.13 | Reproduit sur trois machines par [`data/mime-info.py`](https://github.com/spareilleux/learn/blob/main/code/comfyui/data/mime-info.py). Un EXR écrit par `SaveImageAdvanced` ne peut pas être repris dans la liste sur deux des trois |
| La licence d'un repaquetage couvre les fichiers qu'il livre | [Comfy-Org/TRELLIS.2](https://huggingface.co/Comfy-Org/TRELLIS.2) est étiqueté MIT et livre `clip_vision/dino_v3_vit_l.safetensors`, qui relève de la licence DINOv3, sans copie de cette licence | L'arborescence du dépôt | Lu sur la fiche du modèle et dans l'arborescence | Reproduit. Un repaquetage ne change pas la licence d'un fichier. Ceci n'est pas un avis juridique |
| La licence d'un modèle régit ce qu'on fait des poids | La [licence Hunyuan 3D 2.0](https://huggingface.co/tencent/Hunyuan3D-2/blob/9cd649ba6913f7a852e3286bad86bfa9a2d83dcf/LICENSE) restreint aussi les lieux où ses sorties peuvent être affichées : clause 5.c, Territoire excluant l'Union européenne, le Royaume-Uni et la Corée du Sud | Clauses 1.l et 5.c, lues au commit `9cd649ba` | Deux rendus avaient déjà été publiés sur ce site, et ont été retirés | Reproduit. Le cours ne publie aucune sortie Hunyuan3D ([Un modèle 3D publié avant d'avoir lu sa licence](#2026-09-17--un-modèle-3d-publié-avant-davoir-lu-sa-licence)) |

## Expériences

Une ligne par expérience mesurée. La colonne hypothèse dit ce qui était prévu **avant** que le nombre n'existe ; là où le cours a mesuré d'abord et compris ensuite, elle le dit, plutôt que d'inventer une prédiction qui connaîtrait déjà la réponse.

| Question | Hypothèse | Résultat mesuré | Verdict | Preuves |
|---|---|---|---|---|
| Un `denoise` inférieur à 1 raccourcit-il le rendu ? | Non écrite à l'avance. Ce qui était testé, c'est la lecture qu'invite le mot : moins d'étapes pour moins de débruitage | 25 étapes ont tourné pour toutes les valeurs de 0,3 à 0,9, en 4,6 à 5,1 s | Réfutée : `denoise` fait démarrer l'échantillonneur en cours de route sur un calendrier de même longueur | [Img2img, inpainting, ControlNet et LoRA](#2026-09-16--img2img-inpainting-controlnet-et-lora), [`05-img2img.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/05-img2img.api.json) |
| Les deux images de la graine 42 viennent-elles de la mise en scène de la VRAM dynamique ? | Écrite avant le rendu : désactiver la VRAM dynamique devrait ramener les pixels du démarrage à froid | `--disable-dynamic-vram` a donné l'empreinte à chaud `5374ac40…` dès la première exécution, et les mêmes pixels qu'avec la VRAM dynamique, en 78,87 s contre 63,93 | Non concluante : l'hypothèse a échoué et l'opération responsable reste inconnue | [Une graine, deux images](#2026-09-16--une-graine-deux-images), [Modèles récents et quantification](#2026-09-16--modèles-récents-et-quantification) |
| Le modèle d'inpainting SD-XL exige-t-il un `strength` inférieur à 1,0, comme le dit sa fiche ? | L'instruction de la fiche tenait lieu de prédiction | 1,0 et 0,99 diffèrent sur 0,01 % des pixels de plus de 8 niveaux | Réfutée sur cette image ; une image ne fait pas une réponse générale | [Img2img, inpainting, ControlNet et LoRA](#2026-09-16--img2img-inpainting-controlnet-et-lora), [`05-inpaint-model.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/05-inpaint-model.api.json) |
| Que coûte la quantification en image, et que rapporte-t-elle en vitesse ? | Non écrite à l'avance | int8 avec l'encodeur fp8 : 9 à 15 % des pixels diffèrent du bf16 de plus de 8, à 3,1 étapes par seconde contre 1,5. nvfp4 avec fp4 : 62 à 74 %, à 3,7 à 4,1 | Confirmée pour int8, réfutée pour nvfp4 : ce n'est pas une image dégradée mais un autre agencement de la même scène | [Modèles récents et quantification](#2026-09-16--modèles-récents-et-quantification), [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/08-z-image-turbo.api.json) |
| Un ControlNet sert-il encore après les premières étapes ? | Écrite dans la leçon avant le rendu : la mise en place se décide tôt, donc `end_percent` à 0,3 devrait conserver la composition | Le ControlNet a guidé 8 étapes sur 25, et l'image était presque la même qu'avec lui actif tout du long | Confirmée | [Img2img, inpainting, ControlNet et LoRA](#2026-09-16--img2img-inpainting-controlnet-et-lora), [`06-canny.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/06-canny.api.json) |
| Un LoRA ralentit-il l'échantillonnage ? | Non écrite à l'avance. L'hypothèse testée est que des poids ajoutés coûtent du temps à chaque étape | Changer de LoRA a coûté 4 à 5 s avant la première étape ; une image LCM-LoRA en 4 étapes a ensuite pris 1,16 s | Réfutée : le patch est calculé une fois, au chargement du modèle | [Img2img, inpainting, ControlNet et LoRA](#2026-09-16--img2img-inpainting-controlnet-et-lora), [`07-lcm.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/07-lcm.api.json) |
| Une croix plus large enlève-t-elle le raccord d'une texture décalée et repeinte ? | Écrite après le premier échec et avant le second rendu : 384 pixels de croix, 128 de fondu et denoise 1 devraient le fermer | La croix de 160 pixels a divisé le raccord par deux, de 13,4 à 5,2 niveaux sur la ligne médiane, mais a laissé une ligne mouchetée et un écart de ton. La croix large a enlevé la ligne ; l'écart de ton est resté | Confirmée, avec une réserve : le raccord a disparu, la différence de ton entre les moitiés non | [Agrandissement, textures raccordables et HDR](#2026-09-16--agrandissement-textures-raccordables-et-hdr), [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/09-seamless.api.json) |
| Un PNG 16 bits ou un EXR d'un rendu sont-ils vraiment HDR ? | Non écrite à l'avance. L'attente testée est qu'un conteneur plus large porte davantage | 256 niveaux par canal dans le PNG 16 bits d'un rendu 8 bits, et aucune valeur au-delà de 1,0 dans l'EXR : le VAE borne sa sortie entre 0 et 1 | Réfutée : le conteneur est HDR, le contenu ne l'est pas | [Agrandissement, textures raccordables et HDR](#2026-09-16--agrandissement-textures-raccordables-et-hdr), [`09-exr.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/09-exr.api.json) |
| Le décodage VAE par tuiles change-t-il l'image ? | Non écrite à l'avance | 0,93 niveau d'écart moyen en 2048 × 2048, là où un décodage simple tenait aussi sur le GPU | Confirmée : petit, et non nul — décoder simplement quand ça tient | [Agrandissement, textures raccordables et HDR](#2026-09-16--agrandissement-textures-raccordables-et-hdr), [`09-hires-fix.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/09-hires-fix.api.json) |
| La sortie du nœud `Canny` est-elle comparable d'une machine à l'autre ? | Écrite avant le passage en CI : un filtre de contours à sortie d'apparence entière devrait donner les mêmes pixels partout | Quatre machines ont donné quatre empreintes de pixels ; les trois exécuteurs de CI ont trouvé 467 pixels de contour, la machine de l'auteur 464 | Réfutée : c'est du code à virgule flottante. La CI affiche les nombres à titre indicatif au lieu de les comparer | [Img2img, inpainting, ControlNet et LoRA](#2026-09-16--img2img-inpainting-controlnet-et-lora), [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/comfyui/check.sh) |
| Quelle étape du `canny` de Kornia cesse de coïncider d'une machine à l'autre ? | Non écrite à l'avance : la leçon demandait l'étape sans en nommer une | L'entrée est identique sur quatre machines ; le flou gaussien sépare trois groupes, le gradient spatial les quatre, toutes les magnitudes diffèrent — et les contours seuillés sont identiques, 1 461 pixels sur 3 072 | Répondu, en deux moitiés : la divergence commence à la première convolution et elle est toujours là ; elle n'atteint la sortie que si des pixels passent près d'un seuil | [`data/canny-steps.py`](https://github.com/spareilleux/learn/blob/main/code/comfyui/data/canny-steps.py), [leçon 6](../06-controlnet/#létape-où-ça-cesse-de-coïncider) |
| Que fait l'indicateur `convrot` d'un checkpoint int8 ? | Écrite dans la leçon 8 avant la lecture du noyau : une rotation de groupes de poids avant la quantification, pour étaler les grandes valeurs afin qu'une seule échelle leur convienne mieux | comfy-kitchen 0.2.34 tourne chaque groupe de 256 canaux d'entrée par une matrice de Hadamard régulière, symétrique et orthogonale : le poids hors ligne, les activations en ligne. Sur un poids ayant une valeur aberrante par ligne, l'erreur d'aller-retour int8 vaut 5,7 % sans rotation et 0,76 % avec | Confirmée, avec un chiffre. Étant sa propre inverse, la matrice laisse le produit intact ; elle ne change que ce que l'int8 doit contenir | [`data/convrot.py`](https://github.com/spareilleux/learn/blob/main/code/comfyui/data/convrot.py), [leçon 8](../08-recent-models-quantization/) |

## 2026-09-16 — Versions et installation

- ComfyUI v0.36.0 est sortie la veille, le 15 septembre 2026, et c'est la dernière version ; son tag pointe vers le commit [`ee71d5c`](https://github.com/Comfy-Org/ComfyUI/commit/ee71d5c4993f29086b27fde1629a945ae48425bf). La version portable Windows pour NVIDIA fait 1 917 442 353 octets et embarque Python 3.13.14 et PyTorch 2.13.0 pour CUDA 13.0.
- Le cours réutilise une version portable déjà installée sur la machine, et n'y écrit jamais : le serveur démarre avec `--base-directory` qui pointe ailleurs, `--models-directory` qui pointe vers les modèles de l'installation, et `--database-url sqlite:///:memory:`.
- Un répertoire de base neuf a fait s'arrêter le serveur au démarrage avec `FileNotFoundError`, parce qu'il liste `custom_nodes` avant de créer quoi que ce soit. `server.sh` crée le dossier vide.
- `sd_xl_base_1.0.safetensors` sur la machine a le SHA-256 qu'indique Hugging Face, `31e35c80…7e5b`.
- Les pages de prise en main et les exemples d'API de la documentation utilisent Stable Diffusion 1.5 en 512 × 512, pas SDXL. La page d'installation manuelle utilise conda ; `venv` n'apparaît que sur la page de comfy-cli. Le tutoriel texte-vers-image dit que `EmptyLatentImage` crée un latent de bruit ; il crée des zéros, et c'est `KSampler` qui crée le bruit.

## 2026-09-16 — Premiers rendus

- Le premier rendu SDXL a pris 14,71 secondes, dont environ 4 pour les 25 étapes d'échantillonnage à 6,4 étapes par seconde. Avec les modèles chargés, une nouvelle graine a pris 4,6 secondes.
- Le prompt demandait un métronome en laiton ; la graine 42 a dessiné quelque chose comme un sablier. La graine 43 s'en est approchée.
- `nvidia-smi` a montré environ 7 Go de plus en usage pendant le rendu. Le log a préparé 1 560 Mo pour les encodeurs de texte, 4 896 Mo pour l'UNet et 159 Mo pour le VAE.
- Les aperçus du latent de `--preview-method taesd` ont ralenti l'échantillonnage de 6,4 à 4,9 étapes par seconde.

![Un objet en laiton sur un vieil établi en bois, éclairé par le soleil du matin à travers une fenêtre poussiéreuse. Il ressemble plus à un sablier ouvragé qu'à un métronome : un haut corps de verre à la taille étroite, tenu dans un cadre en laiton sur un socle rond.](../../../../assets/comfyui/l01-metronome.webp)

*Le premier rendu. ComfyUI v0.36.0 : Stable Diffusion XL base 1.0, graine 42, 25 étapes, `euler`, `normal`, CFG 7, 1024 × 1024, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json).*

## 2026-09-16 — Une graine, deux images

- Le même workflow et la même graine ont donné `698e7867…` sur un serveur fraîchement démarré, de nouveau après des redémarrages, et `5374ac40…` chaque fois que le prompt négatif était encodé de nouveau avec l'UNet déjà chargé. Les deux images diffèrent en moyenne de 0,92 niveau, et 2,63 % des pixels diffèrent de plus de 8.
- `--disable-dynamic-vram` a donné `5374ac40…` dès la première exécution aussi. `--deterministic` n'a changé aucun des deux résultats. Je n'ai pas trouvé quelle opération diffère.
- La première image d'un lot de deux différait de l'image seule de même graine (moyenne 0,74), et la seconde image du lot n'est pas celle de la graine 43.
- Un rendu de graine 43 par le client Java, sur un autre démarrage du serveur 20 minutes plus tard, avait les mêmes pixels que le premier rendu de graine 43.

![Trois panneaux. Les deux premiers sont les deux rendus de graine 42, qui paraissent identiques à cette taille. Le troisième est une image blanche avec des traits sombres là où ils diffèrent, amplifiés huit fois : le contour de l'objet en laiton, son verre, les outils sur l'établi et le cadre de la fenêtre.](../../../../assets/comfyui/l02-cold-warm.webp)

*Les deux images de graine 42. ComfyUI v0.36.0 : Stable Diffusion XL base 1.0, graine 42, 25 étapes, `euler`, `normal`, CFG 7, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json). À gauche : première exécution après le démarrage du serveur. Au milieu : le même graphe après un nouvel encodage du prompt négatif. À droite : là où elles diffèrent, amplifié huit fois.*

## 2026-09-16 — Les formats JSON et l'API

- Charger le fichier API dans le frontend et appeler `app.graphToPrompt()` a donné un fichier d'interface et un export API. Le convertisseur C#, qui lit les noms des widgets dans l'`input_order` de `/object_info` et saute le widget de contrôle de la graine, produit l'export octet pour octet.
- Un PNG mis en file d'attente depuis le navigateur a enregistré la graine 42 dans son chunk `workflow`, et le frontend a changé la graine en 140956311522585 juste après la mise en file, parce que son widget `control_after_generate` était réglé sur `randomize`.
- Le serveur a écrit `"cfg": 7.0` dans le prompt du PNG pour un frontend qui avait envoyé `7` : la validation convertit les entrées `FLOAT` avec `float()` et les réécrit.
- Un lien vers un nœud manquant a fait lever à la validation du serveur une `KeyError` hors de son bloc `try`. Le serveur a signalé deux erreurs là où la vérification hors ligne en a trouvé cinq ; l'une était rangée sous le nœud 3 avec le nom d'entrée du nœud 8, `samples`, et une trace d'appels qui contient le chemin d'installation du serveur.
- `check.sh` a échoué à sa deuxième exécution : les deux nœuds `SaveImage` se sont exécutés dans l'autre ordre. Le serveur garde les sorties validées dans un ensemble Python, et les hachages de chaînes sont rendus aléatoires à chaque démarrage. `server.sh` fixe maintenant `PYTHONHASHSEED=0`.
- Une exécution entièrement en cache envoie quand même `executed` pour chaque nœud de sortie, avec les noms de fichiers de la première exécution, et n'écrit rien.
- La première exécution de la CI a échoué sous Ubuntu seulement : le même PNG de 64 × 48 s'y est compressé en 84 octets, et en 88 sous Windows et macOS. `png-info` affiche maintenant la taille décompressée.
- L'exemple d'API en Python du dépôt de ComfyUI attend `executing` avec un nœud `null`. Le serveur l'envoie après avoir écrit l'historique ; les clients s'arrêtent plutôt sur `execution_success`, `execution_error` ou `execution_interrupted`.
- La documentation ne liste pas les routes `/api/jobs`, le préfixe `/api` sur chaque route, ni les messages binaires d'aperçu.

## 2026-09-16 — Les modèles des leçons 5 à 8

- Le disque de la machine du cours était presque plein, donc les nouveaux fichiers de modèles sont allés sur un autre disque, déclaré à ComfyUI avec `--extra-model-paths-config`. Chaque fichier a été téléchargé depuis une révision Hugging Face épinglée et vérifié avec le SHA-256 qu'indique Hugging Face, et sa licence a été lue sur la fiche du modèle à ce moment-là.
- Pixel Art XL est sous CreativeML Open RAIL-M, pas sous la RAIL++-M de SDXL. Sa fiche dit qu'aucun mot déclencheur n'est nécessaire, et ses métadonnées fixent `instance_prompt: pixel art`.
- Les métadonnées du LCM-LoRA indiquent un rang 1 et un alpha 1, et son titre `sdxl_LCM_lora_rank1` ; ses tenseurs ont un rang 64 et un alpha 8.
- L'encodeur de texte Qwen3 4B a le même SHA-256 dans les dépôts Z-Image-Turbo et FLUX.2 klein de Comfy-Org.

## 2026-09-16 — Img2img, inpainting, ControlNet et LoRA

- `denoise` n'a pas changé le nombre d'étapes : 25 étapes se sont exécutées pour chaque valeur de 0,3 à 0,9, en 4,6 à 5,1 secondes.
- Envoyer des octets identiques sous un nom déjà pris a renvoyé le nom existant ; des octets différents ont reçu `name (1).png`. Aucun des deux comportements n'est documenté.
- `VAEEncodeForInpaint` grise les pixels masqués, ce que le tutoriel ne dit pas. Avec `denoise` à 0,5, le résultat était une ellipse grise uniforme.

![Trois recadrages de l'avant de l'établi. Le premier : une ellipse grise uniforme avec un léger ombrage là où étaient les objets. Le deuxième : une ellipse nette de bois pâle et rugueux, avec un bord sombre le long de son haut. Le troisième : deux nouveaux objets en bois sur l'établi, sans bord visible.](../../../../assets/comfyui/journal-l05-failures.webp)

*Deux échecs d'inpainting et la correction, avant de recoller le résultat. ComfyUI v0.36.0 : Stable Diffusion XL base 1.0, graine 42, 25 étapes, CFG 7, `euler`, `normal`. De gauche à droite : [`05-inpaint-vaeencode.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json) avec `denoise` 0,5 ; le même workflow avec `denoise` 1 et un masque au bord adouci sur 24 pixels ; [`05-inpaint-model.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json), le UNet SD-XL inpainting 0.1 avec `denoise` 0,99, sur le même masque adouci.*

- La fiche de SD-XL inpainting dit de garder `strength` sous 1,0 ; 1,0 et 0,99 ont donné ici presque la même image (0,01 % des pixels diffèrent de plus de 8).
- Le résultat d'inpainting décodé a changé de plus de 8 niveaux 6,2 % des pixels hors du masque ; le recoller avec `ImageCompositeMasked` les a laissés identiques.
- La page de documentation de `SetUnionControlNetType` liste 13 types ; le nœud en a 8.
- La première exécution en CI du nœud `Canny` a échoué sous les trois systèmes : quatre machines ont donné quatre hachages de pixels. Les trois runners ont trouvé 467 pixels de contour, la machine de l'auteur 464. La CI les affiche maintenant à titre d'information.

![Des lignes de contour blanches sur fond noir, dessinées en gros pixels : un nid d'abeilles de cellules ondulées tiré de la mire de test du cours.](../../../../assets/comfyui/journal-canny-ci.webp)

*La sortie du nœud `Canny` sur la machine de l'auteur, hachage de pixels `77af5cb1b7e93a5c`, 464 pixels de contour, agrandie quatre fois sans lissage. ComfyUI v0.36.0 sur le CPU, sans modèle, seuils 0,05 et 0,15, workflow [`05-masks.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-masks.api.json). Les trois runners de la CI ont chacun dessiné 467 pixels de contour, avec trois autres hachages.*

- Avec `end_percent` à 0,3, le ControlNet a guidé 8 étapes sur 25, et l'image était presque la même qu'avec lui actif à chaque étape.
- Un LoRA coûte du temps avant la première étape, pas pendant l'échantillonnage : changer de LoRA a pris 4 à 5 secondes de plus, et une image en 4 étapes avec le LCM-LoRA a ensuite pris 1,16 seconde.

## 2026-09-16 — Modèles récents et quantification

- Z-Image-Turbo en bf16 avec son encodeur de texte bf16, soit 19,4 Go de poids, a tourné sur le GPU de 16 Go grâce à la VRAM dynamique : 63,93 secondes pour le premier rendu, puis 5,93 secondes à 1,5 étape par seconde. int8 avec l'encodeur de texte fp8 a tourné à 3,1 étapes par seconde, nvfp4 de 3,7 à 4,1.
- `nvidia-smi` a montré de 12,5 à 15,3 Go en usage pour chaque configuration : la VRAM dynamique utilise ce qui est libre. Les tailles préparées dans le log sont les chiffres utiles.
- Les images int8 sont restées proches de celles en bf16 (9 à 15 % des pixels diffèrent de plus de 8) ; les images nvfp4 montraient la même scène disposée autrement (62 à 74 %).

![Quatre rendus côte à côte, chacun un métronome pyramidal or et noir sur un établi en bois usé devant une fenêtre. Les deux premiers sont presque identiques ; les deux derniers montrent la même scène avec les objets disposés autrement.](../../../../assets/comfyui/l08-quantized.webp)

*ComfyUI v0.36.0 : Z-Image-Turbo, graine 42, 8 étapes, CFG 1, `res_multistep`, `simple`, workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). De gauche à droite : bf16 avec l'encodeur de texte bf16, int8 avec fp8, nvfp4 avec fp4, nvfp4 avec bf16.*

- `qwen_3_4b_fp8_mixed` a 12 couches nvfp4, et `qwen_3_4b_fp4_mixed` a 58 couches fp8. Le fichier Z-Image nvfp4 garde ses quatre blocs de raffinement en bf16.
- Avec `--disable-dynamic-vram`, le premier rendu bf16 a pris 78,87 secondes et a donné les mêmes pixels qu'avec la VRAM dynamique. Le deuxième rendu a été arrêté quand la machine, partagée avec d'autres travaux, a manqué de RAM. Un lot bf16 antérieur avait été arrêté de la même façon : le serveur occupait 14,5 Go de RAM. Chaque serveur ne démarre maintenant que si les poids de la configuration, plus une marge, tiennent dans la RAM libre.
- FLUX.2 klein 4B a dessiné un support en laiton, pas un métronome, avec les graines 42, 43 et 44 ; Z-Image-Turbo a dessiné un métronome à chaque fois.

![Quatre rendus côte à côte. D'abord, le métronome pyramidal de Z-Image-Turbo sur un établi. Puis trois rendus d'un atelier poussiéreux par FLUX.2 klein 4B, chacun avec, au lieu d'un métronome, un support en laiton muni d'une manivelle ou de bras sur un établi usé.](../../../../assets/comfyui/l08-z-image-klein.webp)

*ComfyUI v0.36.0. D'abord : Z-Image-Turbo bf16, graine 43, workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). Ensuite : FLUX.2 klein 4B, graines 42, 43 et 44, 4 étapes, CFG 1, `euler`, workflow [`08-flux2-klein.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-flux2-klein.api.json).*

## 2026-09-16 — Les nœuds personnalisés et leur sécurité

- ComfyUI v0.36.0 importe chaque pack avec `exec_module` avant de lire `NODE_CLASS_MAPPINGS` ; `prestartup_script.py` s'exécute plus tôt, et le JavaScript de `WEB_DIRECTORY` s'exécute dans le navigateur. `hook_breaker_ac10a0.py` restaure une fonction après le chargement des packs ; rien d'autre ne sépare un pack du processus.
- ComfyUI-Manager est maintenant le paquet pip `comfyui_manager==4.2.2`, épinglé dans `manager_requirements.txt`. Les 42 fichiers `.py`, `.json` et `.md` de sa wheel sur PyPI sont identiques au tag `4.2.2`, commit `bd4ede22`. Il filtre les installations selon le niveau de sécurité, l'adresse d'écoute et deux nouveaux drapeaux, et cherche au démarrage des noms de paquets malveillants connus ; rien ne lit le code d'un pack.
- Le pack Guitar Alchemist (GA Chord Diagram, GA Fretboard Control Map, GA Scale Prompt) calcule à partir des tables d'accordage et de gammes de GA au commit `a826864f`, dessine avec Pillow sans police, et passe 14 tests unitaires avec seulement NumPy et Pillow. Chargé dans un répertoire de base jetable, avec le Python de la version portable, sur le CPU, il s'est importé en 0,0 s, a tourné en 0,06 s, et `SaveImage` a écrit les mêmes pixels que le PNG attendu du test. `--disable-all-custom-nodes`, `--whitelist-custom-nodes ga` et un dossier `.disabled` se sont comportés comme le dit le code source.
- Le script d'audit a tourné sur six packs épinglés le 16 septembre 2026 : ComfyUI-GGUF, comfyui_controlnet_aux, ComfyUI-Impact-Pack, ComfyUI-VideoHelperSuite, rgthree-comfy et ComfyUI_essentials. Aucun constat ne suggère une intention malveillante. Impact-Pack installe `onnxruntime` avec pip la première fois qu'un détecteur ONNX tourne, et son `install.py` télécharge un `.pth` de SAM. rgthree-comfy envoie le SHA-256 d'un fichier de modèle à Civitai quand l'interface demande ses informations. comfyui_controlnet_aux contient 72 appels à `torch.load` sans `weights_only`, sûrs par défaut seulement avec PyTorch 2.6 ou plus récent.
- Un pickle dont la charge appelle `print` s'est exécuté avec `pickle.loads` et avec `torch.load(weights_only=False)` ; `torch.load(weights_only=True)` l'a refusé avec PyTorch 2.13.

## 2026-09-16 — ComfyUI en production

- Lu dans ComfyUI v0.36.0 : un seul thread `prompt_worker` exécute un prompt à la fois ; un client peut choisir un `prompt_id`, qui doit être un UUID en minuscules ; le même identifiant envoyé deux fois s'exécute deux fois et écrase son entrée d'historique ; `execution_success` est envoyé avant l'écriture de l'historique ; `execution_interrupted` est diffusé à tous ; une reconnexion ne rejoue rien. Un script d'enregistrement a provoqué ces cas sur un serveur CPU et sauvegardé les réponses.
- Un worker en C# et en Java avec les mêmes lignes de log : une file en mémoire (un `Channel` en C#, une `LinkedBlockingQueue` et des threads virtuels en Java) ou RabbitMQ, l'identifiant du job comme `prompt_id`, un fichier de réservation et `done.json` pour l'idempotence, un backoff exponentiel avec full jitter, les 400 et les erreurs d'exécution ordinaires aux lettres mortes, les manques de mémoire et les 5xx retentés, une interruption à l'expiration du délai, un pool de GPU qui choisit le serveur avec le moins de prompts devant, et la gestion de SIGTERM avec un délai de grâce.
- Un faux ComfyUI en ASP.NET Core rejoue les réponses enregistrées selon un script de pannes. 11 tests xUnit et 9 tests JUnit passent, et les deux workers affichent les mêmes transcriptions sous Windows, Linux et macOS en CI. Contre un vrai ComfyUI sur CPU, le worker C# a exécuté quatre jobs (un doublon, une lettre morte), et le worker Java, sur le même serveur, a retrouvé les prompts terminés dans l'historique sans les exécuter à nouveau.
- La première exécution de la CI s'est bloquée sous Linux et macOS : les faux serveurs survivaient à `kill`. Ils attendent maintenant SIGTERM avec `PosixSignalRegistration`.
- L'expérience « accord vers manche » du labo GA tourne en vingt jobs avec un CSV de résultats contre le faux serveur. Les adaptateurs RabbitMQ, les notes de déploiement et une exécution sur GPU restent à vérifier.

## 2026-09-16 — Les modèles des leçons 9 et 10

- Téléchargés sur le disque des modèles et vérifiés avec le SHA-256 de l'API d'arborescence de Hugging Face : `RealESRGAN_x4plus.safetensors` (66 857 836 octets, BSD-3-Clause), `film_net_fp16.safetensors` (68 882 302 octets), et pour Wan 2.2 TI2V 5B, sous Apache 2.0, `wan2.2_ti2v_5B_fp16.safetensors` (9 999 658 848 octets), `umt5_xxl_fp8_e4m3fn_scaled.safetensors` (6 735 906 897 octets) et `wan2.2_vae.safetensors` (1 409 400 960 octets). Les 18,1 Go de Wan ont pris 10 minutes.
- Le reconditionnement de Comfy-Org n'a pas de fichier fp8 de TI2V 5B, seulement fp16.

## 2026-09-16 — Agrandissement, textures raccordables et HDR

- La règle de RAM a choisi le modèle à chaque démarrage du serveur : Z-Image-Turbo nvfp4 avec 22 Go de RAM libre, int8 avec 24 Go. La RAM libre est descendue à 9 Go pendant les rendus int8.
- Une étape d'échantillonnage a pris environ 0,3 seconde en 1024 × 1024 et de 2,2 à 2,8 secondes en 2048 × 2048.
- Un `VAEDecode` simple du latent 2048 × 2048 a tenu sur le GPU ; son image diffère de celle de `VAEDecodeTiled` de 0,93 niveau en moyenne.
- L'agrandissement dans l'espace latent a laissé un grain bruité et des cordes dédoublées à un denoise de 0,3.
- Le PNG 16 bits de `SaveImageAdvanced` tiré d'un rendu 8 bits a 256 niveaux par canal, et son EXR n'a aucune valeur au-dessus de 1,0. Le client C# s'arrêtait au premier PNG 16 bits : il les décode maintenant, et liste les fichiers EXR et AVIF par taille.
- Le premier essai de texture raccordable, avec une croix de 160 pixels, 64 pixels de fondu et un denoise de 0,7, a divisé les raccords par deux (de 13,4 à 5,2 niveaux sur la ligne du milieu) mais a laissé une ligne mouchetée et une marche de ton. Un denoise de 0,9 n'a pas aidé ; une croix de 384 pixels avec 128 pixels de fondu, si.
- « Pale maple » (érable pâle) a dessiné des feuilles d'érable sculptées dans le bois. « Pale maple wood, a planed board » (bois d'érable pâle, une planche rabotée) a dessiné une planche.

![Trois panneaux. Une répétition 2 × 2 d'une texture de palissandre, avec de légères lignes horizontales et verticales à travers chaque tuile. Un recadrage du milieu de cette texture, où une rangée de mouchetures sombres traverse le fil du bois et où la moitié inférieure est plus claire. Une répétition 2 × 2 d'un bois pâle avec une grande feuille d'érable sculptée dans chaque tuile.](../../../../assets/comfyui/journal-l09-seamless-failures.webp)

*Les échecs, avant la correction. ComfyUI v0.36.0 : Z-Image-Turbo nvfp4 avec Qwen3 4B fp4 mixed, graine 42, 8 étapes, CFG 1, `res_multistep`, `simple`, workflow [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-seamless.api.json) avec sa croix réglée à 160 pixels, 64 de fondu et un denoise de 0,7. De gauche à droite : le palissandre répété 2 × 2 ; les 512 × 512 pixels du milieu du palissandre ; le prompt « flat top-down photograph of pale maple, subtle straight grain, even soft lighting, no shadows, wood texture » (photo à plat, vue de dessus, d'érable pâle au fil fin et droit, sous un éclairage doux et uniforme, sans ombres, texture de bois), répété 2 × 2.*

## 2026-09-17 — Un modèle 3D publié avant d'avoir lu sa licence

- Le 16 septembre, la session Atlas a généré un métronome et un gramophone sous forme de maillages 3D, à partir d'images SDXL, avec Hunyuan3D 2.0 et les nœuds du cœur de ComfyUI. Le journal du cours Blender a publié leurs rendus à 00 h 23 le 17 septembre, dans le commit `a165915`.
- En lisant la licence pour l'expérience image vers 3D du labo GA, la session learn-33 a trouvé la clause 5.c de la [Tencent Hunyuan 3D 2.0 Community License](https://huggingface.co/tencent/Hunyuan3D-2/blob/9cd649ba6913f7a852e3286bad86bfa9a2d83dcf/LICENSE) : « You must not use, reproduce, modify, distribute, or display the Tencent Hunyuan 3D 2.0 Works, Output or results of the Tencent Hunyuan 3D 2.0 Works outside the Territory. Any such use outside the Territory is unlicensed and unauthorized under this Agreement. » Le Territoire exclut l'Union européenne, le Royaume-Uni et la Corée du Sud, et ce site est public. Notre erreur : les rendus ont été publiés avant que quiconque ait lu la clause 5.c.
- À 00 h 44, l'utilisateur a décidé : Hunyuan3D reste sur la machine locale, et tout ce qui est publié utilise TRELLIS.2 (MIT, avec DINOv3 sous sa propre licence) ou des modèles construits par du code. Le cours Blender a retiré les deux rendus dans le commit `c8a5a33` et décrit avec des mots ce qu'ils montraient.
- TRELLIS.2 demande ici environ 23 Go de RAM libre, et l'amont demande 24 Go de VRAM ; il n'a pas tourné. Les deux objets sont remodélisés avec `bpy` à la place : le journal Blender raconte ce côté de l'histoire, [avant](../../blender/journal/#2026-09-17--des-modèles-générés-dans-comfyui-nettoyés-dans-blender) et [après](../../blender/journal/#2026-09-22--modéliser-en-bpy-face-à-limage3d).
- La leçon 8 contient maintenant une section sur [la lecture d'une licence avant de publier une sortie](../08-recent-models-quantization/#lire-la-licence-avant-de-publier-une-sortie), avec les clauses et la comparaison des trois routes. Aucune image de Hunyuan3D ne paraît dans ce cours.

## 2026-09-19 — Vérification ComfyUI pour la scène orbitale

Un serveur CPU séparé (0.36.0, localhost:8193) a confirmé les classes de nœuds du workflow Canny du cours, le checkpoint SDXL et le ControlNet union installés. Aucun prompt soumis ; inférence GPU : 0 s. Le serveur a ensuite été arrêté. Effet inattendu : `--base-directory` seul a déplacé l'ancien `user/comfyui.db` de l'installation vers un `.bak` et l'a copié dans le répertoire de test. Le fichier d'origine a été restauré depuis cette sauvegarde, sans écraser un autre fichier ; les deux SHA-256 sont identiques. La sauvegarde est conservée. Les prochains tests isolés devront préciser `--database-url sqlite:///:memory:` ou une URL de base propre au test. L'inférence et la qualité d'image restent à vérifier.

## 2026-09-19 — Prétraitement réel de Blender vers ComfyUI

Le rendu Blender v2 a été copié dans le répertoire d'entrée ComfyUI isolé. `LoadImage → Canny → SaveImage` a réussi sur CPU en **3.731 s** (horodatages de l'historique) ; l'image a été inspectée. Les contours des anneaux, piliers et de l'allée restent visibles. C'est une image de contrôle, pas une scène générée par SDXL ni une nouvelle géométrie 3D. Identifiant : `7f26de5e-5d83-455c-97be-1e3401e9ba5f`. Sortie : `C:/tmp/blender-comfy-scenes-20260919/comfy-base/output/orbital-study/canny-edges_00001_.png`. La base explicitement en mémoire a empêché la migration précédente ; le hash de la base de l'installation est inchangé. Temps GPU et appels API payants : **0**. L'inférence SDXL a été différée pour ne pas charger les deux modèles avec seulement environ 10 Gio de RAM disponibles.

## 2026-09-22 — Un workflow vérifié avant le GPU, et un défaut dans notre propre vérificateur

- Les workflows de la leçon 10 étaient écrits mais jamais lancés : la machine n'a pas eu la mémoire libre pour Wan 2.2. Plutôt que d'attendre, un serveur ComfyUI a été démarré sans aucun modèle, sur le CPU, dans le seul but d'enregistrer son `/object_info` : 957 classes de nœuds, 1,85 Mo. Le serveur a été arrêté aussitôt.
- Comparés à ce fichier, les 26 workflows du cours sont bons. `Wan22ImageToVideoLatent`, `CreateVideo`, `SaveVideo`, `FrameInterpolationModelLoader` et `FrameInterpolate` sont dans le cœur en v0.36.0, `film_net_fp16` figure dans la liste du chargeur, et les noms des fichiers Wan 2.2 sont ceux que voit le serveur — les chemins de modèles supplémentaires sont donc justes. La leçon 10 peut partir dès que la mémoire est là.
- La vérification a d'abord annoncé que `SaveVideo` n'avait pas d'entrée `format.codec`, sur les trois workflows. Elle avait tort, et le défaut était le nôtre : [`Workflow.cs`](https://github.com/spareilleux/learn/blob/main/code/comfyui/csharp/Workflow.cs) ne lisait que les entrées `required` et `optional` de premier niveau, alors qu'un `COMFY_DYNAMICCOMBO_V3` porte ses enfants dans ses options. Il les parcourt maintenant, et contrôle aussi les clés d'options. La leçon 3 a [la section](../03-workflow-json/#des-entrées-avec-un-point-dans-le-nom), et `check.sh` un jeu d'essai avec les trois fautes possibles sur une entrée à point.
- Un vérificateur qui n'a jamais échoué ne prouve rien. Celui-ci a désormais un fichier qui doit échouer, et les quatre nouvelles lignes d'`expected/03-validate.txt` sont ce qu'il doit imprimer.
- Le même jour, chaque leçon écrite a reçu une section « à toi de jouer » — la 9 était la seule à finir par quelque chose à faire sur sa propre machine — et les trente images du cours ont été rassemblées dans une [galerie](../gallery/), chacune avec le workflow qui l'a faite, à la révision qui l'a faite.

## 2026-09-22 — Où Canny cesse de coïncider, et ce que `convrot` fait tourner

- La question ouverte de la leçon 6 a sa réponse. [`data/canny-steps.py`](https://github.com/spareilleux/learn/blob/main/code/comfyui/data/canny-steps.py) calcule une empreinte par étape du filtre de Kornia sur un motif de 64 sur 48 construit en arithmétique entière, et `check.sh` l'exécute sur les trois machines de CI. L'entrée fait les mêmes octets partout. Le flou gaussien sépare déjà la machine de l'auteur des runners, et le runner Apple Silicon des deux x86 ; le gradient spatial diffère sur les quatre, alors que Windows et Linux coïncidaient une étape plus tôt — la même convolution emprunte un chemin différent selon la compilation. Toutes les magnitudes diffèrent, et leur somme affiche toujours 2729.489258.
- Les contours, eux, sont identiques sur les quatre machines : 1 461 pixels sur 3 072, une seule empreinte. Ce motif n'est fait que d'aplats et de bords francs, donc rien ne passe près d'un seuil. C'est l'autre moitié de la réponse — la divergence est toujours là, dès la première convolution ; c'est l'image qui décide si elle se voit. [La leçon 6](../06-controlnet/#létape-où-ça-cesse-de-coïncider) a le tableau.
- `convrot` était une supposition écrite dans la leçon 8, « une rotation de groupes de poids avant la quantification ». comfy-kitchen 0.2.34 la confirme et dit laquelle : une matrice de Hadamard régulière, symétrique et orthogonale, sur des groupes de 256 canaux d'entrée — le poids hors ligne, les activations en ligne, fusionné dans le quantificateur par ligne. Étant sa propre inverse, elle laisse le produit intact et ne change que ce que l'int8 doit contenir. [`data/convrot.py`](https://github.com/spareilleux/learn/blob/main/code/comfyui/data/convrot.py) la reconstruit, identique à celle de la bibliothèque pour les tailles 16, 64 et 256, et mesure l'erreur d'aller-retour sur un poids ayant une valeur aberrante par ligne : 5,7 % sans rotation, 0,76 % avec.
- Le point EXR de la leçon 9 a gagné la conséquence qui compte pour le partage : un workflow construit là où `.exr` a un type MIME désigne une image que la liste de la machine suivante ne proposera pas. Le fichier reste valide ; le rendu cesse d'être reproductible.

## À vérifier

- SDXL sous Linux avec CUDA, et sur Apple Silicon avec MPS : la machine GPU du cours tourne sous Windows ; la CI n'installe que les versions CPU.
- Quelle opération fait donner aux encodeurs de texte des résultats différents selon que l'UNet est chargé ou non, et si cela arrive avec d'autres GPU ou d'autres pilotes.
- Si un sampler ancestral donne la même image sur le CPU et sur le GPU pour une graine : son bruit d'étape est tiré sur le périphérique.
- Si un hachage perceptuel serait stable dans les cas de la leçon 2.
- Les chaînes de ControlNet, `start_percent`, et l'étape exacte où tombe le niveau de bruit d'un pourcentage, que la leçon a calculée mais pas rendue.
- Entraîner un LoRA avec les nœuds expérimentaux de ComfyUI, et quelle part des 16 Go cela prend pour SDXL.
- Des LoRA empilés dans l'autre ordre : même image, et même hachage de pixels ou non.
- Le chemin émulé pour nvfp4 et fp8 sur un GPU sans leurs noyaux ; la machine du cours n'a qu'un GPU de la série RTX 50.
- Pourquoi le réseau Z-Image nvfp4 échantillonnait plus vite avec l'encodeur de texte bf16 qu'avec celui en fp4.
- Échantillonner les tuiles de `SplitImageToTileList` et les fusionner avec `ImageMergeTileList` : si des raccords se voient à un denoise faible.
- Si l'`EXRLoader` de three.js lit dans un navigateur l'EXR non compressé de ComfyUI.
- Comment les navigateurs affichent l'AVIF HLG de `SaveImageAdvanced`.
- Les temps de rendu à chaud avec `--disable-dynamic-vram`, sur une machine avec assez de RAM libre.
- `execution_interrupted` tel que les clients l'affichent, et `POST /interrupt` avec un identifiant de prompt : il faut une exécution assez longue à interrompre, donc un modèle.
