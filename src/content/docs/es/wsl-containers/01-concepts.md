---
title: 1. Conceptos
description: Los contenedores, WSL 2 y el lugar de wslc.exe.
sidebar:
  order: 1
---

## Un contenedor, en una frase

Un **contenedor** empaqueta una aplicación con todo lo que necesita (bibliotecas, runtime, configuración) para que se ejecute de la misma manera en todas partes.
Se inicia a partir de una **imagen**, una plantilla de solo lectura que descargas de un registro ([Docker Hub](https://hub.docker.com/), por ejemplo) o que construyes tú mismo.

| Término | Analogía | Ejemplo |
|---|---|---|
| Imagen | Una receta fija | `nginx`, `ubuntu:latest` |
| Contenedor | Un plato preparado a partir de la receta | el servidor `web` iniciado a partir de `nginx` |
| Registro | La biblioteca de recetas | `docker.io` |
| Puerto publicado | La ventanilla entre Windows y el contenedor | `-p 8080:80` |

## Por qué hace falta Linux

Los contenedores Linux comparten el **kernel Linux** de la máquina anfitriona. Windows no tiene uno, así que hace falta una máquina virtual Linux en algún lugar.
Eso es exactamente lo que proporciona **[WSL 2](https://learn.microsoft.com/windows/wsl/about)**: una VM ligera, gestionada por Windows, con un verdadero kernel Linux.

## Tres formas de tener contenedores Linux en Windows

| Enfoque | Quién gestiona la VM Linux | Herramienta |
|---|---|---|
| [Docker Desktop](https://docs.docker.com/desktop/) | Docker, mediante su propia distro WSL `docker-desktop` | `docker` |
| [Podman](https://podman.io/) | Podman, mediante su distro WSL `podman-machine-default` | `podman` |
| **WSL containers** | **WSL mismo**, sin producto de terceros | `wslc` |

La novedad: con WSL containers, **el motor de contenedores forma parte de WSL**. No hay nada más que instalar, y `wslc.exe` viene con WSL.

## Los dos componentes

1. **La CLI `wslc.exe`** — para construir, ejecutar e inspeccionar contenedores desde una terminal. Sigue las convenciones de la CLI de Docker.
2. **La API de WSL container** — un paquete NuGet ([`Microsoft.WSL.Containers`](https://www.nuget.org/packages/Microsoft.WSL.Containers)) que permite a una **aplicación Windows** usar contenedores Linux en su propia lógica (C#, y C++/WinRT en versión preliminar).

## Puntos clave

- Imagen = plantilla; contenedor = instancia en ejecución.
- Los contenedores Linux necesitan un kernel Linux → WSL 2 lo proporciona.
- `wslc` = contenedores integrados en WSL, sin Docker Desktop.

## Ejercicios

1. Lista las distribuciones WSL de tu máquina. ¿Cuáles pertenecen a una herramienta de contenedores?

<details>
<summary>Solución</summary>

```powershell
wsl -l -v
```

```text
  NAME                      STATE           VERSION
* podman-machine-default    Stopped         2
  Ubuntu                    Stopped         2
  docker-desktop            Stopped         2
```

En mi máquina: `docker-desktop` (Docker Desktop) y `podman-machine-default` (Podman). Son distros «técnicas» gestionadas por esas herramientas, no distros pensadas para usarse directamente; `Ubuntu` es una distro normal. `wslc` no añade ninguna: sus sesiones no aparecen en `wsl -l -v`.

</details>

2. ¿Por qué no puedes ejecutar una imagen `ubuntu` directamente sobre el kernel de Windows?

<details>
<summary>Solución</summary>

Una imagen Linux contiene binarios que hacen llamadas al sistema **Linux**. Un contenedor no virtualiza el kernel: comparte el del anfitrión. Así que hace falta un kernel Linux, proporcionado aquí por la VM de WSL 2.

</details>

## Fuentes

- [¿Qué es WSL? — Microsoft Learn](https://learn.microsoft.com/windows/wsl/about)
- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container)
