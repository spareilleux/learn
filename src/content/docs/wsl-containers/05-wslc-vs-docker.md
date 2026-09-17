---
title: 5. wslc or Docker Desktop?
description: Compare wslc and Docker Desktop, run both on one machine, and avoid their silent traps - separate image stores, a latest tag that differs, and the same port published twice without an error.
sidebar:
  order: 5
---

After four lessons, `wslc` covers what most developers do with Docker every day: pull, run, publish, exec, build. The practical question is not whether it replaces Docker Desktop in general, but whether it can replace it on **your** machine, or live next to it. This lesson compares the two, then tests the coexistence: do they share images, do they both still work, and what happens when both publish the same port. The measurements are in the [journal](../journal/).

## Comparison

| Criterion | `wslc` (WSL containers) | Docker Desktop |
|---|---|---|
| Installation | included in WSL ≥ 2.9.3 | separate product |
| Maturity (Sept. 2026) | public preview | stable |
| CLI | close to Docker | `docker` |
| Linux VM | one per session, `vmmem<session>` | one distro, `docker-desktop` |
| Resource limits | per session, `settings.yaml` ([lesson 6](../06-resources-and-limits/)) | for the WSL 2 VM, `.wslconfig` |
| API for Windows applications | yes — NuGet `Microsoft.WSL.Containers` ([lesson 9](../09-csharp-api/)) | Docker Engine API (HTTP) |
| Enterprise management | Microsoft Defender for Endpoint, Intune | Docker Business |
| Ecosystem (Compose, Kubernetes, extensions, GUI) | none in 2.9.11: no `compose` command ([lesson 8](../08-compose/)), no Kubernetes (k3s doesn't start), no extensions, no container page in WSL Settings ([lesson 10](../10-networking-kubernetes-gui/)) | complete |

The row that matters most for a C# or Java team is the API. Every tool built on the Docker Engine API, from Testcontainers to IDE container views, needs an endpoint that `wslc` doesn't expose to Windows ([lesson 8](../08-compose/)). In return, `Microsoft.WSL.Containers` gives a Windows application something Docker Desktop doesn't: its own containers, with no product to install.

## Both on one machine

### Docker Desktop still works with WSL 2.9.11

Updating WSL to the pre-release didn't break Docker Desktop 4.61, but its CLI gave a confusing first answer. `docker desktop start` replied `Docker Desktop is already running` while no Docker Desktop process existed, and `docker desktop status` replied `Could not retrieve status`. Starting `C:\Program Files\Docker\Docker\Docker Desktop.exe` directly worked: the engine 29.2.1 was ready after about 130 seconds, and `docker run --rm hello-world` succeeded. Podman 5.8.3 also started and ran its test image.

### Images are not shared

After `docker pull busybox`, the two lists differ:

```text
> docker images            > wslc images
postgres:16-alpine          alpine   latest
busybox:latest
hello-world:latest
node:18-alpine
```

Each tool has its own store: `docker_data.vhdx`, about 50 GB here, for Docker, and one `storage.vhdx` per session for `wslc`. An image used by both is downloaded twice and stored twice. Worse, the same tag can point to two versions: `qdrant/qdrant:latest` was qdrant 1.16.3 in Docker, pulled months earlier, and 1.19.1 in `wslc` ([lesson 7](../07-volumes-and-a-real-service/)).

### The same port, twice, without an error

The riskiest trap. A test with two web servers that answer differently: `nginx` in `wslc`, and `httpd`, the Apache server whose page says "It works!", in Docker. The page tells which tool answered.

```powershell
wslc run -d --name webwslc -p 8080:80 nginx
docker run -d --name webdocker -p 8080:80 httpd
curl.exe http://127.0.0.1:8080/   # nginx  → wslc
curl.exe http://localhost:8080/   # It works! → Docker
```

**Both containers start without any error.** Windows accepts the two listeners because they don't bind exactly the same address. The listeners on port 8080, with their processes:

```text
TCP  0.0.0.0:8080     LISTENING  com.docker.backend
TCP  [::]:8080        LISTENING  com.docker.backend
TCP  127.0.0.1:8080   LISTENING  dllhost      ← wslc
TCP  [::1]:8080       LISTENING  wslrelay
```

`127.0.0.1` goes to `wslc`, because the more specific address wins, while `localhost` resolves to `::1` first and ends up on Docker. The order of the starts and an explicit `0.0.0.0` don't change anything:

| Variant | Errors | `127.0.0.1` | `localhost` |
|---|---|---|---|
| `wslc` first, then Docker (8080) | none | wslc | Docker |
| Docker first, then `wslc` (8081) | none | wslc | Docker |
| Docker, then `wslc -p 0.0.0.0:8082:80` | none | wslc | Docker |
| `wslc -p 0.0.0.0:8083:80`, then Docker | none | wslc | Docker |

Think of what this means for an application. A Spring Boot or ASP.NET Core configuration that says `localhost:5432` and a test script that says `127.0.0.1:5432` can talk to two different databases, and every tool reports success. The fix is organizational: give each tool its own port range, as [lesson 7](../07-volumes-and-a-real-service/) does with 16333 for the `wslc` qdrant.

### Two VMs cost two VMs

Each tool keeps its own VM and its own memory. An idle `wslc` session costs about 0.9 GB and stops after 30 seconds without a command ([lesson 6](../06-resources-and-limits/)); Docker Desktop's VM stays up while Docker Desktop runs. On a machine already short of memory, the journal's first entry shows where this can end: `Wsl/0x8007000e`, not enough memory, and Docker Desktop crashing.

## When to choose what

- **`wslc`**: simple needs, such as running a database, a service or a tool; a wish not to depend on Docker Desktop and its licensing; or a Windows application that needs to drive its own containers.
- **Docker Desktop**, or Podman: projects based on Docker Compose, local Kubernetes, tools that need the Docker Engine API such as Testcontainers, and a team already tooled around Docker.
- **Both**: possible, with separate ports and the memory of two VMs in mind.

## Key takeaways

- `wslc` = native WSL containers, with no third-party product, still in preview.
- Docker Desktop remains more complete: Compose, Kubernetes, extensions, a graphical interface and the Docker Engine API.
- Docker Desktop 4.61 keeps working with WSL 2.9.11, but start it from its executable if `docker desktop start` claims it's already running.
- Images are not shared: an image used by both tools is downloaded twice, and `latest` can be two different versions.
- Both tools can publish the same port without an error. `127.0.0.1` then reaches `wslc` and `localhost` reaches Docker: keep their ports apart.
- The `Microsoft.WSL.Containers` API opens up a use case Docker Desktop doesn't cover directly: Windows applications that embed Linux containers.

## Exercises

1. Docker Desktop publishes PostgreSQL on port 5432. You start another PostgreSQL with `wslc run -d -p 5432:5432 postgres:16-alpine`. Your ASP.NET Core application uses `Host=localhost;Port=5432` and your migration script uses `127.0.0.1`. Which database does each one reach, and what errors do you see?

<details>
<summary>Solution</summary>

No error anywhere. The migration script, on `127.0.0.1`, reaches the `wslc` database, which listens on that exact address. The application, on `localhost`, which resolves to `::1` first, reaches Docker's database. The migrations are applied to a database the application never reads. This follows the four variants measured above; PostgreSQL itself wasn't part of the test, so *to verify* with your client library, since some resolve `localhost` to IPv4 first.

</details>

2. How do you find out, in a few seconds, which process listens on each address of port 8080?

<details>
<summary>Solution</summary>

With PowerShell, which doesn't need elevation for this:

```powershell
Get-NetTCPConnection -LocalPort 8080 -State Listen | Select-Object LocalAddress, OwningProcess, @{n='Process';e={(Get-Process -Id $_.OwningProcess).ProcessName}}
```

A `dllhost` on `127.0.0.1` is the `wslc` listener; `com.docker.backend` on `0.0.0.0` and `[::]` is Docker Desktop. This command was checked on another port of the same machine, not during the port 8080 test. From an administrator terminal, `netstat -abno` gives the same information.

</details>

3. A teammate says: "No need to pull it again, I already have `qdrant/qdrant:latest` in Docker." Give two reasons why that's wrong for `wslc`.

<details>
<summary>Solution</summary>

First, the stores are separate: `wslc` downloads the image again into its session's `storage.vhdx`. Second, `latest` is resolved at pull time, so the `wslc` copy can be a newer version than the Docker one: 1.19.1 against 1.16.3 in the test. Pin a version tag when both must match.

</details>

4. After updating WSL, `docker desktop start` answers `Docker Desktop is already running`, but `docker ps` fails. What do you do?

<details>
<summary>Solution</summary>

Check whether a Docker Desktop process really exists, for example with `Get-Process "Docker Desktop" -ErrorAction SilentlyContinue`. If there is none, start `C:\Program Files\Docker\Docker\Docker Desktop.exe` directly and wait for the engine, which took about two minutes here, before running `docker ps` again.

</details>

## Sources

- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container)
- [Docker Desktop](https://docs.docker.com/desktop/) and [Docker Desktop WSL 2 backend](https://docs.docker.com/desktop/features/wsl/) — Docker docs
- [Published ports](https://docs.docker.com/engine/network/port-publishing/) — Docker docs
- [`Get-NetTCPConnection` — Microsoft Learn](https://learn.microsoft.com/powershell/module/nettcpip/get-nettcpconnection)
- [Testcontainers](https://testcontainers.com/)
