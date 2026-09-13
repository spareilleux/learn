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

## 2026-09-13 — Reproducing hello-world by hand: two traps

### Trap 1: `wslc` "not recognized" in a new tab

```text
PS C:\Users\spare\source\repos> Get-Command wslc
Get-Command : The term 'wslc' is not recognized as the name of a cmdlet, function, script file, or operable program.
```

`wslc.exe` was installed and `C:\Program Files\WSL\` was on the machine `PATH`, but a program receives a *copy* of the environment variables when it starts. Windows Terminal had been running since 2026-09-11, before the update, and the new tab inherited its old `PATH`.

Fixes, from quickest to most durable:

```powershell
# Reload PATH in the current PowerShell (this terminal only)
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
```

- or call the full path: `& "C:\Program Files\WSL\wslc.exe" --version`;
- or close **every** Windows Terminal window (no `WindowsTerminal.exe` left) and restart it, or start a terminal from `Win + R`.

In `cmd.exe`, the equivalent of `Get-Command` is `where wslc`.

### Trap 2: an administrator terminal doesn't see the same images

In a fresh `cmd.exe` (opened in `C:\Windows\System32`, a sign of an elevated terminal), `wslc run --rm hello-world` downloaded the image **again**, even though it had already been pulled from a non-elevated terminal:

```text
Image 'hello-world' not found, pulling
```

`wslc info` explains why:

```text
Sessions: 2
ID   Creator PID   Display Name
1    144356        wslc-cli-spare
2    394856        wslc-cli-admin-spare
```

`wslc` creates one session per user **and per privilege level**: `wslc-cli-<user>` without elevation, `wslc-cli-admin-<user>` as administrator. The image pulled in one session was not found in the other.

**Lesson:** `wslc` does not need elevation. Always use a non-elevated terminal, otherwise images and containers end up in a separate session.

### Verification: what is separated, and who can see what

Non-elevated terminal: create a volume and a network, then delete the image.

```powershell
wslc volume create sesstest-vol
wslc network create sesstest-net
wslc image remove hello-world
wslc images    # empty
```

Administrator terminal:

```text
> wslc image list
hello-world   latest   e2ac70e7319a   5 months ago   10.1kB
> wslc volume list
DRIVER   VOLUME NAME
> wslc network list
d9c6879f7df3   bridge    bridge    local
0dd65e6d15ec   host      host      local
34ad73ecd806   none      null      local
```

- The image deleted in the non-elevated session **is still there** in the admin session.
- The volume and network created in the non-elevated session **don't appear** in the admin session. Even the default `bridge`/`host`/`none` networks have different IDs: each session runs its own engine.

The global option `--session` goes **before** the subcommand (`wslc --session <name> image list`; after it: `Option name was not recognized`). Access is asymmetric:

```text
# non-elevated → admin session
> wslc --session wslc-cli-admin-spare image list
The requested operation requires elevation.
Error code: ERROR_ELEVATION_REQUIRED

# administrator → non-elevated session: works
> wslc --session wslc-cli-spare volume list
DRIVER   VOLUME NAME
guest    sesstest-vol
```

On disk, each session has its own virtual disks:

```text
%LocalAppData%\wslc\sessions\wslc-cli-spare\storage.vhdx         ~587 MB
%LocalAppData%\wslc\sessions\wslc-cli-spare\swap.vhdx            36 MB
%LocalAppData%\wslc\sessions\wslc-cli-admin-spare\storage.vhdx   ~577 MB
%LocalAppData%\wslc\sessions\wslc-cli-admin-spare\swap.vhdx      36 MB
```

Cleanup: `wslc volume remove sesstest-vol`, `wslc network remove sesstest-net`.

## 2026-09-13 — Limiting the CPU and memory of a `wslc` session

`wslc settings` creates `%LocalAppData%\wslc\settings.yaml` on first run (with every setting commented out) and opens it in the default editor. The relevant part:

```yaml
session:
  # Number of virtual CPUs allocated to the session (e.g. 4 default: all available CPUs)
  # cpuCount: default

  # Memory limit for the session (e.g. 2GB default: half of available memory)
  # memorySize: default
```

The same file also has `maxStorageSize` (default 1 TB), `storagePath` (where `wslc\sessions\<session>\storage.vhdx` is created), `defaultBindingAddress` (default `127.0.0.1` for `-p`), `hostLoopback` (`host.wslc.internal`) and `idleTimeout` (30 s). Source: the generated file, <https://aka.ms/wslc-settings>. The API equivalent is `SessionSettings.CpuCount` / `MemoryMB` ([Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container)).

**Measurement.** Host: 24 logical CPUs, 63.7 GB of RAM.

```powershell
wslc run --rm alpine sh -c "echo nproc=`$(nproc); free -m"
```

| Settings | `nproc` | RAM (`free -m`) | Swap |
|---|---|---|---|
| defaults | 24 | 31946 MB | 32617 MB |
| `cpuCount: 4`, `memorySize: 4GB` | 4 | 3919 MB | 4096 MB |

Swap follows `memorySize`.

**Trap: the change is not applied to a running session.** The first measurement after editing the file still showed 24 CPUs. The session has to be terminated; the next `wslc` command starts a new one with the new settings:

```powershell
wslc --session wslc-cli-spare system session terminate
```

(`wslc system session terminate wslc-cli-spare`, with the name as an argument, fails: `Found a positional argument when none was expected`.)

After the test, the settings were set back to `default`: 4 GB is too tight for the rest of the course (qdrant).

*To verify:* whether the admin session (`wslc-cli-admin-<user>`) reads the same `settings.yaml`, and how much memory the VM really takes on the Windows side (Task Manager, `vmmem`).

## Open questions

- ~~Where does `wslc` store its images and containers?~~ In `%LocalAppData%\wslc\sessions\<session>\storage.vhdx`, one virtual disk per session (see above). ~580 MB for a session holding almost nothing: *to verify* whether this file grows with images and shrinks after `prune`.
- ~~Can the memory and CPU of the VM used by `wslc` be limited?~~ Yes: `cpuCount` and `memorySize` in `settings.yaml`, then terminate the session (see above).
- Can `wslc` and Docker Desktop publish ports without conflict?
