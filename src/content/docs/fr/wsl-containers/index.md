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
- faire tourner `wslc` à côté de Docker Desktop sans surprise d'image, de version ou de port ;
- limiter le CPU et la mémoire d'une session ou d'un conteneur, mesurer sa VM depuis Windows et récupérer son espace disque ;
- garder les données d'un service dans un volume nommé, et savoir quand un dossier Windows n'est pas le bon endroit ;
- reproduire une petite pile Compose avec un réseau, des volumes et des noms DNS ;
- piloter des conteneurs depuis un programme C# avec `Microsoft.WSL.Containers`, y compris une image construite par `dotnet build` ;
- expliquer ce que `wslc` 2.9.11 ne fait pas : Compose, Kubernetes, conteneurs privilégiés, extensions, interface graphique ;
- décider quand utiliser `wslc` plutôt que Docker Desktop.

## Prérequis

- Windows 11 avec WSL 2 installé.
- Notions de base sur les conteneurs (image, conteneur, port) — la leçon 1 les rappelle.
- Un terminal PowerShell ; un accès administrateur pour la mise à jour de WSL.
- Pour la leçon 9, le [SDK .NET](https://dotnet.microsoft.com/download) 10.

WSL containers n'existe que sous Windows, ce cours n'a donc pas de variantes Linux ou macOS : chaque commande est pour PowerShell sous Windows 11.

## Plan

1. [Concepts](01-concepts/) — conteneurs, WSL 2, et où se place `wslc`.
2. [Installation](02-installation/) — passer en pre-release, vérifier, dépanner.
3. [Premiers conteneurs](03-first-containers/) — `run`, ports, `exec`, `stop`.
4. [Construire une image](04-build-an-image/) — une API C# et une API Spring Boot WebFlux : `Containerfile` multi-étapes, `build`, logs, nettoyage.
5. [wslc ou Docker Desktop ?](05-wslc-vs-docker/) — comparaison, magasins d'images séparés, le même port publié deux fois sans erreur.
6. [Ressources et limites](06-resources-and-limits/) — `settings.yaml`, limites par conteneur, la VM de la session vue depuis Windows, compacter `storage.vhdx`.
7. [Volumes et un vrai service](07-volumes-and-a-real-service/) — qdrant à côté d'une copie Docker : ports, versions épinglées, volumes nommés, montages de dossiers.
8. [Compose sans Compose](08-compose/) — ce que fait vraiment Compose, les noms DNS sur un réseau, une traduction PowerShell, les health checks.
9. [Piloter des conteneurs depuis C#](09-csharp-api/) — `Microsoft.WSL.Containers` : un projet qui compile, les sessions, le nettoyage, `WslcImage` et `LoadImageAsync`.
10. [Réseau, Kubernetes et interface graphique](10-networking-kubernetes-gui/) — adresses publiées, réseaux par session, conteneurs de l'API sans réseau, k3s et `Privileged`, ce qui manque.
11. [Journal](journal/) — mes essais, erreurs et points à vérifier.

## Ressources

- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container) : vue d'ensemble, CLI et API.
- [Get started with containers on WSL — Microsoft Learn](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers) : tutoriel officiel.
- [WSL container is now available for public preview — Windows Command Line blog](https://devblogs.microsoft.com/commandline/wsl-container-is-now-available-for-public-preview/) : annonce.
- [Notes de version WSL — GitHub](https://github.com/microsoft/WSL/releases) : versions stables et pre-release.
- [Référence de l'API WSL container](https://wsl.dev/api-reference/) et [exemples](https://aka.ms/wslc-samples).
