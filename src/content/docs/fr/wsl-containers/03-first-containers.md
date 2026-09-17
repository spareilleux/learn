---
title: 3. Premiers conteneurs
description: Lancer, publier, inspecter et arrêter des conteneurs avec wslc.
sidebar:
  order: 3
---

:::caution[Utilise un terminal non élevé]
`wslc` n'a pas besoin des droits administrateur. Un terminal élevé utilise une **session différente** (`wslc-cli-admin-<user>` au lieu de `wslc-cli-<user>`), avec ses propres images, conteneurs, volumes et réseaux : une image téléchargée dans l'une n'est pas visible dans l'autre. La section [Une session par niveau de privilège](#une-session-par-niveau-de-privilège) plus bas le montre.
:::

## Se repérer dans la CLI

```powershell
wslc --help                # toutes les commandes
wslc <COMMAND> --help      # aide d'une commande
wslc image list            # images présentes localement
wslc container list        # conteneurs en cours d'exécution
wslc container list --all  # y compris les conteneurs arrêtés
wslc stats                 # consommation CPU / mémoire des conteneurs en cours d'exécution
```

## Un conteneur jetable

```powershell
wslc run --rm -it ubuntu:latest bash -c "echo Hello world from WSL container!"
```

```text
...
Status: Downloaded newer image for ubuntu:latest
Hello world from WSL container!
```

| Option | Effet |
|---|---|
| `--rm` | supprime le conteneur dès qu'il s'arrête |
| `-it` | mode interactif avec terminal |
| `ubuntu:latest` | l'image (téléchargée automatiquement si absente) |
| `bash -c "…"` | la commande à exécuter dans le conteneur |

## Un serveur web en arrière-plan

```powershell
# Lancer nginx en arrière-plan, port 8080 de Windows → port 80 du conteneur
wslc run -d --rm -p 8080:80 --name web nginx

# Interroger le serveur depuis Windows
curl.exe -s -o NUL -w "%{http_code}`n" http://127.0.0.1:8080/

# Voir le conteneur
wslc container list

# Exécuter une commande dans le conteneur en cours
wslc exec web cat /etc/os-release

# Consommation des ressources (un instantané, puis la commande rend la main)
wslc stats

# L'arrêter (et, grâce à --rm, le supprimer)
wslc container stop web
```

```text
1796028d1f6addd8344386cf89632ff99fb5c73faa16c943184421eb08e0943b
200
CONTAINER ID   IMAGE   COMMAND                  CREATED         STATUS         PORTS                    NAMES
1796028d1f6a   nginx   "/docker-entrypoint.…"   3 seconds ago   Up 2 seconds   127.0.0.1:8080->80/tcp   web
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
...
```

| Option | Effet |
|---|---|
| `-d` | détaché : le conteneur tourne en arrière-plan |
| `-p 8080:80` | publie le port : `hôte:conteneur` |
| `--name web` | nom lisible, utilisable à la place de l'identifiant |

:::caution[`127.0.0.1` plutôt que `localhost`]
`wslc` publie uniquement sur `127.0.0.1` (voir la colonne `PORTS`). Si Docker Desktop publie aussi le port 8080, il écoute sur `0.0.0.0` **et** `[::]` : `localhost` se résout d'abord en `::1` et atteint le conteneur de Docker, sans erreur d'un côté comme de l'autre. Adresse `127.0.0.1` explicitement. Et appelle `curl.exe` : dans Windows PowerShell 5.1, `curl` est un alias de `Invoke-WebRequest`.
:::

`wslc stats` affiche la limite de la session dans la colonne `MEM USAGE / LIMIT` :

```text
CONTAINER ID   NAME   CPU %   MEM USAGE / LIMIT     MEM %   NET I/O     BLOCK I/O     PIDS
1e72dbeb2a9a   site   0.00%   8.801MiB / 15.62GiB   0.06%   736B / 0B   0B / 8.19kB   9
```

15.62 GiB ici, parce que la session est limitée à 16 Go dans `settings.yaml` (voir la [leçon 6](../06-resources-and-limits/)).

:::note[Si tu connais Docker]
Ces commandes sont presque identiques à `docker run`, `docker exec`, etc. Les sous-commandes sont regroupées (`wslc container list`, `wslc image list`), mais les raccourcis à la Docker existent aussi : `wslc ps`, `wslc images`, `wslc rmi`, `wslc logs`.
:::

## Une session par niveau de privilège

`wslc` ne parle pas à un moteur unique, commun à toute la machine, comme Docker Desktop. Il crée une **session**, avec sa propre VM, son moteur et son disque virtuel, pour chaque utilisateur **et chaque niveau de privilège**. Le piège apparaît la première fois que tu ouvres un terminal administrateur : dans un `cmd.exe` élevé tout neuf, `wslc run --rm hello-world` a **retéléchargé** l'image, alors qu'elle avait déjà été tirée depuis un terminal normal :

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

`wslc-cli-<user>` est la session des terminaux non élevés, `wslc-cli-admin-<user>` celle des terminaux administrateur. Pour voir ce qui est vraiment séparé, le test a créé un volume et un réseau dans le terminal normal, puis y a supprimé l'image :

```powershell
wslc volume create sesstest-vol
wslc network create sesstest-net
wslc image remove hello-world
wslc images    # vide
```

Dans le terminal administrateur, l'image supprimée est toujours là, alors que le nouveau volume et le nouveau réseau n'y sont pas, et même les réseaux par défaut ont d'autres identifiants :

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

L'option globale `--session` choisit une autre session. Elle se place **avant** la sous-commande ; placée après, `wslc` répond `Option name was not recognized`. L'accès est asymétrique :

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

Sur le disque, chaque session a ses propres disques virtuels, d'un peu moins de 600 Mo chacun à ce moment-là :

```text
%LocalAppData%\wslc\sessions\wslc-cli-spare\storage.vhdx         ~587 MB
%LocalAppData%\wslc\sessions\wslc-cli-spare\swap.vhdx            36 MB
%LocalAppData%\wslc\sessions\wslc-cli-admin-spare\storage.vhdx   ~577 MB
%LocalAppData%\wslc\sessions\wslc-cli-admin-spare\swap.vhdx      36 MB
```

Nettoyage, dans le terminal normal : `wslc volume remove sesstest-vol` et `wslc network remove sesstest-net`. La règle simple : `wslc` n'a jamais besoin de l'élévation, alors utilise toujours un terminal non élevé.

## À retenir

- `run` crée **et** démarre un conteneur ; `--rm` évite d'accumuler des conteneurs arrêtés.
- `-p hôte:conteneur` rend un service accessible depuis Windows, sur `127.0.0.1`.
- `exec` exécute une commande dans un conteneur **déjà lancé**.
- Toujours le même type de terminal (non élevé) : chaque niveau de privilège a sa propre session, avec ses propres images, conteneurs, volumes, réseaux et disque.
- `--session <nom>` se place avant la sous-commande ; un administrateur peut atteindre la session normale, pas l'inverse.

## Exercices

1. Lance un conteneur `nginx` accessible sur le port **9090** de Windows, nommé `site`, puis vérifie qu'il répond.

<details>
<summary>Solution</summary>

```powershell
wslc run -d --rm -p 9090:80 --name site nginx
curl.exe -s -o NUL -w "%{http_code}`n" http://127.0.0.1:9090/
wslc container stop site
```

`200` signifie que nginx a répondu.

</details>

2. Comment connaître la distribution Linux utilisée par l'image `nginx` sans ouvrir de shell interactif ?

<details>
<summary>Solution</summary>

```powershell
wslc run -d --rm --name site nginx
wslc exec site cat /etc/os-release
wslc container stop site
```

En septembre 2026, `nginx:latest` est basée sur `Debian GNU/Linux 13 (trixie)`.

</details>

3. Quelle différence entre `wslc container list` et `wslc container list --all` ?

<details>
<summary>Solution</summary>

Sans `--all`, seuls les conteneurs **en cours d'exécution** sont listés. Avec `--all`, les conteneurs arrêtés (mais pas supprimés) apparaissent aussi.

</details>

4. Dans un PowerShell administrateur, tu tapes `wslc image list --session wslc-cli-<user>` et obtiens `Option name was not recognized`. Corrige la commande. La même commande fonctionnerait-elle depuis un terminal normal avec le nom de la session admin ?

<details>
<summary>Solution</summary>

`--session` est une option globale et se place avant la sous-commande : `wslc --session wslc-cli-<user> image list`. Depuis un terminal administrateur, ça marche. L'inverse, `wslc --session wslc-cli-admin-<user> image list` depuis un terminal normal, échoue avec `ERROR_ELEVATION_REQUIRED`.

</details>

5. Tu as tiré `nginx` dans un terminal normal, et un script de build lancé en administrateur le retélécharge. Donne deux façons d'éviter ce double téléchargement.

<details>
<summary>Solution</summary>

La meilleure : lancer le script depuis un terminal non élevé, puisque `wslc` n'a pas besoin de l'élévation, et tout arrive dans `wslc-cli-<user>`. Si le script doit tourner en administrateur pour une autre raison, fais viser explicitement la session normale à ses commandes `wslc` avec `wslc --session wslc-cli-<user> …`, ce qu'un administrateur a le droit de faire. Sinon, chaque session garde sa propre copie, dans deux fichiers `storage.vhdx`.

</details>

## Sources

- [Bien démarrer avec les conteneurs sur WSL — Microsoft Learn](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers)
- [nginx — Docker Hub](https://hub.docker.com/_/nginx)
- [curl](https://curl.se/)
