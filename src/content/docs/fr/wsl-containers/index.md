---
title: WSL containers — Mission
description: Apprendre à faire tourner des conteneurs Linux sur Windows avec wslc.exe, intégré à WSL.
sidebar:
  label: Mission
  order: 0
---

:::caution[Préversion]
WSL containers est en **préversion publique** (annoncée à Microsoft Build 2026, disponible depuis le 30 juin 2026).
Ce cours étudie **WSL 2.9.11** (canal pre-release). Les commandes peuvent changer avant la version stable, attendue à l'automne 2026.
:::

## Pourquoi j'apprends ça

J'utilise Docker Desktop **et** Podman sur la même machine Windows, chacun avec sa propre VM WSL.
Microsoft intègre désormais un outil de conteneurs directement dans WSL : `wslc.exe`.
Je veux savoir s'il peut remplacer — ou compléter — Docker Desktop pour mon usage quotidien, et comment l'utiliser depuis mes propres applications.

## À la fin de ce cours, je saurai

- expliquer ce qu'est WSL containers et comment il se situe par rapport à WSL 2 et Docker Desktop ;
- installer la bonne version de WSL et diagnostiquer un échec d'installation ;
- lancer, inspecter, publier et arrêter des conteneurs avec `wslc` ;
- construire une image à partir d'un `Containerfile` ;
- décider quand utiliser `wslc` plutôt que Docker Desktop.

## Prérequis

- Windows 11 avec WSL 2 installé.
- Notions de base sur les conteneurs (image, conteneur, port) — la leçon 1 les rappelle.
- Un terminal PowerShell ; un accès administrateur pour la mise à jour de WSL.

## Plan

1. [Concepts](01-concepts/) — conteneurs, WSL 2, et où se place `wslc`.
2. [Installation](02-installation/) — passer en pre-release, vérifier, dépanner.
3. [Premiers conteneurs](03-first-containers/) — `run`, ports, `exec`, `stop`.
4. [Construire une image](04-build-an-image/) — `Containerfile`, `build`, logs, nettoyage.
5. [wslc ou Docker Desktop ?](05-wslc-vs-docker/) — comparaison et API pour applications Windows.
6. [Journal](journal/) — mes essais, erreurs et points à vérifier.

## Ressources

- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container) : vue d'ensemble, CLI et API.
- [Get started with containers on WSL — Microsoft Learn](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers) : tutoriel officiel.
- [WSL container is now available for public preview — Windows Command Line blog](https://devblogs.microsoft.com/commandline/wsl-container-is-now-available-for-public-preview/) : annonce.
- [Notes de version WSL — GitHub](https://github.com/microsoft/WSL/releases) : versions stables et pre-release.
- [Référence de l'API WSL container](https://wsl.dev/api-reference/) et [exemples](https://aka.ms/wslc-samples).
