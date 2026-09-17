---
title: 5. wslc ou Docker Desktop ?
description: Comparer wslc et Docker Desktop, les faire tourner sur une même machine, et éviter leurs pièges silencieux - des stocks d'images séparés, un tag latest qui diffère, et le même port publié deux fois sans erreur.
sidebar:
  order: 5
---

Après quatre leçons, `wslc` couvre ce que la plupart des développeurs font chaque jour avec Docker : télécharger, lancer, publier, exécuter une commande, construire. La question pratique n'est pas de savoir s'il remplace Docker Desktop en général, mais s'il peut le remplacer sur **ta** machine, ou vivre à côté. Cette leçon compare les deux, puis teste la cohabitation : partagent-ils les images, fonctionnent-ils encore tous les deux, et que se passe-t-il quand les deux publient le même port ? Les mesures sont dans le [journal](../journal/).

## Comparaison

| Critère | `wslc` (WSL containers) | Docker Desktop |
|---|---|---|
| Installation | incluse dans WSL ≥ 2.9.3 | produit séparé |
| Maturité (sept. 2026) | préversion publique | stable |
| CLI | proche de Docker | `docker` |
| VM Linux | une par session, `vmmem<session>` | une distribution, `docker-desktop` |
| Limites de ressources | par session, `settings.yaml` ([leçon 6](../06-resources-and-limits/)) | pour la VM WSL 2, `.wslconfig` |
| API pour applications Windows | oui — NuGet `Microsoft.WSL.Containers` ([leçon 9](../09-csharp-api/)) | API Docker Engine (HTTP) |
| Gestion en entreprise | Microsoft Defender for Endpoint, Intune | Docker Business |
| Écosystème (Compose, Kubernetes, extensions, interface graphique) | aucun en 2.9.11 : pas de commande `compose` ([leçon 8](../08-compose/)), pas de Kubernetes (k3s ne démarre pas), pas d'extensions, pas de page conteneurs dans WSL Settings ([leçon 10](../10-networking-kubernetes-gui/)) | complet |

La ligne qui compte le plus pour une équipe C# ou Java, c'est l'API. Tous les outils construits sur l'API Docker Engine, de Testcontainers aux vues conteneurs des IDE, ont besoin d'un point d'accès que `wslc` n'expose pas à Windows ([leçon 8](../08-compose/)). En échange, `Microsoft.WSL.Containers` donne à une application Windows ce que Docker Desktop ne lui donne pas : ses propres conteneurs, sans aucun produit à installer.

## Les deux sur une même machine

### Docker Desktop fonctionne toujours avec WSL 2.9.11

La mise à jour de WSL vers la pre-release n'a pas cassé Docker Desktop 4.61, mais sa CLI a d'abord donné une réponse trompeuse. `docker desktop start` répondait `Docker Desktop is already running` alors qu'aucun processus Docker Desktop n'existait, et `docker desktop status` répondait `Could not retrieve status`. Lancer directement `C:\Program Files\Docker\Docker\Docker Desktop.exe` a fonctionné : le moteur 29.2.1 était prêt après environ 130 secondes, et `docker run --rm hello-world` a réussi. Podman 5.8.3 a aussi démarré et lancé son image de test.

### Les images ne sont pas partagées

Après `docker pull busybox`, les deux listes diffèrent :

```text
> docker images            > wslc images
postgres:16-alpine          alpine   latest
busybox:latest
hello-world:latest
node:18-alpine
```

Chaque outil a son propre stock : `docker_data.vhdx`, environ 50 Go ici, pour Docker, et un `storage.vhdx` par session pour `wslc`. Une image utilisée par les deux est téléchargée deux fois et stockée deux fois. Pire, le même tag peut désigner deux versions : `qdrant/qdrant:latest` était qdrant 1.16.3 dans Docker, téléchargé des mois plus tôt, et 1.19.1 dans `wslc` ([leçon 7](../07-volumes-and-a-real-service/)).

### Le même port, deux fois, sans erreur

C'est le piège le plus risqué. Un test avec deux serveurs web qui répondent différemment : `nginx` dans `wslc`, et `httpd`, le serveur Apache dont la page dit « It works! », dans Docker. La page indique quel outil a répondu.

```powershell
wslc run -d --name webwslc -p 8080:80 nginx
docker run -d --name webdocker -p 8080:80 httpd
curl.exe http://127.0.0.1:8080/   # nginx  → wslc
curl.exe http://localhost:8080/   # It works! → Docker
```

**Les deux conteneurs démarrent sans aucune erreur.** Windows accepte les deux écoutes parce qu'elles ne portent pas exactement sur la même adresse. Les écoutes sur le port 8080, avec leurs processus :

```text
TCP  0.0.0.0:8080     LISTENING  com.docker.backend
TCP  [::]:8080        LISTENING  com.docker.backend
TCP  127.0.0.1:8080   LISTENING  dllhost      ← wslc
TCP  [::1]:8080       LISTENING  wslrelay
```

`127.0.0.1` va à `wslc`, parce que l'adresse la plus précise gagne, tandis que `localhost` se résout d'abord en `::1` et tombe sur Docker. L'ordre des démarrages et un `0.0.0.0` explicite n'y changent rien :

| Variante | Erreurs | `127.0.0.1` | `localhost` |
|---|---|---|---|
| `wslc` d'abord, puis Docker (8080) | aucune | wslc | Docker |
| Docker d'abord, puis `wslc` (8081) | aucune | wslc | Docker |
| Docker, puis `wslc -p 0.0.0.0:8082:80` | aucune | wslc | Docker |
| `wslc -p 0.0.0.0:8083:80`, puis Docker | aucune | wslc | Docker |

Pense à ce que cela signifie pour une application. Une configuration Spring Boot ou ASP.NET Core qui indique `localhost:5432` et un script de test qui indique `127.0.0.1:5432` peuvent parler à deux bases de données différentes, et tous les outils annoncent un succès. La correction est organisationnelle : donne à chaque outil sa propre plage de ports, comme la [leçon 7](../07-volumes-and-a-real-service/) le fait avec 16333 pour le qdrant de `wslc`.

### Deux VM coûtent deux VM

Chaque outil garde sa propre VM et sa propre mémoire. Une session `wslc` inactive coûte environ 0,9 Go et s'arrête 30 secondes après la dernière commande ([leçon 6](../06-resources-and-limits/)) ; la VM de Docker Desktop reste active tant que Docker Desktop tourne. Sur une machine déjà à court de mémoire, la première entrée du journal montre où cela peut mener : `Wsl/0x8007000e`, mémoire insuffisante, et Docker Desktop qui plante.

## Quand choisir quoi

- **`wslc`** : besoins simples, comme lancer une base de données, un service ou un outil ; envie de ne pas dépendre de Docker Desktop et de sa licence ; ou application Windows qui doit piloter ses propres conteneurs.
- **Docker Desktop**, ou Podman : projets basés sur Docker Compose, Kubernetes local, outils qui ont besoin de l'API Docker Engine comme Testcontainers, et équipe déjà outillée autour de Docker.
- **Les deux** : possible, avec des ports séparés et en gardant en tête la mémoire de deux VM.

## À retenir

- `wslc` = conteneurs natifs WSL, sans produit tiers, encore en préversion.
- Docker Desktop reste plus complet : Compose, Kubernetes, extensions, une interface graphique et l'API Docker Engine.
- Docker Desktop 4.61 continue de fonctionner avec WSL 2.9.11, mais lance-le depuis son exécutable si `docker desktop start` prétend qu'il tourne déjà.
- Les images ne sont pas partagées : une image utilisée par les deux outils est téléchargée deux fois, et `latest` peut désigner deux versions différentes.
- Les deux outils peuvent publier le même port sans erreur. `127.0.0.1` atteint alors `wslc` et `localhost` atteint Docker : garde leurs ports séparés.
- L'API `Microsoft.WSL.Containers` ouvre un usage que Docker Desktop ne couvre pas directement : des applications Windows qui embarquent des conteneurs Linux.

## Exercices

1. Docker Desktop publie PostgreSQL sur le port 5432. Tu lances un autre PostgreSQL avec `wslc run -d -p 5432:5432 postgres:16-alpine`. Ton application ASP.NET Core utilise `Host=localhost;Port=5432` et ton script de migration utilise `127.0.0.1`. Quelle base de données chacun atteint-il, et quelles erreurs vois-tu ?

<details>
<summary>Solution</summary>

Aucune erreur nulle part. Le script de migration, sur `127.0.0.1`, atteint la base de `wslc`, qui écoute sur cette adresse exacte. L'application, sur `localhost`, qui se résout d'abord en `::1`, atteint la base de Docker. Les migrations sont appliquées à une base que l'application ne lit jamais. Cela découle des quatre variantes mesurées plus haut ; PostgreSQL lui-même ne faisait pas partie du test, donc *à vérifier* avec ta bibliothèque cliente, car certaines résolvent `localhost` d'abord en IPv4.

</details>

2. Comment savoir, en quelques secondes, quel processus écoute sur chaque adresse du port 8080 ?

<details>
<summary>Solution</summary>

Avec PowerShell, qui n'a pas besoin d'élévation pour cela :

```powershell
Get-NetTCPConnection -LocalPort 8080 -State Listen | Select-Object LocalAddress, OwningProcess, @{n='Process';e={(Get-Process -Id $_.OwningProcess).ProcessName}}
```

Un `dllhost` sur `127.0.0.1` est l'écoute de `wslc` ; `com.docker.backend` sur `0.0.0.0` et `[::]` est Docker Desktop. Cette commande a été vérifiée sur un autre port de la même machine, pas pendant le test du port 8080. Depuis un terminal administrateur, `netstat -abno` donne la même information.

</details>

3. Un collègue dit : « Pas besoin de la retélécharger, j'ai déjà `qdrant/qdrant:latest` dans Docker. » Donne deux raisons pour lesquelles c'est faux pour `wslc`.

<details>
<summary>Solution</summary>

D'abord, les stocks sont séparés : `wslc` télécharge de nouveau l'image dans le `storage.vhdx` de sa session. Ensuite, `latest` est résolu au moment du téléchargement, donc la copie de `wslc` peut être une version plus récente que celle de Docker : 1.19.1 contre 1.16.3 dans le test. Fixe un tag de version quand les deux doivent correspondre.

</details>

4. Après une mise à jour de WSL, `docker desktop start` répond `Docker Desktop is already running`, mais `docker ps` échoue. Que fais-tu ?

<details>
<summary>Solution</summary>

Vérifie qu'un processus Docker Desktop existe vraiment, par exemple avec `Get-Process "Docker Desktop" -ErrorAction SilentlyContinue`. S'il n'y en a aucun, lance directement `C:\Program Files\Docker\Docker\Docker Desktop.exe` et attends le moteur, ce qui a pris environ deux minutes ici, avant de relancer `docker ps`.

</details>

## Sources

- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container)
- [Docker Desktop](https://docs.docker.com/desktop/) et [Docker Desktop WSL 2 backend](https://docs.docker.com/desktop/features/wsl/) — documentation Docker
- [Published ports](https://docs.docker.com/engine/network/port-publishing/) — documentation Docker
- [`Get-NetTCPConnection` — Microsoft Learn](https://learn.microsoft.com/powershell/module/nettcpip/get-nettcpconnection)
- [Testcontainers](https://testcontainers.com/)
