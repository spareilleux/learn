---
title: 3. Primeros contenedores
description: Ejecutar, publicar, inspeccionar y detener contenedores con wslc.
sidebar:
  order: 3
---

:::caution[Usa una terminal sin elevar]
`wslc` no necesita derechos de administrador. Una terminal elevada usa una **sesión diferente** (`wslc-cli-admin-<user>` en lugar de `wslc-cli-<user>`), con sus propias imágenes, contenedores, volúmenes y redes: una imagen descargada en una no es visible en la otra. La sección [Una sesión por nivel de privilegio](#una-sesión-por-nivel-de-privilegio) más abajo lo muestra.
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

Aquí 15.62 GiB, porque la sesión está limitada a 16 GB en `settings.yaml` (ver la [lección 6](../06-resources-and-limits/)).

:::note[Si conoces Docker]
Estos comandos son casi idénticos a `docker run`, `docker exec`, etc. Los subcomandos están agrupados (`wslc container list`, `wslc image list`), pero los atajos al estilo de Docker también existen: `wslc ps`, `wslc images`, `wslc rmi`, `wslc logs`.
:::

## Una sesión por nivel de privilegio

`wslc` no habla con un único motor para toda la máquina como Docker Desktop. Crea una **sesión**, con su propia VM, su motor y su disco virtual, para cada usuario **y cada nivel de privilegio**. La trampa aparece la primera vez que abres una terminal de administrador: en un `cmd.exe` elevado recién abierto, `wslc run --rm hello-world` descargó la imagen **otra vez**, aunque ya se había descargado desde una terminal normal:

```text
Image 'hello-world' not found, pulling
```

`wslc info` explica por qué:

```text
Sessions: 2
ID   Creator PID   Display Name
1    144356        wslc-cli-spare
2    394856        wslc-cli-admin-spare
```

`wslc-cli-<user>` es la sesión de las terminales sin elevar, `wslc-cli-admin-<user>` la de las terminales de administrador. Para ver qué está realmente separado, la prueba creó un volumen y una red en la terminal normal, y luego eliminó allí la imagen:

```powershell
wslc volume create sesstest-vol
wslc network create sesstest-net
wslc image remove hello-world
wslc images    # vacío
```

En la terminal de administrador, la imagen eliminada sigue ahí, mientras que el volumen y la red nuevos no están, e incluso las redes predeterminadas tienen otros ID:

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

La opción global `--session` elige otra sesión. Va **antes** del subcomando; después de él, `wslc` responde `Option name was not recognized`. El acceso es asimétrico:

```text
# sin elevar → sesión admin
> wslc --session wslc-cli-admin-spare image list
The requested operation requires elevation.
Error code: ERROR_ELEVATION_REQUIRED

# administrador → sesión sin elevar: funciona
> wslc --session wslc-cli-spare volume list
DRIVER   VOLUME NAME
guest    sesstest-vol
```

En disco, cada sesión tiene sus propios discos virtuales, de algo menos de 600 MB cada uno en ese momento:

```text
%LocalAppData%\wslc\sessions\wslc-cli-spare\storage.vhdx         ~587 MB
%LocalAppData%\wslc\sessions\wslc-cli-spare\swap.vhdx            36 MB
%LocalAppData%\wslc\sessions\wslc-cli-admin-spare\storage.vhdx   ~577 MB
%LocalAppData%\wslc\sessions\wslc-cli-admin-spare\swap.vhdx      36 MB
```

Limpieza, en la terminal normal: `wslc volume remove sesstest-vol` y `wslc network remove sesstest-net`. La regla simple: `wslc` nunca necesita elevación, así que usa siempre una terminal sin elevar.

## Puntos clave

- `run` crea **e** inicia un contenedor; `--rm` evita acumular contenedores detenidos.
- `-p host:container` hace que un servicio sea accesible desde Windows, en `127.0.0.1`.
- `exec` ejecuta un comando en un contenedor **ya en ejecución**.
- Siempre el mismo tipo de terminal (sin elevar): cada nivel de privilegio tiene su propia sesión, con sus propias imágenes, contenedores, volúmenes, redes y disco.
- `--session <name>` va antes del subcomando; un administrador puede llegar a la sesión normal, no al revés.

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

4. En un PowerShell de administrador, escribes `wslc image list --session wslc-cli-<user>` y obtienes `Option name was not recognized`. Corrige el comando. ¿Funcionaría el mismo comando desde una terminal normal con el nombre de la sesión de administrador?

<details>
<summary>Solución</summary>

`--session` es una opción global y va antes del subcomando: `wslc --session wslc-cli-<user> image list`. Desde una terminal de administrador, eso funciona. Lo contrario, `wslc --session wslc-cli-admin-<user> image list` desde una terminal normal, falla con `ERROR_ELEVATION_REQUIRED`.

</details>

5. Descargaste `nginx` en una terminal normal, y un script de compilación ejecutado como administrador lo descarga otra vez. Da dos formas de evitar la descarga duplicada.

<details>
<summary>Solución</summary>

La mejor: ejecutar el script desde una terminal sin elevar, ya que `wslc` no necesita elevación, y todo acaba en `wslc-cli-<user>`. Si el script tiene que ejecutarse elevado por otro motivo, haz que sus comandos `wslc` apunten explícitamente a la sesión normal con `wslc --session wslc-cli-<user> …`, algo que un administrador tiene permitido. Si no, cada sesión guarda su propia copia, en dos archivos `storage.vhdx`.

</details>

## Fuentes

- [Introducción a los contenedores en WSL — Microsoft Learn](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers)
- [nginx — Docker Hub](https://hub.docker.com/_/nginx)
- [curl](https://curl.se/)
