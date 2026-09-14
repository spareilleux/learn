---
title: 5. ¿wslc o Docker Desktop?
description: Comparar wslc y Docker Desktop, y usar la API de WSL container desde una aplicación Windows.
sidebar:
  order: 5
---

## Comparación

| Criterio | `wslc` (WSL containers) | Docker Desktop |
|---|---|---|
| Instalación | incluido en WSL ≥ 2.9.3 | producto independiente |
| Madurez (sept. de 2026) | versión preliminar pública | estable |
| CLI | cercana a Docker | `docker` |
| API para aplicaciones Windows | sí — NuGet `Microsoft.WSL.Containers` | Docker Engine API (HTTP) |
| Gestión empresarial | Microsoft Defender for Endpoint, Intune | Docker Business |
| Ecosistema (Compose, Kubernetes, extensiones, GUI) | ningún comando `compose` en la 2.9.11; Kubernetes, extensiones, GUI *por verificar* | completo |

:::note[Verificado: no hay Compose en `wslc` 2.9.11]
`wslc compose` → `Unrecognized command: 'compose'`, y `docker compose` no puede alcanzar el motor Docker de la sesión. Una pequeña stack se puede reproducir con un script (`network create`, `volume create`, `run --network --network-alias`); la traducción probada de un `compose.yaml` está en el [diario](../journal/).
:::

:::note[Verificado: las imágenes no se comparten]
Tras `docker pull busybox`, `wslc image list` no la muestra: cada herramienta tiene su propio almacén (`docker_data.vhdx` para Docker, un `storage.vhdx` por sesión de `wslc`). Una imagen que usan las dos se descarga dos veces, y la misma etiqueta `latest` puede incluso apuntar a dos versiones distintas (qdrant 1.16.3 en Docker, 1.19.1 en `wslc`). Detalles en el [diario](../journal/).
:::

## Cuándo elegir qué

- **`wslc`**: necesidades sencillas (ejecutar una base de datos, un servicio, una herramienta), el deseo de no depender de Docker Desktop, o una aplicación Windows que necesita controlar contenedores.
- **Docker Desktop**: proyectos basados en Docker Compose, Kubernetes local, un equipo ya equipado en torno a Docker.
- **Los dos**: es posible, pero cada herramienta mantiene su propia VM y su propia memoria. En una máquina muy cargada, es un coste real (ver el [diario](../journal/)).

## La API de WSL container

Una aplicación Windows puede crear sus propios contenedores Linux. Los objetos siguen el ciclo de vida:

| Objeto | Función |
|---|---|
| `WslcService` | comprobar que los componentes de WSL están instalados, versión del servicio |
| `Session` | host WSL que gestiona las imágenes y crea los contenedores |
| `Container` | iniciar, detener, inspeccionar, eliminar; lanzar procesos |
| `Process` | leer `stdout`/`stderr`, escribir en `stdin`, enviar señales |

El paquete [`Microsoft.WSL.Containers`](https://www.nuget.org/packages/Microsoft.WSL.Containers) 2.9.9 es una proyección [C#/WinRT](https://learn.microsoft.com/windows/apps/develop/platform/csharp-winrt/) compilada con el SDK de Windows 10.0.26100, con una DLL nativa solo para x64 y arm64. El proyecto debe indicarlo; si no, el build falla con `CS1705`:

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

// La sesión guarda sus imágenes y contenedores en su propio storage.vhdx.
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
    // Sin esto, un Start fallido deja el contenedor en storage.vhdx y bloquea su nombre.
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

El programa completo, que también elimina un contenedor dejado por una ejecución que falló, está en [`code/wsl-containers/wslc-host`](https://github.com/spareilleux/learn/tree/main/code/wsl-containers/wslc-host).

:::caution[Los extractos de Microsoft Learn no compilan con la 2.9.9]
La página usa `ComponentFlags`, `MemoryMB`, `CmdLine` y `DeleteContainerFlags`. En el paquete 2.9.9 son `IReadOnlyList<Component>`, `MemorySizeInMB`, `CommandLine` y `DeleteContainerOption`. Detalles en el [diario](../journal/).
:::

Fuentes: [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container), [referencia de la API](https://wsl.dev/api-reference/). Ejemplos completos: [aka.ms/wslc-samples](https://aka.ms/wslc-samples).

## Puntos clave

- `wslc` = contenedores nativos de WSL, sin producto de terceros, todavía en versión preliminar.
- Docker Desktop sigue siendo más completo (Compose, Kubernetes, GUI).
- La API `Microsoft.WSL.Containers` abre un caso de uso que Docker Desktop no cubre directamente: aplicaciones Windows que integran contenedores Linux.

## Ejercicio

Elige un servicio que ejecutes actualmente con Docker (por ejemplo [qdrant](https://qdrant.tech/) o [MongoDB](https://www.mongodb.com/)) y ejecútalo con `wslc`. Anota en el [diario](../journal/) lo que cambia.

<details>
<summary>Pista</summary>

Si Docker ya publica qdrant en el 6333, elige **otro puerto de Windows**: `wslc` se enlazaría al 6333 sin ningún error y le quitaría en silencio `127.0.0.1:6333` al contenedor de Docker.

```powershell
wslc volume create qdrant-data
wslc run -d --name qdrant -p 16333:6333 -v qdrant-data:/qdrant/storage qdrant/qdrant
curl.exe http://127.0.0.1:16333/
wslc container stop qdrant
```

Cosas que observar: ¿se vuelve a descargar la imagen? ¿Es la misma versión que el `latest` de Docker? ¿Cuánta memoria usa la VM? ¿Qué registra qdrant en los logs si montas una carpeta de Windows en lugar de un volumen? Respuestas en el [diario](../journal/).

</details>
