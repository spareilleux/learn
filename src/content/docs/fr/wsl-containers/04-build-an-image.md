---
title: 4. Construire une image
description: Écrire un Containerfile, construire l'image, lire les logs et nettoyer.
sidebar:
  order: 4
---

## Où ranger le code

:::tip[Performance]
Garde le code sur le **même système de fichiers que les outils** qui le lisent. Pour des outils Linux, travaille dans la distro (par exemple `~/projets` sous Ubuntu) plutôt que sur `C:\` : l'accès aux fichiers Windows depuis Linux est nettement plus lent.
:::

Avec VS Code, l'extension **WSL** permet d'éditer le projet côté Linux et d'utiliser le terminal intégré.

## Le Containerfile

Un `Containerfile` (même syntaxe qu'un `Dockerfile`) décrit comment construire l'image. Exemple pour une petite application Django :

```dockerfile
FROM python:3
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```

| Instruction | Rôle |
|---|---|
| `FROM` | image de départ |
| `WORKDIR` | dossier de travail dans l'image |
| `COPY` | copie des fichiers du projet |
| `RUN` | commande exécutée **pendant la construction** |
| `EXPOSE` | documente le port écouté |
| `CMD` | commande lancée **au démarrage du conteneur** |

:::note[Pourquoi copier `requirements.txt` en premier ?]
Chaque instruction produit une couche mise en cache. Tant que `requirements.txt` ne change pas, `pip install` n'est pas rejoué, même si le reste du code change.
:::

## Construire et lancer

```powershell
# Depuis le dossier qui contient le Containerfile
wslc build -t helloworld-django .
wslc image list

wslc run -d --rm -p 8000:8000 --name django helloworld-django
wslc container list
wslc container logs django
```

Ouvre `http://localhost:8000/` dans un navigateur Windows. Pour prouver que l'application tourne bien sous Linux :

```powershell
wslc exec django uname    # → Linux
wslc container stop django
```

## Diagnostiquer

```powershell
wslc container inspect <conteneur>
wslc container logs <conteneur>
wslc image inspect <image>
```

## Libérer de l'espace disque

```powershell
wslc container prune   # supprime les conteneurs arrêtés
wslc image prune       # supprime les images inutilisées
```

## À retenir

- `RUN` s'exécute à la construction, `CMD` au démarrage.
- `-t nom` donne un nom à l'image pour la réutiliser.
- `logs` et `inspect` sont les premiers réflexes quand un conteneur ne se comporte pas comme prévu.

## Exercices

1. Écris un `Containerfile` minimal qui sert un dossier statique avec `nginx`.

<details>
<summary>Solution</summary>

```dockerfile
FROM nginx
COPY site/ /usr/share/nginx/html/
```

```powershell
wslc build -t mon-site .
wslc run -d --rm -p 8080:80 --name mon-site mon-site
curl localhost:8080
```

</details>

2. Le conteneur `django` s'arrête immédiatement après `run`. Quelles commandes lancer, et dans quel ordre ?

<details>
<summary>Solution</summary>

Il ne faut **pas** utiliser `--rm` pendant le diagnostic, sinon le conteneur disparaît avec ses logs.

```powershell
wslc run -d -p 8000:8000 --name django helloworld-django
wslc container list --all        # statut du conteneur
wslc container logs django       # message d'erreur de l'application
wslc container inspect django    # configuration effective (commande, ports…)
```

</details>
