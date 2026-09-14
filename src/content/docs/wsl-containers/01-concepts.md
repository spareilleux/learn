---
title: 1. Concepts
description: Containers, WSL 2 and where wslc.exe fits.
sidebar:
  order: 1
---

## A container, in one sentence

A **container** packages an application with everything it needs (libraries, runtime, configuration) so that it runs the same way everywhere.
You start it from an **image**, a read-only template that you download from a registry ([Docker Hub](https://hub.docker.com/), for example) or build yourself.

| Term | Analogy | Example |
|---|---|---|
| Image | A fixed recipe | `nginx`, `ubuntu:latest` |
| Container | A dish prepared from the recipe | the `web` server started from `nginx` |
| Registry | The recipe library | `docker.io` |
| Published port | The counter between Windows and the container | `-p 8080:80` |

## Why you need Linux

Linux containers share the host machine's **Linux kernel**. Windows doesn't have one, so you need a Linux virtual machine somewhere.
That is exactly what **[WSL 2](https://learn.microsoft.com/windows/wsl/about)** provides: a lightweight VM, managed by Windows, with a real Linux kernel.

## Three ways to get Linux containers on Windows

| Approach | Who manages the Linux VM | Tool |
|---|---|---|
| [Docker Desktop](https://docs.docker.com/desktop/) | Docker, via its own WSL distro `docker-desktop` | `docker` |
| [Podman](https://podman.io/) | Podman, via its WSL distro `podman-machine-default` | `podman` |
| **WSL containers** | **WSL itself**, with no third-party product | `wslc` |

What's new: with WSL containers, **the container engine is part of WSL**. There is nothing else to install, and `wslc.exe` ships with WSL.

## The two components

1. **The `wslc.exe` CLI** — to build, run and inspect containers from a terminal. It follows the conventions of the Docker CLI.
2. **The WSL container API** — a NuGet package ([`Microsoft.WSL.Containers`](https://www.nuget.org/packages/Microsoft.WSL.Containers)) that lets a **Windows application** use Linux containers in its own logic (C#, and C++/WinRT in preview).

## Key takeaways

- Image = template; container = running instance.
- Linux containers need a Linux kernel → WSL 2 provides it.
- `wslc` = containers built into WSL, without Docker Desktop.

## Exercises

1. List the WSL distributions on your machine. Which ones belong to a container tool?

<details>
<summary>Solution</summary>

```powershell
wsl -l -v
```

```text
  NAME                      STATE           VERSION
* podman-machine-default    Stopped         2
  Ubuntu                    Stopped         2
  docker-desktop            Stopped         2
```

On my machine: `docker-desktop` (Docker Desktop) and `podman-machine-default` (Podman). These are "technical" distros managed by those tools, not distros meant to be used directly; `Ubuntu` is a regular distro. `wslc` adds none: its sessions don't appear in `wsl -l -v`.

</details>

2. Why can't you run an `ubuntu` image directly on the Windows kernel?

<details>
<summary>Solution</summary>

A Linux image contains binaries that make **Linux** system calls. A container doesn't virtualize the kernel: it shares the host's. So you need a Linux kernel, provided here by the WSL 2 VM.

</details>

## Sources

- [What is WSL? — Microsoft Learn](https://learn.microsoft.com/windows/wsl/about)
- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container)
