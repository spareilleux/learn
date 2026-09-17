---
title: Diario
description: Notas de progreso fechadas — intentos, errores y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Entender qué es WSL containers y qué versión requiere
- [x] Instalar WSL ≥ 2.9.3 (pre-release)
- [x] `wslc run --rm hello-world`
- [x] Lección 3: contenedores, puertos, `exec`
- [x] Lección 4: construir una imagen
- [x] Ejecutar un servicio existente (qdrant) con `wslc`
- [x] Probar Compose
- [x] Comprobar si las imágenes de Docker y de `wslc` se comparten
- [x] Pequeño programa C# con `Microsoft.WSL.Containers`
- [x] Ir más allá: `WslcImage`, red de la API, Kubernetes, extensiones, interfaz gráfica
- [x] Lote 2: lecciones 6 a 10 escritas a partir de las entradas de abajo, lecciones 1 a 5 ampliadas

## 2026-09-12 — Estado de la situación

- Máquina: Windows 11 Pro build 26200, WSL **2.6.3**.
- Distros WSL ya presentes: `docker-desktop` (Docker Desktop 4.61) y `podman-machine-default`.
- Últimas versiones de WSL en GitHub: estable **2.7.14**, pre-release **2.9.11**. Solo la pre-release incluye `wslc`.

**Incidente no directamente relacionado, pero instructivo:** Docker Desktop se cayó tres veces en pocos minutos («wsl-bootstrap stopped with exit code 1, did wsl shutdown?»). Al mismo tiempo, `wsl -l -v` fallaba con:

```text
Not enough memory resources are available to complete this operation.
Error code: Wsl/0x8007000e
```

Memoria comprometida: 97 GB de 132 GB. Hipótesis: demasiadas VM y procesos pesados al mismo tiempo (Docker + Kubernetes, Podman, ollama, rust-analyzer…). Pista: limitar la memoria de WSL en `%UserProfile%\.wslconfig` (`memory=24GB`).

## 2026-09-13 — Primer intento de actualización: fracaso

```powershell
wsl --update --pre-release
# Updating Windows Subsystem for Linux to version: 2.9.11.
```

El comando terminó sin ningún error visible, pero `wsl --version` seguía mostrando **2.6.3**.

En el registro de Windows (`MsiInstaller`):

```text
Error 1921. Service 'WSL Service' (WSLService) could not be stopped.
Product: Windows Subsystem for Linux -- Installation failed.   (status 1603)
```

**Lección:** no fiarse de la ausencia de un mensaje de error; comprobar la versión después. El servicio WSL estaba retenido por Docker Desktop, Podman y varios procesos `wsl.exe`.
Corrección prevista: detenerlo todo, `wsl --shutdown`, `Stop-Service WSLService` como administrador y volver a lanzar la actualización. → detallado en la [lección 2](../02-installation/).

## 2026-09-13 — Segundo intento: WSL 2.9.11 instalado

Aplicada la corrección prevista. Desde una terminal normal (sin elevación):

```powershell
docker desktop stop
podman machine stop
wsl --shutdown
wsl -l -v   # podman-machine-default y docker-desktop: Stopped
```

Después, en un PowerShell de **administrador**:

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

Esta vez el servicio sí estaba detenido antes de que se ejecutara el instalador, y la versión cambió. `wslc.exe` se instala en `C:\Program Files\WSL\`, que ya está en el `PATH` de la máquina, pero las terminales abiertas antes de la actualización no lo ven: abre una nueva (o llama a la ruta completa).

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

**No te dejes engañar:** «Hello from Docker!» es solo el texto incluido en la imagen `hello-world`. Docker Desktop estuvo detenido todo el tiempo; el contenedor se ejecutó con `wslc`.

`wslc info` muestra un archivo de configuración en `%LocalAppData%\wslc\settings.yaml` y una sesión llamada `wslc-cli-<user>`. `wslc images` solo lista `hello-world` (10.1 kB).

**Pendiente:** reiniciar Docker Desktop y Podman y comprobar que Docker Desktop 4.61 sigue funcionando con WSL 2.9.11. (Docker Desktop: OK, ver «Preguntas abiertas restantes» más abajo. Podman 5.8.3: `podman machine start` OK, `podman run --rm quay.io/podman/hello` OK; advierte de que la pipe por defecto de la API de Docker ya la ocupa Docker Desktop y expone la suya propia, `npipe:////./pipe/podman-machine-default`.)

## 2026-09-13 — Reproducir hello-world a mano: dos trampas

### Trampa 1: `wslc` «no reconocido» en una pestaña nueva

```text
PS C:\Users\spare\source\repos> Get-Command wslc
Get-Command : The term 'wslc' is not recognized as the name of a cmdlet, function, script file, or operable program.
```

`wslc.exe` estaba instalado y `C:\Program Files\WSL\` estaba en el `PATH` de la máquina, pero un programa recibe una *copia* de las variables de entorno al arrancar. Windows Terminal llevaba abierto desde el 2026-09-11, antes de la actualización, y la nueva pestaña heredó su `PATH` antiguo.

Soluciones, de la más rápida a la más duradera:

```powershell
# Recargar el PATH en el PowerShell actual (solo esta terminal)
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
```

- o llamar a la ruta completa: `& "C:\Program Files\WSL\wslc.exe" --version`;
- o cerrar **todas** las ventanas de Windows Terminal (que no quede ningún `WindowsTerminal.exe`) y volver a abrirlo, o iniciar una terminal desde `Win + R`.

En `cmd.exe`, el equivalente de `Get-Command` es `where wslc`.

### Trampa 2: una terminal de administrador no ve las mismas imágenes

En un `cmd.exe` recién abierto (en `C:\Windows\System32`, señal de una terminal elevada), `wslc run --rm hello-world` descargó la imagen **otra vez**, aunque ya se había descargado desde una terminal sin elevación:

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

`wslc` crea una sesión por usuario **y por nivel de privilegio**: `wslc-cli-<user>` sin elevación, `wslc-cli-admin-<user>` como administrador. La imagen descargada en una sesión no se encontraba en la otra.

**Lección:** `wslc` no necesita elevación. Usa siempre una terminal sin elevación; si no, las imágenes y los contenedores acaban en una sesión separada.

### Verificación: qué está separado y quién ve qué

Terminal sin elevación: crear un volumen y una red, y luego eliminar la imagen.

```powershell
wslc volume create sesstest-vol
wslc network create sesstest-net
wslc image remove hello-world
wslc images    # vacío
```

Terminal de administrador:

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

- La imagen eliminada en la sesión sin elevación **sigue ahí** en la sesión admin.
- El volumen y la red creados en la sesión sin elevación **no aparecen** en la sesión admin. Incluso las redes por defecto `bridge`/`host`/`none` tienen ID distintos: cada sesión ejecuta su propio motor.

La opción global `--session` va **antes** del subcomando (`wslc --session <name> image list`; después: `Option name was not recognized`). El acceso es asimétrico:

```text
# sin elevación → sesión admin
> wslc --session wslc-cli-admin-spare image list
The requested operation requires elevation.
Error code: ERROR_ELEVATION_REQUIRED

# administrador → sesión sin elevación: funciona
> wslc --session wslc-cli-spare volume list
DRIVER   VOLUME NAME
guest    sesstest-vol
```

En disco, cada sesión tiene sus propios discos virtuales:

```text
%LocalAppData%\wslc\sessions\wslc-cli-spare\storage.vhdx         ~587 MB
%LocalAppData%\wslc\sessions\wslc-cli-spare\swap.vhdx            36 MB
%LocalAppData%\wslc\sessions\wslc-cli-admin-spare\storage.vhdx   ~577 MB
%LocalAppData%\wslc\sessions\wslc-cli-admin-spare\swap.vhdx      36 MB
```

Limpieza: `wslc volume remove sesstest-vol`, `wslc network remove sesstest-net`.

## 2026-09-13 — Limitar la CPU y la memoria de una sesión `wslc`

`wslc settings` crea `%LocalAppData%\wslc\settings.yaml` en la primera ejecución (con todos los ajustes comentados) y lo abre en el editor por defecto. La parte relevante:

```yaml
session:
  # Number of virtual CPUs allocated to the session (e.g. 4 default: all available CPUs)
  # cpuCount: default

  # Memory limit for the session (e.g. 2GB default: half of available memory)
  # memorySize: default
```

El mismo archivo tiene también `maxStorageSize` (por defecto 1 TB), `storagePath` (donde se crea `wslc\sessions\<session>\storage.vhdx`), `defaultBindingAddress` (por defecto `127.0.0.1` para `-p`), `hostLoopback` (`host.wslc.internal`) e `idleTimeout` (30 s). Fuente: el archivo generado, <https://aka.ms/wslc-settings>. El equivalente en la API es `SessionSettings.CpuCount` / `MemoryMB` ([Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container)).

**Medición.** Anfitrión: 24 CPU lógicas, 63.7 GB de RAM.

```powershell
wslc run --rm alpine sh -c "echo nproc=`$(nproc); free -m"
```

| Ajustes | `nproc` | RAM (`free -m`) | Swap |
|---|---|---|---|
| valores por defecto | 24 | 31946 MB | 32617 MB |
| `cpuCount: 4`, `memorySize: 4GB` | 4 | 3919 MB | 4096 MB |

El swap sigue a `memorySize`.

**Trampa: el cambio no se aplica a una sesión en ejecución.** La primera medición tras editar el archivo seguía mostrando 24 CPU. Hay que terminar la sesión; el siguiente comando `wslc` inicia una nueva con los nuevos ajustes:

```powershell
wslc --session wslc-cli-spare system session terminate
```

(`wslc system session terminate wslc-cli-spare`, con el nombre como argumento, falla: `Found a positional argument when none was expected`.)

4 GB se queda corto para el resto del curso (qdrant). Ajuste conservado en esta máquina, dado el incidente de memoria del 2026-09-12: `cpuCount: 8`, `memorySize: 16GB` → `nproc=8`, RAM 15996 MB, swap 16384 MB.

### Verificación: sesión admin y memoria del lado de Windows

**La sesión admin lee el mismo archivo.** En una terminal de administrador, `wslc info` muestra el mismo `Settings file: C:\Users\spare\AppData\Local\wslc\settings.yaml`. Tras terminar la sesión admin:

```text
> wslc --session wslc-cli-admin-spare system session terminate
> wslc run --rm alpine sh -c 'echo nproc=$(nproc); free -m'
nproc=8
Mem:          15996 ...
Swap:         16384 ...
```

**Del lado de Windows, la VM de cada sesión es un proceso llamado `vmmem<session>`** (`vmmemwslc-cli-spare`, `vmmemwslc-cli-admin-spare`); `hcsdiag list` (administrador) la muestra como una VM `Running` con el nombre de la sesión. Sus cifras de memoria solo se pueden leer desde una terminal elevada.

Prueba: un contenedor que retiene 6 GB durante dos minutos, en la sesión sin elevación.

```powershell
wslc run -d --name memtest alpine sh -c 'apk add -q stress-ng && stress-ng --vm 1 --vm-bytes 6G --vm-hang 0 --timeout 120s'
```

| Momento | Proceso de la VM | Working set | Memoria privada |
|---|---|---|---|
| sesión inactiva (admin, nada en ejecución) | `vmmemwslc-cli-admin-spare` | 921 MB | 970 MB |
| 6 GB retenidos en el contenedor | `vmmemwslc-cli-spare` | 7069 MB | 7083 MB |
| 10 s después de `container stop` + `remove` | `vmmemwslc-cli-spare` | 2776 MB | 7084 MB |
| un poco más tarde | `vmmemwslc-cli-spare` | 902 MB | 1902 MB |

- Una VM de sesión inactiva cuesta unos **0.9 GB**.
- La memoria que usa el contenedor aparece casi entera del lado de Windows (~6 GB + la VM base).
- Cuando el contenedor se detiene, la memoria **no se devuelve de inmediato**: disminuye progresivamente.
- `memorySize` es un techo, no una reserva: la VM solo toma lo que usa.

Entre dos capturas, la VM de la sesión admin había desaparecido (nada en ejecución en ella): coherente con `idleTimeout` (30 s), medido más abajo.

## 2026-09-13 — Preguntas abiertas restantes

### ¿Cuándo se apaga una VM inactiva?

Ejecutar un contenedor y luego vigilar el proceso de la VM **sin ejecutar ningún comando `wslc`** (un comando `wslc` despierta la sesión):

```powershell
wslc run --rm alpine true
# luego, cada 5 s:
Get-Process -Name 'vmmemwslc-cli-spare' -ErrorAction SilentlyContinue
```

```text
    0s  VM running: True
   35s  VM running: False
```

La VM se detiene **entre 30 y 35 s** después del último comando (sondeo cada 5 s): es `idleTimeout: 30`. La sesión sigue listada por `wslc system session list`; solo se apaga la VM, y el siguiente comando la vuelve a iniciar.

### Docker Desktop con WSL 2.9.11

`docker desktop start` respondió `Docker Desktop is already running` cuando no existía ningún proceso de Docker Desktop, y `docker desktop status` respondió `Could not retrieve status`. Lanzar directamente `C:\Program Files\Docker\Docker\Docker Desktop.exe` funcionó: motor 29.2.1 listo tras ~130 s, `docker run --rm hello-world` OK. **Docker Desktop 4.61 funciona con WSL 2.9.11.**

### ¿Se comparten las imágenes de Docker y de `wslc`?

No. Tras `docker pull busybox`:

```text
> docker images            > wslc images
postgres:16-alpine          alpine   latest
busybox:latest
hello-world:latest
node:18-alpine
```

Cada herramienta tiene su propio almacén (`docker_data.vhdx` ≈ 50 GB para Docker, un `storage.vhdx` por sesión para `wslc`). Una imagen que usan las dos se descarga dos veces.

### ¿Pueden `wslc` y Docker Desktop publicar el mismo puerto?

Prueba: `nginx` en `wslc`, `httpd` (Apache, «It works!») en Docker, para que la respuesta indique cuál contesta.

```powershell
wslc run -d --name webwslc -p 8080:80 nginx
docker run -d --name webdocker -p 8080:80 httpd
curl.exe http://127.0.0.1:8080/   # nginx  → wslc
curl.exe http://localhost:8080/   # It works! → Docker
```

**Los dos arrancan sin ningún error: el conflicto es silencioso.** Windows acepta los dos listeners porque no se enlazan exactamente a la misma dirección:

```text
TCP  0.0.0.0:8080     LISTENING  com.docker.backend
TCP  [::]:8080        LISTENING  com.docker.backend
TCP  127.0.0.1:8080   LISTENING  dllhost      ← wslc
TCP  [::1]:8080       LISTENING  wslrelay
```

`127.0.0.1` va a `wslc` (gana la dirección más específica), mientras que `localhost` se resuelve primero a `::1` y acaba en Docker. Mismo resultado en todas las variantes probadas:

| Variante | Errores | `127.0.0.1` | `localhost` |
|---|---|---|---|
| `wslc` primero, luego Docker (8080) | ninguno | wslc | Docker |
| Docker primero, luego `wslc` (8081) | ninguno | wslc | Docker |
| Docker, luego `wslc -p 0.0.0.0:8082:80` | ninguno | wslc | Docker |
| `wslc -p 0.0.0.0:8083:80`, luego Docker | ninguno | wslc | Docker |

**Lección:** no publiques el mismo puerto desde las dos herramientas. Nada te avisa, y la respuesta depende de si el cliente usa `127.0.0.1` o `localhost`.

### ¿Crece y se reduce `storage.vhdx`?

Tamaño de `%LocalAppData%\wslc\sessions\wslc-cli-spare\storage.vhdx`:

| Paso | Tamaño del archivo |
|---|---|
| inicio (`alpine`, `nginx`) | 814 MB |
| `wslc pull mcr.microsoft.com/dotnet/sdk:9.0` (869 MB) | 1070 MB |
| `wslc image remove` de esa imagen | 1070 MB |
| `wslc image prune --all` («Total reclaimed space: 178.5MB», no queda nada) | 1070 MB |
| `system session terminate` | 1070 MB |
| volver a descargar `dotnet/sdk:9.0` | 1070 MB |
| + `dotnet/aspnet:9.0` (224 MB) + `eclipse-temurin:21-jdk` (491 MB) | 1550 MB |

- El archivo **crece** cuando se añaden imágenes, y **nunca se reduce** por sí solo: ni `image remove`, ni `prune`, ni terminar la sesión devuelven espacio a Windows.
- El espacio liberado dentro se **reutiliza**: volver a descargar el SDK no hizo crecer el archivo.
- El crecimiento es menor que el tamaño de imagen mostrado (`SIZE` es el tamaño sin comprimir, y el espacio liberado se reutiliza), así que el tamaño del archivo no es un contador fiable de imágenes.

Trampa: en `wslc image prune`, `-f` significa `--filter`, no `--force`; `--force` no existe (`wslc image prune --all` no pide confirmación).

### Compactar `storage.vhdx`

Tras los builds de la lección 4, el archivo había crecido hasta **3995 MB**, mientras que `df` dentro de la sesión solo mostraba **1.9 GB** usados. Pasos:

```powershell
# 1. Detener la VM de la sesión (sin elevación) y comprobar que ha desaparecido
wslc --session wslc-cli-spare system session terminate
Get-Process -Name 'vmmemwslc-cli-spare' -ErrorAction SilentlyContinue   # nada

# 2. PowerShell de administrador (módulo Hyper-V): copia de seguridad y luego compactación
$f = "$env:LOCALAPPDATA\wslc\sessions\wslc-cli-spare\storage.vhdx"
Copy-Item $f "$f.bak"
Optimize-VHD -Path $f -Mode Full
```

```text
before: 3,995 MB
Optimize-VHD -Mode Full: OK in 10s
after: 2,789 MB
```

**1.2 GB devueltos a Windows en 10 segundos.** Comprobación antes de borrar la copia de seguridad: `wslc image list` sigue listando `csharp-api`, `java-reactor-api` y `alpine`, y las dos API siguen respondiendo tras `wslc run`.

- `Optimize-VHD` necesita una terminal de **administrador** y el módulo PowerShell **Hyper-V** (presente aquí).
- La VM de la sesión debe estar detenida: si no, el VHDX está en uso.
- El archivo sigue siendo más grande que el espacio usado dentro (2.8 GB frente a 1.9 GB): solo se recuperan los bloques totalmente libres.
- `fstrim` no está disponible en la VM de la sesión: `wslc system session run fstrim -v /` → `Failed to launch command fstrim. Errno = 2`.

## 2026-09-13 — Lecciones 3 y 4 terminadas

- **Lección 3** (contenedores, puertos, `exec`): practicada a lo largo de las entradas anteriores — `nginx` publicado con `-p`, `exec`, `container list --all` y el conflicto de puertos con Docker Desktop.
- **Lección 4** (construir una imagen): reescrita con una API en C# y una API Spring Boot WebFlux, construidas y ejecutadas con `wslc`; todas las salidas de la lección son reales.

## 2026-09-13 — Ejecutar qdrant con `wslc`

### Antes de empezar: ya hay un qdrant en ejecución en Docker

```text
> docker ps
ga-qdrant  qdrant/qdrant:latest  Up About an hour (healthy)  0.0.0.0:6333-6334->6333-6334/tcp, [::]:6333-6334->6333-6334/tcp
```

Publicar `wslc` también en el 6333 arrancaría **sin ningún error** y le quitaría en silencio `127.0.0.1:6333` a la aplicación que usa `ga-qdrant` (ver el conflicto de puertos más arriba). Así que el qdrant de `wslc` se publica en **16333/16334**.

### Pull: misma etiqueta, versión distinta

```powershell
wslc pull qdrant/qdrant    # 21 s, 198 MB
```

La imagen de Docker ya estaba ahí, pero `wslc` la vuelve a descargar (almacenes separados). Y `latest` no es la misma versión en los dos lados:

```text
> curl.exe http://127.0.0.1:16333/     # wslc
{"title":"qdrant - vector search engine","version":"1.19.1","commit":"6ab21cac18ebb6f4ae29102c7f8f5cc11affd5de"}
> curl.exe http://127.0.0.1:6333/      # Docker (ga-qdrant, descargada el 2025-12-19)
{"title":"qdrant - vector search engine","version":"1.16.3","commit":"bd49f45a8a2d4e4774cac50fa29507c4e8375af2"}
```

**Lección:** `latest` significa «lo que era lo último cuando *esta* herramienta lo descargó». Fija una versión (`qdrant/qdrant:v1.19.1`) cuando dos entornos deban coincidir.

### Ejecución con un volumen

```powershell
wslc volume create qdrant-data
wslc run -d --name qdrant -p 16333:6333 -p 16334:6334 -v qdrant-data:/qdrant/storage qdrant/qdrant
curl.exe http://127.0.0.1:16333/readyz    # all shards are ready (tras 1 s)
```

```text
CONTAINER ID   IMAGE           COMMAND             CREATED         STATUS        PORTS                                                  NAMES
da52872e3246   qdrant/qdrant   "./entrypoint.sh"   5 seconds ago   Up 1 second   127.0.0.1:16333->6333/tcp, 127.0.0.1:16334->6334/tcp   qdrant
```

Trampa: el log dice `Access web UI at http://localhost:6333/dashboard`. Ese es el puerto **dentro** del contenedor. Desde Windows, el dashboard está en `http://127.0.0.1:16333/dashboard`, y `localhost:6333` abriría el de Docker.

Una colección, tres puntos y una consulta (cuerpos en archivos JSON, para evitar problemas de comillas en PowerShell):

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

### Persistencia: eliminar el contenedor, conservar los datos

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

La colección y sus 3 puntos sobreviven, porque viven en el volumen. `wslc volume inspect qdrant-data` muestra `"Driver": "guest"` y un punto de montaje dentro de la VM de la sesión (`/var/lib/docker/volumes/qdrant-data/_data`), es decir, en el `storage.vhdx` de la sesión.

### No montar una carpeta de Windows para el almacenamiento de qdrant

```powershell
wslc run -d --name qdrant-bind -p 16335:6333 -v "C:\...\qdrant-bind:/qdrant/storage" qdrant/qdrant
wslc exec qdrant-bind sh -c "mount | grep /qdrant/storage"
```

```text
drvfs on /qdrant/storage type virtiofs (rw,relatime)
```

qdrant arranca igualmente y escribe sus archivos en la carpeta de Windows, pero registra un error:

```text
ERROR qdrant: Filesystem check failed for storage path ./storage. Details: FUSE filesystems may cause data corruption due to caching issues
```

**Lección:** para una base de datos, usa un **volumen** de `wslc` (dentro de la VM), no un bind mount de una carpeta de Windows.

### Recursos

```text
> wslc stats qdrant
CONTAINER ID   NAME     CPU %   MEM USAGE / LIMIT     MEM %   NET I/O           BLOCK I/O        PIDS
da52872e3246   qdrant   0.16%   47.21MiB / 15.62GiB   0.30%   10.1kB / 5.77kB   8.19kB / 184kB   35
> docker stats ga-qdrant --no-stream --format "CPU {{.CPUPerc}}  MEM {{.MemUsage}}"
CPU 0.41%  MEM 367.8MiB / 31.2GiB
```

- El límite mostrado es el de la VM: **15.62 GiB** para `wslc` (el ajuste `memorySize: 16GB`), **31.2 GiB** para Docker Desktop (la mitad de la RAM por defecto).
- 47 MiB para 3 puntos frente a 368 MiB para `ga-qdrant`: no es comparable, `ga-qdrant` contiene datos reales.
- Del lado de Windows, la VM `vmmemwslc-cli-spare` estaba en 1160 MB (unos 0.9 GB en reposo, medido antes).
- qdrant registra `starting 7 workers`: ve las 8 CPU permitidas por `cpuCount: 8`.

Limpieza: `wslc container stop qdrant qdrant-bind`, `wslc container remove qdrant qdrant-bind`, `wslc volume remove qdrant-data`. `ga-qdrant` no se tocó en ningún momento.

## 2026-09-13 — Compose con `wslc`

### Ningún comando `compose`

```text
> wslc compose --help
Unrecognized command: 'compose'
```

`wslc --help` no lista ningún equivalente de Compose, y el [tutorial oficial](https://learn.microsoft.com/windows/wsl/tutorials/wsl-containers) no lo menciona. `wslc` 2.9.11 **no admite Compose**.

### Callejón sin salida: conectar `docker compose` al motor de la sesión

La VM de la sesión sí ejecuta un motor Docker:

```text
> wslc system session run ps -eo pid,args
  131 /usr/bin/containerd --address /run/containerd/containerd.sock --root /var/lib/docker/containerd/daemon --state /run/docker/containerd/daemon
  132 /usr/bin/dockerd --containerd /run/containerd/containerd.sock
> wslc system session run ls -la /var/run/docker.sock
srw-rw---- 1 root docker 0 Sep 13 18:47 /var/run/docker.sock
```

Pero nada lo expone a Windows (ninguna named pipe de `wslc`), el propio cliente `docker` de la VM falla (`wslc system session run docker version` → `The handle is invalid. Error code: ERROR_INVALID_HANDLE`), y no se puede montar en un contenedor `docker:cli` (que incluye Compose v5.5.1):

```powershell
wslc run --rm -e DOCKER_HOST=unix:///var/run/docker.sock -v /var/run/docker.sock:/var/run/docker.sock docker:cli docker ps
```

```text
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

Por qué: el origen de `-v` es una ruta de **Windows**. `/var/run/docker.sock` se convirtió en `C:\var\run\docker.sock`, montado sobre `virtiofs`:

```text
drvfs on /run/docker.sock type virtiofs (rw,relatime)
```

**Trampa:** `wslc` **crea** un origen de bind mount que no existe. Esta prueba dejó una carpeta vacía `C:\var\run\docker.sock\` en Windows (eliminada después). `--mount type=bind,source=/var/run/docker.sock,...` se rechaza: `The bind source path must be absolute.`

### Lo que Compose aporta realmente, hecho a mano

`docker compose config` sobre un archivo de dos servicios muestra lo que Compose añade implícitamente: una red por proyecto, volúmenes con nombre y los nombres de servicio como nombres DNS. En una red creada con `wslc network create`, los nombres sí se resuelven:

```text
> wslc run --rm --network demo alpine wget -qO- http://qdrant:6333/
{"title":"qdrant - vector search engine","version":"1.19.1","commit":"6ab21cac18ebb6f4ae29102c7f8f5cc11affd5de"}
> wslc run --rm --network demo alpine wget -qO- http://vectors:6333/readyz      # --network-alias vectors
all shards are ready
> wslc run --rm alpine wget -qO- -T 5 http://qdrant:6333/                      # red por defecto
wget: bad address 'qdrant:6333'
```

El `compose.yaml` (validado con `docker compose -p wslcdemo config`):

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

Su traducción a `wslc`, `wslc-up.ps1`:

```powershell
# Equivalente de `docker compose -p wslcdemo up -d` para compose.yaml, con wslc
$project = 'wslcdemo'

# Lo que Compose crea implícitamente: una red por proyecto, volúmenes con nombre
wslc network create "${project}_default"
wslc volume create "${project}_qdrant-data"

# servicio qdrant (el nombre del servicio se convierte en un alias DNS en la red del proyecto)
wslc run -d --name "$project-qdrant-1" --network "${project}_default" --network-alias qdrant `
    -p 127.0.0.1:16333:6333 -v "${project}_qdrant-data:/qdrant/storage" qdrant/qdrant:v1.19.1

# servicio seed (depends_on solo ordena el arranque: curl reintenta hasta que qdrant responde)
wslc run --name "$project-seed-1" --network "${project}_default" --network-alias seed `
    curlimages/curl:8.16.0 --silent --show-error --retry 10 --retry-connrefused --retry-delay 1 `
    -X PUT http://qdrant:6333/collections/demo -H 'Content-Type: application/json' `
    -d '{"vectors":{"size":4,"distance":"Cosine"}}'
```

Y `wslc-down.ps1`:

```powershell
# Equivalente de `docker compose -p wslcdemo down --volumes`
$project = 'wslcdemo'
wslc container stop "$project-qdrant-1"
wslc container remove "$project-qdrant-1" "$project-seed-1"
wslc network remove "${project}_default"
wslc volume remove "${project}_qdrant-data"
```

Resultado de `wslc-up.ps1`:

```text
CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS                              PORTS                       NAMES
28be34e431f5   curlimages/curl:8.1…   "/entrypoint.sh --si…"   1 second ago    Exited (0) Less than a second ago                               wslcdemo-seed-1
c1f82d52d6ca   qdrant/qdrant:v1.19…   "./entrypoint.sh"        2 seconds ago   Up 1 second                         127.0.0.1:16333->6333/tcp   wslcdemo-qdrant-1
> wslc logs wslcdemo-seed-1
{"result":true,"status":"ok","time":0.409039704}
> curl.exe http://127.0.0.1:16333/collections
{"result":{"collections":[{"name":"demo"}]},"status":"ok","time":0.00004439}
```

Tras `wslc-down.ps1`: ningún contenedor, solo las redes por defecto `bridge`/`host`/`none`, ningún volumen.

**Conclusión:** para una stack pequeña, un script `wslc` reproduce lo que hace Compose (red, volúmenes, nombres DNS, orden de arranque). Lo que no ofrece: no lee `compose.yaml`, no hay `depends_on` con `condition: service_healthy`, no hay `up` basado en diferencias que solo recree lo que cambió, no hay `logs -f` sobre todos los servicios. Para proyectos Compose reales, Docker Desktop (o Podman) sigue siendo la herramienta.

## 2026-09-13 — Un programa C# con `Microsoft.WSL.Containers`

Objetivo: controlar un contenedor desde una aplicación Windows, sin `wslc.exe`. El código está en [`code/wsl-containers/wslc-host`](https://github.com/spareilleux/learn/tree/main/code/wsl-containers/wslc-host); la [lección 9](../09-csharp-api/) lo muestra.

### El extracto documentado no compila

Pegar el extracto de Microsoft Learn en un proyecto que referencia `Microsoft.WSL.Containers` 2.9.9 da cinco errores:

```text
error CS0103: The name 'ComponentFlags' does not exist in the current context
error CS0117: 'SessionSettings' does not contain a definition for 'MemoryMB'
error CS0117: 'ProcessSettings' does not contain a definition for 'CmdLine'
error CS0103: The name 'DeleteContainerFlags' does not exist in the current context
error CS1705: Assembly 'wslcsdkcs' with identity 'wslcsdkcs, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null' uses 'Microsoft.Windows.SDK.NET, Version=10.0.26100.79, Culture=neutral, PublicKeyToken=31bf3856ad364e35' which has a higher version than referenced assembly 'Microsoft.Windows.SDK.NET' with identity 'Microsoft.Windows.SDK.NET, Version=10.0.19041.38, Culture=neutral, PublicKeyToken=31bf3856ad364e35'
```

Los nombres reales se obtienen leyendo los tipos públicos de `wslcsdkcs.dll` con `MetadataLoadContext`:

| Microsoft Learn | Paquete 2.9.9 |
|---|---|
| `ComponentFlags GetMissingComponents()` | `IReadOnlyList<Component> GetMissingComponents()` (`VirtualMachinePlatform`, `WslPackage`, `SdkNeedsUpdate`) |
| `SessionSettings.MemoryMB` | `SessionSettings.MemorySizeInMB` |
| `ProcessSettings.CmdLine` | `ProcessSettings.CommandLine` (`IList<string>`) |
| `DeleteContainerFlags.None` | `DeleteContainerOption.None` / `Force` |

### `CS1705`: la versión del SDK de Windows

El paquete declara `net8.0-windows10.0.19041.0`, pero su `wslcsdkcs.dll` está compilado con `Microsoft.Windows.SDK.NET` 10.0.26100.79. Pasar a `net10.0-windows10.0.26100.0` no basta (el SDK elige la proyección 10.0.26100.38, mismo error); hay que forzar la versión. `10.0.26100.79` no existe en nuget.org (`NU1102`, la más cercana: `10.0.26100.80`):

```xml
<TargetFramework>net10.0-windows10.0.26100.0</TargetFramework>
<WindowsSdkPackageVersion>10.0.26100.80</WindowsSdkPackageVersion>
<RuntimeIdentifier>win-x64</RuntimeIdentifier>
```

### Primera ejecución

```text
WSL container service 2.9.11
Session started, storage in C:\Users\spare\AppData\Local\WslcHost
Image alpine:latest (8 MB)
Hello from 3.24.1 on 6.18.40.1-microsoft-standard-WSL2
Container b27dd2f80927 exited with code 0
```

7 s en total, incluida la descarga de alpine en una sesión nueva y vacía. El contenedor ve los límites de la sesión: `nproc` → `2`, `free -m` → `1907` MB en total para `MemorySizeInMB = 2048`.

### Dónde aparece la sesión de la aplicación

Mientras se ejecuta un contenedor de 20 segundos:

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

- La sesión es una sesión `wslc` normal: la misma VM `vmmem<session>`, visible y controlable desde la CLI con `--session`.
- Su disco está donde lo eligió la aplicación, `%LocalAppData%\WslcHost\storage.vhdx` (67 MB tras la descarga), no bajo `%LocalAppData%\wslc\sessions`. Sus límites vienen de `SessionSettings`, no de `settings.yaml` (8 CPU ahí, 2 vistas por el contenedor).
- Tras `session.Terminate()`, la sesión y su `vmmem` desaparecen de inmediato, sin el retardo de inactividad de 30 s de la CLI.

### Trampa: un `Start` fallido deja el contenedor atrás

Una ejecución lanzada desde Git Bash con `/bin/sh` como argumento: MSYS convierte la ruta en `C:/Program Files/Git/usr/bin/sh`, y `container.Start()` lanza:

```text
Unhandled exception. System.ArgumentException: The parameter is incorrect.

failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "C:/Program Files/Git/usr/bin/sh": stat C:/Program Files/Git/usr/bin/sh: no such file or directory: unknown
```

La siguiente ejecución falla en `CreateContainer`:

```text
Unhandled exception. System.Runtime.InteropServices.COMException (0x800700B7): Cannot create a file when that file already exists.

Conflict. The container name "/wslc-host-hello" is already in use by container "176a59b772bebfb974a8404150407157d49cc279cbe2f66c2d6e2788f9bfbadc". You have to remove (or rename) that container to be able to reuse that name.
```

El contenedor sobrevive al proceso en `storage.vhdx`. Dos correcciones en el programa: `Delete(DeleteContainerOption.Force)` en un `finally` y, al arrancar, `OpenContainer` + `Delete` de un contenedor sobrante (`COMException` si no hay ninguno). Verificado: contenedor sobrante eliminado (`Removed leftover container wslc-host-hello`), y luego un comando que no existe (`/nope`) ya no deja nada atrás.

**Conclusión:** la API funciona y es rápida, pero en versión preliminar su documentación va por detrás del paquete: nombres, versión del SDK. Compila primero y, en caso de duda, lee los tipos. En GitHub Actions los runners Windows no tienen el servicio WSL containers: la CI solo compila el programa.
## 2026-09-13 — Ir más allá: `WslcImage`, red, Kubernetes, interfaz gráfica

### Construir una imagen durante `dotnet build`

Los targets MSBuild del paquete (`build\Microsoft.WSL.Containers.common.targets`) añaden un elemento `WslcImage`: después de `Build`, ejecutan `wslc image build` y luego `wslc image save` hacia un `.tar` junto al programa. Proyecto de prueba:

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

Primera trampa, la misma que con la CLI: los targets llaman a `wslc` sin ruta, así que un terminal (o un IDE) abierto antes de instalar WSL no lo encuentra:

```text
error WSLC0001: The wslc CLI check failed: 'wslc --version' returned exit code 9009. Install WSL by running 'wsl --install --no-distribution', or set the WslcCliPath property to a specific wslc.exe path.
```

Con `-p:WslcCliPath="C:\Program Files\WSL\wslc.exe"` (o un terminal nuevo):

```text
  WSLC: Building image 'wslc-host/greeter:1.0'...
    | naming to docker.io/wslc-host/greeter:1.0
  WSLC: Saving image 'wslc-host/greeter:1.0' to 'bin\Debug\net10.0-windows10.0.26100.0\win-x64\greeter.tar'...
Build succeeded.
```

9 s, y un `greeter.tar` de 8,3 MB. La imagen se construye en la sesión de la CLI (`wslc-cli-spare`), donde se queda.

La construcción es incremental: el target compara los archivos de `Context` (y un archivo `wslc.greeter.options` que guarda las opciones) con el `.tar`:

| Cambio | `dotnet build` | `.tar` |
|---|---|---|
| ninguno | 1 s, ninguna línea `WSLC:` | sin cambios |
| `greet.sh` tocado | 2 s, reconstruida (caché de capas) | reescrito |
| `echo edited` añadido a `greet.sh` | 3 s, reconstruida | reescrito |
| ninguno | 2 s, ninguna línea `WSLC:` | sin cambios |

Cada cambio real deja la imagen anterior sin etiqueta (`<none>`) en la sesión de la CLI: para eso sirve la propiedad `WslcPruneAfterBuild`.

### Cargar el `.tar` en la sesión de la aplicación

`LoadImageAsync` (el equivalente de `wslc load`) conserva la etiqueta y el `ENTRYPOINT`; `CommandLine` pasa entonces argumentos al entrypoint, como `docker run image args`:

```csharp
await session.LoadImageAsync(Path.Combine(AppContext.BaseDirectory, "greeter.tar"));
// ... new ContainerSettings("wslc-host/greeter:1.0") con CommandLine = ["Claude"]
```

```text
before: 
load 427 ms
after: wslc-host/greeter:1.0
Hello Claude from an image built by dotnet build (alpine 3.24.1)
edited
exit 0
```

La cadena completa funciona, pues, sin registro: `dotnet build` produce la imagen, el `.tar` se distribuye con el programa y el programa lo carga en su propia sesión.

`ImportImageAsync` es otra cosa (el equivalente de `wslc import`): espera un sistema de archivos plano, como el que produce `wslc export`. Con el `.tar` de `image save` (un layout OCI que empieza por `blobs/sha256/…`), lo acepta, pero la imagen resultante no tiene entrypoint (`CommandLine = ["Claude"]` falla con `exec: "Claude": executable file not found in $PATH`) ni tampoco `/bin/sh`:

```text
failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "/bin/sh": stat /bin/sh: no such file or directory: unknown
```

Comprobado con la CLI: `wslc export` de un contenedor alpine, `wslc import`, y luego `wslc run --rm exptest/rootfs:1 /bin/cat /etc/alpine-release` → `3.24.1`; `image inspect` muestra `"Cmd": null` y `"Entrypoint": null`.

### Trampa: los contenedores de la API no tienen red por defecto

`container.Inspect()` muestra `"NetworkMode":"none"` cuando `ContainerSettings.NetworkingMode` no está definido, mientras que `wslc run` conecta al bridge. El mismo contenedor alpine, `ip -4 addr` y luego `wget` hacia internet:

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

La descarga de la imagen funciona igualmente (la hace la sesión, no el contenedor). Un servicio en contenedor que tenga que llamar al exterior, o que se publique con `PortMappings`, necesita `NetworkingMode = ContainerNetworkingMode.Bridged`.

### Kubernetes: no, ni siquiera k3s

`wslc` no tiene ningún comando de Kubernetes. Prueba con [k3s](https://k3s.io/) en un contenedor, como se hace con Docker (`--privileged`):

- La CLI no tiene opción `--privileged` ni `--cap-add` (`wslc run --help`). Sin ellas, `wslc run -d --name k3s-cli --tmpfs /run --tmpfs /var/run rancher/k3s:v1.36.4-k3s1 server` se detiene de inmediato:

  ```text
  time="2026-09-14T02:17:38Z" level=fatal msg="Error: failed to evacuate root cgroup: mkdir /sys/fs/cgroup/init: read-only file system"
  ```

- La API tiene `ContainerSettings.Privileged`. Con `Privileged = true`: el mismo error. Comparación de dos contenedores alpine en la misma sesión:

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

  Mismas capacidades (el conjunto por defecto de Docker), cgroups de solo lectura, las mismas 15 entradas en `/dev`: en una sesión sin privilegios de administrador, `Privileged` no tiene ningún efecto visible en la 2.9.11.

  La misma prueba **como administrador** (UAC, sesión limitada a 1 CPU y 1 GB, una comprobación más: `mount -t tmpfs none /mnt`):

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

  Tampoco hay diferencia, y `Inspect()` ni siquiera muestra un campo `Privileged`. Sin embargo, el flag existe en la cabecera C (`WSLC_CONTAINER_FLAG_PRIVILEGED = 0x00000004` en `wslcsdk.h`): declarado, pero no aplicado en la 2.9.11. No se volvió a intentar k3s.

### Extensiones e interfaz gráfica: ninguna

- `wslc --help` lista `container`, `image`, `network`, `registry`, `settings`, `system`, `volume` y los atajos al estilo Docker: ningún mecanismo de extensiones.
- `wslc settings` solo abre `settings.yaml` en el editor por defecto.
- La aplicación **WSL Settings** (la única aplicación de WSL en el menú Inicio junto a `WSL`) no tiene página de contenedores: sus páginas son `About`, `Developer`, `DistroManagement`, `DockerDesktopIntegration`, `FileSystem`, `General`, `GPUAcceleration`, `GUIApps`, `MemAndProc`, `Networking`, `NetworkingIntegration`, `OptionalFeatures`, `VSCodeIntegration`, `VSIntegration`, `WorkingAcrossFileSystems`.

**Conclusión:** la cadena `dotnet build` → `.tar` → `LoadImage` es lo más original del paquete, y funciona. Alrededor, `wslc` 2.9.11 sigue siendo un motor de ejecución: sin Compose, sin Kubernetes, sin extensiones, sin interfaz gráfica. Limpieza: imágenes de prueba eliminadas de la sesión de la CLI (`greeter`, `k3s`, `docker:cli`), `storage.vhdx` de las sesiones de prueba borrados (336 MB + 81 MB).

## 2026-09-16 — Lote 2: cinco lecciones nuevas

Las entradas de arriba contenían más material verificado del que enseñaban las cinco lecciones. Ahora tienen sus propias lecciones: [6. Recursos y límites](../06-resources-and-limits/), [7. Volúmenes y un servicio real](../07-volumes-and-a-real-service/), [8. Compose sin Compose](../08-compose/), [9. Controlar contenedores desde C#](../09-csharp-api/) y [10. Redes, Kubernetes e interfaz gráfica](../10-networking-kubernetes-gui/). La sección de la API pasó de la lección 5 a la lección 9; la lección 5 trata ahora de la convivencia con Docker Desktop. El `compose.yaml` y sus dos scripts `wslc` están en [`code/wsl-containers/compose`](https://github.com/spareilleux/learn/tree/main/code/wsl-containers/compose), y la CI ejecuta el `compose.yaml` con Docker Compose.

Se volvieron a hacer tres comprobaciones para estas lecciones, con `wslc` 2.9.11 y la sesión a 8 CPU y 16 GB.

`wslc run --help` lista, entre otros, los límites por contenedor y las comprobaciones de estado: `--cpus`, `-m`/`--memory`, `--health-cmd`, `--health-interval`, `--gpus`. Sigue sin haber `--privileged` ni `--cap-add`.

Los límites por contenedor configuran el grupo de control, pero `nproc` y `free` siguen mostrando la VM:

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

Un contenedor de la CLI tiene los mismos límites que los contenedores de la API de la prueba de `Privileged`:

```text
> wslc run --rm alpine sh -c 'grep cgroup /proc/mounts; grep CapEff /proc/self/status; ls /dev | wc -l'
cgroup /sys/fs/cgroup cgroup2 ro,nosuid,nodev,noexec,relatime 0 0
CapEff:	00000000a80425fb
15
```

Las comprobaciones de estado funcionan: `wslc run -d --name hc --health-cmd 'test -f /tmp/ready' --health-interval 2s alpine sh -c 'sleep 6; touch /tmp/ready; sleep 60'` mostró `Up 3 seconds (health: starting)` y luego `Up 11 seconds (healthy)` en `wslc container list`, y `container inspect` tiene un objeto `"Health"`. Contenedor detenido y eliminado después.

**Por verificar todavía:** `hostLoopback` (`host.wslc.internal`) desde un contenedor; si `-p 0.0.0.0:…` es accesible desde otra máquina; `wslc network connect` en un contenedor en ejecución; el comportamiento de `volume create` y `network create` cuando el objeto ya existe; `PortMappings` en un contenedor de la API sin red; los scripts de la lección 8 en Windows PowerShell 5.1.

## Preguntas abiertas

- ~~¿Dónde guarda `wslc` sus imágenes y contenedores?~~ En `%LocalAppData%\wslc\sessions\<session>\storage.vhdx`, un disco virtual por sesión. Crece con las imágenes y no se reduce por sí solo (ver más arriba).
- ~~¿Se puede limitar la memoria y la CPU de la VM que usa `wslc`?~~ Sí: `cpuCount` y `memorySize` en `settings.yaml`, y luego terminar la sesión (ver más arriba).
- ~~¿Pueden `wslc` y Docker Desktop publicar puertos sin conflicto?~~ Pueden publicar el mismo puerto sin **ningún error**, y ese es el problema: `127.0.0.1` llega a `wslc`, `localhost` llega a Docker (ver más arriba).
- ~~¿Cómo se compacta el `storage.vhdx` de una sesión?~~ Terminar la sesión y luego `Optimize-VHD -Mode Full` como administrador: 3995 MB → 2789 MB (ver más arriba).
- ~~¿Funciona la integración MSBuild `WslcImage` (construir una imagen en un `.tar` durante `dotnet build`)?~~ Sí, de forma incremental; el `.tar` se carga con `LoadImageAsync`, no con `ImportImageAsync` (ver arriba).
- ~~¿Tiene efecto `ContainerSettings.Privileged` en una sesión de administrador?~~ No: mismas capacidades, cgroups de solo lectura y `mount` denegado, también como administrador (ver arriba).
