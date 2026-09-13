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
| Ecosystem (Compose, Kubernetes, extensions, GUI) | no `compose` command in 2.9.11; Kubernetes, extensions, GUI *to verify* | complete |

:::note[Verified: no Compose in `wslc` 2.9.11]
`wslc compose` → `Unrecognized command: 'compose'`, and the session's Docker engine can't be reached by `docker compose`. A small stack can be reproduced with a script (`network create`, `volume create`, `run --network --network-alias`); the tested translation of a `compose.yaml` is in the [journal](../journal/).
:::

:::note[Verified: images are not shared]
After `docker pull busybox`, `wslc image list` doesn't show it: each tool has its own store (`docker_data.vhdx` for Docker, one `storage.vhdx` per `wslc` session). An image used by both is downloaded twice, and the same `latest` tag can even point to two different versions (qdrant 1.16.3 in Docker, 1.19.1 in `wslc`). Details in the [journal](../journal/).
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

The [`Microsoft.WSL.Containers`](https://www.nuget.org/packages/Microsoft.WSL.Containers) package 2.9.9 is a [C#/WinRT](https://learn.microsoft.com/windows/apps/develop/platform/csharp-winrt/) projection compiled against the Windows 10.0.26100 SDK, with a native DLL for x64 and arm64 only. The project must say so, otherwise the build fails with `CS1705`:

```xml
<PropertyGroup>
  <OutputType>Exe</OutputType>
  <TargetFramework>net10.0-windows10.0.26100.0</TargetFramework>
  <WindowsSdkPackageVersion>10.0.26100.80</WindowsSdkPackageVersion>
  <RuntimeIdentifier>win-x64</RuntimeIdentifier>
</PropertyGroup>
<ItemGroup>
  <PackageReference Include="Microsoft.WSL.Containers" Version="2.9.9" />
</ItemGroup>
```

```csharp
using System.Text;
using Microsoft.WSL.Containers;

var missing = WslcService.GetMissingComponents();
if (missing.Count > 0)
{
    Console.WriteLine($"Missing WSL components: {string.Join(", ", missing)} (run wsl --install)");
    return 1;
}
var version = WslcService.GetVersion();
Console.WriteLine($"WSL container service {version.Major}.{version.Minor}.{version.Revision}");

// The session keeps its images and containers in its own storage.vhdx.
var storage = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "WslcHost");
using var session = new Session(new SessionSettings("wslc-host", storage)
{
    CpuCount = 2,
    MemorySizeInMB = 2048
});
session.Start();
Console.WriteLine($"Session started, storage in {storage}");

await session.PullImageAsync(new PullImageOptions("docker.io/library/alpine:latest"));
foreach (var image in session.GetImages())
    Console.WriteLine($"Image {image.Name} ({image.Size / 1024 / 1024} MB)");

using var container = session.CreateContainer(new ContainerSettings("alpine:latest")
{
    Name = "wslc-host-hello",
    InitProcess = new ProcessSettings
    {
        CommandLine = ["/bin/sh", "-c", "echo Hello from $(cat /etc/alpine-release) on $(uname -r)"],
        OutputMode = ProcessOutputMode.Event
    }
});

try
{
    var exited = new TaskCompletionSource<int>();
    container.InitProcess.OutputReceived += data => Console.Write(Encoding.UTF8.GetString(data));
    container.InitProcess.Exited += code => exited.TrySetResult(code);
    container.Start();

    var exitCode = await exited.Task.WaitAsync(TimeSpan.FromMinutes(2));
    Console.WriteLine($"Container {container.Id[..12]} exited with code {exitCode}");
    return exitCode;
}
finally
{
    // Without this, a failed Start leaves the container in storage.vhdx and blocks its name.
    container.Delete(DeleteContainerOption.Force);
    session.Terminate();
}
```

```text
WSL container service 2.9.11
Session started, storage in C:\Users\spare\AppData\Local\WslcHost
Image alpine:latest (8 MB)
Hello from 3.24.1 on 6.18.40.1-microsoft-standard-WSL2
Container 2b900903f6c8 exited with code 0
```

The full program, which also removes a container left by a crashed run, is in [`code/wsl-containers/wslc-host`](https://github.com/spareilleux/learn/tree/main/code/wsl-containers/wslc-host).

:::caution[The Microsoft Learn snippets don't compile against 2.9.9]
The page uses `ComponentFlags`, `MemoryMB`, `CmdLine` and `DeleteContainerFlags`. In package 2.9.9 they are `IReadOnlyList<Component>`, `MemorySizeInMB`, `CommandLine` and `DeleteContainerOption`. Details in the [journal](../journal/).
:::

Sources: [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container), [API reference](https://wsl.dev/api-reference/). Full samples: [aka.ms/wslc-samples](https://aka.ms/wslc-samples).

## Key takeaways

- `wslc` = native WSL containers, with no third-party product, still in preview.
- Docker Desktop remains more complete (Compose, Kubernetes, GUI).
- The `Microsoft.WSL.Containers` API opens up a use case Docker Desktop doesn't cover directly: Windows applications that embed Linux containers.

## Exercise

Pick a service you currently run with Docker (for example [qdrant](https://qdrant.tech/) or [MongoDB](https://www.mongodb.com/)) and run it with `wslc`. Note in the [journal](../journal/) what differs.

<details>
<summary>Hint</summary>

If Docker already publishes qdrant on 6333, pick **another Windows port**: `wslc` would bind 6333 without any error and silently take `127.0.0.1:6333` away from the Docker container.

```powershell
wslc volume create qdrant-data
wslc run -d --name qdrant -p 16333:6333 -v qdrant-data:/qdrant/storage qdrant/qdrant
curl.exe http://127.0.0.1:16333/
wslc container stop qdrant
```

Things to observe: is the image downloaded again? Is it the same version as Docker's `latest`? How much memory does the VM use? What does qdrant log if you mount a Windows folder instead of a volume? Answers in the [journal](../journal/).

</details>
