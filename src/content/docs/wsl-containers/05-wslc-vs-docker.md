---
title: 5. wslc or Docker Desktop?
description: Compare wslc and Docker Desktop, and use the WSL container API from a Windows application.
sidebar:
  order: 5
---

## Comparison

| Criterion | `wslc` (WSL containers) | Docker Desktop |
|---|---|---|
| Installation | included in WSL ≥ 2.9.3 | separate product |
| Maturity (Sept. 2026) | public preview | stable |
| CLI | close to Docker | `docker` |
| API for Windows applications | yes — NuGet `Microsoft.WSL.Containers` | Docker Engine API (HTTP) |
| Enterprise management | Microsoft Defender for Endpoint, Intune | Docker Business |
| Ecosystem (Compose, Kubernetes, extensions, GUI) | *to verify* — more limited in preview | complete |

:::caution[To verify]
- **Compose**: preview feedback reports limited support. I haven't tested it yet.
- **Shared images?** `wslc` seems to have its own storage: images pulled by Docker would not be visible. To confirm with `wslc image list` after a `docker pull`.
:::

## When to choose what

- **`wslc`**: simple needs (running a database, a service, a tool), a wish not to depend on Docker Desktop, or a Windows application that needs to drive containers.
- **Docker Desktop**: projects based on Docker Compose, local Kubernetes, a team already tooled around Docker.
- **Both**: possible, but each tool keeps its own VM and its own memory. On a busy machine, that's a real cost (see the [journal](../journal/)).

## The WSL container API

A Windows application can create its own Linux containers. The objects follow the lifecycle:

| Object | Role |
|---|---|
| `WslcService` | check that WSL components are installed, service version |
| `Session` | WSL host that manages images and creates containers |
| `Container` | start, stop, inspect, delete; launch processes |
| `Process` | read `stdout`/`stderr`, write to `stdin`, send signals |

```powershell
dotnet add package Microsoft.WSL.Containers
```

```csharp
using System.Text;
using Microsoft.WSL.Containers;

if (WslcService.GetMissingComponents() != ComponentFlags.None)
{
    Console.WriteLine("Missing WSL components: run wsl --install");
    return;
}

var session = new Session(new SessionSettings("MyApp", @"C:\WslcData")
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

// Cleanup
container.Stop(Signal.SIGTERM, TimeSpan.FromSeconds(10));
container.Delete(DeleteContainerFlags.None);
session.Terminate();
```

Source: [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container). Full samples: [aka.ms/wslc-samples](https://aka.ms/wslc-samples).

## Key takeaways

- `wslc` = native WSL containers, with no third-party product, still in preview.
- Docker Desktop remains more complete (Compose, Kubernetes, GUI).
- The `Microsoft.WSL.Containers` API opens up a use case Docker Desktop doesn't cover directly: Windows applications that embed Linux containers.

## Exercise

Pick a service you currently run with Docker (for example `qdrant` or `mongodb`) and run it with `wslc`. Note in the [journal](../journal/) what differs.

<details>
<summary>Hint</summary>

```powershell
wslc run -d --rm -p 6333:6333 --name qdrant qdrant/qdrant
curl localhost:6333
wslc container stop qdrant
```

Things to observe: is the image downloaded again? Does the port conflict with the existing Docker container? How much memory does the VM use?

</details>
