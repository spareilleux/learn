---
title: Journal
description: Dated progress notes — attempts, errors and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Understand what WSL containers is and which version it requires
- [ ] Install WSL ≥ 2.9.3 (pre-release)
- [ ] `wslc run --rm hello-world`
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

## Open questions

- Where does `wslc` store its images and containers?
- Can the memory and CPU of the VM used by `wslc` be limited?
- Can `wslc` and Docker Desktop publish ports without conflict?
