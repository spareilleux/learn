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
- [x] Lesson 3: containers, ports, `exec`
- [x] Lesson 4: building an image
- [x] Run an existing service (qdrant) with `wslc`
- [x] Test Compose
- [x] Check whether Docker and `wslc` images are shared
- [x] Small C# program with `Microsoft.WSL.Containers`
- [x] Go further: `WslcImage`, API networking, Kubernetes, extensions, GUI
- [x] Lot 2: lessons 6 to 10 written from the entries below, lessons 1 to 5 extended

## QA

`wslc`, its C# SDK and Docker Desktop are all somebody else's software, and `wslc` is new enough that most of what follows is about the tool rather than about containers. Two rows are documentation that does not match the build shipped. None of it has been reported upstream.

| Expected | What happens | Where | Measure | Status |
|---|---|---|---|---|
| Microsoft Learn's `Microsoft.WSL.Containers` snippet compiles against the package | Five compiler errors: `ComponentFlags`, `SessionSettings.MemoryMB`, `ProcessSettings.CmdLine` and `DeleteContainerFlags` do not exist. The package calls them `IReadOnlyList<Component>`, `MemorySizeInMB`, `CommandLine` and `DeleteContainerOption` | `Microsoft.WSL.Containers` 2.9.9 | Five name pairs, documentation against package | Reproduced, not reported [2026-09-13](#2026-09-13--a-c-program-with-microsoftwslcontainers) |
| The package's target framework matches the SDK it was built against | `wslcsdkcs.dll` was built against `Microsoft.Windows.SDK.NET` 10.0.26100.79, which is not on nuget.org at all — the nearest is 10.0.26100.80 — so referencing it gives CS1705 | `Microsoft.WSL.Containers` 2.9.9 | CS1705, and an SDK version that cannot be restored | Reproduced, worked around by pinning `WindowsSdkPackageVersion` [2026-09-13](#2026-09-13--a-c-program-with-microsoftwslcontainers) |
| A container is cleaned up when `Start()` throws | It survives in `storage.vhdx`, and the next `Start()` with the same name fails | `Microsoft.WSL.Containers` 2.9.9 | `COMException`, "name already in use" | Reproduced, worked around with `Delete(Force)` in a `finally` and a cleanup at startup [2026-09-13](#2026-09-13--a-c-program-with-microsoftwslcontainers) |
| A container created through the API has network access, as `wslc run` gives it | With `ContainerSettings.NetworkingMode` unset it gets `NetworkMode: none` and no internet; it needs an explicit `Bridged` | `Microsoft.WSL.Containers`, 2.9.11 | `ip -4 addr` and `wget` before and after | Reproduced, defensible default, undocumented [2026-09-13](#2026-09-13--going-further-wslcimage-networking-kubernetes-gui) |
| `wslc` has a Compose subcommand, as `docker compose` does | `Unrecognized command: 'compose'` — there is none in 2.9.11 | `wslc` 2.9.11 | `wslc --help` | Reproduced; the course writes its own runner instead [2026-09-13](#2026-09-13--compose-with-wslc) |
| `wslc image prune -f` forces, as `docker`'s `-f` does | `-f` means `--filter`, and `--force` does not exist | `wslc` 2.9.11 CLI | A flag that reads like `--force` and takes a filter | Reproduced, a trap the lesson keeps [2026-09-13](#2026-09-13--remaining-open-questions) |
| A bind mount's source is read as a path inside the container | It is parsed as a Windows path, so `-v /var/run/docker.sock:/var/run/docker.sock` silently creates a real empty folder `C:\var\run\docker.sock\` | `wslc` 2.9.11 | A directory created on the host, no error | Reproduced, not reported [2026-09-13](#2026-09-13--compose-with-wslc) |
| Removing images and terminating a session give disk space back | `storage.vhdx` only grows | `%LocalAppData%\wslc\sessions\<session>\storage.vhdx` | 814 → 1070 → 1550 MB across a pull, a remove, a prune, a terminate and a re-pull | Reproduced; `Optimize-VHD -Mode Full` reclaims part of it, 3995 → 2789 MB in 10 s [2026-09-13](#2026-09-13--remaining-open-questions) |
| Two engines publishing the same host port conflict, or at least warn | `wslc` and Docker Desktop both bind 8080 in silence, and which one you reach depends on the name you use | Windows networking, `wslc` 2.9.11 against Docker Desktop 4.61 | `127.0.0.1` always reached `wslc` and `localhost` always Docker, in all four start-order and explicit-address variants | Reproduced, no error in any variant [2026-09-13](#2026-09-13--remaining-open-questions) |
| `ContainerSettings.Privileged = true` gives a privileged container, as `docker run --privileged` does | It changes nothing: capabilities, cgroups and `mount` come back identical to `Privileged = false`, in an administrator session too. `wslcsdk.h` declares `WSLC_CONTAINER_FLAG_PRIVILEGED = 0x4`, which is not applied | `wslc` 2.9.11 and its SDK | `CapEff` masks and cgroup mount tables, before and after; k3s still dies with `failed to evacuate root cgroup: read-only file system` | Reproduced, not reported. There is no Kubernetes on `wslc` because of it [2026-09-13](#2026-09-13--going-further-wslcimage-networking-kubernetes-gui) |

## Experiments

Seven questions the course measured rather than assumed. Where the hypothesis was a line of documentation — `settings.yaml`'s own comments, for instance — the row quotes it, because that is what was being tested.

| Question | Hypothesis | Result | Verdict | Where |
|---|---|---|---|---|
| Do `cpuCount` and `memorySize` in `settings.yaml` change what a container sees? | The file's own comments say so: "Number of virtual CPUs allocated to the session… default: all" and "Memory limit… default: half of available memory" | Defaults gave 24 CPUs and 31,946 MB. `cpuCount: 4, memorySize: 4GB` gave `nproc` 4, 3919 MB of RAM and 4096 MB of swap | Confirmed | [2026-09-13](#2026-09-13--limiting-the-cpu-and-memory-of-a-wslc-session) |
| Does editing `settings.yaml` reach a session that is already running? | Implicit: a saved setting takes effect | The first measurement after the edit still showed 24 CPUs; the session has to be terminated first | Refuted | [2026-09-13](#2026-09-13--limiting-the-cpu-and-memory-of-a-wslc-session) |
| When is an idle session's VM torn down? | At the configured `idleTimeout` of 30 s | Running at 0 s, gone at 35 s, polling every 5 s: between 30 and 35 s | Confirmed | [2026-09-13](#2026-09-13--limiting-the-cpu-and-memory-of-a-wslc-session) |
| Is `memorySize` a reservation or a ceiling, and is memory given back when a container stops? | Not written as a prediction; the table was the point | Idle VM about 921 MB. Holding 6 GB: 7069 MB. Ten seconds after stopping and removing: 2776 MB. Later: 902 MB | A ceiling, not a reservation, and released gradually rather than at once | [2026-09-13](#2026-09-13--limiting-the-cpu-and-memory-of-a-wslc-session) |
| Can `Optimize-VHD` reclaim what `storage.vhdx` will not give back? | Not written as a prediction | 3995 MB to 2789 MB in 10 s — still above the 1.9 GB actually used inside | Partly: it reclaims some, not all | [2026-09-13](#2026-09-13--remaining-open-questions) |
| Can `wslc` and Docker Desktop both publish port 8080, and which client reaches which? | Not written as a prediction: the question was whether it would even be allowed | No error in any of four variants. `127.0.0.1` reached `wslc` every time, `localhost` reached Docker every time | Confirmed, and worth knowing | [2026-09-13](#2026-09-13--remaining-open-questions) |
| Do the per-container `--memory` and `--cpus` flags constrain the container or the VM? | Written in advance: they should show up in the container's own view | `memory.max=536870912` and `cpu.max=150000 100000` match the flags exactly, but `nproc` still says 8 and `free -m` still says 15,996 MB | Confirmed in the cgroup, refuted in what the container sees | [2026-09-16](#2026-09-16--lot-2-five-new-lessons) |

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

**Still to do:** restart Docker Desktop and Podman and check that Docker Desktop 4.61 still works with WSL 2.9.11. (Docker Desktop: OK, see "Remaining open questions" below. Podman 5.8.3: `podman machine start` OK, `podman run --rm quay.io/podman/hello` OK; it warns that the default Docker API pipe is already taken by Docker Desktop and exposes its own, `npipe:////./pipe/podman-machine-default`.)

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

4 GB is too tight for the rest of the course (qdrant). Setting kept on this machine, given the memory incident of 2026-09-12: `cpuCount: 8`, `memorySize: 16GB` → `nproc=8`, RAM 15996 MB, swap 16384 MB.

### Verification: admin session and Windows-side memory

**The admin session reads the same file.** In an administrator terminal, `wslc info` shows the same `Settings file: C:\Users\spare\AppData\Local\wslc\settings.yaml`. After terminating the admin session:

```text
> wslc --session wslc-cli-admin-spare system session terminate
> wslc run --rm alpine sh -c 'echo nproc=$(nproc); free -m'
nproc=8
Mem:          15996 ...
Swap:         16384 ...
```

**On the Windows side, each session VM is a process named `vmmem<session>`** (`vmmemwslc-cli-spare`, `vmmemwslc-cli-admin-spare`); `hcsdiag list` (administrator) shows it as a `Running` VM named after the session. Its memory figures are only readable from an elevated terminal.

Test: a container that holds 6 GB for two minutes, in the non-elevated session.

```powershell
wslc run -d --name memtest alpine sh -c 'apk add -q stress-ng && stress-ng --vm 1 --vm-bytes 6G --vm-hang 0 --timeout 120s'
```

| Moment | VM process | Working set | Private memory |
|---|---|---|---|
| idle session (admin, nothing running) | `vmmemwslc-cli-admin-spare` | 921 MB | 970 MB |
| 6 GB held in the container | `vmmemwslc-cli-spare` | 7069 MB | 7083 MB |
| 10 s after `container stop` + `remove` | `vmmemwslc-cli-spare` | 2776 MB | 7084 MB |
| a moment later | `vmmemwslc-cli-spare` | 902 MB | 1902 MB |

- An idle session VM costs about **0.9 GB**.
- The memory used by the container shows up almost entirely on the Windows side (~6 GB + the base VM).
- After the container stops, the memory is **not given back immediately**: it decreases progressively.
- `memorySize` is a ceiling, not a reservation: the VM only takes what it uses.

Between two snapshots, the admin session VM had disappeared (nothing running in it): consistent with `idleTimeout` (30 s) — measured below.

## 2026-09-13 — Remaining open questions

### When is an idle VM torn down?

Run one container, then watch the VM process **without running any `wslc` command** (a `wslc` command wakes the session up):

```powershell
wslc run --rm alpine true
# then, every 5 s:
Get-Process -Name 'vmmemwslc-cli-spare' -ErrorAction SilentlyContinue
```

```text
    0s  VM running: True
   35s  VM running: False
```

The VM stops **30 to 35 s** after the last command (5 s polling): that's `idleTimeout: 30`. The session stays listed by `wslc system session list`; only the VM is torn down, and the next command starts it again.

### Docker Desktop with WSL 2.9.11

`docker desktop start` answered `Docker Desktop is already running` while no Docker Desktop process existed, and `docker desktop status` answered `Could not retrieve status`. Launching `C:\Program Files\Docker\Docker\Docker Desktop.exe` directly worked: engine 29.2.1 ready after ~130 s, `docker run --rm hello-world` OK. **Docker Desktop 4.61 works with WSL 2.9.11.**

### Are Docker and `wslc` images shared?

No. After `docker pull busybox`:

```text
> docker images            > wslc images
postgres:16-alpine          alpine   latest
busybox:latest
hello-world:latest
node:18-alpine
```

Each tool has its own store (`docker_data.vhdx` ≈ 50 GB for Docker, `storage.vhdx` per session for `wslc`). An image used by both is downloaded twice.

### Can `wslc` and Docker Desktop publish the same port?

Test: `nginx` in `wslc`, `httpd` (Apache, "It works!") in Docker, so the answer tells which one responds.

```powershell
wslc run -d --name webwslc -p 8080:80 nginx
docker run -d --name webdocker -p 8080:80 httpd
curl.exe http://127.0.0.1:8080/   # nginx  → wslc
curl.exe http://localhost:8080/   # It works! → Docker
```

**Both start without any error: the conflict is silent.** Windows accepts both listeners because they don't bind exactly the same address:

```text
TCP  0.0.0.0:8080     LISTENING  com.docker.backend
TCP  [::]:8080        LISTENING  com.docker.backend
TCP  127.0.0.1:8080   LISTENING  dllhost      ← wslc
TCP  [::1]:8080       LISTENING  wslrelay
```

`127.0.0.1` goes to `wslc` (the more specific address wins), while `localhost` resolves to `::1` first and ends up on Docker. Same result in every variant tried:

| Variant | Errors | `127.0.0.1` | `localhost` |
|---|---|---|---|
| `wslc` first, then Docker (8080) | none | wslc | Docker |
| Docker first, then `wslc` (8081) | none | wslc | Docker |
| Docker, then `wslc -p 0.0.0.0:8082:80` | none | wslc | Docker |
| `wslc -p 0.0.0.0:8083:80`, then Docker | none | wslc | Docker |

**Lesson:** don't publish the same port from both tools. Nothing warns you, and the answer depends on whether the client uses `127.0.0.1` or `localhost`.

### Does `storage.vhdx` grow and shrink?

Size of `%LocalAppData%\wslc\sessions\wslc-cli-spare\storage.vhdx`:

| Step | File size |
|---|---|
| start (`alpine`, `nginx`) | 814 MB |
| `wslc pull mcr.microsoft.com/dotnet/sdk:9.0` (869 MB) | 1070 MB |
| `wslc image remove` of that image | 1070 MB |
| `wslc image prune --all` ("Total reclaimed space: 178.5MB", nothing left) | 1070 MB |
| `system session terminate` | 1070 MB |
| pull `dotnet/sdk:9.0` again | 1070 MB |
| + `dotnet/aspnet:9.0` (224 MB) + `eclipse-temurin:21-jdk` (491 MB) | 1550 MB |

- The file **grows** when images are added, and **never shrinks** by itself: neither `image remove`, nor `prune`, nor terminating the session gives space back to Windows.
- Space freed inside is **reused**: pulling the SDK again didn't make the file grow.
- The growth is less than the displayed image size (`SIZE` is the uncompressed size, and freed space is reused), so the file size is not a reliable image counter.

Trap: in `wslc image prune`, `-f` means `--filter`, not `--force`; `--force` doesn't exist (`wslc image prune --all` doesn't ask for confirmation).

### Compacting `storage.vhdx`

After the lesson 4 builds, the file had grown to **3995 MB**, while `df` inside the session showed only **1.9 GB** used. Steps:

```powershell
# 1. Stop the session VM (non-elevated) and check it's gone
wslc --session wslc-cli-spare system session terminate
Get-Process -Name 'vmmemwslc-cli-spare' -ErrorAction SilentlyContinue   # nothing

# 2. Administrator PowerShell (Hyper-V module): back up, then compact
$f = "$env:LOCALAPPDATA\wslc\sessions\wslc-cli-spare\storage.vhdx"
Copy-Item $f "$f.bak"
Optimize-VHD -Path $f -Mode Full
```

```text
before: 3,995 MB
Optimize-VHD -Mode Full: OK in 10s
after: 2,789 MB
```

**1.2 GB given back to Windows in 10 seconds.** Check before deleting the backup: `wslc image list` still lists `csharp-api`, `java-reactor-api` and `alpine`, and both APIs still answer after `wslc run`.

- `Optimize-VHD` needs an **administrator** terminal and the **Hyper-V** PowerShell module (present here).
- The session VM must be stopped: otherwise the VHDX is in use.
- The file remains larger than the space used inside (2.8 GB vs 1.9 GB): only fully free blocks are reclaimed.
- `fstrim` isn't available in the session VM: `wslc system session run fstrim -v /` → `Failed to launch command fstrim. Errno = 2`.

## 2026-09-13 — Lessons 3 and 4 done

- **Lesson 3** (containers, ports, `exec`): practiced throughout the entries above — `nginx` published with `-p`, `exec`, `container list --all`, and the port conflict with Docker Desktop.
- **Lesson 4** (building an image): rewritten with a C# API and a Spring Boot WebFlux API, built and run with `wslc`; every output in the lesson is real.

## 2026-09-13 — Running qdrant with `wslc`

### Before starting: a qdrant is already running in Docker

```text
> docker ps
ga-qdrant  qdrant/qdrant:latest  Up About an hour (healthy)  0.0.0.0:6333-6334->6333-6334/tcp, [::]:6333-6334->6333-6334/tcp
```

Publishing `wslc` on 6333 too would start **without any error** and silently take over `127.0.0.1:6333` from the application that uses `ga-qdrant` (see the port conflict above). So the `wslc` qdrant is published on **16333/16334**.

### Pull: same tag, different version

```powershell
wslc pull qdrant/qdrant    # 21 s, 198 MB
```

The Docker image was already there, but `wslc` downloads it again (separate stores). And `latest` isn't the same version on both sides:

```text
> curl.exe http://127.0.0.1:16333/     # wslc
{"title":"qdrant - vector search engine","version":"1.19.1","commit":"6ab21cac18ebb6f4ae29102c7f8f5cc11affd5de"}
> curl.exe http://127.0.0.1:6333/      # Docker (ga-qdrant, pulled on 2025-12-19)
{"title":"qdrant - vector search engine","version":"1.16.3","commit":"bd49f45a8a2d4e4774cac50fa29507c4e8375af2"}
```

**Lesson:** `latest` means "whatever was latest when *this* tool pulled it". Pin a version (`qdrant/qdrant:v1.19.1`) when two environments must match.

### Run with a volume

```powershell
wslc volume create qdrant-data
wslc run -d --name qdrant -p 16333:6333 -p 16334:6334 -v qdrant-data:/qdrant/storage qdrant/qdrant
curl.exe http://127.0.0.1:16333/readyz    # all shards are ready (after 1 s)
```

```text
CONTAINER ID   IMAGE           COMMAND             CREATED         STATUS        PORTS                                                  NAMES
da52872e3246   qdrant/qdrant   "./entrypoint.sh"   5 seconds ago   Up 1 second   127.0.0.1:16333->6333/tcp, 127.0.0.1:16334->6334/tcp   qdrant
```

Trap: the log says `Access web UI at http://localhost:6333/dashboard`. That's the port **inside** the container. From Windows, the dashboard is at `http://127.0.0.1:16333/dashboard` — and `localhost:6333` would open the Docker one.

A collection, three points and a query (bodies in JSON files, to avoid PowerShell quoting issues):

```powershell
curl.exe -X PUT http://127.0.0.1:16333/collections/journal -H "Content-Type: application/json" --data-binary "@coll.json"
curl.exe -X PUT "http://127.0.0.1:16333/collections/journal/points?wait=true" -H "Content-Type: application/json" --data-binary "@points.json"
curl.exe -X POST http://127.0.0.1:16333/collections/journal/points/query -H "Content-Type: application/json" --data-binary "@query.json"
```

```text
coll.json    {"vectors":{"size":4,"distance":"Cosine"}}
points.json  {"points":[{"id":1,"vector":[0.9,0.1,0.1,0.1],"payload":{"note":"wslc sessions"}},{"id":2,"vector":[0.1,0.9,0.1,0.1],"payload":{"note":"ports and localhost"}},{"id":3,"vector":[0.1,0.1,0.9,0.1],"payload":{"note":"storage.vhdx"}}]}
query.json   {"query":[0.2,0.8,0.1,0.1],"limit":2,"with_payload":true}
```

```text
{"result":true,"status":"ok","time":0.24333272}
{"result":{"operation_id":1,"status":"completed"},"status":"ok","time":0.003567116}
{"result":{"points":[{"id":2,"version":1,"score":0.99111706,"payload":{"note":"ports and localhost"}},{"id":1,"version":1,"score":0.3651484,"payload":{"note":"wslc sessions"}}]},"status":"ok","time":0.00189502}
```

### Persistence: delete the container, keep the data

```powershell
wslc container stop qdrant
wslc container remove qdrant
wslc run -d --name qdrant -p 16333:6333 -p 16334:6334 -v qdrant-data:/qdrant/storage qdrant/qdrant
curl.exe http://127.0.0.1:16333/collections
curl.exe -X POST http://127.0.0.1:16333/collections/journal/points/count -H "Content-Type: application/json" -d "{}"
```

```text
{"result":{"collections":[{"name":"journal"}]},"status":"ok","time":8.866e-6}
{"result":{"count":3},"status":"ok","time":0.007211133}
```

The collection and its 3 points survive, because they live in the volume. `wslc volume inspect qdrant-data` shows `"Driver": "guest"` and a mountpoint inside the session VM (`/var/lib/docker/volumes/qdrant-data/_data`), so in the session's `storage.vhdx`.

### Don't mount a Windows folder for qdrant storage

```powershell
wslc run -d --name qdrant-bind -p 16335:6333 -v "C:\...\qdrant-bind:/qdrant/storage" qdrant/qdrant
wslc exec qdrant-bind sh -c "mount | grep /qdrant/storage"
```

```text
drvfs on /qdrant/storage type virtiofs (rw,relatime)
```

qdrant still starts and writes its files into the Windows folder, but logs an error:

```text
ERROR qdrant: Filesystem check failed for storage path ./storage. Details: FUSE filesystems may cause data corruption due to caching issues
```

**Lesson:** for a database, use a `wslc` **volume** (inside the VM), not a bind mount of a Windows folder.

### Resources

```text
> wslc stats qdrant
CONTAINER ID   NAME     CPU %   MEM USAGE / LIMIT     MEM %   NET I/O           BLOCK I/O        PIDS
da52872e3246   qdrant   0.16%   47.21MiB / 15.62GiB   0.30%   10.1kB / 5.77kB   8.19kB / 184kB   35
> docker stats ga-qdrant --no-stream --format "CPU {{.CPUPerc}}  MEM {{.MemUsage}}"
CPU 0.41%  MEM 367.8MiB / 31.2GiB
```

- The limit shown is the VM's: **15.62 GiB** for `wslc` (the `memorySize: 16GB` setting), **31.2 GiB** for Docker Desktop (half of the RAM by default).
- 47 MiB for 3 points against 368 MiB for `ga-qdrant`: not comparable, `ga-qdrant` holds real data.
- On the Windows side, the `vmmemwslc-cli-spare` VM was at 1160 MB (about 0.9 GB idle, measured earlier).
- qdrant logs `starting 7 workers`: it sees the 8 CPUs allowed by `cpuCount: 8`.

Cleanup: `wslc container stop qdrant qdrant-bind`, `wslc container remove qdrant qdrant-bind`, `wslc volume remove qdrant-data`. `ga-qdrant` was never touched.

## 2026-09-13 — Compose with `wslc`

### No `compose` command

```text
> wslc compose --help
Unrecognized command: 'compose'
```

`wslc --help` lists no Compose equivalent, and the [official tutorial](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers) doesn't mention it. `wslc` 2.9.11 **has no Compose support**.

### Dead end: plugging `docker compose` into the session engine

The session VM does run a Docker engine:

```text
> wslc system session run ps -eo pid,args
  131 /usr/bin/containerd --address /run/containerd/containerd.sock --root /var/lib/docker/containerd/daemon --state /run/docker/containerd/daemon
  132 /usr/bin/dockerd --containerd /run/containerd/containerd.sock
> wslc system session run ls -la /var/run/docker.sock
srw-rw---- 1 root docker 0 Sep 13 18:47 /var/run/docker.sock
```

But nothing exposes it to Windows (no `wslc` named pipe), the VM's own `docker` client fails (`wslc system session run docker version` → `The handle is invalid. Error code: ERROR_INVALID_HANDLE`), and it can't be mounted into a `docker:cli` container (which includes Compose v5.5.1):

```powershell
wslc run --rm -e DOCKER_HOST=unix:///var/run/docker.sock -v /var/run/docker.sock:/var/run/docker.sock docker:cli docker ps
```

```text
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

Why: the source of `-v` is a **Windows** path. `/var/run/docker.sock` became `C:\var\run\docker.sock`, mounted over `virtiofs`:

```text
drvfs on /run/docker.sock type virtiofs (rw,relatime)
```

**Trap:** `wslc` **creates** a missing bind-mount source. This test left an empty `C:\var\run\docker.sock\` folder on Windows (removed afterwards). `--mount type=bind,source=/var/run/docker.sock,...` is refused: `The bind source path must be absolute.`

### What Compose really provides, done by hand

`docker compose config` on a two-service file shows what Compose adds implicitly: one network per project, named volumes, and service names as DNS names. On a network created with `wslc network create`, names do resolve:

```text
> wslc run --rm --network demo alpine wget -qO- http://qdrant:6333/
{"title":"qdrant - vector search engine","version":"1.19.1","commit":"6ab21cac18ebb6f4ae29102c7f8f5cc11affd5de"}
> wslc run --rm --network demo alpine wget -qO- http://vectors:6333/readyz      # --network-alias vectors
all shards are ready
> wslc run --rm alpine wget -qO- -T 5 http://qdrant:6333/                      # default network
wget: bad address 'qdrant:6333'
```

The `compose.yaml` (validated with `docker compose -p wslcdemo config`):

```yaml
services:
  qdrant:
    image: qdrant/qdrant:v1.19.1
    ports:
      - "127.0.0.1:16333:6333"
    volumes:
      - qdrant-data:/qdrant/storage

  seed:
    image: curlimages/curl:8.16.0
    depends_on:
      - qdrant
    command: >
      --silent --show-error --retry 10 --retry-connrefused --retry-delay 1
      -X PUT http://qdrant:6333/collections/demo
      -H "Content-Type: application/json"
      -d '{"vectors":{"size":4,"distance":"Cosine"}}'

volumes:
  qdrant-data:
```

Its `wslc` translation, `wslc-up.ps1`:

```powershell
# Equivalent of `docker compose -p wslcdemo up -d` for compose.yaml, with wslc
$project = 'wslcdemo'

# What Compose creates implicitly: one network per project, named volumes
wslc network create "${project}_default"
wslc volume create "${project}_qdrant-data"

# service qdrant (the service name becomes a DNS alias on the project network)
wslc run -d --name "$project-qdrant-1" --network "${project}_default" --network-alias qdrant `
    -p 127.0.0.1:16333:6333 -v "${project}_qdrant-data:/qdrant/storage" qdrant/qdrant:v1.19.1

# service seed (depends_on only orders the start: curl retries until qdrant answers)
wslc run --name "$project-seed-1" --network "${project}_default" --network-alias seed `
    curlimages/curl:8.16.0 --silent --show-error --retry 10 --retry-connrefused --retry-delay 1 `
    -X PUT http://qdrant:6333/collections/demo -H 'Content-Type: application/json' `
    -d '{"vectors":{"size":4,"distance":"Cosine"}}'
```

And `wslc-down.ps1`:

```powershell
# Equivalent of `docker compose -p wslcdemo down --volumes`
$project = 'wslcdemo'
wslc container stop "$project-qdrant-1"
wslc container remove "$project-qdrant-1" "$project-seed-1"
wslc network remove "${project}_default"
wslc volume remove "${project}_qdrant-data"
```

Result of `wslc-up.ps1`:

```text
CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS                              PORTS                       NAMES
28be34e431f5   curlimages/curl:8.1…   "/entrypoint.sh --si…"   1 second ago    Exited (0) Less than a second ago                               wslcdemo-seed-1
c1f82d52d6ca   qdrant/qdrant:v1.19…   "./entrypoint.sh"        2 seconds ago   Up 1 second                         127.0.0.1:16333->6333/tcp   wslcdemo-qdrant-1
> wslc logs wslcdemo-seed-1
{"result":true,"status":"ok","time":0.409039704}
> curl.exe http://127.0.0.1:16333/collections
{"result":{"collections":[{"name":"demo"}]},"status":"ok","time":0.00004439}
```

After `wslc-down.ps1`: no container, only the default `bridge`/`host`/`none` networks, no volume.

**Conclusion:** for a small stack, a `wslc` script reproduces what Compose does (network, volumes, DNS names, start order). What it doesn't give: no reading of `compose.yaml`, no `depends_on` with `condition: service_healthy`, no diff-based `up` that only recreates what changed, no `logs -f` over all services. For real Compose projects, Docker Desktop (or Podman) remains the tool.

## 2026-09-13 — A C# program with `Microsoft.WSL.Containers`

Goal: drive a container from a Windows application, without `wslc.exe`. The code is in [`code/wsl-containers/wslc-host`](https://github.com/spareilleux/learn/tree/main/code/wsl-containers/wslc-host); [lesson 9](../09-csharp-api/) shows it.

### The documented snippet doesn't compile

Pasting the Microsoft Learn snippet into a project that references `Microsoft.WSL.Containers` 2.9.9 gives five errors:

```text
error CS0103: The name 'ComponentFlags' does not exist in the current context
error CS0117: 'SessionSettings' does not contain a definition for 'MemoryMB'
error CS0117: 'ProcessSettings' does not contain a definition for 'CmdLine'
error CS0103: The name 'DeleteContainerFlags' does not exist in the current context
error CS1705: Assembly 'wslcsdkcs' with identity 'wslcsdkcs, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null' uses 'Microsoft.Windows.SDK.NET, Version=10.0.26100.79, Culture=neutral, PublicKeyToken=31bf3856ad364e35' which has a higher version than referenced assembly 'Microsoft.Windows.SDK.NET' with identity 'Microsoft.Windows.SDK.NET, Version=10.0.19041.38, Culture=neutral, PublicKeyToken=31bf3856ad364e35'
```

The real names come from reading the public types of `wslcsdkcs.dll` with `MetadataLoadContext`:

| Microsoft Learn | Package 2.9.9 |
|---|---|
| `ComponentFlags GetMissingComponents()` | `IReadOnlyList<Component> GetMissingComponents()` (`VirtualMachinePlatform`, `WslPackage`, `SdkNeedsUpdate`) |
| `SessionSettings.MemoryMB` | `SessionSettings.MemorySizeInMB` |
| `ProcessSettings.CmdLine` | `ProcessSettings.CommandLine` (`IList<string>`) |
| `DeleteContainerFlags.None` | `DeleteContainerOption.None` / `Force` |

### `CS1705`: the Windows SDK version

The package declares `net8.0-windows10.0.19041.0`, but its `wslcsdkcs.dll` is compiled against `Microsoft.Windows.SDK.NET` 10.0.26100.79. Moving to `net10.0-windows10.0.26100.0` isn't enough (the SDK picks projection 10.0.26100.38, same error); the version has to be forced. `10.0.26100.79` doesn't exist on nuget.org (`NU1102`, nearest: `10.0.26100.80`):

```xml
<TargetFramework>net10.0-windows10.0.26100.0</TargetFramework>
<WindowsSdkPackageVersion>10.0.26100.80</WindowsSdkPackageVersion>
<RuntimeIdentifier>win-x64</RuntimeIdentifier>
```

### First run

```text
WSL container service 2.9.11
Session started, storage in C:\Users\spare\AppData\Local\WslcHost
Image alpine:latest (8 MB)
Hello from 3.24.1 on 6.18.40.1-microsoft-standard-WSL2
Container b27dd2f80927 exited with code 0
```

7 s in total, including the alpine pull into a new, empty session. The container sees the session's limits: `nproc` → `2`, `free -m` → `1907` MB total for `MemorySizeInMB = 2048`.

### Where the application's session shows up

While a 20-second container runs:

```text
> wslc system session list
ID   Creator PID   Display Name
6    350476        wslc-cli-admin-spare
8    275812        wslc-cli-spare
16   110952        wslc-host
> Get-Process vmmem*
vmmemCmZygote     0
vmmemWSL       3307
vmmemwslc-host  510
> wslc --session wslc-host container list
CONTAINER ID   IMAGE           COMMAND                  CREATED         STATUS         PORTS   NAMES
2e75803c92a9   alpine:latest   "/bin/sh -c 'echo st…"   4 seconds ago   Up 3 seconds           wslc-host-hello
```

- The session is a regular `wslc` session: same `vmmem<session>` VM, visible and drivable from the CLI with `--session`.
- Its disk is where the application chose, `%LocalAppData%\WslcHost\storage.vhdx` (67 MB after the pull), not under `%LocalAppData%\wslc\sessions`. Its limits come from `SessionSettings`, not from `settings.yaml` (8 CPUs there, 2 seen by the container).
- After `session.Terminate()`, the session and its `vmmem` disappear right away, without the CLI's 30 s idle delay.

### Trap: a failed `Start` leaves the container behind

A run launched from Git Bash with `/bin/sh` as an argument: MSYS converts the path to `C:/Program Files/Git/usr/bin/sh`, and `container.Start()` throws:

```text
Unhandled exception. System.ArgumentException: The parameter is incorrect.

failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "C:/Program Files/Git/usr/bin/sh": stat C:/Program Files/Git/usr/bin/sh: no such file or directory: unknown
```

The next run fails on `CreateContainer`:

```text
Unhandled exception. System.Runtime.InteropServices.COMException (0x800700B7): Cannot create a file when that file already exists.

Conflict. The container name "/wslc-host-hello" is already in use by container "176a59b772bebfb974a8404150407157d49cc279cbe2f66c2d6e2788f9bfbadc". You have to remove (or rename) that container to be able to reuse that name.
```

The container survives the process in `storage.vhdx`. Two fixes in the program: `Delete(DeleteContainerOption.Force)` in a `finally`, and on startup `OpenContainer` + `Delete` of a leftover (`COMException` if there is none). Verified: leftover removed (`Removed leftover container wslc-host-hello`), then a command that doesn't exist (`/nope`) no longer leaves anything behind.

**Conclusion:** the API works and is fast, but in preview its documentation lags behind the package: names, SDK version. Compile first, read the types if in doubt. On GitHub Actions the Windows runners have no WSL containers service: CI only compiles the program.
## 2026-09-13 — Going further: `WslcImage`, networking, Kubernetes, GUI

### Building an image during `dotnet build`

The package's MSBuild targets (`build\Microsoft.WSL.Containers.common.targets`) add a `WslcImage` item: after `Build`, they run `wslc image build` then `wslc image save` to a `.tar` next to the program. Test project:

```xml
<ItemGroup>
  <PackageReference Include="Microsoft.WSL.Containers" Version="2.9.9" />
  <WslcImage Include="greeter" Image="wslc-host/greeter:1.0" Dockerfile="container/Containerfile" Context="container/" />
</ItemGroup>
```

```dockerfile
FROM docker.io/library/alpine:3.24
COPY greet.sh /usr/local/bin/greet
RUN chmod +x /usr/local/bin/greet
ENTRYPOINT ["/usr/local/bin/greet"]
```

First trap, the same as with the CLI: the targets call a bare `wslc`, so a terminal (or an IDE) opened before WSL was installed doesn't find it:

```text
error WSLC0001: The wslc CLI check failed: 'wslc --version' returned exit code 9009. Install WSL by running 'wsl --install --no-distribution', or set the WslcCliPath property to a specific wslc.exe path.
```

With `-p:WslcCliPath="C:\Program Files\WSL\wslc.exe"` (or a new terminal):

```text
  WSLC: Building image 'wslc-host/greeter:1.0'...
    | naming to docker.io/wslc-host/greeter:1.0
  WSLC: Saving image 'wslc-host/greeter:1.0' to 'bin\Debug\net10.0-windows10.0.26100.0\win-x64\greeter.tar'...
Build succeeded.
```

9 s, and an 8.3 MB `greeter.tar`. The image is built in the CLI session (`wslc-cli-spare`), where it stays.

The build is incremental: the target compares the files in `Context` (and a `wslc.greeter.options` file that records the options) with the `.tar`:

| Change | `dotnet build` | `.tar` |
|---|---|---|
| none | 1 s, no `WSLC:` line | unchanged |
| `greet.sh` touched | 2 s, rebuilt (layer cache) | rewritten |
| `echo edited` added to `greet.sh` | 3 s, rebuilt | rewritten |
| none | 2 s, no `WSLC:` line | unchanged |

Each real change leaves the previous image untagged (`<none>`) in the CLI session: that's what the `WslcPruneAfterBuild` property is for.

### Loading the `.tar` into the application's session

`LoadImageAsync` (the equivalent of `wslc load`) keeps the tag and the `ENTRYPOINT`; `CommandLine` then passes arguments to the entrypoint, like `docker run image args`:

```csharp
await session.LoadImageAsync(Path.Combine(AppContext.BaseDirectory, "greeter.tar"));
// ... new ContainerSettings("wslc-host/greeter:1.0") with CommandLine = ["Claude"]
```

```text
before: 
load 427 ms
after: wslc-host/greeter:1.0
Hello Claude from an image built by dotnet build (alpine 3.24.1)
edited
exit 0
```

So the full chain works without a registry: `dotnet build` produces the image, the `.tar` ships with the program, the program loads it into its own session.

`ImportImageAsync` is something else (the equivalent of `wslc import`): it expects a flat filesystem, like the one `wslc export` produces. Given the `.tar` from `image save` (an OCI layout starting with `blobs/sha256/…`), it accepts it, but the resulting image has no entrypoint (`CommandLine = ["Claude"]` fails with `exec: "Claude": executable file not found in $PATH`) and no `/bin/sh` either:

```text
failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "/bin/sh": stat /bin/sh: no such file or directory: unknown
```

Checked with the CLI: `wslc export` of an alpine container, `wslc import`, then `wslc run --rm exptest/rootfs:1 /bin/cat /etc/alpine-release` → `3.24.1`, and `image inspect` shows `"Cmd": null` and `"Entrypoint": null`.

### Trap: API containers have no network by default

`container.Inspect()` shows `"NetworkMode":"none"` when `ContainerSettings.NetworkingMode` isn't set, while `wslc run` connects to the bridge. Same alpine container, `ip -4 addr` then `wget` to the internet:

```text
--- NetworkingMode=default
NetworkMode in inspect: none
    inet 127.0.0.1/8 scope host lo
no internet
--- NetworkingMode=Bridged
NetworkMode in inspect: bridge
    inet 127.0.0.1/8 scope host lo
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
internet ok
```

The pull itself works without it (it's done by the session, not by the container). A containerized service that needs to call out, or that is published with `PortMappings`, needs `NetworkingMode = ContainerNetworkingMode.Bridged`.

### Kubernetes: no, not even k3s

`wslc` has no Kubernetes command. Attempt with [k3s](https://k3s.io/) in a container, as is done with Docker (`--privileged`):

- The CLI has no `--privileged` or `--cap-add` option (`wslc run --help`). Without them, `wslc run -d --name k3s-cli --tmpfs /run --tmpfs /var/run rancher/k3s:v1.36.4-k3s1 server` stops immediately:

  ```text
  time="2026-09-14T02:17:38Z" level=fatal msg="Error: failed to evacuate root cgroup: mkdir /sys/fs/cgroup/init: read-only file system"
  ```

- The API has `ContainerSettings.Privileged`. With `Privileged = true`: same error. Comparison of two alpine containers in the same session:

  ```text
  --- Privileged=False
  cgroup /sys/fs/cgroup cgroup2 ro,nosuid,nodev,noexec,relatime 0 0
  CapEff:	00000000a80425fb
  15
  --- Privileged=True
  cgroup /sys/fs/cgroup cgroup2 ro,nosuid,nodev,noexec,relatime 0 0
  CapEff:	00000000a80425fb
  15
  ```

  Same capabilities (Docker's default set), cgroups read-only, same 15 entries in `/dev`: in a non-administrator session, `Privileged` has no visible effect in 2.9.11.

  Same test **as administrator** (UAC, session limited to 1 CPU and 1 GB, one more check: `mount -t tmpfs none /mnt`):

  ```text
  elevated: True
  --- Privileged=False  HostConfig={"Memory":0,"NanoCpus":0,"NetworkMode":"none","Ulimits":[]}
  cgroup /sys/fs/cgroup cgroup2 ro,nosuid,nodev,noexec,relatime 0 0
  CapEff:	00000000a80425fb
  dev=15
  mount: permission denied (are you root?)
  mount denied
  --- Privileged=True  HostConfig={"Memory":0,"NanoCpus":0,"NetworkMode":"none","Ulimits":[]}
  cgroup /sys/fs/cgroup cgroup2 ro,nosuid,nodev,noexec,relatime 0 0
  CapEff:	00000000a80425fb
  dev=15
  mount: permission denied (are you root?)
  mount denied
  ```

  No difference either, and `Inspect()` doesn't even report a `Privileged` field. Yet the flag exists in the C header (`WSLC_CONTAINER_FLAG_PRIVILEGED = 0x00000004` in `wslcsdk.h`): declared, but not applied in 2.9.11. k3s wasn't retried.

### Extensions and GUI: none

- `wslc --help` lists `container`, `image`, `network`, `registry`, `settings`, `system`, `volume` and the Docker-style shortcuts: no extension mechanism.
- `wslc settings` only opens `settings.yaml` in the default editor.
- The **WSL Settings** app (the only WSL app in the Start menu besides `WSL`) has no container page: its pages are `About`, `Developer`, `DistroManagement`, `DockerDesktopIntegration`, `FileSystem`, `General`, `GPUAcceleration`, `GUIApps`, `MemAndProc`, `Networking`, `NetworkingIntegration`, `OptionalFeatures`, `VSCodeIntegration`, `VSIntegration`, `WorkingAcrossFileSystems`.

**Conclusion:** the `dotnet build` → `.tar` → `LoadImage` chain is the most original thing in the package, and it works. Around it, `wslc` 2.9.11 stays a runtime: no Compose, no Kubernetes, no extensions, no GUI. Cleanup: test images removed from the CLI session (`greeter`, `k3s`, `docker:cli`), test sessions' `storage.vhdx` deleted (336 MB + 81 MB).

## 2026-09-16 — Lot 2: five new lessons

The entries above held more verified material than the five lessons taught. They now have their own lessons: [6. Resources and limits](../06-resources-and-limits/), [7. Volumes and a real service](../07-volumes-and-a-real-service/), [8. Compose without Compose](../08-compose/), [9. Driving containers from C#](../09-csharp-api/) and [10. Networking, Kubernetes and GUI](../10-networking-kubernetes-gui/). The API section moved from lesson 5 to lesson 9; lesson 5 now covers the coexistence with Docker Desktop. The `compose.yaml` and its two `wslc` scripts are in [`code/wsl-containers/compose`](https://github.com/spareilleux/learn/tree/main/code/wsl-containers/compose), and CI runs the `compose.yaml` with Docker Compose.

Three checks were run again for these lessons, with `wslc` 2.9.11 and the session at 8 CPUs and 16 GB.

`wslc run --help` lists per-container limits and health checks, among others: `--cpus`, `-m`/`--memory`, `--health-cmd`, `--health-interval`, `--gpus`. Still no `--privileged` and no `--cap-add`.

Per-container limits set the control group, but `nproc` and `free` still show the VM:

```text
> wslc run --rm --memory 512M --cpus 1.5 alpine sh -c 'echo nproc=$(nproc); cat /sys/fs/cgroup/memory.max /sys/fs/cgroup/cpu.max; free -m'
wsl: Your kernel does not support swap limit capabilities or the cgroup is not mounted. Memory limited without swap.
nproc=8
536870912
150000 100000
              total        used        free      shared  buff/cache   available
Mem:          15996         278       15439           3         280       15527
Swap:         16384           0       16384
```

A CLI container has the same limits as the API containers of the `Privileged` test:

```text
> wslc run --rm alpine sh -c 'grep cgroup /proc/mounts; grep CapEff /proc/self/status; ls /dev | wc -l'
cgroup /sys/fs/cgroup cgroup2 ro,nosuid,nodev,noexec,relatime 0 0
CapEff:	00000000a80425fb
15
```

Health checks work: `wslc run -d --name hc --health-cmd 'test -f /tmp/ready' --health-interval 2s alpine sh -c 'sleep 6; touch /tmp/ready; sleep 60'` showed `Up 3 seconds (health: starting)`, then `Up 11 seconds (healthy)` in `wslc container list`, and `container inspect` has a `"Health"` object. Container stopped and removed afterwards.

**Still to verify:** `hostLoopback` (`host.wslc.internal`) from a container; whether `-p 0.0.0.0:…` is reachable from another machine; `wslc network connect` on a running container; the behavior of `volume create` and `network create` when the object exists; `PortMappings` on an API container without a network; the scripts of lesson 8 in Windows PowerShell 5.1.

## Open questions

- ~~Where does `wslc` store its images and containers?~~ In `%LocalAppData%\wslc\sessions\<session>\storage.vhdx`, one virtual disk per session. It grows with images and doesn't shrink on its own (see above).
- ~~Can the memory and CPU of the VM used by `wslc` be limited?~~ Yes: `cpuCount` and `memorySize` in `settings.yaml`, then terminate the session (see above).
- ~~Can `wslc` and Docker Desktop publish ports without conflict?~~ They can publish the same port without **any error**, which is the problem: `127.0.0.1` reaches `wslc`, `localhost` reaches Docker (see above).
- ~~How do you compact a session's `storage.vhdx`?~~ Terminate the session, then `Optimize-VHD -Mode Full` as administrator: 3995 MB → 2789 MB (see above).
- ~~Does the MSBuild `WslcImage` integration (building an image to a `.tar` during `dotnet build`) work?~~ Yes, incrementally; the `.tar` is loaded with `LoadImageAsync`, not `ImportImageAsync` (see above).
- ~~Does `ContainerSettings.Privileged` take effect in an administrator session?~~ No: same capabilities, read-only cgroups and `mount` denied, as administrator too (see above).
