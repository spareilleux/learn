---
title: 4. Construire une image
description: Conteneuriser une API minimale C# et une application Spring Boot WebFlux avec un Containerfile multi-étapes, puis construire, lancer, diagnostiquer et nettoyer.
sidebar:
  order: 4
---

Cette leçon empaquette deux petites API web dans des images — l'une en **C#** (API minimale ASP.NET Core), l'autre en **Java** (Spring Boot WebFlux, bâti sur Reactor) — et les lance avec `wslc`. Les deux font la même chose, ce qui permet de comparer les deux écosystèmes étape par étape.

Le code complet se trouve dans le dépôt : [`code/wsl-containers`](https://github.com/spareilleux/learn/tree/main/code/wsl-containers). Tout ce qui suit a été exécuté avec `wslc` 2.9.11 ; les sorties sont réelles.

:::tip[Pas de SDK nécessaire sous Windows]
La compilation se fait **dans** le conteneur de construction. Tu n'as besoin ni de .NET, ni d'un JDK, ni de Maven installés sous Windows pour suivre cette leçon — seulement de `wslc`.
:::

## Les deux applications

Chaque API expose deux points de terminaison sur le port 8080 :

- `GET /` renvoie un petit document JSON : nom de l'application, runtime, système d'exploitation et nom de la machine ;
- `GET /ticks` diffuse trois [Server-Sent Events](https://developer.mozilla.org/docs/Web/API/Server-sent_events), un par seconde.

| | C# | Java |
|---|---|---|
| Framework | API minimale ASP.NET Core 10 | Spring Boot 4.1 WebFlux |
| Valeur unique | objet anonyme renvoyé par la lambda | `Mono<Info>` |
| Flux | `IAsyncEnumerable<int>` + `TypedResults.ServerSentEvents` | `Flux<Long>` + `text/event-stream` |
| Serveur web | Kestrel | Netty |
| Port par défaut dans un conteneur | 8080 | 8080 |

**C#** — `csharp-api/Program.cs` :

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

**Java** — `java-reactor-api/src/main/java/dev/learn/reactorapi/JavaReactorApiApplication.java` (projet généré avec [start.spring.io](https://start.spring.io/), dépendance *Spring Reactive Web*) :

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

## Le Containerfile

Un `Containerfile` (même syntaxe qu'un `Dockerfile`) décrit comment construire l'image. Les deux applications utilisent une **construction multi-étapes** : une première étape avec le SDK complet compile l'application, une seconde étape avec le seul runtime reçoit le résultat. Les outils de construction n'arrivent jamais dans l'image finale.

**C#** — `csharp-api/Containerfile` :

```dockerfile
# --- Stage 1: build with the full SDK (compiler, NuGet) ---
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore first: this layer stays cached as long as the .csproj doesn't change
COPY CsharpApi.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app --no-restore

# --- Stage 2: run with the ASP.NET Core runtime only ---
FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app .

# Non-root user provided by the .NET images
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "CsharpApi.dll"]
```

**Java** — `java-reactor-api/Containerfile` :

```dockerfile
# --- Stage 1: build with Maven and the full JDK ---
FROM maven:3.9-eclipse-temurin-25 AS build
WORKDIR /src

# Download dependencies first: this layer stays cached as long as pom.xml doesn't change
COPY pom.xml .
RUN mvn -q dependency:go-offline

COPY src ./src
RUN mvn -q package

# --- Stage 2: run with the JRE only ---
FROM eclipse-temurin:25-jre
WORKDIR /app
COPY --from=build /src/target/app.jar app.jar

# Non-root user provided by the Ubuntu base image
USER ubuntu
EXPOSE 8080
# Netty loads a native library: allow it explicitly (Java 24+ warns otherwise)
ENTRYPOINT ["java", "--enable-native-access=ALL-UNNAMED", "-jar", "app.jar"]
```

(`<finalName>app</finalName>` dans `pom.xml` donne au jar un nom fixe.)

| Instruction | Rôle |
|---|---|
| `FROM image AS name` | démarre une étape à partir d'une image de base et la nomme |
| `WORKDIR` | dossier de travail dans l'image |
| `COPY` | copie des fichiers du contexte de construction (le dossier passé à `build`) |
| `COPY --from=build` | copie des fichiers depuis **une autre étape** |
| `RUN` | commande exécutée **pendant la construction** |
| `USER` | utilisateur sous lequel tourne le processus du conteneur |
| `EXPOSE` | documente le port écouté (ne le publie pas) |
| `ENTRYPOINT` | commande lancée **au démarrage du conteneur** |

Les mêmes étapes, côte à côte :

| Étape | C# | Java |
|---|---|---|
| Image de construction | `dotnet/sdk:10.0` | `maven:3.9-eclipse-temurin-25` |
| Dépendances | `dotnet restore` | `mvn dependency:go-offline` |
| Compilation et empaquetage | `dotnet publish` → dossier de DLL | `mvn package` → un jar exécutable |
| Image d'exécution | `dotnet/aspnet:10.0` | `eclipse-temurin:25-jre` |
| Utilisateur non root | `USER $APP_UID` (`app`, uid 1654) | `USER ubuntu` (uid 1000) |

:::note[Pourquoi copier le `.csproj` / `pom.xml` en premier ?]
Chaque instruction produit une couche mise en cache, réutilisée tant que ses entrées ne changent pas. En copiant le fichier de projet seul avant les sources, le téléchargement des dépendances n'est rejoué que lorsque les dépendances changent. Mesuré : première construction C# en **87 s** ; après modification de `Program.cs`, `restore` reste `CACHED` et la reconstruction prend **9 s**.
:::

Chaque projet a aussi un `.dockerignore` (`bin/` et `obj/` pour C#, `target/` pour Java) pour que les sorties de compilation locales ne soient pas envoyées dans la construction. `wslc` le respecte : un fichier placé dans `obj/` n'est pas arrivé dans l'image, et `COPY . .` est resté en cache.

## Construire

Depuis le dossier de chaque projet (`wslc build` trouve le `Containerfile` tout seul ; utilise `-f` pour un autre nom) :

```powershell
cd code\wsl-containers\csharp-api
wslc build -t csharp-api .

cd ..\java-reactor-api
wslc build -t java-reactor-api .
```

Extrait de la construction C# :

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

## Lancer

Les deux applications écoutent sur 8080 **dans** leur conteneur ; publie-les sur deux ports Windows différents :

```powershell
wslc run -d --rm -p 5000:8080 --name csharp csharp-api
wslc run -d --rm -p 8081:8080 --name java java-reactor-api
wslc container list
```

```text
CONTAINER ID   IMAGE              COMMAND                  CREATED         STATUS         PORTS                      NAMES
05f66e037cd7   java-reactor-api   "java --enable-nativ…"   6 seconds ago   Up 6 seconds   127.0.0.1:8081->8080/tcp   java
70f326d7417d   csharp-api         "dotnet CsharpApi.dll"   7 seconds ago   Up 6 seconds   127.0.0.1:5000->8080/tcp   csharp
```

`wslc` publie sur `127.0.0.1` par défaut, utilise donc cette adresse :

```powershell
curl.exe http://127.0.0.1:5000/
curl.exe http://127.0.0.1:8081/
```

```text
{"app":"csharp-api","runtime":".NET 10.0.12","os":"Ubuntu 24.04.5 LTS","machine":"d7edc26a9abe"}
{"app":"java-reactor-api","runtime":"Java 25.0.4+7-LTS","os":"Linux 6.18.40.1-microsoft-standard-WSL2","machine":"c5fbd8e50515"}
```

:::caution[`localhost` n'est pas toujours `127.0.0.1`]
Si Docker Desktop publie le même port, `localhost` peut atteindre Docker au lieu de `wslc`, sans aucune erreur nulle part. Voir le [journal](../journal/).
:::

Le nom de la machine est l'identifiant du conteneur. Le flux (`-N` désactive la mise en tampon de curl, pour que les événements s'affichent un par seconde) :

```powershell
curl.exe -N http://127.0.0.1:5000/ticks
curl.exe -N http://127.0.0.1:8081/ticks
```

```text
data: 0

data: 1

data: 2
```

Java écrit `data:0` sans l'espace ; les deux formes sont du SSE valide.

### La preuve que c'est Linux, et pas root

```powershell
wslc exec csharp uname -a
wslc exec csharp id
wslc exec java id
```

```text
Linux d7edc26a9abe 6.18.40.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Fri Jul 31 22:12:15 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
uid=1654(app) gid=1654(app) groups=1654(app)
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu),4(adm),20(dialout),24(cdrom),25(floppy),27(sudo),29(audio),30(dip),44(video),46(plugdev)
```

Le noyau est celui de WSL : les conteneurs partagent le noyau de la VM de la session `wslc`. Sans la ligne `USER`, le conteneur Java tournerait en `uid=0(root)`.

## Lire les logs

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

## Diagnostiquer

```powershell
wslc container list --all        # includes stopped containers, with their exit code
wslc container logs <container>  # what the application printed
wslc container inspect <container>  # effective configuration: command, env, ports, exit code
wslc image inspect <image>
```

## Libérer de l'espace disque

Chaque reconstruction déplace le tag vers la nouvelle image et laisse l'ancienne derrière elle, sans tag :

```text
REPOSITORY         TAG      IMAGE ID       CREATED         SIZE
csharp-api         latest   c1bdb0897739   3 minutes ago   230MB
<none>             <none>   ddb9e015ed72   4 minutes ago   387MB
java-reactor-api   latest   3a731cbc7d15   4 minutes ago   387MB
<none>             <none>   c32cae38bd07   7 minutes ago   230MB
```

```powershell
wslc container prune       # removes stopped containers
wslc image prune           # removes dangling images (the <none> ones)
wslc image prune --all     # removes all images not used by a container (no confirmation)
```

:::caution
Dans `wslc image prune`, `-f` signifie `--filter`, pas `--force`. Et le nettoyage libère de l'espace **dans** le `storage.vhdx` de la session, mais le fichier ne rétrécit pas côté Windows (mesuré dans le [journal](../journal/)).
:::

## À retenir

- Une construction **multi-étapes** compile avec le SDK et ne livre que le runtime : 230 Mo pour l'image C# au lieu de 918 Mo pour l'étape de construction.
- Copie le fichier de projet (`.csproj`, `pom.xml`) et restaure les dépendances **avant** de copier les sources, pour garder cette couche en cache.
- `RUN` s'exécute à la construction, `ENTRYPOINT` au démarrage.
- Exécute sous un utilisateur non root : `USER $APP_UID` pour les images .NET, `USER ubuntu` pour les images Temurin.
- Les deux applications écoutent sur 8080 dans le conteneur ; `-p host:container` choisit le port Windows.
- `container list --all`, `logs` et `inspect` sont les premiers réflexes quand un conteneur ne se comporte pas comme prévu.

## Exercices

1. Quelle serait la taille de l'image C# si tu livrais l'étape de **construction** au lieu de l'étape d'exécution ? Mesure-la sans modifier le `Containerfile`.

<details>
<summary>Solution</summary>

`--target` arrête la construction à une étape nommée :

```powershell
wslc build --target build -t csharp-api:build .
wslc image list
```

```text
csharp-api   latest   c32cae38bd07   3 minutes ago   230MB
csharp-api   build    3d3e47d940b4   3 minutes ago   918MB
```

Le SDK, les caches NuGet et les fichiers intermédiaires rendent l'étape de construction quatre fois plus lourde. Supprime-la ensuite : `wslc image remove csharp-api:build`.

</details>

2. Fais écouter les deux applications sur le port **9000** dans leur conteneur, **sans reconstruire** les images.

<details>
<summary>Solution</summary>

Les deux frameworks lisent le port dans une variable d'environnement, passée avec `-e` :

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

Le côté conteneur de `-p` doit suivre : `5000:9000`, et non `5000:8080`. `EXPOSE 8080` dans le `Containerfile` n'est que de la documentation et ne l'empêche pas.

</details>

3. Un collègue lance l'application Java avec `wslc run -d --rm -e SERVER_PORT=abc --name java java-reactor-api`. Quelques secondes plus tard, `wslc container list` n'affiche rien et `wslc container logs java` répond :

```text
Container 'java' not found.
Error code: WSLC_E_CONTAINER_NOT_FOUND
```

Que s'est-il passé, et comment trouver la cause ?

<details>
<summary>Solution</summary>

L'application a planté au démarrage, et `--rm` a supprimé le conteneur avec ses logs. Relance-la **sans `--rm`** :

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

`wslc container inspect java` confirme `"SERVER_PORT=abc"` dans `Env` et `"ExitCode": 1`. Nettoie avec `wslc container remove java`.

</details>

4. `GET /` indique `"os":"Ubuntu 24.04.5 LTS"` pour C#, mais `"os":"Linux 6.18.40.1-microsoft-standard-WSL2"` pour Java. Les deux conteneurs tournent-ils sur des systèmes différents ?

<details>
<summary>Solution</summary>

Non. Les deux runtimes ne décrivent pas la même chose :

- `RuntimeInformation.OSDescription` (.NET) lit la distribution de l'**image** (`/etc/os-release`) : l'image `aspnet:10.0` est basée sur Ubuntu 24.04 ;
- `os.name` + `os.version` (Java) donnent le nom et la version du **noyau**, partagé par tous les conteneurs de la session.

`wslc exec java cat /etc/os-release` montre que l'image Temurin 25 est basée sur Ubuntu 26.04, et `wslc exec csharp uname -r` affiche le même noyau WSL que Java.

</details>

## Sources

- [WSL container](https://learn.microsoft.com/windows/wsl/wsl-container) — Microsoft Learn
- [Conteneuriser une application .NET](https://learn.microsoft.com/dotnet/core/docker/build-container) et [Images conteneur .NET](https://learn.microsoft.com/dotnet/core/docker/container-images) — Microsoft Learn
- [Server-Sent Events dans les API minimales ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis/responses) — Microsoft Learn
- [Container images](https://docs.spring.io/spring-boot/reference/packaging/container-images/index.html) et [Dockerfiles](https://docs.spring.io/spring-boot/reference/packaging/container-images/dockerfiles.html) — référence Spring Boot
- [Web on Reactive Stack (WebFlux)](https://docs.spring.io/spring-framework/reference/web/webflux.html) — référence Spring Framework
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/) et [Dockerfile reference](https://docs.docker.com/reference/dockerfile/) — documentation Docker (`wslc` utilise la même syntaxe)
