---
title: 3. Primeros contenedores
description: Ejecutar, publicar, inspeccionar y detener contenedores con wslc.
sidebar:
  order: 3
---

:::caution[Usa una terminal sin elevar]
`wslc` no necesita derechos de administrador. Una terminal elevada usa una **sesión diferente** (`wslc-cli-admin-<user>` en lugar de `wslc-cli-<user>`), con sus propias imágenes, contenedores, volúmenes y redes: una imagen descargada en una no es visible en la otra. Detalles en el [diario](../journal/).
:::

## Orientarse en la CLI

```powershell
wslc --help                # todos los comandos
wslc <COMMAND> --help      # ayuda de un comando
wslc image list            # imágenes disponibles localmente
wslc container list        # contenedores en ejecución
wslc container list --all  # incluidos los contenedores detenidos
wslc stats                 # uso de CPU / memoria de los contenedores en ejecución
```

## Un contenedor desechable

```powershell
wslc run --rm -it ubuntu:latest bash -c "echo Hello world from WSL container!"
```

```text
...
Status: Downloaded newer image for ubuntu:latest
Hello world from WSL container!
```

| Opción | Efecto |
|---|---|
| `--rm` | elimina el contenedor en cuanto se detiene |
| `-it` | modo interactivo con una terminal |
| `ubuntu:latest` | la imagen (se descarga automáticamente si falta) |
| `bash -c "…"` | el comando que se ejecuta en el contenedor |

## Un servidor web en segundo plano

```powershell
# Ejecutar nginx en segundo plano, puerto 8080 de Windows → puerto 80 del contenedor
wslc run -d --rm -p 8080:80 --name web nginx

# Consultar el servidor desde Windows
curl.exe -s -o NUL -w "%{http_code}`n" http://127.0.0.1:8080/

# Ver el contenedor
wslc container list

# Ejecutar un comando en el contenedor en ejecución
wslc exec web cat /etc/os-release

# Uso de recursos (una instantánea, y luego el comando termina)
wslc stats

# Detenerlo (y, gracias a --rm, eliminarlo)
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

| Opción | Efecto |
|---|---|
| `-d` | separado (detached): el contenedor se ejecuta en segundo plano |
| `-p 8080:80` | publica el puerto: `host:container` |
| `--name web` | nombre legible, utilizable en lugar del ID |

:::caution[`127.0.0.1` en lugar de `localhost`]
`wslc` publica solo en `127.0.0.1` (ver la columna `PORTS`). Si Docker Desktop también publica el puerto 8080, escucha en `0.0.0.0` **y** en `[::]`: `localhost` se resuelve primero como `::1` y llega al contenedor de Docker, sin error en ninguno de los dos lados. Usa `127.0.0.1` explícitamente. Y llama a `curl.exe`: en Windows PowerShell 5.1, `curl` es un alias de `Invoke-WebRequest`.
:::

`wslc stats` muestra el límite de la sesión en la columna `MEM USAGE / LIMIT`:

```text
CONTAINER ID   NAME   CPU %   MEM USAGE / LIMIT     MEM %   NET I/O     BLOCK I/O     PIDS
1e72dbeb2a9a   site   0.00%   8.801MiB / 15.62GiB   0.06%   736B / 0B   0B / 8.19kB   9
```

Aquí 15.62 GiB, porque la sesión está limitada a 16 GB en `settings.yaml` (ver el [diario](../journal/)).

:::note[Si conoces Docker]
Estos comandos son casi idénticos a `docker run`, `docker exec`, etc. Los subcomandos están agrupados (`wslc container list`, `wslc image list`), pero los atajos al estilo de Docker también existen: `wslc ps`, `wslc images`, `wslc rmi`, `wslc logs`.
:::

## Puntos clave

- `run` crea **e** inicia un contenedor; `--rm` evita acumular contenedores detenidos.
- `-p host:container` hace que un servicio sea accesible desde Windows, en `127.0.0.1`.
- `exec` ejecuta un comando en un contenedor **ya en ejecución**.
- Siempre el mismo tipo de terminal (sin elevar): cada nivel de privilegio tiene su propia sesión.

## Ejercicios

1. Ejecuta un contenedor `nginx` accesible en el puerto **9090** de Windows, llamado `site`, y comprueba que responde.

<details>
<summary>Solución</summary>

```powershell
wslc run -d --rm -p 9090:80 --name site nginx
curl.exe -s -o NUL -w "%{http_code}`n" http://127.0.0.1:9090/
wslc container stop site
```

`200` significa que nginx respondió.

</details>

2. ¿Cómo saber qué distribución Linux usa la imagen `nginx` sin abrir un shell interactivo?

<details>
<summary>Solución</summary>

```powershell
wslc run -d --rm --name site nginx
wslc exec site cat /etc/os-release
wslc container stop site
```

En septiembre de 2026, `nginx:latest` se basa en `Debian GNU/Linux 13 (trixie)`.

</details>

3. ¿Cuál es la diferencia entre `wslc container list` y `wslc container list --all`?

<details>
<summary>Solución</summary>

Sin `--all`, solo se listan los contenedores **en ejecución**. Con `--all`, también aparecen los contenedores detenidos (pero no eliminados).

</details>

## Fuentes

- [Introducción a los contenedores en WSL — Microsoft Learn](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers)
- [nginx — Docker Hub](https://hub.docker.com/_/nginx)
- [curl](https://curl.se/)
