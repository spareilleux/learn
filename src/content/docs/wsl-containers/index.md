---
title: WSL containers — Mission
description: Learn to run Linux containers on Windows with wslc.exe, built into WSL.
sidebar:
  label: Mission
  order: 0
---

:::caution[Preview]
WSL containers is in **public preview** (announced at Microsoft Build 2026, available since June 30, 2026).
This course studies **WSL 2.9.11** (pre-release channel). Commands may change before the stable release, expected in fall 2026.
:::

## Why I'm learning this

I use Docker Desktop **and** Podman on the same Windows machine, each with its own WSL VM.
Microsoft now builds a container tool directly into WSL: `wslc.exe`.
I want to know whether it can replace — or complement — Docker Desktop for my daily use, and how to use it from my own applications.

## By the end of this course, I will be able to

- explain what WSL containers is and how it relates to WSL 2 and Docker Desktop;
- install the right version of WSL and diagnose a failed installation;
- run, inspect, publish and stop containers with `wslc`;
- build an image from a `Containerfile`;
- run `wslc` next to Docker Desktop without image, version or port surprises;
- limit the CPU and memory of a session or a container, measure its VM from Windows and reclaim its disk space;
- keep a service's data in a named volume, and know when a Windows folder is the wrong place;
- reproduce a small Compose stack with a network, volumes and DNS names;
- drive containers from a C# program with `Microsoft.WSL.Containers`, including an image built by `dotnet build`;
- explain what `wslc` 2.9.11 doesn't do: Compose, Kubernetes, privileged containers, extensions, a graphical interface;
- decide when to use `wslc` rather than Docker Desktop.

## Prerequisites

- Windows 11 with WSL 2 installed.
- Basic container concepts (image, container, port) — lesson 1 reviews them.
- A PowerShell terminal; administrator access to update WSL.
- For lesson 9, the [.NET SDK](https://dotnet.microsoft.com/download) 10.

WSL containers only exist on Windows, so this course has no Linux or macOS variants: every command is for PowerShell on Windows 11.

## Outline

1. [Concepts](01-concepts/) — containers, WSL 2, and where `wslc` fits.
2. [Installation](02-installation/) — switch to pre-release, verify, troubleshoot.
3. [First containers](03-first-containers/) — `run`, ports, `exec`, `stop`.
4. [Building an image](04-build-an-image/) — a C# API and a Spring Boot WebFlux API: multi-stage `Containerfile`, `build`, logs, cleanup.
5. [wslc or Docker Desktop?](05-wslc-vs-docker/) — comparison, separate image stores, the same port published twice without an error.
6. [Resources and limits](06-resources-and-limits/) — `settings.yaml`, per-container limits, the session VM seen from Windows, compacting `storage.vhdx`.
7. [Volumes and a real service](07-volumes-and-a-real-service/) — qdrant next to a Docker copy: ports, pinned versions, named volumes, bind mounts.
8. [Compose without Compose](08-compose/) — what Compose really does, DNS names on a network, a PowerShell translation, health checks.
9. [Driving containers from C#](09-csharp-api/) — `Microsoft.WSL.Containers`: a project that compiles, sessions, cleanup, `WslcImage` and `LoadImageAsync`.
10. [Networking, Kubernetes and GUI](10-networking-kubernetes-gui/) — published addresses, networks per session, API containers without a network, k3s and `Privileged`, what's missing.
11. [Journal](journal/) — my attempts, errors and items to verify.

## Resources

- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container): overview, CLI and API.
- [Get started with containers on WSL — Microsoft Learn](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers): official tutorial.
- [WSL container is now available for public preview — Windows Command Line blog](https://devblogs.microsoft.com/commandline/wsl-container-is-now-available-for-public-preview/): announcement.
- [WSL release notes — GitHub](https://github.com/microsoft/WSL/releases): stable and pre-release versions.
- [WSL container API reference](https://wsl.dev/api-reference/) and [samples](https://aka.ms/wslc-samples).
