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
Toutes les distributions WSL s'arrêtent pendant la mise à jour — y compris celles de [Docker Desktop](https://docs.docker.com/desktop/) et [Podman](https://podman.io/). Sauvegarde ce qui tourne dans tes conteneurs avant.
:::

## Vérifier

```powershell
wsl --version        # doit afficher 2.9.3 ou plus
wslc --version       # confirme que la CLI est disponible (wslc version fonctionne aussi)
wslc run --rm hello-world
```

```text
WSL version: 2.9.11.0
Kernel version: 6.18.40.1-1
...
wslc 2.9.11.0
Image 'hello-world' not found, pulling
...
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

Le dernier test télécharge l'image `hello-world` et affiche son message de bienvenue. « Hello from Docker! » n'est que le texte intégré à l'image : Docker Desktop n'y joue aucun rôle, le conteneur tourne sous `wslc`.

:::caution[`wslc` n'est pas reconnu]
`wslc.exe` est installé dans `C:\Program Files\WSL\`, qui figure dans le `PATH` machine, mais un programme reçoit une copie de l'environnement au moment où il démarre. Un nouvel onglet d'un [Windows Terminal](https://learn.microsoft.com/windows/terminal/) lancé **avant** la mise à jour hérite de l'ancien `PATH`. Ferme toutes les fenêtres Windows Terminal, ou recharge le `PATH` dans le PowerShell courant :

```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
```

Il en va de même pour un IDE ouvert avant la mise à jour : MSBuild échoue alors avec `WSLC0001` (voir la [leçon 5](../05-wslc-vs-docker/)).
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

**Correctif** — la séquence qui a fonctionné chez moi. D'abord, depuis un terminal normal :

```powershell
docker desktop stop
podman machine stop
wsl --shutdown
wsl -l -v   # toutes les distros doivent être Stopped
```

Puis, dans un terminal **administrateur** :

```powershell
wsl --shutdown
Get-Process wsl, wslhost, wslrelay -ErrorAction SilentlyContinue | Stop-Process -Force
Stop-Service WSLService -Force
wsl --update --pre-release
wsl --version
```

Si le service refuse encore de s'arrêter : redémarrer Windows et lancer la mise à jour **avant** que Docker Desktop ne redémarre automatiquement.

## Revenir en arrière

Pour quitter la pre-release, réinstaller une version stable : `wsl --update` (sans `--pre-release`) ou le paquet MSI stable depuis les [releases GitHub de WSL](https://github.com/microsoft/WSL/releases). *À vérifier : le comportement exact du retour arrière depuis 2.9.x.*

## À retenir

- `wslc` exige WSL 2.9.3 ou plus récent, qui n'existe pour l'instant qu'en pré-version : `wsl --update --pre-release`.
- La mise à jour arrête toutes les distributions WSL, y compris celles de Docker Desktop et de Podman.
- Un terminal ou un IDE ouvert avant la mise à jour garde l'ancien `PATH` et ne trouve pas `wslc`.
- Une mise à jour peut échouer sans erreur : relance `wsl --version`, et cherche l'erreur 1921 ou le statut 1603 dans les événements `MsiInstaller`.
- Si le service WSL refuse de s'arrêter, arrête Docker Desktop, Podman et les processus WSL, puis mets à jour depuis un terminal administrateur.

## Exercices

1. Comment savoir si une mise à jour de WSL a vraiment réussi, même si la commande n'affiche aucune erreur ?

<details>
<summary>Solution</summary>

Relancer `wsl --version` et comparer la version. En cas de doute, lire les événements `MsiInstaller` : l'événement **1033** indique le statut final (`0` = succès, `1603` = échec), l'événement **11707** signale « Installation completed successfully » et l'événement **11708** « Installation failed ». Après ma tentative réussie :

```text
TimeCreated               Id Message
2026-09-13 12:25:19 PM  1033 Windows Installer installed the product. Product Name: Windows Subsystem for Linux. Product Version: 2.9.11.0. ...
2026-09-13 12:25:19 PM 11707 Product: Windows Subsystem for Linux -- Installation completed successfully.
```

</details>

2. Pourquoi faut-il arrêter Docker Desktop avant de mettre à jour WSL ?

<details>
<summary>Solution</summary>

Docker Desktop fait tourner sa propre distro WSL, qui garde le service `WSLService` actif. L'installateur ne peut pas remplacer les fichiers d'un service qu'il n'arrive pas à arrêter.

</details>

## Sources

- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container)
- [Notes de version de WSL — GitHub](https://github.com/microsoft/WSL/releases)
- [Journalisation des événements — Windows Installer](https://learn.microsoft.com/windows/win32/msi/event-logging)
