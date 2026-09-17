---
title: Laboratoire Guitar Alchemist — Mission
description: Des prototypes de bout en bout construits sur les vraies données et le vrai code de Guitar Alchemist — chacun part d'une hypothèse écrite avant toute mesure, et publie ses chiffres et ses échecs.
sidebar:
  label: Mission
  order: 0
---

## Pourquoi ce laboratoire

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) contient beaucoup de mécanique : un index de 313 047 voicings plongés dans l'espace OPTIC-K, de la reconnaissance d'accords, la géométrie du manche, un manche en 3D, des générateurs d'images et de modèles. Les autres cours du site démontent chaque pièce : [la théorie musicale](../music-theory-ga/), [l'IA de GA](../ga-ai/), [three.js](../threejs/), [ComfyUI](../comfyui/), [Blender](../blender/). Ce laboratoire assemble les pièces en choses qu'on peut voir, entendre et tenir en main, et se demande à chaque fois si l'idée fonctionne vraiment.

Chaque prototype suit le même contrat.

1. **Une hypothèse, commitée d'abord.** Avant toute mesure, un fichier du dossier `results/` du prototype dit ce que j'attends, chiffres à l'appui. Si j'ai vu un chiffre avant de l'écrire, le fichier le dit.
2. **Des mesures.** Les chiffres viennent d'un script du dépôt, lancé sur une machine nommée, avec des données épinglées : le commit de GA, le SHA-256 du fichier, la graine de l'échantillon.
3. **Des échecs publiés.** Une prédiction qui se révèle fausse reste dans la leçon, à côté de ce qui s'est passé à la place.

## À qui s'adresse ce laboratoire

Vous écrivez du C# ou du Java, vous avez suivi au moins un des cours sur GA, et vous êtes curieux de voir à quoi ressemblent les données de GA quand on arrête de les lire à travers une API. Chaque prototype indique sur quelles leçons il s'appuie. Le code est en JavaScript pour le navigateur et Node.js, plus ce dont chaque prototype a besoin.

## Prérequis

- [Node.js](https://nodejs.org/) 24 et [Git](https://git-scm.com/downloads). Sous Windows, lancez les commandes depuis Git Bash.
- Un navigateur avec [WebGPU](https://developer.mozilla.org/docs/Web/API/WebGPU_API) : un Chrome ou un Edge récent. Ailleurs, les prototypes se replient sur WebGL 2.
- Pour les modes locaux qui lisent tout l'index de GA : un clone de [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) et environ 200 Mo pour le fichier d'index. Les pages publiées n'ont besoin que d'un navigateur.
- Utile en arrière-plan : la [leçon 2](../ga-ai/02-optic-k-embeddings/) et la [leçon 3](../ga-ai/03-index-and-search/) du cours sur l'IA de GA, la [leçon 5](../machine-learning-ix/05-dimensionality-reduction/) du cours d'apprentissage automatique avec IX, et la [leçon 8](../threejs/08-performance-instancing-batching-lod/) du cours three.js.

## Plan

| # | Prototype | Question | État |
|---|---|---|---|
| P1 | [Explorateur de l'espace des voicings](01-voicing-explorer/) | Peut-on voir l'espace des voicings de GA en trois dimensions, et que cache l'image ? | publié |
| P2 | [Joue un accord, vois l'univers](02-chord-universe/) | Reconnaissance d'accords dans le navigateur : FFT, estimation des notes, gabarits sur les qualités d'accords de GA, manche 3D, bracelet et accord suivant ; 624 grattés synthétiques et 17 enregistrements CC0, prédictions d'abord | publié |
| P3 | Pochettes d'album | Un modèle de diffusion peut-il faire une pochette qui dise quelque chose de vrai sur une grille d'accords ? | prévu |
| P4 | Passe de rendu IA | Une texture ou un éclairage générés améliorent-ils les scènes 3D de GA, mesurés face au rendu simple ? | prévu |
| P5 | Bracelets imprimables en 3D | Un bracelet de classes de hauteur peut-il devenir un objet imprimable, des données de GA à un maillage qui passe un slicer ? | prévu |
| P6 | Chaîne complète | Du micro à l'accord, au voicing, à l'image et à l'objet, d'une traite : où est-ce que ça casse ? | prévu |
| P7 | Modèle de jouabilité | Un petit modèle entraîné sur le CPU prédit-il la difficulté d'un voicing mieux que le coût écrit à la main dans GA ? | prévu |
| — | [Journal](journal/) | | |

## Ressources

- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), le code et les données que lit chaque prototype.
- Le code du laboratoire : [`code/ga-protos`](https://github.com/spareilleux/learn/tree/main/code/ga-protos), un dossier par prototype, testé par [`.github/workflows/ga-protos-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ga-protos-examples.yml).
- [three.js](https://threejs.org/) et son [WebGPURenderer](https://threejs.org/docs/pages/WebGPURenderer.html), [Vite](https://vite.dev/), et la [Web Audio API](https://developer.mozilla.org/docs/Web/API/Web_Audio_API).
- Clifton Callender, Ian Quinn et Dmitri Tymoczko, [« Generalized Voice-Leading Spaces »](https://doi.org/10.1126/science.1153021), *Science* 320, 2008 : les équivalences OPTIC qui donnent leur nom au plongement de GA.
