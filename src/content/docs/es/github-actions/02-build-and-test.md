---
title: 2. Compilar y probar .NET y Java
description: Una matrix sobre tres sistemas operativos, setup-dotnet y setup-java, la caché de Maven, y las trampas de xUnit v3 con el SDK de .NET 10.
sidebar:
  order: 2
---

## El proyecto

[`code/github-actions`](https://github.com/spareilleux/learn/tree/main/code/github-actions) contiene dos veces la misma pequeña función — convertir un título en un slug de URL — con cuatro pruebas en cada lado:

| | .NET | Java |
|---|---|---|
| Código | `dotnet/Slugs/Slug.cs` | `java/src/main/java/com/example/slugs/Slug.java` |
| Pruebas | [xUnit v3](https://xunit.net/) `[Theory]` + `[InlineData]` | [JUnit 6](https://docs.junit.org/) `@ParameterizedTest` + `@CsvSource` |
| Comando | `dotnet test` | `mvn -B verify` |
| SDK fijado por | `global.json` | `maven.compiler.release` en `pom.xml` |

De [`dotnet/Slugs.Tests/SlugTests.cs`, líneas 8-14](https://github.com/spareilleux/learn/blob/93f6f82/code/github-actions/dotnet/Slugs.Tests/SlugTests.cs#L8-L14):

```csharp
[Theory]
[InlineData("Hello, Wörld!", "hello-world")]
[InlineData("  GitHub   Actions  ", "github-actions")]
[InlineData("C# 14 & .NET 10", "c-14-net-10")]
[InlineData("", "")]
public void From_builds_a_lowercase_ascii_slug(string text, string expected) =>
    Assert.Equal(expected, Slug.From(text));
```

Antes de escribir YAML: **tiene que pasar en local**, con los mismos comandos que ejecutará la CI. Ahí aparecieron las dos primeras trampas de esta lección.

## Trampa 1: xUnit v3 y `dotnet test` con el SDK de .NET 10

Con `xunit.v3` 4.0.1, el primer `dotnet test` falló antes de ejecutar nada:

```text
error : Testing with VSTest target is no longer supported by Microsoft.Testing.Platform on .NET 10 SDK and later. If you use dotnet test, you should opt-in to the new dotnet test experience. For more information, see https://aka.ms/dotnet-test-mtp-error
```

xUnit v3 se ejecuta sobre [Microsoft.Testing.Platform](https://learn.microsoft.com/dotnet/core/testing/microsoft-testing-platform-intro), y el SDK de .NET 10 quiere que actives explícitamente el nuevo `dotnet test`, en `global.json` ([`dotnet/global.json`](https://github.com/spareilleux/learn/blob/main/code/github-actions/dotnet/global.json)):

```json
{
  "sdk": {
    "version": "10.0.100",
    "rollForward": "latestFeature"
  },
  "test": {
    "runner": "Microsoft.Testing.Platform"
  }
}
```

## Trampa 2: no hay `using Xunit` implícito

Siguiente error:

```text
CS0246: The type or namespace name 'Theory' could not be found (are you missing a using directive or an assembly reference?)
CS0246: The type or namespace name 'InlineData' could not be found (are you missing a using directive or an assembly reference?)
```

Con `ImplicitUsings` activado, este paquete 4.0.1 no añadía `Xunit` a los usings globales: el archivo de pruebas necesita `using Xunit;`. Después:

```text
Test run summary: Passed!
  total: 4
  failed: 0
  succeeded: 4
  skipped: 0
```

## El workflow

[`.github/workflows/gha-02-build.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-02-build.yml):

```yaml
# GitHub Actions course, lesson 2: build and test .NET and Java on three OSes
name: "GHA 02: build and test"

on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['code/github-actions/**', '.github/workflows/gha-02-build.yml']
  pull_request:
    paths: ['code/github-actions/**', '.github/workflows/gha-02-build.yml']

jobs:
  dotnet:
    name: dotnet (${{ matrix.os }})
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    defaults:
      run:
        working-directory: code/github-actions/dotnet
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-dotnet@v6
        with:
          global-json-file: code/github-actions/dotnet/global.json
      - run: dotnet --version
      - run: dotnet test

  java:
    name: java (${{ matrix.os }})
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    defaults:
      run:
        working-directory: code/github-actions/java
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-java@v6
        with:
          distribution: temurin
          java-version: '25'
          cache: maven
      - run: java --version
      - run: mvn -B verify
```

| Elemento | Efecto |
|---|---|
| `strategy.matrix.os` | un job por valor: 3 jobs `dotnet` y 3 jobs `java`, todos en paralelo |
| `fail-fast: false` | un fallo en Windows no cancela el job de macOS que sigue en curso (el valor por defecto, `true`, sí lo hace) |
| `name: dotnet (${{ matrix.os }})` | el nombre del job que se muestra en la ejecución; sin `name`, GitHub usa el id del job y todos los valores de la matrix, p. ej. `java (ubuntu-latest, 22)` |
| `defaults.run.working-directory` | cada `run:` empieza en esa carpeta (los steps `uses:` no se ven afectados) |
| [`actions/setup-dotnet`](https://github.com/actions/setup-dotnet) con `global-json-file` | instala el SDK que pide `global.json` |
| [`actions/setup-java`](https://github.com/actions/setup-java) con `cache: maven` | instala Temurin 25 y guarda `~/.m2/repository` en caché, con una clave basada en el hash de `pom.xml` |
| `mvn -B` | modo batch: sin colores ni barras de progreso de descarga en el log |

## Lo que muestra la ejecución

Los seis jobs pasaron. Extractos:

```text
dotnet (ubuntu-latest) | dotnet-install: Installed version is 10.0.401
dotnet (ubuntu-latest) | 10.0.401
java (ubuntu-latest)   | Resolved Java 25.0.4+1 from tool-cache
java (ubuntu-latest)   | openjdk 25.0.4.1 2026-08-18 LTS
java (ubuntu-latest)   | [INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
java (ubuntu-latest)   | [INFO] BUILD SUCCESS
```

- `global.json` indica `10.0.100` con `rollForward: latestFeature`: `setup-dotnet` instaló la **última** banda de características de 10.0, 10.0.401. Fija `"rollForward": "disable"` si necesitas exactamente un SDK.
- Temurin 25 ya estaba en la imagen de Ubuntu (`from tool-cache`): sin descarga.

**El shell no es el mismo en todas partes.** El mismo step `run: dotnet test` registró:

```text
dotnet (ubuntu-latest)  | shell: /usr/bin/bash -e {0}
dotnet (macos-latest)   | shell: /bin/bash -e {0}
dotnet (windows-latest) | shell: C:\Program Files\PowerShell\7\pwsh.EXE -command ". '{0}'"
```

En Windows, `run:` usa PowerShell 7 por defecto. `dotnet test` y `mvn -B verify` se comportan igual en ambos, pero un script con `$(pwd)`, `export` o cadenas con `&&` no. Define `defaults.run.shell: bash` para el job (Git Bash está instalado en los runners de Windows) cuando un script deba ser idéntico en los tres sistemas operativos.

## La caché, medida

La primera ejecución no encontró caché de Maven y guardó una; una segunda ejecución (iniciada con `gh workflow run gha-02-build.yml`) la restauró ([`setup-java/src/cache.ts`](https://github.com/actions/setup-java/blob/de7274f081f381c8f8158605e0321c36c376e2e6/src/cache.ts#L260-L275)):

```text
maven cache is not found
Cache saved with the key: setup-java-Linux-x64-maven-4b450ab7781caaed20d3b55ef20c4500aaacb6aad3f54b145929988a7515a1eb
```

```text
Cache restored from key: setup-java-Linux-x64-maven-4b450ab7781caaed20d3b55ef20c4500aaacb6aad3f54b145929988a7515a1eb
Cache hit occurred on the primary key setup-java-Linux-x64-maven-4b450ab7781caaed20d3b55ef20c4500aaacb6aad3f54b145929988a7515a1eb, not saving cache.
```

| Job | 1.ª ejecución (sin caché) | 2.ª ejecución (acierto de caché) |
|---|---|---|
| java (ubuntu-latest) | 16 s | 10 s |
| java (windows-latest) | 43 s | 28 s |
| java (macos-latest) | 20 s | 9 s |
| dotnet (ubuntu-latest) | 21 s | 22 s |
| dotnet (windows-latest) | 60 s | 57 s |
| dotnet (macos-latest) | 20 s | 22 s |

Los jobs de .NET no se aceleraron: todavía nada guarda en caché los paquetes NuGet. `setup-dotnet` tiene una opción `cache: true` basada en archivos `packages.lock.json`, medida en la [lección 5](../05-caches-and-artifacts/). La clave contiene el sistema operativo (`Linux-x64`, `Windows-x64`, `macOS-arm64`): cada sistema operativo tiene su propia caché. Y `macos-latest` es una máquina **arm64**.

## Puntos clave

- Primero haz que pase en local, exactamente con los comandos que ejecuta la CI.
- Una `matrix` multiplica un job; `fail-fast: false` deja que cada combinación termine.
- `setup-dotnet` lee `global.json`; `setup-java` instala un JDK y guarda Maven o Gradle en caché.
- `run:` es bash en Linux/macOS y PowerShell 7 en Windows, salvo que definas `shell`.
- Mide: aquí un acierto de la caché de Maven ahorró de 6 a 15 segundos por job; los jobs de Windows son los más lentos.

## Ejercicios

1. Añade `22` junto a `25` para que el job de Java se ejecute también con Java 22, en los tres sistemas operativos. ¿Cuántos jobs de Java se ejecutarán?

<details>
<summary>Solución</summary>

```yaml
    name: java ${{ matrix.java }} (${{ matrix.os }})
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        java: ['25', '22']
    steps:
      - uses: actions/setup-java@v6
        with:
          distribution: temurin
          java-version: ${{ matrix.java }}
          cache: maven
```

6 jobs (3 × 2). Pero el build falla con 22: `pom.xml` fija `maven.compiler.release` en 25. Comprobado con [`gha-02-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-02-exercises.yml):

```text
[INFO] BUILD FAILURE
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.15.0:compile (default-compile) on project slugs: Fatal error compiling: error: release version 25 not supported -> [Help 1]
```

Una matrix prueba combinaciones; el proyecto tiene que soportarlas.

</details>

2. Quieres que el job de Windows ejecute `dotnet test` en bash, como los demás. ¿Dónde pones `shell: bash` para que se aplique a cada `run:` del job?

<details>
<summary>Solución</summary>

```yaml
    defaults:
      run:
        shell: bash
        working-directory: code/github-actions/dotnet
```

`defaults.run` a nivel de job (o a nivel de workflow para todos los jobs). En Windows el log muestra entonces:

```text
shell: C:\Program Files\Git\bin\bash.EXE --noprofile --norc -e -o pipefail {0}
bash 5.3.15(2)-release, options ehB
```

Fíjate en `-o pipefail`: un `shell: bash` explícito también falla cuando falla un comando en medio de una tubería, cosa que no hace el `bash -e {0}` implícito de los runners de Linux.

</details>

3. Sin `using Xunit;`, ¿qué error mostraría la CI, y en cuántos jobs?

<details>
<summary>Solución</summary>

`CS0246: The type or namespace name 'Theory' could not be found`, en los tres jobs `dotnet`. Con `fail-fast: false` los tres se ejecutan hasta el final; con el valor por defecto `fail-fast: true`, el primer fallo cancela los otros jobs `dotnet` aún en curso — los jobs `java` vienen de otra definición de job, con su propia matrix, y no se ven afectados.

</details>

## Fuentes

- [Compilar y probar .NET — GitHub Docs](https://docs.github.com/actions/tutorials/build-and-test-code/net)
- [Compilar y probar Java con Maven — GitHub Docs](https://docs.github.com/actions/tutorials/build-and-test-code/java-with-maven)
- [Ejecutar variaciones de jobs en un workflow (matrix)](https://docs.github.com/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations)
- [Probar con `dotnet test` y Microsoft.Testing.Platform](https://learn.microsoft.com/dotnet/core/testing/unit-testing-with-dotnet-test)
- [Información general de `global.json`](https://learn.microsoft.com/dotnet/core/tools/global-json)
