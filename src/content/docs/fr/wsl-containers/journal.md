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
- [x] Leçon 3 : conteneurs, ports, `exec`
- [x] Leçon 4 : construire une image
- [x] Faire tourner un service existant (qdrant) avec `wslc`
- [x] Tester Compose
- [x] Vérifier si les images Docker et `wslc` sont partagées
- [x] Petit programme C# avec `Microsoft.WSL.Containers`

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

**Reste à faire :** relancer Docker Desktop et Podman, et vérifier que Docker Desktop 4.61 fonctionne toujours avec WSL 2.9.11. (Docker Desktop : OK, voir « Les dernières questions ouvertes » plus bas. Podman 5.8.3 : `podman machine start` OK, `podman run --rm quay.io/podman/hello` OK ; il prévient que le canal API Docker par défaut est déjà pris par Docker Desktop et expose le sien, `npipe:////./pipe/podman-machine-default`.)

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

## 2026-09-13 — Limiter le CPU et la mémoire d'une session `wslc`

`wslc settings` crée `%LocalAppData%\wslc\settings.yaml` au premier lancement (tous les réglages commentés) et l'ouvre dans l'éditeur par défaut. La partie utile :

```yaml
session:
  # Number of virtual CPUs allocated to the session (e.g. 4 default: all available CPUs)
  # cpuCount: default

  # Memory limit for the session (e.g. 2GB default: half of available memory)
  # memorySize: default
```

Le même fichier contient aussi `maxStorageSize` (1 To par défaut), `storagePath` (où est créé `wslc\sessions\<session>\storage.vhdx`), `defaultBindingAddress` (`127.0.0.1` par défaut pour `-p`), `hostLoopback` (`host.wslc.internal`) et `idleTimeout` (30 s). Source : le fichier généré, <https://aka.ms/wslc-settings>. L'équivalent côté API est `SessionSettings.CpuCount` / `MemoryMB` ([Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container)).

**Mesure.** Machine : 24 CPU logiques, 63,7 Go de RAM.

```powershell
wslc run --rm alpine sh -c "echo nproc=`$(nproc); free -m"
```

| Réglages | `nproc` | RAM (`free -m`) | Swap |
|---|---|---|---|
| par défaut | 24 | 31946 Mo | 32617 Mo |
| `cpuCount: 4`, `memorySize: 4GB` | 4 | 3919 Mo | 4096 Mo |

Le swap suit `memorySize`.

**Piège : le changement ne s'applique pas à une session en cours.** La première mesure après modification du fichier affichait toujours 24 CPU. Il faut terminer la session ; la commande `wslc` suivante en démarre une nouvelle avec les nouveaux réglages :

```powershell
wslc --session wslc-cli-spare system session terminate
```

(`wslc system session terminate wslc-cli-spare`, avec le nom en argument, échoue : `Found a positional argument when none was expected`.)

4 Go est trop juste pour la suite du cours (qdrant). Réglage retenu sur cette machine, vu l'incident mémoire du 2026-09-12 : `cpuCount: 8`, `memorySize: 16GB` → `nproc=8`, RAM 15996 Mo, swap 16384 Mo.

### Vérification : session admin et mémoire côté Windows

**La session admin lit le même fichier.** Dans un terminal administrateur, `wslc info` affiche le même `Settings file: C:\Users\spare\AppData\Local\wslc\settings.yaml`. Après avoir terminé la session admin :

```text
> wslc --session wslc-cli-admin-spare system session terminate
> wslc run --rm alpine sh -c 'echo nproc=$(nproc); free -m'
nproc=8
Mem:          15996 ...
Swap:         16384 ...
```

**Côté Windows, chaque VM de session est un processus nommé `vmmem<session>`** (`vmmemwslc-cli-spare`, `vmmemwslc-cli-admin-spare`) ; `hcsdiag list` (administrateur) la montre comme une VM `Running` portant le nom de la session. Ses chiffres mémoire ne sont lisibles que depuis un terminal élevé.

Test : un conteneur qui occupe 6 Go pendant deux minutes, dans la session non élevée.

```powershell
wslc run -d --name memtest alpine sh -c 'apk add -q stress-ng && stress-ng --vm 1 --vm-bytes 6G --vm-hang 0 --timeout 120s'
```

| Moment | Processus VM | Working set | Mémoire privée |
|---|---|---|---|
| session inactive (admin, rien ne tourne) | `vmmemwslc-cli-admin-spare` | 921 Mo | 970 Mo |
| 6 Go occupés dans le conteneur | `vmmemwslc-cli-spare` | 7069 Mo | 7083 Mo |
| 10 s après `container stop` + `remove` | `vmmemwslc-cli-spare` | 2776 Mo | 7084 Mo |
| un peu plus tard | `vmmemwslc-cli-spare` | 902 Mo | 1902 Mo |

- Une VM de session inactive coûte environ **0,9 Go**.
- La mémoire utilisée par le conteneur se retrouve presque entièrement côté Windows (~6 Go + la VM de base).
- Après l'arrêt du conteneur, la mémoire n'est **pas rendue tout de suite** : elle redescend progressivement.
- `memorySize` est un plafond, pas une réservation : la VM ne prend que ce qu'elle utilise.

Entre deux relevés, la VM de la session admin avait disparu (rien n'y tournait) : cohérent avec `idleTimeout` (30 s) — mesuré plus bas.

## 2026-09-13 — Les dernières questions ouvertes

### Quand une VM inactive est-elle arrêtée ?

Lancer un conteneur, puis surveiller le processus de la VM **sans lancer aucune commande `wslc`** (une commande `wslc` réveille la session) :

```powershell
wslc run --rm alpine true
# puis, toutes les 5 s :
Get-Process -Name 'vmmemwslc-cli-spare' -ErrorAction SilentlyContinue
```

```text
    0s  VM running: True
   35s  VM running: False
```

La VM s'arrête **30 à 35 s** après la dernière commande (relevé toutes les 5 s) : c'est `idleTimeout: 30`. La session reste listée par `wslc system session list` ; seule la VM est arrêtée, et la commande suivante la redémarre.

### Docker Desktop avec WSL 2.9.11

`docker desktop start` répondait `Docker Desktop is already running` alors qu'aucun processus Docker Desktop n'existait, et `docker desktop status` répondait `Could not retrieve status`. Lancer directement `C:\Program Files\Docker\Docker\Docker Desktop.exe` a fonctionné : moteur 29.2.1 prêt après ~130 s, `docker run --rm hello-world` OK. **Docker Desktop 4.61 fonctionne avec WSL 2.9.11.**

### Les images Docker et `wslc` sont-elles partagées ?

Non. Après `docker pull busybox` :

```text
> docker images            > wslc images
postgres:16-alpine          alpine   latest
busybox:latest
hello-world:latest
node:18-alpine
```

Chaque outil a son propre stock (`docker_data.vhdx` ≈ 50 Go pour Docker, un `storage.vhdx` par session pour `wslc`). Une image utilisée par les deux est téléchargée deux fois.

### `wslc` et Docker Desktop peuvent-ils publier le même port ?

Test : `nginx` dans `wslc`, `httpd` (Apache, « It works! ») dans Docker, pour savoir qui répond.

```powershell
wslc run -d --name webwslc -p 8080:80 nginx
docker run -d --name webdocker -p 8080:80 httpd
curl.exe http://127.0.0.1:8080/   # nginx  → wslc
curl.exe http://localhost:8080/   # It works! → Docker
```

**Les deux démarrent sans aucune erreur : le conflit est silencieux.** Windows accepte les deux écoutes parce qu'elles ne portent pas exactement sur la même adresse :

```text
TCP  0.0.0.0:8080     LISTENING  com.docker.backend
TCP  [::]:8080        LISTENING  com.docker.backend
TCP  127.0.0.1:8080   LISTENING  dllhost      ← wslc
TCP  [::1]:8080       LISTENING  wslrelay
```

`127.0.0.1` va à `wslc` (l'adresse la plus précise gagne), tandis que `localhost` se résout d'abord en `::1` et tombe sur Docker. Même résultat dans toutes les variantes essayées :

| Variante | Erreurs | `127.0.0.1` | `localhost` |
|---|---|---|---|
| `wslc` d'abord, puis Docker (8080) | aucune | wslc | Docker |
| Docker d'abord, puis `wslc` (8081) | aucune | wslc | Docker |
| Docker, puis `wslc -p 0.0.0.0:8082:80` | aucune | wslc | Docker |
| `wslc -p 0.0.0.0:8083:80`, puis Docker | aucune | wslc | Docker |

**Leçon :** ne pas publier le même port depuis les deux outils. Rien ne prévient, et la réponse dépend de ce qu'utilise le client : `127.0.0.1` ou `localhost`.

### `storage.vhdx` grossit-il et rétrécit-il ?

Taille de `%LocalAppData%\wslc\sessions\wslc-cli-spare\storage.vhdx` :

| Étape | Taille du fichier |
|---|---|
| départ (`alpine`, `nginx`) | 814 Mo |
| `wslc pull mcr.microsoft.com/dotnet/sdk:9.0` (869 Mo) | 1070 Mo |
| `wslc image remove` de cette image | 1070 Mo |
| `wslc image prune --all` (« Total reclaimed space: 178.5MB », plus rien) | 1070 Mo |
| `system session terminate` | 1070 Mo |
| nouveau pull de `dotnet/sdk:9.0` | 1070 Mo |
| + `dotnet/aspnet:9.0` (224 Mo) + `eclipse-temurin:21-jdk` (491 Mo) | 1550 Mo |

- Le fichier **grossit** quand on ajoute des images, et **ne rétrécit jamais** tout seul : ni `image remove`, ni `prune`, ni l'arrêt de la session ne rendent de place à Windows.
- L'espace libéré à l'intérieur est **réutilisé** : retélécharger le SDK n'a pas fait grossir le fichier.
- La croissance est inférieure à la taille affichée des images (`SIZE` est la taille décompressée, et l'espace libéré est réutilisé) : la taille du fichier n'est donc pas un compteur fiable des images.

Piège : dans `wslc image prune`, `-f` veut dire `--filter`, pas `--force` ; `--force` n'existe pas (`wslc image prune --all` ne demande pas de confirmation).

### Compacter `storage.vhdx`

Après les builds de la leçon 4, le fichier atteignait **3995 Mo**, alors que `df` dans la session n'indiquait que **1,9 Go** utilisés. Étapes :

```powershell
# 1. Arrêter la VM de la session (sans élévation) et vérifier qu'elle a disparu
wslc --session wslc-cli-spare system session terminate
Get-Process -Name 'vmmemwslc-cli-spare' -ErrorAction SilentlyContinue   # rien

# 2. PowerShell administrateur (module Hyper-V) : sauvegarder, puis compacter
$f = "$env:LOCALAPPDATA\wslc\sessions\wslc-cli-spare\storage.vhdx"
Copy-Item $f "$f.bak"
Optimize-VHD -Path $f -Mode Full
```

```text
before: 3,995 MB
Optimize-VHD -Mode Full: OK in 10s
after: 2,789 MB
```

**1,2 Go rendus à Windows en 10 secondes.** Vérifier avant de supprimer la sauvegarde : `wslc image list` liste toujours `csharp-api`, `java-reactor-api` et `alpine`, et les deux API répondent toujours après `wslc run`.

- `Optimize-VHD` exige un terminal **administrateur** et le module PowerShell **Hyper-V** (présent ici).
- La VM de la session doit être arrêtée : sinon le VHDX est en cours d'utilisation.
- Le fichier reste plus gros que l'espace utilisé à l'intérieur (2,8 Go contre 1,9 Go) : seuls les blocs entièrement libres sont récupérés.
- `fstrim` n'est pas disponible dans la VM de session : `wslc system session run fstrim -v /` → `Failed to launch command fstrim. Errno = 2`.

## 2026-09-13 — Leçons 3 et 4 faites

- **Leçon 3** (conteneurs, ports, `exec`) : pratiquée tout au long des entrées ci-dessus — `nginx` publié avec `-p`, `exec`, `container list --all`, et le conflit de ports avec Docker Desktop.
- **Leçon 4** (construire une image) : réécrite avec une API C# et une API Spring Boot WebFlux, construites et lancées avec `wslc` ; toutes les sorties de la leçon sont réelles.

## 2026-09-13 — Faire tourner qdrant avec `wslc`

### Avant de commencer : un qdrant tourne déjà dans Docker

```text
> docker ps
ga-qdrant  qdrant/qdrant:latest  Up About an hour (healthy)  0.0.0.0:6333-6334->6333-6334/tcp, [::]:6333-6334->6333-6334/tcp
```

Publier `wslc` aussi sur 6333 démarrerait **sans aucune erreur** et prendrait discrètement `127.0.0.1:6333` à l'application qui utilise `ga-qdrant` (voir le conflit de ports plus haut). Le qdrant `wslc` est donc publié sur **16333/16334**.

### Téléchargement : même tag, version différente

```powershell
wslc pull qdrant/qdrant    # 21 s, 198 Mo
```

L'image Docker était déjà là, mais `wslc` la retélécharge (stocks séparés). Et `latest` n'est pas la même version des deux côtés :

```text
> curl.exe http://127.0.0.1:16333/     # wslc
{"title":"qdrant - vector search engine","version":"1.19.1","commit":"6ab21cac18ebb6f4ae29102c7f8f5cc11affd5de"}
> curl.exe http://127.0.0.1:6333/      # Docker (ga-qdrant, tirée le 2025-12-19)
{"title":"qdrant - vector search engine","version":"1.16.3","commit":"bd49f45a8a2d4e4774cac50fa29507c4e8375af2"}
```

**Leçon :** `latest` veut dire « la plus récente au moment où *cet* outil l'a tirée ». Épingler une version (`qdrant/qdrant:v1.19.1`) quand deux environnements doivent correspondre.

### Lancer avec un volume

```powershell
wslc volume create qdrant-data
wslc run -d --name qdrant -p 16333:6333 -p 16334:6334 -v qdrant-data:/qdrant/storage qdrant/qdrant
curl.exe http://127.0.0.1:16333/readyz    # all shards are ready (après 1 s)
```

```text
CONTAINER ID   IMAGE           COMMAND             CREATED         STATUS        PORTS                                                  NAMES
da52872e3246   qdrant/qdrant   "./entrypoint.sh"   5 seconds ago   Up 1 second   127.0.0.1:16333->6333/tcp, 127.0.0.1:16334->6334/tcp   qdrant
```

Piège : le log indique `Access web UI at http://localhost:6333/dashboard`. C'est le port **dans** le conteneur. Depuis Windows, le tableau de bord est à `http://127.0.0.1:16333/dashboard` — et `localhost:6333` ouvrirait celui de Docker.

Une collection, trois points et une requête (corps dans des fichiers JSON, pour éviter les problèmes de guillemets de PowerShell) :

```powershell
curl.exe -X PUT http://127.0.0.1:16333/collections/journal -H "Content-Type: application/json" --data-binary "@coll.json"
curl.exe -X PUT "http://127.0.0.1:16333/collections/journal/points?wait=true" -H "Content-Type: application/json" --data-binary "@points.json"
curl.exe -X POST http://127.0.0.1:16333/collections/journal/points/query -H "Content-Type: application/json" --data-binary "@query.json"
```

```text
coll.json    {"vectors":{"size":4,"distance":"Cosine"}}
points.json  {"points":[{"id":1,"vector":[0.9,0.1,0.1,0.1],"payload":{"note":"wslc sessions"}},{"id":2,"vector":[0.1,0.9,0.1,0.1],"payload":{"note":"ports and localhost"}},{"id":3,"vector":[0.1,0.1,0.9,0.1],"payload":{"note":"storage.vhdx"}}]}
query.json   {"query":[0.2,0.8,0.1,0.1],"limit":2,"with_payload":true}
```

```text
{"result":true,"status":"ok","time":0.24333272}
{"result":{"operation_id":1,"status":"completed"},"status":"ok","time":0.003567116}
{"result":{"points":[{"id":2,"version":1,"score":0.99111706,"payload":{"note":"ports and localhost"}},{"id":1,"version":1,"score":0.3651484,"payload":{"note":"wslc sessions"}}]},"status":"ok","time":0.00189502}
```

### Persistance : supprimer le conteneur, garder les données

```powershell
wslc container stop qdrant
wslc container remove qdrant
wslc run -d --name qdrant -p 16333:6333 -p 16334:6334 -v qdrant-data:/qdrant/storage qdrant/qdrant
curl.exe http://127.0.0.1:16333/collections
curl.exe -X POST http://127.0.0.1:16333/collections/journal/points/count -H "Content-Type: application/json" -d "{}"
```

```text
{"result":{"collections":[{"name":"journal"}]},"status":"ok","time":8.866e-6}
{"result":{"count":3},"status":"ok","time":0.007211133}
```

La collection et ses 3 points survivent, parce qu'ils vivent dans le volume. `wslc volume inspect qdrant-data` montre `"Driver": "guest"` et un point de montage dans la VM de la session (`/var/lib/docker/volumes/qdrant-data/_data`), donc dans le `storage.vhdx` de la session.

### Ne pas monter un dossier Windows pour le stockage de qdrant

```powershell
wslc run -d --name qdrant-bind -p 16335:6333 -v "C:\...\qdrant-bind:/qdrant/storage" qdrant/qdrant
wslc exec qdrant-bind sh -c "mount | grep /qdrant/storage"
```

```text
drvfs on /qdrant/storage type virtiofs (rw,relatime)
```

qdrant démarre quand même et écrit ses fichiers dans le dossier Windows, mais journalise une erreur :

```text
ERROR qdrant: Filesystem check failed for storage path ./storage. Details: FUSE filesystems may cause data corruption due to caching issues
```

**Leçon :** pour une base de données, utiliser un **volume** `wslc` (dans la VM), pas un montage d'un dossier Windows.

### Ressources

```text
> wslc stats qdrant
CONTAINER ID   NAME     CPU %   MEM USAGE / LIMIT     MEM %   NET I/O           BLOCK I/O        PIDS
da52872e3246   qdrant   0.16%   47.21MiB / 15.62GiB   0.30%   10.1kB / 5.77kB   8.19kB / 184kB   35
> docker stats ga-qdrant --no-stream --format "CPU {{.CPUPerc}}  MEM {{.MemUsage}}"
CPU 0.41%  MEM 367.8MiB / 31.2GiB
```

- La limite affichée est celle de la VM : **15,62 Gio** pour `wslc` (le réglage `memorySize: 16GB`), **31,2 Gio** pour Docker Desktop (la moitié de la RAM par défaut).
- 47 Mio pour 3 points contre 368 Mio pour `ga-qdrant` : pas comparable, `ga-qdrant` contient de vraies données.
- Côté Windows, la VM `vmmemwslc-cli-spare` était à 1160 Mo (environ 0,9 Go à vide, mesuré plus tôt).
- qdrant journalise `starting 7 workers` : il voit les 8 CPU autorisés par `cpuCount: 8`.

Nettoyage : `wslc container stop qdrant qdrant-bind`, `wslc container remove qdrant qdrant-bind`, `wslc volume remove qdrant-data`. `ga-qdrant` n'a jamais été touché.

## 2026-09-13 — Compose avec `wslc`

### Pas de commande `compose`

```text
> wslc compose --help
Unrecognized command: 'compose'
```

`wslc --help` ne liste aucun équivalent de Compose, et le [tutoriel officiel](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers) n'en parle pas. `wslc` 2.9.11 **ne prend pas en charge Compose**.

### Impasse : brancher `docker compose` sur le moteur de la session

La VM de session fait bien tourner un moteur Docker :

```text
> wslc system session run ps -eo pid,args
  131 /usr/bin/containerd --address /run/containerd/containerd.sock --root /var/lib/docker/containerd/daemon --state /run/docker/containerd/daemon
  132 /usr/bin/dockerd --containerd /run/containerd/containerd.sock
> wslc system session run ls -la /var/run/docker.sock
srw-rw---- 1 root docker 0 Sep 13 18:47 /var/run/docker.sock
```

Mais rien ne l'expose à Windows (aucun canal nommé `wslc`), le client `docker` de la VM échoue (`wslc system session run docker version` → `The handle is invalid. Error code: ERROR_INVALID_HANDLE`), et on ne peut pas le monter dans un conteneur `docker:cli` (qui contient Compose v5.5.1) :

```powershell
wslc run --rm -e DOCKER_HOST=unix:///var/run/docker.sock -v /var/run/docker.sock:/var/run/docker.sock docker:cli docker ps
```

```text
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

Pourquoi : la source de `-v` est un chemin **Windows**. `/var/run/docker.sock` est devenu `C:\var\run\docker.sock`, monté en `virtiofs` :

```text
drvfs on /run/docker.sock type virtiofs (rw,relatime)
```

**Piège :** `wslc` **crée** la source d'un montage si elle n'existe pas. Ce test a laissé un dossier vide `C:\var\run\docker.sock\` sous Windows (supprimé ensuite). `--mount type=bind,source=/var/run/docker.sock,...` est refusé : `The bind source path must be absolute.`

### Ce que Compose apporte vraiment, fait à la main

`docker compose config` sur un fichier à deux services montre ce que Compose ajoute implicitement : un réseau par projet, des volumes nommés, et les noms de service comme noms DNS. Sur un réseau créé avec `wslc network create`, les noms se résolvent bien :

```text
> wslc run --rm --network demo alpine wget -qO- http://qdrant:6333/
{"title":"qdrant - vector search engine","version":"1.19.1","commit":"6ab21cac18ebb6f4ae29102c7f8f5cc11affd5de"}
> wslc run --rm --network demo alpine wget -qO- http://vectors:6333/readyz      # --network-alias vectors
all shards are ready
> wslc run --rm alpine wget -qO- -T 5 http://qdrant:6333/                      # réseau par défaut
wget: bad address 'qdrant:6333'
```

Le `compose.yaml` (validé avec `docker compose -p wslcdemo config`) :

```yaml
services:
  qdrant:
    image: qdrant/qdrant:v1.19.1
    ports:
      - "127.0.0.1:16333:6333"
    volumes:
      - qdrant-data:/qdrant/storage

  seed:
    image: curlimages/curl:8.16.0
    depends_on:
      - qdrant
    command: >
      --silent --show-error --retry 10 --retry-connrefused --retry-delay 1
      -X PUT http://qdrant:6333/collections/demo
      -H "Content-Type: application/json"
      -d '{"vectors":{"size":4,"distance":"Cosine"}}'

volumes:
  qdrant-data:
```

Sa traduction en `wslc`, `wslc-up.ps1` :

```powershell
# Équivalent de `docker compose -p wslcdemo up -d` pour compose.yaml, avec wslc
$project = 'wslcdemo'

# Ce que Compose crée implicitement : un réseau par projet, des volumes nommés
wslc network create "${project}_default"
wslc volume create "${project}_qdrant-data"

# service qdrant (le nom du service devient un alias DNS sur le réseau du projet)
wslc run -d --name "$project-qdrant-1" --network "${project}_default" --network-alias qdrant `
    -p 127.0.0.1:16333:6333 -v "${project}_qdrant-data:/qdrant/storage" qdrant/qdrant:v1.19.1

# service seed (depends_on ne fait qu'ordonner le démarrage : curl réessaie jusqu'à ce que qdrant réponde)
wslc run --name "$project-seed-1" --network "${project}_default" --network-alias seed `
    curlimages/curl:8.16.0 --silent --show-error --retry 10 --retry-connrefused --retry-delay 1 `
    -X PUT http://qdrant:6333/collections/demo -H 'Content-Type: application/json' `
    -d '{"vectors":{"size":4,"distance":"Cosine"}}'
```

Et `wslc-down.ps1` :

```powershell
# Équivalent de `docker compose -p wslcdemo down --volumes`
$project = 'wslcdemo'
wslc container stop "$project-qdrant-1"
wslc container remove "$project-qdrant-1" "$project-seed-1"
wslc network remove "${project}_default"
wslc volume remove "${project}_qdrant-data"
```

Résultat de `wslc-up.ps1` :

```text
CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS                              PORTS                       NAMES
28be34e431f5   curlimages/curl:8.1…   "/entrypoint.sh --si…"   1 second ago    Exited (0) Less than a second ago                               wslcdemo-seed-1
c1f82d52d6ca   qdrant/qdrant:v1.19…   "./entrypoint.sh"        2 seconds ago   Up 1 second                         127.0.0.1:16333->6333/tcp   wslcdemo-qdrant-1
> wslc logs wslcdemo-seed-1
{"result":true,"status":"ok","time":0.409039704}
> curl.exe http://127.0.0.1:16333/collections
{"result":{"collections":[{"name":"demo"}]},"status":"ok","time":0.00004439}
```

Après `wslc-down.ps1` : aucun conteneur, seulement les réseaux par défaut `bridge`/`host`/`none`, aucun volume.

**Conclusion :** pour une petite pile, un script `wslc` reproduit ce que fait Compose (réseau, volumes, noms DNS, ordre de démarrage). Ce qu'il n'apporte pas : aucune lecture de `compose.yaml`, pas de `depends_on` avec `condition: service_healthy`, pas de `up` différentiel qui ne recrée que ce qui a changé, pas de `logs -f` sur tous les services. Pour de vrais projets Compose, Docker Desktop (ou Podman) reste l'outil.

## 2026-09-13 — Un programme C# avec `Microsoft.WSL.Containers`

Objectif : piloter un conteneur depuis une application Windows, sans `wslc.exe`. Le code est dans [`code/wsl-containers/wslc-host`](https://github.com/spareilleux/learn/tree/main/code/wsl-containers/wslc-host) ; la leçon 5 le présente.

### L'extrait documenté ne compile pas

Coller l'extrait de Microsoft Learn dans un projet qui référence `Microsoft.WSL.Containers` 2.9.9 donne cinq erreurs :

```text
error CS0103: The name 'ComponentFlags' does not exist in the current context
error CS0117: 'SessionSettings' does not contain a definition for 'MemoryMB'
error CS0117: 'ProcessSettings' does not contain a definition for 'CmdLine'
error CS0103: The name 'DeleteContainerFlags' does not exist in the current context
error CS1705: Assembly 'wslcsdkcs' with identity 'wslcsdkcs, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null' uses 'Microsoft.Windows.SDK.NET, Version=10.0.26100.79, Culture=neutral, PublicKeyToken=31bf3856ad364e35' which has a higher version than referenced assembly 'Microsoft.Windows.SDK.NET' with identity 'Microsoft.Windows.SDK.NET, Version=10.0.19041.38, Culture=neutral, PublicKeyToken=31bf3856ad364e35'
```

Les vrais noms viennent de la lecture des types publics de `wslcsdkcs.dll` avec `MetadataLoadContext` :

| Microsoft Learn | Paquet 2.9.9 |
|---|---|
| `ComponentFlags GetMissingComponents()` | `IReadOnlyList<Component> GetMissingComponents()` (`VirtualMachinePlatform`, `WslPackage`, `SdkNeedsUpdate`) |
| `SessionSettings.MemoryMB` | `SessionSettings.MemorySizeInMB` |
| `ProcessSettings.CmdLine` | `ProcessSettings.CommandLine` (`IList<string>`) |
| `DeleteContainerFlags.None` | `DeleteContainerOption.None` / `Force` |

### `CS1705` : la version du SDK Windows

Le paquet déclare `net8.0-windows10.0.19041.0`, mais son `wslcsdkcs.dll` est compilé contre `Microsoft.Windows.SDK.NET` 10.0.26100.79. Passer à `net10.0-windows10.0.26100.0` ne suffit pas (le SDK choisit la projection 10.0.26100.38, même erreur) ; il faut forcer la version. `10.0.26100.79` n'existe pas sur nuget.org (`NU1102`, la plus proche : `10.0.26100.80`) :

```xml
<TargetFramework>net10.0-windows10.0.26100.0</TargetFramework>
<WindowsSdkPackageVersion>10.0.26100.80</WindowsSdkPackageVersion>
<RuntimeIdentifier>win-x64</RuntimeIdentifier>
```

### Première exécution

```text
WSL container service 2.9.11
Session started, storage in C:\Users\spare\AppData\Local\WslcHost
Image alpine:latest (8 MB)
Hello from 3.24.1 on 6.18.40.1-microsoft-standard-WSL2
Container b27dd2f80927 exited with code 0
```

7 s au total, téléchargement d'alpine compris dans une session neuve et vide. Le conteneur voit les limites de la session : `nproc` → `2`, `free -m` → `1907` Mo au total pour `MemorySizeInMB = 2048`.

### Où apparaît la session de l'application

Pendant qu'un conteneur de 20 secondes tourne :

```text
> wslc system session list
ID   Creator PID   Display Name
6    350476        wslc-cli-admin-spare
8    275812        wslc-cli-spare
16   110952        wslc-host
> Get-Process vmmem*
vmmemCmZygote     0
vmmemWSL       3307
vmmemwslc-host  510
> wslc --session wslc-host container list
CONTAINER ID   IMAGE           COMMAND                  CREATED         STATUS         PORTS   NAMES
2e75803c92a9   alpine:latest   "/bin/sh -c 'echo st…"   4 seconds ago   Up 3 seconds           wslc-host-hello
```

- La session est une session `wslc` ordinaire : même VM `vmmem<session>`, visible et pilotable depuis la CLI avec `--session`.
- Son disque est là où l'application l'a choisi, `%LocalAppData%\WslcHost\storage.vhdx` (67 Mo après le téléchargement), pas sous `%LocalAppData%\wslc\sessions`. Ses limites viennent de `SessionSettings`, pas de `settings.yaml` (8 CPU là-bas, 2 vus par le conteneur).
- Après `session.Terminate()`, la session et son `vmmem` disparaissent tout de suite, sans le délai d'inactivité de 30 s de la CLI.

### Piège : un `Start` en échec laisse le conteneur derrière lui

Une exécution lancée depuis Git Bash avec `/bin/sh` en argument : MSYS convertit le chemin en `C:/Program Files/Git/usr/bin/sh`, et `container.Start()` lève :

```text
Unhandled exception. System.ArgumentException: The parameter is incorrect.

failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "C:/Program Files/Git/usr/bin/sh": stat C:/Program Files/Git/usr/bin/sh: no such file or directory: unknown
```

L'exécution suivante échoue sur `CreateContainer` :

```text
Unhandled exception. System.Runtime.InteropServices.COMException (0x800700B7): Cannot create a file when that file already exists.

Conflict. The container name "/wslc-host-hello" is already in use by container "176a59b772bebfb974a8404150407157d49cc279cbe2f66c2d6e2788f9bfbadc". You have to remove (or rename) that container to be able to reuse that name.
```

Le conteneur survit au processus dans `storage.vhdx`. Deux corrections dans le programme : `Delete(DeleteContainerOption.Force)` dans un `finally`, et au démarrage `OpenContainer` + `Delete` d'un reste éventuel (`COMException` s'il n'y en a pas). Vérifié : reste supprimé (`Removed leftover container wslc-host-hello`), puis une commande inexistante (`/nope`) ne laisse plus rien derrière elle.

**Conclusion :** l'API fonctionne et elle est rapide, mais en préversion sa documentation est en retard sur le paquet : noms, version du SDK. Compiler d'abord, lire les types en cas de doute. Sur GitHub Actions, les runners Windows n'ont pas le service WSL containers : la CI ne fait que compiler le programme.
## Questions ouvertes

- ~~Où `wslc` stocke-t-il ses images et conteneurs ?~~ Dans `%LocalAppData%\wslc\sessions\<session>\storage.vhdx`, un disque virtuel par session. Il grossit avec les images et ne rétrécit pas tout seul (voir ci-dessus).
- ~~Peut-on limiter la mémoire et le CPU de la VM utilisée par `wslc` ?~~ Oui : `cpuCount` et `memorySize` dans `settings.yaml`, puis terminer la session (voir ci-dessus).
- ~~`wslc` et Docker Desktop peuvent-ils publier des ports sans conflit ?~~ Ils peuvent publier le même port **sans aucune erreur**, et c'est bien le problème : `127.0.0.1` atteint `wslc`, `localhost` atteint Docker (voir ci-dessus).
- ~~Comment compacter le `storage.vhdx` d'une session ?~~ Terminer la session, puis `Optimize-VHD -Mode Full` en administrateur : 3995 Mo → 2789 Mo (voir ci-dessus).
- L'intégration MSBuild `WslcImage` (construire une image en `.tar` pendant `dotnet build`) fonctionne-t-elle ? *À vérifier.*
