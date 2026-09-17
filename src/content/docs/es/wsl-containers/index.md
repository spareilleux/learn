---
title: WSL containers — Misión
description: Aprender a ejecutar contenedores Linux en Windows con wslc.exe, integrado en WSL.
sidebar:
  label: Misión
  order: 0
---

:::caution[Versión preliminar]
WSL containers está en **versión preliminar pública** (anunciada en Microsoft Build 2026, disponible desde el 30 de junio de 2026).
Este curso estudia **WSL 2.9.11** (canal pre-release). Los comandos pueden cambiar antes de la versión estable, prevista para el otoño de 2026.
:::

## Por qué aprendo esto

Uso Docker Desktop **y** Podman en la misma máquina Windows, cada uno con su propia VM de WSL.
Microsoft integra ahora una herramienta de contenedores directamente en WSL: `wslc.exe`.
Quiero saber si puede reemplazar —o complementar— a Docker Desktop en mi uso diario, y cómo usarla desde mis propias aplicaciones.

## Al final de este curso, sabré

- explicar qué es WSL containers y cómo se relaciona con WSL 2 y Docker Desktop;
- instalar la versión correcta de WSL y diagnosticar una instalación fallida;
- ejecutar, inspeccionar, publicar y detener contenedores con `wslc`;
- construir una imagen a partir de un `Containerfile`;
- usar `wslc` junto a Docker Desktop sin sorpresas de imágenes, versiones ni puertos;
- limitar la CPU y la memoria de una sesión o de un contenedor, medir su VM desde Windows y recuperar su espacio en disco;
- guardar los datos de un servicio en un volumen con nombre, y saber cuándo una carpeta de Windows es el lugar equivocado;
- reproducir una pequeña pila Compose con una red, volúmenes y nombres DNS;
- controlar contenedores desde un programa C# con `Microsoft.WSL.Containers`, incluida una imagen construida por `dotnet build`;
- explicar lo que `wslc` 2.9.11 no hace: Compose, Kubernetes, contenedores privilegiados, extensiones, una interfaz gráfica;
- decidir cuándo usar `wslc` en lugar de Docker Desktop.

## Requisitos previos

- Windows 11 con WSL 2 instalado.
- Conceptos básicos de contenedores (imagen, contenedor, puerto): la lección 1 los repasa.
- Una terminal PowerShell; acceso de administrador para actualizar WSL.
- Para la lección 9, el [SDK de .NET](https://dotnet.microsoft.com/download) 10.

WSL containers solo existe en Windows, así que este curso no tiene variantes para Linux ni macOS: todos los comandos son para PowerShell en Windows 11.

## Plan

1. [Conceptos](01-concepts/) — los contenedores, WSL 2 y el lugar de `wslc`.
2. [Instalación](02-installation/) — pasar a pre-release, verificar, solucionar problemas.
3. [Primeros contenedores](03-first-containers/) — `run`, puertos, `exec`, `stop`.
4. [Construir una imagen](04-build-an-image/) — una API en C# y una API Spring Boot WebFlux: `Containerfile` multietapa, `build`, logs, limpieza.
5. [¿wslc o Docker Desktop?](05-wslc-vs-docker/) — comparación, almacenes de imágenes separados, el mismo puerto publicado dos veces sin error.
6. [Recursos y límites](06-resources-and-limits/) — `settings.yaml`, límites por contenedor, la VM de la sesión vista desde Windows, compactar `storage.vhdx`.
7. [Volúmenes y un servicio real](07-volumes-and-a-real-service/) — qdrant junto a una copia en Docker: puertos, versiones fijadas, volúmenes con nombre, montajes de carpetas.
8. [Compose sin Compose](08-compose/) — lo que Compose hace realmente, nombres DNS en una red, una traducción a PowerShell, comprobaciones de estado.
9. [Controlar contenedores desde C#](09-csharp-api/) — `Microsoft.WSL.Containers`: un proyecto que compila, sesiones, limpieza, `WslcImage` y `LoadImageAsync`.
10. [Redes, Kubernetes e interfaz gráfica](10-networking-kubernetes-gui/) — direcciones publicadas, redes por sesión, contenedores de la API sin red, k3s y `Privileged`, lo que falta.
11. [Diario](journal/) — mis intentos, errores y puntos por verificar.

## Recursos

- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container): visión general, CLI y API.
- [Get started with containers on WSL — Microsoft Learn](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers): tutorial oficial.
- [WSL container is now available for public preview — blog Windows Command Line](https://devblogs.microsoft.com/commandline/wsl-container-is-now-available-for-public-preview/): anuncio.
- [Notas de versión de WSL — GitHub](https://github.com/microsoft/WSL/releases): versiones estables y pre-release.
- [Referencia de la API de WSL container](https://wsl.dev/api-reference/) y [ejemplos](https://aka.ms/wslc-samples).
