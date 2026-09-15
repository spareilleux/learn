---
title: "L'IA de GA : OPTIC-K, ML, agents et chatbot — Mission"
description: Le côté apprentissage automatique et agents de Guitar Alchemist, pour développeurs C# — l'embedding OPTIC-K, l'index de voicings et sa recherche, le routage et les agents du chatbot, et ce que le chatbot doit devenir, chaque partie exécutée hors ligne contre le code même de GA.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Chaque tableau de sortie des leçons vient de [`code/ga-ai`](https://github.com/spareilleux/learn/tree/main/code/ga-ai), un programme console .NET 10 qui référence directement trois projets de Guitar Alchemist : `GA.Business.ML`, l'outil en ligne de commande qui écrit l'index de voicings, et l'hôte du chatbot `GaChatbot.Api`. GA est cloné au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Le programme n'a besoin ni de clé d'API, ni de GPU, ni de serveur de modèles : il construit lui-même un petit index, et démarre le chatbot dans son propre processus, avec une adresse de modèle qui pointe vers un port fermé. [`.github/workflows/ga-ai-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ga-ai-examples.yml) l'exécute sous Linux, Windows et macOS et compare la sortie de chaque leçon avec les fichiers de `expected/`. Les sorties ont été capturées en septembre 2026.
:::

## Pourquoi j'apprends ça

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) a un chatbot pour guitaristes. Derrière lui, il y a une description en 240 nombres de chaque forme d'accord à la guitare, appelée OPTIC-K, un index de 313 047 de ces descriptions, un routeur qui décide quel morceau de code répond à une question, et une poignée d'agents qui appellent un modèle de langage. La documentation autour est abondante et en partie périmée, et le code bouge chaque semaine.

Je veux savoir ce qui se passe vraiment : quels nombres reçoit un accord, pourquoi deux accords ressortent comme semblables, ce que contient le fichier d'index, et ce que fait le chatbot d'une question quand aucun modèle n'est joignable. Pour le découvrir, j'appelle les classes de GA depuis un programme, j'affiche ce qu'elles renvoient, et je le compare à ce que disent les commentaires et les documents. Là où les deux divergent, la différence va dans le [journal](journal/).

## À qui s'adresse ce cours

Tu écris du C#. Tu connais `float[]`, LINQ, l'injection de dépendances et ASP.NET Core assez pour lire un `Program.cs`. Tu n'as besoin d'aucune connaissance en apprentissage automatique : le cours utilise trois idées, chacune expliquée là où elle apparaît pour la première fois.

1. **Un embedding** (plongement vectoriel) est un tableau de nombres de longueur fixe qui décrit un objet, de sorte que des objets semblables reçoivent des tableaux semblables.
2. **La similarité cosinus** mesure à quel point deux tels tableaux pointent dans la même direction : 1 pour la même direction, 0 pour rien en commun.
3. **La recherche des plus proches voisins** renvoie les tableaux stockés les plus proches d'un tableau de requête.

Trois autres cours de ce site couvrent les bases, et celui-ci renvoie vers eux au lieu de les répéter :

- [Théorie musicale pour Guitar Alchemist](../music-theory-ga/) : classes de hauteurs, voicings, vecteurs d'intervalles et classes d'ensembles, le vocabulaire qu'encode OPTIC-K ;
- [Apprentissage automatique, appliqué dans IX](../machine-learning-ix/) : caractéristiques, distances, plus proches voisins et partitionnement, écrits à la main ;
- [Programmation agentique avec Claude Code et Codex](../agentic-coding/) : la boucle d'outils, les hooks, les skills et les serveurs MCP, du point de vue d'un développeur qui utilise des agents.

## À la fin de ce cours, je saurai

- dessiner la pile IA de GA : quel projet calcule les embeddings, lequel écrit l'index, lequel route un message de chat, et ce que font ix, Demerzel et TARS autour ;
- lire un vecteur OPTIC-K partition par partition, calculer à la main la similarité pondérée de deux voicings, et dire à quoi le vecteur est invariant et à quoi il ne l'est pas ;
- ouvrir un fichier d'index OPTK, expliquer son en-tête, et prédire ce que renvoie une recherche et pourquoi ;
- suivre un message de chat à travers les hooks, les gardes déterministes, le routeur d'intentions et les agents de GA, et expliquer pourquoi certaines questions fonctionnent sans modèle et d'autres échouent ;
- distinguer, dans l'IA de GA, ce qui fonctionne aujourd'hui, ce qui est en construction, et ce qui n'est que prévu.

## Plan

| # | Leçon | Dans GA | Si tu écris du C# |
|---|---|---|---|
| 1 | [La carte](01-the-map/) | les cinq couches, le pipeline de l'index, l'hôte du chatbot, les dépôts voisins | lire un conteneur d'injection de dépendances, `WebApplicationFactory` |
| 2 | [Les embeddings OPTIC-K](02-optic-k-embeddings/) | `EmbeddingSchema`, `MusicalEmbeddingGenerator`, `VoicingAnalyzer` | records positionnels, `TensorPrimitives` |
| 3 | [L'index et la recherche](03-index-and-search/) | `OptickIndexWriter`, `OptickIndexReader`, `OptickSearchStrategy`, `MusicalQueryEncoder` | formats binaires, fichiers mappés en mémoire, tas top-k |
| 4 | [Le chatbot et ses agents](04-chatbot-and-agents/) | `ProductionOrchestrator`, `SemanticIntentRouter`, `SemanticRouter`, skills, hooks | services hébergés, replis, tester un hôte dans le processus |
| — | [Journal](journal/) | | |

## Prérequis

- Le [SDK .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) et [Git](https://git-scm.com/downloads). Sous Windows, lance les scripts du cours depuis Git Bash.
- Environ 20 Mo de disque pour le clone partiel de GA, et environ 1,1 Go une fois les projets de GA et le programme du cours compilés.
- Une connexion réseau pour la première exécution seulement, pour cloner GA et restaurer les paquets NuGet. Ensuite, tout s'exécute hors ligne.
- Pas besoin de guitare, mais les formes d'accords de la leçon 2 sont les premières qu'apprend un guitariste.

## Ressources

- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) au commit `a826864`, en particulier son [`CLAUDE.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/CLAUDE.md), les [documents du schéma OPTIC-K](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Documentation/Schema) et la [feuille de route du chatbot](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/docs/plans/2026-05-07-chatbot-roadmap.md).
- Clifton Callender, Ian Quinn et Dmitri Tymoczko, ["Generalized Voice-Leading Spaces"](https://doi.org/10.1126/science.1153021), *Science* 320, 2008 : l'article qui a nommé les équivalences OPTIC.
- Jared Updike, [Harmonious](https://harmoniousapp.net/) : une référence exhaustive des accords et des gammes pour piano et guitare. Sa page [Equivalence Groups](https://harmoniousapp.net/p/ec/Equivalence-Groups) illustre chaque équivalence OPTIC par des diagrammes d'accords, et ajoute le K d'OPTIC-K, pour la complémentarité.
- [Tests d'intégration dans ASP.NET Core](https://learn.microsoft.com/aspnet/core/test/integration-tests), pour `WebApplicationFactory`, et [Microsoft.Extensions.AI](https://learn.microsoft.com/dotnet/ai/microsoft-extensions-ai), les abstractions par lesquelles le chatbot de GA appelle les modèles.
