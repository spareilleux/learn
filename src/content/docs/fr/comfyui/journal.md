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
- [ ] Leçon 9 : agrandissement, textures raccordables et HDR

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

## 2026-09-16 — Une graine, deux images

- Le même workflow et la même graine ont donné `698e7867…` sur un serveur fraîchement démarré, de nouveau après des redémarrages, et `5374ac40…` chaque fois que le prompt négatif était encodé de nouveau avec l'UNet déjà chargé. Les deux images diffèrent en moyenne de 0,92 niveau, et 2,63 % des pixels diffèrent de plus de 8.
- `--disable-dynamic-vram` a donné `5374ac40…` dès la première exécution aussi. `--deterministic` n'a changé aucun des deux résultats. Je n'ai pas trouvé quelle opération diffère.
- La première image d'un lot de deux différait de l'image seule de même graine (moyenne 0,74), et la seconde image du lot n'est pas celle de la graine 43.
- Un rendu de graine 43 par le client Java, sur un autre démarrage du serveur 20 minutes plus tard, avait les mêmes pixels que le premier rendu de graine 43.

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
- La fiche de SD-XL inpainting dit de garder `strength` sous 1,0 ; 1,0 et 0,99 ont donné ici presque la même image (0,01 % des pixels diffèrent de plus de 8).
- Le résultat d'inpainting décodé a changé de plus de 8 niveaux 6,2 % des pixels hors du masque ; le recoller avec `ImageCompositeMasked` les a laissés identiques.
- La page de documentation de `SetUnionControlNetType` liste 13 types ; le nœud en a 8.
- La première exécution en CI du nœud `Canny` a échoué sous les trois systèmes : quatre machines ont donné quatre hachages de pixels. Les trois runners ont trouvé 467 pixels de contour, la machine de l'auteur 464. La CI les affiche maintenant à titre d'information.
- Avec `end_percent` à 0,3, le ControlNet a guidé 8 étapes sur 25, et l'image était presque la même qu'avec lui actif à chaque étape.
- Un LoRA coûte du temps avant la première étape, pas pendant l'échantillonnage : changer de LoRA a pris 4 à 5 secondes de plus, et une image en 4 étapes avec le LCM-LoRA a ensuite pris 1,16 seconde.

## 2026-09-16 — Modèles récents et quantification

- Z-Image-Turbo en bf16 avec son encodeur de texte bf16, soit 19,4 Go de poids, a tourné sur le GPU de 16 Go grâce à la VRAM dynamique : 63,93 secondes pour le premier rendu, puis 5,93 secondes à 1,5 étape par seconde. int8 avec l'encodeur de texte fp8 a tourné à 3,1 étapes par seconde, nvfp4 de 3,7 à 4,1.
- `nvidia-smi` a montré de 12,5 à 15,3 Go en usage pour chaque configuration : la VRAM dynamique utilise ce qui est libre. Les tailles préparées dans le log sont les chiffres utiles.
- Les images int8 sont restées proches de celles en bf16 (9 à 15 % des pixels diffèrent de plus de 8) ; les images nvfp4 montraient la même scène disposée autrement (62 à 74 %).
- `qwen_3_4b_fp8_mixed` a 12 couches nvfp4, et `qwen_3_4b_fp4_mixed` a 58 couches fp8. Le fichier Z-Image nvfp4 garde ses quatre blocs de raffinement en bf16.
- Avec `--disable-dynamic-vram`, le premier rendu bf16 a pris 78,87 secondes et a donné les mêmes pixels qu'avec la VRAM dynamique. Le deuxième rendu a été arrêté quand la machine, partagée avec d'autres travaux, a manqué de RAM. Un lot bf16 antérieur avait été arrêté de la même façon : le serveur occupait 14,5 Go de RAM. Chaque serveur ne démarre maintenant que si les poids de la configuration, plus une marge, tiennent dans la RAM libre.
- FLUX.2 klein 4B a dessiné un support en laiton, pas un métronome, avec les graines 42, 43 et 44 ; Z-Image-Turbo a dessiné un métronome à chaque fois.
## À vérifier

- SDXL sous Linux avec CUDA, et sur Apple Silicon avec MPS : la machine GPU du cours tourne sous Windows ; la CI n'installe que les versions CPU.
- Quelle opération fait donner aux encodeurs de texte des résultats différents selon que l'UNet est chargé ou non, et si cela arrive avec d'autres GPU ou d'autres pilotes.
- Si un sampler ancestral donne la même image sur le CPU et sur le GPU pour une graine : son bruit d'étape est tiré sur le périphérique.
- Si un hachage perceptuel serait stable dans les cas de la leçon 2.
- Les chaînes de ControlNet, `start_percent`, et l'étape exacte où tombe le niveau de bruit d'un pourcentage, que la leçon a calculée mais pas rendue.
- Le `canny` de Kornia : quelle étape fait différer les contours d'une machine à l'autre.
- Entraîner un LoRA avec les nœuds expérimentaux de ComfyUI, et quelle part des 16 Go cela prend pour SDXL.
- Des LoRA empilés dans l'autre ordre : même image, et même hachage de pixels ou non.
- Le chemin émulé pour nvfp4 et fp8 sur un GPU sans leurs noyaux ; la machine du cours n'a qu'un GPU de la série RTX 50.
- Pourquoi le réseau Z-Image nvfp4 échantillonnait plus vite avec l'encodeur de texte bf16 qu'avec celui en fp4.
- Ce que fait l'option `convrot` d'int8 dans les noyaux de comfy-kitchen.
- Les temps de rendu à chaud avec `--disable-dynamic-vram`, sur une machine avec assez de RAM libre.
- `execution_error` et `execution_interrupted` tels que les clients les affichent, `POST /interrupt` avec un identifiant de prompt, et la suppression d'un prompt en file d'attente : aucune exécution ne les a encore produits.
