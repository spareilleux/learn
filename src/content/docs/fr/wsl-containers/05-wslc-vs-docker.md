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
| Écosystème (Compose, Kubernetes, extensions, interface graphique) | *à vérifier* — plus limité en préversion | complet |

:::caution[À vérifier]
- **Compose** : des retours de la préversion signalent un support limité. Je ne l'ai pas encore testé.
- **Images partagées ?** `wslc` semble avoir son propre stockage : les images téléchargées par Docker ne seraient pas visibles. À confirmer avec `wslc image list` après un `docker pull`.
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

Choisis un service que tu lances aujourd'hui avec Docker (par exemple `qdrant` ou `mongodb`) et fais-le tourner avec `wslc`. Note dans le [journal](../journal/) ce qui diffère.

<details>
<summary>Piste</summary>

```powershell
wslc run -d --rm -p 6333:6333 --name qdrant qdrant/qdrant
curl localhost:6333
wslc container stop qdrant
```

Points à observer : l'image est-elle retéléchargée ? Le port entre-t-il en conflit avec le conteneur Docker existant ? Quelle mémoire consomme la VM ?

</details>
