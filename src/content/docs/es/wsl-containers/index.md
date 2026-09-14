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
- decidir cuándo usar `wslc` en lugar de Docker Desktop.

## Requisitos previos

- Windows 11 con WSL 2 instalado.
- Conceptos básicos de contenedores (imagen, contenedor, puerto): la lección 1 los repasa.
- Una terminal PowerShell; acceso de administrador para actualizar WSL.

## Plan

1. [Conceptos](01-concepts/) — los contenedores, WSL 2 y el lugar de `wslc`.
2. [Instalación](02-installation/) — pasar a pre-release, verificar, solucionar problemas.
3. [Primeros contenedores](03-first-containers/) — `run`, puertos, `exec`, `stop`.
4. [Construir una imagen](04-build-an-image/) — una API en C# y una API Spring Boot WebFlux: `Containerfile` multietapa, `build`, logs, limpieza.
5. [¿wslc o Docker Desktop?](05-wslc-vs-docker/) — comparación y API para aplicaciones Windows.
6. [Diario](journal/) — mis intentos, errores y puntos por verificar.

## Recursos

- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container): visión general, CLI y API.
- [Get started with containers on WSL — Microsoft Learn](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers): tutorial oficial.
- [WSL container is now available for public preview — blog Windows Command Line](https://devblogs.microsoft.com/commandline/wsl-container-is-now-available-for-public-preview/): anuncio.
- [Notas de versión de WSL — GitHub](https://github.com/microsoft/WSL/releases): versiones estables y pre-release.
- [Referencia de la API de WSL container](https://wsl.dev/api-reference/) y [ejemplos](https://aka.ms/wslc-samples).
