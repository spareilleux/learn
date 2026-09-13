---
title: 3. Premiers conteneurs
description: Lancer, publier, inspecter et arrêter des conteneurs avec wslc.
sidebar:
  order: 3
---

## Se repérer dans la CLI

```powershell
wslc --help              # toutes les commandes
wslc <COMMANDE> --help   # aide d'une commande
wslc image list          # images présentes localement
wslc container list      # conteneurs en cours d'exécution
wslc container list --all  # y compris les conteneurs arrêtés
wslc stats               # consommation CPU / mémoire des conteneurs
```

## Un conteneur jetable

```powershell
wslc run --rm -it ubuntu:latest bash -c "echo Hello world from WSL container!"
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
curl localhost:8080

# Voir le conteneur
wslc container list

# Exécuter une commande dans le conteneur en cours
wslc exec web cat /etc/os-release

# L'arrêter (et, grâce à --rm, le supprimer)
wslc container stop web
```

| Option | Effet |
|---|---|
| `-d` | détaché : le conteneur tourne en arrière-plan |
| `-p 8080:80` | publie le port : `hôte:conteneur` |
| `--name web` | nom lisible, utilisable à la place de l'identifiant |

:::note[Si tu connais Docker]
Ces commandes sont presque identiques à `docker run`, `docker exec`, etc. La principale différence visible : les sous-commandes sont regroupées (`wslc container list` plutôt que `docker ps`).
:::

## À retenir

- `run` crée **et** démarre un conteneur ; `--rm` évite d'accumuler des conteneurs arrêtés.
- `-p hôte:conteneur` rend un service accessible depuis Windows.
- `exec` exécute une commande dans un conteneur **déjà lancé**.

## Exercices

1. Lance un conteneur `nginx` accessible sur le port **9090** de Windows, nommé `site`, puis vérifie qu'il répond.

<details>
<summary>Solution</summary>

```powershell
wslc run -d --rm -p 9090:80 --name site nginx
curl localhost:9090
wslc container stop site
```

</details>

2. Comment connaître la distribution Linux utilisée par l'image `nginx` sans ouvrir de shell interactif ?

<details>
<summary>Solution</summary>

```powershell
wslc run -d --rm --name site nginx
wslc exec site cat /etc/os-release
wslc container stop site
```

</details>

3. Quelle différence entre `wslc container list` et `wslc container list --all` ?

<details>
<summary>Solution</summary>

Sans `--all`, seuls les conteneurs **en cours d'exécution** sont listés. Avec `--all`, les conteneurs arrêtés (mais pas supprimés) apparaissent aussi.

</details>
