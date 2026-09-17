---
title: Journal
description: Notes d'avancement datées du cours ComfyUI — ComfyUI v0.36.0 et SDXL base 1.0 épinglés, une version portable avec son propre répertoire de base, deux images pour une graine, les sorties du serveur ordonnées par un ensemble et ses erreurs de validation, des tailles zlib qui changent selon le système, une CI sur CPU sous trois systèmes, et les points à vérifier.
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
- [x] Traductions en français et en espagnol
- [ ] Leçon 5 : img2img, inpainting et outpainting

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

## À vérifier

- SDXL sous Linux avec CUDA, et sur Apple Silicon avec MPS : la machine GPU du cours tourne sous Windows ; la CI n'installe que les versions CPU.
- Quelle opération fait donner aux encodeurs de texte des résultats différents selon que l'UNet est chargé ou non, et si cela arrive avec d'autres GPU ou d'autres pilotes.
- Si un sampler ancestral donne la même image sur le CPU et sur le GPU pour une graine : son bruit d'étape est tiré sur le périphérique.
- Si un hachage perceptuel serait stable dans les cas de la leçon 2.
- `execution_error` et `execution_interrupted` tels que les clients les affichent, `POST /interrupt` avec un identifiant de prompt, et la suppression d'un prompt en file d'attente : aucune exécution ne les a encore produits.
