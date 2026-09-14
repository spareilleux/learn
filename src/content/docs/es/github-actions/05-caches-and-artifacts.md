---
title: 5. Cachés y artefactos
description: Los archivos de bloqueo de NuGet y la caché de setup-dotnet, actions/cache y sus claves, subir y descargar artefactos entre jobs — con el tiempo que la caché ahorró de verdad.
sidebar:
  order: 5
---

## Dos formas de conservar archivos

Cada job empieza en una máquina nueva ([lección 1](../01-first-workflow/)). GitHub ofrece dos almacenamientos que sobreviven a un job, y la documentación insiste en que «no se pueden usar indistintamente»:

| | Caché | Artefacto |
|---|---|---|
| Contiene | archivos que podrías regenerar: paquetes descargados, builds intermedios | archivos que un job **produjo**: informes de pruebas, paquetes, binarios |
| Compartido entre | ejecuciones del repositorio (por clave y rama) | los jobs de **una** ejecución, y las personas que lo descargan |
| ¿Falta? | el job debe funcionar igualmente, solo que más lento | el job que lo necesita falla |
| Duración | se elimina tras 7 días sin acceso, 10 GB por repositorio por defecto | 90 días por defecto, `retention-days` para acortarla |
| Actions | [`actions/cache`](https://github.com/actions/cache), o `cache:` en las actions `setup-*` | [`actions/upload-artifact`](https://github.com/actions/upload-artifact), [`actions/download-artifact`](https://github.com/actions/download-artifact) |
| Azure Pipelines | `Cache@2` | `PublishPipelineArtifact@1`, `DownloadPipelineArtifact@2` |

## Una caché de NuGet necesita archivos de bloqueo

La [lección 2](../02-build-and-test/) lo midió: la caché de Maven de `setup-java` ahorró de 6 a 15 segundos por job, mientras que los jobs de .NET no guardaban nada en caché. `setup-dotnet` tiene un input `cache: true`, pero su README dice que la clave de caché es el hash de los archivos `packages.lock.json`, y que «si el archivo de bloqueo no existe, esta action lanza un error». El proyecto de ejemplo no tenía ninguno.

Un [archivo de bloqueo de NuGet](https://learn.microsoft.com/nuget/consume-packages/package-references-in-project-files#locking-dependencies) registra la versión exacta y el hash del contenido de cada paquete, directo o transitivo — el equivalente de `package-lock.json` para npm. Una sola propiedad en un [`Directory.Build.props`](https://learn.microsoft.com/visualstudio/msbuild/customize-by-directory) junto a la solución lo activa para todos los proyectos ([`dotnet/Directory.Build.props`](https://github.com/spareilleux/learn/blob/main/code/github-actions/dotnet/Directory.Build.props)):

```xml
<Project>

  <PropertyGroup>
    <!-- Write packages.lock.json next to each project: setup-dotnet's cache key is its hash (lesson 5) -->
    <RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>
  </PropertyGroup>

</Project>
```

Un `dotnet restore` en local escribió entonces `Slugs/packages.lock.json` (5 líneas, sin paquetes) y `Slugs.Tests/packages.lock.json` (170 líneas: los tres paquetes de prueba y sus dependencias). Los dos están en el commit. En la CI, `dotnet restore --locked-mode` falla en lugar de actualizar el archivo en silencio cuando un paquete ya no coincide con él.

## El workflow

[`.github/workflows/gha-05-artifacts.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-05-artifacts.yml) tiene cuatro jobs: `test` en tres sistemas operativos con la caché de NuGet y un informe de pruebas, `pack` genera un paquete NuGet, `cache-demo` usa `actions/cache` directamente, y `report` descarga los artefactos de los dos primeros.

```yaml
# GitHub Actions course, lesson 5: dependency caches, actions/cache, build artifacts between jobs
name: "GHA 05: caches and artifacts"

on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['.github/workflows/gha-05-artifacts.yml', 'code/github-actions/dotnet/**']

jobs:
  test:
    name: test (${{ matrix.os }})
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    env:
      NUGET_PACKAGES: ${{ github.workspace }}/.nuget/packages
    defaults:
      run:
        working-directory: code/github-actions/dotnet
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-dotnet@v6
        with:
          global-json-file: code/github-actions/dotnet/global.json
          cache: true
          cache-dependency-path: code/github-actions/dotnet/*/packages.lock.json
      - run: dotnet restore --locked-mode
      - run: dotnet test --no-restore --report-xunit-junit --report-xunit-junit-filename slugs.junit.xml --results-directory TestResults
      - name: Upload the test report
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: test-results-${{ matrix.os }}
          path: code/github-actions/dotnet/TestResults/
          retention-days: 7

  pack:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: code/github-actions/dotnet
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-dotnet@v6
        with:
          global-json-file: code/github-actions/dotnet/global.json
      - run: dotnet pack Slugs/Slugs.csproj --configuration Release --output dist -p:Version=1.0.${{ github.run_number }}
      - uses: actions/upload-artifact@v7
        with:
          name: package
          path: code/github-actions/dotnet/dist/*.nupkg
          if-no-files-found: error

  cache-demo:
    runs-on: ubuntu-latest
    steps:
      - name: Restore the cache
        id: cache
        uses: actions/cache@v6
        with:
          path: expensive
          key: gha-05-expensive-${{ runner.os }}-v1
      - name: Show the cache-hit output
        run: echo "cache-hit='${{ steps.cache.outputs.cache-hit }}'"
      - name: Produce the files only on a miss
        if: steps.cache.outputs.cache-hit != 'true'
        run: |
          mkdir -p expensive
          date -u +%FT%TZ > expensive/created-at.txt
          echo "produced"
      - run: cat expensive/created-at.txt

  report:
    needs: [test, pack]
    if: ${{ !cancelled() }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v8
        with:
          pattern: test-results-*
          path: results
      - uses: actions/download-artifact@v8
        with:
          name: package
          path: package
      - run: find results package -type f | sort
      - name: Tests per OS
        run: |
          for f in results/*/slugs.junit.xml; do
            echo "$(dirname "$f"): $(grep -o 'tests="[0-9]*" failures="[0-9]*"' "$f" | head -1)"
          done
```

| Elemento | Por qué |
|---|---|
| `NUGET_PACKAGES` | mueve la carpeta global de paquetes de NuGet al workspace, como recomienda el README de `setup-dotnet`: así la caché solo contiene los paquetes de este proyecto, no lo que ya trae la imagen del runner |
| `cache-dependency-path` | los archivos de bloqueo no están en la raíz del repositorio, donde `setup-dotnet` busca por defecto |
| `--report-xunit-junit` | una opción de xUnit v3 (ver `dotnet test --help`) que escribe un informe JUnit XML; `--results-directory` elige la carpeta |
| `if: always()` en la subida | el informe es más útil precisamente cuando las pruebas **fallan** |
| `name: test-results-${{ matrix.os }}` | un artefacto por job de la matrix, con un nombre distinto |
| `if-no-files-found: error` | el valor por defecto es `warn`: una ruta equivocada no subiría nada y el job pasaría igualmente |

## Ejecución 1 → ejecución 2: lo que hizo la caché

La primera ejecución, en el push, no encontró caché y guardó una por sistema operativo al final del job (el step *Post*):

```text
test (ubuntu-latest) | Dotnet cache is not found
test (ubuntu-latest) | Cache saved with the key: dotnet-cache-Linux-557e0cce818be1e496015809f30b8f55625063a595165d73158bbd2bdf0b419c
```

Una segunda ejecución, iniciada con `gh workflow run gha-05-artifacts.yml`, la restauró:

```text
test (ubuntu-latest) | Cache hit for: dotnet-cache-Linux-557e0cce818be1e496015809f30b8f55625063a595165d73158bbd2bdf0b419c
test (ubuntu-latest) | Cache Size: ~54 MB (56306437 B)
test (ubuntu-latest) | Cache restored from key: dotnet-cache-Linux-557e0cce818be1e496015809f30b8f55625063a595165d73158bbd2bdf0b419c
test (ubuntu-latest) |   Restored /home/runner/work/learn/learn/code/github-actions/dotnet/Slugs.Tests/Slugs.Tests.csproj (in 294 ms).
test (ubuntu-latest) | Cache hit occurred on the primary key dotnet-cache-Linux-557e0cce818be1e496015809f30b8f55625063a595165d73158bbd2bdf0b419c, not saving cache.
```

El mismo hash en los tres sistemas operativos (los archivos de bloqueo son idénticos), con el prefijo `Linux`, `Windows` o `macOS`: tres cachés de unos 54 MB cada una, visibles con `gh cache list`.

Ahora lo que importa — la duración de los steps, según `gh api repos/spareilleux/learn/actions/runs/<run-id>/jobs`:

| Step | Ubuntu sin caché → acierto | Windows sin caché → acierto | macOS sin caché → acierto |
|---|---|---|---|
| `setup-dotnet` (instalación del SDK + restauración de la caché) | 9 s → 11 s | 35 s → 29 s | 20 s → 12 s |
| `dotnet restore --locked-mode` | 3 s → 1 s | 5 s → 4 s | 3 s → 1 s |
| *Post* `setup-dotnet` (guardado de la caché) | 1 s → 0 s | 5 s → 1 s | 4 s → 0 s |

El step de restauración pasó de 3 s a 1 s. Descargar 54 MB de caché cuesta más o menos lo mismo: en este proyecto diminuto, la caché de NuGet **no ahorra casi nada**, y las grandes variaciones del step `setup-dotnet` vienen de la descarga del SDK, no de la caché. Compensa cuando una restauración descarga cientos de paquetes, y es entonces cuando conviene añadirla — después de medir, como aquí. Los archivos de bloqueo merecen conservarse de todos modos: hacen que la CI restaure exactamente lo que se probó en local.

## `actions/cache` directamente

`setup-java` y `setup-dotnet` construyen la clave por ti. Con [`actions/cache`](https://github.com/actions/cache) eliges tú mismo `path` y `key`. El job `cache-demo`, en las dos ejecuciones:

```text
Run 1
Cache not found for input keys: gha-05-expensive-Linux-v1
cache-hit=''
produced
2026-09-14T13:12:25Z
Cache saved with key: gha-05-expensive-Linux-v1

Run 2
Cache restored from key: gha-05-expensive-Linux-v1
cache-hit='true'
2026-09-14T13:12:25Z
Cache hit occurred on the primary key gha-05-expensive-Linux-v1, not saving cache.
```

- Sin acierto, `cache-hit` es una **cadena vacía**, no `'false'`: comprueba `!= 'true'`, nunca `== 'false'`.
- La segunda ejecución imprimió la fecha escrita por la primera: los archivos volvieron.
- Una caché **nunca se actualiza**: con un acierto no se guarda nada, aunque el job haya cambiado los archivos. Para guardar contenido nuevo, cambia la clave — aquí el sufijo `-v1`, o un `hashFiles()` de los archivos que definen el contenido.
- La caché la guarda un step *Post*, al final del job, solo si el job tuvo éxito (`post-if: success()` en el `action.yml` de la action).

### Qué cachés puede ver una ejecución

Según la documentación: «las ejecuciones de workflow pueden restaurar cachés creadas en la rama actual o en la rama por defecto», además de la rama base en un pull request; no las cachés de ramas hijas o hermanas. Una caché creada por una ejecución `pull_request` pertenece a la ref de merge y «solo pueden restaurarla las nuevas ejecuciones del pull request». En la práctica: deja que un `push` a `main` llene las cachés, y cada rama y cada pull request parten de ellas.

## Artefactos

Cada job `test` subió su informe, `pack` subió el paquete:

```text
test (ubuntu-latest) | Artifact test-results-ubuntu-latest has been successfully uploaded! Final size is 510 bytes. Artifact ID is 10348099499
pack                 | Successfully created package '/home/runner/work/learn/learn/code/github-actions/dotnet/dist/Slugs.1.0.1.nupkg'.
pack                 | Artifact package has been successfully uploaded! Final size is 3463 bytes. Artifact ID is 10349121193
```

`report` los descargó. Con `pattern`, cada artefacto que coincide va a su propia subcarpeta (`merge-multiple: true` pondría todos los archivos en una sola carpeta):

```text
Found 4 artifact(s)
Filtering artifacts by pattern 'test-results-*'
Total of 3 artifact(s) downloaded
package/Slugs.1.0.1.nupkg
results/test-results-macos-latest/slugs.junit.xml
results/test-results-ubuntu-latest/slugs.junit.xml
results/test-results-windows-latest/slugs.junit.xml
results/test-results-macos-latest: tests="4" failures="0"
results/test-results-ubuntu-latest: tests="4" failures="0"
results/test-results-windows-latest: tests="4" failures="0"
```

Fechas de caducidad, según `gh api repos/spareilleux/learn/actions/runs/<run-id>/artifacts`: 7 días para los informes (`retention-days: 7`), 90 días para el paquete — el valor por defecto del repositorio, el máximo permitido para un repositorio público.

Los mismos artefactos en tu máquina, con la [CLI de GitHub](https://cli.github.com/manual/gh_run_download):

```powershell
gh run download 34848185308 --repo spareilleux/learn --name package --dir package
gh run download 34848185308 --repo spareilleux/learn --pattern "test-results-*" --dir results
```

```text
package/Slugs.1.0.2.nupkg
results/test-results-macos-latest/slugs.junit.xml
results/test-results-ubuntu-latest/slugs.junit.xml
results/test-results-windows-latest/slugs.junit.xml
```

## Puntos clave

- Caché = archivos regenerables compartidos entre ejecuciones; artefacto = archivos producidos por una ejecución, compartidos entre sus jobs y con personas.
- `setup-dotnet` `cache: true` requiere `packages.lock.json` (`RestorePackagesWithLockFile`); restaura con `--locked-mode`.
- Mide: aquí la caché de NuGet convirtió una restauración de 3 s en 1 s, y descargarla costó lo mismo.
- `cache-hit` es `'true'` o vacío; una caché es inmutable, así que cambia la clave para renovarla.
- Da a cada job de la matrix su propio nombre de artefacto, define `if-no-files-found: error` y acorta `retention-days` para los informes.

## Ejercicios

1. Dos jobs de matrix (`ubuntu-latest`, `macos-latest`) suben un artefacto con el **mismo** nombre, `os`, que contiene un archivo con el nombre del sistema operativo. Un job posterior descarga `name: os`. ¿Qué pasa?

<details>
<summary>Solución</summary>

El README de upload-artifact dice que «los artefactos creados por upload-artifact@v4 son inmutables», y advierte que en una matrix, subir al mismo artefacto significa que «encontrarás errores de conflicto». No es lo que ocurrió en [`gha-05-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-05-exercises.yml), tres veces seguidas: las dos subidas tuvieron éxito y la ejecución tenía **dos** artefactos llamados `os`.

```text
same-name (macos-latest)  | Artifact os has been successfully uploaded! Final size is 141 bytes. Artifact ID is 10348738133
same-name (ubuntu-latest) | Artifact os has been successfully uploaded! Final size is 142 bytes. Artifact ID is 10348957530
same-name-download        | Downloading single artifact
same-name-download        | ubuntu-latest
```

La descarga eligió uno de ellos sin ningún aviso — el de Ubuntu, tanto en el job como con `gh run download --name os`. Cuál se elige no está documentado: *por verificar* si es estable. En cualquier caso, un informe puede desaparecer en silencio. Pon el valor de la matrix en el nombre.

</details>

2. Quita el input `cache-dependency-path` y usa `dotnet-version: 10.0.x` en lugar de `global-json-file`, manteniendo `cache: true`. ¿Qué hace el job?

<details>
<summary>Solución</summary>

Falla en el step `setup-dotnet`, después de instalar el SDK ([`setup-dotnet/src/cache-restore.ts`](https://github.com/actions/setup-dotnet/blob/a98b56852c35b8e3190ac28c8c2271da59106c68/src/cache-restore.ts#L38-L47)):

```text
##[error]Dependencies lock file is not found in /home/runner/work/learn/learn. Supported file patterns: packages.lock.json
```

Sin `cache-dependency-path`, la action busca `packages.lock.json` solo en la raíz del repositorio. La caché no es opcional una vez que la pides: sin archivo de bloqueo, no hay job.

</details>

3. Un step usa `key: counter-${{ github.run_id }}` y `restore-keys: counter-`, y luego suma uno a un número guardado en la carpeta en caché. ¿Qué muestran `cache-hit` y el contador en la primera ejecución, y en la segunda?

<details>
<summary>Solución</summary>

```text
Run 1
Cache not found for input keys: gha-05-counter-34847802892, gha-05-counter-
cache-hit=''
counter is now 1
Cache saved with key: gha-05-counter-34847802892

Run 2
Cache restored from key: gha-05-counter-34847802892
cache-hit='false'
counter is now 2
Cache saved with key: gha-05-counter-34848189352
```

En la ejecución 2 la clave exacta no existía (nuevo `run_id`), pero el prefijo `gha-05-counter-` coincidió con la caché más reciente: `cache-hit` es `'false'` — una coincidencia parcial —, los archivos se restauran igualmente y, como no se encontró la clave exacta, se guarda una caché nueva al final. Así se construye una caché incremental que mejora de ejecución en ejecución, a costa de una nueva entrada de caché por ejecución.

</details>

## Fuentes

- [Referencia de la caché de dependencias](https://docs.github.com/actions/reference/workflows-and-actions/dependency-caching)
- [Artefactos de workflow](https://docs.github.com/actions/concepts/workflows-and-actions/workflow-artifacts)
- [Almacenar y compartir datos con artefactos de workflow](https://docs.github.com/actions/tutorials/store-and-share-data)
- [`actions/setup-dotnet`: guardar en caché los paquetes NuGet](https://github.com/actions/setup-dotnet#caching-nuget-packages)
- [`actions/upload-artifact`](https://github.com/actions/upload-artifact) y [`actions/download-artifact`](https://github.com/actions/download-artifact)
- [Bloquear dependencias — NuGet](https://learn.microsoft.com/nuget/consume-packages/package-references-in-project-files#locking-dependencies)
