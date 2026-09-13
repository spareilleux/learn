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
- decide when to use `wslc` rather than Docker Desktop.

## Prerequisites

- Windows 11 with WSL 2 installed.
- Basic container concepts (image, container, port) — lesson 1 reviews them.
- A PowerShell terminal; administrator access to update WSL.

## Outline

1. [Concepts](01-concepts/) — containers, WSL 2, and where `wslc` fits.
2. [Installation](02-installation/) — switch to pre-release, verify, troubleshoot.
3. [First containers](03-first-containers/) — `run`, ports, `exec`, `stop`.
4. [Building an image](04-build-an-image/) — a C# API and a Spring Boot WebFlux API: multi-stage `Containerfile`, `build`, logs, cleanup.
5. [wslc or Docker Desktop?](05-wslc-vs-docker/) — comparison and API for Windows applications.
6. [Journal](journal/) — my attempts, errors and items to verify.

## Resources

- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container): overview, CLI and API.
- [Get started with containers on WSL — Microsoft Learn](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers): official tutorial.
- [WSL container is now available for public preview — Windows Command Line blog](https://devblogs.microsoft.com/commandline/wsl-container-is-now-available-for-public-preview/): announcement.
- [WSL release notes — GitHub](https://github.com/microsoft/WSL/releases): stable and pre-release versions.
- [WSL container API reference](https://wsl.dev/api-reference/) and [samples](https://aka.ms/wslc-samples).
