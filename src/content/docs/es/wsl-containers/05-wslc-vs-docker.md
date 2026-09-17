---
title: 5. ¿wslc o Docker Desktop?
description: Comparar wslc y Docker Desktop, usar los dos en la misma máquina y evitar sus trampas silenciosas - almacenes de imágenes separados, una etiqueta latest que difiere y el mismo puerto publicado dos veces sin ningún error.
sidebar:
  order: 5
---

Tras cuatro lecciones, `wslc` cubre lo que la mayoría de los desarrolladores hacen a diario con Docker: descargar imágenes, ejecutar contenedores, publicar puertos, entrar en ellos y construir imágenes. La pregunta práctica no es si sustituye a Docker Desktop en general, sino si puede sustituirlo en **tu** máquina, o convivir con él. Esta lección compara los dos y luego pone a prueba la convivencia: si comparten las imágenes, si los dos siguen funcionando y qué pasa cuando ambos publican el mismo puerto. Las mediciones están en el [diario](../journal/).

## Comparación

| Criterio | `wslc` (WSL containers) | Docker Desktop |
|---|---|---|
| Instalación | incluido en WSL ≥ 2.9.3 | producto independiente |
| Madurez (sept. de 2026) | versión preliminar pública | estable |
| CLI | cercana a Docker | `docker` |
| VM Linux | una por sesión, `vmmem<session>` | una distribución, `docker-desktop` |
| Límites de recursos | por sesión, `settings.yaml` ([lección 6](../06-resources-and-limits/)) | para la VM de WSL 2, `.wslconfig` |
| API para aplicaciones Windows | sí — NuGet `Microsoft.WSL.Containers` ([lección 9](../09-csharp-api/)) | Docker Engine API (HTTP) |
| Gestión empresarial | Microsoft Defender for Endpoint, Intune | Docker Business |
| Ecosistema (Compose, Kubernetes, extensiones, GUI) | nada en la 2.9.11: ningún comando `compose` ([lección 8](../08-compose/)), sin Kubernetes (k3s no arranca), sin extensiones, sin página de contenedores en WSL Settings ([lección 10](../10-networking-kubernetes-gui/)) | completo |

La fila que más importa para un equipo C# o Java es la de la API. Todas las herramientas basadas en la Docker Engine API, desde Testcontainers hasta las vistas de contenedores de los IDE, necesitan un punto de conexión que `wslc` no expone a Windows ([lección 8](../08-compose/)). A cambio, `Microsoft.WSL.Containers` le da a una aplicación Windows algo que Docker Desktop no le da: sus propios contenedores, sin ningún producto que instalar.

## Los dos en la misma máquina

### Docker Desktop sigue funcionando con WSL 2.9.11

Actualizar WSL a la versión preliminar no rompió Docker Desktop 4.61, pero su CLI dio una primera respuesta confusa. `docker desktop start` respondió `Docker Desktop is already running` cuando no existía ningún proceso de Docker Desktop, y `docker desktop status` respondió `Could not retrieve status`. Lanzar directamente `C:\Program Files\Docker\Docker\Docker Desktop.exe` funcionó: el motor 29.2.1 estuvo listo tras unos 130 segundos, y `docker run --rm hello-world` se ejecutó correctamente. Podman 5.8.3 también arrancó y ejecutó su imagen de prueba.

### Las imágenes no se comparten

Tras `docker pull busybox`, las dos listas difieren:

```text
> docker images            > wslc images
postgres:16-alpine          alpine   latest
busybox:latest
hello-world:latest
node:18-alpine
```

Cada herramienta tiene su propio almacén: `docker_data.vhdx`, unos 50 GB aquí, para Docker, y un `storage.vhdx` por sesión para `wslc`. Una imagen que usan las dos se descarga dos veces y se almacena dos veces. Peor aún, la misma etiqueta puede apuntar a dos versiones: `qdrant/qdrant:latest` era qdrant 1.16.3 en Docker, descargado meses antes, y 1.19.1 en `wslc` ([lección 7](../07-volumes-and-a-real-service/)).

### El mismo puerto, dos veces, sin ningún error

La trampa más arriesgada. Una prueba con dos servidores web que responden de forma distinta: `nginx` en `wslc`, y `httpd`, el servidor Apache cuya página dice «It works!», en Docker. La página indica qué herramienta ha respondido.

```powershell
wslc run -d --name webwslc -p 8080:80 nginx
docker run -d --name webdocker -p 8080:80 httpd
curl.exe http://127.0.0.1:8080/   # nginx  → wslc
curl.exe http://localhost:8080/   # It works! → Docker
```

**Los dos contenedores arrancan sin ningún error.** Windows acepta los dos listeners porque no se enlazan exactamente a la misma dirección. Los listeners del puerto 8080, con sus procesos:

```text
TCP  0.0.0.0:8080     LISTENING  com.docker.backend
TCP  [::]:8080        LISTENING  com.docker.backend
TCP  127.0.0.1:8080   LISTENING  dllhost      ← wslc
TCP  [::1]:8080       LISTENING  wslrelay
```

`127.0.0.1` va a `wslc`, porque gana la dirección más específica, mientras que `localhost` se resuelve primero a `::1` y acaba en Docker. Ni el orden de los arranques ni un `0.0.0.0` explícito cambian nada:

| Variante | Errores | `127.0.0.1` | `localhost` |
|---|---|---|---|
| `wslc` primero, luego Docker (8080) | ninguno | wslc | Docker |
| Docker primero, luego `wslc` (8081) | ninguno | wslc | Docker |
| Docker, luego `wslc -p 0.0.0.0:8082:80` | ninguno | wslc | Docker |
| `wslc -p 0.0.0.0:8083:80`, luego Docker | ninguno | wslc | Docker |

Piensa en lo que esto significa para una aplicación. Una configuración de Spring Boot o de ASP.NET Core que dice `localhost:5432` y un script de pruebas que dice `127.0.0.1:5432` pueden hablar con dos bases de datos distintas, y todas las herramientas informan de que todo ha ido bien. La solución es organizativa: dale a cada herramienta su propio rango de puertos, como hace la [lección 7](../07-volumes-and-a-real-service/) con el 16333 para el qdrant de `wslc`.

### Dos VM cuestan dos VM

Cada herramienta mantiene su propia VM y su propia memoria. Una sesión `wslc` inactiva cuesta unos 0,9 GB y se detiene tras 30 segundos sin ningún comando ([lección 6](../06-resources-and-limits/)); la VM de Docker Desktop sigue en marcha mientras Docker Desktop se ejecuta. En una máquina que ya anda escasa de memoria, la primera entrada del diario muestra cómo puede acabar esto: `Wsl/0x8007000e`, memoria insuficiente, y Docker Desktop cerrándose de golpe.

## Cuándo elegir qué

- **`wslc`**: necesidades sencillas, como ejecutar una base de datos, un servicio o una herramienta; el deseo de no depender de Docker Desktop y de su licencia; o una aplicación Windows que necesita controlar sus propios contenedores.
- **Docker Desktop**, o Podman: proyectos basados en Docker Compose, Kubernetes local, herramientas que necesitan la Docker Engine API, como Testcontainers, y un equipo ya equipado en torno a Docker.
- **Los dos**: es posible, con puertos separados y teniendo en cuenta la memoria de dos VM.

## Puntos clave

- `wslc` = contenedores nativos de WSL, sin producto de terceros, todavía en versión preliminar.
- Docker Desktop sigue siendo más completo: Compose, Kubernetes, extensiones, una interfaz gráfica y la Docker Engine API.
- Docker Desktop 4.61 sigue funcionando con WSL 2.9.11, pero arráncalo desde su ejecutable si `docker desktop start` asegura que ya está en marcha.
- Las imágenes no se comparten: una imagen que usan las dos herramientas se descarga dos veces, y `latest` puede ser dos versiones distintas.
- Las dos herramientas pueden publicar el mismo puerto sin ningún error. `127.0.0.1` llega entonces a `wslc` y `localhost` llega a Docker: mantén sus puertos separados.
- La API `Microsoft.WSL.Containers` abre un caso de uso que Docker Desktop no cubre directamente: aplicaciones Windows que integran contenedores Linux.

## Ejercicios

1. Docker Desktop publica PostgreSQL en el puerto 5432. Arrancas otro PostgreSQL con `wslc run -d -p 5432:5432 postgres:16-alpine`. Tu aplicación ASP.NET Core usa `Host=localhost;Port=5432` y tu script de migraciones usa `127.0.0.1`. ¿A qué base de datos llega cada uno, y qué errores ves?

<details>
<summary>Solución</summary>

Ningún error en ninguna parte. El script de migraciones, en `127.0.0.1`, llega a la base de datos de `wslc`, que escucha en esa dirección exacta. La aplicación, en `localhost`, que se resuelve primero a `::1`, llega a la base de datos de Docker. Las migraciones se aplican a una base de datos que la aplicación nunca lee. Esto se deduce de las cuatro variantes medidas más arriba; el propio PostgreSQL no formó parte de la prueba, así que queda *por verificar* con tu biblioteca cliente, ya que algunas resuelven `localhost` primero a IPv4.

</details>

2. ¿Cómo averiguas, en unos segundos, qué proceso escucha en cada dirección del puerto 8080?

<details>
<summary>Solución</summary>

Con PowerShell, que no necesita elevación para esto:

```powershell
Get-NetTCPConnection -LocalPort 8080 -State Listen | Select-Object LocalAddress, OwningProcess, @{n='Process';e={(Get-Process -Id $_.OwningProcess).ProcessName}}
```

Un `dllhost` en `127.0.0.1` es el listener de `wslc`; `com.docker.backend` en `0.0.0.0` y `[::]` es Docker Desktop. Este comando se comprobó en otro puerto de la misma máquina, no durante la prueba del puerto 8080. Desde una terminal de administrador, `netstat -abno` da la misma información.

</details>

3. Un compañero dice: «No hace falta volver a descargarla, ya tengo `qdrant/qdrant:latest` en Docker». Da dos razones por las que eso es falso para `wslc`.

<details>
<summary>Solución</summary>

Primero, los almacenes están separados: `wslc` vuelve a descargar la imagen en el `storage.vhdx` de su sesión. Segundo, `latest` se resuelve en el momento de la descarga, así que la copia de `wslc` puede ser una versión más reciente que la de Docker: 1.19.1 frente a 1.16.3 en la prueba. Fija una etiqueta de versión cuando las dos deban coincidir.

</details>

4. Después de actualizar WSL, `docker desktop start` responde `Docker Desktop is already running`, pero `docker ps` falla. ¿Qué haces?

<details>
<summary>Solución</summary>

Comprueba si existe realmente un proceso de Docker Desktop, por ejemplo con `Get-Process "Docker Desktop" -ErrorAction SilentlyContinue`. Si no hay ninguno, lanza directamente `C:\Program Files\Docker\Docker\Docker Desktop.exe` y espera al motor, que aquí tardó unos dos minutos, antes de volver a ejecutar `docker ps`.

</details>

## Fuentes

- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container)
- [Docker Desktop](https://docs.docker.com/desktop/) y [Docker Desktop WSL 2 backend](https://docs.docker.com/desktop/features/wsl/) — documentación de Docker
- [Published ports](https://docs.docker.com/engine/network/port-publishing/) — documentación de Docker
- [`Get-NetTCPConnection` — Microsoft Learn](https://learn.microsoft.com/powershell/module/nettcpip/get-nettcpconnection)
- [Testcontainers](https://testcontainers.com/)
