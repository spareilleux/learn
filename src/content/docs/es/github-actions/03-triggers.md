---
title: 3. Disparadores, filtros y concurrencia
description: push y pull_request con filtros de ramas y rutas, ejecuciones manuales con inputs, programaciones, y grupos de concurrencia que cancelan o encolan ejecuciones.
sidebar:
  order: 3
---

## Elegir los eventos

La clave `on:` lista los eventos que inician una ejecución. Los que usas a diario:

| Evento | Inicia una ejecución cuando | Equivalente en Azure Pipelines |
|---|---|---|
| `push` | se hace push de commits a una rama o una etiqueta | `trigger:` |
| `pull_request` | se abre, se actualiza (`synchronize`) o se reabre un pull request | `pr:` |
| `workflow_dispatch` | alguien hace clic en *Run workflow*, o ejecuta `gh workflow run` | ejecución manual con `parameters:` |
| `schedule` | coincide una expresión cron | `schedules:` |
| `workflow_call` | otro workflow llama a este ([lección 6](../06-reuse/)) | plantillas |

[`.github/workflows/gha-03-triggers.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-03-triggers.yml) combina cuatro de ellos:

```yaml
# GitHub Actions course, lesson 3: events, filters, manual inputs, schedules, concurrency
name: "GHA 03: triggers"

on:
  push:
    branches: [main]
    paths: ['.github/workflows/gha-03-triggers.yml']
  workflow_dispatch:
    inputs:
      greeting:
        description: Who to greet
        type: string
        default: world
      loud:
        description: Shout the greeting
        type: boolean
        default: false
  schedule:
    - cron: '17 6 * * 1'   # Mondays 06:17 UTC

concurrency:
  group: gha-03-${{ github.ref }}
  cancel-in-progress: true

jobs:
  show:
    runs-on: ubuntu-latest
    steps:
      - name: Which event?
        run: |
          echo "event_name: ${{ github.event_name }}"
          echo "ref:        ${{ github.ref }}"
          echo "actor:      ${{ github.actor }}"
      - name: Manual inputs
        if: github.event_name == 'workflow_dispatch'
        run: |
          echo "greeting: ${{ inputs.greeting }}"
          echo "loud:     ${{ inputs.loud }}"
      - name: Scheduled run
        if: github.event_name == 'schedule'
        run: |
          echo "cron: ${{ github.event.schedule }}"
      - name: Slow step (to see concurrency cancel a run)
        run: sleep 60
```

## Filtros: `branches` y `paths`

`branches: [main]` ignora los pushes a otras ramas; `paths` ignora los pushes que no modifican ningún archivo que coincida. Todos los workflows de este sitio usan `paths` para que corregir una errata en una lección no vuelva a compilar el curso de Rust en tres sistemas operativos.

Dos advertencias de la documentación:

- **Checks obligatorios.** «Si se omite un workflow debido al filtrado de rutas, al filtrado de ramas o a un mensaje de commit, los checks asociados a ese workflow permanecerán en estado "Pending"». Si un workflow filtrado con `paths` es un status check *obligatorio* en una regla de protección de rama, un pull request que no toque esas rutas nunca podrá fusionarse.
- **Diffs grandes.** «Si el diff generado contiene más de 3.000 archivos y los archivos que coinciden con el filtro del workflow no están entre los primeros 3.000 que devuelve el filtro, el workflow **no** se ejecutará».

Y la trampa vista en la [lección 1](../01-first-workflow/): si el archivo no se puede analizar, sus filtros tampoco existen, y cada push produce una ejecución fallida.

## Ejecuciones manuales con inputs

`workflow_dispatch.inputs` declara parámetros tipados (`string`, `boolean`, `choice`, `number`, `environment`). Desde la terminal:

```powershell
gh workflow run gha-03-triggers.yml --field greeting=Grace
```

```text
##[group]Run echo "greeting: Grace"
echo "greeting: Grace"
echo "loud:     false"
greeting: Grace
loud:     false
```

`loud` no se pasó: tomó su `default`. Dos límites: el archivo del workflow debe existir **en la rama por defecto** para que funcionen el botón y `gh workflow run`, y un bloque `inputs` puede tener como máximo 25 propiedades de primer nivel.

**Los inputs están vacíos en los demás eventos.** El workflow de la lección 4 también tiene un input, `fail`. En un `push`, el step `if [ "${{ inputs.fail }}" = "true" ]` se convirtió en:

```text
if [ "" = "true" ]; then
```

Ni error ni valor por defecto: una cadena vacía. Comprueba `github.event_name` o dale al script un valor de reserva cuando un workflow tenga varios eventos.

## Programaciones

`cron: '17 6 * * 1'` significa «minuto 17, hora 6, cualquier día del mes, cualquier mes, lunes». Según la documentación:

- las ejecuciones programadas usan «el último commit de la rama por defecto»;
- «el intervalo más corto con el que puedes ejecutar workflows programados es una vez cada 5 minutos»;
- las ejecuciones «pueden retrasarse durante los periodos de mucha carga… Los momentos de mucha carga incluyen el comienzo de cada hora» — de ahí el minuto 17 en lugar del 0;
- «en un repositorio público, los workflows programados se desactivan automáticamente cuando no ha habido actividad en el repositorio durante 60 días».

La expresión está en UTC salvo que especifiques una zona horaria IANA, algo que la documentación ahora permite. *Por verificar: la primera ejecución del lunes de `gha-03`, que se anotará en el [diario](../journal/).*

## Concurrencia: cancelar o encolar

Un **grupo de concurrencia** es un nombre; «puede haber como máximo un job o workflow en ejecución en un grupo de concurrencia en cualquier momento». Lo que les pasa a los demás depende de `cancel-in-progress`:

| `cancel-in-progress` | Llega una nueva ejecución mientras otra está en curso |
|---|---|
| `false` (por defecto) | espera como *pending*; una ejecución pendiente que ya estaba esperando se **cancela** y se reemplaza |
| `true` | la que está en curso se cancela y la nueva arranca |

`gha-03` usa `group: gha-03-${{ github.ref }}` (un grupo por rama) y `cancel-in-progress: true`. Hice push de un cambio en el archivo y luego lancé dos ejecuciones manuales con diez segundos de diferencia mientras la primera estaba en su `sleep 60`:

```powershell
gh workflow run gha-03-triggers.yml --field greeting=Ada --field loud=true
gh workflow run gha-03-triggers.yml --field greeting=Grace
gh run list --workflow gha-03-triggers.yml --limit 3
```

| Inicio (UTC) | Evento | Resultado | Duración |
|---|---|---|---|
| 12:46:38 | push | cancelada | 1m10s |
| 12:47:19 | workflow_dispatch (Ada) | cancelada | 12s |
| 12:47:29 | workflow_dispatch (Grace) | éxito | 1m25s |

El log de la ejecución del push termina con:

```text
##[group]Run sleep 60
sleep 60
shell: /usr/bin/bash -e {0}
##[error]The operation was canceled.
```

La ejecución *Ada* se canceló antes incluso de que arrancara su job: su lista de jobs está vacía. Solo terminó la última ejecución del grupo. Es lo que quieres para un build de CI de una rama: nadie necesita el resultado de un commit que ya ha sido reemplazado.

### Cuando cancelar es un error: los despliegues

El workflow de despliegue de este sitio no tenía grupo de concurrencia. Dos pushes con 14 segundos de diferencia iniciaron dos despliegues, y el segundo falló:

```text
##[error]HttpError: Deployment request failed for cb69dca950b667b876d8d32cfe778a24b6320c59 due to in progress deployment. Please cancel 61e7e4235b7bc138f2f35cd7f61195bdaed4b019 first or wait for it to complete.
```

Cancelar un despliegue a medias es peor que esperar, así que la corrección [los encola](https://github.com/spareilleux/learn/blob/main/.github/workflows/deploy.yml):

```yaml
concurrency:
  group: pages
  cancel-in-progress: false
```

Con un nombre de grupo fijo (`pages`, no por rama) y sin cancelación, un despliegue se ejecuta hasta el final; si llegan varios pushes mientras tanto, solo espera el más reciente — los intermedios se cancelan mientras están pendientes, lo cual está bien, ya que el último commit los contiene.

## Puntos clave

- Los filtros `branches` y `paths` ahorran ejecuciones, pero un check obligatorio omitido se queda en *Pending*.
- Los inputs de `workflow_dispatch` son tipados, necesitan el archivo en la rama por defecto y están vacíos en los demás eventos.
- `schedule` es de mejor esfuerzo: rama por defecto, mínimo de 5 minutos, retrasos al comienzo de la hora, desactivado tras 60 días sin actividad en un repositorio público.
- `concurrency` con `cancel-in-progress: true` conserva solo la última ejecución de CI; para los despliegues, usa un grupo fijo sin cancelación.

## Ejercicios

1. Un pull request solo modifica `README.md`. `gha-02-build.yml` es un check obligatorio en `main`. ¿Qué muestra la página del pull request, y cuáles son dos formas de salir del bloqueo?

<details>
<summary>Solución</summary>

El check `dotnet (ubuntu-latest)` (y los demás) se queda en *Expected — Waiting for status to be reported*, y el botón de merge sigue bloqueado. Salidas: quitar `paths` del disparador `pull_request` y omitir el trabajo costoso dentro del job; o añadir un pequeño job que se ejecute siempre, que dependa de los demás, y hacer que *ese* job sea el check obligatorio. *Por verificar: la redacción exacta del check pendiente en la página del pull request.*

</details>

2. Escribe un grupo de concurrencia para un workflow de CI que cancele las ejecuciones superadas en los pull requests pero nunca cancele las ejecuciones en `main`.

<details>
<summary>Solución</summary>

```yaml
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
```

`cancel-in-progress` acepta una expresión. En un pull request, `github.ref` es `refs/pull/<number>/merge`, así que cada pull request tiene su propio grupo y los nuevos pushes cancelan la ejecución anterior; en `main` las ejecuciones se encolan.

</details>

3. Quieres un build nocturno a las 02:00 en París. ¿Por qué `cron: '0 2 * * *'` es un doble error?

<details>
<summary>Solución</summary>

Sin zona horaria son las 02:00 **UTC** (las 03:00 o las 04:00 en París según el horario de verano), y el minuto 0 es el momento de más carga, cuando es más probable que las ejecuciones programadas se retrasen. Elige un minuto que no sea redondo (`'23 0 * * *'` son las 01:23 o las 02:23 en París) o especifica la zona horaria.

</details>

## Fuentes

- [Eventos que desencadenan workflows](https://docs.github.com/actions/reference/workflows-and-actions/events-that-trigger-workflows)
- [Sintaxis de los workflows: `on.<push|pull_request>.paths`](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax#onpushpull_requestpull_request_targetpathspaths-ignore)
- [Controlar la concurrencia de workflows y jobs](https://docs.github.com/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency)
- [`gh workflow run` — manual de GitHub CLI](https://cli.github.com/manual/gh_workflow_run)
