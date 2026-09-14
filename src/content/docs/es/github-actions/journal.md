---
title: Diario
description: Notas de progreso fechadas — ejecuciones, errores y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Código de ejemplo: la misma función de slug en .NET (xUnit v3) y Java (JUnit 6)
- [x] Lección 1: primer workflow, leer ejecuciones con `gh`
- [x] Lección 2: build con matrix en tres sistemas operativos, setup-dotnet, setup-java, caché de Maven
- [x] Lección 3: disparadores, filtros, inputs, concurrencia
- [x] Lección 4: expresiones, contextos, salidas, condiciones
- [x] Lección 5: cachés y artefactos (caché de NuGet con `packages.lock.json`, `actions/cache`, artefactos entre jobs)
- [x] Lección 6: workflows reutilizables y acciones compuestas
- [x] Lección 7: seguridad — permisos, secretos, fijación de versiones, OIDC
- [x] Lección 8: desplegar en GitHub Pages
- [x] Lección 9: depurar ejecuciones
- [x] Lección 10: escribir tu propia acción

## 2026-09-14 — Primero en local: dos trampas de xUnit v3

Antes de escribir ningún workflow, `dotnet test` en el proyecto de ejemplo (SDK 10.0.112 en local, `xunit.v3` 4.0.1) falló dos veces:

1. `Testing with VSTest target is no longer supported by Microsoft.Testing.Platform on .NET 10 SDK and later.` Corrección: `"test": { "runner": "Microsoft.Testing.Platform" }` en `global.json`.
2. `CS0246: The type or namespace name 'Theory' could not be found`. Con `ImplicitUsings` activado, esta versión del paquete no añadía `using Xunit`. Corrección: el `using` en el archivo de pruebas.

El lado Java (`mvn -B verify`, JUnit 6.1.3, Maven 3.9.16) pasó a la primera.

## 2026-09-14 — Primer push: cuatro workflows, uno inválido

El push de los cuatro workflows de las lecciones (commit `61e7e42`) los inició todos. `GHA 01`, `GHA 02` (6 jobs) y `GHA 04` pasaron. `GHA 03` apareció con el nombre de su archivo, falló en 0 s, sin ningún job: `You have an error in your yaml syntax on line 41`, una línea `run: echo "cron: …"` (un valor sin comillas que contiene `: `). El push siguiente, sin relación con ese archivo, lo hizo fallar de nuevo, a pesar de su filtro `paths`.

Un segundo commit la misma tarde repitió el error en `gha-04-exercises.yml` (`run: echo "next: $BUILD_LABEL"`); esta vez `python -c "import yaml; yaml.safe_load(...)"` lo detectó antes del push. Lección: validar el YAML en local, siempre.

## 2026-09-14 — Colisión de dos despliegues de este sitio

Los pushes `61e7e42` y `cb69dca`, con 14 s de diferencia, iniciaron cada uno `Deploy to GitHub Pages`. El segundo job de despliegue falló:

```text
##[error]HttpError: Deployment request failed for cb69dca950b667b876d8d32cfe778a24b6320c59 due to in progress deployment. Please cancel 61e7e4235b7bc138f2f35cd7f61195bdaed4b019 first or wait for it to complete.
```

El sitio se quedó en la versión anterior hasta el push siguiente. Corrección en `deploy.yml` (commit `5c9896f`): `concurrency: { group: pages, cancel-in-progress: false }`. Varias sesiones hacen push a este repositorio, así que las colisiones iban a volver a ocurrir.

## 2026-09-14 — Mediciones

- Caché de Maven, primera ejecución → segunda ejecución de `gha-02`: Ubuntu 16 s → 10 s, Windows 43 s → 28 s, macOS 20 s → 9 s. Jobs de .NET sin cambios (21/60/20 s → 22/57/22 s): todavía no hay caché de NuGet.
- `global.json` `10.0.100` + `latestFeature` → `setup-dotnet` instaló el SDK 10.0.401.
- Temurin 25.0.4 venía preinstalado en `ubuntu-latest` (`Resolved Java 25.0.4+1 from tool-cache`).
- `macos-latest` es arm64 (clave de caché `setup-java-macOS-arm64-maven-…`).
- Shell por defecto de `run:`: `/usr/bin/bash -e {0}` (Ubuntu), `/bin/bash -e {0}` (macOS), `pwsh -command ". '{0}'"` (Windows). `shell: bash` explícito en Windows: `bash.EXE --noprofile --norc -e -o pipefail {0}`, bash 5.3.15.
- Permisos por defecto de `GITHUB_TOKEN` en este repositorio: `Contents: read`, `Metadata: read`, `Packages: read`. El token tenía 377 caracteres.
- Concurrencia con `cancel-in-progress: true`: la ejecución del push fue cancelada por una ejecución manual 41 s después, cancelada a su vez 10 s más tarde por otra antes de que arrancara su job.

## 2026-09-14 — Lección 5: una caché que no ahorra nada, un conflicto de artefactos que no ocurre

- `setup-dotnet` `cache: true` sin ningún `packages.lock.json`: `Dependencies lock file is not found in /home/runner/work/learn/learn`. Se añadió `RestorePackagesWithLockFile` en `Directory.Build.props`, se hizo commit de los dos archivos de bloqueo, `dotnet restore --locked-mode` en la CI.
- Caché de NuGet, sin caché → acierto: step de restauración 3 s → 1 s (Ubuntu, macOS), 5 s → 4 s (Windows), para una caché de 54 MB por sistema operativo. La descarga de la caché cuesta más o menos lo que ahorra en un proyecto con tres paquetes de prueba. Se mantiene por la lección y por los archivos de bloqueo.
- Salida `cache-hit` de `actions/cache`: vacía sin acierto, `false` con una coincidencia de `restore-keys`, `true` con un acierto exacto.
- Dos jobs de matrix que suben un artefacto llamado `os`: el README anuncia errores de conflicto; en tres ejecuciones de tres, las dos subidas tuvieron éxito y la ejecución tenía dos artefactos llamados `os`. `download-artifact` y `gh run download --name os` devolvieron ambos el de Ubuntu, sin aviso.
- Caducidad de los artefactos: 7 días con `retention-days: 7`, si no, 90 días (`gh api repos/spareilleux/learn/actions/permissions/artifact-and-log-retention` → `{"days":90,"maximum_allowed_days":90}`).

## 2026-09-14 — Lección 6: la reutilización, y una rama para un workflow no válido

- La acción compuesta `dotnet-restore` restauró la caché de NuGet guardada por `gha-05`: misma clave y misma ruta, otro workflow. Las cachés pertenecen al repositorio y a la rama.
- En el workflow llamado: `github.workflow` es el nombre del llamador, `job.workflow_ref` apunta a `gha-06-dotnet-test.yml`, el `env` a nivel de workflow del llamador está vacío.
- Matrix de dos llamadas a un workflow reutilizable: la salida `tested-on` fue `Windows`, el job que terminó el último.
- `run:` de acción compuesta sin `shell:`: `Required property is missing: shell`, solo cuando un job ejecuta la acción.
- Input no declarado: `startup_failure`, ningún job, y `gh run view` no muestra el motivo (la página de la ejecución, sí). Probado desde una rama temporal `gha-06-invalid` para que `main` nunca contuviera un workflow no válido. El borrado de la rama remota lo bloqueó un hook de seguridad local: sigue ahí, hay que borrarla a mano.

## 2026-09-14 — Lección 7: permisos que no restringen y una inyección que se ejecuta

- `gh run list` desde un job con solo `contents: read` (sin `actions: read`) funcionó: datos públicos de un repositorio público. Se sustituyó por la creación de una etiqueta con nombre vacío: 403 `Resource not accessible by integration` sin `issues: write`, 422 `Validation Failed` con él — no se creó nada en ningún caso.
- `permissions: actions: read` a nivel de job → el token perdió `Contents`, y `actions/checkout` funcionó igualmente en este repositorio público.
- El input de `workflow_dispatch` `$(whoami)`, pegado con `${{ }}` en `run:`, imprimió `runner`; a través de `env:`, imprimió `$(whoami)`.
- `::add-mask::` oculta el valor solo en las líneas impresas después.
- Token OIDC para la audiencia `learn-course`: duración 300 s, `sub` = `repo:spareilleux@6644695/learn@1368550922:ref:refs/heads/main`, el formato inmutable de los repositorios creados después del 2026-07-15.

## 2026-09-14 — Lección 8: el despliegue de este sitio, desmontado

- Una ejecución de despliegue: `build` 30 s (310 páginas construidas en 7,47 s, artefacto `github-pages` de 9 108 634 bytes conservado 1 día), `deploy` 8 s. Estados del despliegue: `waiting` → `queued` → `in_progress` → `success` en 13 s.
- La cola de concurrencia funcionó: un push 41 s después de otro esperó 14 s, y su job `build` se creó a las 13:32:18, el segundo en que terminó el job `deploy` anterior.
- `gh workflow run deploy.yml --ref gha-06-invalid`: el build se ejecutó, el job de despliegue fue rechazado (`Branch "gha-06-invalid" is not allowed to deploy to github-pages due to environment protection rules`), el sitio publicado no cambió. Comprobado antes que no había ningún despliegue de `main` pendiente, ya que la ejecución de la rama comparte el grupo de concurrencia `pages`.
- `https://spareilleux.github.io/method/` → 404: un enlace absoluto desde la raíz sale del sitio del proyecto.

## 2026-09-14 — Lección 9: timeouts que tardan más, y un fallo que cuenta como éxito

- `gh run view --log-failed`: 15 líneas de 169; el job cancelado por su timeout no aparece.
- `gh run rerun --debug`: evaluaciones de condiciones `##[debug]`, `RUNNER_DEBUG=1`, el job `noisy` de 70 a 190 líneas, y una carpeta `runner-diagnostic-logs` (logs de Runner y Worker) en el archivo.
- `gh run rerun --failed` volvió a ejecutar los jobs fallidos y el cancelado, y conservó el que tuvo éxito en el intento 1.
- `timeout-minutes: 1` en un job: cancelado a los 87 s, tres veces, con `sleep 90` o `sleep 300`. En un step: fallido a los 72 s, `The action 'Run date -u +%T' has timed out after 1 minutes.`
- Una ejecución cuyos jobs tuvieron éxito, fallaron con `continue-on-error` o fueron cancelados por un timeout termina en `cancelled`. Con solo el fallo con `continue-on-error`, termina en `success`, y `needs.<job>.result` es `success`.

## 2026-09-14 — Lección 10: tres fallos antes de una acción que funciona

- `require()` en la acción JavaScript: `require is not defined in ES module scope`, en local, porque el `package.json` del repositorio (el del sitio Astro) dice `"type": "module"`. Cambiado a `import`; una copia CommonJS falló igual en el runner.
- Acción de contenedor, primer push, incluida en el commit sin el bit de ejecución a propósito: `exec: "/entrypoint.sh": permission denied`. Los archivos creados en Windows se incluyen en el commit como `100644` (`core.filemode` es `false`); corregido con `git update-index --chmod=+x`.
- Acción de contenedor en `windows-latest`: `Container action is only supported on Linux`.
- El runner no impone `required: true`; un input desconocido es solo una advertencia (`Unexpected input(s) 'txt', valid inputs are ['text', 'max-length']`).
- Duración de los steps: acción JavaScript en menos de 1 s en los tres sistemas operativos, acción de contenedor en 5 s (construcción de la imagen incluida).

## Preguntas abiertas

- ¿El disparador `schedule` de `gha-03` (lunes 06:17 UTC) se ejecuta a su hora? *Por verificar el 2026-09-21.*
- ¿Qué artefacto elige `download-artifact` cuando dos comparten nombre, y es estable? *Por verificar.*
- ¿Falla `actions/checkout` en un repositorio privado cuando el token del job no tiene el permiso `contents`? *Por verificar.*
- ¿Por qué un timeout de job de 1 minuto se aplica a los 87 s? *Por verificar* con límites más largos.
- ¿Qué muestra exactamente la página de un pull request para un check obligatorio omitido por `paths`? *Por verificar.*
