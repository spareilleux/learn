---
title: 2. Installation
description: Passer WSL en pre-release, vérifier wslc et dépanner un échec de mise à jour.
sidebar:
  order: 2
---

## Quelle version faut-il ?

`wslc.exe` exige **WSL 2.9.3 ou plus récent**. Cette branche n'existe pour l'instant qu'en **pre-release** : la version stable (2.7.x en septembre 2026) ne contient pas `wslc`.

Vérifie ta version :

```powershell
wsl --version
```

## Mettre à jour

```powershell
wsl --update --pre-release
```

:::caution[La mise à jour arrête WSL]
Toutes les distributions WSL s'arrêtent pendant la mise à jour — y compris celles de Docker Desktop et Podman. Sauvegarde ce qui tourne dans tes conteneurs avant.
:::

## Vérifier

```powershell
wsl --version        # doit afficher 2.9.3 ou plus
wslc version         # confirme que la CLI est disponible
wslc run --rm hello-world
```

Le dernier test télécharge l'image `hello-world` si nécessaire et affiche un message de bienvenue.

:::tip
Si `wslc` est introuvable juste après la mise à jour, ouvre un **nouveau** terminal : l'ancien n'a pas le `PATH` à jour.
:::

## Dépannage : l'installation échoue (erreur 1921 / 1603)

C'est ce qui m'est arrivé (voir le [journal](../journal/)). La commande affiche la barre de progression, puis rend la main — mais `wsl --version` montre toujours l'ancienne version.

**Diagnostic** — le journal *Application* de Windows contient :

```text
Error 1921. Service 'WSL Service' (WSLService) could not be stopped.
Installation success or error status: 1603.
```

Pour le retrouver :

```powershell
Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='MsiInstaller'; StartTime=(Get-Date).AddHours(-1)} |
  Select-Object TimeCreated, Id, Message
```

**Cause** — l'installateur MSI doit arrêter le service `WSLService`, mais des processus le maintiennent occupé : Docker Desktop, Podman, des terminaux WSL ouverts…

**Correctif** — dans un terminal **administrateur** :

```powershell
Get-Process "Docker Desktop","com.docker.backend" -ErrorAction SilentlyContinue | Stop-Process -Force
podman machine stop
wsl --shutdown
Stop-Service WSLService -Force
wsl --update --pre-release
wsl --version
```

Si le service refuse encore de s'arrêter : redémarrer Windows et lancer la mise à jour **avant** que Docker Desktop ne redémarre automatiquement.

## Revenir en arrière

Pour quitter la pre-release, réinstaller une version stable : `wsl --update` (sans `--pre-release`) ou le paquet MSI stable depuis les [releases GitHub de WSL](https://github.com/microsoft/WSL/releases). *À vérifier : le comportement exact du retour arrière depuis 2.9.x.*

## Exercices

1. Comment savoir si une mise à jour de WSL a vraiment réussi, même si la commande n'affiche aucune erreur ?

<details>
<summary>Solution</summary>

Relancer `wsl --version` et comparer la version. En cas de doute, lire les événements `MsiInstaller` : l'événement **1033** indique le statut final (`0` = succès, `1603` = échec) et l'événement **11708** signale « Installation failed ».

</details>

2. Pourquoi faut-il arrêter Docker Desktop avant de mettre à jour WSL ?

<details>
<summary>Solution</summary>

Docker Desktop fait tourner sa propre distro WSL, qui garde le service `WSLService` actif. L'installateur ne peut pas remplacer les fichiers d'un service qu'il n'arrive pas à arrêter.

</details>
