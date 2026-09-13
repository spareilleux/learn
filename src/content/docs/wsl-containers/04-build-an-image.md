---
title: 4. Building an image
description: Write a Containerfile, build the image, read the logs and clean up.
sidebar:
  order: 4
---

## Where to keep the code

:::tip[Performance]
Keep the code on the **same file system as the tools** that read it. For Linux tools, work inside the distro (for example `~/projects` under Ubuntu) rather than on `C:\`: accessing Windows files from Linux is significantly slower.
:::

With VS Code, the **WSL** extension lets you edit the project on the Linux side and use the integrated terminal.

## The Containerfile

A `Containerfile` (same syntax as a `Dockerfile`) describes how to build the image. Example for a small Django application:

```dockerfile
FROM python:3
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```

| Instruction | Role |
|---|---|
| `FROM` | base image |
| `WORKDIR` | working directory in the image |
| `COPY` | copies the project files |
| `RUN` | command run **during the build** |
| `EXPOSE` | documents the listening port |
| `CMD` | command run **when the container starts** |

:::note[Why copy `requirements.txt` first?]
Each instruction produces a cached layer. As long as `requirements.txt` doesn't change, `pip install` isn't rerun, even if the rest of the code changes.
:::

## Building and running

```powershell
# From the folder that contains the Containerfile
wslc build -t helloworld-django .
wslc image list

wslc run -d --rm -p 8000:8000 --name django helloworld-django
wslc container list
wslc container logs django
```

Open `http://localhost:8000/` in a Windows browser. To prove the application is really running on Linux:

```powershell
wslc exec django uname    # → Linux
wslc container stop django
```

## Diagnosing

```powershell
wslc container inspect <container>
wslc container logs <container>
wslc image inspect <image>
```

## Freeing up disk space

```powershell
wslc container prune   # removes stopped containers
wslc image prune       # removes unused images
```

## Key takeaways

- `RUN` runs at build time, `CMD` at startup.
- `-t name` gives the image a name so you can reuse it.
- `logs` and `inspect` are the first things to reach for when a container doesn't behave as expected.

## Exercises

1. Write a minimal `Containerfile` that serves a static folder with `nginx`.

<details>
<summary>Solution</summary>

```dockerfile
FROM nginx
COPY site/ /usr/share/nginx/html/
```

```powershell
wslc build -t my-site .
wslc run -d --rm -p 8080:80 --name my-site my-site
curl localhost:8080
```

</details>

2. The `django` container stops immediately after `run`. Which commands should you run, and in what order?

<details>
<summary>Solution</summary>

Do **not** use `--rm` while diagnosing, otherwise the container disappears along with its logs.

```powershell
wslc run -d -p 8000:8000 --name django helloworld-django
wslc container list --all        # container status
wslc container logs django       # application error message
wslc container inspect django    # effective configuration (command, ports…)
```

</details>
