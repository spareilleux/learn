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

## 2026-09-13 — Refaire hello-world à la main : deux pièges

### Piège 1 : `wslc` « not recognized » dans un nouvel onglet

```text
PS C:\Users\spare\source\repos> Get-Command wslc
Get-Command : The term 'wslc' is not recognized as the name of a cmdlet, function, script file, or operable program.
```

`wslc.exe` était installé et `C:\Program Files\WSL\` figurait dans le `PATH` machine, mais un programme reçoit une *copie* des variables d'environnement au démarrage. Windows Terminal tournait depuis le 2026-09-11, donc avant la mise à jour, et le nouvel onglet a hérité de son ancien `PATH`.

Solutions, de la plus rapide à la plus durable :

```powershell
# Recharger le PATH dans le PowerShell courant (ce terminal seulement)
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
```

- ou appeler le chemin complet : `& "C:\Program Files\WSL\wslc.exe" --version` ;
- ou fermer **toutes** les fenêtres de Windows Terminal (plus aucun `WindowsTerminal.exe`) et le relancer, ou lancer un terminal depuis `Win + R`.

Dans `cmd.exe`, l'équivalent de `Get-Command` est `where wslc`.

### Piège 2 : un terminal administrateur ne voit pas les mêmes images

Dans un `cmd.exe` neuf (ouvert dans `C:\Windows\System32`, signe d'un terminal élevé), `wslc run --rm hello-world` a **retéléchargé** l'image, alors qu'elle avait déjà été tirée depuis un terminal sans élévation :

```text
Image 'hello-world' not found, pulling
```

`wslc info` explique pourquoi :

```text
Sessions: 2
ID   Creator PID   Display Name
1    144356        wslc-cli-spare
2    394856        wslc-cli-admin-spare
```

`wslc` crée une session par utilisateur **et par niveau de droits** : `wslc-cli-<utilisateur>` sans élévation, `wslc-cli-admin-<utilisateur>` en administrateur. L'image tirée dans une session était introuvable dans l'autre.

**Leçon :** `wslc` n'a pas besoin de l'élévation. Toujours utiliser un terminal non administrateur, sinon images et conteneurs se retrouvent dans une session à part.

### Vérification : ce qui est séparé, et qui voit quoi

Terminal non élevé : créer un volume et un réseau, puis supprimer l'image.

```powershell
wslc volume create sesstest-vol
wslc network create sesstest-net
wslc image remove hello-world
wslc images    # vide
```

Terminal administrateur :

```text
> wslc image list
hello-world   latest   e2ac70e7319a   5 months ago   10.1kB
> wslc volume list
DRIVER   VOLUME NAME
> wslc network list
d9c6879f7df3   bridge    bridge    local
0dd65e6d15ec   host      host      local
34ad73ecd806   none      null      local
```

- L'image supprimée dans la session non élevée **est toujours là** dans la session admin.
- Le volume et le réseau créés dans la session non élevée **n'apparaissent pas** dans la session admin. Même les réseaux par défaut `bridge`/`host`/`none` ont des ID différents : chaque session fait tourner son propre moteur.

L'option globale `--session` se place **avant** la sous-commande (`wslc --session <nom> image list` ; placée après : `Option name was not recognized`). L'accès est asymétrique :

```text
# non élevé → session admin
> wslc --session wslc-cli-admin-spare image list
The requested operation requires elevation.
Error code: ERROR_ELEVATION_REQUIRED

# administrateur → session non élevée : ça marche
> wslc --session wslc-cli-spare volume list
DRIVER   VOLUME NAME
guest    sesstest-vol
```

Sur le disque, chaque session a ses propres disques virtuels :

```text
%LocalAppData%\wslc\sessions\wslc-cli-spare\storage.vhdx         ~587 Mo
%LocalAppData%\wslc\sessions\wslc-cli-spare\swap.vhdx            36 Mo
%LocalAppData%\wslc\sessions\wslc-cli-admin-spare\storage.vhdx   ~577 Mo
%LocalAppData%\wslc\sessions\wslc-cli-admin-spare\swap.vhdx      36 Mo
```

Nettoyage : `wslc volume remove sesstest-vol`, `wslc network remove sesstest-net`.

## Questions ouvertes

- ~~Où `wslc` stocke-t-il ses images et conteneurs ?~~ Dans `%LocalAppData%\wslc\sessions\<session>\storage.vhdx`, un disque virtuel par session (voir ci-dessus). ~580 Mo pour une session presque vide : *à vérifier* si ce fichier grossit avec les images et diminue après un `prune`.
- Peut-on limiter la mémoire et le CPU de la VM utilisée par `wslc` ?
- `wslc` et Docker Desktop peuvent-ils publier des ports sans conflit ?
