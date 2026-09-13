---
title: Journal
description: Dated progress notes — attempts, errors and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Understand what WSL containers is and which version it requires
- [x] Install WSL ≥ 2.9.3 (pre-release)
- [x] `wslc run --rm hello-world`
- [ ] Lesson 3: containers, ports, `exec`
- [ ] Lesson 4: building an image
- [ ] Run an existing service (qdrant) with `wslc`
- [ ] Test Compose
- [ ] Check whether Docker and `wslc` images are shared
- [ ] Small C# program with `Microsoft.WSL.Containers`

## 2026-09-12 — Taking stock

- Machine: Windows 11 Pro build 26200, WSL **2.6.3**.
- WSL distros already present: `docker-desktop` (Docker Desktop 4.61) and `podman-machine-default`.
- Latest WSL versions on GitHub: stable **2.7.14**, pre-release **2.9.11**. Only the pre-release includes `wslc`.

**Incident not directly related, but instructive:** Docker Desktop crashed three times within a few minutes ("wsl-bootstrap stopped with exit code 1, did wsl shutdown?"). At the same time, `wsl -l -v` failed with:

```text
Not enough memory resources are available to complete this operation.
Error code: Wsl/0x8007000e
```

Committed memory: 97 GB out of 132 GB. Hypothesis: too many VMs and heavy processes at the same time (Docker + Kubernetes, Podman, ollama, rust-analyzer…). Lead: limit WSL memory in `%UserProfile%\.wslconfig` (`memory=24GB`).

## 2026-09-13 — First update attempt: failure

```powershell
wsl --update --pre-release
# Updating Windows Subsystem for Linux to version: 2.9.11.
```

The command returned with no visible error, but `wsl --version` still showed **2.6.3**.

In the Windows log (`MsiInstaller`):

```text
Error 1921. Service 'WSL Service' (WSLService) could not be stopped.
Product: Windows Subsystem for Linux -- Installation failed.   (status 1603)
```

**Lesson:** don't rely on the absence of an error message; check the version afterwards. The WSL service was held by Docker Desktop, Podman and several `wsl.exe` processes.
Planned fix: stop everything, `wsl --shutdown`, `Stop-Service WSLService` as administrator, then rerun the update. → detailed in [lesson 2](../02-installation/).

## 2026-09-13 — Second attempt: WSL 2.9.11 installed

Applied the planned fix. From a normal (non-elevated) terminal:

```powershell
docker desktop stop
podman machine stop
wsl --shutdown
wsl -l -v   # podman-machine-default and docker-desktop: Stopped
```

Then, in an **administrator** PowerShell:

```powershell
wsl --shutdown
Get-Process wsl, wslhost, wslrelay -ErrorAction SilentlyContinue | Stop-Process -Force
Stop-Service WSLService -Force
wsl --update --pre-release
wsl --version
```

```text
WSLService: Stopped
Updating Windows Subsystem for Linux to version: 2.9.11.
WSL version: 2.9.11.0
Kernel version: 6.18.40.1-1
WSLg version: 1.0.79
```

This time the service really was stopped before the installer ran, and the version changed. `wslc.exe` is installed in `C:\Program Files\WSL\`, which is already on the machine `PATH` — but terminals opened before the update don't see it: open a new one (or call the full path).

```powershell
wslc --version   # wslc 2.9.11.0
wslc run --rm hello-world
```

```text
Image 'hello-world' not found, pulling
latest: Pulling from library/hello-world
...
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.
```

**Don't be fooled:** "Hello from Docker!" is just the text baked into the `hello-world` image. Docker Desktop was stopped the whole time; the container ran under `wslc`.

`wslc info` shows a settings file at `%LocalAppData%\wslc\settings.yaml` and a session named `wslc-cli-<user>`. `wslc images` lists only `hello-world` (10.1 kB).

**Still to do:** restart Docker Desktop and Podman and check that Docker Desktop 4.61 still works with WSL 2.9.11 (*to verify*).

## Open questions

- Where does `wslc` store its images and containers?
- Can the memory and CPU of the VM used by `wslc` be limited?
- Can `wslc` and Docker Desktop publish ports without conflict?
