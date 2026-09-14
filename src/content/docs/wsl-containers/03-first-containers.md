---
title: 3. First containers
description: Run, publish, inspect and stop containers with wslc.
sidebar:
  order: 3
---

:::caution[Use a non-elevated terminal]
`wslc` doesn't need administrator rights. An elevated terminal uses a **different session** (`wslc-cli-admin-<user>` instead of `wslc-cli-<user>`), with its own images, containers, volumes and networks: an image pulled in one isn't visible in the other. Details in the [journal](../journal/).
:::

## Finding your way around the CLI

```powershell
wslc --help                # all commands
wslc <COMMAND> --help      # help for a command
wslc image list            # images available locally
wslc container list        # running containers
wslc container list --all  # including stopped containers
wslc stats                 # CPU / memory usage of running containers
```

## A throwaway container

```powershell
wslc run --rm -it ubuntu:latest bash -c "echo Hello world from WSL container!"
```

```text
...
Status: Downloaded newer image for ubuntu:latest
Hello world from WSL container!
```

| Option | Effect |
|---|---|
| `--rm` | removes the container as soon as it stops |
| `-it` | interactive mode with a terminal |
| `ubuntu:latest` | the image (downloaded automatically if missing) |
| `bash -c "…"` | the command to run in the container |

## A web server in the background

```powershell
# Run nginx in the background, Windows port 8080 → container port 80
wslc run -d --rm -p 8080:80 --name web nginx

# Query the server from Windows
curl.exe -s -o NUL -w "%{http_code}`n" http://127.0.0.1:8080/

# See the container
wslc container list

# Run a command in the running container
wslc exec web cat /etc/os-release

# Resource usage (a snapshot, then the command returns)
wslc stats

# Stop it (and, thanks to --rm, remove it)
wslc container stop web
```

```text
1796028d1f6addd8344386cf89632ff99fb5c73faa16c943184421eb08e0943b
200
CONTAINER ID   IMAGE   COMMAND                  CREATED         STATUS         PORTS                    NAMES
1796028d1f6a   nginx   "/docker-entrypoint.…"   3 seconds ago   Up 2 seconds   127.0.0.1:8080->80/tcp   web
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
...
```

| Option | Effect |
|---|---|
| `-d` | detached: the container runs in the background |
| `-p 8080:80` | publishes the port: `host:container` |
| `--name web` | readable name, usable instead of the ID |

:::caution[`127.0.0.1` rather than `localhost`]
`wslc` publishes on `127.0.0.1` only (see the `PORTS` column). If Docker Desktop also publishes port 8080, it listens on `0.0.0.0` **and** `[::]`: `localhost` resolves to `::1` first and reaches Docker's container, with no error on either side. Address `127.0.0.1` explicitly. And call `curl.exe`: in Windows PowerShell 5.1, `curl` is an alias of `Invoke-WebRequest`.
:::

`wslc stats` shows the session's limit in the `MEM USAGE / LIMIT` column:

```text
CONTAINER ID   NAME   CPU %   MEM USAGE / LIMIT     MEM %   NET I/O     BLOCK I/O     PIDS
1e72dbeb2a9a   site   0.00%   8.801MiB / 15.62GiB   0.06%   736B / 0B   0B / 8.19kB   9
```

15.62 GiB here, because the session is limited to 16 GB in `settings.yaml` (see the [journal](../journal/)).

:::note[If you know Docker]
These commands are almost identical to `docker run`, `docker exec`, etc. Subcommands are grouped (`wslc container list`, `wslc image list`), but the Docker-style shortcuts exist too: `wslc ps`, `wslc images`, `wslc rmi`, `wslc logs`.
:::

## Key takeaways

- `run` creates **and** starts a container; `--rm` avoids piling up stopped containers.
- `-p host:container` makes a service reachable from Windows, on `127.0.0.1`.
- `exec` runs a command in an **already running** container.
- Always the same terminal type (non-elevated): each privilege level has its own session.

## Exercises

1. Run an `nginx` container reachable on Windows port **9090**, named `site`, then check that it responds.

<details>
<summary>Solution</summary>

```powershell
wslc run -d --rm -p 9090:80 --name site nginx
curl.exe -s -o NUL -w "%{http_code}`n" http://127.0.0.1:9090/
wslc container stop site
```

`200` means nginx answered.

</details>

2. How can you find out which Linux distribution the `nginx` image uses without opening an interactive shell?

<details>
<summary>Solution</summary>

```powershell
wslc run -d --rm --name site nginx
wslc exec site cat /etc/os-release
wslc container stop site
```

In September 2026, `nginx:latest` is based on `Debian GNU/Linux 13 (trixie)`.

</details>

3. What is the difference between `wslc container list` and `wslc container list --all`?

<details>
<summary>Solution</summary>

Without `--all`, only **running** containers are listed. With `--all`, stopped (but not removed) containers appear as well.

</details>

## Sources

- [Get started with containers on WSL — Microsoft Learn](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers)
- [nginx — Docker Hub](https://hub.docker.com/_/nginx)
- [curl](https://curl.se/)
