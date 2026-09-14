---
title: 6. Workflows reutilizables y acciones compuestas
description: Deja de copiar YAML — una acción compuesta para steps repetidos, un workflow reutilizable para jobs enteros, con inputs, salidas, una matrix, y lo que el workflow llamado puede ver y lo que no.
sidebar:
  order: 6
---

## El problema de copiar y pegar

Después de cinco lecciones, las mismas cuatro líneas aparecen en varios workflows: `setup-dotnet` con `global-json-file`, la caché de NuGet, `dotnet restore --locked-mode`. GitHub Actions tiene dos formas de compartirlas, que quien desarrolla en C# puede asociar a ideas conocidas:

| | Acción compuesta | Workflow reutilizable |
|---|---|---|
| Comparte | una secuencia de **steps** | **jobs** enteros |
| Archivo | `action.yml` en su propia carpeta | un workflow en `.github/workflows/` con `on: workflow_call` |
| Se llama desde | un step: `uses: ./.github/actions/<name>` | un job: `uses: ./.github/workflows/<file>.yml` |
| Elige el runner | no, se ejecuta en el job del llamador | sí, cada job tiene su propio `runs-on` |
| Secretos | «No puede usar secretos» directamente — pásalos como inputs | recibe `secrets:` o `secrets: inherit` |
| En el log | «Se registra como un solo step aunque contenga varios steps» | cada job y cada step se registran normalmente |
| Analogía con C# | un método auxiliar llamado en medio de tu código | una plantilla de build completa |
| Azure Pipelines | plantilla de step | plantilla de job o de stage |

Las citas vienen de la tabla comparativa de la documentación. Ambos pueden vivir en el mismo repositorio o llamarse desde otro (`owner/repo/path@ref`).

## Una acción compuesta

[`.github/actions/dotnet-restore/action.yml`](https://github.com/spareilleux/learn/blob/main/.github/actions/dotnet-restore/action.yml):

```yaml
# GitHub Actions course, lesson 6: a composite action that installs the SDK and restores with the NuGet cache
name: Set up and restore a .NET solution
description: Installs the SDK pinned by global.json, then restores with the NuGet cache and the lock files.

inputs:
  directory:
    description: Folder that contains global.json, the solution and the packages.lock.json files
    required: true

outputs:
  sdk-version:
    description: The SDK version reported by dotnet --version
    value: ${{ steps.sdk.outputs.version }}

runs:
  using: composite
  steps:
    - name: Keep NuGet packages in the workspace
      shell: bash
      run: echo "NUGET_PACKAGES=$GITHUB_WORKSPACE/.nuget/packages" >> "$GITHUB_ENV"
    - uses: actions/setup-dotnet@v6
      with:
        global-json-file: ${{ inputs.directory }}/global.json
        cache: true
        cache-dependency-path: ${{ inputs.directory }}/*/packages.lock.json
    - id: sdk
      shell: bash
      working-directory: ${{ inputs.directory }}
      run: echo "version=$(dotnet --version)" >> "$GITHUB_OUTPUT"
    - shell: bash
      working-directory: ${{ inputs.directory }}
      run: dotnet restore --locked-mode
```

- Los `inputs` se leen con `${{ inputs.directory }}`; una salida debe asociarse explícitamente a un step interno (`value: ${{ steps.sdk.outputs.version }}`).
- Cada step `run:` de una acción compuesta necesita un `shell:` — el ejercicio 1 muestra qué pasa sin él.
- El primer step escribe en `$GITHUB_ENV`: la variable existe para los steps siguientes de la acción **y** para el resto del job del llamador. Una acción compuesta comparte la máquina, el workspace y el entorno del job.

## Un workflow reutilizable

[`.github/workflows/gha-06-dotnet-test.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-06-dotnet-test.yml) usa la acción y ejecuta las pruebas:

```yaml
# GitHub Actions course, lesson 6: a reusable workflow that tests the .NET sample on one OS
name: "GHA 06: reusable .NET test"

on:
  workflow_call:
    inputs:
      os:
        description: Runner label
        type: string
        default: ubuntu-latest
    outputs:
      sdk-version:
        description: SDK used by the tests
        value: ${{ jobs.test.outputs.sdk-version }}
      tested-on:
        description: Operating system of the runner
        value: ${{ jobs.test.outputs.tested-on }}

jobs:
  test:
    runs-on: ${{ inputs.os }}
    outputs:
      sdk-version: ${{ steps.setup.outputs.sdk-version }}
      tested-on: ${{ runner.os }}
    steps:
      - uses: actions/checkout@v7
      - id: setup
        uses: ./.github/actions/dotnet-restore
        with:
          directory: code/github-actions/dotnet
      - run: dotnet test --no-restore
        working-directory: code/github-actions/dotnet
      - name: What the called workflow sees
        shell: bash
        run: |
          echo "event_name:         ${{ github.event_name }}"
          echo "github.workflow:    ${{ github.workflow }}"
          echo "github.workflow_ref: ${{ github.workflow_ref }}"
          echo "job.workflow_ref:   ${{ job.workflow_ref }}"
          echo "COURSE from caller: '$COURSE'"
          echo "NUGET_PACKAGES:     $NUGET_PACKAGES"
```

Las salidas suben dos niveles: step → job (`jobs.test.outputs`) → workflow (`on.workflow_call.outputs`).

Y el llamador, [`.github/workflows/gha-06-reuse.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-06-reuse.yml):

```yaml
# GitHub Actions course, lesson 6: calling a reusable workflow with a matrix, and reading its outputs
name: "GHA 06: reuse"

on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['.github/workflows/gha-06-reuse.yml', '.github/workflows/gha-06-dotnet-test.yml', '.github/actions/dotnet-restore/**']

env:
  COURSE: github-actions

jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest]
    uses: ./.github/workflows/gha-06-dotnet-test.yml
    with:
      os: ${{ matrix.os }}

  summary:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "COURSE in the caller: '$COURSE'"
          echo "sdk-version: ${{ needs.test.outputs.sdk-version }}"
          echo "tested-on:   ${{ needs.test.outputs.tested-on }}"
```

Un job que llama a un workflow reutilizable **no** tiene `runs-on` ni `steps`: solo `name`, `uses`, `with`, `secrets`, `strategy`, `needs`, `if`, `concurrency`, `permissions` y `cache-mode`.

## Lo que muestra la ejecución

```text
test (ubuntu-latest) / test   success
test (windows-latest) / test  success
summary                       success
```

Los jobs se llaman `<caller job> / <called job>`. En la API, el job de Ubuntu tiene estos steps:

```text
1 Set up job
2 Run actions/checkout@v7
3 Run ./.github/actions/dotnet-restore
4 Run dotnet test --no-restore
5 What the called workflow sees
9 Post Run ./.github/actions/dotnet-restore
10 Post Run actions/checkout@v7
11 Complete job
```

Los cuatro steps de la acción compuesta son **un solo** step (3), y sus logs son grupos anidados dentro de él; los números 6 a 8 no aparecen en la lista. El step *Post* 9 es el step post de `setup-dotnet` dentro de la acción — el guardado de la caché de NuGet, omitido aquí porque hubo acierto de caché.

### Lo que ve el workflow llamado

```text
event_name:         push
github.workflow:    GHA 06: reuse
github.workflow_ref: spareilleux/learn/.github/workflows/gha-06-reuse.yml@refs/heads/main
job.workflow_ref:   spareilleux/learn/.github/workflows/gha-06-dotnet-test.yml@refs/heads/main
COURSE from caller: ''
NUGET_PACKAGES:     /home/runner/work/learn/learn/.nuget/packages
```

- El contexto `github` es el del **llamador**: mismo evento, mismo nombre de workflow. Para saber qué archivo define el job en curso, lee `job.workflow_ref`.
- `COURSE` está vacía. La documentación es explícita: «las variables de entorno definidas en un contexto `env` a nivel de workflow en el workflow llamador no se propagan al workflow llamado». Pasa los valores como `inputs`, o usa `vars` (variables del repositorio).
- `NUGET_PACKAGES` venía del `$GITHUB_ENV` de la acción compuesta y llegó a los steps siguientes del job.

¿Y las cachés? La acción restauró `dotnet-cache-Linux-557e0cce…`, la caché guardada por el workflow de la [lección 5](../05-caches-and-artifacts/): misma clave, misma ruta, misma rama — las cachés pertenecen al repositorio, no a un workflow.

### Las salidas de una matrix

```text
COURSE in the caller: 'github-actions'
sdk-version: 10.0.401
tested-on:   Windows
```

Dos jobs de matrix definen `tested-on` y el llamador recibió un solo valor: Windows, el job que terminó el último (13:25:06, frente a 13:24:29 de Ubuntu). Es la regla documentada: «la salida será la definida por el último workflow reutilizable de la matrix en completarse con éxito que realmente define un valor». No uses una salida de matrix para nada que cambie entre combinaciones; sube en su lugar un artefacto por combinación.

## Límites que conviene conocer

Según la referencia:

- «Puedes conectar hasta diez niveles de workflows» (el llamador más nueve niveles anidados);
- «Puedes llamar a un máximo de 50 workflows reutilizables únicos desde un solo archivo de workflow»;
- un workflow reutilizable referenciado por rama o por tag puede cambiar sin avisar; un SHA de commit, no. La [lección 7](../07-security/) vuelve sobre la fijación de versiones.

## Puntos clave

- **Steps** repetidos → acción compuesta, llamada por un step, ejecutada en el job del llamador. **Jobs** repetidos → workflow reutilizable, llamado por un job, con sus propios runners.
- Los steps `run:` de una acción compuesta necesitan `shell:`; las acciones y workflows locales necesitan primero `actions/checkout` (para las acciones) y una ruta que empiece por `./`.
- El workflow llamado ve el contexto `github` del llamador pero no su `env`; usa `inputs`, `outputs` y `job.workflow_ref`.
- Con una matrix, la salida de un workflow reutilizable es la del último job en terminar.

## Ejercicios

1. Quita `shell: bash` de un step `run:` de una acción compuesta. ¿Cuándo se detecta el error, y qué dice?

<details>
<summary>Solución</summary>

Solo cuando un job ejecuta la acción — el push que la incluye en un commit no se queja. Comprobado con [`gha-06-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-06-exercises.yml) y una acción [`exercise-no-shell`](https://github.com/spareilleux/learn/blob/main/.github/actions/exercise-no-shell/action.yml) rota a propósito:

```text
##[error]/home/runner/work/learn/learn/./.github/actions/exercise-no-shell/action.yml (Line: 8, Col: 7): Required property is missing: shell
##[error]Failed to load /home/runner/work/learn/learn/./.github/actions/exercise-no-shell/action.yml
```

En un workflow, `run:` tiene un shell por defecto; en una acción compuesta, no tiene ninguno.

</details>

2. Un job empieza directamente con `uses: ./.github/actions/dotnet-restore`, sin `actions/checkout`. ¿Qué pasa?

<details>
<summary>Solución</summary>

```text
##[error]Can't find 'action.yml', 'action.yaml' or 'Dockerfile' under '/home/runner/work/learn/learn/.github/actions/dotnet-restore'. Did you forget to run actions/checkout before running your local action?
```

Una acción local se lee del workspace, que está vacío hasta el checkout. Un workflow reutilizable referenciado con `./` no tiene este problema: GitHub lo lee del repositorio antes de que empiece el job.

</details>

3. El llamador pasa `configuration: Release` en `with:`, pero `gha-06-dotnet-test.yml` solo declara el input `os`. ¿Cuándo falla?

<details>
<summary>Solución</summary>

Antes de que empiece ningún job. La ejecución termina con la conclusión `startup_failure` y sin jobs; `gh run view` solo dice «This run likely failed because of a workflow file issue», y la página de la ejecución muestra:

```text
The workflow is not valid. .github/workflows/gha-06-invalid-input.yml (Line: 13, Col: 22): Invalid input, configuration is not defined in the referenced workflow.
```

Comprobado en una rama temporal, para que un workflow no válido no hiciera fallar cada push a `main` (ver la [lección 1](../01-first-workflow/)). Los inputs son un contrato que se comprueba al crear la ejecución, como los parámetros de un método en tiempo de compilación.

</details>

## Fuentes

- [Reutilizar workflows](https://docs.github.com/actions/how-tos/reuse-automations/reuse-workflows)
- [Referencia de workflows reutilizables](https://docs.github.com/actions/reference/workflows-and-actions/reusable-workflows)
- [Reutilizar configuraciones de workflow: workflows reutilizables frente a acciones compuestas](https://docs.github.com/actions/concepts/workflows-and-actions/reusing-workflow-configurations)
- [Sintaxis de metadatos para GitHub Actions (`action.yml`)](https://docs.github.com/actions/reference/workflows-and-actions/metadata-syntax)
- [Referencia de contextos: `job.workflow_ref`](https://docs.github.com/actions/reference/workflows-and-actions/contexts)
