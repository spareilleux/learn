---
title: 9. Depurar ejecuciones
description: Leer una ejecución fallida desde la terminal, agrupar y anotar los logs, activar los logs de depuración, volver a ejecutar solo lo que falló, y entender los timeouts, las cancelaciones y continue-on-error.
sidebar:
  order: 9
---

## Un workflow que falla a propósito

[`.github/workflows/gha-09-debug.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-09-debug.yml) tiene cuatro jobs, cada uno una situación con la que te vas a encontrar:

```yaml
# GitHub Actions course, lesson 9: reading a failing run, debug logging, re-runs, timeouts
name: "GHA 09: debugging"

on:
  workflow_dispatch:
    inputs:
      fail:
        description: Make the test step fail
        type: boolean
        default: true
  push:
    branches: [main]
    paths: ['.github/workflows/gha-09-debug.yml']

permissions:
  contents: read

jobs:
  noisy:
    runs-on: ubuntu-latest
    steps:
      - name: Groups, debug and notice messages
        run: |
          echo "::group::Environment of the step"
          echo "RUNNER_OS=$RUNNER_OS RUNNER_ARCH=$RUNNER_ARCH"
          echo "RUNNER_DEBUG='${RUNNER_DEBUG:-}'"
          echo "::endgroup::"
          echo "::debug::only visible when step debug logging is on"
          echo "::notice title=Lesson 9::a notice annotation"
      - name: Trace the commands with set -x
        run: |
          set -x
          version=$(date -u +%Y.%m.%d)
          test -n "$version"
      - name: Tests (fail on demand, attempt ${{ github.run_attempt }})
        run: |
          if [ "${{ inputs.fail }}" = "true" ] && [ "${{ github.run_attempt }}" = "1" ]; then
            echo "::error title=Flaky test::failed on attempt ${{ github.run_attempt }}"
            exit 1
          fi
          echo "tests passed on attempt ${{ github.run_attempt }}"

  independent:
    runs-on: ubuntu-latest
    steps:
      - run: echo "this job doesn't depend on noisy"

  allowed-to-fail:
    runs-on: ubuntu-latest
    continue-on-error: true
    steps:
      - run: exit 3

  timeout:
    runs-on: ubuntu-latest
    timeout-minutes: 1
    steps:
      - run: sleep 90
```

El step de tests solo falla en el primer intento: un **test inestable (flaky)**, el motivo más habitual para volver a ejecutar.

## Paso 1: el resumen, desde la terminal

```powershell
gh workflow run gha-09-debug.yml --field fail=true
gh run view 34850662582
```

El final de la salida lista las anotaciones — cada `::error`, `::warning` y `::notice`, más los errores que añade el runner:

```text
ANNOTATIONS
X The job has exceeded the maximum execution time of 1m0s
timeout: .github#1

X The operation was canceled.
timeout: .github#5

X Process completed with exit code 1.
noisy: .github#10

X failed on attempt 1
noisy: .github#9

- a notice annotation
noisy: .github#14

X Process completed with exit code 3.
allowed-to-fail: .github#5
```

Léelas antes que cualquier log: aquí ya dicen *qué* jobs fallaron y *por qué* — un timeout, un test, un fallo esperado. El `title=` de una anotación aparece en la página web, no en esta lista.

## Paso 2: solo los logs fallidos

```powershell
gh run view 34850662582 --log-failed
```

El log completo de este intento tiene 169 líneas; `--log-failed` devolvió 15, solo los steps fallidos de `noisy` y `allowed-to-fail`:

```text
noisy	Tests (fail on demand, attempt 1)	##[error]failed on attempt 1
noisy	Tests (fail on demand, attempt 1)	##[error]Process completed with exit code 1.
allowed-to-fail	Run exit 3	##[error]Process completed with exit code 3.
```

El job `timeout` no está: su step fue **cancelado**, no falló. Cuando un job parece desaparecer de `--log-failed`, mira su conclusión.

## Comandos de workflow que estructuran un log

En el log normal del primer step:

```text
##[group]Environment of the step
RUNNER_OS=Linux RUNNER_ARCH=X64
RUNNER_DEBUG=''
##[endgroup]
##[notice]a notice annotation
```

- `::group::title` … `::endgroup::` agrupan líneas en una sección plegable del log web.
- `::notice`, `::warning`, `::error` crean anotaciones (con `title=`, `file=`, `line=` — [lección 4](../04-expressions-and-outputs/)).
- `::debug::` no imprimió **nada**: los mensajes de depuración están ocultos salvo que los logs de depuración estén activados.

Para los scripts de shell, `set -x` imprime cada comando después de la expansión, el equivalente a ejecutar paso a paso:

```text
++ date -u +%Y.%m.%d
+ version=2026.09.14
+ test -n 2026.09.14
```

## Logs de depuración

Dos interruptores, como secretos o variables del repositorio, o para una sola reejecución con `--debug`:

| Ajuste | Añade |
|---|---|
| `ACTIONS_STEP_DEBUG` = `true` | líneas `##[debug]`: evaluación de condiciones, inputs, el archivo de script ejecutado, mensajes `::debug::` |
| `ACTIONS_RUNNER_DEBUG` = `true` | logs de diagnóstico del runner en el archivo de logs |

El tercer intento de la ejecución se lanzó con:

```powershell
gh run rerun 34850662582 --debug
```

El mismo step, ahora:

```text
##[debug]Evaluating condition for step: 'Groups, debug and notice messages'
##[debug]Evaluating: success()
##[debug]Evaluating success:
##[debug]=> true
##[debug]Result: true
##[debug]Starting: Groups, debug and notice messages
...
##[debug]/usr/bin/bash -e /home/runner/work/_temp/e3c00f12-b91a-4ef4-830d-2340170b7bc7.sh
::group::Environment of the step
##[group]Environment of the step
RUNNER_OS=Linux RUNNER_ARCH=X64
RUNNER_DEBUG='1'
::endgroup::
##[endgroup]
##[debug]only visible when step debug logging is on
##[notice]a notice annotation
```

- Cada `if:` muestra cómo se evaluó — la forma más rápida de entender un step que se omitió.
- `RUNNER_DEBUG` vale `1`: un script puede imprimir más cuando esta variable está definida.
- El job `noisy` pasó de 70 a 190 líneas de log.

El archivo de logs de ese intento, descargado con `gh api repos/spareilleux/learn/actions/runs/34850662582/attempts/3/logs > attempt3.zip`, contiene una carpeta por job con un archivo por step, y una carpeta `runner-diagnostic-logs`:

```text
runner-diagnostic-logs/103998873521-noisy.zip
    13448  Runner_20260914-134407-utc.log
    73191  Worker_20260914-134409-utc.log
```

El log *Runner* es el del agente que recoge los jobs; el log *Worker* es el del proceso que ejecuta los steps. Rara vez los necesitas, salvo cuando un job falla antes de su primer step.

## Volver a ejecutar

La documentación: «Las reejecuciones usan los privilegios del actor que desencadenó inicialmente el workflow … El workflow también usará el mismo `GITHUB_SHA` (SHA del commit) y el mismo `GITHUB_REF`». Una reejecución prueba el **mismo commit**: puede revelar un test inestable, no validar una corrección que acabas de subir.

El intento 2 se lanzó con `gh run rerun 34850662582 --failed`:

```text
noisy            success    attempt=2  13:42:13 → 13:42:16
timeout          cancelled  attempt=2  13:42:13 → 13:43:42
allowed-to-fail  failure    attempt=2  13:42:13 → 13:42:16
independent      success    attempt=2  13:40:15 → 13:40:18
```

- `noisy` pasó: `github.run_attempt` valía `2`, e incluso cambió el nombre del step (`Tests (fail on demand, attempt 2)`).
- Los tres jobs que no habían tenido éxito se ejecutaron de nuevo — incluido el cancelado; `independent` no se volvió a ejecutar: sus horas son las del intento 1, conservadas.
- Cada intento guarda sus propios logs (`attempts/1/logs`, `attempts/2/logs`…).

## Timeouts y conclusiones

`timeout-minutes` vale por defecto **360** minutos por job. El job `timeout` estaba limitado a 1 minuto y ejecutaba `sleep 90`:

```text
2026-09-14T13:44:10.0526092Z ##[group]Run sleep 90
2026-09-14T13:45:37.2574842Z ##[error]The operation was canceled.
2026-09-14T13:45:37.3009029Z Terminate orphan process: pid (2052) (sleep)
```

Cancelado a los 87 segundos, no a los 60 — en cada intento, y en el ejercicio con `sleep 300`. Trata el límite como «cancelado algún tiempo después del límite», y fíjalo muy por debajo del tiempo que estás dispuesto a pagar.

Las conclusiones de las ejecuciones, que deciden el icono rojo o gris:

| Ejecución | Jobs | Conclusión de la ejecución |
|---|---|---|
| push | `noisy` ✓, `independent` ✓, `allowed-to-fail` ✗ (continue-on-error), `timeout` cancelado | `cancelled` |
| dispatch, intento 1 | `noisy` ✗, `timeout` cancelado, los demás como arriba | `failure` |
| dispatch, intentos 2 y 3 | `noisy` ✓, `timeout` cancelado | `cancelled` |

Un timeout deja la ejecución en *cancelled*, no en *failed* — y una regla de notificación o un check obligatorio que solo busca fallos no lo detecta.

## Puntos clave

- Empieza por `gh run view <id>` (anotaciones), y después `gh run view <id> --log-failed`; los jobs cancelados no están en los logs fallidos.
- `::group::`, `::notice::` y `set -x` hacen legibles los logs; `::debug::` necesita los logs de depuración.
- `gh run rerun --debug` muestra cómo se evaluó cada `if:`, y añade los logs de diagnóstico del runner.
- `gh run rerun --failed` vuelve a ejecutar cada job que no tuvo éxito, sobre el mismo commit.
- Un timeout de job cancela el job (aquí 87 s para un límite de 1 minuto) y deja la ejecución en *cancelled*.

## Ejercicios

1. Mueve el timeout del job al step: `timeout-minutes: 1` en un step `sleep 300`, seguido de un step con `if: always()`. ¿Cuál es la conclusión del step, y se ejecuta el step siguiente?

<details>
<summary>Solución</summary>

Comprobado con [`gha-09-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-09-exercises.yml):

```text
step-timeout | Run date -u +%T | 13:46:49
step-timeout | Run date -u +%T | ##[error]The action 'Run date -u +%T' has timed out after 1 minutes.
step-timeout | Run date -u +%T | 13:48:01
```

El step **falló** (no fue cancelado) a los 72 segundos, el step `always()` se ejecutó, y la conclusión del job fue `failure`. El timeout a nivel de job de la misma ejecución canceló su job a los 87 segundos (13:46:49 → 13:48:16), con `sleep 300`: el retraso no depende del script.

</details>

2. El único job fallido de una ejecución tiene `continue-on-error: true`, y otro job lo incluye en `needs`. ¿Cuál es la conclusión de la ejecución, y qué contiene `needs.allowed-to-fail.result`?

<details>
<summary>Solución</summary>

```text
allowed-to-fail  failure
after            success
run conclusion   success
needs.allowed-to-fail.result=success
```

El job aparece como fallido, pero la ejecución tiene éxito — «Establécelo en `true` para permitir que una ejecución de workflow pase cuando este job falle» — y para el job dependiente, el resultado es `success`: `after` se ejecutó sin ningún `if:`. Un job dependiente no puede saber que el fallo se toleró.

</details>

3. Un job se ejecutó aunque esperabas que su `if:` lo omitiera. ¿Dónde puedes ver cómo evaluó GitHub la condición, sin logs de depuración?

<details>
<summary>Solución</summary>

En el log *system* del job, que forma parte del archivo de logs (`gh api repos/<owner>/<repo>/actions/runs/<run-id>/attempts/<n>/logs`), archivo `<job>/system.txt`. Para `noisy`, en el intento 1, sin depuración:

```text
Requested labels: ubuntu-latest
Job defined at: spareilleux/learn/.github/workflows/gha-09-debug.yml@refs/heads/main
Waiting for a runner to pick up this job...
Evaluating noisy.if
Evaluating: success()
Result: true
```

Un job sin `if:` se evalúa como `success()`. Para el `if:` de los **steps**, vuelve a ejecutar con `--debug`: las líneas `##[debug]Evaluating condition for step` aparecen en el log del step.

</details>

## Fuentes

- [Habilitar el registro de depuración](https://docs.github.com/actions/how-tos/monitor-workflows/enable-debug-logging)
- [Volver a ejecutar workflows y jobs](https://docs.github.com/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs)
- [Comandos de workflow](https://docs.github.com/actions/reference/workflows-and-actions/workflow-commands)
- [Sintaxis de workflow: `timeout-minutes`, `continue-on-error`](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idtimeout-minutes)
- [`gh run view`](https://cli.github.com/manual/gh_run_view) y [`gh run rerun`](https://cli.github.com/manual/gh_run_rerun)
