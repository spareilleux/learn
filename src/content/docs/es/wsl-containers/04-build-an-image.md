---
title: 4. Construir una imagen
description: Contenerizar una minimal API en C# y una aplicación Spring Boot WebFlux con un Containerfile multietapa, y luego construir, ejecutar, diagnosticar y limpiar.
sidebar:
  order: 4
---

Esta lección empaqueta dos pequeñas API web en imágenes —una en **C#** ([minimal API de ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis/overview)), otra en **Java** ([Spring Boot](https://spring.io/projects/spring-boot) [WebFlux](https://docs.spring.io/spring-framework/reference/web/webflux.html), basada en [Reactor](https://projectreactor.io/))— y las ejecuta con `wslc`. Las dos hacen lo mismo, así que puedes comparar los dos ecosistemas paso a paso.

El código completo está en el repositorio: [`code/wsl-containers`](https://github.com/spareilleux/learn/tree/main/code/wsl-containers). Todo lo que sigue se ejecutó con `wslc` 2.9.11; las salidas son reales.

:::tip[No hace falta ningún SDK en Windows]
La compilación ocurre **dentro** del contenedor de build. No necesitas tener instalados en Windows [.NET](https://dotnet.microsoft.com/), un JDK (como [Eclipse Temurin](https://adoptium.net/temurin/releases/)) ni [Maven](https://maven.apache.org/) para seguir esta lección: solo `wslc`.
:::

## Las dos aplicaciones

Cada API expone dos endpoints en el puerto 8080:

- `GET /` devuelve un pequeño documento JSON: nombre de la aplicación, runtime, sistema operativo y nombre de la máquina;
- `GET /ticks` emite en streaming tres [Server-Sent Events](https://developer.mozilla.org/docs/Web/API/Server-sent_events), uno por segundo.

| | C# | Java |
|---|---|---|
| Framework | minimal API de ASP.NET Core 10 | Spring Boot 4.1 WebFlux |
| Valor único | objeto anónimo devuelto por la lambda | `Mono<Info>` |
| Flujo | `IAsyncEnumerable<int>` + `TypedResults.ServerSentEvents` | `Flux<Long>` + `text/event-stream` |
| Servidor web | [Kestrel](https://learn.microsoft.com/aspnet/core/fundamentals/servers/kestrel) | [Netty](https://netty.io/) |
| Puerto por defecto en un contenedor | 8080 | 8080 |

**C#** — `csharp-api/Program.cs`:

```csharp
app.MapGet("/", () => new
{
    App = "csharp-api",
    Runtime = RuntimeInformation.FrameworkDescription,
    Os = RuntimeInformation.OSDescription,
    Machine = Environment.MachineName
});

app.MapGet("/ticks", (CancellationToken ct) => TypedResults.ServerSentEvents(Ticks(ct)));

static async IAsyncEnumerable<int> Ticks([EnumeratorCancellation] CancellationToken ct)
{
    for (var i = 0; i < 3; i++)
    {
        await Task.Delay(TimeSpan.FromSeconds(1), ct);
        yield return i;
    }
}
```

**Java** — `java-reactor-api/src/main/java/dev/learn/reactorapi/JavaReactorApiApplication.java` (proyecto generado con [start.spring.io](https://start.spring.io/), dependencia *Spring Reactive Web*):

```java
record Info(String app, String runtime, String os, String machine) {
}

@RestController
class InfoController {

	@GetMapping("/")
	Mono<Info> info() {
		return Mono.just(new Info(
				"java-reactor-api",
				"Java " + Runtime.version(),
				System.getProperty("os.name") + " " + System.getProperty("os.version"),
				System.getenv().getOrDefault("HOSTNAME", "?")));
	}

	@GetMapping(value = "/ticks", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
	Flux<Long> ticks() {
		return Flux.interval(Duration.ofSeconds(1)).take(3);
	}

}
```

## El Containerfile

Un `Containerfile` (misma sintaxis que un `Dockerfile`) describe cómo construir la imagen. Las dos aplicaciones usan un **build multietapa**: una primera etapa con el SDK completo compila la aplicación, y una segunda etapa con solo el runtime recibe el resultado. Las herramientas de build nunca llegan a la imagen final.

**C#** — `csharp-api/Containerfile`:

```dockerfile
# --- Etapa 1: build con el SDK completo (compilador, NuGet) ---
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restaurar primero: esta capa queda en caché mientras el .csproj no cambie
COPY CsharpApi.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app --no-restore

# --- Etapa 2: ejecución con solo el runtime de ASP.NET Core ---
FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app .

# Usuario no root proporcionado por las imágenes de .NET
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "CsharpApi.dll"]
```

**Java** — `java-reactor-api/Containerfile`:

```dockerfile
# --- Etapa 1: build con Maven y el JDK completo ---
FROM maven:3.9-eclipse-temurin-25 AS build
WORKDIR /src

# Descargar primero las dependencias: esta capa queda en caché mientras pom.xml no cambie
COPY pom.xml .
RUN mvn -q dependency:go-offline

COPY src ./src
RUN mvn -q package

# --- Etapa 2: ejecución con solo el JRE ---
FROM eclipse-temurin:25-jre
WORKDIR /app
COPY --from=build /src/target/app.jar app.jar

# Usuario no root proporcionado por la imagen base de Ubuntu
USER ubuntu
EXPOSE 8080
# Netty carga una biblioteca nativa: permitirlo explícitamente (si no, Java 24+ muestra una advertencia)
ENTRYPOINT ["java", "--enable-native-access=ALL-UNNAMED", "-jar", "app.jar"]
```

(`<finalName>app</finalName>` en `pom.xml` da al jar un nombre fijo.)

| Instrucción | Función |
|---|---|
| `FROM image AS name` | inicia una etapa a partir de una imagen base y le da un nombre |
| `WORKDIR` | directorio de trabajo en la imagen |
| `COPY` | copia archivos desde el contexto de build (la carpeta pasada a `build`) |
| `COPY --from=build` | copia archivos desde **otra etapa** |
| `RUN` | comando ejecutado **durante el build** |
| `USER` | usuario con el que se ejecuta el proceso del contenedor |
| `EXPOSE` | documenta el puerto de escucha (no lo publica) |
| `ENTRYPOINT` | comando ejecutado **cuando arranca el contenedor** |

Los mismos pasos, lado a lado:

| Paso | C# | Java |
|---|---|---|
| Imagen de build | [`dotnet/sdk:10.0`](https://hub.docker.com/r/microsoft/dotnet-sdk) | [`maven:3.9-eclipse-temurin-25`](https://hub.docker.com/_/maven) |
| Dependencias | `dotnet restore` ([NuGet](https://www.nuget.org/)) | `mvn dependency:go-offline` |
| Compilar y empaquetar | `dotnet publish` → carpeta de DLL | `mvn package` → un único jar ejecutable |
| Imagen de runtime | [`dotnet/aspnet:10.0`](https://hub.docker.com/r/microsoft/dotnet-aspnet) | [`eclipse-temurin:25-jre`](https://hub.docker.com/_/eclipse-temurin) |
| Usuario no root | `USER $APP_UID` (`app`, uid 1654) | `USER ubuntu` (uid 1000) |

:::note[¿Por qué copiar primero el `.csproj` / `pom.xml`?]
Cada instrucción produce una capa en caché, reutilizada mientras sus entradas no cambien. Al copiar el archivo de proyecto solo, antes que el código fuente, la descarga de dependencias solo se repite cuando cambian las dependencias. Medido: primer build de C# **87 s**; tras editar `Program.cs`, `restore` queda `CACHED` y el rebuild tarda **9 s**.
:::

Cada proyecto tiene también un `.dockerignore` (`bin/` y `obj/` para C#, `target/` para Java) para que las salidas de build locales no se envíen al build. `wslc` lo respeta: un archivo colocado en `obj/` no llegó a la imagen, y `COPY . .` siguió en caché.

## Construir

Desde la carpeta de cada proyecto (`wslc build` encuentra el `Containerfile` por sí solo; usa `-f` para otro nombre):

```powershell
cd code\wsl-containers\csharp-api
wslc build -t csharp-api .

cd ..\java-reactor-api
wslc build -t java-reactor-api .
```

Extracto del build de C#:

```text
[build 3/6] COPY CsharpApi.csproj .
[build 4/6] RUN dotnet restore
  [build]   Determining projects to restore...
  [build]   Restored /src/CsharpApi.csproj (in 201 ms).
[build 5/6] COPY . .
[build 6/6] RUN dotnet publish -c Release -o /app --no-restore
  [build]   CsharpApi -> /src/bin/Release/net10.0/CsharpApi.dll
  [build]   CsharpApi -> /app/
[stage-1 3/3] COPY --from=build /app .
exporting to image
  | naming to docker.io/library/csharp-api
```

```text
> wslc image list
REPOSITORY         TAG      IMAGE ID       CREATED         SIZE
csharp-api         latest   c1bdb0897739   3 minutes ago   230MB
java-reactor-api   latest   3a731cbc7d15   4 minutes ago   387MB
```

## Ejecutar

Las dos aplicaciones escuchan en el 8080 **dentro** de su contenedor; publícalas en dos puertos distintos de Windows:

```powershell
wslc run -d --rm -p 5000:8080 --name csharp csharp-api
wslc run -d --rm -p 8081:8080 --name java java-reactor-api
wslc container list
```

```text
CONTAINER ID   IMAGE              COMMAND                  CREATED         STATUS         PORTS                      NAMES
b8acbb234fb1   java-reactor-api   "java --enable-nativ…"   8 seconds ago   Up 7 seconds   127.0.0.1:8081->8080/tcp   java
8bdcda0c3927   csharp-api         "dotnet CsharpApi.dll"   8 seconds ago   Up 7 seconds   127.0.0.1:5000->8080/tcp   csharp
```

`wslc` publica en `127.0.0.1` por defecto, así que usa esa dirección con [curl](https://curl.se/) (`curl.exe` viene con Windows):

```powershell
curl.exe http://127.0.0.1:5000/
curl.exe http://127.0.0.1:8081/
```

```text
{"app":"csharp-api","runtime":".NET 10.0.12","os":"Ubuntu 24.04.5 LTS","machine":"8bdcda0c3927"}
{"app":"java-reactor-api","runtime":"Java 25.0.4+7-LTS","os":"Linux 6.18.40.1-microsoft-standard-WSL2","machine":"b8acbb234fb1"}
```

:::caution[`localhost` no siempre es `127.0.0.1`]
Si Docker Desktop publica el mismo puerto, `localhost` puede llegar a Docker en lugar de a `wslc`, sin ningún error en ninguna parte. Ver el [diario](../journal/).
:::

El nombre de la máquina es el ID del contenedor. El flujo (`-N` desactiva el búfer de curl, para que los eventos aparezcan uno por segundo):

```powershell
curl.exe -N http://127.0.0.1:5000/ticks
curl.exe -N http://127.0.0.1:8081/ticks
```

```text
data: 0

data: 1

data: 2
```

Java escribe `data:0` sin el espacio; las dos formas son SSE válido.

### Prueba de que es Linux, y no root

```powershell
wslc exec csharp uname -a
wslc exec csharp id
wslc exec java id
```

```text
Linux 8bdcda0c3927 6.18.40.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Fri Jul 31 22:12:15 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
uid=1654(app) gid=1654(app) groups=1654(app)
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu),4(adm),20(dialout),24(cdrom),25(floppy),27(sudo),29(audio),30(dip),44(video),46(plugdev)
```

El kernel es el de WSL: los contenedores comparten el kernel de la VM de la sesión `wslc`. Sin la línea `USER`, el contenedor Java se ejecutaría como `uid=0(root)`.

## Leer los logs

```powershell
wslc container logs csharp
wslc container logs java
```

```text
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://[::]:8080
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
```

```text
 :: Spring Boot ::                (v4.1.1)

... Starting JavaReactorApiApplication v0.0.1-SNAPSHOT using Java 25.0.4 with PID 1 (/app/app.jar started by ubuntu in /app)
... Netty started on port 8080 (http)
... Started JavaReactorApiApplication in 1.391 seconds (process running for 1.795)
```

```powershell
wslc container stop csharp java
```

## Diagnosticar

```powershell
wslc container list --all        # incluye los contenedores detenidos, con su código de salida
wslc container logs <container>  # lo que imprimió la aplicación
wslc container inspect <container>  # configuración efectiva: comando, env, puertos, código de salida
wslc image inspect <image>
```

## Liberar espacio en disco

Cada rebuild mueve la etiqueta a la nueva imagen y deja la antigua atrás, sin etiqueta:

```text
REPOSITORY         TAG      IMAGE ID       CREATED         SIZE
csharp-api         latest   c1bdb0897739   3 minutes ago   230MB
<none>             <none>   ddb9e015ed72   4 minutes ago   387MB
java-reactor-api   latest   3a731cbc7d15   4 minutes ago   387MB
<none>             <none>   c32cae38bd07   7 minutes ago   230MB
```

```powershell
wslc container prune       # elimina los contenedores detenidos
wslc image prune           # elimina las imágenes huérfanas (las <none>)
wslc image prune --all     # elimina todas las imágenes que no usa ningún contenedor (sin confirmación)
```

:::caution
En `wslc image prune`, `-f` significa `--filter`, no `--force`. Y la limpieza libera espacio **dentro** del `storage.vhdx` de la sesión, pero el archivo no se reduce del lado de Windows (medido en el [diario](../journal/)).
:::

## Puntos clave

- Un build **multietapa** compila con el SDK y solo entrega el runtime: 230 MB para la imagen de C# en lugar de 918 MB para la etapa de build.
- Copia el archivo de proyecto (`.csproj`, `pom.xml`) y restaura las dependencias **antes** de copiar el código fuente, para mantener esa capa en caché.
- `RUN` se ejecuta en el build, `ENTRYPOINT` al arrancar.
- Ejecuta con un usuario no root: `USER $APP_UID` para las imágenes de .NET, `USER ubuntu` para las imágenes de Temurin.
- Las dos aplicaciones escuchan en el 8080 dentro del contenedor; `-p host:container` elige el puerto de Windows.
- `container list --all`, `logs` e `inspect` son lo primero a lo que recurrir cuando un contenedor no se comporta como se espera.

## Ejercicios

1. ¿Qué tamaño tendría la imagen de C# si entregaras la etapa de **build** en lugar de la etapa de runtime? Mídelo sin editar el `Containerfile`.

<details>
<summary>Solución</summary>

`--target` detiene el build en una etapa con nombre:

```powershell
wslc build --target build -t csharp-api:build .
wslc image list
```

```text
csharp-api   latest   c32cae38bd07   3 minutes ago   230MB
csharp-api   build    3d3e47d940b4   3 minutes ago   918MB
```

El SDK, las cachés de NuGet y los archivos intermedios hacen que la etapa de build sea cuatro veces más grande. Elimínala después: `wslc image remove csharp-api:build`.

</details>

2. Haz que las dos aplicaciones escuchen en el puerto **9000** dentro de su contenedor, **sin reconstruir** las imágenes.

<details>
<summary>Solución</summary>

Los dos frameworks leen el puerto de una variable de entorno, pasada con `-e`:

```powershell
wslc run -d --rm -e ASPNETCORE_HTTP_PORTS=9000 -p 5000:9000 --name csharp csharp-api
wslc run -d --rm -e SERVER_PORT=9000 -p 8081:9000 --name java java-reactor-api
wslc container logs csharp
wslc container logs java
```

```text
      Now listening on: http://[::]:9000
... Netty started on port 9000 (http)
```

El lado del contenedor de `-p` debe seguir el cambio: `5000:9000`, no `5000:8080`. `EXPOSE 8080` en el `Containerfile` es solo documentación y no lo impide.

</details>

3. Un compañero de equipo inicia la aplicación Java con `wslc run -d --rm -e SERVER_PORT=abc --name java java-reactor-api`. Unos segundos después, `wslc container list` no muestra nada y `wslc container logs java` responde:

```text
Container 'java' not found.
Error code: WSLC_E_CONTAINER_NOT_FOUND
```

¿Qué ha pasado y cómo encuentras la causa?

<details>
<summary>Solución</summary>

La aplicación falló al arrancar, y `--rm` eliminó el contenedor junto con sus logs. Vuelve a ejecutarla **sin `--rm`**:

```powershell
wslc run -d -e SERVER_PORT=abc --name java java-reactor-api
wslc container list --all
wslc container logs java
```

```text
CONTAINER ID   IMAGE              COMMAND                  CREATED         STATUS                     PORTS   NAMES
7b374a736ad1   java-reactor-api   "java --enable-nativ…"   7 seconds ago   Exited (1) 4 seconds ago           java
```

```text
***************************
APPLICATION FAILED TO START
***************************

Description:

Failed to bind properties under 'server.port' to java.lang.Integer:

    Property: server.port
    Value: "abc"
    Origin: System Environment Property "SERVER_PORT"
    Reason: failed to convert java.lang.String to java.lang.Integer (caused by java.lang.NumberFormatException: For input string: "abc")
```

`wslc container inspect java` confirma `"SERVER_PORT=abc"` en `Env` y `"ExitCode": 1`. Limpia con `wslc container remove java`.

</details>

4. `GET /` indica `"os":"Ubuntu 24.04.5 LTS"` para C# pero `"os":"Linux 6.18.40.1-microsoft-standard-WSL2"` para Java. ¿Se ejecutan los dos contenedores en sistemas distintos?

<details>
<summary>Solución</summary>

No. Los dos runtimes no describen lo mismo:

- `RuntimeInformation.OSDescription` (.NET) lee la distribución de la **imagen** (`/etc/os-release`): la imagen `aspnet:10.0` se basa en Ubuntu 24.04;
- `os.name` + `os.version` (Java) dan el nombre y la versión del **kernel**, compartido por todos los contenedores de la sesión.

`wslc exec java cat /etc/os-release` muestra que la imagen de Temurin 25 se basa en Ubuntu 26.04, y `wslc exec csharp uname -r` muestra el mismo kernel de WSL que Java.

</details>

## Fuentes

- [WSL container](https://learn.microsoft.com/windows/wsl/wsl-container) — Microsoft Learn
- [Contenerizar una aplicación .NET](https://learn.microsoft.com/dotnet/core/docker/build-container) e [imágenes de contenedor de .NET](https://learn.microsoft.com/dotnet/core/docker/container-images) — Microsoft Learn
- [Server-Sent Events en las minimal API de ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis/responses) — Microsoft Learn
- [Container images](https://docs.spring.io/spring-boot/reference/packaging/container-images/index.html) y [Dockerfiles](https://docs.spring.io/spring-boot/reference/packaging/container-images/dockerfiles.html) — referencia de Spring Boot
- [Web on Reactive Stack (WebFlux)](https://docs.spring.io/spring-framework/reference/web/webflux.html) — referencia de Spring Framework
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/) y [Dockerfile reference](https://docs.docker.com/reference/dockerfile/) — documentación de Docker (`wslc` usa la misma sintaxis)
