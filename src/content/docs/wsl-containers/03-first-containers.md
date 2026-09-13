---
title: 3. First containers
description: Run, publish, inspect and stop containers with wslc.
sidebar:
  order: 3
---

## Finding your way around the CLI

```powershell
wslc --help              # all commands
wslc <COMMAND> --help    # help for a command
wslc image list          # images available locally
wslc container list      # running containers
wslc container list --all  # including stopped containers
wslc stats               # container CPU / memory usage
```

## A throwaway container

```powershell
wslc run --rm -it ubuntu:latest bash -c "echo Hello world from WSL container!"
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
curl localhost:8080

# See the container
wslc container list

# Run a command in the running container
wslc exec web cat /etc/os-release

# Stop it (and, thanks to --rm, remove it)
wslc container stop web
```

| Option | Effect |
|---|---|
| `-d` | detached: the container runs in the background |
| `-p 8080:80` | publishes the port: `host:container` |
| `--name web` | readable name, usable instead of the ID |

:::note[If you know Docker]
These commands are almost identical to `docker run`, `docker exec`, etc. The main visible difference: subcommands are grouped (`wslc container list` rather than `docker ps`).
:::

## Key takeaways

- `run` creates **and** starts a container; `--rm` avoids piling up stopped containers.
- `-p host:container` makes a service reachable from Windows.
- `exec` runs a command in an **already running** container.

## Exercises

1. Run an `nginx` container reachable on Windows port **9090**, named `site`, then check that it responds.

<details>
<summary>Solution</summary>

```powershell
wslc run -d --rm -p 9090:80 --name site nginx
curl localhost:9090
wslc container stop site
```

</details>

2. How can you find out which Linux distribution the `nginx` image uses without opening an interactive shell?

<details>
<summary>Solution</summary>

```powershell
wslc run -d --rm --name site nginx
wslc exec site cat /etc/os-release
wslc container stop site
```

</details>

3. What is the difference between `wslc container list` and `wslc container list --all`?

<details>
<summary>Solution</summary>

Without `--all`, only **running** containers are listed. With `--all`, stopped (but not removed) containers appear as well.

</details>
