---
title: 1. Concepts
description: Conteneurs, WSL 2 et la place de wslc.exe.
sidebar:
  order: 1
---

## Un conteneur, en une phrase

Un **conteneur** emballe une application avec tout ce dont elle a besoin (bibliothèques, runtime, configuration) pour qu'elle s'exécute de la même façon partout.
On le lance à partir d'une **image**, un modèle en lecture seule que l'on télécharge depuis un registre ([Docker Hub](https://hub.docker.com/), par exemple) ou que l'on construit soi-même.

| Terme | Analogie | Exemple |
|---|---|---|
| Image | Une recette figée | `nginx`, `ubuntu:latest` |
| Conteneur | Un plat préparé à partir de la recette | le serveur `web` lancé depuis `nginx` |
| Registre | La bibliothèque de recettes | `docker.io` |
| Port publié | Le guichet entre Windows et le conteneur | `-p 8080:80` |

## Pourquoi il faut Linux

Les conteneurs Linux partagent le **noyau Linux** de la machine hôte. Windows n'en a pas : il faut donc une machine virtuelle Linux quelque part.
C'est exactement ce que fournit **[WSL 2](https://learn.microsoft.com/windows/wsl/about)** : une VM légère, gérée par Windows, avec un vrai noyau Linux.

## Trois façons d'avoir des conteneurs Linux sur Windows

| Approche | Qui gère la VM Linux | Outil |
|---|---|---|
| [Docker Desktop](https://docs.docker.com/desktop/) | Docker, via sa propre distro WSL `docker-desktop` | `docker` |
| [Podman](https://podman.io/) | Podman, via sa distro WSL `podman-machine-default` | `podman` |
| **WSL containers** | **WSL lui-même**, sans produit tiers | `wslc` |

La nouveauté : avec WSL containers, **le moteur de conteneurs fait partie de WSL**. Il n'y a rien d'autre à installer, et `wslc.exe` est livré avec WSL.

## Les deux composants

1. **La CLI `wslc.exe`** — pour construire, lancer et inspecter des conteneurs depuis un terminal. Elle reprend les habitudes de la CLI Docker.
2. **L'API WSL container** — un paquet NuGet ([`Microsoft.WSL.Containers`](https://www.nuget.org/packages/Microsoft.WSL.Containers)) qui permet à une **application Windows** d'utiliser des conteneurs Linux dans sa propre logique (C#, et C++/WinRT en préversion).

## À retenir

- Image = modèle ; conteneur = instance en cours d'exécution.
- Les conteneurs Linux ont besoin d'un noyau Linux → WSL 2 le fournit.
- `wslc` = conteneurs intégrés à WSL, sans Docker Desktop.

## Exercices

1. Liste les distributions WSL présentes sur ta machine. Lesquelles appartiennent à un outil de conteneurs ?

<details>
<summary>Solution</summary>

```powershell
wsl -l -v
```

```text
  NAME                      STATE           VERSION
* podman-machine-default    Stopped         2
  Ubuntu                    Stopped         2
  docker-desktop            Stopped         2
```

Sur ma machine : `docker-desktop` (Docker Desktop) et `podman-machine-default` (Podman). Ce sont des distros « techniques » gérées par ces outils, pas des distros à utiliser directement ; `Ubuntu` est une distro ordinaire. `wslc` n'en ajoute aucune : ses sessions n'apparaissent pas dans `wsl -l -v`.

</details>

2. Pourquoi ne peut-on pas faire tourner une image `ubuntu` directement sur le noyau Windows ?

<details>
<summary>Solution</summary>

Une image Linux contient des binaires qui font des appels système **Linux**. Un conteneur ne virtualise pas le noyau : il partage celui de l'hôte. Il faut donc un noyau Linux, fourni ici par la VM de WSL 2.

</details>

## Sources

- [Qu'est-ce que WSL ? — Microsoft Learn](https://learn.microsoft.com/windows/wsl/about)
- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container)
