---
title: Journal
description: Notes de progression datées — essais, erreurs et points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Comprendre ce qu'est WSL containers et quelle version il exige
- [x] Installer WSL ≥ 2.9.3 (pre-release)
- [x] `wslc run --rm hello-world`
- [ ] Leçon 3 : conteneurs, ports, `exec`
- [ ] Leçon 4 : construire une image
- [ ] Faire tourner un service existant (qdrant) avec `wslc`
- [ ] Tester Compose
- [ ] Vérifier si les images Docker et `wslc` sont partagées
- [ ] Petit programme C# avec `Microsoft.WSL.Containers`

## 2026-09-12 — État des lieux

- Machine : Windows 11 Pro build 26200, WSL **2.6.3**.
- Distros WSL déjà présentes : `docker-desktop` (Docker Desktop 4.61) et `podman-machine-default`.
- Dernières versions WSL sur GitHub : stable **2.7.14**, pre-release **2.9.11**. Seule la pre-release contient `wslc`.

**Incident sans rapport direct, mais instructif :** Docker Desktop a planté trois fois en quelques minutes (« wsl-bootstrap stopped with exit code 1, did wsl shutdown? »). Au même moment, `wsl -l -v` échouait avec :

```text
Not enough memory resources are available to complete this operation.
Error code: Wsl/0x8007000e
```

Charge mémoire engagée : 97 Go sur 132 Go. Hypothèse : trop de VM et de processus lourds en même temps (Docker + Kubernetes, Podman, ollama, rust-analyzer…). Piste : limiter la mémoire de WSL dans `%UserProfile%\.wslconfig` (`memory=24GB`).

## 2026-09-13 — Première tentative de mise à jour : échec

```powershell
wsl --update --pre-release
# Updating Windows Subsystem for Linux to version: 2.9.11.
```

La commande a rendu la main sans erreur visible, mais `wsl --version` affichait toujours **2.6.3**.

Dans le journal Windows (`MsiInstaller`) :

```text
Error 1921. Service 'WSL Service' (WSLService) could not be stopped.
Product: Windows Subsystem for Linux -- Installation failed.   (statut 1603)
```

**Leçon :** ne pas se fier à l'absence de message d'erreur ; vérifier la version après coup. Le service WSL était retenu par Docker Desktop, Podman et plusieurs processus `wsl.exe`.
Correctif prévu : tout arrêter, `wsl --shutdown`, `Stop-Service WSLService` en administrateur, puis relancer la mise à jour. → détaillé dans la [leçon 2](../02-installation/).

## 2026-09-13 — Deuxième tentative : WSL 2.9.11 installé

Application du correctif prévu. Depuis un terminal normal (sans élévation) :

```powershell
docker desktop stop
podman machine stop
wsl --shutdown
wsl -l -v   # podman-machine-default et docker-desktop : Stopped
```

Puis, dans un PowerShell **administrateur** :

```powershell
wsl --shutdown
Get-Process wsl, wslhost, wslrelay -ErrorAction SilentlyContinue | Stop-Process -Force
Stop-Service WSLService -Force
wsl --update --pre-release
wsl --version
```

```text
WSLService: Stopped
Updating Windows Subsystem for Linux to version: 2.9.11.
WSL version: 2.9.11.0
Kernel version: 6.18.40.1-1
WSLg version: 1.0.79
```

Cette fois, le service était vraiment arrêté avant le passage de l'installeur, et la version a changé. `wslc.exe` est installé dans `C:\Program Files\WSL\`, qui est déjà dans le `PATH` machine. Les terminaux ouverts avant la mise à jour ne le voient pourtant pas : en ouvrir un nouveau (ou appeler le chemin complet).

```powershell
wslc --version   # wslc 2.9.11.0
wslc run --rm hello-world
```

```text
Image 'hello-world' not found, pulling
latest: Pulling from library/hello-world
...
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.
```

**Ne pas se laisser tromper :** « Hello from Docker! » est seulement le texte contenu dans l'image `hello-world`. Docker Desktop est resté arrêté tout du long ; c'est bien `wslc` qui a exécuté le conteneur.

`wslc info` indique un fichier de réglages `%LocalAppData%\wslc\settings.yaml` et une session nommée `wslc-cli-<utilisateur>`. `wslc images` ne liste que `hello-world` (10,1 ko).

**Reste à faire :** relancer Docker Desktop et Podman, et vérifier que Docker Desktop 4.61 fonctionne toujours avec WSL 2.9.11 (*à vérifier*).

## Questions ouvertes

- Où `wslc` stocke-t-il ses images et conteneurs ?
- Peut-on limiter la mémoire et le CPU de la VM utilisée par `wslc` ?
- `wslc` et Docker Desktop peuvent-ils publier des ports sans conflit ?
