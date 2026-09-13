---
title: 5. wslc ou Docker Desktop ?
description: Comparer wslc et Docker Desktop, et utiliser l'API WSL container depuis une application Windows.
sidebar:
  order: 5
---

## Comparaison

| Critère | `wslc` (WSL containers) | Docker Desktop |
|---|---|---|
| Installation | incluse dans WSL ≥ 2.9.3 | produit séparé |
| Maturité (sept. 2026) | préversion publique | stable |
| CLI | proche de Docker | `docker` |
| API pour applications Windows | oui — NuGet `Microsoft.WSL.Containers` | API Docker Engine (HTTP) |
| Gestion en entreprise | Microsoft Defender for Endpoint, Intune | Docker Business |
| Écosystème (Compose, Kubernetes, extensions, interface graphique) | pas de commande `compose` en 2.9.11 ; Kubernetes, extensions, interface graphique *à vérifier* | complet |

:::note[Vérifié : pas de Compose dans `wslc` 2.9.11]
`wslc compose` → `Unrecognized command: 'compose'`, et `docker compose` ne peut pas atteindre le moteur Docker de la session. Une petite pile se reproduit avec un script (`network create`, `volume create`, `run --network --network-alias`) ; la traduction testée d'un `compose.yaml` est dans le [journal](../journal/).
:::

:::note[Vérifié : les images ne sont pas partagées]
Après `docker pull busybox`, `wslc image list` ne l'affiche pas : chaque outil a son propre stock (`docker_data.vhdx` pour Docker, un `storage.vhdx` par session `wslc`). Une image utilisée par les deux est téléchargée deux fois, et le même tag `latest` peut même désigner deux versions différentes (qdrant 1.16.3 dans Docker, 1.19.1 dans `wslc`). Détails dans le [journal](../journal/).
:::

## Quand choisir quoi

- **`wslc`** : besoin simple (lancer une base de données, un service, un outil), envie de ne pas dépendre de Docker Desktop, ou application Windows qui doit piloter des conteneurs.
- **Docker Desktop** : projets basés sur Docker Compose, Kubernetes local, équipe déjà outillée autour de Docker.
- **Les deux** : possible, mais chaque outil garde sa propre VM et sa propre mémoire. Sur une machine chargée, c'est un coût réel (voir le [journal](../journal/)).

## L'API WSL container

Une application Windows peut créer ses propres conteneurs Linux. Les objets suivent le cycle de vie :

| Objet | Rôle |
|---|---|
| `WslcService` | vérifier que les composants WSL sont installés, version du service |
| `Session` | hôte WSL qui gère les images et crée les conteneurs |
| `Container` | démarrer, arrêter, inspecter, supprimer ; lancer des processus |
| `Process` | lire `stdout`/`stderr`, écrire sur `stdin`, envoyer des signaux |

```powershell
dotnet add package Microsoft.WSL.Containers
```

```csharp
using System.Text;
using Microsoft.WSL.Containers;

if (WslcService.GetMissingComponents() != ComponentFlags.None)
{
    Console.WriteLine("Composants WSL manquants : lancer wsl --install");
    return;
}

var session = new Session(new SessionSettings("MonApp", @"C:\WslcData")
{
    CpuCount = 4,
    MemoryMB = 4096
});
session.Start();

await session.PullImageAsync(new PullImageOptions("docker.io/library/alpine:latest"));

var container = session.CreateContainer(new ContainerSettings("alpine:latest")
{
    Name = "hello-container",
    InitProcess = new ProcessSettings
    {
        CmdLine = new[] { "/bin/echo", "Hello from WSL Container!" },
        OutputMode = ProcessOutputMode.Event
    }
});

container.InitProcess.OutputReceived += data => Console.Write(Encoding.UTF8.GetString(data));
container.Start();

// Nettoyage
container.Stop(Signal.SIGTERM, TimeSpan.FromSeconds(10));
container.Delete(DeleteContainerFlags.None);
session.Terminate();
```

Source : [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container). Exemples complets : [aka.ms/wslc-samples](https://aka.ms/wslc-samples).

## À retenir

- `wslc` = conteneurs natifs WSL, sans produit tiers, encore en préversion.
- Docker Desktop reste plus complet (Compose, Kubernetes, interface graphique).
- L'API `Microsoft.WSL.Containers` ouvre un usage que Docker Desktop ne couvre pas directement : des applications Windows qui embarquent des conteneurs Linux.

## Exercice

Choisis un service que tu lances aujourd'hui avec Docker (par exemple [qdrant](https://qdrant.tech/) ou [MongoDB](https://www.mongodb.com/)) et fais-le tourner avec `wslc`. Note dans le [journal](../journal/) ce qui diffère.

<details>
<summary>Piste</summary>

Si Docker publie déjà qdrant sur 6333, choisis **un autre port Windows** : `wslc` prendrait 6333 sans aucune erreur et enlèverait discrètement `127.0.0.1:6333` au conteneur Docker.

```powershell
wslc volume create qdrant-data
wslc run -d --name qdrant -p 16333:6333 -v qdrant-data:/qdrant/storage qdrant/qdrant
curl.exe http://127.0.0.1:16333/
wslc container stop qdrant
```

Points à observer : l'image est-elle retéléchargée ? Est-ce la même version que le `latest` de Docker ? Quelle mémoire consomme la VM ? Que journalise qdrant si tu montes un dossier Windows au lieu d'un volume ? Réponses dans le [journal](../journal/).

</details>
