---
title: 3. First containers
description: Run, publish, inspect and stop containers with wslc.
sidebar:
  order: 3
---

:::caution[Use a non-elevated terminal]
`wslc` doesn't need administrator rights. An elevated terminal uses a **different session** (`wslc-cli-admin-<user>` instead of `wslc-cli-<user>`), with its own images, containers, volumes and networks: an image pulled in one isn't visible in the other. The section [One session per privilege level](#one-session-per-privilege-level) below shows it.
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

15.62 GiB here, because the session is limited to 16 GB in `settings.yaml` (see [lesson 6](../06-resources-and-limits/)).

:::note[If you know Docker]
These commands are almost identical to `docker run`, `docker exec`, etc. Subcommands are grouped (`wslc container list`, `wslc image list`), but the Docker-style shortcuts exist too: `wslc ps`, `wslc images`, `wslc rmi`, `wslc logs`.
:::

## One session per privilege level

`wslc` doesn't talk to a single, machine-wide engine like Docker Desktop. It creates a **session**, with its own VM, engine and virtual disk, for each user **and each privilege level**. The trap shows up the first time you open an administrator terminal: in a fresh elevated `cmd.exe`, `wslc run --rm hello-world` downloaded the image **again**, although it had already been pulled from a normal terminal:

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

`wslc-cli-<user>` is the session of non-elevated terminals, `wslc-cli-admin-<user>` the one of administrator terminals. To see what is really separated, the test created a volume and a network in the normal terminal, then removed the image there:

```powershell
wslc volume create sesstest-vol
wslc network create sesstest-net
wslc image remove hello-world
wslc images    # empty
```

In the administrator terminal, the removed image is still there, while the new volume and network are not, and even the default networks have other IDs:

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

The global option `--session` chooses another session. It goes **before** the subcommand; after it, `wslc` answers `Option name was not recognized`. Access is asymmetric:

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

On disk, each session has its own virtual disks, a little under 600 MB each at that point:

```text
%LocalAppData%\wslc\sessions\wslc-cli-spare\storage.vhdx         ~587 MB
%LocalAppData%\wslc\sessions\wslc-cli-spare\swap.vhdx            36 MB
%LocalAppData%\wslc\sessions\wslc-cli-admin-spare\storage.vhdx   ~577 MB
%LocalAppData%\wslc\sessions\wslc-cli-admin-spare\swap.vhdx      36 MB
```

Cleanup, in the normal terminal: `wslc volume remove sesstest-vol` and `wslc network remove sesstest-net`. The simple rule: `wslc` never needs elevation, so always use a non-elevated terminal.

## Key takeaways

- `run` creates **and** starts a container; `--rm` avoids piling up stopped containers.
- `-p host:container` makes a service reachable from Windows, on `127.0.0.1`.
- `exec` runs a command in an **already running** container.
- Always the same terminal type (non-elevated): each privilege level has its own session, with its own images, containers, volumes, networks and disk.
- `--session <name>` goes before the subcommand; an administrator can reach the normal session, not the reverse.

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

4. In an administrator PowerShell, you type `wslc image list --session wslc-cli-<user>` and get `Option name was not recognized`. Fix the command. Would the same command work from a normal terminal with the admin session's name?

<details>
<summary>Solution</summary>

`--session` is a global option and goes before the subcommand: `wslc --session wslc-cli-<user> image list`. From an administrator terminal, that works. The reverse, `wslc --session wslc-cli-admin-<user> image list` from a normal terminal, fails with `ERROR_ELEVATION_REQUIRED`.

</details>

5. You pulled `nginx` in a normal terminal, and a build script run as administrator pulls it again. Give two ways to avoid the duplicate download.

<details>
<summary>Solution</summary>

The best one: run the script from a non-elevated terminal, since `wslc` doesn't need elevation, and everything lands in `wslc-cli-<user>`. If the script must run elevated for another reason, make its `wslc` commands target the normal session explicitly with `wslc --session wslc-cli-<user> …`, which an administrator is allowed to do. Otherwise both sessions keep their own copy, in two `storage.vhdx` files.

</details>

## Sources

- [Get started with containers on WSL — Microsoft Learn](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers)
- [nginx — Docker Hub](https://hub.docker.com/_/nginx)
- [curl](https://curl.se/)
